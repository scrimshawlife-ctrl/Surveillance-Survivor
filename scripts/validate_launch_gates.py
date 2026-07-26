#!/usr/bin/env python3
"""Validate docs/launch/launch_gates.json honesty. See design 2026-07-26."""

from __future__ import annotations

from pathlib import Path
from typing import Any


def derive_overall(data: dict[str, Any]) -> str:
    raise NotImplementedError


def validate_data(
    data: dict[str, Any], root: Path, tip_short: str
) -> list[str]:
    raise NotImplementedError


def main() -> int:
    print("launch-gate-check: not implemented", flush=True)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
