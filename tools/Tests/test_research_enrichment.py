#!/usr/bin/env python3
"""Static checks for optional research enrichment tools."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def test_research_tools_exist_and_require_opt_in() -> None:
    for name in ("collect-x-insights.py", "fetch-page-summaries.py"):
        text = read(ROOT / "tools" / name)
        require("--allow-network" in text, f"{name} lacks network opt-in flag")
        require("argparse" in text, f"{name} should use argparse")


def test_dashboard_export_merges_x_insights() -> None:
    export_script = read(ROOT / "tools" / "export-dashboard-data.ps1")
    require("x-insights.json" in export_script, "dashboard export does not read x-insights.json")
    require("xInsight" in export_script, "dashboard export does not attach xInsight")


def test_dashboard_template_metadata() -> None:
    html = read(ROOT / "app" / "reel-it-in.html")
    require('name="reel-it-in-version"' in html, "dashboard missing version metadata")
    require("x-insight" in html, "dashboard missing xInsight styles or render hook")


if __name__ == "__main__":
    test_research_tools_exist_and_require_opt_in()
    test_dashboard_export_merges_x_insights()
    test_dashboard_template_metadata()
    print("research enrichment checks passed")