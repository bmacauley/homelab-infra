#-------------------------------------------------------------
# terragrunt.hcl
#
# - configure module source for the layer
# - configure module inputs
# - configure layer dependencies
#-------------------------------------------------------------

include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  global_vars = read_terragrunt_config("global.hcl", read_terragrunt_config(find_in_parent_folders("global.hcl", "does-not-exist.fallback"), { locals = {} }))
  proxmox_api_url = local.global_vars.locals.proxmox_api_url

}

terraform {
  source = "github.com/trfore/terraform-telmate-proxmox//modules/lxc"
  # version = "2.0.1"
}

inputs = {
  pm_api_url = local.proxmox_api_url
  node = "proxmox"
  lxc_id = 150
  lxc_name = "iventoy"  # Container name in Proxmox
  os_template = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  os_type = "ubuntu"

  # CPU and Memory
  vcpu = "1"              # Number of CPU cores
  memory = "512"         # Memory in MiB (2GB = 2048 MiB)
  memory_swap = "512"    # Swap in MiB (2GB = 2048 MiB)

  # Disk
  disk_storage = "local-lvm"  # Storage pool name
  disk_size = "8G"           # Disk size (supports G, M, T suffixes)


    # Network configuration
  vnic_name = "eth0"
  vnic_bridge = "vmbr0"
  vlan_tag = null  # Remove VLAN tag if not using VLANs
  ipv4_address = "dhcp"

  # User credentials
  user_password = "password"

    # Start container after creation
  start_on_create = true

  # Optional: start container on Proxmox host boot
  start_on_boot = false
}
