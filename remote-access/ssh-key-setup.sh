#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: ssh-key-setup.sh
#
# DESCRIPTION:
#   Automates SSH key generation (Ed25519) on NixOS and deploys it to an
#   Ubuntu target for passwordless login. Uses per-target keys named by
#   hostname and configures ~/.ssh/config for automatic key selection.
#
# HOW TO RUN THIS SCRIPT:
#   1. chmod +x ssh-key-setup.sh
#   2. ./ssh-key-setup.sh <REMOTE_USER> <REMOTE_IP> <HOSTNAME>
#      Example: ./ssh-key-setup.sh alice 192.168.1.50 homelab
#               ./ssh-key-setup.sh deploy 10.0.0.5 staging
#
# HOW TO USE SSH AFTER CONFIGURATION (Examples):
#   - Connect:           ssh <HOSTNAME>
#   - Copy File:         scp ./file <HOSTNAME>:/tmp/
#   - Remote Command:    ssh <HOSTNAME> "ls -la"
#
# NOTES:
#   - On first run, you will be prompted to confirm the remote host key.
#   - You will be prompted for the Ubuntu password once during key deployment.
#   - After setup, all connections are passwordless via the hostname alias.
# ==============================================================================
set -euo pipefail

# --- Variables ---
TARGET_USER="${1:-}"
TARGET_IP="${2:-}"
TARGET_HOSTNAME="${3:-}"
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"

# --- Input Validation ---
if [[ -z "$TARGET_USER" || -z "$TARGET_IP" || -z "$TARGET_HOSTNAME" ]]; then
    echo "Error: Missing arguments."
    echo "Usage: $0 <username> <ip_address> <hostname>"
    echo "Example: $0 alice 192.168.1.50 homelab"
    exit 1
fi

# Sanitize hostname for use as filename (alphanumeric, hyphens, underscores only)
SAFE_HOSTNAME=$(echo "$TARGET_HOSTNAME" | tr -cd '[:alnum:]-_')
if [[ -z "$SAFE_HOSTNAME" ]]; then
    echo "Error: Hostname contains no valid characters after sanitization."
    exit 1
fi

KEY_PATH="$SSH_DIR/${SAFE_HOSTNAME}"
KEY_PUB="${KEY_PATH}.pub"

echo "=== SSH Setup: NixOS → ${TARGET_USER}@${TARGET_IP} (${TARGET_HOSTNAME}) ==="

# --- Step 1/5: Generate Key Pair ---
if [[ ! -f "$KEY_PATH" ]]; then
    echo "[Step 1/5] Generating Ed25519 key pair for '${TARGET_HOSTNAME}'..."
    ssh-keygen -t ed25519 -f "$KEY_PATH" -C "nixos-to-${SAFE_HOSTNAME}-$(date +%Y%m%d)" -N ""
    echo "  Key created at $KEY_PATH"
else
    echo "[Step 1/5] Key already exists at $KEY_PATH. Skipping generation."
fi

# --- Step 2/5: Set Strict Permissions ---
echo "[Step 2/5] Setting directory and key permissions..."
chmod 700 "$SSH_DIR"
chmod 600 "$KEY_PATH"
chmod 644 "$KEY_PUB"

# --- Step 3/5: Deploy Key to Ubuntu ---
echo "[Step 3/5] Deploying public key to ${TARGET_USER}@${TARGET_IP}..."
echo "  (You will be prompted for the Ubuntu password one last time)"

if command -v ssh-copy-id &>/dev/null; then
    ssh-copy-id -i "$KEY_PUB" "${TARGET_USER}@${TARGET_IP}"
else
    echo "  ssh-copy-id not found, using nix-shell fallback..."
    nix-shell -p openssh --run "ssh-copy-id -i '${KEY_PUB}' '${TARGET_USER}@${TARGET_IP}'"
fi

echo "  Key deployed successfully."

# --- Step 4/5: Configure SSH Config ---
echo "[Step 4/5] Updating ${SSH_CONFIG}..."

# Create config file if it doesn't exist
touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

# Check if a Host block for this hostname already exists
if grep -qP "^Host\s+${SAFE_HOSTNAME}\s*$" "$SSH_CONFIG" 2>/dev/null; then
    echo "  Host block for '${SAFE_HOSTNAME}' already exists. Skipping."
    echo "  (Delete the existing block manually if you need to update it)"
else
    # Ensure file ends with a newline before appending
    [[ -s "$SSH_CONFIG" && "$(tail -c 1 "$SSH_CONFIG")" != "" ]] && echo "" >> "$SSH_CONFIG"

    cat >> "$SSH_CONFIG" <<EOF

Host ${SAFE_HOSTNAME}
    HostName ${TARGET_IP}
    User ${TARGET_USER}
    IdentityFile ${KEY_PATH}
    IdentitiesOnly yes
EOF
    echo "  Added Host block for '${SAFE_HOSTNAME}'."
fi

# --- Step 5/5: Verify Connection ---
echo "[Step 5/5] Verifying passwordless SSH connection..."

if ssh -o BatchMode=yes -o ConnectTimeout=5 \
    "${SAFE_HOSTNAME}" "echo 'Success: Logged into \$(hostname) as \$(whoami)'"; then
    echo ""
    echo "=== Setup Complete ==="
    echo "Connect with:    ssh ${SAFE_HOSTNAME}"
    echo "Copy files:      scp ./file ${SAFE_HOSTNAME}:/tmp/"
    echo "Run command:     ssh ${SAFE_HOSTNAME} \"ls -la\""
else
    echo ""
    echo "ERROR: Verification failed. Possible causes:"
    echo "  - The remote SSH server may not be running"
    echo "  - Key was not correctly installed on the target"
    echo "  - Firewall blocking port 22"
    echo "  - sshd_config on target may not allow PubkeyAuthentication"
    exit 1
fi
