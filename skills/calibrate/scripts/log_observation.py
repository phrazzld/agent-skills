#!/usr/bin/env python3
"""
Log a Spellbook observation to .spellbook/observations.ndjson.

Usage:
    log_observation.py --primitive NAME --type TYPE --summary TEXT --context TEXT --confidence FLOAT
"""

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path


VALID_TYPES = {"friction", "gap", "error", "enhancement"}


def main():
    parser = argparse.ArgumentParser(description="Log a Spellbook observation")
    parser.add_argument("--primitive", required=True, help="e.g. phrazzld/spellbook@autopilot")
    parser.add_argument("--type", required=True, choices=sorted(VALID_TYPES), help="Observation type")
    parser.add_argument("--summary", required=True, help="Brief description")
    parser.add_argument("--context", required=True, help="Detailed context")
    parser.add_argument("--confidence", required=True, type=float, help="0.0 to 1.0")
    args = parser.parse_args()

    if not 0.0 <= args.confidence <= 1.0:
        print("[x] Error: confidence must be between 0.0 and 1.0")
        raise SystemExit(1)

    obs_dir = Path(".spellbook")
    obs_dir.mkdir(exist_ok=True)

    observation = {
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "primitive": args.primitive,
        "type": args.type,
        "summary": args.summary,
        "context": args.context,
        "confidence": args.confidence,
    }

    obs_file = obs_dir / "observations.ndjson"
    with open(obs_file, "a") as f:
        f.write(json.dumps(observation) + "\n")

    print(f"[OK] Logged {args.type} observation for {args.primitive}")
    print(f"     File: {obs_file}")


if __name__ == "__main__":
    main()
