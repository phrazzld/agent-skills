# Tailscale CLI Reference

## Core Commands

```bash
tailscale status                    # Peer status: direct vs DERP relay
tailscale ping <hostname-or-ip>     # Test direct connectivity
tailscale netcheck                  # NAT type, DERP latency, IPv6
tailscale dns status                # DNS resolver state
tailscale dns query <hostname>      # Query through Tailscale resolver
tailscale version                   # Client/daemon version (watch for mismatch)
```

## MagicDNS

Full names: `<hostname>.<tailnet>.ts.net`. Short names only work if "Use Tailscale DNS settings" is checked (adds tailnet as search domain).

CLI tools that bypass system DNS (`dig`, `nslookup`, `host`) NEVER resolve MagicDNS names. Test with `ping` or `dns-sd`.

## Exit Node DNS Override

When using exit node, ALL DNS goes through it — overrides split DNS and custom nameservers. By design for privacy, breaks internal DNS. Fix: mark specific nameservers as not overridden in admin console, or configure per-domain split DNS.

## Direct vs Relayed

`tailscale ping` shows direct (UDP hole-punch) vs DERP relay.
`tailscale netcheck` shows NAT type.
If `MappingVariesByDestIP: true` = symmetric NAT → all traffic through DERP relays.

## Version Mismatch

App Store updates GUI but may not update `tailscaled`. `tailscale version` shows both. Fix: restart from menu bar or `killall Tailscale` and relaunch.

## Debug Menu

Option+click the Tailscale menu bar icon → debug menu → "Bug Report" generates full config dump.
