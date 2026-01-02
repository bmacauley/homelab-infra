#---------------------------------------------------------------------------------------------------------------------
# root.hcl
#
# https://github.com/gruntwork-io/terragrunt
#
# - consolidate  environment variables across terragrunt layers
# - auto-create s3 state bucket and dynamodb lock table
# - constrain terraform/terragrunt versions
# - generate override provider.tf to constrain usage to specific AWS account
#---------------------------------------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------------------------------------
# Terraform/terragrunt constraints
#-----------------------------------------------------------------------------------------------------------------------
# the constraints should match the versions in the .tool-version config

terraform_binary = "tofu"


# Overrides the default minimum supported version of terraform. Terragrunt only officially supports the latest version
# of terraform, however in some cases an old terraform is needed.
terraform_version_constraint = ">= 0.11 "
# If the running version of Terragrunt doesn’t match the constraints specified, Terragrunt will produce an error and
# exit without taking any further actions.
terragrunt_version_constraint = ">= 0.96"


#-----------------------------------------------------------------------------------------------------------------------
# Auto configure  terraform state  in consul
# name pattern: -<project_name>-tfstate-consul-mbp-home
#               eg homelab-infra-tfstate-consul-mbp-home
#-----------------------------------------------------------------------------------------------------------------------


remote_state {
  backend = "consul"

  config = {
    address = "127.0.0.1:8500"
    scheme  = "http"
    # Key path in Consul KV where the state is stored
    path = "terraform/state/${basename(get_repo_root())}-tfstate-consul-mbp-home"  # eg homelab-infra-tfstate-consul-mbp-home
    # Consul supports locking for the backend
    lock = true
    gzip = true

  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}


# ---------------------------------------------------------------------------------------------------------------------
#  variables
#
# These variables apply to all configurations in this subfolder. These are automatically merged into the child
# `terragrunt.hcl` config via the include block.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Automatically load global (project scoped) variables
  global_vars = read_terragrunt_config("global.hcl", read_terragrunt_config(find_in_parent_folders("global.hcl", "does-not-exist.fallback"), { locals = {} }))

  proxmox_api_url   = local.global_vars.locals.proxmox_api_url
}




# ---------------------------------------------------------------------------------------------------------------------
# generate terraform provider.tf override
# ---------------------------------------------------------------------------------------------------------------------
# Generate vault_provider.tf
generate "vault_provider" {
  path      = "vault_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "vault" {
      # Defaults to http://127.0.0.1:8200
      # Or set via VAULT_ADDR env var
    }
    data "vault_kv_secret_v2" "proxmox" {
      mount = "kv"
      name  = "proxmox"
    }
    data "vault_kv_secret_v2" "tailscale" {
      mount = "kv"
      name  = "tailscale"
    }
  EOF
}

generate "proxmox_provider" {
  path      = "proxmox_provider.tf"
  if_exists = "skip"
  contents  = <<-EOF
    provider "proxmox" {
      pm_api_url          = "${local.proxmox_api_url}"
      pm_api_token_id     = data.vault_kv_secret_v2.proxmox.data["api-token-id"]
      pm_api_token_secret = data.vault_kv_secret_v2.proxmox.data["api-token-secret"]
      pm_debug = false
    }
  EOF
}

# generate "proxmox_module_versions_override" {
#   path      = "versions_override.tf"
#   if_exists = "overwrite_terragrunt"
#   contents  = <<-EOF
#     terraform {
#       required_providers {
#         proxmox = {
#           source  = "Telmate/proxmox"
#           version = "3.0.2-rc07"
#         }
#       }
#     }
#   EOF
# }
