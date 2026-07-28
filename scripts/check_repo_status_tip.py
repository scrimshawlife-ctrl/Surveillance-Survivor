#!/usr/bin/env python3
"""Validate that docs/REPO_STATUS.md names a real, reachable implementation baseline.

Branches, including merge commits on main, may intentionally build on a documented
implementation baseline, so auto/CI validation requires that the status SHA exists
and is an ancestor of HEAD. Explicit ``--mode main`` retains the exact-match audit.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

STATUS_PATH = Path("docs/REPO_STATUS.md")
TIP_PATTERN = re.compile(r"\*\*`main` tip:\*\*\s*`([0-9a-fA-F]{7,40})`")


class StatusError(RuntimeError):
    pass


def git(*args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise StatusError(f"git {' '.join(args)} failed: {detail}")
    return result.stdout.strip()


def documented_tip(text: str) -> str:
    match = TIP_PATTERN.search(text)
    if not match:
        raise StatusError("docs/REPO_STATUS.md is missing a valid '**`main` tip:** `<sha>`' field")
    return match.group(1).lower()


def branch_name() -> str:
    github_ref = os.environ.get("GITHUB_REF_NAME", "").strip()
    if github_ref:
        return github_ref
    return git("branch", "--show-current")


def validate(mode: str) -> tuple[str, str, str]:
    if not STATUS_PATH.is_file():
        raise StatusError(f"missing {STATUS_PATH}")

    stated = documented_tip(STATUS_PATH.read_text(encoding="utf-8"))
    try:
        resolved = git("rev-parse", f"{stated}^{{commit}}")
    except StatusError as exc:
        raise StatusError(f"documented status SHA does not exist: {stated}") from exc

    head = git("rev-parse", "HEAD")
    branch = branch_name()
    exact_required = mode == "main"

    if exact_required:
        if resolved != head:
            raise StatusError(
                f"stale main status: documented {resolved[:12]} but HEAD is {head[:12]}; "
                "run 'make repo-status-refresh' after updating evidence text"
            )
    else:
        ancestor = subprocess.run(
            ["git", "merge-base", "--is-ancestor", resolved, head],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if ancestor.returncode != 0:
            raise StatusError(
                f"documented status SHA {resolved[:12]} is not an ancestor of HEAD {head[:12]}"
            )

    return resolved, head, branch


def refresh() -> None:
    if not STATUS_PATH.is_file():
        raise StatusError(f"missing {STATUS_PATH}")
    text = STATUS_PATH.read_text(encoding="utf-8")
    current = documented_tip(text)
    head_short = git("rev-parse", "--short=7", "HEAD")
    updated = TIP_PATTERN.sub(f"**`main` tip:** `{head_short}`", text, count=1)
    if updated == text and current == head_short:
        print(f"repo status already references {head_short}")
        return
    STATUS_PATH.write_text(updated, encoding="utf-8")
    print(f"updated {STATUS_PATH} main tip: {current} -> {head_short}")
    print("Review all human-owned evidence and gate language before committing this refresh.")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=("auto", "ci", "main"), default="auto")
    parser.add_argument("--refresh", action="store_true")
    args = parser.parse_args()

    try:
        if args.refresh:
            refresh()
            return 0
        resolved, head, branch = validate(args.mode)
    except StatusError as exc:
        print(f"repo-status-check: FAIL: {exc}", file=sys.stderr)
        return 1

    print(
        "repo-status-check: PASS: "
        f"documented={resolved[:12]} head={head[:12]} branch={branch or '(detached)'}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
