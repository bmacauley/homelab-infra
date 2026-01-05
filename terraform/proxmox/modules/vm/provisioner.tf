#-------------------------------------------------------------
# provisioner.tf
#
# VM provisioning via cloud-init or qemu-guest-agent
#-------------------------------------------------------------

# NOTE: local.tailscale_auth_key must be defined externally via terragrunt generate
# This decouples the module from vault provider dependency

locals {
  # Cloud-init user-data content
  cloudinit_userdata = var.use_cloudinit_provisioning ? templatefile("${path.module}/templates/cloudinit-userdata.yml.tpl", {
    hostname             = var.vm_name
    enable_tailscale     = var.enable_tailscale
    tailscale_auth_token = try(local.tailscale_auth_key, null)
    additional_runcmd    = var.additional_runcmd
  }) : null

  # Snippet filename on Proxmox
  snippet_filename = "vm-${var.vm_id}-user.yml"

  # Bootstrap script for legacy provisioning
  bootstrap_script = var.enable_bootstrap && !var.use_cloudinit_provisioning ? templatefile("${path.module}/templates/bootstrap.sh.tpl", {
    tailscale_auth_token = try(local.tailscale_auth_key, null)
    hostname             = var.vm_name
    additional_packages  = join(" ", var.additional_packages)
    enable_tailscale     = var.enable_tailscale
  }) : null
}

#-------------------------------------------------------------
# Cloud-init provisioning
# Uploads user-data to Proxmox snippets BEFORE VM creation
#-------------------------------------------------------------
resource "local_file" "cloudinit_userdata" {
  count    = var.use_cloudinit_provisioning ? 1 : 0
  content  = local.cloudinit_userdata
  filename = "${path.module}/generated/${local.snippet_filename}"
}

resource "null_resource" "cloudinit_snippet" {
  count = var.use_cloudinit_provisioning ? 1 : 0

  triggers = {
    userdata_hash = sha256(local.cloudinit_userdata)
    proxmox_host  = var.proxmox_host
    snippet_file  = local.snippet_filename
    storage       = var.snippets_storage
  }

  connection {
    type = "ssh"
    host = self.triggers.proxmox_host
    user = "root"
  }

  # Ensure snippets directory exists
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /var/lib/vz/snippets",
    ]
  }

  # Upload cloud-init user-data to Proxmox snippets
  provisioner "file" {
    source      = local_file.cloudinit_userdata[0].filename
    destination = "/var/lib/vz/snippets/${self.triggers.snippet_file}"
  }

  # Cleanup snippet on destroy
  provisioner "remote-exec" {
    when = destroy

    inline = [
      "rm -f /var/lib/vz/snippets/${self.triggers.snippet_file} || true",
    ]
  }

  depends_on = [local_file.cloudinit_userdata]
}

#-------------------------------------------------------------
# Tailscale cleanup on destroy (cloud-init mode)
# Uses qemu-guest-agent to logout from Tailscale before VM deletion
#-------------------------------------------------------------
resource "null_resource" "tailscale_cleanup" {
  count = var.use_cloudinit_provisioning && var.enable_tailscale && var.agent == 1 ? 1 : 0

  triggers = {
    vm_id        = proxmox_vm_qemu.vm.vmid
    proxmox_host = var.proxmox_host
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
# Legacy: Bootstrap script file (qemu-guest-agent mode)
#-------------------------------------------------------------
resource "local_file" "bootstrap_script" {
  count    = var.enable_bootstrap && !var.use_cloudinit_provisioning ? 1 : 0
  content  = local.bootstrap_script
  filename = "${path.module}/generated/bootstrap_script_${proxmox_vm_qemu.vm.vmid}.sh"
}

#-------------------------------------------------------------
# Legacy: Base provisioner via qemu-guest-agent
#-------------------------------------------------------------
resource "null_resource" "base_provisioner" {
  count      = var.enable_bootstrap && !var.use_cloudinit_provisioning && var.agent == 1 ? 1 : 0
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
    destination = "/tmp/bootstrap_script_${self.triggers.vm_id}.sh"
  }

  # Push script into VM and execute it via qemu-guest-agent
  provisioner "remote-exec" {
    inline = [
      # Wait for QEMU guest agent to be ready (up to 2 minutes)
      <<-EOT
      echo "Waiting for QEMU guest agent on VM ${self.triggers.vm_id}..."
      for i in $(seq 1 24); do
        if qm guest exec ${self.triggers.vm_id} -- echo "ready" >/dev/null 2>&1; then
          echo "Guest agent ready after $((i * 5)) seconds"
          break
        fi
        echo "Attempt $i: Guest agent not ready, waiting 5s..."
        sleep 5
      done
      EOT
      ,
      "qm guest exec ${self.triggers.vm_id} -- mkdir -p /tmp",
      "qm guest exec-file ${self.triggers.vm_id} --source /tmp/bootstrap_script_${self.triggers.vm_id}.sh --destination /tmp/bootstrap_script.sh",
      "qm guest exec ${self.triggers.vm_id} -- chmod +x /tmp/bootstrap_script.sh",
      "qm guest exec ${self.triggers.vm_id} -- /tmp/bootstrap_script.sh",
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
# Legacy: SSH provisioner (when guest agent unavailable)
#-------------------------------------------------------------
resource "null_resource" "ssh_provisioner" {
  count      = var.enable_bootstrap && !var.use_cloudinit_provisioning && var.agent == 0 && var.ssh_private_key_path != null ? 1 : 0
  depends_on = [proxmox_vm_qemu.vm, local_file.bootstrap_script]

  triggers = {
    vm_id           = proxmox_vm_qemu.vm.vmid
    vm_ip           = proxmox_vm_qemu.vm.default_ipv4_address
    proxmox_host    = var.proxmox_host
    ssh_private_key = var.ssh_private_key_path
    ssh_user        = var.ssh_user
  }

  # First, copy script to Proxmox host
  connection {
    type = "ssh"
    host = self.triggers.proxmox_host
    user = "root"
  }

  provisioner "file" {
    source      = local_file.bootstrap_script[0].filename
    destination = "/tmp/bootstrap_script_${self.triggers.vm_id}.sh"
  }

  # SSH from Proxmox host to VM and run the script
  provisioner "remote-exec" {
    inline = [
      "sleep 60", # Wait for VM to fully boot
      "scp -o StrictHostKeyChecking=no -i ${self.triggers.ssh_private_key} /tmp/bootstrap_script_${self.triggers.vm_id}.sh ${self.triggers.ssh_user}@${self.triggers.vm_ip}:/tmp/bootstrap_script.sh",
      "ssh -o StrictHostKeyChecking=no -i ${self.triggers.ssh_private_key} ${self.triggers.ssh_user}@${self.triggers.vm_ip} 'chmod +x /tmp/bootstrap_script.sh && /tmp/bootstrap_script.sh'",
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
      "ssh -o StrictHostKeyChecking=no -i ${self.triggers.ssh_private_key} ${self.triggers.ssh_user}@${self.triggers.vm_ip} 'tailscale logout' || true",
    ]
  }
}
