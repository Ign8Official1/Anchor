# Anchor Website

Marketing site for Anchor — cinematic, [Active Theory](https://activetheory.net/)–inspired landing page with a live WebGL ocean.

## Stack

- **Vite** — dev server & build
- **Three.js** — open-source Water + Sky shaders (MIT)
- **GSAP ScrollTrigger** — scroll-driven depth & section reveals
- **Optional video** — Mixkit/Pexels royalty-free ocean footage layered under WebGL

## Run locally

```bash
cd website
npm install
npm run dev
```

Open http://localhost:5173

## Build for production

```bash
npm run build
npm run preview
```

Output: `website/dist/`

## Optional 4K video (local)

Bundled clips live in `public/videos/` (1080p large from Pixabay, free license).

Re-download:

```bash
chmod +x scripts/download-videos.sh
./scripts/download-videos.sh
```

The site also tries Pixabay CDN mirrors in the browser if local files are missing.

- Surface: ocean waves / above water
- Underwater: fish & blue depth — crossfades in as you scroll below the surface

## Deploy

Static hosting (Vercel, Netlify, GitHub Pages):

```bash
npm run build
# publish website/dist
```

## Credits

- Ocean shaders: Three.js examples (MIT)
- Fonts: Inter, Instrument Serif, IBM Plex Mono (Google Fonts)
- Optional stock video: Mixkit / Pexels (free licenses)
