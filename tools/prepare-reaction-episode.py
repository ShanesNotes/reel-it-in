#!/usr/bin/env python3
"""Prepare a simple Reel It In solo reaction Episode from a YouTube URL.

Default behavior creates the required Episode files from YouTube metadata.
Pass `--ingest` to call Shane's existing `~/university/tools/ingest.sh`
YouTube University pipeline and link the external transcript artifacts back into
the Episode Folder. Raw media and full transcripts stay outside git.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
EPISODES_DIR = ROOT / "episodes"
DEFAULT_UNIVERSITY_DIR = Path.home() / "university"
DEFAULT_INGEST_SCRIPT = DEFAULT_UNIVERSITY_DIR / "tools" / "ingest.sh"
DEFAULT_PROFILE = DEFAULT_UNIVERSITY_DIR / "tools" / "whisperx_profile.yaml"

VIDEO_ID_RE = re.compile(r"(?:v=|youtu\.be/|shorts/|embed/|live/)([A-Za-z0-9_-]{11})|^([A-Za-z0-9_-]{11})$")
CHAPTER_RE = re.compile(r"^\s*(?P<time>(?:\d{1,2}:)?\d{1,2}:\d{2})\s*(?:[-–—|:]\s*)?(?P<title>.+?)\s*$")


def extract_video_id(value: str) -> str:
    match = VIDEO_ID_RE.search(value.strip())
    if not match:
        return ""
    return next(group for group in match.groups() if group)


def slugify(value: str, *, max_length: int = 72) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    slug = re.sub(r"-+", "-", slug)
    return (slug[:max_length].rstrip("-") or "reaction")


def format_duration(seconds: Any) -> str:
    try:
        total = int(seconds or 0)
    except (TypeError, ValueError):
        total = 0
    hours, remainder = divmod(total, 3600)
    minutes, secs = divmod(remainder, 60)
    if hours:
        return f"{hours}:{minutes:02d}:{secs:02d}"
    return f"{minutes}:{secs:02d}"


def format_upload_date(value: Any) -> str:
    text = str(value or "").strip()
    if re.fullmatch(r"\d{8}", text):
        return f"{text[:4]}-{text[4:6]}-{text[6:8]}"
    return text


def parse_chapters(description: str) -> list[tuple[str, str]]:
    chapters: list[tuple[str, str]] = []
    for line in description.splitlines():
        match = CHAPTER_RE.match(line)
        if not match:
            continue
        title = match.group("title").strip(" -–—|:")
        if title:
            chapters.append((match.group("time"), title))
    return chapters


def next_episode_number(episodes_dir: Path = EPISODES_DIR) -> int:
    numbers: list[int] = []
    for child in episodes_dir.iterdir() if episodes_dir.exists() else []:
        if child.is_dir() and re.match(r"^\d{3}", child.name):
            numbers.append(int(child.name[:3]))
    return max(numbers, default=0) + 1


def fetch_metadata(url: str, *, timeout: int = 120) -> dict[str, Any]:
    exe = shutil.which("yt-dlp")
    if not exe:
        raise RuntimeError("yt-dlp is not installed or not on PATH. Install it or rerun with --no-fetch.")

    result = subprocess.run(
        [exe, "--dump-json", "--no-download", url],
        check=False,
        capture_output=True,
        text=True,
        timeout=timeout,
    )
    if result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()
        raise RuntimeError(f"yt-dlp metadata fetch failed: {detail}")
    return json.loads(result.stdout)


def run_university_ingest(
    url: str,
    *,
    ingest_script: Path,
    out_dir: Path,
    profile: Path,
    source_kind: str,
    dry_run: bool = False,
) -> str:
    if not ingest_script.exists():
        raise RuntimeError(f"YouTube ingest script not found: {ingest_script}")
    if not profile.exists():
        raise RuntimeError(f"WhisperX profile not found: {profile}")

    command = [
        "bash",
        str(ingest_script),
        "--url",
        url,
        "--out-dir",
        str(out_dir),
        "--profile",
        str(profile),
        "--source-kind",
        source_kind,
    ]
    if dry_run:
        command.append("--dry-run")

    if dry_run:
        result = subprocess.run(command, check=False, capture_output=True, text=True)
        output = "\n".join(part for part in [result.stdout.strip(), result.stderr.strip()] if part)
    else:
        result = subprocess.run(command, check=False, text=True)
        output = "Ran YouTube University ingest:\n" + " ".join(command)

    if result.returncode != 0:
        raise RuntimeError(f"YouTube University ingest failed with exit {result.returncode}:\n{output}")
    return output


def find_ingest_manifest(out_dir: Path, video_id: str) -> Path | None:
    if not video_id or not out_dir.exists():
        return None
    matches: list[Path] = []
    for manifest_path in out_dir.rglob("manifest.json"):
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if manifest.get("video_id") == video_id:
            matches.append(manifest_path)
    if not matches:
        return None
    return max(matches, key=lambda path: path.stat().st_mtime)


def load_ingest_manifest(path: Path | None) -> dict[str, Any]:
    if not path:
        return {}
    manifest = json.loads(path.read_text(encoding="utf-8"))
    manifest["_manifest_path"] = str(path)
    manifest["_root"] = str(path.parent)
    paths = manifest.get("paths") or {}
    transcript_rel = paths.get("transcript_md") or "transcript.md"
    audio_rel = paths.get("audio") or "audio/source.wav"
    manifest["_transcript_path"] = str(path.parent / transcript_rel)
    manifest["_audio_path"] = str(path.parent / audio_rel)
    return manifest


def markdown_table_row(values: list[str]) -> str:
    escaped = [value.replace("|", "\\|").replace("\n", " ").strip() for value in values]
    return "| " + " | ".join(escaped) + " |"


def render_ingest_lines(ingest: dict[str, Any]) -> str:
    if not ingest:
        return "- Status: Not run yet. Run `tools/prepare-reaction-episode.py --ingest ...` when a transcript is useful."
    return "\n".join(
        [
            "- Status: Ingested through YouTube University.",
            f"- Manifest: `{ingest.get('_manifest_path')}`",
            f"- Transcript: `{ingest.get('_transcript_path')}`",
            f"- Audio: `{ingest.get('_audio_path')}`",
            "- Repo rule: keep those large artifacts outside git; this Episode Folder only points to them.",
        ]
    )


def render_episode_md(episode_number: str, title: str, url: str, metadata: dict[str, Any], chapters: list[tuple[str, str]], ingest: dict[str, Any] | None = None) -> str:
    channel = metadata.get("channel") or metadata.get("uploader") or "Unknown channel"
    upload_date = format_upload_date(metadata.get("upload_date")) or "Unknown"
    duration = format_duration(metadata.get("duration"))
    video_title = metadata.get("title") or title

    beat_lines = []
    for timecode, chapter_title in chapters[:12]:
        beat_lines.append(f"- {timecode} — {chapter_title}: pause if there is a plain-English consequence, disagreement, or Dad-would-ask-that moment.")
    if not beat_lines:
        beat_lines.append("- Add live pause points while watching. React to claims, not every sentence.")

    return f"""# Episode {episode_number}: {title}

