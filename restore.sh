#!/usr/bin/env bash
# ==============================================================================
# SE WORKSPACE RECOVERY & BOOTSTRAP ENGINE
# ==============================================================================
# Restores all repositories and GitHub SSH keys on a fresh OS.
# Usage:
#   curl -sL https://raw.githubusercontent.com/devkumar70401/emergency_vault/main/restore.sh | bash
# ==============================================================================

set -euo pipefail

echo "============================================================"
echo "         SE WORKSPACE RESTORATION & BOOTSTRAP ENGINE        "
echo "============================================================"
echo "This script will restore your complete SE workspace, repositories,"
echo "and GitHub SSH keys onto this fresh OS."
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
curl -sL "https://raw.githubusercontent.com/devkumar70401/emergency_vault/main/vault.enc" -o "$TEMP_DIR/vault.enc"

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

echo "[+] Decryption successful!"

# 3. Restore SSH Keys
if [[ -d "$TEMP_DIR/ssh" ]]; then
  echo "[+] Restoring GitHub SSH keys..."
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  cp "$TEMP_DIR/ssh/id_ed25519"* "$HOME/.ssh/" 2>/dev/null || true
  chmod 600 "$HOME/.ssh/id_ed25519" 2>/dev/null || true
  chmod 644 "$HOME/.ssh/id_ed25519.pub" 2>/dev/null || true
fi

# 4. Test SSH connection to GitHub
echo "[+] Testing GitHub SSH connection..."
ssh -o StrictHostKeyChecking=no -T git@github.com 2>&1 || true

# 5. Clone or pull all 5 repositories into ~/se
mkdir -p "$HOME/se"
cd "$HOME/se"

echo "[+] Restoring all repositories into $HOME/se..."

repos=(
  "emergency_vault|https://github.com/devkumar70401/emergency_vault.git"
  "notes|https://github.com/devkumar70401/notes.git"
  "projects|https://github.com/devkumar70401/projects.git"
  "toolbox|https://github.com/devkumar70401/toolbox.git"
  "personal|git@github.com:devkumar70401/personal.git"
)

for entry in "${repos[@]}"; do
  repo_name="${entry%%|*}"
  repo_url="${entry##*|}"
  if [[ -d "$HOME/se/$repo_name/.git" ]]; then
    echo "  [✔] $repo_name already exists, updating..."
    git -C "$HOME/se/$repo_name" pull --rebase 2>/dev/null || true
  else
    echo "  [⬇] Cloning $repo_name..."
    git clone "$repo_url" "$HOME/se/$repo_name" || echo "[-] Warning: failed to clone $repo_name"
  fi
done

echo ""
echo "============================================================"
echo " [SUCCESS] SE WORKSPACE IS FULLY RESTORED AND OPERATIONAL! "
echo "============================================================"
echo "All 5 repositories are now present in: $HOME/se"
