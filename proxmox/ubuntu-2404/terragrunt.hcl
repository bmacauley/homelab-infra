#-------------------------------------------------------------
# terragrunt.hcl
#
# Ubuntu 24.04 VM layer
# - configure module source for the layer
# - configure module inputs
# - configure layer dependencies
#-------------------------------------------------------------

include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  global_vars     = read_terragrunt_config("global.hcl", read_terragrunt_config(find_in_parent_folders("global.hcl", "does-not-exist.fallback"), { locals = {} }))
  proxmox_api_url = local.global_vars.locals.proxmox_api_url
}

terraform {
  source = "${get_repo_root()}/terraform/proxmox/modules/vm"
}

# Wire vault secrets to module locals
generate "vault_secrets" {
  path      = "vault_secrets.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    # Provide tailscale_auth_key local required by the VM module
    locals {
      tailscale_auth_key = data.vault_kv_secret_v2.tailscale.data["auth-key"]
    }
  EOF
}

inputs = {
  # Proxmox node
  node = "proxmox"

  # VM identity
  vm_id       = 200
  vm_name     = "ubuntu-2404"
  description = "Ubuntu 24.04 LTS VM"
  tags        = "terraform,ubuntu"

  # Clone from cloud-init template
  clone      = "ubuntu-2404-homelab"
  full_clone = true

  # OS type (l26 = Linux 2.6+ kernel)
  qemu_os = "l26"
  os_type = "l26"

  # CPU configuration
  cores    = 2
  sockets  = 1
  cpu_type = "host"
  numa     = false

  # Memory configuration
  memory  = 512
  balloon = 0

  # BIOS
  bios = "seabios"

  # SCSI controller
  scsihw = "virtio-scsi-pci"

  # Disk configuration
  disks = {
    scsi = {
      scsi0 = {
        disk = {
          storage    = "local-lvm"
          size       = 32
          discard    = true
          emulatessd = true
          iothread   = true
        }
      }
    }
    ide = {
      ide2 = {
        cloudinit = {
          storage = "local-lvm"
        }
      }
    }
  }

  # Network configuration
  network = {
    model    = "virtio"
    bridge   = "vmbr0"
    tag      = null
    firewall = false
  }

  # Cloud-init configuration
  cloudinit = {
    enabled   = true
    ipconfig0 = "ip=dhcp"
    ciuser    = "ubuntu"
  }

  # Display
  vga = {
    type = "std"
  }

  # Boot and startup
  onboot   = false
  vm_state = "running"

  # QEMU guest agent
  agent = 1

  # Tailscale configuration
  enable_tailscale = true

  # Bootstrap configuration
  enable_bootstrap = true
}
