#!/usr/bin/env bash
# ==============================================================================
# SE WORKSPACE RECOVERY & BOOTSTRAP ENGINE
# ==============================================================================
# Restores all repositories, SSH keys, configs, and backup automation on a fresh OS.
# Usage:
#   curl -sL https://raw.githubusercontent.com/devkumar70401/emergency-vault/main/restore.sh | bash
# ==============================================================================

set -euo pipefail

echo "============================================================"
echo "         SE WORKSPACE RESTORATION & BOOTSTRAP ENGINE        "
echo "============================================================"
echo "This script will restore your complete SE workspace, repositories,"
echo "SSH keys, and automated backup schedules onto this fresh OS."
echo ""

# 1. Check prerequisites
for cmd in curl openssl tar git; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "[-] ERROR: Required command '$cmd' is not installed."
    echo "    Please run: sudo apt update && sudo apt install -y curl openssl git"
    exit 1
  fi
done

# 2. Prompt for 3 passphrases (hidden input)
read -rsp "Enter Passphrase #3 (outermost shield): " PASS3
echo ""
read -rsp "Enter Passphrase #2 (middle shield): " PASS2
echo ""
read -rsp "Enter Passphrase #1 (innermost shield): " PASS1
echo ""

TEMP_DIR=$(mktemp -d /tmp/se_restore.XXXXXX)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "[+] Downloading encrypted vault from GitHub..."
curl -sL "https://raw.githubusercontent.com/devkumar70401/emergency-vault/main/vault.enc" -o "$TEMP_DIR/vault.enc"

if [[ ! -s "$TEMP_DIR/vault.enc" ]]; then
  echo "[-] ERROR: Downloaded vault is empty or unavailable!"
  exit 1
fi

echo "[+] Decrypting 3-layer AES-256-CBC payload..."
if ! (
  openssl enc -d -aes-256-cbc -pbkdf2 -iter 300000 -in "$TEMP_DIR/vault.enc" -pass pass:"$PASS3" | \
  openssl enc -d -aes-256-cbc -pbkdf2 -iter 300000 -pass pass:"$PASS2" | \
  openssl enc -d -aes-256-cbc -pbkdf2 -iter 300000 -pass pass:"$PASS1" | \
  tar -xz -C "$TEMP_DIR"
); then
  echo "[-] DECRYPTION FAILED: One or more passphrases were incorrect."
  exit 1
fi

echo "[+] Decryption successful! Deploying workspace to $HOME/se..."

# 3. Restore ~/se workspace
mkdir -p "$HOME/se"
if [[ -d "$TEMP_DIR/se" ]]; then
  cp -r "$TEMP_DIR/se/"* "$HOME/se/"
fi

# 4. Restore SSH keys if present in vault
if [[ -d "$TEMP_DIR/ssh_keys" ]]; then
  echo "[+] Restoring GitHub SSH keys..."
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  cp "$TEMP_DIR/ssh_keys/id_ed25519"* "$HOME/.ssh/" 2>/dev/null || true
  chmod 600 "$HOME/.ssh/id_ed25519" 2>/dev/null || true
  chmod 644 "$HOME/.ssh/id_ed25519.pub" 2>/dev/null || true
fi

# 5. Restore .vault_secrets if present
if [[ -f "$TEMP_DIR/.vault_secrets" ]]; then
  echo "[+] Restoring vault secrets configuration..."
  cp "$TEMP_DIR/.vault_secrets" "$HOME/.vault_secrets"
  chmod 600 "$HOME/.vault_secrets"
fi

# 6. Set up nightly cron job
echo "[+] Configuring automated nightly backup (2:00 AM)..."
CRON_LINE="0 2 * * * /bin/bash $HOME/se/sync_vault.sh >> $HOME/se/vault_sync.log 2>&1"
( crontab -l 2>/dev/null | grep -v "sync_vault.sh" ; echo "$CRON_LINE" ) | crontab -

# 7. Test SSH connection to GitHub
echo "[+] Testing GitHub SSH connection..."
ssh -o StrictHostKeyChecking=no -T git@github.com 2>&1 || true

echo ""
echo "============================================================"
echo " [SUCCESS] SE WORKSPACE IS FULLY RESTORED AND OPERATIONAL! "
echo "============================================================"
echo "Your repositories are in: $HOME/se"
echo "Nightly backups are enabled automatically."
