# Recording

This folder documents the practical recording setup for Reel It In.

## Default Stack

- Riverside: primary recording room
- OBS: local safety recording or screen/dashboard capture
- `app/reel-it-in.html`: Shane's operator dashboard
- `episodes/<episode>/production-notes.md`: live edit notes
- `Reel It In Media/<episode>/raw/`: raw media storage outside git

## Services To Run During An Episode

1. Run `tools/start-recording-session.ps1 -Episode <episode>`.
2. Open or confirm the Riverside studio.
3. Start OBS only when a backup mix, screen recording, or video layout is needed.
4. Keep the episode notes file available for quick timecoded notes.

The launcher creates:

- `episodes/<episode>/handoff/session-launch.md`
- `Reel It In Media/<episode>/raw/`
- `Reel It In Media/<episode>/exports/`
- `Reel It In Media/<episode>/clips/`
- `Reel It In Media/<episode>/thumbnails/`
- `Reel It In Media/<episode>/transcripts/`

## Riverside Setup

- Use headphones for all participants.
- Capture separate host tracks whenever possible.
- For in-person recording, assign separate microphone inputs or channels.
- For hybrid recording, add remote guests through the Riverside invite link.
- Confirm uploads finish before closing the session.

## OBS Safety Setup

OBS is not the primary recorder. It is a backup.

Good OBS uses:

- safety audio/video mix
- screen capture of the dashboard
- local backup when testing a new recording setup
- live layout preview if the show becomes video-first

## Minimum Preflight

- Mic check for Shane
- Mic check for Dad
- Headphones on
- Riverside recording test
- OBS test if used
- Sync marker
- Dashboard Live Mode ready

## After Recording

- Download or link Riverside raw tracks.
- Put raw media in the cloud media folder, not git.
- Update `production-notes.md`.
- Move into Descript for edit.
- Use Auphonic only after the edit is locked.
