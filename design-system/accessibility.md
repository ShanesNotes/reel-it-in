# Reel It In — Accessibility & Contrast Audit (Phase 1)

WCAG 2.1 contrast ratios for the key foreground-on-background pairings in both themes. Ratios computed from the hex tokens in `colors_and_type.css`. Thresholds: **AA normal** ≥ 4.5:1, **AA large** (≥24px, or ≥18.66px bold) ≥ 3:1, **AAA normal** ≥ 7:1.

> The dashboard is glanceable and high-stakes during a take, so legibility matters more than usual. Where a token is borderline, the fix is to *use the right token for the job*, not to repaint the brand.

## Paper / Draft theme (bg `#F2EBDB`)

| Foreground | Token | Ratio | Verdict |
|---|---|---|---|
| Ink `#221B12` | `--fg1` | **14.3:1** | ✅ AAA — primary text |
| Ink soft `#5C5142` | `--fg2` | **6.5:1** | ✅ AA (near-AAA) — secondary text |
| Ink faint `#8A7E6B` | `--fg3` | **3.4:1** | ⚠️ **fails AA normal** — meta/labels only |
| Gold `#AE7A2A` | `--accent` / `--gold-500` | **3.2:1** | ⚠️ large/display & accents only |
| Gold deep `#855B17` | `--accent-deep` / `--gold-700` | **5.0:1** | ✅ AA — links & small text |
| Teal `#1E4D49` | `--accent-2` | **8.0:1** | ✅ AAA — news source labels |

## On-Air / Live theme (bg `#16110A`)

| Foreground | Token | Ratio | Verdict |
|---|---|---|---|
| Night ink `#F0E7D2` | `--fg1` | **15.3:1** | ✅ AAA — primary text |
| Soft `#C5B594` | `--fg2` | **9.3:1** | ✅ AAA — secondary |
| Faint `#8A7C5F` | `--fg3` | **4.6:1** | ✅ AA — meta (more legible than paper's faint) |
| Gold `#E5A93F` | `--accent` | **9.0:1** | ✅ AAA — focus tag / accents |
| Teal `#5FA89F` | `--accent-2` | **6.8:1** | ✅ AA (near-AAA) — status |

## Findings & rules

1. **Two paper-theme tokens fail AA for normal body text** — and both are *already* restricted by the brand to roles where that's acceptable:
   - **`--fg3` ink-faint (3.4:1):** only ever used for small UPPERCASE mono meta (kickers, dates, source tags, archive tags). These are *labels, not reading text.* **Rule:** never set running/body copy in `--fg3` on paper. If a piece of faint text must be reliably read, use `--fg2` (6.5:1).
   - **`--accent` base gold (3.2:1):** used for the huge display title, roman numerals, and decorative accents — all **large text** (≥24px), where the 3:1 large threshold is met. **Rule:** for any small text or link, use `--accent-deep` / `--gold-700` (5.0:1), which the kit already does.

2. **The on-air theme is strong across the board** — every pairing clears AA, most clear AAA. Good, because the live dashboard is the high-stakes glanceable surface.

3. **Non-text contrast:** hairlines (`--line` at .16 alpha) are decorative dividers, exempt from the 3:1 UI-component rule. Focus rings use a solid `2px var(--accent)` outline with 3px offset — meets the focus-visibility expectation.

## Optional future tightening (not blocking)
- If you ever want paper-theme `--fg3` to clear AA for incidental small text, darken it to ~`#7A6E5A` (≈4.5:1) — a barely-perceptible shift. Left as-is for now to preserve the exact source palette.
- The new `--gold-*` / `--teal-*` ramps are for fills/washes/borders; if any ramp step is used behind text later, re-check the specific pairing.

_Method: relative luminance per WCAG (sRGB linearized), ratio = (L_lighter + 0.05) / (L_darker + 0.05). Re-run when tokens change._
