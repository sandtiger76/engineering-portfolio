# Phase 00 — Prerequisites & Setup

**AZ-104 Domain:** All | **Services:** Azure CLI, PowerShell Az module

---

## Navigation

[README](../README.md) &nbsp;|&nbsp; [Phase 01 →](01-resource-groups.md)

---

## What We're Building

Nothing in Azure yet. This phase gets your local tooling ready, authenticates you to Azure, and establishes the conventions followed throughout the project. Getting this right means every phase after this runs cleanly.

---

## The Technology

### Azure CLI

The Azure CLI (`az`) is a cross-platform command-line tool for managing Azure resources from a terminal. Every `az` command maps directly to an Azure REST API call — so `az group create` does exactly what clicking "Create resource group" in the portal does, just faster and repeatably.

It outputs JSON by default, but supports `--output table` for readable terminal output and `--output tsv` for scripting.

### PowerShell Az Module

The `Az` PowerShell module provides cmdlets (e.g. `New-AzResourceGroup`) that wrap the same Azure REST API. PowerShell works with objects rather than text, making it more powerful for complex scripting — filtering, looping, error handling.

Many enterprise environments are Windows-first and PowerShell-heavy. Knowing both CLI and PowerShell means you can work in any environment.

| | Azure CLI | PowerShell Az |
|---|---|---|
| Syntax | `az resource verb --flag` | `Verb-AzResource -Param` |
| Output | JSON / table / tsv | Objects |
| Scripting | Bash / shell | `.ps1` scripts |
| Cross-platform | Yes | Yes (PowerShell 7+) |

Both tools call the same Azure API. The choice is usually personal preference or environment constraint. This project documents both throughout.

---

## Step 1 — Verify Tools Are Installed

### Azure CLI

```bash
az version
```

Expected output includes `"azure-cli": "2.x.x"`. If not installed:

```bash
# Debian/Ubuntu/Mint
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### PowerShell

```bash
pwsh --version
```

Expected: `PowerShell 7.x.x`. If not installed:

```bash
# Debian/Ubuntu/Mint
sudo apt-get install -y powershell
```

### Az PowerShell Module

```powershell
Get-Module -Name Az.Accounts -ListAvailable
```

If not installed:

```powershell
Install-Module -Name Az -Repository PSGallery -Force
```

> If prompted about an untrusted repository, type `Y` to continue.

---

## Step 2 — Authenticate

### Azure CLI

```bash
az login
```

This opens a browser. Sign in with your Azure account. Once complete, your terminal shows your available subscriptions.

### PowerShell

```powershell
Connect-AzAccount
```

Same browser-based flow. Stores credentials in-memory for the session.

---

## Step 3 — Confirm Your Subscription

### Azure CLI

```bash
# List all subscriptions
az account list --output table

# Confirm active subscription
az account show --output table
```

### PowerShell

```powershell
Get-AzSubscription
Get-AzContext
```

If you have multiple subscriptions, set the correct one:

```bash
# CLI
az account set --subscription "<your-subscription-name-or-id>"
```

```powershell
# PowerShell
Set-AzContext -SubscriptionName "<your-subscription-name>"
```

---

## Step 4 — Set Default Region (CLI)

Setting a default location saves typing `--location eastus` on every command.

```bash
az configure --defaults location=eastus
```

Replace `eastus` with your preferred region. Run `az account list-locations --output table` to see all options.

```bash
# Verify
az configure --list-defaults
```

> PowerShell has no equivalent — pass `-Location` explicitly on each command.

---

## Step 5 — Check for Existing Resources

```bash
az group list --output table
```

```powershell
Get-AzResourceGroup | Format-Table ResourceGroupName, Location, ProvisioningState
```

A clean subscription shows only `NetworkWatcherRG` (auto-created by Azure) or nothing at all.

---

## Verification Checklist

- [ ] `az version` returns 2.x or higher
- [ ] `pwsh --version` returns 7.x or higher
- [ ] `az login` completed successfully
- [ ] `az account show` shows the correct subscription
- [ ] `az configure --list-defaults` shows `location = eastus`

---

## Gotchas & Lessons Learned

> *Updated: 2026-03-11*

**1. Az module installs per-user by default.** On Linux, `Install-PSResource Az` installs to `~/.local/share/powershell/Modules`. For a shared or system-wide install, run `Install-PSResource Az -Scope AllUsers` as root.

**2. `Install-PSResource Az` is the modern replacement** for `Install-Module -Name Az -Repository PSGallery -Force`. Both work — `Install-PSResource` is the preferred approach going forward.

**3. `Get-AzContext` shows "Azure subscription 1" not the subscription name.** This is a display quirk. The subscription ID and account details are correct.

**4. Az 15.0.0 contains breaking changes from 14.x.** If PowerShell warns that an upgrade is available, do not upgrade mid-project. Review the migration guide before upgrading.

**5. Cached credentials mean login steps may not be interactive.** If you've previously authenticated, `az account show` and `Get-AzContext` return valid sessions immediately. If tokens have expired, run `az login` and `Connect-AzAccount` to re-authenticate.

**6. Token expiry.** Azure CLI tokens expire after approximately 1 hour of inactivity. If commands start returning authentication errors mid-session, run `az login` again.

**7. NetworkWatcherRG is expected.** Azure Network Watcher creates this automatically. Do not delete it.

---

## Navigation

[README](../README.md) &nbsp;|&nbsp; [Phase 01 →](01-resource-groups.md)
