---
name: macos-network-diagnostics
description: "macOS network debugging: DNS resolution paths, firewall layers, Tailscale fleet management, mDNS/Bonjour, SSH tunneling. Diagnostic sequences that go beyond man pages."
argument-hint: "[diagnose|dns|firewall|tailscale|ssh|wol]"
---

## Routing Table

| Command | Action |
|---------|--------|
| (no args) / `diagnose` | Run the diagnostic sequence |
| `dns` | DNS resolution debugging (scutil, dns-sd, split DNS) |
| `firewall` | Firewall layer debugging (ALF + PF) |
| `tailscale` | Load `references/tailscale.md` |
| `ssh` | Load `references/ssh-patterns.md` |
| `wol` | Wake-on-LAN patterns |

## Critical Rule: dig/nslookup LIE on macOS

`dig`, `nslookup`, `host` bypass macOS DNS resolution — they read `/etc/resolv.conf` directly, which only shows the default resolver. No split DNS, no scoped resolvers, no mDNS. Use these instead:

```bash
dns-sd -G v4v6 hostname.example.com     # Uses mDNSResponder (what apps use)
dscacheutil -q host -a name hostname.com  # Uses system resolver
```

If `dig` works but apps fail (or vice versa): split DNS routing, not the server.

## Diagnostic Sequence (Start Here)

When something network-related breaks on macOS:

```bash
# 1. Default route and interface
route -n get 8.8.8.8

# 2. DNS resolvers and ordering (lower order wins)
scutil --dns | head -40

# 3. System DNS resolution (NOT dig)
dscacheutil -q host -a name problem-hostname.example.com

# 4. mDNSResponder resolution
dns-sd -G v4v6 problem-hostname.example.com

# 5. Tailscale routing (if applicable)
tailscale ping target-device
tailscale netcheck

# 6. Firewall state
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
sudo pfctl -si | head -5

# 7. Nuclear flush (both caches are separate)
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
```

## DNS Deep Dive

**scutil --dns** shows ALL resolvers including scoped/supplemental (VPN, Tailscale). Lower `order` value wins. Tailscale injects supplemental resolver (100.100.100.100) with `match domain` for your tailnet.

**Per-domain override:** Drop file in `/etc/resolver/` named after domain. Example: `/etc/resolver/corp.example.com` containing `nameserver 10.0.0.53`. Survives reboots.

**The .local disaster:** `.local` TLD is reserved for mDNS (RFC 6762). macOS sends `.local` queries via multicast first (5-sec timeout), then unicast. Corporate AD domains using `.local` = 5-sec delay on every lookup.

**DNS flush requires BOTH commands:**

```bash
sudo dscacheutil -flushcache     # Directory Services cache
sudo killall -HUP mDNSResponder  # Daemon's internal cache
```

Chrome/Firefox have their own caches (`chrome://net-internals/#dns`).

## Firewall Layers

macOS has TWO independent firewalls:

| Layer | Tool | Purpose |
|-------|------|---------|
| ALF (Application Layer) | `socketfilterfw` | Per-app allow/deny incoming |
| PF (Packet Filter) | `pfctl` | BSD packet filter, IP/port rules |

ALF can allow an app while PF blocks its port. Check both.

```bash
# ALF status
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# PF status and rules
sudo pfctl -si | head -5   # enabled/disabled
sudo pfctl -sr              # active rules
sudo pfctl -sA              # all anchors
```

**PF reference counting:** macOS PF uses `-E` (enable, returns token) and `-X token` (release). PF disables only when last reference released. `sudo pfctl -d` force-kills ALL consumers including system services. Use tokens.

**Never flush main ruleset:** `sudo pfctl -F all` destroys system anchors. Work in your own anchor: `sudo pfctl -a "my.rules" -f /path/to/rules.conf`.

## mDNS / Bonjour

```bash
dns-sd -B _services._dns-sd._udp  # Browse ALL service types
dns-sd -B _ssh._tcp                # Browse SSH services
dns-sd -L "Name" _ssh._tcp        # Resolve instance to IP:port
```

All `dns-sd` commands stream continuously. Ctrl-C to stop.

mDNS uses UDP 5353 multicast (224.0.0.251). If PF blocks this, Bonjour/AirDrop/Handoff break silently.

## networksetup

```bash
networksetup -listnetworkserviceorder   # Service priority (determines default route)
networksetup -getdnsservers "Wi-Fi"     # DNS for a service
networksetup -setdnsservers "Wi-Fi" empty  # Revert to DHCP DNS
```

**Service ordering gotcha:** First active service provides default route. Plugging USB-C Ethernet creates new service at random position — all traffic may shift unexpectedly. DNS is per-service, not global.

## Wake-on-LAN

```bash
brew install wakeonlan
wakeonlan AA:BB:CC:DD:EE:FF                     # Same broadcast domain
wakeonlan -i 192.168.1.255 AA:BB:CC:DD:EE:FF    # Specify broadcast
```

**WoL over Tailscale does NOT work.** Tailscale is L3 (IP). WoL is L2 (Ethernet broadcast). Subnet routing doesn't forward broadcasts. Use an always-on LAN proxy:

```bash
ssh pi@always-on-device "wakeonlan AA:BB:CC:DD:EE:FF"
```

**macOS WoL quirk:** After waking, Mac sleeps again in 30-60 sec unless there's an active session. Establish SSH/screen sharing quickly.

## Cross-Tool Interaction Map

| Scenario | Tools | Root Cause |
|----------|-------|------------|
| VPN + Tailscale DNS conflict | `scutil --dns` | Resolver ordering: lowest order wins |
| Can ping IP but not hostname | `dns-sd`, `dscacheutil` | Split DNS: dig and apps use different paths |
| AirDrop/Handoff stopped | `dns-sd`, `pfctl` | mDNS blocked: UDP 5353 filtered |
| SSH through Tailscale hangs | `tailscale ping`, `netcheck` | DERP relay; symmetric NAT kills direct connections |
| Wake remote Mac over Tailscale | `wakeonlan`, `ssh` | L2 vs L3: need always-on LAN proxy |
| Hotel Wi-Fi won't authenticate | captive portal | Custom DNS or VPN intercepting probe |
| Works in Safari not in curl | `scutil --dns` | curl uses resolv.conf; Safari uses mDNSResponder |

## Captive Portal Gotcha

macOS probes `captive.apple.com/hotspot-detect.html` over plain HTTP. Custom DNS servers, VPNs, or DoH/DoT prevent the redirect. Force open:

```bash
open "http://captive.apple.com/hotspot-detect.html"
```

Nuclear: disable custom DNS and VPN, connect, authenticate, re-enable.
