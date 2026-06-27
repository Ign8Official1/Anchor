# Anchor Website

Marketing site for Anchor. Deploys to GitHub Pages on every push to `main`.

**Live site:** https://ign8official1.github.io/Anchor/

## Run locally

```bash
cd website
npm install
npm run dev
```

Open http://localhost:5173

## Build

```bash
npm run build
npm run preview
```

Output goes to `website/dist/`.

## GitHub Pages

One-time setup in the repo on GitHub:

1. **Settings → Pages**
2. Under **Build and deployment**, set **Source** to **GitHub Actions**
3. Push to `main` — the `Deploy website` workflow publishes automatically

Live URL: https://ign8official1.github.io/Anchor/

## App downloads (GitHub Releases)

The macOS app zip is **not** hosted on Pages — it comes from GitHub Releases.

After pushing the release workflow, users download from:

```
https://github.com/Ign8Official1/Anchor/releases/latest/download/Anchor-macOS.zip
```

First time: **Actions → Release app → Run workflow** to create the first release.

Each push to `main` that changes app code rebuilds and updates the zip for the version in `Anchor/Info.plist` (currently v0.3.0).

```bash
cd website
GITHUB_PAGES=true npm run build
# upload dist/ to any static host
```

`GITHUB_PAGES=true` sets the Vite base path to `/Anchor/` so assets load correctly on GitHub Pages.

## Credits

- Ocean shaders: Three.js examples (MIT)
- Fonts: Inter, Instrument Serif, IBM Plex Mono (Google Fonts)
