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

generate "proxmox_module_versions_override" {
  path      = "versions_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_providers {
        proxmox = {
          source  = "Telmate/proxmox"
          version = "3.0.2-rc07"
        }
      }
    }
  EOF
}

generate "lxc_advanced_config" {
  path      = "lxc_advanced_config.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    variable "proxmox_host" {
      type    = string
      default = "proxmox.tailfb76f.ts.net"
    }

    locals {
      lxc_id = proxmox_lxc.lxc.vmid
    }

    resource "null_resource" "configure_lxc_tailscale" {
      depends_on = [proxmox_lxc.lxc]

      connection {
        type        = "ssh"
        host        = var.proxmox_host
        user        = "root"
        # private_key = file("~/.ssh/id_rsa") # access via tailscale
      }

      provisioner "remote-exec" {
        inline = [
          # Configure LXC features and TUN device (container must be stopped)
          "pct stop $${local.lxc_id} || true",
          "pct set $${local.lxc_id} --dev0 /dev/net/tun",
          "pct set $${local.lxc_id} --features keyctl=1,nesting=1",
          "pct start $${local.lxc_id}",

        ]
      }

      triggers = {
        container_id = proxmox_lxc.lxc.vmid
      }
    }
  EOF
}



generate "lxc_bootstrap_script_tpl" {
  path      = "lxc_bootstrap_script.sh.tpl"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y curl ansible avahi-daemon

    # Install Tailscale
    curl -fsSL https://tailscale.com/install.sh | sh
    systemctl enable tailscaled
    systemctl start tailscaled

    # Enable and start mDNS (Avahi)
   systemctl enable avahi-daemon 
    systemctl start avahi-daemon

    # Authenticate Tailscale with token and enable SSH
    tailscale up --authkey="$${tailscale_auth_token}" --ssh --accept-risk=lose-ssh --accept-routes=false --hostname="$${hostname}"
  EOF
}







generate "lxc_base_provisioner" {
  path      = "lxc_base_provisioner.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF

    locals {
      bootstrap_script = templatefile("$${path.module}/lxc_bootstrap_script.sh.tpl", {
        tailscale_auth_token = data.vault_kv_secret_v2.tailscale.data["auth-key"]
        hostname = var.lxc_name
      })
    }

    resource "local_file" "bootstrap_script" {
      content  = local.bootstrap_script
      filename = "$${path.module}/bootstrap_script.sh"
    }

    resource "null_resource" "base_provisioner" {
          depends_on = [null_resource.configure_lxc_tailscale, local_file.bootstrap_script]

          triggers = {
            lxc_id       = proxmox_lxc.lxc.vmid
            proxmox_host = var.proxmox_host
          }

          connection {
            type        = "ssh"
            host        = self.triggers.proxmox_host
            user        = "root"
          }

          # Copy script to Proxmox host first
          provisioner "file" {
            source      = local_file.bootstrap_script.filename
            destination = "/tmp/bootstrap_script_$${local.lxc_id}.sh"
          }

          # Push script into LXC container and execute it
          provisioner "remote-exec" {
            inline = [
              "pct push $${local.lxc_id} /tmp/bootstrap_script_$${local.lxc_id}.sh /tmp/bootstrap_script.sh",
              "pct exec $${local.lxc_id} -- chmod +x /tmp/bootstrap_script.sh",
              "pct exec $${local.lxc_id} -- /tmp/bootstrap_script.sh",
            ]
          }

          # Logout of Tailscale on destroy
          provisioner "remote-exec" {
            when = destroy

            connection {
              type        = "ssh"
              host        = self.triggers.proxmox_host
              user        = "root"
            }

            inline = [
              "pct exec $${self.triggers.lxc_id} -- tailscale logout || true",
            ]
          }
        }
  EOF
}
