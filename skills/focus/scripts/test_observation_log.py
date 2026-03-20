from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("observation_log.py")


def valid_events() -> list[dict[str, object]]:
    return [
        {
            "type": "selected",
            "summary": "Selected codified-context-architecture for repo tuning.",
            "context": "High semantic match and low overlap with the other candidates.",
            "confidence": 0.82,
            "primitive": "phrazzld/spellbook@codified-context-architecture",
            "wishlist_item": "repo tuning",
            "run_kind": "init",
        },
        {
            "type": "excluded",
            "summary": "Excluded harness-engineering from the initial subset.",
            "context": "The global install already covers the same operational ground.",
            "confidence": 0.73,
            "primitive": "phrazzld/spellbook@harness-engineering",
            "wishlist_item": "repo tuning",
            "run_kind": "init",
            "related_primitive": "phrazzld/spellbook@codified-context-architecture",
        },
        {
            "type": "gap",
            "summary": "No skill matched factory-specific routing policy.",
            "context": "Catalog search found no strong candidate for the repo-specific conventions.",
            "confidence": 0.71,
            "wishlist_item": "factory-specific routing policy",
            "run_kind": "init",
            "gap_scope": "spellbook",
        },
    ]


class ObservationLogScriptTest(unittest.TestCase):
    def run_script(self, *args: str, input_text: str | None = None) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT), *args],
            input=input_text,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_append_and_validate_round_trip(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            output = Path(tmpdir) / ".spellbook" / "observations.ndjson"

            append = self.run_script(
                "append",
                "--output",
                str(output),
                input_text=json.dumps(valid_events()),
            )
            self.assertEqual(append.returncode, 0, append.stderr)
            self.assertTrue(output.exists())

            lines = output.read_text(encoding="utf-8").strip().splitlines()
            self.assertEqual(len(lines), 3)

            for line in lines:
                event = json.loads(line)
                self.assertIn("timestamp", event)
                self.assertIn(event["type"], {"selected", "excluded", "gap"})

            validate = self.run_script("validate", str(output))
            self.assertEqual(validate.returncode, 0, validate.stderr)
            self.assertEqual(validate.stdout.strip(), "ok")

    def test_selected_requires_primitive(self) -> None:
        broken = valid_events()
        broken[0].pop("primitive")

        result = self.run_script("append", "--output", "/tmp/ignored.ndjson", input_text=json.dumps(broken))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("event[0].primitive is required for type=selected", result.stderr)

    def test_gap_requires_scope_but_not_primitive(self) -> None:
        events = [valid_events()[2]]

        result = self.run_script("append", "--output", "/tmp/ignored.ndjson", input_text=json.dumps(events))
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_append_rejects_blank_timestamp_when_provided(self) -> None:
        events = valid_events()
        events[0]["timestamp"] = ""

        result = self.run_script("append", "--output", "/tmp/ignored.ndjson", input_text=json.dumps(events))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("event[0].timestamp must be a non-empty string", result.stderr)

    def test_sync_outcomes_require_primitive(self) -> None:
        result = self.run_script(
            "append",
            "--output",
            "/tmp/ignored.ndjson",
            input_text=json.dumps(
                [
                    {
                        "type": "installed",
                        "summary": "Installed debug into all harness targets.",
                        "context": "The manifest declared it and distribution completed cleanly.",
                        "confidence": 0.9,
                        "run_kind": "sync",
                    }
                ]
            ),
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("event[0].primitive is required for type=installed", result.stderr)


if __name__ == "__main__":
    unittest.main()
