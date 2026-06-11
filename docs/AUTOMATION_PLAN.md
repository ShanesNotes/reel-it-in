# Automation Plan

Last verified: 2026-06-11.

## Goal

Make Reel It In feel like a weekly production system that Codex can help run end to end:

- find real stories
- turn them into plain-English prep
- generate the recording dashboard material
- package artifacts for Dad, editing, publishing, and archive
- keep the repo organized without making the show feel over-produced

Automation should remove friction. Shane still owns the editorial call. Dad should get just enough context to be curious on mic.

## Workspace Model

The active Codex workspace lives here:

```text
C:\Users\Shane\Documents\reel-it-in
```

The shared source-of-truth repo is:

```text
https://github.com/ShanesNotes/reel-it-in.git
```

Use git for text, code, planning, metadata, source links, templates, and automation scripts.

Do not use git for raw media. Create a separate cloud folder named `Reel It In Media` in Google Drive or OneDrive:

```text
Reel It In Media/
  001-pilot/
    raw/
    exports/
    clips/
    thumbnails/
    transcripts/
```

The repo should point to media locations by folder name or link, but the media files themselves should stay outside git unless they are tiny reusable assets.

## Update Model

Codex updates the local workspace first:

```text
C:\Users\Shane\Documents\reel-it-in
```

After a meaningful change, run:

```powershell
git status --short
```

Then review, commit, and push to GitHub when the change is ready to share across machines or preserve as project history.

GitHub is the shared production brain. It should contain:

- docs
- episode folders
- source links
- dashboard code
- automation scripts
- publishing metadata
- decisions

The cloud media folder is the shared production vault. It should contain:

- raw Riverside downloads
- OBS safety captures
- Descript exports
- Auphonic masters
- final video exports
- clip exports
- thumbnail exports

Dad-facing material is updated by exporting or sharing `dad-brief.md`. Dad does not need to pull from GitHub or browse the media vault.

## Dad Sharing Model

Dad does not need to use GitHub, Codex, or the repo.

For each episode, Codex should generate a `dad-brief.md` file under the episode folder. Share that as a Google Doc, PDF, email, or printed page. It should contain:

- the episode theme
- recording time and link
- 3 to 5 plain-English story bullets
- why each story matters
- one good question he might ask
- anything to avoid

Dad should receive a recording link from Riverside, plus the brief if useful. He should not receive a research dump.

If Dad eventually wants a live view, publish or send a read-only dashboard/brief. Do not require him to operate the dashboard unless the format changes.

## Weekly Automation Loop

### 1. Open The Week

Codex creates the next episode folder:

```powershell
.\tools\new-episode.ps1 -Title "Episode working title"
```

Generated files:

- `episode.md`
- `sources.md`
- `dad-brief.md`
- `production-notes.md`
- `publishing.md`

### 2. Research

Codex browses for current AI stories and prioritizes primary sources when available.

Each candidate story should include:

- source URL
- source date
- plain-English headline
- what happened
- why it matters
- Dad question
- risk or uncertainty
- whether it is news, deep conversation, or discard

### 3. Select

Shane chooses the story slate:

- 3 to 5 news items
- 3 to 6 sparks
- one bigger episode angle

Codex can rank, cluster, and argue for a slate, but the final choice stays human.

### 4. Prepare

Codex updates:

- `episode.md` with the actual show angle and rundown
- `sources.md` with real links and notes
- `research-inbox.md` and `research-inbox.json` with fresh feed-watchlist items
- `research-drafts.md` and `research-drafts.json` with scored first-pass candidate rows
- `research-scout.md` and `research-candidates.json` with the candidate triage snapshot
- `dad-brief.md` with the lightweight Dad-facing version
- `app/reel-it-in.html` or future episode data with the selected slate
- `handoff/` packets for Dad, recording, editing, and publishing
- `automation-report.md` with the latest automated readiness pass

### 5. Record

Run the recording stack:

- `app/reel-it-in.html` for Shane's operator dashboard
- Riverside as the primary recording room
- OBS as local safety capture when video or dashboard capture matters
- a notes file for live edit markers
- `tools/start-recording-session.ps1` to open the room, create media folders, and write `handoff/session-launch.md`

