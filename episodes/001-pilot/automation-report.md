# Automation Report

- Episode: 001-pilot
- Generated: 2026-06-01 13:26:44
- Result: Ready

## Pipeline

| Step | Status | Exit | Duration | Command |
| --- | --- | ---: | ---: | --- |
| Preflight episode status | PASS | 0 | 0.9s | `.\tools\episode-status.ps1 -Episode 001-pilot` |
| Source validation | PASS | 0 | 15.8s | `.\tools\validate-sources.ps1 -Path C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot -TimeoutSec 20` |
| Collect research feeds | PASS | 0 | 15.3s | `.\tools\collect-research-feeds.ps1 -Episode 001-pilot` |
| Draft research candidates | PASS | 0 | 1.1s | `.\tools\draft-research-candidates.ps1 -Episode 001-pilot` |
| Research scout | PASS | 0 | 1.1s | `.\tools\generate-research-scout.ps1 -Episode 001-pilot` |
| Dad brief | PASS | 0 | 0.9s | `.\tools\generate-dad-brief.ps1 -Episode 001-pilot` |
| Dashboard data export | PASS | 0 | 0.9s | `.\tools\export-dashboard-data.ps1 -Episode 001-pilot -UpdateDashboard` |
| Edit plan | PASS | 0 | 1.1s | `.\tools\generate-edit-plan.ps1 -Episode 001-pilot` |
| Publishing package | PASS | 0 | 0.9s | `.\tools\generate-publishing-package.ps1 -Episode 001-pilot` |
| Title and thumbnail package | PASS | 0 | 1.1s | `.\tools\generate-title-thumbnail-package.ps1 -Episode 001-pilot` |
| Production packets | PASS | 0 | 0.8s | `.\tools\export-production-packets.ps1 -Episode 001-pilot` |
| Marketing assets | PASS | 0 | 1s | `.\tools\export-marketing-assets.ps1 -Episode 001-pilot` |
| Archive metadata | PASS | 0 | 1.1s | `.\tools\export-archive-metadata.ps1 -Episode 001-pilot -UpdateIndex` |
| Postflight episode status | PASS | 0 | 0.8s | `.\tools\episode-status.ps1 -Episode 001-pilot` |
| Workspace git status | PASS | 0 | 0.2s | `git status --short` |

## Artifacts

- `episode.md`: present
- `sources.md`: present
- `research-inbox.md`: present
- `research-inbox.json`: present
- `research-drafts.md`: present
- `research-drafts.json`: present
- `research-scout.md`: present
- `research-candidates.json`: present
- `dad-brief.md`: present
- `production-notes.md`: present
- `dashboard-data.js`: present
- `publishing.md`: present
- `title-thumbnail.md`: present
- `title-thumbnail.json`: present
- `thumbnail-images.json`: present
- `archive.json`: present
- `transcript.md`: present
- `edit-plan.md`: present
- `edit-plan.json`: present
- `handoff\session-launch.md`: present
- `handoff\edit-plan.md`: present
- `handoff\editor\chapters.csv`: present
- `handoff\editor\clip-candidates.csv`: present
- `handoff\editor\transcript-cleanup-checklist.md`: present
- `handoff\marketing\title-options.md`: present
- `handoff\marketing\thumbnail-brief.md`: present
- `handoff\marketing\thumbnail-prompts.txt`: present
- `handoff\marketing\thumbnail-board.html`: present
- `handoff\marketing\generated-thumbnails.md`: present
- `handoff\dad-packet.md`: present
- `handoff\recording-packet.md`: present
- `handoff\editor-packet.md`: present
- `handoff\publishing-packet.md`: present
- `handoff\marketing\youtube-upload.md`: present
- `handoff\marketing\youtube-description.txt`: present
- `handoff\marketing\rss-upload.md`: present
- `handoff\marketing\social-posts.md`: present
- `handoff\marketing\newsletter-blurb.md`: present
- `handoff\marketing\clip-candidates.csv`: present
- `handoff\marketing\distribution-checklist.md`: present
- `handoff\marketing\upload-fields.json`: present

## Step Output

### Preflight episode status

- Status: PASS
- Command: `.\tools\episode-status.ps1 -Episode 001-pilot`

