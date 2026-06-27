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

## Build

Needs macOS 13+ and Node (for the ocean visuals).

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

After rebuilding, quit the old app (Cmd+Q) before opening the new one. Permissions may need to be re-granted after each build since it's ad-hoc signed.

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
