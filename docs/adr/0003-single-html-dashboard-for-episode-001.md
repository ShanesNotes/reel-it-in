# ADR 0003: Keep Single HTML Dashboard For Episode 001

Date: 2026-06-11

## Status

Accepted

## Context

Phase 2 asked whether `app/reel-it-in.html` should remain the production template for episode 001 or split into per-episode HTML files immediately.

The dashboard is already wired to episode automation via `tools/export-dashboard-data.ps1` and `episodes/<episode>/dashboard-data.js`.

## Decision

Keep one self-contained HTML file as the production dashboard for episode 001.

Weekly workflow:

1. Edit episode prep in the Episode Folder.
2. Run `export-dashboard-data.ps1 -UpdateDashboard` when dashboard data changes.
3. Open `app/reel-it-in.html` directly for prep and Live Mode.

Per-episode HTML duplicates stay optional for archive snapshots, not the default operator path.

## Consequences

- No frontend build system is required for the first recording.
- Browser verification stays a manual checklist in `app/README.md`.
- If repeated episodes prove duplication painful, revisit with a generator, not a framework rewrite.