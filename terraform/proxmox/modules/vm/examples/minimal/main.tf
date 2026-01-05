#-------------------------------------------------------------
# Example: Minimal VM
#
# This example demonstrates the minimal configuration required
# to create a VM by cloning from an existing template.
#-------------------------------------------------------------

module "minimal_vm" {
  source = "../../"

  # Required: VM identity
  node    = "proxmox"
  vm_id   = 202
  vm_name = "minimal-vm"

  # Clone from template
  clone = "ubuntu-cloud-24.04"

  # Basic resources
  cores  = 1
  memory = 1024

  # Single disk
  disks = {
    scsi = {
      scsi0 = {
        disk = {
          storage = "local-lvm"
          size    = 16
        }
      }
    }
  }

  # Network with defaults
  network = {
    bridge = "vmbr0"
  }

  # Cloud-init with DHCP
  cloudinit = {
    enabled   = true
    ipconfig0 = "ip=dhcp"
  }

  # Disable provisioning for minimal example
  enable_bootstrap = false
  enable_tailscale = false
}

output "vm_id" {
  value = module.minimal_vm.vmid
}
