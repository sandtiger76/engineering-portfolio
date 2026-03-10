# Ansible Vault — Secrets Management

[← Back to README](../../README.md) | [← SSL Certificate Setup](ssl-certificates.md)

---

## What Is It?

Ansible Vault is a built-in feature of Ansible that encrypts sensitive values — passwords, API tokens, private keys — so they can be safely stored in version control alongside the rest of the infrastructure code.

Without secrets management, the common (bad) practice is to hardcode credentials in configuration files or leave them in environment variables. Ansible Vault solves this by encrypting the values with a password, making the repository safe to publish without exposing secrets.

**Why it's in this project:** It is the difference between amateur and professional infrastructure code. Any repository that contains plaintext credentials is a security liability. Ansible Vault is the lightweight, built-in solution for this.

---

## Why We Need It

This project handles several sensitive credentials:

| Secret | Used By |
|---|---|
| Proxmox API token | Ansible LXC provisioning |
| Cloudflare API token | DDNS, Certbot DNS challenge |
| Tailscale auth key | Unattended device enrollment |
| PostgreSQL passwords | Nextcloud, Gitea database access |
| Nextcloud admin password | Initial platform setup |
| Gitea admin password | Initial repository setup |

None of these should ever appear in plaintext in the repository.

---

## Technical Implementation

### Vault File Structure

```
ansible/
└── group_vars/
    └── all/
        ├── vars.yml          # Non-sensitive variables (plaintext)
        └── vault.yml         # Sensitive variables (encrypted)
```

### Creating the Vault

```bash
# Create and encrypt the vault file
ansible-vault create ansible/group_vars/all/vault.yml
```

### Example Vault Contents

```yaml
# ansible/group_vars/all/vault.yml (encrypted at rest)
proxmox_api_token_secret: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
cloudflare_api_token: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
tailscale_auth_key: "tskey-auth-xxxxxxxxxxxxxx"
postgres_root_password: "ChangeMe_StrongPassword_123!"
nextcloud_db_password: "ChangeMe_StrongPassword_456!"
nextcloud_admin_password: "ChangeMe_StrongPassword_789!"
gitea_db_password: "ChangeMe_StrongPassword_012!"
gitea_admin_password: "ChangeMe_StrongPassword_345!"
admin_email: "your@email.com"
```

### Running Playbooks with Vault

```bash
# Prompt for vault password at runtime
ansible-playbook ansible/site.yml -i ansible/inventory/hosts.yml --ask-vault-pass

# Or use a password file (never commit this file)
ansible-playbook ansible/site.yml -i ansible/inventory/hosts.yml --vault-password-file ~/.vault_pass
```

### .gitignore

The vault password file is excluded from Git:

```gitignore
.vault_pass
*.vault_pass
```

---

## Gotchas & Notes

- The vault password is the one secret that cannot be stored in the vault itself — store it in a password manager (Bitwarden, 1Password, etc.)
- `ansible-vault view vault.yml` decrypts and displays the contents without editing
- `ansible-vault rekey vault.yml` changes the encryption password if needed
- A `vault.yml.example` file with placeholder values is committed to the repository so new users know what secrets are required

---

[Next: Monitoring →](../operations/monitoring.md)
