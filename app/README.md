# App

This folder contains the current usable show dashboard.

## Current File

- `reel-it-in.html`: self-contained pilot dashboard for prep and live recording.

Open it directly in a browser. No build step is required.

## Current Intent

The dashboard is both:

- an editorial show document for the week
- a live operator surface during recording

It should remain easy to duplicate, email, open, and test while the show is still prototyping.

## Metadata

`reel-it-in.html` carries template metadata in `<head>`:

- `reel-it-in-template`: `pilot-dashboard`
- `reel-it-in-version`: current template version (now `5.1`)
- `reel-it-in-updated`: last template housekeeping date

The footer mirrors version/date for quick operator checks.

## Asset References

Last audited: 2026-06-11.

- External: Google Fonts CDN only (`fonts.googleapis.com`, `fonts.gstatic.com`)
- Local: none required; grain texture is inline SVG data
- Episode data: edit the `EPISODE` block or run `tools/export-dashboard-data.ps1 -UpdateDashboard`

## Browser Test Checklist

Run after meaningful dashboard changes:

1. Open `app/reel-it-in.html` directly in a desktop browser.
2. Confirm episode header, three news cards, and sparks render.
3. Confirm optional `On X:` lines appear under news cards in prep mode.
4. Click **Live** (or press `L`): page darkens, timer starts, Act III scrolls into view.
5. In Live Mode, confirm news `why`, `On X`, and read links hide; headlines stay readable.
6. Click a spark card: focus deck opens; test `←` / `→`, `C` (cover), `W` (wildcard), `Esc` (close).
7. Press `F` for fullscreen toggle; confirm no console errors.
8. Resize to mobile width (~390px): status pill, live toggle, and cards remain usable.

## When Editing

- Preserve Live Mode unless intentionally changing it.
- Keep the episode data easy to find.
- Use real sources for news examples.
- Run the browser checklist after interaction or layout changes.
