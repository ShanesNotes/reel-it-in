# Reel It In — Show UI Kit

A high-fidelity, mostly-cosmetic recreation of the **Reel It In** show document — the single product of the brand. It demonstrates both modes the host actually uses:

1. **Draft / Working-Draft view** — the editorial single-page episode document (header, four acts, news cards, conversation sparks, archive).
2. **Live / "On Air" mode** — toggle the button (bottom-right) or press **L**. The whole document flips to the warm-black teleprompter theme, chrome collapses, an on-air clock starts, and sparks become clickable.
3. **Focus deck** — in live mode, click any spark (or press ←/→) to open the full-screen prompt deck: arrow between sparks, **Mark covered**, throw a **Wildcard**, resize the prompt (A− / A+). Esc closes.

> This recreates the existing template — it does not invent new UI. Behavior is faithful but simplified (no file duplication, fullscreen, or persistence).

## Files
| File | Purpose |
|---|---|
| `index.html` | Show document entry point (draft + on-air teleprompter + focus deck). |
| `dashboard.html` | **Operator control dashboard** (Phase 2) — the single-operator "control room" run during a recording. |
| `kit.css` | Show-document styles, lifted from the source template. Pairs with `../../colors_and_type.css`. |
| `dashboard.css` | Control-dashboard styles (dark on-air theme, rundown spine + NOW panel + clocks). |
| `data.jsx` | **Shared episode data** (`window.RII_SPARKS / RII_EPISODE / RII_ARCHIVE`) — single source of truth for both the document and the dashboard. Includes the per-act `rundown` time budgets. |
| `components.jsx` | Document building blocks: `Status`, `LiveToggle`, `Kicker`, `ShowTitle`, `Deck`, `Epigraph`, `Meta`, `ActHead`, `Lede`, `NewsCard`, `NewsBlank`, `Spark`, `ArcRow`, `Footer`. |
| `focus-deck.jsx` | `FocusDeck` — the on-air full-screen spark overlay. |
| `show-app.jsx` | The show-document `App` (consumes `data.jsx`). |
| `control-room.jsx` | The dashboard `App` — recording state machine, master + segment clocks, rundown, NOW/next, coverage. |

## The operator control dashboard (`dashboard.html`)
The single-operator surface from `WORKFLOW.md`: **one host drives it on a second monitor while Dad is on a Zoom/call and never sees it.** Denser than the teleprompter — a persistent **rundown spine** (acts + sparks with time budgets, current highlighted, covered checked), a dominant **NOW panel** (big serif prompt + aside the operator reads/steers with), a **segment timer** that shifts *quietly* gold→red when over budget (never flashes), a **NEXT** strip, **coverage** progress, and a **recording state machine** (Standby → ● Rec → Wrapped). Keyboard-first:

| Key | Action |
|---|---|
| `Space` / `R` | Toggle recording (Rec ⇄ Wrapped) |
| `S` | Reset to Standby (clears clocks + coverage) |
| `←` / `→` | Previous / next spark |
| `C` | Mark current spark covered |
| `Enter` | Jump to next *uncovered* spark |

> Mostly-cosmetic recreation: clocks and state are real, but there's no actual recording, call, or persistence — it's a faithful UI, not production software.

## Using a component elsewhere
Components are exported to `window` (each file ends with `Object.assign(window, {...})`), so any later `text/babel` script can use them. Drop the same three CDN script tags from `index.html`, include `../../colors_and_type.css` + `kit.css`, then compose:

```jsx
<NewsCard source="Google I/O 2026" headline="…" why="…" url="#" />
<Spark id="oracle" index={0} tag="Myth & Machine" prompt="…" aside="…" live={false} onCover={()=>{}} onOpen={()=>{}} />
```

## Note on entrance animations
The `.rise` entrance animates **transform only** (opacity stays 1), and theme/overlay transitions are instant rather than cross-faded. This is deliberate: backgrounded/hidden browser tabs freeze CSS animation timelines on their start frame, which would otherwise leave content stuck invisible. Content is therefore always visible regardless of tab state. If you want the original opacity cross-fades back for a always-foreground context, re-add them in `kit.css` (`.rise`, `#focus.open` fadein, `.f-center` swap, body `transition`).
