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
  global_vars     = read_terragrunt_config("global.hcl", read_terragrunt_config(find_in_parent_folders("global.hcl", "does-not-exist.fallback"), { locals = {} }))
  proxmox_api_url = local.global_vars.locals.proxmox_api_url
}

terraform {
  source = "${get_repo_root()}/terraform/proxmox/modules/lxc"
}

# Wire vault secrets to module locals
generate "vault_secrets" {
  path      = "vault_secrets.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    # Provide tailscale_auth_key local required by the LXC module
    locals {
      tailscale_auth_key = data.vault_kv_secret_v2.tailscale.data["auth-key"]
    }
  EOF
}

inputs = {
  # Proxmox node
  node = "proxmox"

  # LXC identity
  lxc_id   = 151
  lxc_name = "iventoy"

  # OS template
  os_template = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  os_type     = "ubuntu"

  # CPU and Memory
  vcpu        = "1"
  memory      = "512"
  memory_swap = "512"

  # Disk
  disk_storage = "local-lvm"
  disk_size    = "8G"

  # Network configuration
  vnic_name    = "eth0"
  vnic_bridge  = "vmbr0"
  vlan_tag     = null
  ipv4_address = "dhcp"

  # User credentials
  user_password = "password"

  # Container privilege mode (false = privileged, required for Tailscale)
  unprivileged = false

  # Start container after creation
  start_on_create = true

  # Start container on Proxmox host boot
  start_on_boot = false

  # Tailscale configuration
  enable_tailscale = true

  # Bootstrap configuration
  enable_bootstrap = true
}
