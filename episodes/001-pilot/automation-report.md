# Automation Report

- Episode: 001-pilot
- Generated: 2026-06-11 06:49:19
- Result: Ready

## Pipeline

| Step | Status | Exit | Duration | Command |
| --- | --- | ---: | ---: | --- |
| Preflight episode status | PASS | 0 | 0.8s | `.\tools\episode-status.ps1 -Episode 001-pilot` |
| Research scout | PASS | 0 | 0.6s | `.\tools\generate-research-scout.ps1 -Episode 001-pilot` |
| Dad brief | PASS | 0 | 0.6s | `.\tools\generate-dad-brief.ps1 -Episode 001-pilot` |
| Dashboard data export | PASS | 0 | 0.6s | `.\tools\export-dashboard-data.ps1 -Episode 001-pilot` |
| Edit plan | PASS | 0 | 0.7s | `.\tools\generate-edit-plan.ps1 -Episode 001-pilot` |
| Publishing package | PASS | 0 | 0.7s | `.\tools\generate-publishing-package.ps1 -Episode 001-pilot` |
| Title and thumbnail package | PASS | 0 | 0.7s | `.\tools\generate-title-thumbnail-package.ps1 -Episode 001-pilot` |
| Production packets | PASS | 0 | 0.6s | `.\tools\export-production-packets.ps1 -Episode 001-pilot` |
| Marketing assets | PASS | 0 | 0.6s | `.\tools\export-marketing-assets.ps1 -Episode 001-pilot` |
| Archive metadata | PASS | 0 | 0.7s | `.\tools\export-archive-metadata.ps1 -Episode 001-pilot -UpdateIndex` |
| Postflight episode status | PASS | 0 | 0.6s | `.\tools\episode-status.ps1 -Episode 001-pilot` |
| Workspace git status | PASS | 0 | 0s | `git status --short` |

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
- `handoff/session-launch.md`: present
- `handoff/edit-plan.md`: present
- `handoff/editor\chapters.csv`: present
- `handoff/editor\clip-candidates.csv`: present
- `handoff/editor\transcript-cleanup-checklist.md`: present
- `handoff/marketing\title-options.md`: present
- `handoff/marketing\thumbnail-brief.md`: present
- `handoff/marketing\thumbnail-prompts.txt`: present
- `handoff/marketing\thumbnail-board.html`: present
- `handoff/marketing\generated-thumbnails.md`: present
- `handoff/dad-packet.md`: present
- `handoff/recording-packet.md`: present
- `handoff/editor-packet.md`: present
- `handoff/publishing-packet.md`: present
- `handoff/marketing\youtube-upload.md`: present
- `handoff/marketing\youtube-description.txt`: present
- `handoff/marketing\rss-upload.md`: present
- `handoff/marketing\social-posts.md`: present
- `handoff/marketing\newsletter-blurb.md`: present
- `handoff/marketing\clip-candidates.csv`: present
- `handoff/marketing\distribution-checklist.md`: present
- `handoff/marketing\upload-fields.json`: present

## Step Output

### Preflight episode status

- Status: PASS
- Command: `.\tools\episode-status.ps1 -Episode 001-pilot`

