#!/usr/bin/env python3
"""Unit tests for the bounded simctl launch retry helper."""

from __future__ import annotations

import os
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "scripts" / "lib" / "simctl_launch_retry.sh"


class SimctlLaunchRetryTests(unittest.TestCase):
    def run_helper(self, failures_before_success: int, attempts: int = 3) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            bin_dir = root / "bin"
            bin_dir.mkdir()
            state = root / "attempts"
            mock = bin_dir / "xcrun"
            mock.write_text(
                textwrap.dedent(
                    """\
                    #!/usr/bin/env bash
                    set -eu
                    if [[ "$1 $2" == "simctl launch" ]]; then
                      count=0
                      [[ -f "$MOCK_STATE" ]] && count="$(cat "$MOCK_STATE")"
                      count=$((count + 1))
                      printf '%s' "$count" > "$MOCK_STATE"
                      if (( count <= MOCK_FAILURES )); then
                        echo "CoreSimulator transient failure $count" >&2
                        exit 3
                      fi
                      echo "com.example.app: 4242"
                      exit 0
                    fi
                    if [[ "$1 $2" == "simctl terminate" ]]; then
                      exit 0
                    fi
                    echo "unexpected xcrun invocation: $*" >&2
                    exit 99
                    """
                ),
                encoding="utf-8",
            )
            mock.chmod(0o755)
            script = (
                f'source "{HELPER}"; '
                f'simctl_launch_with_retry simulator com.example.app {attempts} 0; '
                'status=$?; echo "status=$status output=$SIMCTL_LAUNCH_OUTPUT"; exit "$status"'
            )
            env = os.environ.copy()
            env.update(
                {
                    "PATH": f"{bin_dir}:{env['PATH']}",
                    "MOCK_STATE": str(state),
                    "MOCK_FAILURES": str(failures_before_success),
                }
            )
            return subprocess.run(
                ["bash", "-c", script],
                text=True,
                capture_output=True,
                env=env,
                check=False,
            )

    def test_succeeds_immediately(self) -> None:
        result = self.run_helper(0)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("com.example.app: 4242", result.stdout)
        self.assertNotIn("failed", result.stderr)

    def test_retries_transient_failures_and_preserves_diagnostics(self) -> None:
        result = self.run_helper(2)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("attempt 1/3 failed", result.stderr)
        self.assertIn("CoreSimulator transient failure 1", result.stderr)
        self.assertIn("attempt 2/3 failed", result.stderr)
        self.assertIn("com.example.app: 4242", result.stdout)

    def test_exhaustion_returns_final_status_and_error(self) -> None:
        result = self.run_helper(5)
        self.assertEqual(result.returncode, 3)
        self.assertIn("attempt 3/3 failed", result.stderr)
        self.assertIn("CoreSimulator transient failure 3", result.stderr)
        self.assertIn("exhausted 3 attempts", result.stderr)

    def test_rejects_invalid_attempt_count(self) -> None:
        result = self.run_helper(0, attempts=0)
        self.assertEqual(result.returncode, 64)
        self.assertIn("positive integer", result.stderr)


if __name__ == "__main__":
    raise SystemExit(unittest.main())
