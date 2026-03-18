#!/usr/bin/env bash
# Verify vendored copies in skills/focus/scripts/ match their canonical sources.
# Run from repo root. Non-zero exit means drift detected.

set -euo pipefail

errors=0

check() {
    local canonical="$1" vendored="$2"
    if ! diff -q "$canonical" "$vendored" >/dev/null 2>&1; then
        echo "DRIFT: $vendored differs from $canonical"
        errors=$((errors + 1))
    fi
}

check scripts/lib/search_core.py skills/focus/scripts/search_core.py
check scripts/gemini_embeddings.py skills/focus/scripts/gemini_embeddings.py

if [ "$errors" -gt 0 ]; then
    echo "$errors vendored file(s) out of sync. Copy canonical → vendored."
    exit 1
fi

echo "All vendored copies in sync."
