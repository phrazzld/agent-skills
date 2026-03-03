# Bitcoin Audit Checklist

## Checks

### 1. Node Connectivity
```bash
command -v bitcoin-cli >/dev/null && echo "OK" || echo "FAIL: bitcoin-cli missing"
bitcoin-cli getblockchaininfo 2>/dev/null | head -20 || echo "FAIL: Node not reachable"
bitcoin-cli getblockchaininfo 2>/dev/null | grep -E "blocks|headers|verificationprogress|initialblockdownload"
```

### 2. Wallet Health
```bash
bitcoin-cli listwallets 2>/dev/null || echo "FAIL: No wallets loaded"
bitcoin-cli getwalletinfo 2>/dev/null | grep -E "balance|unconfirmed_balance|immature_balance|txcount|private_keys_enabled|keypoolsize"
```

### 3. Address Derivation (BIP84)
```bash
bitcoin-cli listdescriptors 2>/dev/null | grep -E "wpkh|84h" | head -5
```

### 4. Network Config
```bash
bitcoin-cli getblockchaininfo 2>/dev/null | grep -E "\"chain\"|\"pruned\""
ls -1 ~/.bitcoin 2>/dev/null | grep -E "bitcoin.conf|testnet3|regtest" || true
```

### 5. Fee Estimation
```bash
bitcoin-cli estimatesmartfee 6 2>/dev/null || echo "FAIL: Fee estimator unavailable"
bitcoin-cli getmempoolinfo 2>/dev/null | grep -E "mempoolminfee|minrelaytxfee"
```

### 6. UTXO Consolidation
```bash
bitcoin-cli listunspent 2>/dev/null | grep -c "\"txid\"" || echo "FAIL: listunspent failed"
bitcoin-cli listunspent 2>/dev/null | grep -E "\"amount\"" | head -20
```

## Priority Mapping

| Finding | Priority |
|---------|----------|
| Node unreachable | P0 |
| Wallet not loaded | P0 |
| Network mismatch (testnet/mainnet) | P0 |
| Private keys disabled unexpectedly | P1 |
| Missing BIP84 descriptors | P1 |
| Fee estimator unavailable | P1 |
| Excess small UTXOs | P2 |
| Address reuse risk | P2 |
| Low keypool | P2 |
| Fee floor not handled | P2 |
| Automation/monitoring | P3 |

## Deep Audit Areas
- Wallet descriptor correctness (BIP84)
- Address reuse risk
- Fee policy and fallback behavior
- UTXO set health and dust exposure
- Node security and RPC exposure
