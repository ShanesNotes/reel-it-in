# Changelog

## Unreleased

- Verified PowerShell Episode Pipeline on Linux with portable `pwsh` 7.5.1.
- Completed Phase 2 dashboard stabilization: encoding cleanup, version metadata, asset audit, browser checklist, ADR for single-HTML template.
- Added cross-platform Production Vault path helper (`Get-ReelItInMediaRoot`) and regenerated `001-pilot/thumbnail-images.json` on Linux.
- Added optional research enrichment: `tools/fetch-page-summaries.py` and `tools/collect-x-insights.py` (Grok Build X discourse).
- Wired `xInsight` into dashboard news beats via `export-dashboard-data.ps1`.
- Documented deferred hosting/publishing choices in ADRs 0002 and 0003.
- Reorganized project into app, design-system, docs, episodes, production, tools, archive, and inbox lanes.
- Moved the current pilot dashboard to `app/reel-it-in.html`.
- Extracted the Claude-generated design system into project-owned folders.
- Added source-of-truth docs, `CONTEXT.md` glossary, and Codex operating instructions.
- Added episode automation (`tools/`), PowerShell Episode Pipeline, and shared `ReelItIn.Tools` module.
- Added solo-reaction lane via `tools/prepare-reaction-episode.py` and episode `002-...`.
- Added Python foundation tests under `tools/Tests/`.
- Added `docs/adr/0001-keep-powershell-core-for-episode-automation.md`.
- Added a local Golden Thread intro prototype for controllable browser-based animation tests.
- Added a Flow upload pack that converts the intro handoff into image references and copy-paste prompts.
- Merged foundation work to `main` via PR #1.
