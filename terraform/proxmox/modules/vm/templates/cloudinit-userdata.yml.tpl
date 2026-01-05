#cloud-config
# Cloud-init user-data for VM provisioning

hostname: ${hostname}

# Ensure services are enabled and started
runcmd:
%{ if enable_tailscale ~}
  # Start Tailscale service (already installed in template)
  - systemctl enable tailscaled
  - systemctl start tailscaled
%{ if tailscale_auth_token != null && tailscale_auth_token != "" ~}
  # Authenticate to Tailscale
  - tailscale up --authkey="${tailscale_auth_token}" --ssh --accept-risk=lose-ssh --accept-routes=false --hostname="${hostname}"
%{ endif ~}
%{ endif ~}
  # Enable mDNS (avahi-daemon already installed in template)
  - systemctl enable avahi-daemon
  - systemctl start avahi-daemon
  # Ensure qemu-guest-agent is running
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
%{ for cmd in additional_runcmd ~}
  - ${cmd}
%{ endfor ~}
