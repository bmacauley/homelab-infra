#-------------------------------------------------------------
# variables.tf
#
# VM module input variables
#-------------------------------------------------------------

#-------------------------------------------------------------
# VM Core Variables
#-------------------------------------------------------------
variable "node" {
  description = "Name of Proxmox node to provision VM on, e.g. `proxmox`."
  type        = string
}

variable "vm_id" {
  description = "ID number for new VM."
  type        = number
}

variable "vm_name" {
  description = "VM name, must be alphanumeric (may contain dash: `-`)."
  type        = string
}

variable "description" {
  description = "VM description."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for the VM (comma-separated string or list)."
  type        = string
  default     = null
}

#-------------------------------------------------------------
# Clone Variables
#-------------------------------------------------------------
variable "clone" {
  description = "Name of the template to clone from. If set, iso will be ignored."
  type        = string
  default     = null
}

variable "full_clone" {
  description = "Create a full clone instead of linked clone."
  type        = bool
  default     = true
}

#-------------------------------------------------------------
# ISO Variables
#-------------------------------------------------------------
variable "iso" {
  description = "ISO image to boot from, e.g. `local:iso/ubuntu-24.04-live-server-amd64.iso`."
  type        = string
  default     = null
}

#-------------------------------------------------------------
# OS Type Variables
#-------------------------------------------------------------
variable "os_type" {
  description = "Provisioning method based on OS type. Use 'cloud-init' for cloud-init templates."
  type        = string
  default     = "cloud-init"
  validation {
    condition     = contains(["ubuntu", "centos", "cloud-init", "l26", "l24", "win11", "win10", "win8", "win7", "wvista", "wxp", "w2k8", "w2k3", "w2k", "solaris", "other"], var.os_type)
    error_message = "Invalid OS type. Use 'cloud-init' for cloud-init templates, or OS-specific types."
  }
}

variable "qemu_os" {
  description = "QEMU OS type for KVM."
  type        = string
  default     = "l26"
}

#-------------------------------------------------------------
# CPU Variables
#-------------------------------------------------------------
variable "cores" {
  description = "Number of CPU cores per socket."
  type        = number
  default     = 1
}

variable "sockets" {
  description = "Number of CPU sockets."
  type        = number
  default     = 1
}

variable "cpu_type" {
  description = "CPU type (host, kvm64, qemu64, etc.)."
  type        = string
  default     = "host"
}

variable "numa" {
  description = "Enable NUMA."
  type        = bool
  default     = false
}

variable "hotplug" {
  description = "Hotplug settings (disk, network, usb, memory, cpu)."
  type        = string
  default     = "network,disk,usb"
}

#-------------------------------------------------------------
# Memory Variables
#-------------------------------------------------------------
variable "memory" {
  description = "Memory size in MiB."
  type        = number
  default     = 2048
}

variable "balloon" {
  description = "Minimum memory for balloon device (0 to disable)."
  type        = number
  default     = 0
}

#-------------------------------------------------------------
# BIOS and Machine Variables
#-------------------------------------------------------------
variable "bios" {
  description = "BIOS type (seabios or ovmf for UEFI)."
  type        = string
  default     = "seabios"
  validation {
    condition     = contains(["seabios", "ovmf"], var.bios)
    error_message = "BIOS must be seabios or ovmf."
  }
}

variable "machine" {
  description = "Machine type (pc, q35, etc.)."
  type        = string
  default     = null
}

#-------------------------------------------------------------
# Boot Variables
#-------------------------------------------------------------
variable "boot" {
  description = "Boot order, e.g. `order=scsi0;ide2;net0`."
  type        = string
  default     = null
}

variable "onboot" {
  description = "Start VM on PVE boot."
  type        = bool
  default     = false
}

variable "startup" {
  description = "Startup and shutdown options, e.g. `order=1,up=30,down=30`."
  type        = string
  default     = null
}

variable "vm_state" {
  description = "Desired state of the VM after creation (running, stopped)."
  type        = string
  default     = "running"
  validation {
    condition     = contains(["running", "stopped"], var.vm_state)
    error_message = "vm_state must be running or stopped."
  }
}

#-------------------------------------------------------------
# Agent Variables
#-------------------------------------------------------------
variable "agent" {
  description = "Enable QEMU Guest Agent (1 to enable, 0 to disable)."
  type        = number
  default     = 1
  validation {
    condition     = contains([0, 1], var.agent)
    error_message = "Agent must be 0 or 1."
  }
}

#-------------------------------------------------------------
# Display Variables
#-------------------------------------------------------------
variable "vga" {
  description = "VGA display configuration."
  type = object({
    type   = optional(string, "std")
    memory = optional(number, null)
  })
  default = {
    type = "std"
  }
}

variable "serial" {
  description = "Serial device configuration."
  type = object({
    id   = number
    type = string
  })
  default = null
}

#-------------------------------------------------------------
# Disk Variables
#-------------------------------------------------------------
variable "scsihw" {
  description = "SCSI controller type."
  type        = string
  default     = "virtio-scsi-pci"
  validation {
    condition     = contains(["lsi", "lsi53c810", "megasas", "pvscsi", "virtio-scsi-pci", "virtio-scsi-single"], var.scsihw)
    error_message = "Invalid SCSI hardware type."
  }
}

