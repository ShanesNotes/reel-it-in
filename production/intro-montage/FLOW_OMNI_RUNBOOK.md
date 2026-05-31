# Flow / Gemini Omni Runbook

Research snapshot: 2026-05-31

This runbook translates the Golden Thread montage handoff into a practical Google Flow workflow using Gemini Omni Flash, Veo 3.1, Flow Agent, and Flow tools.

## What Matters About Flow Now

Google Flow is no longer just a video prompt box. Google now positions it as an AI creative studio with planning, generation, editing, asset tools, and music workflows.

Relevant capabilities:

- Gemini Omni Flash can create and edit video from mixed inputs such as text, image, audio, and video.
- Omni supports conversational video editing, so each revision can build on the previous scene.
- Flow Agent can help plan, generate variations, and reason through a project.
- Flow supports start/end frames, ingredients/references, and model selection.
- Omni Flash supports 10-second video clips, video-to-video editing, advanced references, and custom voices.
- Flow tools include Storyboard Studio, Type Overlays, Video Resizer, Shader Effects, and pixelBento-style post-processing.

Sources:

- Google Flow updates: https://blog.google/innovation-and-ai/models-and-research/google-labs/flow-updates/
- Gemini Omni announcement: https://blog.google/innovation-and-ai/models-and-research/gemini-models/gemini-omni/
- Flow product page: https://labs.google/fx/tools/flow
- Flow help: https://support.google.com/flow/answer/16353334
- Flow model support: https://support.google.com/flow/answer/16352836

## Production Strategy

Do not ask Flow for the whole intro in one shot first.

Use this sequence:

1. Create the visual grammar.
2. Generate or upload image references.
3. Build five 6-10 second scene clips.
4. Use Omni conversational edits to preserve thread continuity and improve weak motion.
5. Cut the clips down to roughly 18-22 seconds total.
6. Add final wordmark/title treatment outside the generated video, or with Type Overlays only after picture lock.

The generated shots should have no text, no logos, no captions, and no watermark-like invented marks.

## Project Setup In Flow

Create a new Flow project:

```text
Reel It In - The Golden Thread
```

Upload these as references:

- `production/intro-montage/assets/style-board.png`
- `production/intro-montage/assets/wordmark-night.png`

Use the style board as the visual reference. Do not use the wordmark as a generated-video ingredient unless the goal is the final title/resolve frame.

Recommended project collections:

- `00_style_refs`
- `01_creation`
- `02_babel`
- `03_flood`
- `04_leviathan`
- `05_resolve`
- `99_selects`

## Model Choice

Use Gemini Omni Flash when:

- refining an uploaded/generated clip through conversation
- preserving continuity between iterations
- combining image/video/text references
- editing motion, camera angle, lighting, or specific details
- generating 10-second clips

Use Veo 3.1 Quality when:

- a shot needs maximum cinematic realism and prompt adherence
- native ambience/audio is useful
- the shot can be created cleanly from text or frames

Use Flow Agent when:

- asking for variations
- planning the sequence
- organizing scenes
- generating multiple alternate takes

## Global Style Prompt

Paste this into every shot prompt or store it as a reusable style reference:

```text
Ancient-futuristic sacred montage. Illuminated manuscript fused with archaic technology: gold leaf and circuitry, clay and code, bronze and light. Patinated, archaeological, reverent, touched by the divine but grounded and cinematic. Deep chiaroscuro, warm darkness, single shafts of volumetric gold light. Palette: warm near-black, papyrus cream, antique gold, luminous gold, one subtle verdigris teal accent. Heavy 16mm film grain, soft halation on highlights, gentle gate weave. A single unbroken luminous golden thread is the connective motif. Slow deliberate camera, shallow depth of field, 16:9, cinematic, no on-screen text.
```

Negative prompt where supported:

```text
No on-screen text, no lettering, no captions, no logos, no watermark, no modern clothing, no contemporary city, no glossy sci-fi, no chrome, no neon cyberpunk, no cartoon, no anime, no fast cuts, no stock lens flares, no rainbow palette, no busy clutter, no flat lighting.
```

## Shot Build Plan

### Shot 1: Creation

Goal: establish the golden thread as the show's visual thesis.

Prompt:

```text
[GLOBAL STYLE] In total darkness, a single point of gold light ignites. A luminous golden thread unspools outward into the void. As it travels, it fractures the dark into a fine geometric lattice, like the first pattern, a proto-circuit, the first algorithm. Below it, mirror-black primordial water glints faintly. Gold dust drifts like forming stars. Slow push-in toward the igniting spark. Reverent, quiet, cinematic. No text.
```

Flow notes:

- Generate 4 variations.
- Pick the one where the thread reads clearly from the first second.
- Ask Omni to remove any text-like glyphs if they appear.

Omni edit prompts:

```text
Make the golden thread more continuous and physically present across the full clip. Reduce any busy particles. Keep the camera slow and reverent.
```

```text
Make the water below more mirror-black and subtle. Keep the thread luminous gold, not neon.
```

### Shot 2: Babel

Goal: language, ambition, complexity, fragmentation.

Prompt:

```text
[GLOBAL STYLE] The golden thread climbs and weaves a great ziggurat under construction. The tower is both an ancient stepped temple, a stack of glowing inscribed clay tablets, and a vertical lattice of archaic server-racks. Faint glyph-like marks swirl as abstract embers, not readable text. Hands of light set each course. Slow tilt up the tower. Near the summit, the structure shudders and begins to fracture, scattering gold embers into the dark. No readable text.
```

