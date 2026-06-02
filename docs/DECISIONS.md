# Decisions

Record durable decisions here so future sessions do not relitigate settled ground.

## 2026-05-31: Repo is organized around production lanes

Decision: split the repo into `app`, `design-system`, `docs`, `episodes`, `production`, `tools`, `archive`, and `inbox`.

Reason: future work spans product code, show planning, design assets, and media production. A flat root will become confusing quickly.

## 2026-05-31: Current product is an operator dashboard

Decision: optimize first for the host dashboard used during prep and recording, not a public marketing site.

Reason: the show has not recorded yet. The biggest immediate value is helping Shane and Dad create the show.

## 2026-05-31: Keep the pilot HTML self-contained for now

Decision: keep `app/reel-it-in.html` as a self-contained file until real production use proves the need for a build system.

Reason: the HTML can be opened directly, emailed, and used without setup. That simplicity is valuable during prototyping.

## 2026-05-31: Original zip is provenance, not source of truth

Decision: quarantine the design-system zip in `inbox/original-exports/` and ignore it from git.

Reason: extracted, named files are easier for Codex and humans to navigate. The zip should not be the working artifact.

## 2026-05-31: Mythology framing stays metaphorical

Decision: oracle, gods, spirits, and mythology language can guide creative framing, but the show must remain grounded.

Reason: the metaphor is memorable, but the audience trust depends on practical explanation and intellectual honesty.

## 2026-06-01: Git repo is the production brain, not the media vault

Decision: keep planning docs, episode metadata, source links, dashboard code, and automation scripts in git. Keep raw audio, raw video, rendered exports, and large editing artifacts in a separate shared cloud media folder.

Reason: Codex and GitHub are ideal for text and structured production artifacts. Large media files make git slow and brittle.

## 2026-06-01: Dad gets briefs, not repo access

Decision: Dad should receive a lightweight `dad-brief.md` export and a recording link, not a GitHub workflow.

Reason: Dad's role is to stay curious and representative of the listener. Making him operate project tooling would weaken the premise.

## 2026-06-01: Default production stack starts with Riverside, OBS, Descript, and Auphonic

Decision: use Riverside as the primary recording room, OBS as a local safety recorder when useful, Descript for transcript-first editing, and Auphonic for repeatable final audio processing.

Reason: this stack gives separate tracks, browser-based guest access, a local backup path, fast transcript editing, and repeatable loudness/mastering without forcing a custom build system.

## 2026-06-01: Episode automation stays PowerShell-first but must run cross-platform

Decision: keep the Episode Pipeline in PowerShell, but make it runnable under PowerShell Core on Windows and Linux through a cross-platform execution seam and shared tool modules.

Reason: the repo already has a broad PowerShell automation lane, and this fresh Linux machine needs local verification without forcing a rewrite before the first recording. See `docs/adr/0001-keep-powershell-core-for-episode-automation.md`.

## 2026-06-01: Foundation work has a complexity budget

Decision: improve the codebase by adding only the smallest architecture needed for clear operation: source-of-truth docs, fail-fast preflight behavior, tiny shared helpers for repeated script logic, and a thin YouTube reaction wrapper around the existing ingest pipeline.

Reason: Shane and Dad are starting the podcast now. The repo should make weekly production smooth before it becomes a platform. Dashboard build systems, broad adapter frameworks, schema systems, rewrites, and new dependencies stay deferred until real production pain proves they are simpler.

## 2026-06-01: Solo reaction episodes use the existing YouTube University ingest lane

Decision: operationalize Shane's existing `~/university/tools/ingest.sh` pipeline from Reel It In instead of rebuilding YouTube ingestion inside this repo.

Reason: the old lane already handles `yt-dlp`, `ffmpeg`, WhisperX, manifests, and transcript rendering. Reel It In only needs Episode Folder files, source links, and pointers to external transcript/media artifacts.