## Status

Prep for solo reaction livestream.

## Metadata

- Number: {episode_number}
- Label: {title}
- Date: {dt.date.today().isoformat()}
- Format: Solo Reaction Episode
- Host 1: Shane
- Host 2: Solo

## Dashboard

Current dashboard: `../../app/reel-it-in.html`

## Working Angle

Shane watches one outside AI conversation and turns it into plain-English commentary for Reel It In listeners: what is being claimed, what seems true, what seems overstated, and why normal people should care.

## Source Video

- Title: [{video_title}]({url})
- Channel: {channel}
- Upload date: {upload_date}
- Duration: {duration}
- Source video ID: {metadata.get('id') or extract_video_id(url) or 'unknown'}

## YouTube University Ingest

{render_ingest_lines(ingest or {})}

## Selected Stories

### Story 1

- Source: [{video_title}]({url})
- Plain-English headline: A long-form AI discussion worth pausing, translating, and challenging live.
- What happened: {channel} published a conversation about artificial intelligence, wisdom, agency, and cultural consequences.
- Why it matters: Reaction format lets Shane keep the original voices visible while adding the Reel It In job: make the implications concrete and challenge abstractions as they appear.
- Dad question: If this is true, what changes for a normal person this year?
- Status: Selected

## Reaction Beats

{chr(10).join(beat_lines)}

## Sparks

- `oracle`
- `consciousness`
- `where-it-lives`
- `who-owns-temple`

## Live Stream Guardrails

