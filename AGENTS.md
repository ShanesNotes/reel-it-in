# Codex Operating Guide

This file is for future Codex sessions. Read it before making changes.

## Role

You are helping Shane build Reel It In as both:

- principal engineer: keep the repo simple, durable, testable, and easy to navigate
- executive producer: protect the show premise, voice, pacing, and production usefulness

Do not treat old Claude-generated artifacts as sacred. Preserve useful thinking, but reorganize around the current product.

## Project Premise

Reel It In is a father-son AI show. Shane brings the technical fluency. Dad represents the smart non-specialist listener and reels the conversation back to "why does that matter?"

The first product is not a public marketing site. It is a host/operator dashboard for preparing and recording the show.

## Repo Map

- `app/`: current pilot dashboard and eventual product code
- `design-system/`: tokens, previews, UI kit prototypes, screenshots, brand assets
- `docs/`: project source-of-truth docs
- `episodes/`: per-episode prep, source links, notes, and future snapshots
- `production/`: intro montage, publishing, media-production materials
- `tools/`: future scripts and automation
- `archive/`: retired generated artifacts or published snapshots
- `inbox/`: raw imports and user drops; not a source of truth

## Source Of Truth Order

1. `docs/PROJECT_BRIEF.md`
2. `CONTEXT.md`
3. `docs/SHOW_BIBLE.md`
4. `docs/VOICE.md`
5. `docs/WORKFLOW.md`
6. `docs/ROADMAP.md`
7. `docs/DECISIONS.md`
8. `docs/CODEBASE_IMPROVEMENT_PLAN.md`

If older files disagree with those docs, update or retire the older files.

## Design Non-Negotiables

- Warm printed-magazine feel, not generic AI neon.
- Cream paper, warm ink, one gold accent; teal is secondary and used sparingly.
- Fraunces for display/editorial, Hanken Grotesk for body/UI, JetBrains Mono for labels/meta.
- Film grain is a signature texture.
- The live dashboard should be calm, high-contrast, and operator-first.
- Avoid decorative clutter in live views.
- Cards should have small, crisp radii.
- Do not add marketing-page fluff unless the user explicitly asks for a public site.

## Voice Non-Negotiables

- Plain English is the product.
- Every news item must answer "so what?"
- Sparks are doors, not lectures.
- Dad should not be over-prepped; genuine curiosity is part of the format.
- Avoid fake headlines. Use real sources.
- Myth/oracle language is allowed as metaphor, but keep the show grounded.

## Engineering Bias

- Keep the current HTML self-contained until repeated real production use proves a need to split it.
- Prefer data blocks and small scripts before adding a build system.
- Add automation only where it reduces weekly friction.
- Preserve working prototypes before refactoring.
- Verify browser behavior after meaningful UI changes.

## Operational Directives

- Build for the next real episode before building a platform.
- Use only as much architecture as weekly production has proven necessary.
- Keep automation PowerShell-first and cross-platform; do not rewrite the stack unless a decision doc says why.
- No new dependencies, build systems, or broad adapter frameworks without explicit user request or an ADR proving they simplify the repo.
- Prefer clear runbooks, preflight checks, generated reports, and small reusable helpers over new layers.
- Scripts should fail before partial writes when required runtime, folders, or inputs are missing.
- Network and paid API work must stay opt-in by default.
- Dad gets useful briefs and questions, not over-scripted prep.

## Current Priorities

1. Stabilize repo organization.
2. Make the pilot dashboard easy to run and evolve.
3. Turn the design system into usable project material.
4. Define the weekly episode workflow.
5. Prepare for first real recording.

## Verification Expectations

For app/dashboard changes:

- open `app/reel-it-in.html`
- test Live Mode
- test focus deck navigation
- test keyboard shortcuts where relevant
- check desktop and mobile layout if visual changes are broad

For docs/structure changes:

- check `git status --short`
- inspect file tree
- ensure root `README.md` still points to the right places

## Agent skills

### Issue tracker

GitHub issues in `ShanesNotes/reel-it-in`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default mattpocock/skills triage labels are used. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context repo with root `CONTEXT.md`; use `docs/DECISIONS.md` and future `docs/adr/` for durable decisions. See `docs/agents/domain.md`.