### 6. Wrap

Immediately after recording, Codex turns rough notes into:

- best moments
- confusing spots
- edit decision list
- an automated `edit-plan.md`
- editor chapter and clip CSVs
- transcript cleanup checklist
- clip candidates
- title options
- thumbnail concepts
- a generated `title-thumbnail.md`
- a thumbnail board for quick visual review
- source citations to include

### 7. Edit

Use Descript for transcript-first editing and clip extraction. Use Auphonic for final loudness, leveling, and intro/outro automation once the intro package is ready.

Codex can process transcript exports and produce:

- an updated `edit-plan.md`
- `handoff/edit-plan.md` for editor sharing
- `handoff/editor/chapters.csv`
- `handoff/editor/clip-candidates.csv`
- `handoff/editor/transcript-cleanup-checklist.md`
- chapters
- show notes
- short descriptions
- clip titles
- quote candidates
- "what changed from prep" notes
- an updated `handoff/editor-packet.md`

### 8. Publish

Codex generates the package in `publishing.md`:

- final title
- episode description
- short summary
- chapters
- source links
- YouTube description
- RSS metadata
- social posts
- newsletter copy
- clip list

Codex also generates `title-thumbnail.md` and `handoff/marketing/thumbnail-board.html` so title and thumbnail decisions are part of the release workflow instead of a last-minute scramble.
When explicitly enabled with `OPENAI_API_KEY` and `REEL_IT_IN_GENERATE_IMAGES=1`, Codex can also run `tools/generate-thumbnail-images.ps1` to create thumbnail PNGs from the generated image prompts. This step is intentionally opt-in because it can spend API credits.
Codex also generates `handoff/publishing-packet.md` as the copy/paste handoff for upload surfaces.
Codex also generates `handoff/marketing/` files for platform-specific copy, clip tables, distribution checklists, and future API/browser form filling.

Upload and account-authenticated publishing may still be manual or browser-assisted.

### 9. Archive

After publishing, Codex updates:

- final episode metadata
- source list
- transcript link
- media export links
- lessons learned
- `docs/DECISIONS.md` if a production decision changed

## Recommended Service Stack

### Recording

Default: Riverside.

Reasons:

- supports remote, in-person, and hybrid sessions
- creates individual participant tracks
- records high-quality tracks locally before upload
- can export separate files for editing elsewhere

Safety: OBS.

Reasons:

- free and open source
- records video/audio locally
- useful for a backup mix, dashboard capture, or screen material

### Editing

Default: Descript.

Reasons:

- edit audio/video through the transcript
- supports separate participant recordings
- can speed up filler removal, rough edits, captions, and clips

Final polish: Auphonic.

Reasons:

- repeatable loudness and leveling presets
- intro/outro support
- output metadata and publishing integrations

### Hosting And Distribution

Automation-first default to evaluate: RSS.com or Simplecast.

Why: the show needs one reliable RSS feed, directory submission, analytics, transcripts or metadata support, and room to grow.

Zero-cost fallback: Spotify for Creators.

Tradeoff: Spotify offers hosting and RSS, but its own help docs say you still need to submit the feed to other listening platforms. That is less automated than a host with broader distribution workflow.

YouTube:

- for audio-first episodes, YouTube can ingest an RSS feed and create static-image videos
- for a video show, upload the finished video natively to YouTube and treat RSS ingestion as secondary

## Recording Runbook

Before recording:

1. Create or update the episode folder.
2. Run `tools/start-recording-session.ps1 -Episode <episode-folder>`.
3. Open the Riverside studio if the launcher did not have a recording link yet.
4. Confirm each host has headphones.
5. Confirm separate tracks or separate mic channels.
6. Start OBS only if using a backup mix, screen capture, or video layout.
7. Record a short sync marker.

During recording:

1. Shane operates Live Mode.
2. Keep the dashboard calm and glanceable.
3. Mark covered items.
4. Add rough edit notes as they happen.
5. Avoid stopping the main recording unless there is a real break.

