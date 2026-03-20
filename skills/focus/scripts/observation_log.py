#!/usr/bin/env python3
"""Validate and append /focus observation events."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

VALID_TYPES = {
    "selected": ("primitive", "wishlist_item", "run_kind"),
    "excluded": ("primitive", "wishlist_item", "run_kind"),
    "gap": ("wishlist_item", "run_kind", "gap_scope"),
    "installed": ("primitive", "run_kind"),
    "updated": ("primitive", "run_kind"),
    "removed": ("primitive", "run_kind"),
    "undertriggered": ("primitive", "run_kind"),
}
VALID_RUN_KINDS = {"init", "sync", "improve", "manual"}
VALID_GAP_SCOPES = {"repo-local", "spellbook"}


def _expect_dict(value: object, path: str) -> list[str]:
    if isinstance(value, dict):
        return []
    return [f"{path} must be an object"]


def _expect_non_empty_string(value: object, path: str) -> list[str]:
    if isinstance(value, str) and value.strip():
        return []
    return [f"{path} must be a non-empty string"]


def _expect_confidence(value: object, path: str) -> list[str]:
    if isinstance(value, (int, float)) and not isinstance(value, bool) and 0 <= value <= 1:
        return []
    return [f"{path} must be a number between 0 and 1"]


def validate_event(event: object, path: str, *, require_timestamp: bool) -> list[str]:
    errors = _expect_dict(event, path)
    if errors:
        return errors

    data = event
    assert isinstance(data, dict)

    for field in ("type", "summary", "context"):
        if field not in data:
            errors.append(f"{path}.{field} is required")
        else:
            errors.extend(_expect_non_empty_string(data[field], f"{path}.{field}"))

    if "confidence" not in data:
        errors.append(f"{path}.confidence is required")
    else:
        errors.extend(_expect_confidence(data["confidence"], f"{path}.confidence"))

    if require_timestamp:
        if "timestamp" not in data:
            errors.append(f"{path}.timestamp is required")
        else:
            errors.extend(_expect_non_empty_string(data["timestamp"], f"{path}.timestamp"))
    elif "timestamp" in data:
        errors.extend(_expect_non_empty_string(data["timestamp"], f"{path}.timestamp"))

    if errors:
        return errors

    event_type = data["type"]
    assert isinstance(event_type, str)
    if event_type not in VALID_TYPES:
        errors.append(f"{path}.type must be one of: {', '.join(sorted(VALID_TYPES))}")
        return errors

    for field in VALID_TYPES[event_type]:
        if field not in data:
            errors.append(f"{path}.{field} is required for type={event_type}")
        else:
            errors.extend(_expect_non_empty_string(data[field], f"{path}.{field}"))

    run_kind = data.get("run_kind")
    if isinstance(run_kind, str) and run_kind not in VALID_RUN_KINDS:
        errors.append(
            f"{path}.run_kind must be one of: {', '.join(sorted(VALID_RUN_KINDS))}"
        )

    gap_scope = data.get("gap_scope")
    if isinstance(gap_scope, str) and gap_scope not in VALID_GAP_SCOPES:
        errors.append(
            f"{path}.gap_scope must be one of: {', '.join(sorted(VALID_GAP_SCOPES))}"
        )

    return errors


def _read_json(path: str | None) -> object:
    if path in (None, "-"):
        raw = sys.stdin.read()
    else:
        raw = Path(path).read_text(encoding="utf-8")
    return json.loads(raw)


def _read_events(path: str | None) -> list[dict[str, object]]:
    payload = _read_json(path)
    if isinstance(payload, dict):
        events = [payload]
    elif isinstance(payload, list):
        events = payload
    else:
        raise ValueError("input must be a JSON object or array of objects")

    typed_events: list[dict[str, object]] = []
    for event in events:
        if not isinstance(event, dict):
            raise ValueError("every event must be a JSON object")
        typed_events.append(dict(event))
    return typed_events


def cmd_append(args: argparse.Namespace) -> int:
    try:
        events = _read_events(args.input)
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        return 1

    errors: list[str] = []
    for index, event in enumerate(events):
        errors.extend(validate_event(event, f"event[{index}]", require_timestamp=False))

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)

    with output.open("a", encoding="utf-8") as handle:
        for event in events:
            event.setdefault(
                "timestamp",
                datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            )
            handle.write(json.dumps(event, sort_keys=True) + "\n")

    print(output)
    return 0


def cmd_validate(args: argparse.Namespace) -> int:
    path = Path(args.path)
    try:
        raw_lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    errors: list[str] = []
    event_count = 0

    for line_number, raw_line in enumerate(raw_lines, start=1):
        line = raw_line.strip()
        if not line:
            continue
        event_count += 1
        try:
            payload = json.loads(line)
        except json.JSONDecodeError as exc:
            errors.append(f"line {line_number}: invalid JSON ({exc.msg})")
            continue
        errors.extend(validate_event(payload, f"line {line_number}", require_timestamp=True))

    if event_count == 0:
        errors.append("observations log must contain at least one event")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("ok")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Append and validate /focus observation events")
    subparsers = parser.add_subparsers(dest="command", required=True)

    append_parser = subparsers.add_parser("append", help="append validated events to an NDJSON file")
    append_parser.add_argument("--output", required=True, help="path to .spellbook/observations.ndjson")
    append_parser.add_argument("--input", help="JSON file containing one event object or an array; defaults to stdin")
    append_parser.set_defaults(func=cmd_append)

    validate_parser = subparsers.add_parser("validate", help="validate an NDJSON observations file")
    validate_parser.add_argument("path", help="path to .spellbook/observations.ndjson")
    validate_parser.set_defaults(func=cmd_validate)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
