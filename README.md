# Reel It In

Reel It In is a father-son show about AI for people who are curious but not living inside the AI news cycle.

The engine is simple: Shane follows the technology closely; Dad keeps the conversation honest by asking the normal-person question: "why does that matter?"

This repo contains the show product, design system, production workflow, and early intro montage materials.

## Start Here

| Need | Go to |
| --- | --- |
| What is this project? | `docs/PROJECT_BRIEF.md` |
| How does the show work? | `docs/SHOW_BIBLE.md` |
| How should it sound? | `docs/VOICE.md` |
| How do we prep and record? | `docs/WORKFLOW.md` |
| How do we automate production? | `docs/AUTOMATION_PLAN.md` |
| How do we operate it week to week? | `docs/OPERATIONAL_WORKFLOW.md` |
| Visual workflow map | `docs/operational-workflow.html` |
| What is the weekly Codex loop? | `docs/WEEKLY_AUTOMATION_RUNBOOK.md` |
| What are we building next? | `docs/ROADMAP.md` |
| What should Codex know first? | `AGENTS.md` |
| Current pilot dashboard | `app/reel-it-in.html` |
| Design system assets | `design-system/` |
| Intro montage handoff | `production/intro-montage/` |

## Current Status

- `main` contains the original pilot HTML and README history.
- This branch reorganizes the project into a production-ready repo shape.
- The current usable prototype is `app/reel-it-in.html`.
- The design system has been extracted into `design-system/`.
- The automation-first operating plan is `docs/AUTOMATION_PLAN.md`.
- A Codex app weekly production check-in is active for Monday mornings.
- The original Claude export zip is quarantined under `inbox/original-exports/` and ignored by git; it is not a working source of truth.

## Local Use

Open `app/reel-it-in.html` directly in a browser. It is intentionally self-contained for now.

During Live Mode, the dashboard supports:

- on-air clock
- focus deck
- keyboard navigation
- covered tracking
- wildcard prompts
- fullscreen operation

No build step is required yet.

To create a new episode workspace from the standard templates:

```powershell
.\tools\new-episode.ps1 -Title "Episode working title"
```

To inspect the latest episode workspace:

```powershell
.\tools\episode-status.ps1
```

To run the full episode automation loop and write `automation-report.md`:

```powershell
.\tools\run-episode-pipeline.ps1 -Episode 001-pilot
```

To validate source links for an episode:

```powershell
.\tools\validate-sources.ps1 -Path .\episodes\001-pilot
```

To generate the research scout from candidate sources:

```powershell
.\tools\collect-research-feeds.ps1 -Episode 001-pilot
.\tools\draft-research-candidates.ps1 -Episode 001-pilot
.\tools\generate-research-scout.ps1 -Episode 001-pilot
```

To generate Dad's brief from the selected episode stories:

```powershell
.\tools\generate-dad-brief.ps1 -Episode 001-pilot
```

To generate dashboard-ready data:

```powershell
.\tools\export-dashboard-data.ps1 -Episode 001-pilot
```

To generate the editor-facing plan from recording notes and transcript markers:

```powershell
.\tools\generate-edit-plan.ps1 -Episode 001-pilot
```

To generate a first-pass publishing package:

```powershell
.\tools\generate-publishing-package.ps1 -Episode 001-pilot -Force
```

To generate title options, thumbnail concepts, prompts, and a thumbnail board:

```powershell
.\tools\generate-title-thumbnail-package.ps1 -Episode 001-pilot
```

To generate actual thumbnail PNGs after explicitly enabling paid image generation:

```powershell
$env:OPENAI_API_KEY = "<your key>"
$env:REEL_IT_IN_GENERATE_IMAGES = "1"
.\tools\generate-thumbnail-images.ps1 -Episode 001-pilot
```

To generate shareable handoff packets for Dad, recording, editing, and publishing:

```powershell
.\tools\export-production-packets.ps1 -Episode 001-pilot
```

To split publishing copy into YouTube, RSS, social, newsletter, clip, checklist, and upload-field files:

```powershell
.\tools\export-marketing-assets.ps1 -Episode 001-pilot
```

To prepare recording day, create the external media folders, and open the working files:

```powershell
.\tools\start-recording-session.ps1 -Episode 001-pilot
```

To generate structured archive metadata:

```powershell
.\tools\export-archive-metadata.ps1 -Episode 001-pilot -UpdateIndex
```

## Operating Principle

Keep the weekly workflow simple until real episodes prove where complexity belongs. Prefer clear files, plain data, and documented decisions over premature architecture.