After recording:

1. Confirm Riverside uploads are complete.
2. Download or link raw tracks into `Reel It In Media/<episode>/raw/`.
3. Save rough notes in `production-notes.md`.
4. Export or import into Descript.
5. Generate the publishing package after the edit is locked.

## Artifact Contract

Each episode folder should eventually contain:

- `episode.md`: editorial source of truth
- `sources.md`: source URLs and research notes
- `research-inbox.md`: generated fresh feed inbox from the official watchlist
- `research-inbox.json`: structured feed inbox for future automation
- `research-drafts.md`: generated candidate story rows from the inbox
- `research-drafts.json`: structured draft candidate rows and scores
- `research-scout.md`: generated candidate triage snapshot and next research prompt
- `research-candidates.json`: structured candidate data for future automation
- `dad-brief.md`: lightweight pre-show brief
- `production-notes.md`: recording and edit notes
- `publishing.md`: final metadata and launch copy
- `title-thumbnail.md`: generated title options, thumbnail concepts, and image prompts
- `title-thumbnail.json`: structured title and thumbnail options
- `thumbnail-images.json`: generated or skipped image-generation manifest
- `transcript.md`: optional transcript or link
- `edit-plan.md`: generated assembly plan from live notes and transcript markers
- `edit-plan.json`: structured edit metadata for future automation
- `handoff/dad-packet.md`: shareable prep for Dad
- `handoff/session-launch.md`: recording-day launch report and folder map
- `handoff/edit-plan.md`: shareable editor copy of the edit plan
- `handoff/editor/chapters.csv`: chapter rows for the editor and publishing package
- `handoff/editor/clip-candidates.csv`: clip rows for Shorts/Reels/TikTok review
- `handoff/editor/transcript-cleanup-checklist.md`: transcript QA checklist
- `handoff/marketing/title-options.md`: title candidates for YouTube/RSS/social
- `handoff/marketing/thumbnail-brief.md`: thumbnail direction and concept table
- `handoff/marketing/thumbnail-prompts.txt`: image-generation prompts
- `handoff/marketing/thumbnail-board.html`: visual thumbnail concept board
- `handoff/marketing/generated-thumbnails.md`: generated thumbnail paths or skipped-generation instructions
- `handoff/recording-packet.md`: services, dashboard, and recording checklist
- `handoff/editor-packet.md`: edit notes and inputs
- `handoff/publishing-packet.md`: copy/paste publishing and marketing package
- `handoff/marketing/youtube-upload.md`: YouTube upload fields
- `handoff/marketing/rss-upload.md`: RSS host upload fields
- `handoff/marketing/social-posts.md`: social and newsletter copy
- `handoff/marketing/clip-candidates.csv`: clip export queue
- `handoff/marketing/upload-fields.json`: structured fields for future browser/API automation

## Automation Backlog

Now:

- create new episode folders from templates
- standardize episode artifacts
- define service stack and sharing model
- generate Dad-facing briefs
- inspect episode readiness
- validate source URLs
- collect fresh primary-source feed items from `docs/RESEARCH_WATCHLIST.json`
- draft scored candidate rows from the feed inbox
- generate a research scout and candidate JSON from `sources.md`
- generate Dad-facing briefs from selected episode stories
- generate dashboard episode data from `episode.md`
- generate publishing packages from episode notes and transcripts
- generate edit plans, chapter CSVs, clip CSVs, and transcript cleanup checklists from production notes and transcript markers
- generate title options, thumbnail concepts, image prompts, and thumbnail boards
- optionally generate thumbnail images from prompts when paid image generation is explicitly enabled
- generate production handoff packets for Dad, recording, editing, and publishing
- generate platform-specific marketing and distribution assets
- generate structured archive metadata and an episode index
- run the full episode pipeline and write an automation report
- keep episode 001 populated with real, dated source links

Next:

- improve candidate drafting with browsing page summaries and source-specific heuristics
- produce deeper show-note drafts from full transcript exports
- improve clip scoring from full transcript highlights
- connect archive metadata to a public/private archive view

Later:

