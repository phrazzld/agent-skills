#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scaffold-expo.sh [--root <path>] [--template <expo-template>]

Purpose:
  Scaffold an Expo app at apps/mobile inside an existing Turbo monorepo.

Behavior:
  - Verifies monorepo root (package.json + turbo.json)
  - Creates apps/mobile when missing
  - Runs npx create-expo-app once (idempotent)
  - Writes a monorepo-safe metro.config.js
  - Ensures workspace patterns in root package.json
  - Adds/merges dev/build/lint/typecheck in turbo.json

Examples:
  scaffold-expo.sh
  scaffold-expo.sh --template blank-typescript
  scaffold-expo.sh --root ~/code/my-monorepo
EOF
}

log() { printf '[mobile-migrate] %s\n' "$*"; }
die() { printf '[mobile-migrate] ERROR: %s\n' "$*" >&2; exit 1; }

ROOT_DIR="$(pwd)"
EXPO_TEMPLATE="blank-typescript"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      [[ $# -ge 2 ]] || die "--root requires a value"
      ROOT_DIR="$2"
      shift 2
      ;;
    --template)
      [[ $# -ge 2 ]] || die "--template requires a value"
      EXPO_TEMPLATE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1 (use --help)"
      ;;
  esac
done

[[ -d "$ROOT_DIR" ]] || die "root does not exist: $ROOT_DIR"
cd "$ROOT_DIR"

[[ -f package.json ]] || die "package.json not found at repo root: $ROOT_DIR"
[[ -f turbo.json ]] || die "turbo.json not found at repo root: $ROOT_DIR"

if [[ ! -d apps && ! -f pnpm-workspace.yaml ]]; then
  log "apps/ missing; creating standard monorepo directories"
fi
mkdir -p apps packages
mkdir -p apps/mobile

MOBILE_DIR="$ROOT_DIR/apps/mobile"
MOBILE_PKG="$MOBILE_DIR/package.json"

if [[ -f "$MOBILE_PKG" ]]; then
  log "apps/mobile already scaffolded; skipping create-expo-app"
else
  log "scaffolding Expo app at apps/mobile (template: $EXPO_TEMPLATE)"
  npx create-expo-app@latest "$MOBILE_DIR" --template "$EXPO_TEMPLATE"
fi

log "writing metro.config.js for monorepo"
cat > "$MOBILE_DIR/metro.config.js" <<'EOF'
const path = require('path');
const { getDefaultConfig } = require('expo/metro-config');

const projectRoot = __dirname;
const workspaceRoot = path.resolve(projectRoot, '../..');

const config = getDefaultConfig(projectRoot);

config.watchFolders = [workspaceRoot];
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, 'node_modules'),
  path.resolve(workspaceRoot, 'node_modules'),
];
config.resolver.disableHierarchicalLookup = true;

module.exports = config;
EOF

log "ensuring workspace patterns in root package.json"
python3 - <<'PY'
from __future__ import annotations

import json
from pathlib import Path

root = Path.cwd()
pkg_path = root / "package.json"
data = json.loads(pkg_path.read_text(encoding="utf-8"))

def ensure_workspace_patterns(obj: dict) -> bool:
    changed = False
    patterns = ["apps/*", "packages/*"]
    workspaces = obj.get("workspaces")

    if workspaces is None:
        obj["workspaces"] = patterns
        return True

    if isinstance(workspaces, list):
        for pat in patterns:
            if pat not in workspaces:
                workspaces.append(pat)
                changed = True
        return changed

    if isinstance(workspaces, dict):
        pkgs = workspaces.setdefault("packages", [])
        for pat in patterns:
            if pat not in pkgs:
                pkgs.append(pat)
                changed = True
        return changed

    return False

changed = ensure_workspace_patterns(data)

if changed:
    pkg_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY

log "ensuring workspace refs inside apps/mobile/package.json"
python3 - <<'PY'
from __future__ import annotations

import json
from pathlib import Path

root = Path.cwd()
mobile_pkg_path = root / "apps" / "mobile" / "package.json"

if not mobile_pkg_path.exists():
    raise SystemExit("apps/mobile/package.json missing after scaffold")

mobile = json.loads(mobile_pkg_path.read_text(encoding="utf-8"))
mobile_changed = False

if mobile.get("private") is not True:
    mobile["private"] = True
    mobile_changed = True

if mobile.get("name") != "@apps/mobile":
    mobile["name"] = "@apps/mobile"
    mobile_changed = True

scripts = mobile.setdefault("scripts", {})
script_defaults = {
    "dev": "expo start --clear",
    "start": "expo start",
    "ios": "expo run:ios",
    "android": "expo run:android",
    "web": "expo start --web",
    "lint": "expo lint",
}

for key, value in script_defaults.items():
    if key not in scripts:
        scripts[key] = value
        mobile_changed = True

shared_pkg_path = root / "packages" / "shared" / "package.json"
if shared_pkg_path.exists():
    shared = json.loads(shared_pkg_path.read_text(encoding="utf-8"))
    shared_name = shared.get("name")
    if shared_name:
        deps = mobile.setdefault("dependencies", {})
        if deps.get(shared_name) != "workspace:*":
            deps[shared_name] = "workspace:*"
            mobile_changed = True

if mobile_changed:
    mobile_pkg_path.write_text(json.dumps(mobile, indent=2) + "\n", encoding="utf-8")
PY

log "merging turbo.json pipeline entries"
python3 - <<'PY'
from __future__ import annotations

import json
from pathlib import Path

root = Path.cwd()
turbo_path = root / "turbo.json"
turbo = json.loads(turbo_path.read_text(encoding="utf-8"))

pipeline = turbo.setdefault("pipeline", {})
changed = False

def merge_task(name: str, defaults: dict) -> None:
    global changed
    task = pipeline.get(name)
    if task is None:
        pipeline[name] = defaults
        changed = True
        return
    for key, value in defaults.items():
        if key not in task:
            task[key] = value
            changed = True

merge_task("dev", {"cache": False, "persistent": True})
merge_task("build", {"dependsOn": ["^build"], "outputs": ["dist/**", "build/**"]})
merge_task("lint", {"dependsOn": ["^lint"]})
merge_task("typecheck", {"dependsOn": ["^typecheck"]})

if changed:
    turbo_path.write_text(json.dumps(turbo, indent=2) + "\n", encoding="utf-8")
PY

log "done. next: install deps, then run: turbo run dev --filter=@apps/mobile"
