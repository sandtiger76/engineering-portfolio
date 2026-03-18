# NetApp ONTAP Simulator on Proxmox VE
## Part 2 — Two-Node HA Cluster with VyOS iSCSI Routing

Part 1 produced a working standalone single-node cluster. Part 2 extends this to a two-node HA cluster with a VyOS virtual router providing management routing and a dedicated iSCSI fabric.

Tested on Proxmox VE 9.1.5 with the ONTAP 9.6 simulator.

---

## Table of Contents

1. [Overview](#overview)
2. [What You Will Build](#what-you-will-build)
3. [Prerequisites](#prerequisites)
4. [Phase 1 — Add vmbr3 (iSCSI Fabric Bridge)](#phase-1--add-vmbr3-iscsi-fabric-bridge)
5. [Phase 2 — Build the VyOS VM](#phase-2--build-the-vyos-vm)
6. [Phase 3 — Configure VyOS](#phase-3--configure-vyos)
7. [Phase 4 — Build C1N2 from OVA VMDKs](#phase-4--build-c1n2-from-ova-vmdks)
8. [Phase 5 — Change C1N2 System ID at VLOADER](#phase-5--change-c1n2-system-id-at-vloader)
9. [Phase 6 — C1N2 Setup Wizard — Join Cluster](#phase-6--c1n2-setup-wizard--join-cluster)
10. [Phase 7 — Verify HA and Cluster Health](#phase-7--verify-ha-and-cluster-health)
11. [Phase 8 — iSCSI Data LIF Setup](#phase-8--iscsi-data-lif-setup)
12. [Troubleshooting](#troubleshooting)
13. [IP Reference](#ip-reference)

---

## Overview

Part 2 adds three things to the Part 1 lab:

- **VyOS virtual router** — routes traffic between your LAN, the lab management network, and the iSCSI fabric
- **Dedicated iSCSI fabric** — a separate network for storage traffic, isolated from management
- **C1N2** — a second ONTAP node that joins the existing cluster, enabling storage failover

The cluster interconnect (e0a/e0b) remains on the isolated vmbr2 bridge. VyOS does not touch this — HA heartbeat traffic is internal to the cluster only.

---

## What You Will Build

```
Your LAN (192.168.x.x)
       |
    [vmbr0] — Proxmox physical NIC
       |
    [VyOS VM 304]
      /        \            \
  [vmbr1]    [vmbr2]      [vmbr3]
  172.17.17.x  (cluster    10.10.10.x
  mgmt/data    interconnect) iSCSI fabric
     |              |              |
  C1N1 e0c/e0d  C1N1 e0a/e0b  C1N1 e0e
  C1N2 e0c/e0d  C1N2 e0a/e0b  C1N2 e0e
```

---

## Prerequisites

- Part 1 complete — working single-node cluster (C1N1, VM 301)
- The `fresh-install` snapshot exists on VM 301 — **taken before first boot, with disk4 pre-wiped**
- Original OVA VMDKs available on the Proxmox host or attached storage
- VyOS rolling release ISO downloaded to Proxmox local storage

> **Important — about the fresh-install snapshot:**
> The `fresh-install` snapshot must have been taken before the VM was ever booted — after disk import and dd wipe only. If your snapshot was taken after option 4 ran, it cannot be used for cloning. See the cloning note in the Troubleshooting section.

---

## Phase 1 — Add vmbr3 (iSCSI Fabric Bridge)

Add a third isolated bridge for the iSCSI fabric. This keeps storage traffic separated from management traffic, which mirrors real-world SAN design.

```bash
cat >> /etc/network/interfaces << 'EOF'

auto vmbr3
iface vmbr3 inet manual
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    # iSCSI fabric (routed by VyOS)
EOF

ifreload -a
ip link show vmbr3
```

Expected output:
```
32: vmbr3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 ... state UNKNOWN
```

---

## Phase 2 — Build the VyOS VM

Download the VyOS 1.4+ (Sagitta) or 1.5 rolling release ISO from vyos.io and upload it to Proxmox local storage.

Enable ISO content type on local storage if not already set:

```bash
pvesm set local --content iso,vztmpl,backup,snippets
```

Create the VM:

```bash
qm create 304 \
    --name VyOS \
    --machine q35 \
    --bios seabios \
    --cores 2 \
    --memory 1024 \
    --balloon 0 \
    --net0 e1000,bridge=vmbr0 \
    --net1 e1000,bridge=vmbr1 \
    --net2 e1000,bridge=vmbr3 \
    --onboot 1 \
    --boot order='scsi0;ide2'

qm set 304 --scsi0 local-lvm:8,format=raw
qm set 304 --ide2 local:iso/<your-vyos-iso-filename>,media=cdrom
```

> **NIC assignment:**
> - net0 / eth0 — vmbr0 — LAN uplink (DHCP)
> - net1 / eth1 — vmbr1 — lab management (172.17.17.1/24)
> - net2 / eth2 — vmbr3 — iSCSI fabric (10.10.10.1/24)

Start the VM and open the Proxmox web console:

```bash
qm start 304
```

Boot the live ISO. Login with `vyos / vyos`, then install:

```bash
install image
```

Accept all defaults. Set a password when prompted. Reboot when complete — the VM will boot from scsi0 (the installed image) on the next start.

---

## Phase 3 — Configure VyOS

After reboot, log in and enable SSH first so you can configure over a proper terminal rather than the KVM console:

```bash
configure
set service ssh port 22
set interfaces ethernet eth0 address dhcp
commit
save
exit
```

Find the DHCP address assigned to eth0:

```bash
show interfaces ethernet eth0
```

SSH in from your workstation or the Proxmox host:

```bash
ssh vyos@<eth0-ip>
```

Now apply the full configuration:

```bash
configure
```

```
set interfaces ethernet eth0 address dhcp
set interfaces ethernet eth0 description 'LAN-uplink'

set interfaces ethernet eth1 address '172.17.17.1/24'
set interfaces ethernet eth1 description 'lab-mgmt'

set interfaces ethernet eth2 address '10.10.10.1/24'
set interfaces ethernet eth2 description 'iscsi-fabric'

set nat source rule 10 outbound-interface name 'eth0'
set nat source rule 10 source address '172.17.17.0/24'
set nat source rule 10 translation address masquerade

set nat source rule 20 outbound-interface name 'eth0'
set nat source rule 20 source address '10.10.10.0/24'
set nat source rule 20 translation address masquerade

set protocols static route 0.0.0.0/0 next-hop <your-LAN-gateway>

commit
save
```

Replace `<your-LAN-gateway>` with your actual LAN gateway IP (e.g. `192.168.1.1`).

Verify:

```bash
show interfaces
ping 172.17.17.254 count 3
ping 8.8.8.8 count 3
```

Both pings should succeed. VyOS is done.

---

## Phase 4 — Build C1N2 from OVA VMDKs

> **Do not clone from the fresh-install snapshot.** Cloning ONTAP VMs does not work regardless of when the snapshot was taken. Each node must be built from the original OVA VMDKs. See Troubleshooting for a full explanation.

### Add the iSCSI NIC to C1N1

While we are making changes, add the iSCSI NIC to C1N1 as well:

```bash
qm set 301 --net4 e1000,bridge=vmbr3
```

This will appear as e0e in ONTAP.

### Create the C1N2 VM Shell

```bash
VMID=302
STORAGE=local-lvm
VMDK_DIR=/mnt/usbdrive/ontap-staging   # adjust to your path

qm create ${VMID} \
    --name "C1N2" \
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
    --net4 e1000,bridge=vmbr3 \
    --onboot 0
```

### Import the Four Disks

```bash
qm importdisk ${VMID} ${VMDK_DIR}/vsim-netapp-DOT9.6-cm-disk1.vmdk ${STORAGE} --format raw
qm importdisk ${VMID} ${VMDK_DIR}/vsim-netapp-DOT9.6-cm-disk2.vmdk ${STORAGE} --format raw
qm importdisk ${VMID} ${VMDK_DIR}/vsim-netapp-DOT9.6-cm-disk3.vmdk ${STORAGE} --format raw
qm importdisk ${VMID} ${VMDK_DIR}/vsim-netapp-DOT9.6-cm-disk4.vmdk ${STORAGE} --format raw
```

### Attach the Disks

```bash
qm set ${VMID} --ide0 ${STORAGE}:vm-${VMID}-disk-0
qm set ${VMID} --ide1 ${STORAGE}:vm-${VMID}-disk-1
qm set ${VMID} --ide2 ${STORAGE}:vm-${VMID}-disk-2
qm set ${VMID} --ide3 ${STORAGE}:vm-${VMID}-disk-3
qm set ${VMID} --boot order=ide0
```

### Wipe Disk4 Before First Boot

> **This must be done before the VM is ever started.**

```bash
dd if=/dev/zero of=/dev/pve/vm-${VMID}-disk-3 bs=1M count=1024 status=progress
```

### Take the pre-join Snapshot

The VM now has clean virgin disks with disk4 pre-wiped. Take a snapshot before booting so you have a clean rollback point:

```bash
qm snapshot ${VMID} pre-join --description "C1N2 - clean disks, disk4 wiped, never booted"
qm listsnapshot ${VMID}
```

---

## Phase 5 — Change C1N2 System ID at VLOADER

C1N2 needs a unique System ID before option 4 runs. If it boots with the same System ID as C1N1, disk ownership conflicts will occur when joining the cluster.

First check C1N1's current System ID:

```bash
ssh admin@172.17.17.20
::> node show -fields system-id
```

C1N2 should be assigned the next sequential ID. If C1N1 is `4082368507`, C1N2 should be `4082368508`.

### Boot and Intercept at VLOADER

Open the Proxmox web console for VM 302 **before** starting it, then:

```bash
qm start 302
```

Watch for all 4 BIOS drive lines:
```
BIOS drive C: is disk1
BIOS drive D: is disk2
BIOS drive E: is disk3
BIOS drive F: is disk4
```

Press **Ctrl-C** after all 4 appear. At `VLOADER>`:

```
VLOADER> setenv SYS_SERIAL_NUM 4034389-06-2
VLOADER> setenv bootarg.nvram.sysid 4082368508
VLOADER> setenv bootarg.init.bootmenu 1
VLOADER> printenv bootarg.nvram.sysid
4082368508
VLOADER> boot
```

The `printenv` confirms the value was set. The `bootarg.init.bootmenu 1` forces the boot menu to appear so you can select option 4.

### System ID Override Prompt

After the FIPS self-tests you will see:

```
WARNING: System ID mismatch. This usually occurs when replacing a boot device or NVRAM cards!
Override system ID? {y|n}
```

Type **y**. This is expected — the boot disks were cloned from OVA VMDKs that have no prior System ID, so ONTAP flags the mismatch between the VLOADER value and what it finds on disk. Answering yes tells ONTAP to accept the new ID.

> **If you built C1N2 from truly fresh OVA VMDKs that have never been booted**, you may not see this prompt at all — ONTAP has nothing to compare against and accepts the VLOADER value without question. Both behaviours are normal.

### Select Option 4

At the boot menu select **4** — Clean configuration and initialize all disks.

```
Selection (1-9)? 4

Zero disks, reset config and install a new file system?: y
This will erase all the data on the disks, are you sure?: y
```

This takes 10–20 minutes. Do not interrupt it. The VM will reboot automatically when done and drop into the cluster setup wizard.

---

## Phase 6 — C1N2 Setup Wizard — Join Cluster

When the setup wizard appears on C1N2, the process is different from Part 1. C1N2 joins the existing cluster rather than creating a new one.

**Confirm AutoSupport:**
```
Type yes to confirm and continue {yes}: yes
```

**Node management interface:**
```
Enter the node management interface port [e0c]: e0c
Enter the node management interface IP address: 172.17.17.22
Enter the node management interface netmask: 255.255.255.0
Enter the node management interface default gateway: 172.17.17.1
```

**Choose CLI setup:**

Press **Enter** to use the CLI.

**Join the existing cluster:**

```
Do you want to create a new cluster or join an existing cluster? {create, join}: join

Enter the IP address of the cluster interface [e0c]: 172.17.17.20
```

Enter the cluster admin password when prompted. C1N2 will contact C1N1 and join the cluster. This takes a minute or two.

When complete you will see the cluster prompt:

```
netapp-lab::>
```

---

## Phase 7 — Verify HA and Cluster Health

From C1N1 (SSH to 172.17.17.20):

```
::> cluster show
```

Both nodes should be listed and healthy:

```
Node                  Health  Eligibility
--------------------- ------- ------------
netapp-lab-01         true    true
netapp-lab-02         true    true
```

Verify storage failover:

```
::> storage failover show
```

Both nodes should show `Connected` under Partner Status:

```
Node           Partner        Possible State Description
-------------- -------------- -------- ---------------------
netapp-lab-01  netapp-lab-02  true     Connected to netapp-lab-02
netapp-lab-02  netapp-lab-01  true     Connected to netapp-lab-01
```

Assign disks to C1N2:

```
::> storage disk assign -all true -node netapp-lab-02
```

Add Node 2 license keys from `CMode_licenses_9.6.txt`:

```
::> license add -license-code <key>
```

---

## Phase 8 — iSCSI Data LIF Setup

Both nodes now have e0e connected to the iSCSI fabric (vmbr3 / 10.10.10.0/24). Configure iSCSI LIFs so initiators on your LAN can reach ONTAP storage through VyOS.

### Create an iSCSI SVM

```
::> vserver create -vserver iscsi-svm -rootvolume root -aggregate aggr1 -rootvolume-security-style unix
```

### Enable iSCSI Protocol

```
::> vserver iscsi create -vserver iscsi-svm
```

### Create Data LIFs — One Per Node

```
::> network interface create -vserver iscsi-svm -lif iscsi-lif-01 \
    -role data -data-protocol iscsi \
    -home-node netapp-lab-01 -home-port e0e \
    -address 10.10.10.11 -netmask 255.255.255.0

::> network interface create -vserver iscsi-svm -lif iscsi-lif-02 \
    -role data -data-protocol iscsi \
    -home-node netapp-lab-02 -home-port e0e \
    -address 10.10.10.12 -netmask 255.255.255.0
```

### Add Default Gateway to C1N1

C1N1 needs to know about VyOS as its gateway to route iSCSI traffic correctly:

```
::> network route create -vserver iscsi-svm -destination 0.0.0.0/0 -gateway 10.10.10.1
```

### Verify

```
::> network interface show -vserver iscsi-svm
::> vserver iscsi show
```

iSCSI initiators on your LAN can now reach `10.10.10.11` and `10.10.10.12` through VyOS.

---

## Troubleshooting

### Why cloning ONTAP VMs does not work

Cloning an ONTAP VM — regardless of when the snapshot was taken — results in nodes that share identity at a level deeper than the System ID override can fix.

If the snapshot was taken after option 4, all four disks carry the source node's WWN addresses and ONTAP subsystem identity. The cloned node panics before ONTAP is far enough along to run option 4 or enter maintenance mode. The System ID override at VLOADER is not sufficient — it only changes the NVRAM identity, not the disk shelf WWNs.

The only reliable approach is to build each node from the original OVA VMDKs. The process takes the same time as the original Part 1 build.

### PANIC: Can't find device with WWN

```
PANIC: Can't find device with WWN 0x... Remove '/sim/dev/,disks/,reservations' and restart.
```

**Cause:** Old reservation data on disk4. Either the OVA pre-baked config was not wiped, or this is a clone carrying the source node's reservation data.

**Fix:** Stop the VM and wipe disk4:
```bash
qm stop 302
dd if=/dev/zero of=/dev/pve/vm-302-disk-3 bs=1M count=1024 status=progress
```

If the `dd` completes instantly and the panic persists, the storage is thin-provisioned and the wipe is not reaching allocated blocks. Use `blkdiscard` instead:
```bash
blkdiscard /dev/pve/vm-302-disk-3
```

### PANIC: /sim/dev/,disks directory not found

**Cause:** disk4 is blank — correctly wiped. ONTAP cannot find the disk shelf structure because it has not been initialised yet.

**Fix:** This is expected after a wipe. Use `bootarg.init.bootmenu 1` at VLOADER to force the boot menu, then select option 4.

### blkdiscard needed for thin-provisioned clones

When wiping a disk on LVM thin storage, `dd` alone writes zeroes into the thin pool but does not discard already-allocated extents. The reservation data survives. `blkdiscard` tells the thin pool to actually release all allocated blocks:

```bash
blkdiscard /dev/pve/vm-302-disk-3
```

This is only needed for cloned or previously-booted disks on thin storage. Fresh OVA imports wipe correctly with `dd`.

### bootarg.init.bootmenu 1

If ONTAP panics before reaching the boot menu (for example after the System ID override), use this VLOADER variable to force the menu:

```
VLOADER> setenv bootarg.init.bootmenu 1
VLOADER> boot
```

This is required when disk4 has been wiped — ONTAP would otherwise panic at startup before giving you the chance to select option 4.

### C1N2 cannot reach cluster management IP

**Cause:** C1N2's default gateway is not set, or the cluster management LIF is on the wrong port.

**Fix:** Verify the gateway was entered correctly during the setup wizard (172.17.17.1 — the VyOS eth1 address). If the LIF is on e0a, move it to e0c as described in Part 1 Post-Setup Tasks.

### Storage failover shows Waiting for giveback

**Cause:** Normal state immediately after C1N2 joins. HA negotiation takes a minute or two.

**Fix:** Wait 2–3 minutes and run `storage failover show` again.

---

## IP Reference

| Host | Interface | IP | Purpose |
|------|-----------|-----|---------|
| Proxmox host | vmbr1 | 172.17.17.254 | Lab network (existing) |
| VyOS | eth0 | DHCP | LAN uplink |
| VyOS | eth1 | 172.17.17.1 | Lab mgmt gateway |
| VyOS | eth2 | 10.10.10.1 | iSCSI fabric gateway |
| C1N1 cluster mgmt | e0c | 172.17.17.20 | Cluster mgmt LIF |
| C1N1 node mgmt | e0c | 172.17.17.21 | Node mgmt LIF |
| C1N1 iSCSI | e0e | 10.10.10.11 | iSCSI data LIF |
| C1N2 node mgmt | e0c | 172.17.17.22 | Node mgmt LIF |
| C1N2 iSCSI | e0e | 10.10.10.12 | iSCSI data LIF |
| C1N1/C1N2 interconnect | e0a/e0b | (no IP) | HA heartbeat — vmbr2 only |

---

*Tested on: Proxmox VE 9.1.5 | ONTAP Simulator 9.6 | 2026*
