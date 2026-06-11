# Tools

Scripts and automation for weekly episode production.

Current tools:

- `new-episode.ps1`: create a new episode folder from `episodes/_template/`
- `prepare-reaction-episode.py`: create/update a Solo Reaction Episode from a YouTube URL and optionally call the existing `~/university/tools/ingest.sh` transcript pipeline.
- `collect-x-insights.py`: optional Grok Build X discourse briefs for selected stories (`--allow-network`).
- `fetch-page-summaries.py`: optional lightweight page summaries for empty research inbox rows (`--allow-network`).
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

Shared foundation:

- `Modules/ReelItIn.Tools.psm1`: tiny shared helpers for episode folder resolution, relative paths, markdown/list parsing, UTF-8 text writes, and PowerShell runtime resolution. Keep this module boring; add helpers only when repeated scripts need the same behavior.
- `Tests/test_tools_foundation.py`: dependency-free static regression check for the shared module imports, cross-platform path seams, and runtime resolver.
- `Tests/test_research_enrichment.py`: static checks for optional research enrichment tools and dashboard xInsight wiring.

### PowerShell Core on Linux

If `pwsh` is not installed system-wide, a portable build works:

```bash
mkdir -p ~/.local/powershell
curl -fsSL https://github.com/PowerShell/PowerShell/releases/download/v7.5.1/powershell-7.5.1-linux-x64.tar.gz -o /tmp/pwsh.tar.gz
tar -xzf /tmp/pwsh.tar.gz -C ~/.local/powershell
chmod +x ~/.local/powershell/pwsh
export PATH="$HOME/.local/powershell:$PATH"
```

Solo reaction entrypoint:

```bash
python3 tools/prepare-reaction-episode.py --url "<youtube-url>" --ingest --force
```

This keeps YouTube University transcript/media artifacts under `~/university/` and writes only Episode Folder pointers into this repo.

Good next tools:

- draft deeper show notes from transcript exports
- generate archive/web views from `episodes/index.json`

Do not add a build system until the single-file workflow becomes a real bottleneck.
