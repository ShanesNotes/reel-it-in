# Reel It In

> **Not all the AI news — just what matters, and why. In plain English.**

A weekly father–son conversation about artificial intelligence.

This repository contains the living, self-contained web template used to publish each episode.

---

## The Show

Two people sit down once a week:

- One who follows AI closely
- One who keeps the other honest

The goal is simple: cut through the hype, explain what actually happened, and answer the only question that matters — *so what?*

No jargon survives the table.

## Format

| Act | Name            | Purpose                                      |
|-----|-----------------|----------------------------------------------|
| I   | The Setup       | Who we are, what this is. Keep it short.     |
| II  | This Week       | 3–5 headlines + the human "why it matters"   |
| III | The Conversation| "Sparks" — potent prompts to pull like threads |
| IV  | The Archive     | Every previous episode, saved forever        |

## How to Publish a New Episode (The Weekly Ritual)

1. **Duplicate the file**
   ```bash
   cp reel-it-in.html reel-it-in-ep002.html
   ```

2. **Edit only the `EPISODE` block** (near the top of the `<script>`)
   - Update `number`, `label`, `date`, `hosts`
   - Replace the `news` array (source + headline + *why it matters*)
   - Pick featured sparks from `SPARK_LIBRARY` via `featuredSparks`

3. **Update the `ARCHIVE` array** with last week's episode

4. **(Recommended)** Move the previous week's file into `archive/`

The entire page is one HTML file. No build tools. No dependencies. Open it in any browser.

## Live Production Tools

During recording, press <kbd>L</kbd> (or click the button) to enter **Live Mode**:

- Dark "on air" theme
- Large readable focus view for each spark
- Keyboard-driven navigation (`←` `→`, `C` = mark covered, `W` = wildcard)
- Built-in timer
- Fullscreen support

Designed so two people can run the entire show from one laptop.

## Design Notes

- Warm paper aesthetic (light mode) with a rich dark theater mode for live
- Custom typography: Fraunces (serif) + Hanken Grotesk (sans) + JetBrains Mono
- Subtle paper grain texture
- Smooth animations that respect `prefers-reduced-motion`
- Fully responsive down to small phones
- 100% self-contained after fonts load from Google Fonts

## Philosophy

Keep it human.  
Every headline must earn its place by answering "why should a normal person care?"  
The sparks are doors, not lectures. One person explores; the other reels it back in.

---

**Template version:** 5 (as of the pilot)

Made with care by Shane & Dad · 2026

*If you're seeing this in the repo: the current `reel-it-in.html` is the working pilot (Episode 001).*
