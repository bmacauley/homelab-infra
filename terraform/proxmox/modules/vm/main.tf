#-------------------------------------------------------------
# main.tf
#
# VM Qemu resource for Proxmox
#-------------------------------------------------------------

resource "proxmox_vm_qemu" "vm" {
  target_node = var.node
  vmid        = var.vm_id
  name        = var.vm_name
  desc        = var.description
  tags        = var.tags

  # Clone configuration
  clone      = var.clone
  full_clone = var.full_clone

  # OS type
  qemu_os = var.qemu_os
  os_type = var.os_type

  # BIOS and boot
  bios     = var.bios
  machine  = var.machine
  boot     = var.boot
  onboot   = var.onboot
  vm_state = var.vm_state

  # Agent
  agent = var.agent

  # CPU configuration
  cpu {
    cores   = var.cores
    sockets = var.sockets
    type    = var.cpu_type
    numa    = var.numa
  }

  # Memory
  memory  = var.memory
  balloon = var.balloon
  hotplug = var.hotplug

  # SCSI controller
  scsihw = var.scsihw

  # VGA
  vga {
    type   = var.vga.type
    memory = var.vga.memory
  }

  # Serial device
  dynamic "serial" {
    for_each = var.serial != null ? [var.serial] : []
    content {
      id   = serial.value.id
      type = serial.value.type
    }
  }

  # Disks configuration
  dynamic "disks" {
    for_each = var.disks != null ? [var.disks] : []
    content {
      dynamic "scsi" {
        for_each = disks.value.scsi != null ? [disks.value.scsi] : []
        content {
          dynamic "scsi0" {
            for_each = scsi.value.scsi0 != null ? [scsi.value.scsi0] : []
            content {
              dynamic "disk" {
                for_each = scsi0.value.disk != null ? [scsi0.value.disk] : []
                content {
                  storage    = disk.value.storage
                  size       = disk.value.size
                  emulatessd = disk.value.emulatessd
                  discard    = disk.value.discard
                  iothread   = disk.value.iothread
                  replicate  = disk.value.replicate
                  backup     = disk.value.backup
                  cache      = disk.value.cache
                }
              }
              dynamic "cloudinit" {
                for_each = scsi0.value.cloudinit != null ? [scsi0.value.cloudinit] : []
                content {
                  storage = cloudinit.value.storage
                }
              }
            }
          }
          dynamic "scsi1" {
            for_each = scsi.value.scsi1 != null ? [scsi.value.scsi1] : []
            content {
              dynamic "disk" {
                for_each = scsi1.value.disk != null ? [scsi1.value.disk] : []
                content {
                  storage    = disk.value.storage
                  size       = disk.value.size
                  emulatessd = disk.value.emulatessd
                  discard    = disk.value.discard
                  iothread   = disk.value.iothread
                  replicate  = disk.value.replicate
                  backup     = disk.value.backup
                  cache      = disk.value.cache
                }
              }
            }
          }
          dynamic "scsi2" {
            for_each = scsi.value.scsi2 != null ? [scsi.value.scsi2] : []
            content {
              dynamic "disk" {
                for_each = scsi2.value.disk != null ? [scsi2.value.disk] : []
                content {
                  storage    = disk.value.storage
                  size       = disk.value.size
                  emulatessd = disk.value.emulatessd
                  discard    = disk.value.discard
                  iothread   = disk.value.iothread
                  replicate  = disk.value.replicate
                  backup     = disk.value.backup
                  cache      = disk.value.cache
                }
              }
            }
          }
        }
      }
      dynamic "ide" {
        for_each = disks.value.ide != null ? [disks.value.ide] : []
        content {
          dynamic "ide0" {
            for_each = ide.value.ide0 != null ? [ide.value.ide0] : []
            content {
              dynamic "cdrom" {
                for_each = ide0.value.cdrom != null ? [ide0.value.cdrom] : []
                content {
                  iso = cdrom.value.iso
                }
              }
              dynamic "cloudinit" {
                for_each = ide0.value.cloudinit != null ? [ide0.value.cloudinit] : []
                content {
                  storage = cloudinit.value.storage
                }
              }
            }
          }
          dynamic "ide2" {
            for_each = ide.value.ide2 != null ? [ide.value.ide2] : []
            content {
              dynamic "cdrom" {
                for_each = ide2.value.cdrom != null ? [ide2.value.cdrom] : []
                content {
                  iso = cdrom.value.iso
                }
              }
              dynamic "cloudinit" {
                for_each = ide2.value.cloudinit != null ? [ide2.value.cloudinit] : []
                content {
                  storage = cloudinit.value.storage
                }
              }
            }
          }
        }
      }
      dynamic "virtio" {
        for_each = disks.value.virtio != null ? [disks.value.virtio] : []
        content {
          dynamic "virtio0" {
            for_each = virtio.value.virtio0 != null ? [virtio.value.virtio0] : []
            content {
              dynamic "disk" {
                for_each = virtio0.value.disk != null ? [virtio0.value.disk] : []
                content {
                  storage   = disk.value.storage
                  size      = disk.value.size
                  discard   = disk.value.discard
                  iothread  = disk.value.iothread
                  replicate = disk.value.replicate
                  backup    = disk.value.backup
                  cache     = disk.value.cache
                }
              }
            }
          }
        }
      }
    }
  }

  # EFI disk (for UEFI)
  dynamic "efidisk" {
    for_each = var.efidisk != null ? [var.efidisk] : []
    content {
      storage           = efidisk.value.storage
      efitype           = efidisk.value.efitype
      pre_enrolled_keys = efidisk.value.pre_enrolled_keys
    }
  }

  # TPM state
  dynamic "tpm_state" {
    for_each = var.tpm_state != null ? [var.tpm_state] : []
    content {
      storage = tpm_state.value.storage
      version = tpm_state.value.version
    }
  }

  # Primary network interface
  network {
    id       = 0
    model    = var.network.model
    bridge   = var.network.bridge
    tag      = var.network.tag
    firewall = var.network.firewall
    macaddr  = var.network.macaddr
    queues   = var.network.queues
    rate     = var.network.rate
    mtu      = var.network.mtu
  }

  # Additional network interfaces
  dynamic "network" {
    for_each = var.additional_networks
    content {
      id       = network.key + 1
      model    = network.value.model
      bridge   = network.value.bridge
      tag      = network.value.tag
      firewall = network.value.firewall
      macaddr  = network.value.macaddr
      queues   = network.value.queues
      rate     = network.value.rate
      mtu      = network.value.mtu
    }
  }

  # Cloud-init settings
  ciuser       = var.cloudinit.enabled ? var.cloudinit.ciuser : null
  cipassword   = var.cloudinit.enabled ? var.cloudinit.cipassword : null
  cicustom     = var.cloudinit.enabled ? var.cloudinit.cicustom : null
  ipconfig0    = var.cloudinit.enabled ? var.cloudinit.ipconfig0 : null
  ipconfig1    = var.cloudinit.enabled ? var.cloudinit.ipconfig1 : null
  searchdomain = var.cloudinit.enabled ? var.cloudinit.searchdomain : null
  nameserver   = var.cloudinit.enabled ? var.cloudinit.nameserver : null
  sshkeys      = var.cloudinit.enabled ? var.cloudinit.sshkeys : null

  # Lifecycle
  lifecycle {
    ignore_changes = [
      network[0].macaddr,
    ]
  }
}