- Keep commentary transformative: pause often, explain the claim, agree or push back, then move on.
- Do not download or commit raw video/audio to git.
- Capture Shane's commentary notes in `production-notes.md` during the stream.
- If a claim sounds factual and important, mark it for source checking instead of treating the video as proof.

## Open Questions

- Final stream title
- Whether to stream the full video or selected chapters
- Clip candidates from Shane's commentary
"""


def render_sources_md(url: str, metadata: dict[str, Any], ingest: dict[str, Any] | None = None) -> str:
    video_title = metadata.get("title") or "Source video"
    upload_date = format_upload_date(metadata.get("upload_date")) or ""
    return f"""# Sources

## Candidate Stories

| Status | Source | Date | Plain-English note | Why it matters | Dad question |
| --- | --- | --- | --- | --- | --- |
| Selected | [{video_title}]({url}) | {upload_date} | Source video for a solo reaction episode. | Gives Shane one focused AI conversation to translate and challenge live. | If this is true, what changes for a normal person this year? |

## Selected Sources

| Segment | Source | Date | Notes |
| --- | --- | --- | --- |
| Solo reaction | [{video_title}]({url}) | {upload_date} | Use as the video being watched and commented on. |

## Verification Notes

- This file records the source video; it does not prove every claim made in the video.
- During or after the stream, add primary sources for factual claims Shane wants to repeat as show claims.
- Do not commit downloaded video, audio, or full transcript files to git.
{f"- Transcript artifact: `{ingest.get('_transcript_path')}`" if ingest else "- Transcript artifact: not ingested yet."}
"""


def render_production_notes_md(metadata: dict[str, Any], chapters: list[tuple[str, str]], ingest: dict[str, Any] | None = None) -> str:
    rows = [markdown_table_row([timecode, title, "pause/comment/check"]) for timecode, title in chapters[:12]]
    if not rows:
        rows = ["|  |  |  |"]
    return f"""# Production Notes

## Recording Setup

- Recording service: Livestream / local recording
- Backup recording: OBS if useful
- Microphones:
- Camera:
- Headphones:
- Media folder:

## Source Playback

- Source video title: {metadata.get('title') or 'TBD'}
- Source channel: {metadata.get('channel') or metadata.get('uploader') or 'TBD'}
- Source duration: {format_duration(metadata.get('duration'))}
- Transcript artifact: {ingest.get('_transcript_path') if ingest else 'Not ingested yet.'}
- Playback plan: Pause for Shane commentary; do not let the source video replace the episode.

## Live Notes

Use action words like `chapter`, `clip`, `cut`, `fix`, `highlight`, `source-check`, or `pause` so the edit-plan generator can route the note.

| Timecode | Note | Action |
| --- | --- | --- |
{chr(10).join(rows)}

## Best Moments

-

## Confusing Spots

-

## Edit Decisions

-

## Follow-Up Source Checks

-
"""


def render_dad_brief_md(title: str) -> str:
    return f"""# Dad Brief

## Recording

- Date: {dt.date.today().isoformat()}
- Time:
- Link:

## Episode Theme

Solo reaction episode: {title}

## Note

Dad is not needed for this solo recording. Keep this file present so the standard Episode Pipeline can still run later if needed.

## What We Might Talk About

### 1. Source video reaction

- Plain-English version: Shane watches an outside AI conversation and pauses to translate, agree, challenge, and connect it to ordinary life.
- Why it matters: It is a lower-friction way to start recording and find the show's voice.
- A good question: If this is true, what changes for a normal person this year?

## Keep It Loose

The solo format should still sound like Reel It In: curious, grounded, and allergic to jargon.
"""


def render_publishing_md(title: str, url: str, metadata: dict[str, Any], chapters: list[tuple[str, str]], ingest: dict[str, Any] | None = None) -> str:
    chapter_rows = [markdown_table_row([timecode, chapter_title]) for timecode, chapter_title in chapters[:12]]
    if not chapter_rows:
        chapter_rows = ["| 00:00 | Intro |"]
    video_title = metadata.get("title") or "Source video"
    return f"""# Publishing

Generated by `tools/prepare-reaction-episode.py` as a first pass.

## Final Metadata

- Final title: Reel It In Reacts: {video_title}
- Short title: AI reaction
- Episode number:
- Release date:
- Runtime:
- Explicit: No

## Description

