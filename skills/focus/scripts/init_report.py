#!/usr/bin/env python3
"""Validate and persist /focus init reports."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

TOP_LEVEL_KEYS = (
    "repo_summary",
    "wishlist",
    "candidate_matrix",
    "selected_primitives",
    "gaps",
    "confidence",
)


def _expect_dict(value: object, path: str) -> list[str]:
    if isinstance(value, dict):
        return []
    return [f"{path} must be an object"]


def _expect_list(value: object, path: str) -> list[str]:
    if isinstance(value, list):
        return []
    return [f"{path} must be an array"]


def _expect_non_empty_string(value: object, path: str) -> list[str]:
    if isinstance(value, str) and value.strip():
        return []
    return [f"{path} must be a non-empty string"]


def _expect_non_negative_number(value: object, path: str) -> list[str]:
    if isinstance(value, (int, float)) and not isinstance(value, bool) and value >= 0:
        return []
    return [f"{path} must be a non-negative number"]


def _expect_string_list(
    value: object,
    path: str,
    *,
    allow_empty: bool,
) -> list[str]:
    errors = _expect_list(value, path)
    if errors:
        return errors

    items = value
    assert isinstance(items, list)
    if not allow_empty and not items:
        return [f"{path} must be a non-empty array"]

    for index, item in enumerate(items):
        errors.extend(_expect_non_empty_string(item, f"{path}[{index}]"))
    return errors


def _validate_object(
    value: object,
    path: str,
    required_fields: tuple[str, ...],
) -> list[str]:
    errors = _expect_dict(value, path)
    if errors:
        return errors

    data = value
    assert isinstance(data, dict)
    for field in required_fields:
        if field not in data:
            errors.append(f"{path}.{field} is required")
            continue
        errors.extend(_expect_non_empty_string(data[field], f"{path}.{field}"))
    return errors


def validate_report(report: object) -> list[str]:
    errors = _expect_dict(report, "report")
    if errors:
        return errors

    data = report
    assert isinstance(data, dict)

    for key in TOP_LEVEL_KEYS:
        if key not in data:
            errors.append(f"report.{key} is required")

    if errors:
        return errors

    errors.extend(
        _validate_object(
            data["repo_summary"],
            "report.repo_summary",
            ("project",),
        )
    )
    errors.extend(_expect_list(data["wishlist"], "report.wishlist"))
    errors.extend(_expect_list(data["candidate_matrix"], "report.candidate_matrix"))
    errors.extend(_expect_list(data["selected_primitives"], "report.selected_primitives"))
    errors.extend(_expect_list(data["gaps"], "report.gaps"))
    errors.extend(_expect_dict(data["confidence"], "report.confidence"))
    if errors:
        return errors

    wishlist = data["wishlist"]
    candidate_matrix = data["candidate_matrix"]
    selected_primitives = data["selected_primitives"]
    gaps = data["gaps"]
    confidence = data["confidence"]

    assert isinstance(wishlist, list)
    assert isinstance(candidate_matrix, list)
    assert isinstance(selected_primitives, list)
    assert isinstance(gaps, list)
    assert isinstance(confidence, dict)

    repo_summary = data["repo_summary"]
    assert isinstance(repo_summary, dict)

    if not wishlist:
        errors.append("report.wishlist must contain at least one item")
    if not candidate_matrix:
        errors.append("report.candidate_matrix must contain at least one row")

    for field in ("stack", "domains", "services", "signals"):
        if field not in repo_summary:
            errors.append(f"report.repo_summary.{field} is required")
            continue
        errors.extend(
            _expect_string_list(
                repo_summary[field],
                f"report.repo_summary.{field}",
                allow_empty=(field == "services"),
            )
        )

    for index, item in enumerate(wishlist):
        errors.extend(
            _validate_object(item, f"report.wishlist[{index}]", ("name", "why"))
        )

    for index, item in enumerate(candidate_matrix):
        errors.extend(
            _validate_object(
                item,
                f"report.candidate_matrix[{index}]",
                ("wishlist_item", "status", "rationale"),
            )
        )
        if isinstance(item, dict):
            status = item.get("status")
            if status != "gap":
                if "primitive" not in item:
                    errors.append(f"report.candidate_matrix[{index}].primitive is required")
                else:
                    errors.extend(
                        _expect_non_empty_string(
                            item["primitive"],
                            f"report.candidate_matrix[{index}].primitive",
                        )
                    )

                score_path = f"report.candidate_matrix[{index}].score"
                if "score" not in item:
                    errors.append(f"{score_path} is required")
                else:
                    errors.extend(_expect_dict(item["score"], score_path))
                    if isinstance(item["score"], dict):
                        for dim in ("semantic", "coverage", "overlap"):
                            if dim not in item["score"]:
                                errors.append(f"{score_path}.{dim} is required")
                            else:
                                errors.extend(
                                    _expect_non_negative_number(
                                        item["score"][dim], f"{score_path}.{dim}"
                                    )
                                )

            if "evidence" not in item:
                errors.append(f"report.candidate_matrix[{index}].evidence is required")
            else:
                errors.extend(
                    _expect_string_list(
                        item["evidence"],
                        f"report.candidate_matrix[{index}].evidence",
                        allow_empty=False,
                    )
                )

    for index, item in enumerate(selected_primitives):
        errors.extend(
            _validate_object(
                item,
                f"report.selected_primitives[{index}]",
                ("name", "kind", "selected_because"),
            )
        )

    for index, item in enumerate(gaps):
        errors.extend(
            _validate_object(item, f"report.gaps[{index}]", ("name", "why", "next_action"))
        )

    for field in ("level", "summary"):
        if field not in confidence:
            errors.append(f"report.confidence.{field} is required")
        else:
            errors.extend(
                _expect_non_empty_string(confidence[field], f"report.confidence.{field}")
            )

    if "open_questions" not in confidence:
        errors.append("report.confidence.open_questions is required")
    else:
        errors.extend(
            _expect_string_list(
                confidence["open_questions"],
                "report.confidence.open_questions",
                allow_empty=True,
            )
        )

    return errors


def _read_json(path: str | None) -> object:
    if path in (None, "-"):
        raw = sys.stdin.read()
    else:
        raw = Path(path).read_text(encoding="utf-8")
    return json.loads(raw)


def cmd_write(args: argparse.Namespace) -> int:
    report = _read_json(args.input)
    errors = validate_report(report)
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(output)
    return 0


def cmd_validate(args: argparse.Namespace) -> int:
    report = _read_json(args.path)
    errors = validate_report(report)
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1
    print("ok")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Validate and persist /focus init reports."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    write_parser = subparsers.add_parser("write", help="validate and write a report")
    write_parser.add_argument(
        "--input",
        default="-",
        help="JSON input path or - for stdin",
    )
    write_parser.add_argument(
        "--output",
        required=True,
        help="Path to write the validated init report",
    )
    write_parser.set_defaults(func=cmd_write)

    validate_parser = subparsers.add_parser("validate", help="validate an existing report")
    validate_parser.add_argument("path", help="Path to the init report JSON file")
    validate_parser.set_defaults(func=cmd_validate)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        return args.func(args)
    except json.JSONDecodeError as exc:
        print(f"invalid JSON: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
