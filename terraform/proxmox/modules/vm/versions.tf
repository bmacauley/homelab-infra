#-------------------------------------------------------------
# versions.tf
#
# Provider version constraints for VM module
#-------------------------------------------------------------

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc07"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0.0"
    }
  }
}
