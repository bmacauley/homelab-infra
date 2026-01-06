#!/bin/bash
set -e

# Helper function to check if a package is installed
pkg_installed() {
  dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

# Update package lists
apt-get update -y

# Install base packages only if not already present
PACKAGES="curl ansible avahi-daemon git ${additional_packages}"
MISSING=""
for pkg in $PACKAGES; do
  if [ -n "$pkg" ] && ! pkg_installed "$pkg"; then
    MISSING="$MISSING $pkg"
  fi
done
if [ -n "$MISSING" ]; then
  apt-get install -y $MISSING
fi

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

%{ if enable_ansible_pull && ansible_pull_repo != null ~}
#-------------------------------------------------------------
# Ansible Pull Configuration
#-------------------------------------------------------------
echo "Running ansible-pull from ${ansible_pull_repo}..."

# Create checkout directory
mkdir -p ${ansible_pull_checkout_dir}

%{ if ansible_pull_vault_password != null ~}
# Write vault password file
echo "${ansible_pull_vault_password}" > /tmp/.ansible_vault_pass
chmod 600 /tmp/.ansible_vault_pass
VAULT_ARGS="--vault-password-file=/tmp/.ansible_vault_pass"
%{ else ~}
VAULT_ARGS=""
%{ endif ~}

# Build extra vars argument
%{ if length(ansible_pull_extra_vars) > 0 ~}
EXTRA_VARS="-e '${join("' -e '", [for k, v in ansible_pull_extra_vars : "${k}=${v}"])}'"
%{ else ~}
EXTRA_VARS=""
%{ endif ~}

# Run ansible-pull
ansible-pull \
  --url="${ansible_pull_repo}" \
  --checkout="${ansible_pull_branch}" \
  --directory="${ansible_pull_checkout_dir}" \
  --full \
  $VAULT_ARGS \
  $EXTRA_VARS \
  ${ansible_pull_playbook}

%{ if ansible_pull_vault_password != null ~}
# Cleanup vault password file
rm -f /tmp/.ansible_vault_pass
%{ endif ~}

echo "ansible-pull completed successfully"
%{ endif ~}
