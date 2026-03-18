# Sprites CLI Reference

Install: https://docs.sprites.dev/cli/installation/

## Authentication

```bash
sprite login                     # Interactive browser auth
sprite login -o my-org           # Auth to specific org
sprite logout                    # Clear credentials
sprite org auth                  # Create/manage org tokens
sprite org auth -o myorg         # Token for specific org
sprite org list                  # List available orgs
sprite org keyring enable        # Store tokens in OS keyring
sprite org keyring disable       # Use file-based token storage
sprite auth setup --token "..."  # Non-interactive token setup
```

## Sprite Management

```bash
sprite create my-sprite          # Create (opens console by default)
sprite create --skip-console     # Create without entering console
sprite create -o myorg my-sprite # Create in specific org
sprite use my-sprite             # Set active sprite (avoids -s flag)
sprite use --unset               # Clear active sprite
sprite list                      # List all sprites (alias: sprite ls)
sprite list --prefix dev         # Filter by name prefix
sprite list -w                   # Watch mode (live updates)
sprite destroy my-sprite         # IRREVERSIBLE: delete sprite + all data
sprite destroy --force my-sprite # Skip confirmation prompt
```

## Command Execution

```bash
sprite exec ls -la                          # Run command
sprite exec --dir /app echo hello           # Set working directory
sprite exec --env KEY=val,FOO=bar env       # Pass env vars (COMMA DELIMITED)
sprite exec --tty /bin/bash                 # TTY mode
sprite exec --file local.txt:/remote.txt cmd  # Upload file before exec
sprite exec -s other-sprite cmd             # Target specific sprite
sprite exec --http-post cmd                 # Force HTTP POST mode

# Alias
sprite x ls -la
```

**Gotcha:** `--env` uses comma delimiter. Values containing commas are
silently corrupted. Use the HTTP API for values with commas.

## Console (Interactive Shell)

```bash
sprite console                  # Open shell on active sprite
sprite console -s my-sprite     # Open shell on specific sprite

# Detach: Ctrl+\  (session persists)
# Reattach via sessions commands
```

## Sessions

```bash
sprite sessions list            # Show active sessions
sprite sessions attach <id>     # Reconnect to detached session
sprite sessions kill <id>       # Terminate a session
```

## Checkpoints

```bash
sprite checkpoint create                     # Create checkpoint
sprite checkpoint create --comment "v2 setup"  # With description
sprite checkpoint list                       # List checkpoints (alias: ls)
sprite checkpoint list --include-auto        # Include auto-checkpoints
sprite checkpoint list --history v3          # Show history for version
sprite checkpoint info v2                    # Checkpoint details
sprite checkpoint delete v3                  # Delete checkpoint (alias: rm)
sprite restore v1                            # Restore to checkpoint
sprite restore -s my-sprite v2               # Restore specific sprite
```

**Critical:** `checkpoint list` may return "Current" — never restore it.

## Networking

```bash
sprite proxy 8080                  # Forward local:8080 → sprite:8080
sprite proxy 3000 8080             # Forward multiple ports
sprite proxy 4005:4000             # Local 4005 → sprite 4000
sprite proxy -W :22                # stdio mode (for SSH piping)
sprite url                         # Show sprite's public URL
sprite url update --auth public    # Make URL publicly accessible
sprite url update --auth sprite    # Require token for URL access
```

## API (Raw)

```bash
sprite api /sprites                         # GET request
sprite api -s my-sprite /upgrade -X POST    # POST request
sprite api -o myorg /sprites                # Org-scoped request
```

Passes auth automatically. Useful for operations not yet in the CLI.

## Upgrade

```bash
sprite upgrade            # Update to latest
sprite upgrade --check    # Check for updates only
sprite upgrade --force    # Force reinstall
sprite upgrade --channel dev  # Use dev channel
```

## Common Flags

| Flag | Short | Meaning |
|------|-------|---------|
| `--org` | `-o` | Target organization |
| `--sprite` | `-s` | Target sprite (overrides `sprite use`) |
| `--help` | `-h` | Show command help |

## Scripting Patterns

### Exec with env from file

```bash
# Load .env and pass as comma-separated pairs
ENV_PAIRS=$(grep -v '^#' .env | grep '=' | tr '\n' ',')
sprite exec -s "$SPRITE" --env "$ENV_PAIRS" -- bash -c 'echo $MY_VAR'
```

**Warning:** This breaks if any .env value contains commas.
For safety, use the API directly or pass secrets individually.

### Check if sprite exists

```bash
if sprite list --prefix "$NAME" 2>/dev/null | grep -q "^$NAME "; then
  echo "Sprite exists"
else
  sprite create --skip-console "$NAME"
fi
```

### Batch exec with error handling

```bash
sprite exec -s "$SPRITE" -- bash -c '
  set -euo pipefail
  cd /home/sprite/repos/myapp
  git fetch origin main
  git checkout main
  git reset --hard FETCH_HEAD
  npm install
' || { echo "Sprite exec failed"; exit 1; }
```
