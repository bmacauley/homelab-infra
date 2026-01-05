#-------------------------------------------------------------
# Example: ISO Boot VM
#
# This example demonstrates creating a VM that boots from
# an ISO image for manual OS installation.
#-------------------------------------------------------------

module "iso_boot_vm" {
  source = "../../"

  # VM Identity
  node        = "proxmox"
  vm_id       = 201
  vm_name     = "example-iso-install"
  description = "Example VM for manual OS installation from ISO"
  tags        = "terraform,example,iso"

  # No clone - fresh VM
  clone = null

  # OS type for QEMU optimization
  qemu_os = "l26"
  os_type = "l26"

  # CPU and Memory
  cores    = 2
  sockets  = 1
  cpu_type = "host"
  memory   = 4096
  balloon  = 0

  # BIOS - use UEFI for modern OS
  bios = "ovmf"

  # SCSI controller
  scsihw = "virtio-scsi-pci"

  # Disk configuration with ISO
  disks = {
    scsi = {
      scsi0 = {
        disk = {
          storage    = "local-lvm"
          size       = 64
          discard    = true
          emulatessd = true
          iothread   = true
        }
      }
    }
    ide = {
      ide2 = {
        cdrom = {
          iso = "local:iso/ubuntu-24.04-live-server-amd64.iso"
        }
      }
    }
  }

  # EFI disk required for UEFI boot
  efidisk = {
    storage           = "local-lvm"
    efitype           = "4m"
    pre_enrolled_keys = false
  }

  # Boot order - CD first, then disk
  boot = "order=ide2;scsi0"

  # Network configuration
  network = {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = false
  }

  # Cloud-init disabled for ISO install
  cloudinit = {
    enabled = false
  }

  # Display for VNC access during installation
  vga = {
    type   = "std"
    memory = 16
  }

  # Boot and startup
  onboot   = false
  vm_state = "running"

  # Agent disabled until OS is installed
  agent = 0

  # Disable provisioning for ISO install
  enable_bootstrap = false
  enable_tailscale = false
  proxmox_host     = "proxmox.example.com"
}

output "vm_id" {
  value = module.iso_boot_vm.vmid
}

output "vm_name" {
  value = module.iso_boot_vm.name
}
