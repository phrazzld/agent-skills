from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("init_report.py")


def valid_report() -> dict:
    return {
        "repo_summary": {
            "project": "Spellbook",
            "stack": ["markdown", "python"],
            "domains": ["agent tooling"],
            "services": ["GitHub"],
            "signals": ["README.md", "project.md"],
        },
        "wishlist": [
            {
                "name": "repo tuning",
                "why": "Agents need repo-specific context structure.",
            }
        ],
        "candidate_matrix": [
            {
                "wishlist_item": "repo tuning",
                "primitive": "phrazzld/spellbook@codified-context-architecture",
                "status": "selected",
                "rationale": "It matches the repo-tuning need directly.",
                "evidence": ["docs/context/** exists", "project.md references agent workflows"],
            }
        ],
        "selected_primitives": [
            {
                "name": "codified-context-architecture",
                "kind": "skill",
                "reason": "Best match for repo tuning.",
            }
        ],
        "gaps": [
            {
                "name": "selection telemetry",
                "why": "No durable report existed before this run.",
                "next_action": "persist init report",
            }
        ],
        "confidence": {
            "level": "medium",
            "summary": "Grounded in repo docs and file layout.",
            "open_questions": [],
        },
    }


class InitReportScriptTest(unittest.TestCase):
    def run_script(self, *args: str, input_text: str | None = None) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT), *args],
            input=input_text,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_write_and_validate_round_trip(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            output = Path(tmpdir) / ".spellbook" / "init-report.json"
            report_json = json.dumps(valid_report())

            write = self.run_script("write", "--output", str(output), input_text=report_json)
            self.assertEqual(write.returncode, 0, write.stderr)
            self.assertTrue(output.exists())

            validate = self.run_script("validate", str(output))
            self.assertEqual(validate.returncode, 0, validate.stderr)
            self.assertEqual(validate.stdout.strip(), "ok")

    def test_missing_top_level_key_fails(self) -> None:
        broken = valid_report()
        broken.pop("gaps")

        result = self.run_script("write", "--output", "/tmp/ignored.json", input_text=json.dumps(broken))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("report.gaps is required", result.stderr)

    def test_candidate_matrix_requires_evidence(self) -> None:
        broken = valid_report()
        broken["candidate_matrix"][0].pop("evidence")

        result = self.run_script("write", "--output", "/tmp/ignored.json", input_text=json.dumps(broken))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("report.candidate_matrix[0].evidence is required", result.stderr)


if __name__ == "__main__":
    unittest.main()
