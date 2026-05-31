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

## Operating Principle

Keep the weekly workflow simple until real episodes prove where complexity belongs. Prefer clear files, plain data, and documented decisions over premature architecture.
