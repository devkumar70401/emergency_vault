#!/usr/bin/env bash
# ==============================================================================
# 🔐 EMERGENCY VAULT PACKAGER & ENCRYPTION ENGINE
# ==============================================================================
# Packages your SSH keys & identity into a 3-layer AES-256-CBC encrypted vault.enc
# and pushes it to GitHub.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_ENC="$SCRIPT_DIR/vault.enc"
TMP_DIR="$(mktemp -d /tmp/emergency_vault_staging.XXXXXX)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "============================================================"
echo "      EMERGENCY VAULT PACKAGER & ENCRYPTION ENGINE          "
echo "============================================================"
echo "This will package your GitHub SSH credentials into a secure,"
echo "3-layer AES-256 encrypted payload and push it to GitHub."
echo ""

# Check prerequisites
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  echo "[-] ERROR: $HOME/.ssh/id_ed25519 not found!"
  exit 1
fi

mkdir -p "$TMP_DIR/ssh"
cp -a "$HOME/.ssh/id_ed25519"* "$TMP_DIR/ssh/"

# Prompt for 3 passphrases if not passed in environment
if [ -z "${PASS1:-}" ]; then
  read -rsp "Enter Passphrase #1 (innermost shield): " PASS1
  echo ""
  read -rsp "Confirm Passphrase #1: " PASS1_CONFIRM
  echo ""
  if [ "$PASS1" != "$PASS1_CONFIRM" ]; then
    echo "[-] Passphrase #1 mismatch! Aborting."
    exit 1
  fi
fi

if [ -z "${PASS2:-}" ]; then
  read -rsp "Enter Passphrase #2 (middle shield): " PASS2
  echo ""
  read -rsp "Confirm Passphrase #2: " PASS2_CONFIRM
  echo ""
  if [ "$PASS2" != "$PASS2_CONFIRM" ]; then
    echo "[-] Passphrase #2 mismatch! Aborting."
    exit 1
  fi
fi

if [ -z "${PASS3:-}" ]; then
  read -rsp "Enter Passphrase #3 (outermost shield): " PASS3
  echo ""
  read -rsp "Confirm Passphrase #3: " PASS3_CONFIRM
  echo ""
  if [ "$PASS3" != "$PASS3_CONFIRM" ]; then
    echo "[-] Passphrase #3 mismatch! Aborting."
    exit 1
  fi
fi

echo "[+] Compressing and applying 3-layer AES-256-CBC encryption..."
tar -cz -C "$TMP_DIR" . | \
  openssl enc -aes-256-cbc -pbkdf2 -iter 300000 -pass pass:"$PASS1" | \
  openssl enc -aes-256-cbc -pbkdf2 -iter 300000 -pass pass:"$PASS2" | \
  openssl enc -aes-256-cbc -pbkdf2 -iter 300000 -pass pass:"$PASS3" \
  > "$VAULT_ENC"

chmod 600 "$VAULT_ENC"
echo "[✔] Encrypted vault created successfully: $VAULT_ENC ($(du -h "$VAULT_ENC" | cut -f1))"

echo "[+] Committing and pushing vault.enc to GitHub..."
cd "$SCRIPT_DIR"
git add vault.enc restore.sh backup_vault.sh README.md
git commit -m "Update emergency vault payload and bootstrap engine" || echo "No changes to commit"
git push origin main

echo ""
echo "============================================================"
echo " [SUCCESS] EMERGENCY VAULT IS LIVE & ARMED ON GITHUB!       "
echo "============================================================"
echo "Anywhere in the world, on any blank terminal, run:"
echo ""
echo "  curl -sL https://raw.githubusercontent.com/devkumar70401/emergency_vault/main/restore.sh | bash"
echo ""
echo "Then enter your 3 passphrases to restore your entire workspace."