```text
Episode: 001-pilot
Folder:  C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot


File                Status  Bytes
----                ------  -----
episode.md          Present  3768
sources.md          Present  3820
dad-brief.md        Present  2444
production-notes.md Present   829
publishing.md       Present  6838


Optional artifacts:

File                                           Status  Bytes
----                                           ------  -----
research-inbox.md                              Present  7303
research-inbox.json                            Present 18304
research-drafts.md                             Present  5586
research-drafts.json                           Present 11275
research-scout.md                              Present  4686
research-candidates.json                       Present  4607
dashboard-data.js                              Present  3090
title-thumbnail.md                             Present  4609
title-thumbnail.json                           Present  8028
thumbnail-images.json                          Present   394
transcript.md                                  Present   521
edit-plan.md                                   Present  2246
edit-plan.json                                 Present  1552
archive.json                                   Present 11851
automation-report.md                           Present 17940
handoff\session-launch.md                      Present  1460
handoff\edit-plan.md                           Present  2246
handoff\editor\chapters.csv                    Present    57
handoff\editor\clip-candidates.csv             Present    48
handoff\editor\transcript-cleanup-checklist.md Present   524
handoff\marketing\title-options.md             Present  1363
handoff\marketing\thumbnail-brief.md           Present  1372
handoff\marketing\thumbnail-prompts.txt        Present  1608
handoff\marketing\thumbnail-board.html         Present  8582
handoff\marketing\generated-thumbnails.md      Present  1471
handoff\dad-packet.md                          Present  2505
handoff\recording-packet.md                    Present  1272
handoff\editor-packet.md                       Present  1893
handoff\publishing-packet.md                   Present  6112
handoff\marketing\youtube-upload.md            Present  1767
handoff\marketing\youtube-description.txt      Present  1452
handoff\marketing\rss-upload.md                Present  1802
handoff\marketing\social-posts.md              Present  1173
handoff\marketing\newsletter-blurb.md          Present   956
handoff\marketing\clip-candidates.csv          Present    94
handoff\marketing\distribution-checklist.md    Present   356
handoff\marketing\upload-fields.json           Present 16752


Source URL count: 22
Open placeholder count: 5

Episode workspace has the required files.
```

### Source validation

- Status: PASS
- Command: `.\tools\validate-sources.ps1 -Path C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot -TimeoutSec 20`

```text
File                             Line Status Code Url
----                             ---- ------ ---- ---
episodes\001-pilot\episode.md      31 OK      200 https://blog.google/innovation-and-ai/technology/ai/google-io-2026...
episodes\001-pilot\episode.md      40 OK      200 https://www.microsoft.com/en-us/security/blog/2026/05/12/defense-a...
episodes\001-pilot\episode.md      49 OK      200 https://digital-strategy.ec.europa.eu/en/news/commission-opens-con...
episodes\001-pilot\episode.md      58 OK      200 https://www.anthropic.com/news/anthropic-acquires-stainless
episodes\001-pilot\publishing.md   31 OK      200 https://blog.google/innovation-and-ai/technology/ai/google-io-2026...
episodes\001-pilot\publishing.md   32 OK      200 https://www.microsoft.com/en-us/security/blog/2026/05/12/defense-a...
episodes\001-pilot\publishing.md   33 OK      200 https://digital-strategy.ec.europa.eu/en/news/commission-opens-con...
episodes\001-pilot\publishing.md   48 OK      200 https://blog.google/innovation-and-ai/technology/ai/google-io-2026...
episodes\001-pilot\publishing.md   49 OK      200 https://www.microsoft.com/en-us/security/blog/2026/05/12/defense-a...
episodes\001-pilot\publishing.md   50 OK      200 https://digital-strategy.ec.europa.eu/en/news/commission-opens-con...
episodes\001-pilot\publishing.md   71 OK      200 https://blog.google/innovation-and-ai/technology/ai/google-io-2026...
episodes\001-pilot\publishing.md   72 OK      200 https://www.microsoft.com/en-us/security/blog/2026/05/12/defense-a...
episodes\001-pilot\publishing.md   73 OK      200 https://digital-strategy.ec.europa.eu/en/news/commission-opens-con...
episodes\001-pilot\sources.md       7 OK      200 https://blog.google/innovation-and-ai/technology/ai/google-io-2026...
episodes\001-pilot\sources.md       8 OK      200 https://www.microsoft.com/en-us/security/blog/2026/05/12/defense-a...
episodes\001-pilot\sources.md       9 OK      200 https://digital-strategy.ec.europa.eu/en/news/commission-opens-con...
episodes\001-pilot\sources.md      10 OK      200 https://www.anthropic.com/news/anthropic-acquires-stainless
episodes\001-pilot\sources.md      11 OK      200 https://www.anthropic.com/news/series-h
episodes\001-pilot\sources.md      17 OK      200 https://blog.google/innovation-and-ai/technology/ai/google-io-2026...
episodes\001-pilot\sources.md      18 OK      200 https://www.microsoft.com/en-us/security/blog/2026/05/12/defense-a...
episodes\001-pilot\sources.md      19 OK      200 https://digital-strategy.ec.europa.eu/en/news/commission-opens-con...
episodes\001-pilot\sources.md      20 OK      200 https://www.anthropic.com/news/anthropic-acquires-stainless



Checked 22 source reference(s); all reachable.
```

