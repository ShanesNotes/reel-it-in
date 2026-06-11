#!/usr/bin/env python3
"""Collect optional X discourse insights for episode stories via Grok Build.

Network and Grok calls are opt-in. Pass --allow-network to run.
Writes x-insights.md and x-insights.json in the Episode Folder.
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
URL_RE = re.compile(r"https?://[^\s\)\]\|]+")
STORY_BLOCK_RE = re.compile(
    r"(?ms)^###\s+(?P<title>.+?)\s*\r?\n(?P<body>.*?)(?=^###\s+|\Z)"
)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write_text(path: Path, content: str) -> None:
    path.write_text(content.rstrip() + "\n", encoding="utf-8")


def write_json(path: Path, data: Any) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def resolve_episode_dir(value: str) -> Path:
    if value:
        candidate = Path(value)
        if candidate.is_dir():
            return candidate.resolve()
        numbered = EPISODES_DIR / value
        if numbered.is_dir():
            return numbered.resolve()
        raise SystemExit(f"Episode folder not found: {value}")

    numbered_dirs = sorted(
        path for path in EPISODES_DIR.iterdir()
        if path.is_dir() and re.match(r"^\d{3}", path.name)
    )
    if not numbered_dirs:
        raise SystemExit(f"No numbered episode folders found under {EPISODES_DIR}")
    return numbered_dirs[-1].resolve()


def list_field(body: str, name: str) -> str:
    match = re.search(rf"(?mi)^-[ \t]*{re.escape(name)}[ \t]*:[ \t]*(?P<value>[^\r\n]*)", body)
    return match.group("value").strip() if match else ""


def load_stories(sources_path: Path) -> list[dict[str, str]]:
    if not sources_path.exists():
        raise SystemExit(f"Missing sources file: {sources_path}")

    text = read_text(sources_path)
    section_match = re.search(
        r"(?ms)^##\s+Candidate Stories\s*\r?\n(?P<body>.*?)(?=^##\s+|\Z)",
        text,
    )
    section = section_match.group("body") if section_match else text
    stories: list[dict[str, str]] = []

    for block in STORY_BLOCK_RE.finditer(section):
        body = block.group("body")
        status = list_field(body, "Status")
        if status and re.search(r"(?i)backup|discard", status):
            continue

        source = list_field(body, "Source")
        url_match = URL_RE.search(source)
        url = url_match.group(0).rstrip(".,;:)") if url_match else ""
        headline = list_field(body, "Plain-English headline") or block.group("title").strip()
        why = list_field(body, "Why it matters")

        if not url and not headline:
            continue

        stories.append(
            {
                "title": headline,
                "url": url,
                "source": source,
                "why": why,
                "status": status or "Selected",
            }
        )

    if stories:
        return stories

    table_match = re.search(
        r"(?ms)^\|[^\n]*Status[^\n]*\n\|[^\n]*\n(?P<rows>(?:\|.*\n)+)",
        section,
    )
    if not table_match:
        return stories

    for row in table_match.group("rows").strip().splitlines():
        cells = [cell.strip() for cell in row.strip("|").split("|")]
        if len(cells) < 3:
            continue
        status, source = cells[0], cells[1]
        if re.search(r"(?i)backup|discard", status):
            continue
        url_match = URL_RE.search(source)
        url = url_match.group(0).rstrip(".,;:)") if url_match else ""
        headline = cells[3] if len(cells) > 3 else source
        why = cells[4] if len(cells) > 4 else ""
        stories.append(
            {
                "title": headline,
                "url": url,
                "source": source,
                "why": why,
                "status": status,
            }
        )

    return stories


def build_prompt(story: dict[str, str]) -> str:
    return (
        "You are helping prep a father-son AI news show called Reel It In.\n"
        "Give a short X (Twitter) discourse brief for this story.\n"
        "Return exactly 3 bullet points:\n"
        "1) What people on X are arguing about\n"
        "2) One surprising or representative post angle (paraphrase, no fake quotes)\n"
        "3) A plain-English 'so what' for normal listeners\n"
        "Keep it under 120 words total. No hashtags spam. No lecturing tone.\n\n"
        f"Story title: {story['title']}\n"
        f"URL: {story.get('url', '')}\n"
        f"Why it matters: {story.get('why', '')}\n"
    )


def normalize_insight(text: str) -> str:
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    while lines and not re.match(r"^([-*•]|\d+[\).])", lines[0]):
        lines.pop(0)
    return "\n".join(lines).strip()


def call_grok(prompt: str, grok_bin: str) -> str:
    result = subprocess.run(
        [grok_bin, "-p", prompt],
        check=False,
        capture_output=True,
        text=True,
        cwd=ROOT,
    )
    if result.returncode != 0:
        stderr = (result.stderr or "").strip()
        raise RuntimeError(stderr or f"Grok exited with code {result.returncode}")
    return normalize_insight((result.stdout or "").strip())


def render_markdown(episode_name: str, items: list[dict[str, Any]]) -> str:
    lines = [
        "# X Insights",
        "",
        f"Generated by `tools/collect-x-insights.py` for `{episode_name}`.",
        "",
        "Optional discourse context for news beats. Shane still chooses what lands on air.",
        "",
    ]
    for item in items:
        lines.extend(
            [
                f"## {item['title']}",
                "",
                f"- URL: {item.get('url') or 'n/a'}",
                f"- Status: {item.get('status', 'n/a')}",
                "",
                item.get("xInsight", "").strip() or "_No insight generated._",
                "",
            ]
        )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--episode", default="", help="Episode folder name or path")
    parser.add_argument("--limit", type=int, default=3, help="Max stories to enrich")
    parser.add_argument("--grok-bin", default="grok", help="Grok Build CLI binary")
    parser.add_argument(
        "--allow-network",
        action="store_true",
        help="Required to call Grok Build (network opt-in)",
    )
    parser.add_argument("--dry-run", action="store_true", help="Print prompts only")
    args = parser.parse_args()

    episode_dir = resolve_episode_dir(args.episode)
    episode_name = episode_dir.name
    stories = load_stories(episode_dir / "sources.md")[: max(args.limit, 0)]

    if not stories:
        raise SystemExit(f"No selected stories found in {episode_dir / 'sources.md'}")

    if not args.allow_network and not args.dry_run:
        raise SystemExit(
            "Network opt-in required. Re-run with --allow-network to call Grok Build."
        )

    if not args.dry_run and not shutil.which(args.grok_bin):
        raise SystemExit(f"Grok Build CLI not found: {args.grok_bin}")

    generated_at = dt.datetime.now().replace(microsecond=0).isoformat()
    items: list[dict[str, Any]] = []

    for story in stories:
        prompt = build_prompt(story)
        if args.dry_run:
            print(f"\n--- {story['title']} ---\n{prompt}")
            insight = ""
            status = "dry-run"
        else:
            try:
                insight = call_grok(prompt, args.grok_bin)
                status = "ok"
            except RuntimeError as exc:
                insight = ""
                status = f"error: {exc}"

        items.append(
            {
                "title": story["title"],
                "url": story.get("url", ""),
                "status": story.get("status", ""),
                "xInsight": insight,
                "generationStatus": status,
            }
        )

    payload = {
        "schemaVersion": 1,
        "generatedAt": generated_at,
        "episode": episode_name,
        "provider": "grok-build",
        "itemCount": len(items),
        "items": items,
    }

    if args.dry_run:
        return 0

    write_json(episode_dir / "x-insights.json", payload)
    write_text(episode_dir / "x-insights.md", render_markdown(episode_name, items))
    print(f"Wrote {episode_dir / 'x-insights.json'}")
    print(f"Wrote {episode_dir / 'x-insights.md'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())