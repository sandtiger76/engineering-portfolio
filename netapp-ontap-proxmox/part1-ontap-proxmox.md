# NetApp ONTAP Simulator on Proxmox VE
## Part 1 — Standalone Single-Node Cluster

The official NetApp documentation covers VMware Workstation and VMware Player. That works fine if you have a dedicated Windows machine, but running a hypervisor inside a hypervisor on a laptop is not something most people want to do long-term. I wanted the simulator running on my Proxmox homelab so it would always be available without tying up my laptop.

There was no reliable Proxmox guide. There were a few forum posts and one short GitHub write-up for a different ONTAP version. None of them covered the full process end to end.

This guide documents what actually worked, including every panic we hit, why it happened, and how to fix it. The goal is that someone following this should get a working simulator without spending days debugging things that are not in the official documentation.

Tested on Proxmox VE 9.1.5 with the ONTAP 9.6 simulator. Other ONTAP simulator versions should follow the same process.

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Proxmox Preparation](#proxmox-preparation)
4. [Getting the Files onto Proxmox](#getting-the-files-onto-proxmox)
5. [VM Creation](#vm-creation)
6. [Pre-Boot Disk Preparation](#pre-boot-disk-preparation)
7. [First Boot — Navigating the Bootloader](#first-boot--navigating-the-bootloader)
8. [Disk Initialization — Boot Menu Option 4](#disk-initialization--boot-menu-option-4)
9. [Cluster Setup Wizard](#cluster-setup-wizard)
10. [Post-Setup Tasks](#post-setup-tasks)
11. [Accessing the Cluster](#accessing-the-cluster)
12. [Snapshots, Backups and Cloning](#snapshots-backups-and-cloning)
13. [Hibernate and Shutdown](#hibernate-and-shutdown)
14. [Safe Shutdown Procedure](#safe-shutdown-procedure)
15. [Troubleshooting](#troubleshooting)

---

## Overview

Simulate ONTAP is a NetApp-provided simulator for learning and testing ONTAP without physical hardware. NetApp distributes it as a VMware OVA file. This guide takes that OVA and gets it running on Proxmox VE instead.

**What you will have at the end of Part 1:**
- A single-node ONTAP 9.6 cluster running on Proxmox
- SSH access from the Proxmox host
- All feature licenses installed
- Snapshots saved so you can restore or clone at any time

**What a single-node cluster gives you:**
- Full ONTAP CLI
- Aggregates, volumes, SVMs
- NFS, CIFS, iSCSI
- Snapshots, FlexClone, SnapMirror
- System Manager web UI
- Enough to study for ONTAP certification or learn the platform

The one thing a single node cannot do is HA failover, which requires a partner node. Part 2 covers building a two-node HA cluster using the snapshot from this guide as a starting point.

---

## Prerequisites

### Files Required

Download the following from the [NetApp Support Site](https://mysupport.netapp.com/site/tools/tool-eula/simulate-ontap). A free account is required.

| File | Description |
|------|-------------|
| `vsim-netapp-DOT9.6-cm_nodar.ova` | The ONTAP simulator OVA |
| `CMode_licenses_9.6.txt` | License keys for all ONTAP features |

### Hardware Requirements

| Resource | Minimum | Notes |
|----------|---------|-------|
| CPU | 2 cores, VT-x enabled | Check BIOS if virtualisation is disabled |
| RAM | 5 GB free | 4 GB will panic during disk initialisation |
| Disk | 40 GB free | Per node. The disk shelf image is sparse but grows with use |
| Proxmox VE | 7.x or 8.x | Tested on 9.1.5 |

**RAM note:** ONTAP pre-allocates memory at boot. It does not support the QEMU balloon driver so whatever you allocate, it holds. 5120 MB is the minimum that works reliably. Do not be tempted to try 4096 MB.

### Storage Note

This guide uses `local-lvm` (LVM thin provisioned). Replace `local-lvm` with your pool name if you use something different. One important difference: `local-lvm` does not support qcow2 format. Use `raw` for all disk imports.

---

## Proxmox Preparation

### Step 1 — Create Internal Network Bridges

Two internal bridges are needed. These have **no physical NIC attached** —
they are completely isolated lab networks.

**Option A — Proxmox Web UI:**
1. Navigate to your node → System → Network
2. Click **Create → Linux Bridge**
3. Name: `vmbr1` | Leave Bridge ports **empty** | Comment: `Lab management network`
4. Click **Create → Linux Bridge** again
5. Name: `vmbr2` | Leave Bridge ports **empty** | Comment: `ONTAP cluster interconnect`
6. Click **Apply Configuration**

**Option B — Edit `/etc/network/interfaces` directly:**

```bash
cat >> /etc/network/interfaces << 'EOF'

auto vmbr1
iface vmbr1 inet static
    address 172.17.17.254/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    # Lab management and data network

auto vmbr2
iface vmbr2 inet manual
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    # ONTAP cluster interconnect (isolated)
EOF

ifreload -a
```

Verify both bridges are up:

```bash
ip link show vmbr1 && ip link show vmbr2
```

**Network layout:**

| Bridge | Network | Purpose |
|--------|---------|---------|
| vmbr0 | Your LAN | Proxmox host management only |
| vmbr1 | 172.17.17.0/24 | Lab management and data |
| vmbr2 | isolated | ONTAP cluster interconnect (e0a/e0b) |

---

## Getting the Files onto Proxmox

You have several options for getting the OVA and files onto your Proxmox host.
Choose whichever suits your setup.

### Option A — Extract on Proxmox directly (recommended)

Copy the OVA to your Proxmox host and extract it there:

```bash
# Create a staging directory
mkdir -p /tmp/ontap-staging

# Copy OVA to Proxmox (from another machine)
scp /path/to/vsim-netapp-DOT9.6-cm_nodar.ova root@<proxmox-ip>:/tmp/ontap-staging/

# Or if already on Proxmox, just extract in place
cd /tmp/ontap-staging
tar -xvf vsim-netapp-DOT9.6-cm_nodar.ova
```

### Option B — Extract locally and transfer VMDKs

```bash
# Extract on your local Linux machine
tar -xvf vsim-netapp-DOT9.6-cm_nodar.ova

# Transfer only the VMDKs to Proxmox
ssh root@<proxmox-ip> "mkdir -p /tmp/ontap-staging"
scp vsim-netapp-DOT9.6-cm-disk*.vmdk root@<proxmox-ip>:/tmp/ontap-staging/
```

### Option C — USB drive or external storage

If your Proxmox host has an external drive mounted, copy files directly
to a staging folder on that drive. Make sure you have enough free space —
the VMDKs total around 10 GB extracted.

### Verify the extracted files

After extraction you should see exactly these four files:

```bash
ls -lh /tmp/ontap-staging/*.vmdk
```

```
vsim-netapp-DOT9.6-cm-disk1.vmdk   ~414 MB  (boot disk)
vsim-netapp-DOT9.6-cm-disk2.vmdk   ~70 KB   (sparse)
vsim-netapp-DOT9.6-cm-disk3.vmdk   ~70 KB   (sparse)
vsim-netapp-DOT9.6-cm-disk4.vmdk   ~100 KB  (sparse — disk shelf)
```

> **Important:** The actual filenames extracted from the OVA are
> `vsim-netapp-DOT9.6-cm-disk1.vmdk` (not `vsim-NetAppDOT-simulate-disk1.vmdk`
> as mentioned in some other guides). Use the exact names shown above.

Also copy the license file to your staging directory:

```bash
scp CMode_licenses_9.6.txt root@<proxmox-ip>:/tmp/ontap-staging/
```

---

## VM Creation

All commands below are run on the **Proxmox host** via SSH or the Proxmox shell.

### Critical VM Settings

These settings are non-negotiable. Deviating from them will prevent ONTAP from booting:

| Setting | Value | Reason |
|---------|-------|--------|
| Machine type | `pc` (i440fx) | q35 causes boot failures |
| BIOS | SeaBIOS | UEFI not supported |
| CPU type | `SandyBridge` | Other types cause ONTAP boot failures |
| Disk bus | IDE | SCSI and VirtIO not recognised by ONTAP |
| Disk format | `raw` | local-lvm does not support qcow2 |
| NIC model | `e1000` | ONTAP recognises this model |
| RAM | 5120 MB | Less causes out-of-memory panic |
| Balloon | disabled | ONTAP does not support balloon driver |

### NIC to Bridge Mapping

| ONTAP Port | Proxmox NIC | Bridge | Purpose |
|------------|------------|--------|---------|
| e0a | net0 | vmbr2 | Cluster interconnect |
| e0b | net1 | vmbr2 | Cluster interconnect |
| e0c | net2 | vmbr1 | Management + data |
| e0d | net3 | vmbr1 | Management + data |

### Create the VM

```bash
VMID=301         # Change this if 301 is already in use
STORAGE=local-lvm  # Change to your storage pool name
VMDK_DIR=/tmp/ontap-staging  # Path to your extracted VMDKs

# Create the VM shell — no disks yet
qm create ${VMID} \
    --name "C1N1" \
    --machine pc \
    --bios seabios \
    --cores 2 \
    --cpu SandyBridge \
    --memory 5120 \
    --balloon 0 \
    --net0 e1000,bridge=vmbr2 \
    --net1 e1000,bridge=vmbr2 \
    --net2 e1000,bridge=vmbr1 \
    --net3 e1000,bridge=vmbr1 \
    --onboot 0
```

### Import the Four Disks

Import each disk individually and attach immediately as IDE. **Order matters** —
disk1 must be ide0, disk2 must be ide1, etc.

```bash
# Import all 4 disks
for n in 1 2 3 4; do
    qm disk import ${VMID} \
        ${VMDK_DIR}/vsim-netapp-DOT9.6-cm-disk${n}.vmdk \
        ${STORAGE} --format raw
done

# Attach as IDE devices in order
qm set ${VMID} --ide0 ${STORAGE}:vm-${VMID}-disk-0
qm set ${VMID} --ide1 ${STORAGE}:vm-${VMID}-disk-1
qm set ${VMID} --ide2 ${STORAGE}:vm-${VMID}-disk-2
qm set ${VMID} --ide3 ${STORAGE}:vm-${VMID}-disk-3

# Set boot order — ide0 only, no network boot
qm set ${VMID} --boot order=ide0
```

Verify the final VM configuration:

```bash
qm config ${VMID} | grep -E "^ide|^boot|^memory|^cpu|^machine|^name"
```

Expected output:

```
boot: order=ide0
cpu: SandyBridge
ide0: local-lvm:vm-301-disk-0,size=1944M
ide1: local-lvm:vm-301-disk-1,size=1544M
ide2: local-lvm:vm-301-disk-2,size=4868M
ide3: local-lvm:vm-301-disk-3,size=236232M
machine: pc
memory: 5120
name: C1N1
```

---

## Pre-Boot Disk Preparation

> **This step is critical and must be done before first boot.**

The OVA ships with pre-existing cluster configuration data on disk4 (the simulated
disk shelf). If you boot without clearing this, ONTAP will panic immediately with:

```
PANIC: Can't find device with WWN 0x... Remove '/sim/dev/,disks/,reservations' and restart.
```

Clear the first 1 GB of disk4 to remove the old shelf metadata:

```bash
# VM must be stopped before running this
dd if=/dev/zero of=/dev/pve/vm-${VMID}-disk-3 bs=1M count=1024 status=progress
```

This takes only a few seconds and removes all old reservation and configuration
data from the disk shelf, allowing ONTAP to initialise it fresh.

> **Only wipe disk4 (disk-3 in Proxmox naming).** Do not wipe disk1, disk2,
> or disk3 — these contain the ONTAP operating system and are needed for booting.

---

## First Boot — Navigating the Bootloader

ONTAP uses a two-stage bootloader which can be confusing at first. Here is
exactly how to navigate it.

### Starting the VM

```bash
qm start ${VMID}
```

Open the console in the Proxmox web UI: select the VM → Console.

### The Boot Sequence

```
Stage 1: SeaBIOS (Proxmox BIOS)
Stage 2: FreeBSD/x86 boot: prompt  ← too early, wrong place
Stage 3: BIOS drive listing        ← wait for this
Stage 4: VLOADER prompt            ← this is where you want to be
Stage 5: ONTAP boot menu           ← option 4 goes here
```

### How to Get to VLOADER (Critical Timing)

> **The most common mistake is pressing Ctrl-C too early.**

Watch the console carefully. You will see:

```
SeaBIOS ...
Booting from Hard Disk...
FreeBSD/x86 boot          ← DO NOT press Ctrl-C here
Default: 0:ad(0,a)/boot/loader
boot:                     ← This is too early (wrong stage)
BTX loader 1.00
BIOS drive C: is disk1
BIOS drive D: is disk2
BIOS drive E: is disk3
BIOS drive F: is disk4   ← WAIT until you see all 4 disks
BIOS 639kB/...available memory
FreeBSD/x86 bootstrap loader...
Hit [Enter] to boot immediately, or any other key for command prompt.
```

**Press Ctrl-C AFTER all 4 BIOS drive lines appear.** This lands you at
the `VLOADER>` prompt.

If you press Ctrl-C too early you land at `boot:` which is the wrong stage.
If this happens, type `boot` and try again next cycle.

### Set the Required Boot Variable

At the `VLOADER>` prompt, set this variable before booting:

```
VLOADER> setenv bootarg.init.boot_clustered false
VLOADER> boot
```

> This variable prevents ONTAP from panicking when it can't find a cluster
> partner node. It is required for the first initialization boot.

After typing `boot`, the ONTAP kernel will begin loading. Watch for the
boot menu opportunity.

### Getting to the ONTAP Boot Menu

After the kernel starts loading you will see many lines of module loading.
Watch for:

```
Press Ctrl-C for Boot Menu
```

Press **Ctrl-C** immediately when you see this line. You have about 3 seconds.

The boot menu will appear:

```
(1) Normal Boot.
(2) Boot without /etc/rc.
(3) Change password.
(4) Clean configuration and initialize all disks.
(5) Maintenance mode boot.
(6) Update flash from backup config.
(7) Install new software first.
(8) Reboot node.
(9) Configure Advanced Drive Partitioning.
```

---

## Disk Initialization — Boot Menu Option 4

Select option **4** — Clean configuration and initialize all disks.

```
Selection (1-9)? 4
```

Answer yes to both prompts:

```
Zero disks, reset config and install a new file system?: y
This will erase all the data on the disks, are you sure?: y
```

> **Do not interrupt this process.** The VM will reboot automatically
> when complete. Interrupting it may corrupt the simulator disks requiring
> a full reimport.

The initialization process takes **10–20 minutes**. You will see disk
activity messages and the VM will reboot itself when done. Leave it
completely alone until you see:

```
Welcome to the cluster setup wizard.
```

---

## Cluster Setup Wizard

When the setup wizard appears, follow these steps.

**Press Enter or type `yes` to confirm AutoSupport notice:**

```
Type yes to confirm and continue {yes}: yes
```

**Node management interface — use e0c:**

```
Enter the node management interface port [e0c]: e0c
Enter the node management interface IP address: 172.17.17.21
Enter the node management interface netmask: 255.255.255.0
Enter the node management interface default gateway: 172.17.17.1
```

> Adjust IP addresses to match your lab network.

**Choose CLI setup when prompted:**

```
Use your web browser to complete cluster setup by accessing https://172.17.17.21
Otherwise, press Enter to complete cluster setup using the command line interface:
```

Press **Enter** to use the CLI.

**Create a new cluster:**

```
Do you want to create a new cluster or join an existing cluster? {create, join}: create
```

**Single node cluster:**

```
Do you intend for this cluster to be used as a single node cluster? {yes, no}: yes
```

**Set an admin password** when prompted. Record it safely.

**Name the cluster:**

```
Enter the cluster name: netapp-lab
```

**License key** — press Enter to skip for now (added in post-setup):

```
Enter an additional license key []: <Enter>
```

**Cluster management interface:**

```
Enter the cluster management interface port [e0a]: e0c
Enter the cluster management interface IP address: 172.17.17.20
Enter the cluster management interface netmask: 255.255.255.0
Enter the cluster management interface default gateway: 172.17.17.1
```

**Skip optional fields** — press Enter for DNS domain names, controller
location, and backup destination.

The wizard will complete and you will be logged in automatically:

```
netapp-lab::>
```

---

## Post-Setup Tasks

### Fix the Cluster Management LIF

After setup, the cluster management LIF may be on the wrong port (e0a instead
of e0c). Verify and fix:

```
netapp-lab::> network interface show
```

If `cluster_mgmt` shows port `e0a`, move it to `e0c`:

```
netapp-lab::> network interface modify -vserver netapp-lab -lif cluster_mgmt -home-port e0c -home-node netapp-lab-01
netapp-lab::> network interface revert -vserver netapp-lab -lif cluster_mgmt
netapp-lab::> network interface show
```

Both LIFs should now show port `e0c`.

### Assign Disks

```
netapp-lab::> storage disk assign -all true -node netapp-lab-01
```

### Verify Cluster Health

```
netapp-lab::> cluster show
netapp-lab::> aggr status
netapp-lab::> storage disk show
```

Expected: 1 node healthy, aggr0 online, 28 disks visible (3 in aggr0,
25 spare).

### Add License Keys

Open your `CMode_licenses_9.6.txt` file. It contains three sections:
- Cluster Base License
- Licenses for Node 1
- Licenses for Node 2 (used in Part 2)

Add all Node 1 licenses and the Cluster Base license. Do not publish
these keys — they are available to anyone who downloads the simulator
from the NetApp Support Site.

```
netapp-lab::> license add -license-code <key>
```

Repeat for each key, then verify:

```
netapp-lab::> license show
```

You should see licenses for: NFS, CIFS, iSCSI, FCP, SnapRestore,
SnapMirror, FlexClone, SnapVault, SnapLock, SnapManagerSuite,
SnapProtectApps, and Insight_Balance.

### Disable AutoSupport

```
netapp-lab::> autosupport modify -support disable
```

---

## Accessing the Cluster

### From the Proxmox Host

The Proxmox host has IP `172.17.17.254` on `vmbr1` and can reach the
cluster directly:

```bash
ssh admin@172.17.17.20
```

### From Your Workstation

Your workstation is on a different network and cannot reach `172.17.17.x`
directly. Options:

**Option A — SSH via Proxmox as a jump host:**

```bash
ssh -J root@<proxmox-ip> admin@172.17.17.20
```

**Option B — Add a static route on your workstation:**

```bash
# Linux
sudo ip route add 172.17.17.0/24 via <proxmox-ip>

# MacOS
sudo route add -net 172.17.17.0/24 <proxmox-ip>

# Windows (run as Administrator)
route add 172.17.17.0 mask 255.255.255.0 <proxmox-ip>
```

**Option C — Set up VyOS router** (covered in Part 2) for full routing
between your LAN and the lab network.

### System Manager Web UI

Once routing is configured, access the web UI at:

```
https://172.17.17.20
```

Login with username `admin` and your cluster password.

---

## Snapshots, Backups and Cloning

This is one of the bigger advantages of running the simulator on Proxmox rather than a laptop. You can snapshot at any point, restore instantly if something goes wrong, and clone the node to create additional cluster members without reimporting VMDKs.

### Two Snapshots Worth Keeping

| Snapshot | When | Purpose |
|----------|------|---------|
| `fresh-install` | After option 4, before the wizard | Clean initialised node. Use this when cloning nodes for a cluster. |
| `part1-complete` | After full setup and licensing | Working standalone cluster. Restore this if you break something. |

### Taking a Snapshot

Always shut down cleanly before snapshotting. A snapshot of a running ONTAP VM will corrupt the internal database. This is a known issue and not specific to Proxmox.

```bash
# Step 1 — halt from the ONTAP CLI
netapp-lab::> system node halt -node netapp-lab-01 -skip-lif-migration true
# Answer: y
# Wait for SSH connection to drop

# Step 2 — stop the VM from Proxmox
# After halt, ONTAP sits at "press any key to reboot"
# Do not wait for it — just stop the VM directly
qm stop 301

# Step 3 — take the snapshot
qm snapshot 301 part1-complete --description "Standalone cluster, licensed, ready to use"

# Verify
qm listsnapshot 301
```

### Restoring a Snapshot

```bash
qm stop 301
qm rollback 301 part1-complete
qm start 301
```

### Cloning — The Time Saver for Part 2

The `fresh-install` snapshot is the key to building a multi-node lab without repeating the full setup process. Rather than reimporting four VMDKs and running option 4 for every node, you clone the already-initialised VM. Each clone starts from a clean wiped state, ready for the setup wizard.

```bash
# Clone VM 301 to create two additional nodes
qm clone 301 302 --name C1N2 --full --snapname fresh-install
qm clone 301 303 --name C2N1 --full --snapname fresh-install
```

The `--full` flag creates independent copies with their own disks. The `--snapname` flag clones from the clean pre-setup state rather than the current configured state.

Each cloned node will still need a System ID change at VLOADER before first boot. That is covered in Part 2.

> **Disk space note:** Each clone copies the full disk set including the 230 GB sparse disk4.
> On thin-provisioned storage this is fast and uses minimal real space until ONTAP writes data.
> Expect a few minutes per clone.

---

## Hibernate and Shutdown

### Hibernate — Recommended for Day-to-Day Use

For regular lab sessions, hibernate is faster and more reliable than a full shutdown cycle.

**Via Proxmox web UI:** Shutdown dropdown → **Hibernate**

**Via CLI:**
```bash
qm suspend 301 --todisk 1
```

**Resume:**
```bash
qm resume 301
```

Hibernate frees all RAM. ONTAP uses around 4.5 GB when running idle, so hibernating gives that back to the host immediately. The VM resumes in seconds without a full boot.

Hibernate state is stored on disk as a file roughly equal to the VM's RAM size (5 GB in this case).

**Single node cluster:** Hibernate works reliably. No caveats.

**Multi-node clusters (Part 2):** Hibernate or resume all nodes together. If one node comes up and cannot find its partner, it will panic. Always start both nodes before either one tries to reach the other.

---

## Safe Shutdown Procedure

Never hard-stop an ONTAP VM. Always halt from the CLI first. Skipping this can corrupt the NVRAM simulation and may require a full reinitialisation.

```bash
# Step 1 — from the ONTAP CLI
netapp-lab::> system node halt -node netapp-lab-01 -skip-lif-migration true
# Answer: y

# Step 2 — wait for SSH to disconnect

# Step 3 — from the Proxmox terminal
# Do not wait for "press any key to reboot" — just stop it
qm stop 301
```

---

## Troubleshooting

### PANIC: Can't find device with WWN

```
PANIC: Can't find device with WWN 0x... Remove '/sim/dev/,disks/,reservations' and restart.
```

**Cause:** Old cluster reservation data on disk4 from the OVA's pre-baked config.

**Fix:** Stop the VM and wipe disk4:
```bash
qm stop 301
dd if=/dev/zero of=/dev/pve/vm-301-disk-3 bs=1M count=1024 status=progress
```
Then set the boot variable at VLOADER and run option 4.

### PANIC: out of memory

```
PANIC: sk_allocate_memory: out of memory
```

**Cause:** VM has less than 5120 MB RAM.

**Fix:**
```bash
qm stop 301
qm set 301 --memory 5120
qm start 301
```

### PANIC: /sim/dev/,disks directory not found

**Cause:** disk4 is blank or was wiped incorrectly.

**Fix:** This is actually expected if you wiped disk4 — run option 4
from the boot menu and ONTAP will rebuild the disk shelf structure fresh.

### PANIC: No /dev/ad2s1 file found

**Cause:** disk2 or disk3 was wiped. These contain essential ONTAP
filesystem data and must not be wiped.

**Fix:** Destroy the VM and reimport the VMDKs fresh from the OVA.
Only wipe disk4.

### Landed at `boot:` instead of `VLOADER>`

**Cause:** Pressed Ctrl-C too early, before all 4 BIOS drive lines appeared.

**Fix:** Type `boot` at the `boot:` prompt and try again next cycle —
wait until all 4 drives appear before pressing Ctrl-C.

### Cluster management LIF unreachable after setup

**Cause:** The setup wizard assigns `cluster_mgmt` to `e0a` which is
connected to the isolated `vmbr2` bridge.

**Fix:** Move the LIF to `e0c` as described in the Post-Setup Tasks section.

### Cannot take snapshot — lock timeout

```
can't lock file '/var/lock/qemu-server/lock-301.conf' - got timeout
```

**Cause:** VM is still in a running or transitional state after halt.

**Fix:** Wait 30 seconds and try again. If it persists, force stop first:
```bash
qm stop 301
qm snapshot 301 <name>
```

---

## Summary — IP Reference

| Host | IP | Purpose |
|------|-----|---------|
| Proxmox host (vmbr1) | 172.17.17.254 | Lab network gateway |
| netapp-lab cluster mgmt | 172.17.17.20 | Cluster management LIF |
| netapp-lab-01 node mgmt | 172.17.17.21 | Node management LIF |

---

---

*Part 2 covers building a two-node HA cluster and a second standalone cluster for SnapMirror replication.*

*Tested on: Proxmox VE 9.1.5 | ONTAP Simulator 9.6 | 2026*
