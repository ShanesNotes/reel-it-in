# Weekly Automation Runbook

This is the practical Codex loop for producing Reel It In with as little repeated manual work as possible.

## 0. Start With State

The Codex app also has an active weekly production check-in scheduled for Monday mornings. Manual weekly work should still start with the same state checks.

Run:

```powershell
git status --short
.\tools\episode-status.ps1
```

Use the output to see the latest episode folder and whether the required artifacts exist.

## 1. Open A New Episode

Run:

```powershell
.\tools\new-episode.ps1 -Title "Working title"
```

Codex should then fill the new folder with the week-specific angle, research, Dad brief, production notes, and publishing package.

## 2. Research The Week

Ask Codex:

```text
Research this week's AI stories for Reel It In. Favor primary sources. Give me candidates with source date, plain-English headline, what happened, why it matters, Dad question, uncertainty, and recommendation: news, deep conversation, or discard.
```

Codex should update `sources.md`, not just answer in chat.

Then run:

```powershell
.\tools\collect-research-feeds.ps1 -Episode <episode-folder>
.\tools\draft-research-candidates.ps1 -Episode <episode-folder>
.\tools\generate-research-scout.ps1 -Episode <episode-folder>
.\tools\validate-sources.ps1 -Path .\episodes\<episode-folder>
```

Use `research-inbox.md` as the raw feed inbox. Use `research-drafts.md` for scored candidate rows to copy into `sources.md`. Use `research-scout.md` to see selected stories, backup stories, slate gaps, and the next research prompt.

## 3. Select The Slate

Shane chooses:

- 3 to 5 news stories
- 3 to 6 sparks
- one episode angle

Codex should update:

- `episode.md`
- `sources.md`
- `dad-brief.md`
- `dashboard-data.js`
- the dashboard `EPISODE` block when the slate is final

Generate the Dad-facing brief from the selected slate:

```powershell
.\tools\generate-dad-brief.ps1 -Episode <episode-folder>
```

Run:

```powershell
.\tools\export-dashboard-data.ps1 -Episode <episode-folder>
```

When ready to record:

```powershell
.\tools\export-dashboard-data.ps1 -Episode <episode-folder> -UpdateDashboard
```

For a full prep/pass report, run:

```powershell
.\tools\run-episode-pipeline.ps1 -Episode <episode-folder> -UpdateDashboard
```

## 4. Send Dad The Brief

Share only `dad-brief.md`, `handoff/dad-packet.md`, or an exported copy.

The brief should be short enough to read in a few minutes. Dad should know the frame, not the whole research stack.

## 5. Record

Prepare the recording workspace:

```powershell
.\tools\start-recording-session.ps1 -Episode <episode-folder>
```

Use `-NoOpen` to generate the launch report and media folders without opening windows.

Run:

- `app/reel-it-in.html`
- Riverside
- OBS only if using safety capture, screen capture, or a video layout
- `production-notes.md`
- `handoff/recording-packet.md`
- `handoff/session-launch.md`

During recording, capture rough timecodes in `production-notes.md`.

## 6. Wrap Immediately

Ask Codex:

```text
Turn these live notes into edit decisions, best moments, confusing spots, title options, thumbnail ideas, and clip candidates.
```

Codex should update `production-notes.md`, `edit-plan.md`, and `publishing.md`.

Run this once rough notes or transcript markers exist:

```powershell
.\tools\generate-edit-plan.ps1 -Episode <episode-folder>
.\tools\generate-title-thumbnail-package.ps1 -Episode <episode-folder>
.\tools\generate-publishing-package.ps1 -Episode <episode-folder> -Force
.\tools\export-production-packets.ps1 -Episode <episode-folder>
```

## 7. Edit

Use Descript for transcript-first editing. Export transcript or highlights back into the episode folder.

After transcript export, run:

```powershell
.\tools\generate-edit-plan.ps1 -Episode <episode-folder>
```

Use `edit-plan.md`, `handoff/edit-plan.md`, `handoff/editor/chapters.csv`, `handoff/editor/clip-candidates.csv`, and `handoff/editor/transcript-cleanup-checklist.md` as the editor-facing source of truth.

After the edit is locked, use Auphonic for final leveling and loudness if needed.

## 8. Package

Ask Codex:

```text
Generate the final publishing package from the episode notes and transcript: RSS title, summary, show notes, chapters, YouTube description, source links, social posts, and clip list.
```

Codex should update `publishing.md`.

The mechanical first pass is:

```powershell
.\tools\generate-edit-plan.ps1 -Episode <episode-folder>
.\tools\generate-title-thumbnail-package.ps1 -Episode <episode-folder>
.\tools\generate-publishing-package.ps1 -Episode <episode-folder> -Force
.\tools\export-production-packets.ps1 -Episode <episode-folder>
.\tools\export-marketing-assets.ps1 -Episode <episode-folder>
```

Use `title-thumbnail.md`, `handoff/marketing/title-options.md`, `handoff/marketing/thumbnail-brief.md`, `handoff/marketing/thumbnail-prompts.txt`, and `handoff/marketing/thumbnail-board.html` to choose the upload title and thumbnail direction.

If paid image generation is enabled for this workspace, generate actual thumbnail candidates:

```powershell
$env:OPENAI_API_KEY = "<your key>"
$env:REEL_IT_IN_GENERATE_IMAGES = "1"
.\tools\generate-thumbnail-images.ps1 -Episode <episode-folder>
```

The image script writes to `Reel It In Media/<episode-folder>/thumbnails/` and records the result in `thumbnail-images.json` plus `handoff/marketing/generated-thumbnails.md`.

## 9. Publish And Archive

After upload:

- add final platform links to `publishing.md`
- add transcript or transcript link
- add media folder links
- record lessons learned in `production-notes.md`
- update durable production decisions in `docs/DECISIONS.md` when needed
- generate `archive.json` and refresh `episodes/index.json`
- keep `handoff/marketing/` as the copy/paste source for YouTube, RSS, social, newsletter, clips, and distribution checks

Run:

```powershell
.\tools\export-archive-metadata.ps1 -Episode <episode-folder> -UpdateIndex
```

Then run:

```powershell
.\tools\run-episode-pipeline.ps1 -Episode <episode-folder>
```

The pipeline writes `automation-report.md` inside the episode folder. Use that report as the handoff summary for what passed, what failed, and what artifacts exist.

## Weekly Principle

Codex should make the table, fill the first draft, check the links, and package the release. Shane should make the taste calls. Dad should keep the conversation honest.
