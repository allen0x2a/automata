# SSH Key Setup

Automates Ed25519 key generation, deployment, and `~/.ssh/config` management for passwordless SSH. Each target gets its own key named by hostname.

## Prerequisites

- NixOS (client)
- Ubuntu (target) with SSH server running
- Password access to the target (one-time, for key deployment)

## Usage

```bash
chmod +x ssh-key-setup.sh
./ssh-key-setup.sh <user> <ip> <hostname>
```

### Example: Multiple Targets

```bash
./ssh-key-setup.sh alice 192.168.1.50 homelab
./ssh-key-setup.sh deploy 10.0.0.5 staging
./ssh-key-setup.sh root 10.0.0.20 production
```

### After Setup

```bash
ssh homelab
scp ./file staging:/tmp/
ssh production "ls -la"
```

## What This Script Performs

1. Generates an Ed25519 key pair at `~/.ssh/<hostname>` (skips if exists)
2. Sets strict permissions on the key files
3. Deploys the public key to the target via `ssh-copy-id`
4. Adds a `Host` block to `~/.ssh/config` for automatic key selection
5. Verifies passwordless connectivity

## Example Result

```
~/.ssh/
├── config
├── staging
├── staging.pub
├── production
└── production.pub
```

```
# ~/.ssh/config (auto-generated)
Host homelab
    HostName 192.168.1.50
    User alice
    IdentityFile ~/.ssh/homelab
    IdentitiesOnly yes
```
