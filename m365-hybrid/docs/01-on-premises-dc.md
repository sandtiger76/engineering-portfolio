[← README — Project Overview](../README.md) &nbsp;|&nbsp; [🏠 README](../README.md) &nbsp;|&nbsp; [02 — AD Provisioning Scripts →](02-ad-scripts.md)

---

# 01 — On-Premises Infrastructure

## Overview — What This Document Covers

Before a business can use Microsoft 365 or any cloud service, it needs a reliable foundation for managing who its people are. In the Microsoft world, that foundation is called Active Directory — a central directory that holds every user account, every computer, and every permission in the organisation.

This document covers setting up a Windows Server that acts as the organisation's identity anchor. Think of it as the master phonebook for the business — every user account is created here first, and from here it gets synchronised into the cloud. The server also handles DNS, which is the system that translates names like "qcbhomelab.online" into the actual network addresses computers use to talk to each other.

This is the starting point for everything else in the project. Without this server running correctly, nothing that follows — cloud identities, email, Teams, device management — will work properly.

---

## Introduction

Most organisations that use Microsoft 365 in the cloud still have some form of on-premises Windows Server infrastructure. The reason is identity. When a company has years of user accounts, passwords, and permissions stored in Active Directory on a local server, they do not simply abandon that when moving to the cloud. Instead, they connect the two environments together — this is called a hybrid identity model.

Active Directory (AD) is Microsoft's directory service. Think of it as the master list of everyone in the organisation: who they are, what groups they belong to, what computers they use, and what they are allowed to access. It has been the backbone of Windows-based IT environments for over two decades.

In this project, a single Windows Server 2022 domain controller acts as the identity anchor. It runs Active Directory and DNS (the service that translates names like qcbhomelab.online into network addresses). All user accounts are created here first, then synchronised to Microsoft Entra ID in the cloud — covered in document 04.

---

## What We Are Building

| Item                   | Value                                     |
| ---------------------- | ----------------------------------------- |
| Server name            | QCBHC-DC01                                |
| Operating system       | Windows Server 2022 Standard (Evaluation) |
| Roles                  | Active Directory Domain Services, DNS     |
| Forest and domain name | qcbhomelab.online                         |
| NetBIOS name           | QCBHOMELAB                                |

The server runs as a virtual machine — either in Proxmox, Hyper-V, or VirtualBox depending on your lab setup. It does not need to be powerful. 2 vCPUs, 4 GB RAM, and a 60 GB disk is sufficient.

---

## Infrastructure Diagram

The diagram below shows how QCBHC-DC01 fits into the lab network and how DNS resolution works — internal queries are handled locally, all other queries are forwarded upstream.

```mermaid
graph TB
    subgraph LAB["🏠  Lab Network (192.168.1.0/24)"]
        subgraph VM["QCBHC-DC01 — 192.168.1.10"]
            ADDS["Active Directory\nDomain Services\nqcbhomelab.online"]
            DNS["DNS Server\n127.0.0.1"]
            ADDS <--> DNS
        end
        WS1["WS-LDN-CARTER\n192.168.1.x"]
        WS2["WS-LDN-BROWN\n192.168.1.x"]
        GW["Router / Gateway\n192.168.1.1"]
    end

    subgraph UPSTREAM["🌐  Internet"]
        CF["Cloudflare DNS\n1.1.1.1"]
        GG["Google DNS\n8.8.8.8"]
    end

    WS1 -->|"DNS queries"| DNS
    WS2 -->|"DNS queries"| DNS
    DNS -->|"internal: resolves locally\nqcbhomelab.online"| ADDS
    DNS -->|"external: forwards\ngoogle.com, etc."| CF
    DNS -->|"fallback forwarder"| GG
    GW --> UPSTREAM
```

---

## DNS Resolution Flow

```mermaid
flowchart LR
    Q["Client DNS query"] --> DC{"Is it\nqcbhomelab.online?"}
    DC -->|"Yes — internal"| AD["AD DNS\nresolves locally"]
    DC -->|"No — external"| FWD["Forward to\n1.1.1.1 or 8.8.8.8"]
    AD --> ANS["Answer returned\nto client"]
    FWD --> ANS
```

---

## Implementation Steps

### Step 1 — Create the Virtual Machine

Create a new VM with the following minimum specifications:

- 2 vCPUs
- 4 GB RAM
- 60 GB disk
- Network adapter connected to your LAN or a host-only network with internet access

Attach the Windows Server 2022 evaluation ISO and install the OS. Select "Standard with Desktop Experience" when prompted for the edition. Complete the installation and set a strong local Administrator password.

### Step 2 — Configure a Static IP Address

A domain controller must have a static IP address. Open Network and Sharing Centre, go to the network adapter properties, and set the following:

