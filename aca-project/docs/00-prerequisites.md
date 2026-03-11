# Phase 00 — Prerequisites & Setup

| | |
|---|---|
| **Phase** | 00 |
| **Topic** | Prerequisites & Setup |
| **Services** | Azure CLI, PowerShell Az module |
| **Est. Cost** | None — nothing deployed |

---

## Navigation

[← Back to README](../README.md) | [Next: Phase 01 — Resource Groups →](01-resource-groups.md)

---

## What We're Building

Nothing in Azure yet. This phase gets your local tooling ready, authenticates you to Azure, and establishes the conventions we'll follow throughout the project. Getting this right means every phase after this runs cleanly.

---

## The Technology

### Azure CLI

The Azure CLI (`az`) is a cross-platform command-line tool that lets you manage Azure resources from a terminal. Every `az` command maps directly to an Azure REST API call — so when you run `az group create`, you're doing exactly what the portal does when you click "Create resource group", just faster and repeatably.

It outputs JSON by default, but supports `--output table` for readable terminal output and `--output tsv` for scripting.

**Why we use it:** It's the most direct and scriptable way to interact with Azure. It's also what most Azure documentation uses, so it's worth being fluent in it.

### PowerShell Az Module

The `Az` PowerShell module provides cmdlets (e.g. `New-AzResourceGroup`) that wrap the same Azure REST API. PowerShell works with objects rather than text, which makes it more powerful for scripting complex logic — filtering, looping, error handling.

**Why we use it:** Many enterprise environments are Windows-first and PowerShell-heavy. Knowing both CLI and PowerShell means you can work in any environment.

### How They Relate

Both tools do the same thing — they call the Azure API. The choice is usually personal preference or environment. This project documents both so you build fluency in each.

| | Azure CLI | PowerShell Az |
|---|---|---|
| Syntax | `az resource verb --flag` | `Verb-AzResource -Param` |
| Output | JSON / table / tsv | Objects |
| Scripting | Bash / shell | `.ps1` scripts |
| Cross-platform | Yes | Yes (PowerShell 7+) |

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

### What This Does

Both commands request an OAuth2 token from Entra ID (formerly Azure Active Directory). The CLI stores the token at `~/.azure/`, PowerShell holds it in memory. Tokens expire — if a session goes idle for a long time you may need to re-authenticate.

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
# List all subscriptions
Get-AzSubscription

# Confirm active context
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

Setting a default location saves you typing `--location eastus` on every command.

```bash
az configure --defaults location=eastus
```

> Replace `eastus` with your preferred region. Run `az account list-locations --output table` to see all options.

### Verify

```bash
az configure --list-defaults
```

> PowerShell has no equivalent — you'll pass `-Location` explicitly on each command.

---

## Step 5 — Check for Existing Resources

Before building anything, confirm what's already in your subscription:

```bash
az group list --output table
```

```powershell
Get-AzResourceGroup | Format-Table ResourceGroupName, Location, ProvisioningState
```

A clean subscription will show only `NetworkWatcherRG` (auto-created by Azure) or nothing at all. If you see other resource groups from previous work, make a note — they won't interfere but it's good to know they're there.

---

## Verification Checklist

Before moving to Phase 01, confirm all of the following:

- [ ] `az version` returns 2.x or higher
- [ ] `pwsh --version` returns 7.x or higher
- [ ] `az login` completed successfully
- [ ] `az account show` shows the correct subscription
- [ ] `az configure --list-defaults` shows `location = eastus` (or your chosen region)

---

## Gotchas & Lessons Learned

> *Updated: 2026-03-11*

**1. Az module installs per-user by default.** On Linux, `Install-PSResource Az` installs to `~/.local/share/powershell/Modules`. This is fine for personal use. For a shared or system-wide install, run `Install-PSResource Az -Scope AllUsers` as root.

**2. PowerShell alternative install method.** `Install-PSResource Az` is the modern replacement for `Install-Module -Name Az -Repository PSGallery -Force`. Both work — `Install-PSResource` is the preferred approach going forward.

**3. `Get-AzContext` shows "Azure subscription 1" not the subscription name.** This is a display quirk in the context Name field. The subscription ID and account details are correct — don't be thrown off by the label.

**4. Az 15.0.0 upgrade warning.** If PowerShell warns that Az 14.x is outdated and Az 15.0.0 is available, do not upgrade mid-project. Az 15.0.0 contains breaking changes from 14.x. Review the migration guide before upgrading and wait until between projects.

**5. Cached credentials mean login steps may not be interactive.** If you've previously authenticated, `az account show` and `Get-AzContext` will return valid sessions immediately — no browser flow is triggered. If you're on a fresh machine or tokens have expired, run `az login` and `Connect-AzAccount` to re-authenticate.

**6. Token expiry.** Azure CLI tokens expire after approximately 1 hour of inactivity. If commands start returning authentication errors mid-session, run `az login` again.

**7. NetworkWatcherRG is expected.** `az group list` will show a `NetworkWatcherRG` resource group that you didn't create. Azure Network Watcher creates this automatically. Do not delete it.

---

## Teardown

Nothing was deployed in this phase. No teardown required.

---

## Cost at This Phase

**Zero** — no Azure resources created.

---

## Navigation

[← Back to README](../README.md) | [Next: Phase 01 — Resource Groups →](01-resource-groups.md)
