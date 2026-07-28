#!/usr/bin/env python3
"""Build a fail-closed, linked QA evidence index for one simulator matrix run."""
from __future__ import annotations

import html
import json
import subprocess
import sys
from pathlib import Path

from qa_artifact_schemas import QAArtifactError, load as load_artifact, validate


def load(path: Path, kind: str) -> dict:
    try:
        return load_artifact(path, kind)
    except QAArtifactError as exc:
        raise SystemExit(f"qa-index: {exc}") from exc


def main() -> int:
    if len(sys.argv) != 4:
        raise SystemExit("usage: generate_qa_evidence_index.py ARTIFACT_ROOT BASELINE_JSON REPO_ROOT")
    root = Path(sys.argv[1]).resolve()
    baseline_path = Path(sys.argv[2]).resolve()
    repo = Path(sys.argv[3]).resolve()
    baseline = load(baseline_path, "baseline")
    artifacts = {
        "matrix": ("matrix-receipt.json", load(root / "matrix-receipt.json", "matrix")),
        "triage": ("visual-triage.json", load(root / "visual-triage.json", "triage")),
        "history": ("visual-history-entry.json", load(root / "visual-history-entry.json", "history")),
        "trend": ("visual-trend.json", load(root / "visual-trend.json", "trend")),
        "anomalyReview": ("anomaly-review.json", load(root / "anomaly-review.json", "anomaly")),
    }
    current = subprocess.check_output(["git", "-C", str(repo), "rev-parse", "--short", "HEAD"], text=True).strip()
    errors: list[str] = []
    for name, (_, value) in artifacts.items():
        commit = value.get("commit", value.get("currentCommit"))
        if commit != current:
            errors.append(f"{name}: commit {commit!r} does not match {current}")
    for name in ("matrix", "triage", "history"):
        if artifacts[name][1].get("status") != "pass":
            errors.append(f"{name}: status is not pass")
    counts = baseline.get("counts", {})
    expected_counts = {"swiftPackage": 211, "simulatorHosted": 319, "uiJourneys": 10}
    if counts != expected_counts or baseline.get("status") != "pass":
        errors.append("non-device baseline registry is invalid or unexpectedly changed")
    links = [
        ("Contact sheet", "contact-sheet.jpg"),
        ("Matrix receipt", "matrix-receipt.json"),
        ("Visual triage", "visual-triage.md"),
        ("Cross-run trend", "visual-trend.md"),
        ("Anomaly review", "anomaly-review.html"),
        ("Anomaly review JSON", "anomaly-review.json"),
    ]
    for label, relative in links:
        path = root / relative
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"missing linked evidence: {label} ({relative})")
    payload = {
        "schemaVersion": 1,
        "status": "fail" if errors else "pass",
        "commit": current,
        "testBaseline": baseline,
        "visualEvidence": {
            "panelCount": artifacts["matrix"][1].get("expectedPanelCount"),
            "matrixStatus": artifacts["matrix"][1].get("status"),
            "triageStatus": artifacts["triage"][1].get("status"),
            "trendStatus": artifacts["trend"][1].get("status"),
            "anomalyStatus": artifacts["anomalyReview"][1].get("status"),
            "baselineCommit": artifacts["trend"][1].get("baselineCommit"),
        },
        "links": [{"label": label, "path": path} for label, path in links],
        "errors": errors,
        "limitations": "Simulator/non-device evidence index only; physical-device acceptance remains separate.",
    }
    validate("index", payload)
    (root / "qa-index.json").write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
    rows = "\n".join(f"| [{label}]({path}) | `{path}` |" for label, path in links)
    markdown = f"""# QA evidence index

- Commit: `{current}`
- Status: **{payload['status'].upper()}**
- Package tests: **{counts.get('swiftPackage')}**
- Simulator-hosted tests: **{counts.get('simulatorHosted')}**
- UI journeys: **{counts.get('uiJourneys')}**
- Visual panels: **{payload['visualEvidence']['panelCount']}**
- Trend: **{payload['visualEvidence']['trendStatus']}**
- Anomaly review: **{payload['visualEvidence']['anomalyStatus']}**

| Evidence | Path |
|---|---|
{rows}

> Simulator/non-device evidence only. Physical-device thermal, touch, haptic, audio-route, and ART acceptance remain separate.
"""
    (root / "qa-index.md").write_text(markdown)
    cards = "".join(f'<li><a href="{html.escape(path)}">{html.escape(label)}</a><code>{html.escape(path)}</code></li>' for label, path in links)
    page = f"""<!doctype html><meta charset="utf-8"><title>QA evidence index</title>
<style>body{{font:17px -apple-system;background:#111;color:#eee;max-width:980px;margin:40px auto;padding:0 20px}}a{{color:#5ee}}li{{margin:14px 0}}code{{display:block;color:#aaa}}.stats{{display:grid;grid-template-columns:repeat(4,1fr);gap:12px}}.stat{{background:#20262c;padding:16px;border-radius:10px}}strong{{font-size:24px}}</style>
<h1>QA evidence index</h1><p>Commit <code>{html.escape(current)}</code> · status <strong>{payload['status'].upper()}</strong></p>
<div class="stats"><div class="stat"><strong>{counts.get('swiftPackage')}</strong><br>package</div><div class="stat"><strong>{counts.get('simulatorHosted')}</strong><br>simulator</div><div class="stat"><strong>{counts.get('uiJourneys')}</strong><br>UI journeys</div><div class="stat"><strong>{payload['visualEvidence']['panelCount']}</strong><br>visual panels</div></div>
<h2>Evidence</h2><ul>{cards}</ul><p>Simulator/non-device evidence only. Physical-device acceptance remains separate.</p>"""
    (root / "qa-index.html").write_text(page)
    if errors:
        raise SystemExit("qa-index failed: " + "; ".join(errors))
    print(f"qa-index: PASS commit={current} links={len(links)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