Shane reacts live to {video_title}, pausing to translate the AI claims into plain English and ask what they mean for normal people.

## Chapters

| Timecode | Title |
| --- | --- |
{chr(10).join(chapter_rows)}

## Source Links

- [{video_title}]({url})

## YouTube Package

- Title: Reel It In Reacts: {video_title}
- Description: Shane watches and comments on the source video, focusing on what the AI claims mean in everyday life. Source video: {url}
- Tags: AI, reaction, Reel It In
- Thumbnail idea: Shane watching the source video with one clear question: "What does this mean for us?"

## RSS Package

- Episode title: Reel It In Reacts: {video_title}
- Episode summary: Solo reaction episode with Shane translating and challenging an outside AI conversation.
- Episode notes: Source video: {url}
- Transcript: {ingest.get('_transcript_path') if ingest else ''}

## Social Copy

### Short Post

Tonight I'm trying a solo Reel It In reaction format: one AI conversation, frequent pauses, plain-English commentary, and no jargon hiding place.

### Newsletter Blurb

A solo reaction experiment: Shane watches a long-form AI conversation and keeps asking the Reel It In question — what does this actually change for normal people?

### Clip Candidates

| Clip | Timecode | Hook | Platform |
| --- | --- | --- | --- |
|  |  |  |  |

## Edit Package

### Best Moments

-

### Confusing Spots

-

### Edit Decisions

-

## Distribution Checklist

