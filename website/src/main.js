import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { DepthController } from "./depthController.js";
import {
  SURFACE_VIDEO_SOURCES,
  UNDERWATER_VIDEO_SOURCES,
  loadVideoFromSources,
} from "./videoSources.js";
import "./styles.css";

gsap.registerPlugin(ScrollTrigger);

async function initVideos() {
  const surfaceVideo = document.getElementById("surface-video");
  const underwaterVideo = document.getElementById("underwater-video");

  const [surfaceOk, underwaterOk] = await Promise.all([
    loadVideoFromSources(surfaceVideo, SURFACE_VIDEO_SOURCES),
    loadVideoFromSources(underwaterVideo, UNDERWATER_VIDEO_SOURCES),
  ]);

  if (surfaceOk) {
    document.body.classList.add("has-surface-video");
    surfaceVideo.loop = true;
    surfaceVideo.muted = true;
    await surfaceVideo.play().catch(() => {});
  }

  if (underwaterOk) {
    document.body.classList.add("has-underwater-video");
    underwaterVideo.loop = true;
    underwaterVideo.muted = true;
  }

  let underwaterLoaded = underwaterOk;
  const ensureUnderwaterLoaded = async () => {
    if (underwaterLoaded || !underwaterVideo) return underwaterVideo;
    underwaterLoaded = await loadVideoFromSources(underwaterVideo, UNDERWATER_VIDEO_SOURCES);
    if (underwaterLoaded) {
      document.body.classList.add("has-underwater-video");
      underwaterVideo.loop = true;
      underwaterVideo.muted = true;
    }
    return underwaterVideo;
  };

  return { surfaceVideo, underwaterVideo, ensureUnderwaterLoaded };
}

function initLoader() {
  const loader = document.getElementById("loader");
  const bar = loader?.querySelector(".loader-bar span");

  return new Promise((resolve) => {
    gsap.timeline({
      onComplete: () => {
        gsap.to(loader, {
          opacity: 0,
          duration: 0.6,
          onComplete: () => {
            loader?.remove();
            resolve();
          },
        });
      },
    }).to(bar, { scaleX: 1, duration: 1.1, ease: "power2.inOut" });
  });
}

function initScroll(depthController) {
  gsap.utils.toArray(".panel").forEach((panel, i) => {
    if (i === 0) return;
    gsap.from(panel, {
      opacity: 0,
      y: 40,
      duration: 0.9,
      ease: "power2.out",
      scrollTrigger: {
        trigger: panel,
        start: "top 80%",
        toggleActions: "play none none reverse",
      },
    });
  });

  gsap.from(".hero .line", {
    yPercent: 110,
    opacity: 0,
    duration: 1,
    stagger: 0.1,
    ease: "power3.out",
    delay: 0.1,
  });

  ScrollTrigger.create({
    trigger: document.body,
    start: "top top",
    end: "bottom bottom",
    scrub: 0.35,
    onUpdate: (self) => depthController.setScrollProgress(self.progress),
  });

  const nav = document.querySelector(".nav");
  ScrollTrigger.create({
    start: 80,
    onUpdate: (self) => nav?.classList.toggle("nav-solid", self.scroll() > 80),
  });
}

async function boot() {
  const { surfaceVideo, underwaterVideo, ensureUnderwaterLoaded } = await initVideos();

  const depthController = new DepthController({
    surfaceVideo,
    underwaterVideo,
    ensureUnderwaterLoaded,
  });

  const loaderDone = initLoader();
  initScroll(depthController);
  await loaderDone;

  let ticking = true;
  const loop = () => {
    if (ticking) depthController.update();
    requestAnimationFrame(loop);
  };
  loop();

  document.addEventListener("visibilitychange", () => {
    ticking = !document.hidden;
    if (document.hidden) {
      surfaceVideo?.pause();
      underwaterVideo?.pause();
    } else if (!depthController.underwaterActive) {
      surfaceVideo?.play().catch(() => {});
    }
  });

  document.getElementById("download-link")?.addEventListener("click", (e) => {
    const cmd = "./build.sh && open dist/Anchor.app";
    navigator.clipboard?.writeText(cmd);
    const link = e.currentTarget;
    if (link instanceof HTMLAnchorElement) {
      const original = link.textContent;
      link.textContent = "Copied build command";
      setTimeout(() => {
        link.textContent = original;
      }, 1800);
    }
  });
}

boot().catch(console.error);
