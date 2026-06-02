# Codebase Improvement Plan

Updated: 2026-06-01.

## Goal

Keep Reel It In simple enough to operate tonight: one Episode Folder per episode, one normal Episode Pipeline for weekly production, and one thin YouTube reaction wrapper that operationalizes the existing YouTube University ingest pipeline without moving media into git.

## Implemented Foundation

- Source-of-truth language lives in `CONTEXT.md`.
- Operational directives live in `AGENTS.md`.
- The PowerShell Episode Pipeline remains the main weekly automation lane.
- `tools/Modules/ReelItIn.Tools.psm1` holds only repeated PowerShell helpers that remove duplication.
- `tools/prepare-reaction-episode.py` prepares Solo Reaction Episodes and can call `~/university/tools/ingest.sh` for transcript artifacts.

## Current Operating Shape

### Standard co-host episode

1. Create or update an Episode Folder.
2. Fill `episode.md`, `sources.md`, `dad-brief.md`, `production-notes.md`, and `publishing.md`.
3. Run `tools/run-episode-pipeline.ps1` when PowerShell Core is available.
4. Record, edit, publish, archive.

### Solo reaction episode

1. Run `python3 tools/prepare-reaction-episode.py --url <youtube-url> --ingest --force`.
2. Use `source-ingest.md` and the external transcript path for prep.
3. Stream or record while pausing for commentary.
4. Capture Shane's commentary notes in `production-notes.md`.
5. Run the normal packaging tools after recording if needed.

## Deferred Until Pain Is Proven

- Extra readiness gates that do not directly help recording or publishing.
- A frontend build system for the dashboard.
- A new YouTube ingestion framework inside this repo.
- Committing raw media, downloaded audio/video, or full external transcripts to git.
- Broad adapter layers or schemas before repeated episodes prove the need.

## Verification Bias

Run the smallest check that proves the claim: Python tests for Python tools, PowerShell pipeline once `pwsh` is installed, and direct review of generated Episode Folder files.
