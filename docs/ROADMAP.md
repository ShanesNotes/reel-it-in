# Roadmap

## Phase 1: Repo Foundation

- [x] Connect local repo to GitHub.
- [x] Move pilot dashboard into `app/`.
- [x] Extract design-system assets.
- [x] Create source-of-truth docs.
- [x] Add Codex operating guide.
- [x] Review and commit foundation branch.
- [x] Merge foundation work to `main` (PR #1).

## Phase 2: Pilot Dashboard Stabilization

- [x] Verify `app/reel-it-in.html` after the move.
- [x] Fix any broken asset references (Google Fonts CDN only; audited 2026-06-11).
- [x] Add a small browser test checklist (`app/README.md`).
- [x] Decide whether the current single HTML remains the production template for episode 001 (`docs/adr/0003-single-html-dashboard-for-episode-001.md`).
- [x] Add version/date metadata inside the HTML.

## Phase 3: First Recording Prep

- [x] Choose host display names.
- [x] Build episode 001 prep folder.
- [x] Select real current AI stories.
- [x] Replace placeholder/aggregator links with primary sources.
- [x] Write 3-6 first-episode sparks.

## Phase 4: Automation-First Production System

- [x] Define workspace and sharing model.
- [x] Add automation-first operating plan.
- [x] Add episode folder templates.
- [x] Add starter new-episode script.
- [x] Add episode status script.
- [x] Add source validation script.
- [x] Add primary-source research feed collection.
- [x] Add scored research draft generation from feed inbox.
- [x] Add research scout and candidate JSON generation.
- [x] Add weekly automation runbook.
- [x] Add Dad brief generation from episode prep.
- [x] Set up weekly Codex app production check-in.
- [x] Add dashboard data export from episode prep.
- [x] Add transcript/production-notes edit plan generation.
- [x] Add title and thumbnail option generation.
- [x] Add publishing package generation from episode artifacts.
- [x] Add Dad, recording, editor, and publishing handoff packet generation.
- [x] Add marketing and distribution asset export from publishing metadata.
- [x] Add recording-session launcher and media folder setup.
- [x] Add archive metadata export and episode index.
- [x] Add one-command episode pipeline and report.
- [x] Define default recording setup: Riverside primary, OBS safety capture.
- [x] Define audio capture plan with separate tracks.
- [x] Create post-recording notes template.
- [x] Create publishing metadata template.
- [x] Create thumbnail/title workflow (automation in `tools/`; human still picks final title and image).
- [x] Operationalize YouTube University ingest for solo reaction episodes.

## Phase 5: Design System Productization

- [ ] Normalize UI kit file names and references.
- [ ] Decide whether React prototypes stay as references or become app code.
- [x] Add design-system preview index.
- [ ] Keep accessibility notes current.
- [ ] Create public graphics lane only when needed.

## Phase 6: Automation

- [x] Script new episode folder creation.
- [x] Script source/link validation.
- [x] Collect primary-source research inbox items.
- [x] Draft candidate story rows from the research inbox.
- [x] Generate research scout snapshots from source tables.
- [x] Generate Dad-facing briefs from selected stories.
- [x] Generate dashboard episode data from `episode.md`.
- [x] Generate edit plans, chapter CSVs, clip CSVs, and transcript QA checklists.
- [x] Generate title options, thumbnail briefs, prompts, and thumbnail boards.
- [x] Generate publishing package from episode metadata.
- [x] Generate production handoff packets.
- [x] Generate platform-specific marketing and distribution files.
- [x] Generate archive metadata and episode index.
- [x] Run the episode production pipeline from one command.
- [x] Improve research drafts with browsing-backed page summaries (`tools/fetch-page-summaries.py`; still human-reviewed).
- [ ] Generate deeper show notes from full transcript exports.
- [ ] Connect archive metadata to a public/private archive view.

## Phase 7: Hosting And Publishing

- [ ] Choose RSS host: RSS.com, Simplecast, Buzzsprout, Spotify for Creators, or other (deferred — see `docs/adr/0002-defer-public-hosting-until-first-recording.md`).
- [ ] Choose hosting target for the dashboard/prototype (deferred until after first recording).
- [ ] Publish a simple web version for Dad and collaborators (deferred; Dad still gets briefs + link).
- [x] Decide public site vs private production dashboard boundaries (operator dashboard stays local/private for now).
- [ ] Add RSS/YouTube publishing workflow.