### Collect research feeds

- Status: PASS
- Command: `.\tools\collect-research-feeds.ps1 -Episode 001-pilot`

```text
Research inbox written: C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot\research-inbox.md
Research inbox JSON written: C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot\research-inbox.json
Feed items: 25
Feed errors: 0
```

### Draft research candidates

- Status: PASS
- Command: `.\tools\draft-research-candidates.ps1 -Episode 001-pilot`

```text
Research drafts written: C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot\research-drafts.md
Research drafts JSON written: C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot\research-drafts.json
Drafts: 10
Append to sources: False
```

### Research scout

- Status: PASS
- Command: `.\tools\generate-research-scout.ps1 -Episode 001-pilot`

```text
Research scout written: C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot\research-scout.md
Research candidates JSON written: C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot\research-candidates.json
Selected: 3
Backup: 2
Candidates: 0
```

### Dad brief

- Status: PASS
- Command: `.\tools\generate-dad-brief.ps1 -Episode 001-pilot`

```text
Dad brief written: C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot\dad-brief.md
Stories: 3
Episode: 001 Pilot
```

### Dashboard data export

- Status: PASS
- Command: `.\tools\export-dashboard-data.ps1 -Episode 001-pilot -UpdateDashboard`

```text
Dashboard data written: C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot\dashboard-data.js
News items: 3
Featured sparks: 5
Custom sparks: 0
Dashboard EPISODE block already current: C:\Users\Shane\Documents\reel-it-in\app\reel-it-in.html
```

### Edit plan

- Status: PASS
- Command: `.\tools\generate-edit-plan.ps1 -Episode 001-pilot`

```text
Edit plan written: C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot\edit-plan.md
Editor handoff:    C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot\handoff\edit-plan.md
Editor CSV folder: C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot\handoff\editor
Transcript status: Template present; transcript not added yet
Chapters: 1
Clip candidates: 0
```

### Publishing package

- Status: PASS
- Command: `.\tools\generate-publishing-package.ps1 -Episode 001-pilot`

```text
Publishing package written: C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot\publishing.md
Stories: 3
Source links: 3
Chapters: 1
Clip candidates: 1
```

### Title and thumbnail package

- Status: PASS
- Command: `.\tools\generate-title-thumbnail-package.ps1 -Episode 001-pilot`

```text
Title and thumbnail package written: C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot\title-thumbnail.md
Title options: 11
Thumbnail options: 4
Thumbnail board: C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot\handoff\marketing\thumbnail-board.html
```

### Production packets

- Status: PASS
- Command: `.\tools\export-production-packets.ps1 -Episode 001-pilot`

```text
Production packets written: C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot\handoff
Dad packet:        dad-packet.md
Recording packet:  recording-packet.md
Editor packet:     editor-packet.md
Publishing packet: publishing-packet.md
```

### Marketing assets

- Status: PASS
- Command: `.\tools\export-marketing-assets.ps1 -Episode 001-pilot`

```text
Marketing assets written: C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot\handoff\marketing
YouTube title: Reel It In 001: Pilot
RSS title: Reel It In 001: Pilot
Clips: 1
Source links: 3
```

### Archive metadata

- Status: PASS
- Command: `.\tools\export-archive-metadata.ps1 -Episode 001-pilot -UpdateIndex`

```text
Archive metadata written: C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot\archive.json
Selected stories: 3
Source links: 3
Clip candidates: 0
Episode index written: C:\Users\Shane\Documents\reel-it-in\episodes\index.json
Indexed episodes: 1
```

### Postflight episode status

- Status: PASS
- Command: `.\tools\episode-status.ps1 -Episode 001-pilot`

