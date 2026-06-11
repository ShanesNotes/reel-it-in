# Changelog

## Unreleased

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
