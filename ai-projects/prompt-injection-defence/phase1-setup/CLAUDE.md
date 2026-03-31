# Phase 0b — Pre-Experiment Snapshots

## Your Role
You are a **backup agent**. Your only job is to take snapshots of both LXC containers
on Proxmox before any experiment work begins. This gives us a clean restore point.

Do not touch automation2 (10.20.0.11) or kali (10.20.0.20) directly.
Do not change any configuration on Proxmox.
Do not snapshot the router or any other host.
Snapshot only the two LXCs listed below.

---

## Access

```bash
ssh root@proxmox2
```

---

## Step 1 — Confirm the LXC IDs

Before snapshotting, confirm which VMID belongs to each container:

```bash
pct list
```

Expected:
- automation2 → likely VMID 101
- kali        → likely VMID 102

If the VMIDs are different from expected, use whatever pct list returns.
Document the actual VMIDs in the report.

---

## Step 2 — Check for Existing Snapshots

```bash
pct snapshot list 101
pct snapshot list 102
```

Document any existing snapshots so we have a before/after picture.

---

## Step 3 — Take Snapshots

Take a snapshot of each container with a clear descriptive name and description.
Use the naming convention: `pre-experiment-YYYYMMDD`

```bash
pct snapshot 101 pre-experiment-20260331 --description "Clean baseline before network ops experiment - all containers healthy, disk 76%, iptables DROP policy in place"

pct snapshot 102 pre-experiment-20260331 --description "Clean baseline before network ops experiment - kali idle, full toolset installed"
```

Wait for each snapshot to complete before proceeding to the next.

---

## Step 4 — Verify Snapshots Were Created

```bash
pct snapshot list 101
pct snapshot list 102
```

Confirm both snapshots appear in the list with the correct names.

---

## Step 5 — Confirm Containers Still Running

After snapshotting, confirm both containers are still up and unaffected:

```bash
pct list
pct status 101
pct status 102
```

Both should show status: running.

---

## Output

Print a clear summary to the terminal when done:

```
=== SNAPSHOT SUMMARY ===
automation2 (VMID: 101) — snapshot: pre-experiment-20260331 ✅
kali        (VMID: 102) — snapshot: pre-experiment-20260331 ✅
Both containers: running ✅
Ready to proceed with experiment.
========================
```

If either snapshot fails, stop immediately and report the error.
Do NOT proceed with the experiment if snapshots have not been confirmed.

---

## Important
- Snapshots on running LXCs are supported by Proxmox and will not interrupt services.
- If pct snapshot returns an error about the storage not supporting snapshots,
  report it immediately — do not attempt workarounds.
- Do not reboot, stop, or modify either container.
- Do not touch any other VMs or LXCs on this Proxmox host.
- The router is out of scope. Do not SSH to it or reference it.
