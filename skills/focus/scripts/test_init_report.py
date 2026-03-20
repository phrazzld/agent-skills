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
                "score": {
                    "semantic": 0.82,
                    "coverage": 0.9,
                    "overlap": 0.05,
                },
            }
        ],
        "selected_primitives": [
            {
                "name": "codified-context-architecture",
                "kind": "skill",
                "reason": "Best match for repo tuning.",
                "selected_because": "Highest coverage for repo-tuning need with minimal overlap.",
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

    def test_selected_candidate_requires_primitive(self) -> None:
        broken = valid_report()
        broken["candidate_matrix"][0].pop("primitive")

        result = self.run_script("write", "--output", "/tmp/ignored.json", input_text=json.dumps(broken))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("report.candidate_matrix[0].primitive is required", result.stderr)

    def test_gap_candidate_can_omit_primitive(self) -> None:
        report = valid_report()
        report["candidate_matrix"] = [
            {
                "wishlist_item": "repo tuning",
                "status": "gap",
                "rationale": "No existing primitive covers this need.",
                "evidence": ["catalog search returned no strong matches"],
            }
        ]
        report["selected_primitives"] = []

        result = self.run_script("write", "--output", "/tmp/ignored.json", input_text=json.dumps(report))
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_repo_summary_requires_documented_fields(self) -> None:
        broken = valid_report()
        broken["repo_summary"].pop("signals")

        result = self.run_script("write", "--output", "/tmp/ignored.json", input_text=json.dumps(broken))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("report.repo_summary.signals is required", result.stderr)

    def test_candidate_matrix_requires_score(self) -> None:
        broken = valid_report()
        broken["candidate_matrix"][0].pop("score")

        result = self.run_script("write", "--output", "/tmp/ignored.json", input_text=json.dumps(broken))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("report.candidate_matrix[0].score is required", result.stderr)

    def test_candidate_score_requires_all_dimensions(self) -> None:
        for dimension in ("semantic", "coverage", "overlap"):
            broken = valid_report()
            broken["candidate_matrix"][0]["score"].pop(dimension)

            result = self.run_script("write", "--output", "/tmp/ignored.json", input_text=json.dumps(broken))
            self.assertNotEqual(result.returncode, 0, f"should fail when {dimension} missing")
            self.assertIn(
                f"report.candidate_matrix[0].score.{dimension}",
                result.stderr,
                f"error should name {dimension}",
            )

    def test_candidate_score_rejects_non_positive(self) -> None:
        broken = valid_report()
        broken["candidate_matrix"][0]["score"]["semantic"] = 0

        result = self.run_script("write", "--output", "/tmp/ignored.json", input_text=json.dumps(broken))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("report.candidate_matrix[0].score.semantic", result.stderr)

    def test_gap_candidate_score_optional(self) -> None:
        report = valid_report()
        report["candidate_matrix"] = [
            {
                "wishlist_item": "selection telemetry",
                "status": "gap",
                "rationale": "No existing primitive covers this need.",
                "evidence": ["catalog search returned no strong matches"],
            }
        ]
        report["selected_primitives"] = []

        result = self.run_script("write", "--output", "/tmp/ignored.json", input_text=json.dumps(report))
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_selected_primitives_requires_selected_because(self) -> None:
        broken = valid_report()
        broken["selected_primitives"][0].pop("selected_because")

        result = self.run_script("write", "--output", "/tmp/ignored.json", input_text=json.dumps(broken))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("report.selected_primitives[0].selected_because", result.stderr)

    def test_rejected_candidate_requires_rationale(self) -> None:
        report = valid_report()
        report["candidate_matrix"].append({
            "wishlist_item": "repo tuning",
            "primitive": "phrazzld/spellbook@harness-engineering",
            "status": "rejected",
            "rationale": "Overlaps with codified-context-architecture on repo structure concerns.",
            "evidence": ["description overlap with selected candidate"],
            "score": {"semantic": 0.7, "coverage": 0.3, "overlap": 0.8},
        })

        result = self.run_script("write", "--output", "/tmp/ignored.json", input_text=json.dumps(report))
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_rejected_candidate_without_rationale_fails(self) -> None:
        report = valid_report()
        report["candidate_matrix"].append({
            "wishlist_item": "repo tuning",
            "primitive": "phrazzld/spellbook@harness-engineering",
            "status": "rejected",
            "rationale": "",
            "evidence": ["description overlap"],
            "score": {"semantic": 0.7, "coverage": 0.3, "overlap": 0.8},
        })

        result = self.run_script("write", "--output", "/tmp/ignored.json", input_text=json.dumps(report))
        self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