- [ ] Final audio exported.
- [ ] Final video exported if used.
- [ ] Audio mastered or normalized.
- [ ] Source links checked.
- [ ] Transcript checked for obvious errors.
- [ ] YouTube upload checked before public release.
- [ ] RSS episode checked after publish.
"""


def render_source_ingest_md(url: str, metadata: dict[str, Any], ingest: dict[str, Any] | None, ingest_output: str = "") -> str:
    video_title = metadata.get("title") or "Source video"
    lines = [
        "# YouTube Source Ingest",
        "",
        f"- Source: [{video_title}]({url})",
        f"- Video ID: {metadata.get('id') or extract_video_id(url) or 'unknown'}",
        f"- Channel: {metadata.get('channel') or metadata.get('uploader') or 'Unknown'}",
        f"- Duration: {format_duration(metadata.get('duration'))}",
        "",
        "## External Artifacts",
        "",
    ]
    if ingest:
        lines.extend(
            [
                f"- University root: `{ingest.get('_root')}`",
                f"- Manifest: `{ingest.get('_manifest_path')}`",
                f"- Transcript: `{ingest.get('_transcript_path')}`",
                f"- Audio: `{ingest.get('_audio_path')}`",
            ]
        )
    else:
        lines.append("- Not ingested yet.")
    lines.extend(
        [
            "",
            "## Operating Notes",
            "",
            "- Keep YouTube University artifacts outside git.",
            "- Use the transcript for prep, source checking, and post-stream edit notes.",
            "- Add primary sources to `sources.md` before repeating factual claims as Reel It In claims.",
        ]
    )
    if ingest_output:
        lines.extend(["", "## Last Ingest Output", "", "```text", ingest_output.strip(), "```"])
    return "\n".join(lines)


def write_file(path: Path, content: str, *, force: bool) -> None:
    if path.exists() and not force:
        raise FileExistsError(f"Refusing to overwrite {path}. Use --force to replace it.")
    path.write_text(content.strip() + "\n", encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Prepare a simple solo reaction Episode from a YouTube URL.")
    parser.add_argument("--url", required=True, help="YouTube URL to react to.")
    parser.add_argument("--title", default="", help="Episode title. Defaults to '<video title> Reaction'.")
    parser.add_argument("--number", type=int, default=0, help="Episode number. Defaults to next numbered folder.")
    parser.add_argument("--slug", default="", help="Folder slug override.")
    parser.add_argument("--episode", default="", help="Existing episode folder name/path to update instead of creating next numbered folder.")
    parser.add_argument("--force", action="store_true", help="Overwrite files in the target episode folder.")
    parser.add_argument("--no-fetch", action="store_true", help="Do not call yt-dlp; use URL/video ID only.")
    parser.add_argument("--ingest", action="store_true", help="Run the existing YouTube University ingest pipeline before writing episode files.")
    parser.add_argument("--ingest-dry-run", action="store_true", help="Exercise YouTube University ingest preflight without downloading/transcribing.")
    parser.add_argument("--ingest-script", default=str(DEFAULT_INGEST_SCRIPT), help="Path to the existing ingest.sh script.")
    parser.add_argument("--profile", default=str(DEFAULT_PROFILE), help="WhisperX profile for the existing ingest pipeline.")
    parser.add_argument("--university-dir", default=str(DEFAULT_UNIVERSITY_DIR), help="External YouTube University output directory.")
    parser.add_argument("--source-kind", default="solo", choices=["solo", "multi_speaker", "unknown"], help="Transcript source kind for WhisperX metadata.")
    args = parser.parse_args(argv)

    video_id = extract_video_id(args.url)
    metadata: dict[str, Any] = {"id": video_id, "webpage_url": args.url}
    if not args.no_fetch:
        metadata.update(fetch_metadata(args.url))

    ingest_output = ""
    ingest: dict[str, Any] = {}

    if args.ingest or args.ingest_dry_run:
        ingest_output = run_university_ingest(
            args.url,
            ingest_script=Path(args.ingest_script).expanduser(),
            out_dir=Path(args.university_dir).expanduser(),
            profile=Path(args.profile).expanduser(),
            source_kind=args.source_kind,
            dry_run=args.ingest_dry_run,
        )
        if args.ingest:
            manifest_path = find_ingest_manifest(Path(args.university_dir).expanduser(), metadata.get("id") or video_id)
            if not manifest_path:
                raise RuntimeError("YouTube University ingest completed, but no manifest.json was found for this video.")
            ingest = load_ingest_manifest(manifest_path)
    elif not args.ingest_dry_run:
        manifest_path = find_ingest_manifest(Path(args.university_dir).expanduser(), metadata.get("id") or video_id)
        if manifest_path:
            ingest = load_ingest_manifest(manifest_path)
    if ingest:
        for source_key, target_key in [
            ("title", "title"),
            ("channel", "channel"),
            ("duration_seconds", "duration"),
            ("upload_date", "upload_date"),
            ("url", "webpage_url"),
            ("description", "description"),
        ]:
            if not metadata.get(target_key) and ingest.get(source_key):
                metadata[target_key] = ingest[source_key]

    source_title = metadata.get("title") or "YouTube Reaction"
    episode_title = args.title.strip() or f"{source_title} Reaction"
    chapters = parse_chapters(str(metadata.get("description") or ""))

    if args.episode:
        episode_dir = Path(args.episode)
        if not episode_dir.is_absolute():
            candidate = EPISODES_DIR / args.episode
            episode_dir = candidate if candidate.exists() or re.match(r"^\d{3}", args.episode) else ROOT / args.episode
        number_text = re.match(r"^(\d{3})", episode_dir.name)
        episode_number = number_text.group(1) if number_text else f"{args.number or next_episode_number():03d}"
    else:
        episode_number = f"{args.number or next_episode_number():03d}"
        folder_slug = slugify(args.slug or episode_title)
        episode_dir = EPISODES_DIR / f"{episode_number}-{folder_slug}"

    episode_dir.mkdir(parents=True, exist_ok=True)

    files = {
        "episode.md": render_episode_md(episode_number, episode_title, args.url, metadata, chapters, ingest),
        "sources.md": render_sources_md(args.url, metadata, ingest),
        "dad-brief.md": render_dad_brief_md(episode_title),
        "production-notes.md": render_production_notes_md(metadata, chapters, ingest),
        "publishing.md": render_publishing_md(episode_title, args.url, metadata, chapters, ingest),
        "source-ingest.md": render_source_ingest_md(args.url, metadata, ingest, ingest_output),
    }
    if ingest:
        files["youtube-ingest.json"] = json.dumps(ingest, ensure_ascii=False, indent=2)

    for name, content in files.items():
        write_file(episode_dir / name, content, force=args.force)

    print(f"Reaction episode ready: {episode_dir.relative_to(ROOT)}")
    print(f"Source video: {metadata.get('title') or args.url}")
    print(f"Chapter beats: {len(chapters)}")
    if ingest:
        print(f"Transcript: {ingest.get('_transcript_path')}")
    elif args.ingest_dry_run:
        print("Ingest dry-run passed; rerun with --ingest for the real transcript.")
    print("Next: record/stream, capture commentary notes in production-notes.md, then run the Episode Pipeline when pwsh is available.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
