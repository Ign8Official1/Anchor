/** Local hero footage — place files in public/videos/ */

export const SURFACE_VIDEO_SOURCES = [
  "/videos/surface.mp4",
];

export const UNDERWATER_VIDEO_SOURCES = [
  "/videos/underwater.mp4",
];

export function loadVideoFromSources(video, sources) {
  if (!video) return Promise.resolve(false);

  return new Promise((resolve) => {
    let index = 0;

    const tryNext = () => {
      if (index >= sources.length) {
        resolve(false);
        return;
      }

      const src = sources[index++];
      const onReady = () => {
        cleanup();
        resolve(true);
      };
      const onError = () => {
        cleanup();
        tryNext();
      };
      const cleanup = () => {
        video.removeEventListener("loadeddata", onReady);
        video.removeEventListener("error", onError);
      };

      video.addEventListener("loadeddata", onReady, { once: true });
      video.addEventListener("error", onError, { once: true });
      video.src = src;
      video.load();
    };

    tryNext();
  });
}
