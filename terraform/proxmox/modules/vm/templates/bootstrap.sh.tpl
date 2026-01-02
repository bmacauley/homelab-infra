#!/bin/bash
set -e

# Update package lists
apt-get update -y

# Install base packages
apt-get install -y curl ansible avahi-daemon qemu-guest-agent ${additional_packages}

# Enable and start qemu-guest-agent
systemctl enable qemu-guest-agent
systemctl start qemu-guest-agent

%{ if enable_tailscale ~}
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
systemctl enable tailscaled
systemctl start tailscaled
%{ endif ~}

# Enable and start mDNS (Avahi)
systemctl enable avahi-daemon
systemctl start avahi-daemon

%{ if enable_tailscale && tailscale_auth_token != null ~}
# Authenticate Tailscale with token and enable SSH
tailscale up --authkey="${tailscale_auth_token}" --ssh --accept-risk=lose-ssh --accept-routes=false --hostname="${hostname}"
%{ endif ~}
