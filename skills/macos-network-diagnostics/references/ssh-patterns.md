# SSH Patterns for Fleet Management

## Tunnel Types

```bash
ssh -L 5432:db.internal:5432 jump     # LOCAL: access remote service locally
ssh -R 8080:localhost:3000 remote      # REMOTE: expose local service remotely
ssh -D 1080 remote                     # SOCKS: dynamic proxy
```

## ProxyJump (Preferred)

```
# ~/.ssh/config
Host internal-server
    HostName 10.0.0.50
    ProxyJump jump-host
    User deploy
```

End-to-end encrypted — jump host sees only opaque bytes. Multi-hop:
`ProxyJump host1,host2,host3` chains left to right.

Strictly better than agent forwarding.

## Agent Forwarding: Avoid

`ForwardAgent yes` exposes your SSH agent socket on the remote host. Anyone with root can authenticate as you to any server your keys unlock.

Prefer ProxyJump. If you must forward, use `ssh-add -c` for per-use confirmation and scope to specific hosts only.

## 1Password SSH Agent + ProxyJump

`IdentityAgent` takes precedence over `SSH_AUTH_SOCK`. For remote sessions needing forwarded agent, don't set `IdentityAgent` on that host entry.

## Keepalive + Persistent Tunnels

```
# ~/.ssh/config
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3

# Persistent tunnel (uses SSH keepalive, not monitor port)
autossh -M 0 -f -N -L 5432:db.internal:5432 jump-host
```

## Tailscale + SSH

With Tailscale, direct SSH to any peer — no jump hosts needed:

```
Host phyrexia
    HostName phyrexia
    User phaedrus
    # MagicDNS resolves if Tailscale DNS enabled
```

Use `tailscale ssh` for keyless SSH (Tailscale manages auth). Requires enabling in ACLs.
