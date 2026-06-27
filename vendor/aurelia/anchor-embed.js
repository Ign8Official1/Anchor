import * as THREE from "three/webgpu";
import App from "./src/app";

THREE.ColorManagement.enabled = true;

window.__ANCHOR_OCEAN__ = {
    sessionActive: false,
    setSessionActive(active) {
        this.sessionActive = !!active;
        window.__anchorApp?.setSessionActive(this.sessionActive);
    },
    setJellyfishReady() {
        hideVeil();
    },
    resize(width, height) {
        if (!window.__anchorRenderer || !window.__anchorApp) return;
        if (width < 2 || height < 2) return;
        window.__anchorRenderer.setSize(width, height);
        window.__anchorApp.resize(width, height);
    },
};

function hideVeil() {
    const veil = document.getElementById("veil");
    if (veil) veil.style.opacity = "0";
}

function showError(msg) {
    const error = document.getElementById("error");
    if (error) {
        error.style.visibility = "visible";
        error.innerText = msg;
    }
    hideVeil();
}

function viewportSize() {
    return {
        width: Math.max(document.documentElement.clientWidth, window.innerWidth),
        height: Math.max(document.documentElement.clientHeight, window.innerHeight),
    };
}

function debounce(fn, ms) {
    let timer = null;
    return (...args) => {
        clearTimeout(timer);
        timer = setTimeout(() => fn(...args), ms);
    };
}

function resizeScene(renderer, app) {
    const { width, height } = viewportSize();
    if (width < 2 || height < 2) return;
    renderer.setSize(width, height);
    app?.resize(width, height);
}

function createRenderer() {
    const renderer = new THREE.WebGPURenderer({ antialias: false });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5));
    const { width, height } = viewportSize();
    renderer.setSize(width, height);
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    renderer.domElement.style.position = "absolute";
    renderer.domElement.style.inset = "0";
    renderer.domElement.style.width = "100%";
    renderer.domElement.style.height = "100%";
    renderer.domElement.style.display = "block";
    return renderer;
}

async function run() {
    if (!navigator.gpu) {
        showError("WebGPU is not available on this Mac.");
        return;
    }

    const renderer = createRenderer();

    if (!renderer.backend.isWebGPUBackend) {
        showError("Could not initialize WebGPU.");
        return;
    }

    const container = document.getElementById("container");
    container.appendChild(renderer.domElement);

    const params = new URLSearchParams(window.location.search);
    const jellyfishCount = Number(params.get("jellyfish") || "6");

    const app = new App(renderer, {
        embed: true,
        jellyfishCount: Number.isFinite(jellyfishCount) ? jellyfishCount : 6,
        enableControls: false,
        embedRiseBase: 0.42,
        embedRiseSpeed: 1.55,
        embedSpawnBoostSeconds: 1.4,
        embedMotionSpeed: 0.52,
        embedSubdivisions: 20,
    });

    window.__anchorRenderer = renderer;

    let renderReady = false;
    let rendering = false;
    const clock = new THREE.Clock();

    const animate = () => {
        requestAnimationFrame(animate);
        if (!renderReady || !window.__anchorApp || rendering) return;

        const delta = Math.min(clock.getDelta(), 1 / 30);
        const elapsed = clock.getElapsedTime();
        rendering = true;
        window.__anchorApp.update(delta, elapsed).finally(() => {
            rendering = false;
        });
    };
    requestAnimationFrame(animate);

    await app.init(async () => {});
    window.__anchorApp = app;
    renderReady = true;
    app.setSessionActive(window.__ANCHOR_OCEAN__.sessionActive);

    resizeScene(renderer, app);
    await app.update(1 / 60, 0);
    hideVeil();

    const debouncedResize = debounce(() => resizeScene(renderer, app), 120);
    window.addEventListener("resize", debouncedResize);
    new ResizeObserver(debouncedResize).observe(document.body);
}

run().catch((err) => {
    console.error(err);
    showError(String(err?.message || err));
});
