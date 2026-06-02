# Publishing

Publishing starts from the episode folder, not from memory.

The working package is `episodes/<episode>/publishing.md`.

Generate the edit plan first, then the first mechanical publishing pass from episode notes, live notes, sources, and transcript markers:

```powershell
.\tools\generate-edit-plan.ps1 -Episode <episode-folder>
.\tools\generate-title-thumbnail-package.ps1 -Episode <episode-folder>
.\tools\generate-publishing-package.ps1 -Episode <episode-folder> -Force
```

Then split that package into platform-specific upload assets:

```powershell
.\tools\export-marketing-assets.ps1 -Episode <episode-folder>
```

Generated files live under `episodes/<episode>/handoff/marketing/`:

- `youtube-upload.md`
- `youtube-description.txt`
- `rss-upload.md`
- `social-posts.md`
- `newsletter-blurb.md`
- `clip-candidates.csv`
- `distribution-checklist.md`
- `upload-fields.json`
- `title-options.md`
- `thumbnail-brief.md`
- `thumbnail-prompts.txt`
- `thumbnail-board.html`
- `generated-thumbnails.md`

## Default Direction

For the pilot, treat Reel It In as audio-first with video optional:

- publish the polished audio through one RSS host
- upload finished video natively to YouTube if a video edit exists
- use YouTube RSS ingestion only as a convenience for static-image audio episodes

## Host Options To Decide

- RSS.com: strong automation candidate because of automatic distribution workflow.
- Simplecast: strong paid candidate for distribution, analytics, and monetization.
- Buzzsprout: friendly creator workflow with audio/video hosting features.
- Spotify for Creators: zero-cost fallback, but other platform submissions may require more manual work.

## Per-Episode Deliverables

- final title
- short title
- description
- chapters
- source links
- transcript or transcript link
- title options
- thumbnail concepts and prompts
- generated thumbnail candidates when paid image generation is enabled
- YouTube title and description
- RSS metadata
- clip list
- social copy
- newsletter blurb
- distribution checklist

## Launch Checklist

- Final audio exported.
- Final video exported if used.
- Audio mastered or normalized.
- Source links checked.
- Transcript checked for obvious errors.
- Description includes the plain-English promise of the episode.
- YouTube upload checked before public release.
- RSS episode checked after publish.
- Apple, Spotify, and YouTube pages checked after release.
