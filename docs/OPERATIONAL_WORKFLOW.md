# Operational Workflow

Last verified: 2026-06-01.

This is the plain-English way to run Reel It In each week.

The whole system is built around one rule:

```text
One episode = one folder.
```

Codex can generate, check, and package most of the work. Shane still makes the editorial calls. Dad gets a short brief and a recording link.

## Where Everything Lives

Active workspace:

```text
C:\Users\Shane\Documents\reel-it-in
```

Shared GitHub source of truth:

```text
https://github.com/ShanesNotes/reel-it-in.git
```

Raw and exported media live outside git:

```text
C:\Users\Shane\Documents\Reel It In Media\<episode-folder>\
```

Per-episode working folders live in:

```text
episodes\<episode-folder>\
```

Dad-facing files:

```text
episodes\<episode-folder>\dad-brief.md
episodes\<episode-folder>\handoff\dad-packet.md
```

## The Weekly Loop

### 0. Check The Workspace

Start here before touching anything:

```powershell
git status --short
.\tools\episode-status.ps1
```

Use this to see what changed, what exists, and whether the latest episode folder is healthy.

### 1. Open The Episode

Create the next episode folder:

```powershell
.\tools\new-episode.ps1 -Title "Working title"
```

This creates the episode source files. Codex fills them in as the week develops.

### 2. Research

Ask Codex to research the week, favoring primary sources. Then run:

```powershell
.\tools\collect-research-feeds.ps1 -Episode <episode-folder>
.\tools\draft-research-candidates.ps1 -Episode <episode-folder>
.\tools\generate-research-scout.ps1 -Episode <episode-folder>
.\tools\validate-sources.ps1 -Path .\episodes\<episode-folder>
```

Use `research-drafts.md` for candidates, then copy the chosen stories into `sources.md` and `episode.md`.

### 3. Select The Slate

Shane chooses:

- 3 to 5 stories
- 3 to 6 sparks
- one episode angle

Then generate the host prep:

```powershell
.\tools\generate-dad-brief.ps1 -Episode <episode-folder>
.\tools\export-dashboard-data.ps1 -Episode <episode-folder> -UpdateDashboard
```

Share only the Dad brief or Dad packet with Dad.

### 4. Record

Launch the recording setup:

```powershell
.\tools\start-recording-session.ps1 -Episode <episode-folder>
```

Use:

- Riverside as the primary recording service
- OBS as optional safety capture
- `app/reel-it-in.html` as Shane's live dashboard
- `production-notes.md` for timestamps, clips, cuts, and fixes

### 5. Wrap And Edit

After recording, add rough notes and transcript markers. Then run:

```powershell
.\tools\generate-edit-plan.ps1 -Episode <episode-folder>
.\tools\generate-title-thumbnail-package.ps1 -Episode <episode-folder>
.\tools\generate-publishing-package.ps1 -Episode <episode-folder> -Force
.\tools\export-production-packets.ps1 -Episode <episode-folder>
```

Use Descript for transcript-first editing. Use Auphonic for final leveling and loudness when needed.

Editor-facing files:

```text
edit-plan.md
handoff\edit-plan.md
handoff\editor\chapters.csv
handoff\editor\clip-candidates.csv
handoff\editor\transcript-cleanup-checklist.md
```

Creative files:

```text
title-thumbnail.md
thumbnail-images.json
handoff\marketing\title-options.md
handoff\marketing\thumbnail-brief.md
handoff\marketing\thumbnail-prompts.txt
handoff\marketing\thumbnail-board.html
handoff\marketing\generated-thumbnails.md
```

To generate actual thumbnail images through the OpenAI image API, explicitly enable paid generation:

```powershell
$env:OPENAI_API_KEY = "<your key>"
$env:REEL_IT_IN_GENERATE_IMAGES = "1"
.\tools\generate-thumbnail-images.ps1 -Episode <episode-folder>
```

If the key or opt-in flag is missing, the script writes a skipped manifest and the prompts to review manually.

### 6. Package And Publish

Generate platform-specific copy:

```powershell
.\tools\export-marketing-assets.ps1 -Episode <episode-folder>
```

Upload from:

```text
handoff\marketing\
```

That folder contains YouTube copy, RSS copy, social copy, newsletter copy, clip CSVs, distribution checklist, upload fields, title options, and thumbnail briefs.

### 7. Archive

After publishing, add final links, runtime, transcript link, and export locations. Then run:

```powershell
.\tools\export-archive-metadata.ps1 -Episode <episode-folder> -UpdateIndex
.\tools\run-episode-pipeline.ps1 -Episode <episode-folder>
```

The final pipeline report is:

```text
episodes\<episode-folder>\automation-report.md
```


## Solo Reaction Episodes

Solo reactions use the same one-folder rule, but they start from one Source Video instead of a weekly Story Slate.

Run:

```bash
python3 tools/prepare-reaction-episode.py --url <youtube-url> --ingest --force
```

This operationalizes the existing YouTube University pipeline. It writes the Episode Folder files in this repo, but the downloaded audio and WhisperX transcript stay under `~/university/`. Use `source-ingest.md` to find the external manifest and transcript.

Before going live, decide only:

- stream title
- whether to play the whole video or selected chapters
- where Shane will capture live commentary notes

Do not build a new ingestion stack inside Reel It In unless repeated episodes prove the old one is insufficient.

## The One-Command Health Check

When in doubt, run:

```powershell
.\tools\run-episode-pipeline.ps1 -Episode <episode-folder> -UpdateDashboard
```

This checks sources, research, Dad brief, dashboard data, edit plan, title/thumbnail package, publishing package, handoff packets, marketing files, archive metadata, and git status.

## What Codex Owns

- Creating episode folders
- Collecting and drafting research candidates
- Validating source links
- Generating Dad briefs
- Generating dashboard data
- Generating edit plans
- Generating title and thumbnail options
- Generating publishing and marketing files
- Generating archive metadata
- Running readiness reports

## What Shane Owns

- Which stories matter
- The episode angle
- Final wording and taste
- Whether a title feels right
- Which thumbnail gets used
- What actually gets published

## What Dad Gets

Dad gets:

- the recording time
- the recording link
- a short Dad brief
- a few plain-English story bullets
- one or two useful questions

Dad does not need:

- GitHub
- Codex
- the full research dump
- the raw media folder

## Services

- Riverside: primary recording room
- OBS: optional local safety capture
- Descript: transcript-first edit and clips
- Auphonic: leveling, loudness, and final polish
- RSS.com or Simplecast: preferred RSS host to evaluate
- Spotify for Creators: zero-cost fallback
- YouTube: native video upload when video exists, RSS ingestion only for audio-first static-image episodes

## Visual Map

Open the visual workflow file in a browser:

```text
docs\operational-workflow.html
```
