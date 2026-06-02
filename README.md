# Reel It In

Reel It In is a father-son show about AI for people who are curious but not living inside the AI news cycle.

The engine is simple: Shane follows the technology closely; Dad keeps the conversation honest by asking the normal-person question: "why does that matter?"

This repo contains the show product, design system, production workflow, and early intro montage materials.

## Start Here

| Need | Go to |
| --- | --- |
| What is this project? | `docs/PROJECT_BRIEF.md` |
| What language should agents use? | `CONTEXT.md` |
| What improvements are queued? | `docs/CODEBASE_IMPROVEMENT_PLAN.md` |
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

### Core commands

Create and ingest tonight's solo YouTube reaction episode:

```bash
python3 tools/prepare-reaction-episode.py \
  --url "https://youtu.be/vc4WtPXgk88?si=SUGRAsjUNuZVvqeL" \
  --ingest \
  --force
```

This calls the existing YouTube University pipeline at `~/university/tools/ingest.sh`, writes transcript/media artifacts under `~/university/`, and links them from the Episode Folder. Do not commit raw video, audio, or full transcript artifacts into this repo.

Run the normal episode automation when PowerShell Core is available:

```bash
pwsh -NoProfile -File ./tools/run-episode-pipeline.ps1 -Episode 001-pilot -SkipSourceValidation -SkipResearchFeeds
```

Create a standard Dad/co-host episode from templates:

```powershell
.\tools\new-episode.ps1 -Title "Episode working title"
```

Prepare recording day without opening apps:

```bash
pwsh -NoProfile -File ./tools/start-recording-session.ps1 -Episode <episode-folder> -NoOpen
```

See `docs/WEEKLY_AUTOMATION_RUNBOOK.md` for the longer weekly loop and `tools/README.md` for the full tool list.

## Operating Principle

Keep the weekly workflow simple until real episodes prove where complexity belongs. Prefer clear files, plain data, and documented decisions over premature architecture.

Foundation work should prioritize the next real recording: clear directives, fail-fast automation, small reusable script helpers, and a working YouTube reaction lane that reuses the existing `~/university` ingest pipeline. Defer build systems, rewrites, broad adapter frameworks, and new dependencies until production pain proves they are simpler than the current setup.