Flow notes:

- Watch for invented legible text. Reject or edit out.
- The ziggurat should feel ancient first, technological second.

Omni edit prompts:

```text
Remove any readable letters or symbols. Make all glyphs abstract ember-like marks. Keep the tower ancient, clay, bronze, and sacred, with subtle server-lattice hints.
```

```text
Make the golden thread visibly climb through the tower and remain the same thread from the previous shot.
```

### Shot 3: Flood

Goal: reset, chaos, continuity.

Prompt:

```text
[GLOBAL STYLE] The fracturing tower dissolves into a vast sea of liquid gold-black light. The world is flooded, ancient and endless. The single golden thread survives, drawn taut across the black water and trailing to the horizon. A small vessel of warm light drifts far away. Fine gold rain falls. Slow aerial drift low over the water, following the taut thread. No text.
```

Flow notes:

- Use this as a pacing shot.
- It should be quieter than Babel.
- The thread must be the clearest compositional line.

Omni edit prompts:

```text
Simplify the frame. Make the black water broader and calmer. The golden thread should form the main visual line across the surface.
```

```text
Make the vessel very small and distant, more symbolic than literal. Keep the shot slow.
```

### Shot 4: Jonah And The Leviathan

Goal: the catch. This is the show's title idea becoming motion.

Prompt:

```text
[GLOBAL STYLE] Beneath black water, an immense leviathan rises in the deep. It is mechanical-organic, made of patinated bronze plates with inner gold light. Its scales resemble ancient inscribed circuit-tablets, but no readable text. The golden thread descends into the leviathan's depths where a small human silhouette is held. Suddenly the thread snaps taut and reels upward, drawing the figure through shafts of light toward the surface. Slow upward camera following the reeling thread. No text.
```

Flow notes:

- This is the highest-risk shot.
- Reject anything that becomes cartoon monster, horror, or fantasy battle.
- The leviathan should feel solemn and symbolic.

Omni edit prompts:

```text
Make the leviathan more ancient-bronze and less monster-like. Keep it solemn, enormous, and partially obscured by black water.
```

```text
Make the thread visibly reel upward and pull the small human silhouette toward the light. The movement should be graceful, not action-movie fast.
```

### Shot 5: Resolve

Goal: calm title landing. Leave room for the wordmark.

Prompt:

```text
[GLOBAL STYLE] The taut golden thread breaks the surface and snaps perfectly horizontal, becoming a single luminous gold waterline across a warm-black frame. The water stills to glass. Wide calm negative space above the line for a title to appear later. Hold nearly still, with only film grain, faint shimmer, and subtle water motion. Quiet, resolved, expectant. No text.
```

Flow notes:

- This shot must be calm enough for the title.
- If Flow invents a title, reject or edit it out.
- Consider using start/end frames if we generate a clean still first.

Omni edit prompts:

```text
Remove all text and symbols. Keep only the horizontal golden waterline and warm-black negative space above it.
```

```text
Make the frame calmer and more symmetrical. The line should feel like the final thread resolving into a title baseline.
```

## Assembly Timing

Target runtime: 18-22 seconds.

Suggested edit:

| Time | Picture |
| --- | --- |
| 0.0-3.5s | Creation: thread ignites |
| 3.5-7.0s | Babel: tower climbs/fractures |
| 7.0-10.5s | Flood: thread survives |
| 10.5-14.0s | Leviathan: reel upward |
| 14.0-18.5s | Resolve: horizontal thread |
| 18.5-21.0s | Wordmark/title settles |

Keep transitions slow and minimal. Cross-dissolve where the golden thread can visually bridge clips.

## Music Workflow

Use the existing music prompt in `prompts.txt` as the main generation prompt.

If using Flow Music:

1. Generate a 20-22 second cue first.
2. Favor cello, low drone, frame-drum heartbeat, distant choir pad, bronze textures.
3. Avoid lyrics, EDM drops, drum kit, or trailer percussion.
4. Use Omni/Flow Music to shape the video to the cue's pacing if available.

Picture-lock cue points:

- 0.0s: low cello / ignition
- 4.0s: second wave / Babel
- 8.0s: third wave / Flood
- 11.0s: crescendo / Leviathan
- 12.5s: hard silence
- 13.0s: mechanical reel hit
- 14.0s: resolve
- 17.0s+: wordmark breathes

## Quality Bar

A clip is usable only if:

- the golden thread is legible
- the palette matches the style board
- no readable invented text appears
- the movement is slow and deliberate
- the shot feels ancient first and technological second
- the frame has enough contrast for compression
- it avoids glossy AI-video tells: plastic surfaces, mushy faces, oversharp details, neon glow

## Review Notes Template

Use this after each generation:

```text
Shot:
Model:
Prompt version:
Keep / reject / iterate:
What works:
What fails:
Omni edit to try:
Export name:
```

## First Test Session

Run only Shot 1 and Shot 5 first.

Reason: those two shots define the whole identity. If Flow cannot produce the thread ignition and resolve frame in the correct style, the middle shots will drift.

After those land, build Shot 3. Then Babel. Then Leviathan last.

## Codex + Human Collaboration Loop

Codex can:

- refine prompts
- compare outputs against the style rules
- rename and organize exports
- write edit notes
- build storyboards and shot lists
- update this runbook

Human/browser side likely needed:

- logging into Google Flow
- generating clips
- downloading renders
- choosing subjective favorites

If browser control is available in a future session, Codex can also help drive the UI directly. In this session, the browser-control runtime is not exposed, so the strongest workflow is guided co-piloting.
