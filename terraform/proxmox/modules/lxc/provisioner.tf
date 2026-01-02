#-------------------------------------------------------------
# provisioner.tf
#
# LXC provisioning for Tailscale and bootstrap
#-------------------------------------------------------------

# NOTE: local.tailscale_auth_key must be defined externally via terragrunt generate
# This decouples the module from vault provider dependency
locals {
  lxc_id = proxmox_lxc.lxc.vmid

  bootstrap_script = var.enable_bootstrap ? templatefile("${path.module}/templates/bootstrap.sh.tpl", {
    tailscale_auth_token = try(local.tailscale_auth_key, null)
    hostname             = var.lxc_name
    additional_packages  = join(" ", var.additional_packages)
    enable_tailscale     = var.enable_tailscale
  }) : null
}

#-------------------------------------------------------------
# Configure LXC for Tailscale (TUN device, nesting, keyctl)
#-------------------------------------------------------------
resource "null_resource" "configure_lxc_tailscale" {
  count      = var.enable_tailscale ? 1 : 0
  depends_on = [proxmox_lxc.lxc]

  connection {
    type = "ssh"
    host = var.proxmox_host
    user = "root"
  }

  provisioner "remote-exec" {
    inline = [
      "pct stop ${local.lxc_id} || true",
      "pct set ${local.lxc_id} --dev0 /dev/net/tun",
      "pct set ${local.lxc_id} --features keyctl=1,nesting=1",
      "pct start ${local.lxc_id}",
    ]
  }

  triggers = {
    container_id = proxmox_lxc.lxc.vmid
  }
}

#-------------------------------------------------------------
# Bootstrap script file
#-------------------------------------------------------------
resource "local_file" "bootstrap_script" {
  count    = var.enable_bootstrap ? 1 : 0
  content  = local.bootstrap_script
  filename = "${path.module}/generated/bootstrap_script_${local.lxc_id}.sh"
}

#-------------------------------------------------------------
# Base provisioner - push and execute bootstrap script
#-------------------------------------------------------------
resource "null_resource" "base_provisioner" {
  count      = var.enable_bootstrap ? 1 : 0
  depends_on = [null_resource.configure_lxc_tailscale, local_file.bootstrap_script]

  triggers = {
    lxc_id       = proxmox_lxc.lxc.vmid
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
    destination = "/tmp/bootstrap_script_${local.lxc_id}.sh"
  }

  # Push script into LXC container and execute it
  provisioner "remote-exec" {
    inline = [
      "pct push ${local.lxc_id} /tmp/bootstrap_script_${local.lxc_id}.sh /tmp/bootstrap_script.sh",
      "pct exec ${local.lxc_id} -- chmod +x /tmp/bootstrap_script.sh",
      "pct exec ${local.lxc_id} -- /tmp/bootstrap_script.sh",
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
      "pct exec ${self.triggers.lxc_id} -- tailscale logout || true",
    ]
  }
}
