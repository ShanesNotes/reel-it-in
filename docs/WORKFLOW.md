# Workflow

## What The Dashboard Is For

The dashboard is a host/operator surface used before and during recording. It is not primarily a public website.

The working assumption:

- Shane operates the dashboard.
- Dad joins by call or sits across the table.
- Dad does not need to see the dashboard.
- Shane uses the dashboard to steer, pace, and capture the thread.

## Weekly Episode Flow

The automation-first version of this workflow lives in `docs/AUTOMATION_PLAN.md`. This file stays as the editorial workflow; the automation plan explains what Codex can generate and maintain around it.

### 1. Gather

Collect candidate AI stories. Favor primary sources when possible.

For each candidate, note:

- source URL
- plain-English summary
- why it matters
- Dad question
- whether it belongs in news or deep conversation

Use `sources.md` as the editable research table. Generate `research-scout.md` from it when you want a quick slate snapshot:

```powershell
.\tools\collect-research-feeds.ps1 -Episode <episode-folder>
.\tools\draft-research-candidates.ps1 -Episode <episode-folder>
.\tools\generate-research-scout.ps1 -Episode <episode-folder>
```

`collect-research-feeds.ps1` creates `research-inbox.md` from the official feed watchlist in `docs/RESEARCH_WATCHLIST.json`. `draft-research-candidates.ps1` turns the inbox into scored candidate rows with first-pass "why it matters" and Dad questions. Promising rows should still be copied into `sources.md` and given Shane's actual editorial take before selection.

### 2. Select

Pick three to five news items and three to six conversation sparks.

The selection should balance:

- immediate usefulness
- long-term meaning
- policy/social impact
- tools people may actually use
- one bigger philosophical thread

### 3. Prepare

Update the episode data block in the dashboard or future episode data file.

Do not script Dad. Prepare enough for Shane to guide the conversation and enough source material to avoid hand-waving.

### 4. Record

Use Live Mode.

Useful controls:

- live clock for pacing
- focus deck for one spark at a time
- covered tracking
- wildcard prompt if the conversation stalls
- fullscreen for a clean second-monitor surface

### 5. Wrap

Immediately after recording, capture:

- best moments
- confusing spots
- sources to cite
- possible title
- thumbnail ideas
- clips to cut
- anything to avoid next time

Then generate the mechanical edit handoff:

```powershell
.\tools\generate-edit-plan.ps1 -Episode <episode-folder>
.\tools\generate-title-thumbnail-package.ps1 -Episode <episode-folder>
```

### 6. Publish

Package the episode for YouTube and RSS after the edit plan, transcript, and final runtime are ready.

### 7. Archive

Create an episode folder under `episodes/` with sources, production notes, and final metadata.

## Codex Automation

Automation should assist, not replace editorial judgment.

Codex should help with:

- source collection
- primary-source checks
- plain-English rewrites
- Dad-facing brief generation
- duplicate episode template
- create episode folder
- validate source URLs
- inspect episode readiness
- generate show-note draft
- generate publishing metadata
- generate edit plans, chapter CSVs, clip CSVs, and transcript cleanup checklists
- generate title and thumbnail options
- summarize transcripts for clips and chapters
- generate first-pass RSS, YouTube, social, and newsletter copy
- output archive metadata

Human-owned:

- which stories matter
- why-it-matters copy
- final title
- episode angle
- what actually gets published
