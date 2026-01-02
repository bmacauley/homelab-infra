#-------------------------------------------------------------
# variables.tf
#
# LXC module input variables
#-------------------------------------------------------------

#-------------------------------------------------------------
# LXC Core Variables
#-------------------------------------------------------------
variable "node" {
  description = "Name of Proxmox node to provision LXC on, e.g. `proxmox`."
  type        = string
}

variable "lxc_id" {
  description = "ID number for new LXC."
  type        = number
}

variable "lxc_name" {
  description = "LXC name, must be alphanumeric (may contain dash: `-`). Defaults to using PVE naming, e.g. `CT<LXC_ID>`."
  type        = string
  default     = null
}

variable "description" {
  description = "LXC description."
  type        = string
  default     = null
}

variable "os_template" {
  description = "Template for LXC, e.g. `local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst`."
  type        = string
}

variable "os_type" {
  description = "Container OS specific setup, uses setup scripts in `/usr/share/lxc/config/<ostype>.common.conf`."
  type        = string
  default     = "unmanaged"
  validation {
    condition     = contains(["alpine", "archlinux", "centos", "debian", "devuan", "fedora", "gentoo", "nixos", "opensuse", "ubuntu", "unmanaged"], var.os_type)
    error_message = "Invalid OS type setting."
  }
}

variable "unprivileged" {
  description = "Set container to unprivileged. Set to false for privileged containers (required for Tailscale)."
  type        = bool
  default     = true
}

#-------------------------------------------------------------
# CPU and Memory Variables
#-------------------------------------------------------------
variable "vcpu" {
  description = "Number of CPU cores."
  type        = string
  default     = "1"
}

variable "memory" {
  description = "Memory size in `MiB`."
  type        = string
  default     = "512"
}

variable "memory_swap" {
  description = "Memory swap size in `MiB`."
  type        = string
  default     = "512"
}

#-------------------------------------------------------------
# Startup Variables
#-------------------------------------------------------------
variable "start_on_boot" {
  description = "Start container on PVE boot."
  type        = bool
  default     = false
}

variable "startup_options" {
  description = "Startup and shutdown options, e.g. `order=1,up=30,down=30`"
  type        = string
  default     = null
}

variable "start_on_create" {
  description = "Start container after creation."
  type        = bool
  default     = false
}

#-------------------------------------------------------------
# Disk Variables
#-------------------------------------------------------------
variable "disk_storage" {
  description = "Disk storage location."
  type        = string
  default     = "local-lvm"
}

variable "disk_size" {
  description = "Disk size, e.g. `8G`."
  type        = string
  default     = "8G"
}

variable "mountpoint" {
  description = "Optional mountpoints for the container."
  type = list(object({
    mp         = optional(string, "/mnt/local")
    mp_size    = optional(string, "4G")
    mp_slot    = optional(number, 0)
    mp_key     = optional(string, "0")
    mp_storage = optional(string, "local-lvm")
    mp_volume  = optional(string, null)
    mp_backup  = optional(bool, false)
  }))
  default = null
}

#-------------------------------------------------------------
# Network Variables
#-------------------------------------------------------------
variable "vnic_name" {
  description = "Networking adapter name."
  type        = string
  default     = "eth0"
}

variable "vnic_bridge" {
  description = "Networking adapter bridge, e.g. `vmbr0`."
  type        = string
  default     = "vmbr0"
}

variable "vlan_tag" {
  description = "Networking adapter VLAN tag."
  type        = number
  default     = null
}

variable "ipv4_address" {
  description = "Defaults to DHCP, for static IPv4 address set CIDR."
  type        = string
  default     = "dhcp"
}

variable "ipv4_gateway" {
  description = "Defaults to DHCP, for static IPv4 gateway set IP address."
  type        = string
  default     = null
}

variable "ipv6_address" {
  description = "Defaults to DHCP, for static IPv6 address set CIDR."
  type        = string
  default     = "dhcp"
}

variable "ipv6_gateway" {
  description = "Defaults to DHCP, for static IPv6 gateway set IP address."
  type        = string
  default     = null
}

variable "dns_domain" {
  description = "Defaults to using PVE host setting."
  type        = string
  default     = null
}

variable "dns_server" {
  description = "Defaults to using PVE host setting."
  type        = string
  default     = null
}

#-------------------------------------------------------------
# User Variables
#-------------------------------------------------------------
variable "user_ssh_key_public" {
  description = "Public SSH Key for LXC user."
  default     = null
  type        = string
  sensitive   = true
  validation {
    condition     = var.user_ssh_key_public == null || can(regex("(?i)PRIVATE", var.user_ssh_key_public)) == false
    error_message = "Error: Private SSH Key detected."
  }
}

variable "user_password" {
  description = "Password for LXC user."
  type        = string
  sensitive   = true
  default     = null
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
  description = "Enable Tailscale provisioning on the container."
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
