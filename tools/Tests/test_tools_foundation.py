#!/usr/bin/env python3
"""Static regression checks for the minimal PowerShell tools foundation.

These checks intentionally avoid third-party dependencies and do not require
PowerShell Core. They protect the cross-platform seams until `pwsh` is available
for dynamic script tests.
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

EXPECTED_EXPORTS = [
    "Resolve-ReelItInEpisodeDirectory",
    "Join-ReelItInRelativePath",
    "Get-ReelItInMarkdownSection",
    "Get-ReelItInListField",
    "Write-ReelItInUtf8Text",
    "Resolve-ReelItInPowerShellExecutable",
]

MIGRATED_SCRIPTS = [
    ROOT / "tools" / "episode-status.ps1",
    ROOT / "tools" / "run-episode-pipeline.ps1",
    ROOT / "tools" / "start-recording-session.ps1",
]

FORBIDDEN_DUPLICATES = [
    "function Resolve-EpisodeDirectory",
    "function Resolve-PowerShellExecutable",
    "function Join-RelativePath",
]


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def test_module_exports() -> None:
    module = read(ROOT / "tools" / "Modules" / "ReelItIn.Tools.psm1")
    for name in EXPECTED_EXPORTS:
        require(f"function {name}" in module, f"missing function {name}")
        require(f'"{name}"' in module, f"missing Export-ModuleMember entry for {name}")


def test_migrated_scripts_import_module_and_drop_duplicates() -> None:
    for script in MIGRATED_SCRIPTS:
        text = read(script)
        require(
            'Import-Module (Join-Path $PSScriptRoot "Modules/ReelItIn.Tools.psm1") -Force' in text,
            f"{script.name} does not import the shared tools module",
        )
        for marker in FORBIDDEN_DUPLICATES:
            require(marker not in text, f"{script.name} still defines {marker}")

    start_recording = read(ROOT / "tools" / "start-recording-session.ps1")
    for marker in ["function Get-MarkdownSection", "function Get-ListField", "function Write-Utf8Text"]:
        require(marker not in start_recording, f"start-recording-session.ps1 still defines {marker}")


def test_cross_platform_seams_are_preserved() -> None:
    run_pipeline = read(ROOT / "tools" / "run-episode-pipeline.ps1")
    start_recording = read(ROOT / "tools" / "start-recording-session.ps1")
    episode_status = read(ROOT / "tools" / "episode-status.ps1")
    dashboard_export = read(ROOT / "tools" / "export-dashboard-data.ps1")

    combined = "\n".join([run_pipeline, start_recording])
    require('& powershell.exe' not in combined, "direct powershell.exe invocation returned")
    require('FileName "powershell.exe"' not in combined, "hardcoded powershell.exe FileName returned")
    require("Resolve-ReelItInPowerShellExecutable" in combined, "runtime resolver not used")
    require("Join-ReelItInRelativePath" in run_pipeline, "pipeline artifact paths are not normalized")
    require("Join-ReelItInRelativePath" in episode_status, "status artifact paths are not normalized")
    require('Join-Path (Join-Path $repoRoot "app") "reel-it-in.html"' in start_recording, "recording dashboard path is not platform-safe")
    require('Join-Path (Join-Path $repoRoot "app") "reel-it-in.html"' in dashboard_export, "dashboard export path is not platform-safe")


def test_docs_show_pwsh_entrypoints() -> None:
    readme = read(ROOT / "README.md")
    runbook = read(ROOT / "docs" / "WEEKLY_AUTOMATION_RUNBOOK.md")
    command = "pwsh -NoProfile -File ./tools/run-episode-pipeline.ps1 -Episode 001-pilot"
    require(command in readme, "README lacks cross-platform pipeline command")
    require(command in runbook, "weekly runbook lacks cross-platform pipeline command")


def test_docs_do_not_reintroduce_rehearsal_gate() -> None:
    checked = [
        ROOT / "README.md",
        ROOT / "docs" / "CODEBASE_IMPROVEMENT_PLAN.md",
        ROOT / "docs" / "WEEKLY_AUTOMATION_RUNBOOK.md",
        ROOT / "tools" / "README.md",
    ]
    for path in checked:
        text = read(path).lower()
        require("rehearsal" not in text and "rehearse" not in text, f"{path} reintroduced rehearsal-gate bloat")


def test_docs_show_reaction_ingest_entrypoint() -> None:
    readme = read(ROOT / "README.md")
    runbook = read(ROOT / "docs" / "WEEKLY_AUTOMATION_RUNBOOK.md")
    tools_readme = read(ROOT / "tools" / "README.md")
    command = "python3 tools/prepare-reaction-episode.py"
    for label, text in [("README", readme), ("runbook", runbook), ("tools README", tools_readme)]:
        require(command in text, f"{label} lacks reaction ingest command")
    require("~/university/tools/ingest.sh" in readme, "README does not name the existing ingest pipeline")


if __name__ == "__main__":
    test_module_exports()
    test_migrated_scripts_import_module_and_drop_duplicates()
    test_cross_platform_seams_are_preserved()
    test_docs_show_pwsh_entrypoints()
    test_docs_do_not_reintroduce_rehearsal_gate()
    test_docs_show_reaction_ingest_entrypoint()
    print("tools foundation checks passed")
