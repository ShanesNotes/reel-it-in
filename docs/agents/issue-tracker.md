# Issue tracker: GitHub

Issues and PRDs for this repo live as GitHub issues in `ShanesNotes/reel-it-in`. Use the `gh` CLI for issue operations when publishing or updating tracked work.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`.
- **Read an issue**: `gh issue view <number> --comments`.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments`.
- **Comment on an issue**: `gh issue comment <number> --body "..."`.
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`.
- **Close**: `gh issue close <number> --comment "..."`.

Infer the repo from `git remote -v` when possible.

## When a skill says "publish to the issue tracker"

Create a GitHub issue unless the current task explicitly asks for local-only planning.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`.
