/**
 * Scroll-driven descent: ocean surface video → jellyfish underwater video.
 */
export class DepthController {
  constructor({ surfaceVideo, underwaterVideo, ensureUnderwaterLoaded }) {
    this.surfaceVideo = surfaceVideo;
    this.underwaterVideo = underwaterVideo;
    this.ensureUnderwaterLoaded = ensureUnderwaterLoaded;
    this.depth = 0;
    this.targetDepth = 0;
    this.underwaterActive = false;

    this.surfaceLayer = document.getElementById("surface-layer");
    this.underwaterLayer = document.getElementById("underwater-layer");
    this.depthLine = document.getElementById("depth-line");
    this.depthValue = document.getElementById("depth-value");
    this.surfaceLine = document.getElementById("surface-line");
    this.depthOverlay = document.getElementById("depth-overlay");
    this.underwaterMurk = document.querySelector(".underwater-murk");
  }

  setScrollProgress(progress) {
    const eased = Math.pow(clamp(progress, 0, 1), 0.82);
    this.targetDepth = eased;
  }

  update() {
    this.depth += (this.targetDepth - this.depth) * 0.08;
    const d = this.depth;

    document.documentElement.style.setProperty("--depth", String(d));

    const meters = Math.round(d * 52);
    if (this.depthValue) this.depthValue.textContent = `${meters} m`;
    if (this.depthLine) this.depthLine.style.transform = `scaleX(${d})`;

    if (this.surfaceLine) {
      const surfaceY = 48 - d * 62;
      this.surfaceLine.style.top = `${surfaceY}vh`;
      this.surfaceLine.style.opacity = String(1 - smoothstep(d, 0.55, 0.85));
    }

    if (this.depthOverlay) {
      this.depthOverlay.style.opacity = String(smoothstep(d, 0.05, 0.95) * 0.68);
    }

    const surfaceFade = 1 - smoothstep(d, 0.28, 0.5);
    if (this.surfaceLayer) this.surfaceLayer.style.opacity = String(surfaceFade);

    const underFade = smoothstep(d, 0.34, 0.56);
    if (this.underwaterLayer) this.underwaterLayer.style.opacity = String(underFade);

    const underScale = 1 + d * 0.08;
    if (this.underwaterVideo) {
      this.underwaterVideo.style.transform = `scale(${underScale})`;
      const brightness = 0.88 - d * 0.18;
      this.underwaterVideo.style.filter =
        `saturate(1.08) contrast(1.04) brightness(${brightness})`;
    }

    if (this.underwaterMurk) {
      this.underwaterMurk.style.opacity = String(0.28 + d * 0.42);
    }

    const shouldBeUnder = d > 0.4;
    if (shouldBeUnder && !this.underwaterActive) {
      this.underwaterActive = true;
      this.ensureUnderwaterLoaded?.().then(() => {
        this.underwaterVideo?.play().catch(() => {});
      });
      this.surfaceVideo?.pause();
    } else if (!shouldBeUnder && this.underwaterActive) {
      this.underwaterActive = false;
      this.underwaterVideo?.pause();
      this.surfaceVideo?.play().catch(() => {});
    }

    document.body.classList.toggle("is-underwater", shouldBeUnder);
    document.body.classList.toggle("is-descending", d > 0.08 && d < 0.55);
  }
}

function smoothstep(x, edge0, edge1) {
  const t = clamp((x - edge0) / (edge1 - edge0), 0, 1);
  return t * t * (3 - 2 * t);
}

function clamp(v, min, max) {
  return Math.max(min, Math.min(max, v));
}
