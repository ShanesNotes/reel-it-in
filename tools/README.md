# Tools

Future scripts and automation live here.

Current tools:

- `new-episode.ps1`: create a new episode folder from `episodes/_template/`
- `episode-status.ps1`: inspect required files and open placeholders for an episode
- `validate-sources.ps1`: find and check URLs in episode markdown files
- `collect-research-feeds.ps1`: collect fresh items from the research watchlist into `research-inbox.md` and JSON
- `draft-research-candidates.ps1`: score feed inbox items and draft candidate story rows with "so what?" and Dad questions
- `generate-research-scout.ps1`: summarize candidate stories, slate gaps, and research prompts from `sources.md`
- `generate-dad-brief.ps1`: generate the Dad-facing prep brief from selected episode stories
- `export-dashboard-data.ps1`: generate dashboard-ready `EPISODE` data from an episode folder
- `generate-edit-plan.ps1`: turn production notes and transcript markers into an edit plan, chapter CSV, clip CSV, transcript checklist, and editor handoff
- `generate-publishing-package.ps1`: draft RSS, YouTube, social, clip, and distribution copy from episode artifacts
- `generate-title-thumbnail-package.ps1`: generate title options, thumbnail concepts, image prompts, structured creative metadata, and a thumbnail board
- `generate-thumbnail-images.ps1`: optionally call the OpenAI image generation API to create thumbnail PNGs from the generated thumbnail prompts
- `export-production-packets.ps1`: generate Dad, recording, editor, and publishing handoff packets under the episode folder
- `export-marketing-assets.ps1`: split `publishing.md` into YouTube, RSS, social, newsletter, clip, checklist, and upload-field files
- `start-recording-session.ps1`: prepare recording day, create media folders, write `session-launch.md`, and open the session targets
- `export-archive-metadata.ps1`: generate structured episode archive metadata and the episode index
- `run-episode-pipeline.ps1`: run the status, source, dashboard, edit, publishing, handoff, archive, and git checks in one pass and write `automation-report.md`

Good next tools:

- draft deeper show notes from transcript exports
- generate archive/web views from `episodes/index.json`

Do not add a build system until the single-file workflow becomes a real bottleneck.
