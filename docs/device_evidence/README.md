# Device and automation evidence

Live extract JSON receipts (`live_extract_*`) are the primary Blind Spot extract
proof. Additional archived runner transcripts live under:

- `run_logs/` — physical-device suite / smoke / launch-shell transcripts
- `automation_runs/` — selected `run_automation_tests.sh` PASS receipts

Root-level `.device-*.log`, `.launch-smoke-run.log`, and `.automation-test-results/`
are local working artifacts and are gitignored; promote durable evidence here.
