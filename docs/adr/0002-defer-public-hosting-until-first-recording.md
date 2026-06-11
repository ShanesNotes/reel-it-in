# ADR 0002: Defer Public Hosting Until After First Recording

Date: 2026-06-11

## Status

Accepted

## Context

Reel It In needs three different surfaces:

- an operator dashboard for Shane during prep and recording
- lightweight Dad-facing handoffs (brief + link)
- eventual public publishing (RSS, YouTube, optional web archive)

Phase 7 roadmap work listed RSS host choice, dashboard hosting target, and public-site boundaries before the first real episode was recorded.

## Decision

Keep the operator dashboard local and self-contained (`app/reel-it-in.html`) until at least one episode is recorded and published.

Defer choosing:

- RSS host (RSS.com, Simplecast, Buzzsprout, Spotify for Creators, or other)
- public hosting target for dashboard/archive views
- public marketing site scope

Continue using:

- GitHub as the production brain for text, metadata, and automation
- an external Production Vault for media
- generated publishing packets under each Episode Folder

## Consequences

- No hosting bill or platform migration before production pain is known.
- Dad still gets briefs and links, not repo access.
- Agents should not build a public site unless Shane explicitly asks after the first recording.
- When hosting becomes real, add a follow-up ADR naming the chosen RSS host and dashboard boundary.