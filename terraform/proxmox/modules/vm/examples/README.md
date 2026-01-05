# Proxmox VM Module Examples

This directory contains example configurations for the Proxmox VM module.

## Examples

| Example | Description |
|---------|-------------|
| [minimal](./minimal) | Simplest possible VM configuration cloning from a template |
| [cloud-init](./cloud-init) | VM with cloud-init provisioning, Tailscale, and bootstrap |
| [iso-boot](./iso-boot) | VM booting from ISO for manual OS installation with UEFI |

## Usage

To run an example:

```bash
cd examples/<example-name>
terraform init
terraform plan
terraform apply
```

## Prerequisites

- A Proxmox cluster with API access configured
- For clone examples: A cloud-init ready template (e.g., `ubuntu-cloud-24.04`)
- For ISO examples: ISO images uploaded to Proxmox storage
- Vault secrets configured (if using Tailscale provisioning)

## Notes

- These examples use relative source paths (`../../`) for the module
- In production, use the full path: `${get_repo_root()}/terraform/proxmox/modules/vm`
- Adjust `proxmox_host`, storage names, and network bridges for your environment
