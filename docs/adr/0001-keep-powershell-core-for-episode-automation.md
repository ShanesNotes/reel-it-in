# Keep PowerShell Core for episode automation

The Episode Pipeline stays PowerShell-first because the repo already has a complete PowerShell automation lane and the show needs weekly production reliability more than a language rewrite. Future work should make that lane run under PowerShell Core on Windows and Linux by adding a cross-platform execution seam, shared Tools Modules, and preflight verification instead of replacing the scripts with a new stack.

## Considered Options

- Rewrite the automation in JavaScript or another cross-platform language.
- Keep Windows-only `powershell.exe` assumptions.
- Keep PowerShell, but require `pwsh`/PowerShell Core compatibility and a clear execution adapter.

## Consequences

Codex can verify the same automation on this Linux machine once `pwsh` is available, while Shane can continue using the existing Windows-oriented workflow. Script refactors should preserve the PowerShell-first Interface unless real production use proves a rewrite is worth the cost.
