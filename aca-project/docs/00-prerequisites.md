# Phase 00 — Prerequisites & Setup

> Before building anything in Azure, we need the right tools installed, a verified subscription, and a clear set of conventions to keep everything consistent.

---

## What We're Setting Up

- Azure CLI installed and authenticated
- PowerShell 7+ with the Az module
- Subscription confirmed and default region set
- Naming conventions agreed (see README)
- A baseline understanding of how CLI and PowerShell relate

---

## Step 1 — Install Azure CLI

### Why
The Azure CLI is a cross-platform command-line tool for managing Azure resources. It's the most direct way to interact with Azure outside the portal, and every command maps 1:1 with the underlying REST API.

### Install (Windows)
```powershell
winget install Microsoft.AzureCLI
```

### Install (macOS/Linux)
```bash
brew install azure-cli
# or
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### Verify
```bash
az version
```

---

## Step 2 — Install PowerShell 7+

### Why
PowerShell 5.1 (built into Windows) works but is limited. PowerShell 7+ is cross-platform, faster, and required for some Az module features.

### Install
```bash
# Windows (winget)
winget install Microsoft.PowerShell

# macOS
brew install powershell/tap/powershell
```

### Verify
```powershell
$PSVersionTable.PSVersion
```

---

## Step 3 — Install the Az PowerShell Module

### Why
The `Az` module provides PowerShell cmdlets that wrap the Azure REST API — the PowerShell equivalent of the Azure CLI.

### PowerShell
```powershell
Install-Module -Name Az -Repository PSGallery -Force
```

> If prompted about an untrusted repository, type `Y` to continue.

### Verify
```powershell
Get-Module -Name Az -ListAvailable | Select-Object Name, Version
```

---

## Step 4 — Authenticate to Azure

### Why
Both tools need to know who you are before they can do anything. Authentication opens a browser window and stores a token locally.

### Azure CLI
```bash
az login
```

### PowerShell
```powershell
Connect-AzAccount
```

### What This Does
Both commands open a browser-based login flow. Once authenticated, they store a local token valid for your session. The CLI stores credentials in `~/.azure/`, PowerShell stores them in-memory per session.

---

## Step 5 — Confirm Your Subscription

### Why
If you have multiple subscriptions, you need to make sure commands run against the right one.

### Azure CLI
```bash
# List all subscriptions
az account list --output table

# Set the active subscription
az account set --subscription "<your-subscription-id>"

# Confirm
az account show
```

### PowerShell
```powershell
# List all subscriptions
Get-AzSubscription

# Set the active subscription
Set-AzContext -SubscriptionId "<your-subscription-id>"

# Confirm
Get-AzContext
```

---

## Step 6 — Set Default Region (CLI only)

### Why
Setting a default location means you don't have to type `--location uksouth` on every command. PowerShell doesn't have an equivalent — you'll always pass `-Location` explicitly.

### Azure CLI
```bash
az configure --defaults location=uksouth
```

### Verify
```bash
az configure --list-defaults
```

---

## Step 7 — Understand the Relationship Between CLI and PowerShell

Both tools do the same thing — they call the Azure REST API. The main differences:

| | Azure CLI | PowerShell (Az) |
|---|---|---|
| **Syntax** | `az resource verb --flag value` | `Verb-AzResource -Parameter Value` |
| **Output** | JSON by default (also table, tsv) | Objects (pipe-friendly) |
| **Scripting** | Bash / shell scripts | PowerShell scripts (.ps1) |
| **Learning curve** | Slightly easier to start | More verbose but more powerful for scripting |
| **Cross-platform** | Yes | Yes (PowerShell 7+) |

> **QCB approach:** We document both side-by-side so you build an intuition for how they map to each other. In practice, use whichever feels natural — they're equivalent.

---

## Step 8 — Install Git and Create the Repo

### Why
Every change should be version-controlled. You'll also push your documentation and scripts here as the project progresses.

### CLI
```bash
# Check if git is installed
git --version

# Clone (after creating the repo on GitHub)
git clone https://github.com/<your-username>/qcb-azure-lab.git
cd qcb-azure-lab
```

---

## Verification Checklist

Before moving to Phase 01, confirm all of the following:

```bash
# Azure CLI version (should be 2.x or higher)
az version

# Logged in and correct subscription active
az account show --query "{Name:name, ID:id, State:state}" --output table

# Default region set
az configure --list-defaults
```

```powershell
# PowerShell version (should be 7+)
$PSVersionTable.PSVersion

# Az module installed
Get-Module -Name Az.Accounts -ListAvailable

# Authenticated
Get-AzContext
```

---

## Cost at This Phase

**£0.00** — Nothing has been deployed to Azure yet.

---

## Next Phase

➡️ [Phase 01 — Resource Groups & Subscription Management](01-resource-groups.md)
