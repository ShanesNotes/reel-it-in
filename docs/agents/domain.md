# Domain Docs

This repo uses a single domain context.

## Before exploring, read these

- `CONTEXT.md` at the repo root.
- `docs/adr/` if it exists.
- `docs/DECISIONS.md` for project decisions not yet captured in an ADR.
- The source-of-truth docs listed in `AGENTS.md`.

If an ADR directory does not exist, proceed silently. Create ADRs only when a decision is hard to reverse, surprising without context, and the result of a real trade-off.

## File structure

```text
/
├── CONTEXT.md
├── docs/
│   ├── DECISIONS.md
│   └── adr/            # durable architecture decisions
├── app/
├── episodes/
└── tools/
```

## Use the glossary's vocabulary

When output names a domain concept, use the term as defined in `CONTEXT.md`. Do not drift to avoided synonyms.

If the concept is missing from the glossary, either reconsider the wording or update `CONTEXT.md` and note the change in `docs/DECISIONS.md` when it affects how agents should work.

## Flag decision conflicts

If output contradicts an existing ADR or `docs/DECISIONS.md`, surface it explicitly rather than silently overriding it.
