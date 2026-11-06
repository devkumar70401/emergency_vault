# 🚨 Emergency Vault

A disaster recovery system designed to restore your complete development workspace onto any blank terminal in the world with zero saved configuration, using only your memory and 3 secret passphrases.

---

## 🛠️ How to Arm / Update Vault

Whenever you update your credentials or SSH keys on your workstation:

```bash
cd ~/se/emergency_vault
./backup_vault.sh
```

You will be prompted to enter your 3 memorized passphrases:
- **Passphrase #1**: Innermost encryption shield
- **Passphrase #2**: Middle encryption shield
- **Passphrase #3**: Outermost encryption shield

The script compresses your keys, wraps them in 3-layer `AES-256-CBC` encryption via OpenSSL PBKDF2 (300,000 iterations), and pushes `vault.enc` directly to GitHub.

---

## 🌍 How to Restore on Any Blank Computer

On any Linux/Unix terminal anywhere in the world:

```bash
curl -sL https://raw.githubusercontent.com/devkumar70401/emergency_vault/main/restore.sh | bash
```

1. Enter your 3 passphrases in reverse order (#3, #2, #1).
2. The payload is verified and decrypted.
3. Your SSH keys are restored to `~/.ssh/`.
4. All 5 workspace repositories (`notes`, `projects`, `toolbox`, `emergency_vault`, and private `personal`) are automatically cloned into `~/se/`.