variable "disks" {
  description = "List of disks to attach to the VM."
  type = object({
    scsi = optional(object({
      scsi0 = optional(object({
        disk = optional(object({
          storage         = string
          size            = number
          emulatessd      = optional(bool, false)
          discard         = optional(bool, false)
          iothread        = optional(bool, true)
          replicate       = optional(bool, true)
          backup          = optional(bool, true)
          cache           = optional(string, "none")
          asyncio         = optional(string, null)
        }))
        cloudinit = optional(object({
          storage = string
        }))
      }))
      scsi1 = optional(object({
        disk = optional(object({
          storage         = string
          size            = number
          emulatessd      = optional(bool, false)
          discard         = optional(bool, false)
          iothread        = optional(bool, true)
          replicate       = optional(bool, true)
          backup          = optional(bool, true)
          cache           = optional(string, "none")
          asyncio         = optional(string, null)
        }))
      }))
      scsi2 = optional(object({
        disk = optional(object({
          storage         = string
          size            = number
          emulatessd      = optional(bool, false)
          discard         = optional(bool, false)
          iothread        = optional(bool, true)
          replicate       = optional(bool, true)
          backup          = optional(bool, true)
          cache           = optional(string, "none")
          asyncio         = optional(string, null)
        }))
      }))
    }))
    ide = optional(object({
      ide0 = optional(object({
        cdrom = optional(object({
          iso = string
        }))
        cloudinit = optional(object({
          storage = string
        }))
      }))
      ide2 = optional(object({
        cdrom = optional(object({
          iso = string
        }))
        cloudinit = optional(object({
          storage = string
        }))
      }))
    }))
    virtio = optional(object({
      virtio0 = optional(object({
        disk = optional(object({
          storage         = string
          size            = number
          discard         = optional(bool, false)
          iothread        = optional(bool, true)
          replicate       = optional(bool, true)
          backup          = optional(bool, true)
          cache           = optional(string, "none")
          asyncio         = optional(string, null)
        }))
      }))
    }))
  })
  default = null
}

#-------------------------------------------------------------
# Network Variables
#-------------------------------------------------------------
variable "network" {
  description = "Network interface configuration."
  type = object({
    model    = optional(string, "virtio")
    bridge   = optional(string, "vmbr0")
    tag      = optional(number, null)
    firewall = optional(bool, false)
    macaddr  = optional(string, null)
    queues   = optional(number, null)
    rate     = optional(number, null)
    mtu      = optional(number, null)
  })
  default = {
    model  = "virtio"
    bridge = "vmbr0"
  }
}

variable "additional_networks" {
  description = "Additional network interfaces."
  type = list(object({
    model    = optional(string, "virtio")
    bridge   = optional(string, "vmbr0")
    tag      = optional(number, null)
    firewall = optional(bool, false)
    macaddr  = optional(string, null)
    queues   = optional(number, null)
    rate     = optional(number, null)
    mtu      = optional(number, null)
  }))
  default = []
}

#-------------------------------------------------------------
# Cloud-Init Variables
#-------------------------------------------------------------
variable "cloudinit" {
  description = "Cloud-init configuration."
  type = object({
    enabled      = optional(bool, false)
    storage      = optional(string, "local-lvm")
    user         = optional(string, null)
    password     = optional(string, null)
    sshkeys      = optional(string, null)
    ipconfig0    = optional(string, "ip=dhcp")
    ipconfig1    = optional(string, null)
    nameserver   = optional(string, null)
    searchdomain = optional(string, null)
    ciuser       = optional(string, null)
    cipassword   = optional(string, null)
    cicustom     = optional(string, null)
  })
  default = {
    enabled = false
  }
  sensitive = true
}

#-------------------------------------------------------------
# EFI Disk Variables
#-------------------------------------------------------------
variable "efidisk" {
  description = "EFI disk configuration (required for UEFI/OVMF)."
  type = object({
    storage         = string
    efitype         = optional(string, "4m")
    pre_enrolled_keys = optional(bool, false)
  })
  default = null
}

#-------------------------------------------------------------
# TPM Variables
#-------------------------------------------------------------
variable "tpm_state" {
  description = "TPM state storage configuration."
  type = object({
    storage = string
    version = optional(string, "v2.0")
  })
  default = null
}

#-------------------------------------------------------------
# Proxmox Host Variables
#-------------------------------------------------------------
variable "proxmox_host" {
  description = "Proxmox host address for SSH provisioning."
  type        = string
  default     = "proxmox.tailfb76f.ts.net"
}

#-------------------------------------------------------------
# Tailscale Variables
#-------------------------------------------------------------
variable "enable_tailscale" {
  description = "Enable Tailscale provisioning on the VM."
  type        = bool
  default     = true
}

#-------------------------------------------------------------
# Bootstrap Variables
#-------------------------------------------------------------
variable "enable_bootstrap" {
  description = "Enable bootstrap provisioning (installs curl, ansible, avahi-daemon, Tailscale)."
  type        = bool
  default     = true
}

variable "additional_packages" {
  description = "Additional packages to install during bootstrap."
  type        = list(string)
  default     = []
}

variable "additional_runcmd" {
  description = "Additional runcmd entries for cloud-init."
  type        = list(string)
  default     = []
}

#-------------------------------------------------------------
# Cloud-init Provisioning Variables
#-------------------------------------------------------------
variable "use_cloudinit_provisioning" {
  description = "Use cloud-init for provisioning instead of qemu-guest-agent."
  type        = bool
  default     = true
}

variable "snippets_storage" {
  description = "Proxmox storage for cloud-init snippets."
  type        = string
  default     = "local"
}

#-------------------------------------------------------------
# SSH Variables for Provisioning
#-------------------------------------------------------------
variable "ssh_user" {
  description = "SSH user for connecting to the VM during provisioning."
  type        = string
  default     = "root"
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for VM provisioning (on Proxmox host)."
  type        = string
  default     = null
}

variable "ssh_timeout" {
  description = "Timeout for SSH connection during provisioning."
  type        = string
  default     = "5m"
}
