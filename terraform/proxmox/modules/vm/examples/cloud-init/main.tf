#-------------------------------------------------------------
# Example: Cloud-Init VM
#
# This example demonstrates creating a VM from a cloud-init
# ready template with automatic provisioning.
#-------------------------------------------------------------

module "cloud_init_vm" {
  source = "../../"

  # VM Identity
  node        = "proxmox"
  vm_id       = 200
  vm_name     = "example-cloud-init"
  description = "Example VM created from cloud-init template"
  tags        = "terraform,example"

  # Clone from cloud-init ready template
  clone      = "ubuntu-cloud-24.04"
  full_clone = true

  # CPU and Memory
  cores    = 2
  sockets  = 1
  cpu_type = "host"
  memory   = 2048
  balloon  = 1024

  # SCSI controller for better performance
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
    firewall = false
  }

  # Cloud-init configuration
  cloudinit = {
    enabled      = true
    ipconfig0    = "ip=dhcp"
    ciuser       = "ubuntu"
    sshkeys      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample user@hostname"
    searchdomain = "local"
  }

  # Boot and startup
  onboot   = false
  vm_state = "running"

  # QEMU guest agent (required for IP detection)
  agent = 1

  # Provisioning
  enable_bootstrap = true
  enable_tailscale = true
  proxmox_host     = "proxmox.example.com"
}

output "vm_id" {
  value = module.cloud_init_vm.vmid
}

output "vm_ip" {
  value = module.cloud_init_vm.default_ipv4_address
}