- connect publishing APIs where practical
- generate website/archive pages
- generate final social image variants from selected thumbnail direction
- add analytics snapshots after each release
- automate recurring weekly Codex check-ins

## Local Automation Commands

Create an episode workspace:

```powershell
.\tools\new-episode.ps1 -Title "Working title"
```

Inspect the latest episode:

```powershell
.\tools\episode-status.ps1
```

Validate links for one episode:

```powershell
.\tools\validate-sources.ps1 -Path .\episodes\001-pilot
```

Collect fresh items from the research watchlist:

```powershell
.\tools\collect-research-feeds.ps1 -Episode 001-pilot
```

Draft candidate story rows from the inbox:

```powershell
.\tools\draft-research-candidates.ps1 -Episode 001-pilot
```

Generate the research scout from candidate sources:

```powershell
.\tools\generate-research-scout.ps1 -Episode 001-pilot
```

Generate Dad's brief from the selected episode stories:

```powershell
.\tools\generate-dad-brief.ps1 -Episode 001-pilot
```

Generate dashboard data from episode prep:

```powershell
.\tools\export-dashboard-data.ps1 -Episode 001-pilot
```

When the slate is final, update the live dashboard EPISODE block:

```powershell
.\tools\export-dashboard-data.ps1 -Episode 001-pilot -UpdateDashboard
```

Generate a first-pass publishing package after recording notes or transcript markers exist:

```powershell
.\tools\generate-edit-plan.ps1 -Episode 001-pilot
.\tools\generate-publishing-package.ps1 -Episode 001-pilot -Force
```

Generate title and thumbnail options:

```powershell
.\tools\generate-title-thumbnail-package.ps1 -Episode 001-pilot
```

Generate production handoff packets:

```powershell
.\tools\export-production-packets.ps1 -Episode 001-pilot
```

Generate platform-specific marketing and distribution files:

```powershell
.\tools\export-marketing-assets.ps1 -Episode 001-pilot
```

Prepare the recording session and local media folders:

```powershell
.\tools\start-recording-session.ps1 -Episode 001-pilot
```

Generate structured archive metadata and update the episode shelf:

```powershell
.\tools\export-archive-metadata.ps1 -Episode 001-pilot -UpdateIndex
```

Run the full episode pipeline and write the episode automation report:

```powershell
.\tools\run-episode-pipeline.ps1 -Episode 001-pilot
```

## Codex App Automation

An active weekly Codex app automation exists:

- Name: Reel It In weekly production check-in
- ID: `reel-it-in-weekly-production-check-in`
- Schedule: Mondays at 9:00 AM local time
- Workspace: `C:\Users\Shane\Documents\reel-it-in`

The automation should run the local episode pipeline when possible, read the resulting `automation-report.md`, and report what is ready, what is missing for the next recording, source-link warnings or failures, and the next three highest-leverage actions.

## Service Sources Checked

- Riverside high quality tracks: https://support.riverside.com/hc/en-us/articles/5260109014045-About-high-quality-tracks
- Riverside in-person and hybrid sessions: https://support.riverside.com/hc/en-us/articles/30009945147165-Record-in-person-and-hybrid-sessions
- Riverside record/edit overview: https://support.riverside.com/hc/en-us/articles/5678502519453-Record-and-edit-on-Riverside-Overview
- Descript podcast workflow: https://help.descript.com/hc/en-us/articles/10601764003341-Record-edit-and-export-your-audio-podcast
- Auphonic production docs: https://us.auphonic.com/help/web/production.html
- OBS: https://obsproject.com/
- Apple Podcasts submission: https://podcasters.apple.com/support/897-submit-a-show
- YouTube RSS podcast ingestion: https://support.google.com/youtube/answer/13525207
- Spotify for Creators RSS: https://support.spotify.com/us/creators/article/finding-and-enabling-your-rss-feed/
- RSS.com distribution: https://help.rss.com/en/support/solutions/articles/44002320093-what-s-the-difference-between-automatic-and-guided-distribution-
- Simplecast: https://www.simplecast.com/
- Buzzsprout features: https://www.buzzsprout.com/features
