#-------------------------------------------------------------
# outputs.tf
#
# VM module outputs
#-------------------------------------------------------------

output "id" {
  description = "VM resource ID"
  value       = proxmox_vm_qemu.vm.id
}

output "vmid" {
  description = "VM ID in Proxmox"
  value       = proxmox_vm_qemu.vm.vmid
}

output "name" {
  description = "VM name"
  value       = proxmox_vm_qemu.vm.name
}

output "target_node" {
  description = "Proxmox node where VM is running"
  value       = proxmox_vm_qemu.vm.target_node
}

output "default_ipv4_address" {
  description = "Default IPv4 address (requires qemu-guest-agent)"
  value       = proxmox_vm_qemu.vm.default_ipv4_address
}

output "default_ipv6_address" {
  description = "Default IPv6 address (requires qemu-guest-agent)"
  value       = proxmox_vm_qemu.vm.default_ipv6_address
}

output "ssh_host" {
  description = "SSH host for provisioning"
  value       = proxmox_vm_qemu.vm.ssh_host
}

output "ssh_port" {
  description = "SSH port for provisioning"
  value       = proxmox_vm_qemu.vm.ssh_port
}

output "mac_address" {
  description = "Primary network interface MAC address"
  value       = proxmox_vm_qemu.vm.network[0].macaddr
}
