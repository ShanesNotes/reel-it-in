#!/usr/bin/env python3
"""Regression checks for the lightweight solo reaction episode prep tool."""

from __future__ import annotations

import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "tools" / "prepare-reaction-episode.py"

spec = importlib.util.spec_from_file_location("prepare_reaction_episode", SCRIPT)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def test_extract_video_id() -> None:
    require(module.extract_video_id("https://youtu.be/vc4WtPXgk88?si=x") == "vc4WtPXgk88", "short URL video id not parsed")
    require(module.extract_video_id("https://www.youtube.com/watch?v=vc4WtPXgk88") == "vc4WtPXgk88", "watch URL video id not parsed")
    require(module.extract_video_id("vc4WtPXgk88") == "vc4WtPXgk88", "raw video id not parsed")


def test_chapter_parsing() -> None:
    description = """
00:00:00 - Introduction & Setting the Table
00:01:46 - John's Opening: The Plateau
1:14:05 - Reversing the Flynn Effect
not a chapter
"""
    chapters = module.parse_chapters(description)
    require(chapters == [
        ("00:00:00", "Introduction & Setting the Table"),
        ("00:01:46", "John's Opening: The Plateau"),
        ("1:14:05", "Reversing the Flynn Effect"),
    ], f"unexpected chapters: {chapters!r}")


def test_render_keeps_ingestion_lightweight() -> None:
    metadata = {
        "id": "vc4WtPXgk88",
        "title": "John Vervaeke & Jonathan Pageau - AI Discussion",
        "channel": "Transfigured",
        "duration": 4965,
        "upload_date": "20260601",
        "description": "00:00:00 - Intro",
    }
    episode = module.render_episode_md("002", "Reaction", "https://youtu.be/vc4WtPXgk88", metadata, [("00:00:00", "Intro")])
    require("Do not download or commit raw video/audio to git." in episode, "raw media guardrail missing")
    require("## Reaction Beats" in episode, "reaction beats missing")
    require("Format: Solo Reaction Episode" in episode, "solo format metadata missing")
    require("YouTube University Ingest" in episode, "ingest section missing")


def test_ingest_manifest_paths_are_externalized() -> None:
    manifest = module.load_ingest_manifest(None)
    require(manifest == {}, "empty manifest should stay empty")
    ingest_doc = module.render_source_ingest_md(
        "https://youtu.be/vc4WtPXgk88",
        {
            "id": "vc4WtPXgk88",
            "title": "John Vervaeke & Jonathan Pageau - AI Discussion",
            "channel": "Transfigured",
            "duration": 4965,
        },
        {
            "_root": "/home/ark/university/transfigured/video",
            "_manifest_path": "/home/ark/university/transfigured/video/manifest.json",
            "_transcript_path": "/home/ark/university/transfigured/video/transcript.md",
            "_audio_path": "/home/ark/university/transfigured/video/audio/source.wav",
        },
    )
    require("/home/ark/university/transfigured/video/transcript.md" in ingest_doc, "transcript path missing")
    require("Keep YouTube University artifacts outside git." in ingest_doc, "external artifact guardrail missing")


if __name__ == "__main__":
    test_extract_video_id()
    test_chapter_parsing()
    test_render_keeps_ingestion_lightweight()
    test_ingest_manifest_paths_are_externalized()
    print("reaction episode checks passed")
