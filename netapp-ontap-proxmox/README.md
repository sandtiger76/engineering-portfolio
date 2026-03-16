# NetApp ONTAP Simulator on Proxmox VE

NetApp provides a simulator for learning ONTAP without physical hardware. The official documentation covers VMware Workstation and VMware Player. If you want it running on Proxmox instead, you are mostly on your own.

I wanted the simulator running on my Proxmox homelab so it would always be available without occupying a laptop. There was no reliable end-to-end guide for Proxmox. There were a few short write-ups for different ONTAP versions and some forum threads with partial answers, but nothing that covered the full process including the parts that go wrong.

This project documents the full setup from scratch. Every panic we hit is explained and fixed. The goal is that someone following this gets a working simulator in a few hours rather than a few days.

Tested on Proxmox VE 9.1.5 with the ONTAP 9.6 simulator. Other ONTAP simulator versions should follow the same process with minor differences.

---

## What You Will Build

```
Proxmox VE host
├── vmbr1 (172.17.17.0/24) — lab management network
├── vmbr2 (isolated)       — ONTAP cluster interconnect
│
├── VM 301: C1N1           — ONTAP node (cluster1, node1)
├── VM 302: C1N2           — ONTAP node (cluster1, node2) [Part 2]
├── VM 303: C2N1           — ONTAP node (cluster2, node1) [Part 2]
└── VM 304: VyOS           — virtual router              [Part 2]
```

**Part 1** gets you a working standalone single-node cluster. That is enough to learn ONTAP, create aggregates and volumes, configure NFS/CIFS/iSCSI, practice CLI commands, and study for certification.

**Part 2** extends this to a two-node HA cluster plus a second standalone cluster, which adds storage failover, SnapMirror replication between clusters, and the cluster peering workflow.

---

## Guides

| Guide | Description |
|-------|-------------|
| [Part 1 — Standalone Single-Node Cluster](part1-ontap-proxmox.md) | Full setup from OVA to working cluster. Covers VM creation, disk initialisation, cluster setup wizard, licensing, SSH access, snapshots and cloning. |
| Part 2 — Two-Node HA Cluster *(coming soon)* | Cloning the Part 1 node, System ID changes, building a two-node HA cluster, adding a second cluster, VyOS routing, SnapMirror between clusters. |

---

## Quick Reference

### IP Layout (Part 1)

| Host | IP | Purpose |
|------|-----|---------|
| Proxmox vmbr1 | 172.17.17.254 | Lab network interface on Proxmox host |
| netapp-lab cluster mgmt | 172.17.17.20 | Cluster management LIF |
| netapp-lab-01 node mgmt | 172.17.17.21 | Node management LIF |

### Key Commands

```bash
# Start the lab node
qm start 301

# Hibernate (frees RAM, resumes in seconds)
qm suspend 301 --todisk 1

# SSH to the cluster from Proxmox host
ssh admin@172.17.17.20

# Take a snapshot (VM must be stopped first)
qm stop 301
qm snapshot 301 <name> --description "<description>"

# Clone a node from the clean pre-setup snapshot
qm clone 301 302 --name C1N2 --full --snapname fresh-install
```

### Shutdown (Always do this before stopping the VM)

```bash
# From the ONTAP CLI
system node halt -node netapp-lab-01 -skip-lif-migration true

# Then from Proxmox terminal
qm stop 301
```

---

## Things That Will Catch You Out

These are covered in detail in Part 1. Listed here as a heads-up.

**The OVA filenames are not what other guides say.** The extracted VMDKs are named `vsim-netapp-DOT9.6-cm-disk1.vmdk`, not `vsim-NetAppDOT-simulate-disk1.vmdk`.

**local-lvm does not support qcow2.** Use `--format raw` when importing disks. Proxmox will switch automatically but the import output changes, which breaks scripts that parse it.

**The CPU type must be SandyBridge.** Other types cause ONTAP boot failures. This is not documented in the official guide.

**The machine type must be `pc` (i440fx), not `q35`.** Same reason.

**RAM must be 5120 MB.** 4096 MB panics during disk initialisation with an out-of-memory error.

**Disk4 must be wiped before first boot.** The OVA contains pre-existing cluster config on the disk shelf image. Without clearing it, ONTAP panics immediately on boot before you can do anything.

**VLOADER timing is tricky.** Press Ctrl-C too early and you land at the `boot:` prompt instead of `VLOADER>`. Wait until all four BIOS drive lines appear before pressing Ctrl-C.

**The cluster management LIF ends up on the wrong port.** After the setup wizard, `cluster_mgmt` is assigned to `e0a` which connects to the isolated cluster interconnect bridge. Move it to `e0c` manually.

**Never snapshot a running ONTAP VM.** It corrupts the internal database. Always halt from the ONTAP CLI first, then stop the VM, then snapshot.

---

## Requirements

- Proxmox VE 7.x, 8.x or 9.x
- NetApp Support Site account (free) to download the simulator
- 5 GB free RAM per ONTAP node
- 40 GB free disk space per node
- The simulator OVA and license file from NetApp

---

## About

This documentation was put together after setting up the ONTAP simulator on a Proxmox homelab. The official NetApp guide only covers VMware. Getting it working on Proxmox took trial and error and produced enough undocumented issues that writing it up seemed worthwhile.

If something in these guides is wrong or out of date, pull requests are welcome.

---

*Tested on: Proxmox VE 9.1.5 | ONTAP Simulator 9.6 | 2026*
