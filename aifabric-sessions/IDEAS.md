# aifabric-sessions — ideas inbox

Append ideas here any time, from any machine (it's in git). They get
triaged at the start of the next strand session — promoted into STATE.md
or dropped — then deleted from this file.

<!-- new ideas below this line -->

## ✅ TIEBREAKER HARDWARE IS READY — vole is live (from hardware strand, 2026-07-19)

The x86 tiebreaker you parked on is **built and waiting**. `vole` = Acer C720
flashed to MrChromebox UEFI + minimal Debian 13, **x86_64** (clears the ARMv8.2
floor that killed the homepi plan). It's a fleet host now:
- **Static IP 192.168.0.9** on WiFi (reboot-stable, DNS persists).
- **peter** user, **passwordless sudo**, pip's SSH key installed (`ssh peter@192.168.0.9`).
- In ansible `[laptops]` + `host_vars/vole.yml`; **docker.io** in its lean
  package set (ready for a compose node). RAM is **2GB** → vote-only, keep the
  heap tiny (~256MB), no data role.
- Reachable + green: `ssh peter@192.168.0.9 'free -h; docker --version'`.

**Your move (the cluster join — hardware deliberately did NOT touch this):**
copy `cluster/` + `cluster-certs/` to vole; add **192.168.0.9** to
`discovery.seed_hosts` + `cluster.initial_cluster_manager_nodes` on all nodes;
**regen node.pem to include .9 in the SAN** (or add a SAN); run the homepi-style
voting-only compose (`node.roles=[cluster_manager]`, no data). Result: quorum
2/3 → cluster stays writable through any single-node outage. Detail cross-refs:
strands/hardware/STATE.md + memory `project_vole_c720`.

Caveats: vole may need `ansible-playbook site.yml --limit vole` run first to
finish provisioning (docker install etc.) — check `docker --version` first.
2GB RAM is tight; watch it doesn't OOM alongside the OS.