```text
Episode: 001-pilot
Folder:  C:\Users\Shane\Documents\reel-it-in\episodes\001-pilot


File                Status  Bytes
----                ------  -----
episode.md          Present  3768
sources.md          Present  3820
dad-brief.md        Present  2444
production-notes.md Present   829
publishing.md       Present  6838


Optional artifacts:

File                                           Status  Bytes
----                                           ------  -----
research-inbox.md                              Present  7338
research-inbox.json                            Present 18356
research-drafts.md                             Present  5697
research-drafts.json                           Present 11392
research-scout.md                              Present  4686
research-candidates.json                       Present  4607
dashboard-data.js                              Present  3090
title-thumbnail.md                             Present  4609
title-thumbnail.json                           Present  8028
thumbnail-images.json                          Present   394
transcript.md                                  Present   521
edit-plan.md                                   Present  2246
edit-plan.json                                 Present  1552
archive.json                                   Present 11851
automation-report.md                           Present 17940
handoff\session-launch.md                      Present  1460
handoff\edit-plan.md                           Present  2246
handoff\editor\chapters.csv                    Present    57
handoff\editor\clip-candidates.csv             Present    48
handoff\editor\transcript-cleanup-checklist.md Present   524
handoff\marketing\title-options.md             Present  1363
handoff\marketing\thumbnail-brief.md           Present  1372
handoff\marketing\thumbnail-prompts.txt        Present  1608
handoff\marketing\thumbnail-board.html         Present  8582
handoff\marketing\generated-thumbnails.md      Present  1471
handoff\dad-packet.md                          Present  2505
handoff\recording-packet.md                    Present  1272
handoff\editor-packet.md                       Present  1893
handoff\publishing-packet.md                   Present  6112
handoff\marketing\youtube-upload.md            Present  1767
handoff\marketing\youtube-description.txt      Present  1452
handoff\marketing\rss-upload.md                Present  1802
handoff\marketing\social-posts.md              Present  1173
handoff\marketing\newsletter-blurb.md          Present   956
handoff\marketing\clip-candidates.csv          Present    94
handoff\marketing\distribution-checklist.md    Present   356
handoff\marketing\upload-fields.json           Present 16752


Source URL count: 22
Open placeholder count: 5

Episode workspace has the required files.
```

### Workspace git status

- Status: PASS
- Command: `git status --short`

```text
M .gitignore
 M CHANGELOG.md
 M README.md
 M app/reel-it-in.html
 M archive/README.md
 M docs/DECISIONS.md
 M docs/ROADMAP.md
 M docs/WORKFLOW.md
 M episodes/001-pilot/episode.md
 M episodes/001-pilot/production-notes.md
 M episodes/001-pilot/sources.md
 M episodes/README.md
 M production/README.md
 M production/intro-montage/README.md
 M production/publishing/README.md
 M tools/README.md
?? docs/AUTOMATION_PLAN.md
?? docs/OPERATIONAL_WORKFLOW.md
?? docs/RESEARCH_WATCHLIST.json
?? docs/WEEKLY_AUTOMATION_RUNBOOK.md
?? docs/operational-workflow.html
?? episodes/001-pilot/archive.json
?? episodes/001-pilot/automation-report.md
?? episodes/001-pilot/dad-brief.md
?? episodes/001-pilot/dashboard-data.js
?? episodes/001-pilot/edit-plan.json
?? episodes/001-pilot/edit-plan.md
?? episodes/001-pilot/handoff/
?? episodes/001-pilot/publishing.md
?? episodes/001-pilot/research-candidates.json
?? episodes/001-pilot/research-drafts.json
?? episodes/001-pilot/research-drafts.md
?? episodes/001-pilot/research-inbox.json
?? episodes/001-pilot/research-inbox.md
?? episodes/001-pilot/research-scout.md
?? episodes/001-pilot/thumbnail-images.json
?? episodes/001-pilot/title-thumbnail.json
?? episodes/001-pilot/title-thumbnail.md
?? episodes/001-pilot/transcript.md
?? episodes/_template/
?? episodes/index.json
?? production/intro-montage/flow-upload-pack/
?? production/intro-montage/prototypes/
?? production/recording/
?? tools/collect-research-feeds.ps1
?? tools/draft-research-candidates.ps1
?? tools/episode-status.ps1
?? tools/export-archive-metadata.ps1
?? tools/export-dashboard-data.ps1
?? tools/export-marketing-assets.ps1
?? tools/export-production-packets.ps1
?? tools/generate-dad-brief.ps1
?? tools/generate-edit-plan.ps1
?? tools/generate-publishing-package.ps1
?? tools/generate-research-scout.ps1
?? tools/generate-thumbnail-images.ps1
?? tools/generate-title-thumbnail-package.ps1
?? tools/new-episode.ps1
?? tools/run-episode-pipeline.ps1
?? tools/start-recording-session.ps1
?? tools/validate-sources.ps1
```
