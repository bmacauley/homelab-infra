#!/bin/bash
set -e

# Helper function to check if a package is installed
pkg_installed() {
  dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

# Update package lists
apt-get update -y

# Install base packages only if not already present
PACKAGES="curl qemu-guest-agent ${additional_packages}"
MISSING=""
for pkg in $PACKAGES; do
  if [ -n "$pkg" ] && ! pkg_installed "$pkg"; then
    MISSING="$MISSING $pkg"
  fi
done
if [ -n "$MISSING" ]; then
  apt-get install -y $MISSING
fi

# Enable and start qemu-guest-agent
systemctl enable qemu-guest-agent
systemctl start qemu-guest-agent || true

%{ if enable_tailscale ~}
# Install Tailscale only if not already installed
if ! command -v tailscale &>/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
systemctl enable tailscaled
systemctl start tailscaled || true
%{ endif ~}

# Enable and start mDNS (Avahi) if installed
if pkg_installed avahi-daemon; then
  systemctl enable avahi-daemon
  systemctl start avahi-daemon || true
fi

%{ if enable_tailscale && tailscale_auth_token != null ~}
# Authenticate Tailscale with token and enable SSH (skip if already authenticated)
if ! tailscale status &>/dev/null; then
  tailscale up --authkey="${tailscale_auth_token}" --ssh --accept-risk=lose-ssh --accept-routes=false --hostname="${hostname}"
fi
%{ endif ~}
