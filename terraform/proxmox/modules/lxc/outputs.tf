#-------------------------------------------------------------
# outputs.tf
#
# LXC module outputs
#-------------------------------------------------------------

output "id" {
  description = "Container ID"
  value       = proxmox_lxc.lxc.id
}

output "vmid" {
  description = "Container VMID"
  value       = proxmox_lxc.lxc.vmid
}

output "hostname" {
  description = "Container hostname"
  value       = proxmox_lxc.lxc.hostname
}

output "mac_address" {
  description = "Container MAC Address"
  value       = proxmox_lxc.lxc.network[0].hwaddr
}

output "ip_address" {
  description = "Container IPv4 Address configuration"
  value       = proxmox_lxc.lxc.network[0].ip
}

output "target_node" {
  description = "Proxmox node where container is running"
  value       = proxmox_lxc.lxc.target_node
}
