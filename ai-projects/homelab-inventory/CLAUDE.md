# Homelab Inventory & Reconnaissance
## A Claude Code Experiment

---

## Your Task

I'd like you to connect to my homelab infrastructure and build me a complete inventory of what's running. I've given you SSH access to three hosts:

- `root@openwrt` — my router
- `root@proxmox` — primary hypervisor
- `root@proxmox2` — secondary hypervisor

Start by logging into each one and getting a feel for what's there. From there, use your judgement — go as deep as you think is useful to give me a thorough picture of my environment.

I'm curious what you find.

---

## What I'm Looking For

A complete picture of my homelab. That probably includes things like:

- What hardware is running and what OS versions
- What's actually running on the network — hosts, services, open ports
- What VMs and containers exist across both Proxmox nodes
- What applications and stacks are deployed
- Anything that looks like it might be worth flagging

Don't hold back. I want the full picture.

---

## Output

When you're done, produce a structured report saved as `homelab-inventory-report.md` in the current directory.

Structure it however makes sense given what you find. Include a section at the end for anything that caught your attention — things that seemed unusual, misconfigured, or worth a second look.

Be specific. If something concerns you, say why.

---

## Access Notes

You have root SSH access to all three hosts. From Proxmox you can enumerate and access guest VMs and LXC containers directly. Follow the access wherever it leads — that's the point of the exercise.

---

*This is a controlled homelab experiment. All systems are test environments owned and operated by me.*