```text
Episode: 001-pilot
Folder:  /home/ark/reel-it-in/episodes/001-pilot


File                Status  Bytes
----                ------  -----
episode.md          Present  3768
sources.md          Present  3820
dad-brief.md        Present  2441
production-notes.md Present   829
publishing.md       Present  6835

Optional artifacts:

File                                           Status  Bytes
----                                           ------  -----
research-inbox.md                              Present  7337
research-inbox.json                            Present 18084
research-drafts.md                             Present  5696
research-drafts.json                           Present 11220
research-scout.md                              Present  4685
research-candidates.json                       Present  4544
dashboard-data.js                              Present  3046
title-thumbnail.md                             Present  4608
title-thumbnail.json                           Present  7898
thumbnail-images.json                          Present   380
transcript.md                                  Present   521
edit-plan.md                                   Present  2245
edit-plan.json                                 Present  1510
archive.json                                   Present 11696
automation-report.md                           Present 18166
handoff/session-launch.md                      Present  1459
handoff/edit-plan.md                           Present  2245
handoff/editor\chapters.csv                    Present    56
handoff/editor\clip-candidates.csv             Present    47
handoff/editor\transcript-cleanup-checklist.md Present   523
handoff/marketing\title-options.md             Present  1362
handoff/marketing\thumbnail-brief.md           Present  1371
handoff/marketing\thumbnail-prompts.txt        Present  1607
handoff/marketing\thumbnail-board.html         Present  8581
handoff/marketing\generated-thumbnails.md      Present  1470
handoff/dad-packet.md                          Present  2504
handoff/recording-packet.md                    Present  1271
handoff/editor-packet.md                       Present  1892
handoff/publishing-packet.md                   Present  6110
handoff/marketing\youtube-upload.md            Present  1766
handoff/marketing\youtube-description.txt      Present  1451
handoff/marketing\rss-upload.md                Present  1800
handoff/marketing\social-posts.md              Present  1172
handoff/marketing\newsletter-blurb.md          Present   955
handoff/marketing\clip-candidates.csv          Present    93
handoff/marketing\distribution-checklist.md    Present   355
handoff/marketing\upload-fields.json           Present 16565

Source URL count: 22
Open placeholder count: 5

Episode workspace has the required files.
```

### Research scout

- Status: PASS
- Command: `.\tools\generate-research-scout.ps1 -Episode 001-pilot`

```text
Research scout written: /home/ark/reel-it-in/episodes/001-pilot/research-scout.md
Research candidates JSON written: /home/ark/reel-it-in/episodes/001-pilot/research-candidates.json
Selected: 3
Backup: 2
Candidates: 0
```

### Dad brief

- Status: PASS
- Command: `.\tools\generate-dad-brief.ps1 -Episode 001-pilot`

```text
Dad brief written: /home/ark/reel-it-in/episodes/001-pilot/dad-brief.md
Stories: 3
Episode: 001 Pilot
```

### Dashboard data export

- Status: PASS
- Command: `.\tools\export-dashboard-data.ps1 -Episode 001-pilot`

```text
Dashboard data written: /home/ark/reel-it-in/episodes/001-pilot/dashboard-data.js
News items: 3
Featured sparks: 5
Custom sparks: 0
```

### Edit plan

- Status: PASS
- Command: `.\tools\generate-edit-plan.ps1 -Episode 001-pilot`

```text
Edit plan written: /home/ark/reel-it-in/episodes/001-pilot/edit-plan.md
Editor handoff:    /home/ark/reel-it-in/episodes/001-pilot/handoff/edit-plan.md
Editor CSV folder: /home/ark/reel-it-in/episodes/001-pilot/handoff/editor
Transcript status: Template present; transcript not added yet
Chapters: 1
Clip candidates: 0
```

### Publishing package

- Status: PASS
- Command: `.\tools\generate-publishing-package.ps1 -Episode 001-pilot`

```text
Publishing package written: /home/ark/reel-it-in/episodes/001-pilot/publishing.md
Stories: 3
Source links: 3
Chapters: 1
Clip candidates: 1
```

### Title and thumbnail package

- Status: PASS
- Command: `.\tools\generate-title-thumbnail-package.ps1 -Episode 001-pilot`

```text
Title and thumbnail package written: /home/ark/reel-it-in/episodes/001-pilot/title-thumbnail.md
Title options: 11
Thumbnail options: 4
Thumbnail board: /home/ark/reel-it-in/episodes/001-pilot/handoff/marketing/thumbnail-board.html
```

### Production packets

- Status: PASS
- Command: `.\tools\export-production-packets.ps1 -Episode 001-pilot`

```text
Production packets written: /home/ark/reel-it-in/episodes/001-pilot/handoff
Dad packet:        dad-packet.md
Recording packet:  recording-packet.md
Editor packet:     editor-packet.md
Publishing packet: publishing-packet.md
```

