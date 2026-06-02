# Fonts

All three families are **free Google Fonts** — no proprietary files, no substitutions were necessary. They are loaded via CDN at the top of `colors_and_type.css`:

```
https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght@0,9..144,400;0,9..144,500;0,9..144,600;1,9..144,400;1,9..144,500&family=Hanken+Grotesk:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap
```

| Family | Role | Notes |
|---|---|---|
| **Fraunces** | Display, titles, ledes, roman numerals, drop-cap | Variable serif. Uses the **opsz** (optical size, 9–144) axis — set to 144 on large display — and the playful **WONK** axis (set to 1 on the gold italic "It"). Weights 400/500/600, roman + italic. |
| **Hanken Grotesk** | Body copy, UI, news headlines | Weights 400/500/600/700. Friendly humanist grotesque. |
| **JetBrains Mono** | Kickers, labels, meta, buttons, code | Weights 400/500. Always uppercase with wide letter-spacing. |

To self-host instead of CDN, download the `.woff2` files from Google Fonts, drop them in this folder, and replace the `@import` with `@font-face` rules.
