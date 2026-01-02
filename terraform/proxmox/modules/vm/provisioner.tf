#-------------------------------------------------------------
# provisioner.tf
#
# VM provisioning for Tailscale and bootstrap
#-------------------------------------------------------------

# NOTE: local.tailscale_auth_key must be defined externally via terragrunt generate
# This decouples the module from vault provider dependency
locals {
  vm_id = proxmox_vm_qemu.vm.vmid

  bootstrap_script = var.enable_bootstrap ? templatefile("${path.module}/templates/bootstrap.sh.tpl", {
    tailscale_auth_token = try(local.tailscale_auth_key, null)
    hostname             = var.vm_name
    additional_packages  = join(" ", var.additional_packages)
    enable_tailscale     = var.enable_tailscale
  }) : null
}

#-------------------------------------------------------------
# Bootstrap script file
#-------------------------------------------------------------
resource "local_file" "bootstrap_script" {
  count    = var.enable_bootstrap ? 1 : 0
  content  = local.bootstrap_script
  filename = "${path.module}/generated/bootstrap_script_${local.vm_id}.sh"
}

#-------------------------------------------------------------
# Base provisioner - push and execute bootstrap script via Proxmox host
# Uses qm guest exec to run commands inside the VM via qemu-guest-agent
#-------------------------------------------------------------
resource "null_resource" "base_provisioner" {
  count      = var.enable_bootstrap && var.agent == 1 ? 1 : 0
  depends_on = [proxmox_vm_qemu.vm, local_file.bootstrap_script]

  triggers = {
    vm_id        = proxmox_vm_qemu.vm.vmid
    proxmox_host = var.proxmox_host
  }

  connection {
    type = "ssh"
    host = self.triggers.proxmox_host
    user = "root"
  }

  # Copy script to Proxmox host first
  provisioner "file" {
    source      = local_file.bootstrap_script[0].filename
    destination = "/tmp/bootstrap_script_${local.vm_id}.sh"
  }

  # Push script into VM and execute it via qemu-guest-agent
  provisioner "remote-exec" {
    inline = [
      "sleep 30", # Wait for VM to fully boot and agent to start
      "qm guest exec ${local.vm_id} -- mkdir -p /tmp",
      "qm guest exec-file ${local.vm_id} --source /tmp/bootstrap_script_${local.vm_id}.sh --destination /tmp/bootstrap_script.sh",
      "qm guest exec ${local.vm_id} -- chmod +x /tmp/bootstrap_script.sh",
      "qm guest exec ${local.vm_id} -- /tmp/bootstrap_script.sh",
    ]
  }

  # Logout of Tailscale on destroy
  provisioner "remote-exec" {
    when = destroy

    connection {
      type = "ssh"
      host = self.triggers.proxmox_host
      user = "root"
    }

    inline = [
      "qm guest exec ${self.triggers.vm_id} -- tailscale logout || true",
    ]
  }
}

#-------------------------------------------------------------
# Alternative provisioner - SSH directly to VM
# Use this when qemu-guest-agent is not available
#-------------------------------------------------------------
resource "null_resource" "ssh_provisioner" {
  count      = var.enable_bootstrap && var.agent == 0 && var.ssh_private_key_path != null ? 1 : 0
  depends_on = [proxmox_vm_qemu.vm, local_file.bootstrap_script]

  triggers = {
    vm_id        = proxmox_vm_qemu.vm.vmid
    vm_ip        = proxmox_vm_qemu.vm.default_ipv4_address
    proxmox_host = var.proxmox_host
  }

  # First, copy script to Proxmox host
  connection {
    type = "ssh"
    host = var.proxmox_host
    user = "root"
  }

  provisioner "file" {
    source      = local_file.bootstrap_script[0].filename
    destination = "/tmp/bootstrap_script_${local.vm_id}.sh"
  }

  # SSH from Proxmox host to VM and run the script
  provisioner "remote-exec" {
    inline = [
      "sleep 60", # Wait for VM to fully boot
      "scp -o StrictHostKeyChecking=no -i ${var.ssh_private_key_path} /tmp/bootstrap_script_${local.vm_id}.sh ${var.ssh_user}@${proxmox_vm_qemu.vm.default_ipv4_address}:/tmp/bootstrap_script.sh",
      "ssh -o StrictHostKeyChecking=no -i ${var.ssh_private_key_path} ${var.ssh_user}@${proxmox_vm_qemu.vm.default_ipv4_address} 'chmod +x /tmp/bootstrap_script.sh && /tmp/bootstrap_script.sh'",
    ]
  }

  # Logout of Tailscale on destroy
  provisioner "remote-exec" {
    when = destroy

    connection {
      type = "ssh"
      host = self.triggers.proxmox_host
      user = "root"
    }

    inline = [
      "ssh -o StrictHostKeyChecking=no -i ${var.ssh_private_key_path} ${var.ssh_user}@${self.triggers.vm_ip} 'tailscale logout' || true",
    ]
  }
}