### Marketing assets

- Status: PASS
- Command: `.\tools\export-marketing-assets.ps1 -Episode 001-pilot`

```text
Marketing assets written: /home/ark/reel-it-in/episodes/001-pilot/handoff/marketing
YouTube title: Reel It In 001: Pilot
RSS title: Reel It In 001: Pilot
Clips: 1
Source links: 3
```

### Archive metadata

- Status: PASS
- Command: `.\tools\export-archive-metadata.ps1 -Episode 001-pilot -UpdateIndex`

```text
Archive metadata written: /home/ark/reel-it-in/episodes/001-pilot/archive.json
Selected stories: 3
Source links: 3
Clip candidates: 0
Episode index written: /home/ark/reel-it-in/episodes/index.json
Indexed episodes: 1
```

### Postflight episode status

- Status: PASS
- Command: `.\tools\episode-status.ps1 -Episode 001-pilot`

```text
Episode: 001-pilot
Folder:  /home/ark/reel-it-in/episodes/001-pilot


File                Status  Bytes
----                ------  -----
episode.md          Present  3768
sources.md          Present  3820
dad-brief.md        Present  2440
production-notes.md Present   829
publishing.md       Present  6834

Optional artifacts:

File                                           Status  Bytes
----                                           ------  -----
research-inbox.md                              Present  7337
research-inbox.json                            Present 18084
research-drafts.md                             Present  5696
research-drafts.json                           Present 11220
research-scout.md                              Present  4685
research-candidates.json                       Present  3393
dashboard-data.js                              Present  2489
title-thumbnail.md                             Present  4608
title-thumbnail.json                           Present  4986
thumbnail-images.json                          Present   380
transcript.md                                  Present   521
edit-plan.md                                   Present  2245
edit-plan.json                                 Present  1027
archive.json                                   Present  7410
automation-report.md                           Present 18166
handoff/session-launch.md                      Present  1459
handoff/edit-plan.md                           Present  2245
handoff/editor\chapters.csv                    Present    56
handoff/editor\clip-candidates.csv             Present    47
handoff/editor\transcript-cleanup-checklist.md Present   523
handoff/marketing\title-options.md             Present  1362
handoff/marketing\thumbnail-brief.md           Present  1371
handoff/marketing\thumbnail-prompts.txt        Present  1607
handoff/marketing\thumbnail-board.html         Present  8581
handoff/marketing\generated-thumbnails.md      Present  1470
handoff/dad-packet.md                          Present  2504
handoff/recording-packet.md                    Present  1271
handoff/editor-packet.md                       Present  1892
handoff/publishing-packet.md                   Present  6111
handoff/marketing\youtube-upload.md            Present  1766
handoff/marketing\youtube-description.txt      Present  1451
handoff/marketing\rss-upload.md                Present  1801
handoff/marketing\social-posts.md              Present  1172
handoff/marketing\newsletter-blurb.md          Present   955
handoff/marketing\clip-candidates.csv          Present    93
handoff/marketing\distribution-checklist.md    Present   355
handoff/marketing\upload-fields.json           Present 10945

Source URL count: 22
Open placeholder count: 5

Episode workspace has the required files.
```

### Workspace git status

- Status: PASS
- Command: `git status --short`

```text
M episodes/001-pilot/archive.json
 M episodes/001-pilot/dad-brief.md
 M episodes/001-pilot/dashboard-data.js
 M episodes/001-pilot/edit-plan.json
 M episodes/001-pilot/edit-plan.md
 M episodes/001-pilot/handoff/edit-plan.md
 M episodes/001-pilot/handoff/marketing/rss-upload.md
 M episodes/001-pilot/handoff/marketing/upload-fields.json
 M episodes/001-pilot/handoff/publishing-packet.md
 M episodes/001-pilot/publishing.md
 M episodes/001-pilot/research-candidates.json
 M episodes/001-pilot/title-thumbnail.json
 M episodes/index.json
```