- IP address: choose an appropriate address for your lab network (e.g. 192.168.1.10)
- Subnet mask: 255.255.255.0
- Default gateway: your router address
- Preferred DNS: 127.0.0.1 (the server will become its own DNS server after promotion)

### Step 3 — Rename the Server

Open PowerShell as Administrator and run:

```powershell
Rename-Computer -NewName "QCBHC-DC01" -Restart
```

The server will restart. Log back in as Administrator.

### Step 4 — Install the AD DS Role

```powershell
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
```

This installs Active Directory Domain Services and all the management tools needed to administer it.

### Step 5 — Promote the Server to Domain Controller

```powershell
Install-ADDSForest `
    -DomainName "qcbhomelab.online" `
    -DomainNetbiosName "QCBHOMELAB" `
    -ForestMode "WinThreshold" `
    -DomainMode "WinThreshold" `
    -InstallDns:$true `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "YourDSRMPassword123!" -AsPlainText -Force) `
    -Force
```

The server will restart automatically once promotion completes. When it comes back up, log in with QCBHOMELAB\Administrator.

> The Safe Mode Administrator Password (DSRM password) is used to recover Active Directory if something goes wrong. Store it securely — it is separate from the normal Administrator password.

### Step 6 — Verify the Installation

Open PowerShell and confirm Active Directory is running correctly:

```powershell
# Confirm the domain exists
Get-ADDomain

# Confirm DNS is working
Resolve-DnsName qcbhomelab.online
```

Both commands should return results without errors. If DNS resolution fails, check that the server's preferred DNS is still set to 127.0.0.1.

### Step 7 — Configure DNS Forwarders

The domain controller handles DNS for the internal domain, but it needs to forward all other DNS queries (internet traffic) to an upstream resolver.

```powershell
# Add Cloudflare and Google as forwarders
Add-DnsServerForwarder -IPAddress 1.1.1.1
Add-DnsServerForwarder -IPAddress 8.8.8.8
```

Test that internet name resolution now works from the server:

```powershell
Resolve-DnsName google.com
```

---

## What to Expect

After completing these steps, QCBHC-DC01 is a fully functioning domain controller for qcbhomelab.online. The next step is to build out the Organisational Unit structure and create all user accounts — covered in document 02.

---

## Common Questions & Troubleshooting

**Q1: After promoting the server to domain controller, I can no longer resolve external DNS names like google.com. What is wrong?**

When a server is promoted to a domain controller, it sets itself as its own DNS server (127.0.0.1). If DNS forwarders are not configured, the server can only resolve internal names and has nowhere to send external queries. Run `Add-DnsServerForwarder -IPAddress 1.1.1.1` and `Add-DnsServerForwarder -IPAddress 8.8.8.8` to add upstream resolvers. Verify with `Resolve-DnsName google.com` from the server.

**Q2: I set the preferred DNS on the server to 127.0.0.1 but external DNS resolution from client machines is still failing. Why?**

Client machines resolve through the domain controller, which in turn forwards external queries upstream. If the forwarders are not set on the DC, clients will fail to resolve external names even if the DC itself is reachable. Confirm forwarders are in place using `Get-DnsServerForwarder` on the DC. Also confirm the client's DNS server is pointing to the DC's IP, not to 127.0.0.1 (that only works on the DC itself).

**Q3: The `Install-ADDSForest` command completes but the server does not restart automatically. Is something wrong?**

The `-Force` parameter suppresses the confirmation prompt but does not always guarantee an automatic restart in all environments. If the server does not restart within a few minutes, restart it manually. The promotion process completes on the next boot — log in as `DOMAIN\Administrator` rather than the local Administrator account after restart.

**Q4: I renamed the server with `Rename-Computer` but after the restart, Active Directory still shows the old name. What happened?**

This is normal if the rename was done after AD DS was already installed. Always rename the server before promoting it to a domain controller. If you have already promoted it with the wrong name, the cleanest fix is to demote the DC, rename the server, and re-promote. In a lab environment this is straightforward; in production it requires more care to avoid replication issues.

**Q5: `Resolve-DnsName qcbhomelab.online` returns no results from a client machine on the network, even though the domain controller is reachable. What should I check?**

Work through this in order: confirm the client's DNS server setting points to the DC's IP address (not the router); confirm the DC's DNS service is running (`Get-Service DNS` on the DC); confirm the forward lookup zone for the domain exists in DNS Manager; and confirm there are no firewall rules blocking UDP/TCP port 53 between the client and the DC. A quick test is to run `Resolve-DnsName qcbhomelab.online -Server <DC_IP>` from the client — if that returns a result, the issue is the client's DNS configuration, not the DC itself.

---
