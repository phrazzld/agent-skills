# Lightning Network Audit Checklist

## Checks

### 1. LND Node Connectivity
```bash
command -v lncli >/dev/null && echo "OK" || echo "FAIL: lncli missing"
lncli getinfo 2>/dev/null | head -10 || echo "FAIL: LND not reachable"
lncli getinfo 2>/dev/null | grep -E "synced_to_chain|num_active_channels|num_peers"
```

### 2. Channel Health
```bash
lncli listchannels 2>/dev/null | grep -E "capacity|local_balance|remote_balance|active" | head -20
lncli listchannels 2>/dev/null | grep -c "\"active\": true"  # active channels
lncli pendingchannels 2>/dev/null | head -20  # stuck channels
```

### 3. Liquidity Balance
```bash
lncli channelbalance 2>/dev/null  # total local vs remote
lncli walletbalance 2>/dev/null   # on-chain reserves
```

### 4. Invoice Handling
```bash
grep -rE "lnrpc|invoices|AddInvoice|LookupInvoice" --include="*.ts" --include="*.go" . 2>/dev/null | grep -v node_modules | head -10
grep -rE "bolt11|lnurl|payment_request|pay_req" --include="*.ts" . 2>/dev/null | grep -v node_modules | head -5
```

### 5. LNURL Support
```bash
grep -rE "lnurl|LNURL|lightning-address|lnurlp|lnurlw" --include="*.ts" . 2>/dev/null | grep -v node_modules | head -5
```

### 6. Backup & Recovery
```bash
lncli exportchanbackup --all 2>/dev/null | head -5 || echo "FAIL: Cannot export channel backup"
[ -f "channel.backup" ] || [ -f "*.backup" ] && echo "OK: Backup file exists" || echo "WARN: No local backup file"
```

## Priority Mapping

| Finding | Priority |
|---------|----------|
| LND not reachable | P0 |
| Node not synced | P0 |
| No active channels | P0 |
| All channels inactive | P1 |
| Severe liquidity imbalance | P1 |
| No invoice handling in code | P1 |
| Pending/stuck channels | P2 |
| No LNURL support | P2 |
| No channel backups | P2 |
| Low on-chain reserves | P2 |
| Routing optimization | P3 |
| Fee policy tuning | P3 |

## Deep Audit Areas
- Channel capacity vs payment volume needs
- Inbound vs outbound liquidity ratio
- Watchtower configuration
- Backup automation and verification
- Fee policy competitiveness
