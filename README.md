# Anchor

A small macOS app for blocking distracting apps and websites while you focus. Nothing fancy — just something I built because I kept opening Instagram when I said I wouldn't.

It's free. Always will be. Charging people money to help them focus feels wrong to me.

## What it does

- Block apps and websites during focus sessions
- A few protection levels if you want to make it harder to cheat on yourself
- Schedules, activity tracking, streaks
- Menu bar access so you can close the window and keep going
- Everything stays on your Mac — no account, no cloud

Site blocking works by redirecting blocked tabs to a local lock screen in the browser. App blocking puts a lock overlay on the window you're trying to open. You'll need to grant Accessibility and Automation permissions in System Settings for that to work.

## Download

**Easiest:** download [Anchor.dmg](https://github.com/Ign8Official1/Anchor/releases/latest/download/Anchor.dmg), open it, drag Anchor to Applications.

**One Terminal command** (downloads and installs for you):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Ign8Official1/Anchor/main/scripts/install.sh)"
```

If macOS blocks the first launch, right-click Anchor → Open. No App Store needed.

**Build from source** (Intel Macs or contributors):

```bash
git clone https://github.com/Ign8Official1/Anchor.git
cd Anchor
./build.sh
open dist/Anchor.app
```

Releases are built automatically when you push app changes to `main`. First time: **Actions → Release app → Run workflow**.

**Website:** https://ign8official1.github.io/Anchor/

## Build from source

If you already cloned the repo, you can rebuild without cloning again:

```bash
./build.sh
open dist/Anchor.app
```

Or with Xcode:

```bash
brew install xcodegen
xcodegen generate
open Anchor.xcodeproj
```

## GitHub Pages (website)

1. On GitHub: **Settings → Pages → Source → GitHub Actions**
2. Push to `main` — the deploy workflow publishes `website/` automatically
3. Site URL: https://ign8official1.github.io/Anchor/

## Permissions

Anchor needs:

- **Accessibility** — detect which app is in front
- **Automation (System Events)** — read browser tabs without launching browsers you aren't using
- **Automation (your browser)** — same thing, per browser (Safari, Chrome, Arc, etc.)

Check Settings → Permissions inside the app if something isn't working.

## Project layout

```
Anchor/           Swift app source
vendor/aurelia/   WebGPU jellyfish scene (bundled at build time)
website/          Landing page (separate from the app)
build.sh          Terminal build script
```

## Credits

The jellyfish scene uses [Aurelia](https://github.com/holtsetio/aurelia) by holtsetio (WebGPU / Three.js).

## License

MIT — use it, fork it, whatever helps you focus.
