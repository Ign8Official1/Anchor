import * as THREE from "three/webgpu";
import {pass, mrt, output, float, vec4, Fn, clamp, vec3} from "three/tsl";
import { OrbitControls } from "three/addons/controls/OrbitControls";
import { bloom } from 'three/addons/tsl/display/BloomNode.js';

import { Lights } from "./lights";
import { conf } from "./conf";
import { Info } from "./info";
import { VerletPhysics } from "./physics/verletPhysics";
import { VertexVisualizer } from "./physics/vertexVisualizer";
import {SpringVisualizer} from "./physics/springVisualizer";
import {Medusa} from "./medusa";
import {MedusaVerletBridge} from "./medusaVerletBridge";
import {Background} from "./background";
import {Plankton} from "./plankton";
import {Godrays} from "./godrays";

class App {
    renderer = null;

    camera = null;

    scene = null;

    controls = null;

    lights = null;

    stats = null;

    physics = null;

    vertexVisualizer = null;

    springVisualizer = null;

    frameNum = 0;

    options = {
        jellyfishCount: 10,
        embed: false,
        enableControls: true,
        embedRiseBase: 0.42,
        embedRiseSpeed: 1.55,
        embedSpawnBoostSeconds: 1.4,
        embedMotionSpeed: 0.52,
        embedSubdivisions: 20,
    };

    constructor(renderer, options = {}){
        console.time("firstFrame");
        this.renderer = renderer;
        this.options = { ...this.options, ...options };
    }

    async init(progressCallback) {
        conf.init({
            embed: this.options.embed,
            embedJellyfishCount: this.options.jellyfishCount,
            embedRiseBase: this.options.embedRiseBase,
            embedRiseSpeed: this.options.embedRiseSpeed,
            embedSpawnBoostSeconds: this.options.embedSpawnBoostSeconds,
            embedMotionSpeed: this.options.embedMotionSpeed,
            embedSubdivisions: this.options.embedSubdivisions,
        });
        if (!this.options.embed) {
            this.info = new Info();
        }
        await this.renderer.init();
        this.camera = new THREE.PerspectiveCamera(65, window.innerWidth / window.innerHeight, 0.01, 30);
        if (this.options.embed) {
            this.camera.position.set(0, -0.4, 19);
        } else {
            this.camera.position.set(0, 0, 15);
        }
        this.camera.lookAt(0, 0, 0);
        this.camera.updateProjectionMatrix();

        this.scene = new THREE.Scene();
        this.scene.background = new THREE.Color(0x000000);

        this.controls = new OrbitControls(this.camera, this.renderer.domElement);
        this.controls.enableDamping = true;
        this.controls.minPolarAngle = Math.PI * 0.25;
        this.controls.maxPolarAngle = Math.PI * 0.75;
        this.controls.minDistance = 8;
        this.controls.maxDistance = 25;
        this.controls.enablePan = false;

        if (this.options.embed) {
            this.controls.enableRotate = false;
            this.controls.enableZoom = false;
            this.controls.autoRotate = true;
            this.controls.autoRotateSpeed = 0.035;
        } else if (!this.options.enableControls) {
            this.controls.enabled = false;
        }

        await progressCallback(0.1);

        this.physics = new VerletPhysics(this.renderer);

        await progressCallback(0.3);

        this.lights = new Lights();
        this.scene.add(this.lights.object);

        this.background = new Background(this.renderer);
        this.scene.environmentNode = Background.envFunction;
        this.scene.environmentIntensity = 0.3;
        this.scene.backgroundNode = Background.fogFunction;

        this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
        this.renderer.toneMappingExposure = this.options.embed ? 0.82 : 1.0;

        await progressCallback(0.4);

        await Medusa.initStatic(this.physics);

        await progressCallback(0.5);

        this.bridge = new MedusaVerletBridge(this.physics);

        const jellyfishCount = this.options.jellyfishCount ?? 10;
        if (this.options.embed) {
            Medusa.prepareEmbedEntryOrder(jellyfishCount);
        }
        for (let i = 0; i < jellyfishCount; i++) {
            const medusa = new Medusa(this.renderer, this.physics, this.bridge);
            this.scene.add(medusa.object);
            this.physics.addObject(medusa);
        }
        this.physics.addObject(this.bridge);

        await progressCallback(0.6);

        await this.physics.bake();

        await progressCallback(0.7);

        if (!this.options.embed) {
            this.vertexVisualizer = new VertexVisualizer(this.physics);
            //this.scene.add(this.vertexVisualizer.object);
            this.springVisualizer = new SpringVisualizer(this.physics);
            this.scene.add(this.springVisualizer.object);
        }

        await progressCallback(0.8);

        if (!this.options.embed) {
            this.plankton = new Plankton();
            this.scene.add(this.plankton.object);

            await progressCallback(0.9);
            this.godrays = new Godrays(this.bridge);
            this.scene.add(this.godrays.object);
        }

        await progressCallback(0.9);

        const scenePass = pass(this.scene, this.camera);
        scenePass.setMRT( mrt( {
            output,
            bloomIntensity: float( 0 ) // default bloom intensity
        } ) );

        const outputPass = scenePass.getTextureNode();
        const bloomIntensityPass = scenePass.getTextureNode( 'bloomIntensity' );

        const bloomPass = bloom(Fn(() => {
            const bloomIntensity = bloomIntensityPass.r;
            const charge = bloomIntensityPass.g;
            const colorMask = vec3(1.0 - charge * 0.5, 1.0 - charge, 1.0);

            return vec4(outputPass.rgb * bloomIntensity * colorMask, 1);
        })());

        const postProcessing = new THREE.PostProcessing(this.renderer);
        postProcessing.outputColorTransform = false;
        postProcessing.outputNode = Fn(() => {
            const bloomIntensity = bloomIntensityPass.r;
            const charge = bloomIntensityPass.g;

            const bloomMask = (1.0 - clamp(bloomIntensity, 0, 1)) + charge;
            const finalBloom = bloomPass.rgb * clamp(bloomMask, 0, 1);
            return vec4(outputPass.rgb + finalBloom.rgb, 1.0).renderOutput();
        })();

        this.postProcessing = postProcessing;
        this.bloomPass = bloomPass;

        this.bloomPass.threshold.value = 0.001;
        this.bloomPass.strength.value = 0.4;
        this.bloomPass.radius.value = 0.8;

        this.raycaster = new THREE.Raycaster();
        if (!this.options.embed) {
            this.renderer.domElement.addEventListener("mousemove", (event) => { this.onMouseMove(event); });
        }

        await progressCallback(1.0, 100);

        if (this.options.embed) {
            window.__ANCHOR_OCEAN__?.setJellyfishReady?.();
        }
    }

    onMouseMove(event) {
        const pointer = new THREE.Vector2();
        pointer.x = (event.clientX / window.innerWidth) * 2 - 1;
        pointer.y = -(event.clientY / window.innerHeight) * 2 + 1;
        this.raycaster.setFromCamera(pointer, this.camera);
        this.physics.setMouseRay(this.raycaster.ray.origin, this.raycaster.ray.direction);
    }

    resize(width, height) {
        this.camera.aspect = width / height;
        this.camera.updateProjectionMatrix();
    }

    updatePointer() {
        if (!this.raycaster) return;
        this.bridge.medusae.forEach(medusa => {
            medusa.updatePointerInteraction(this.raycaster.ray);
        });
    }

    sortMedusae() {
        this.bridge.medusae.forEach(medusa => {
           medusa.distance = this.camera.position.distanceTo(medusa.transformationObject.position);
        });
        const sorted = [...this.bridge.medusae].sort((m1,m2) => m1.distance - m2.distance);
        let z = 10;
        for (let i = 0; i < sorted.length; i++) {
            const m = sorted[i];
            m.bell.geometryInside.object.renderOrder = z++;
            m.arms.object.renderOrder = z++;
            m.tentacles.object.renderOrder = z++;
            m.bell.geometryOutside.object.renderOrder = z++;
        }
    }

    async update(delta, elapsed) {
        if (!this.postProcessing) return;

        conf.begin();
        const { runSimulation, showVerletSprings } = conf;
        if (this.springVisualizer?.object) {
            this.springVisualizer.object.visible = showVerletSprings;
        }

        conf.update();
        this.controls.update(delta);
        Medusa.updateStatic();

        this.background.update(elapsed);
        this.lights.update(elapsed);

        if (!this.options.embed) {
            this.updatePointer();
        }

        if (runSimulation) {
            await this.physics.update(delta, elapsed);
        }

        if (!this.options.embed || this.frameNum % 2 === 0) {
            this.sortMedusae();
        }

        //this.renderer.render(this.scene, this.camera);

        await this.postProcessing.renderAsync();

        if (this.frameNum === 0) {
            console.timeEnd("firstFrame");
            if (this.options.embed) {
                window.__ANCHOR_OCEAN__?.setJellyfishReady?.();
            }
        }
        this.frameNum++
        conf.end();
    }

    setSessionActive(active) {
        if (!this.bloomPass) return;
        this.bloomPass.strength.value = active ? 0.72 : 0.38;
        this.bloomPass.radius.value = active ? 1.25 : 0.75;
        if (this.renderer) {
            this.renderer.toneMappingExposure = active ? 1.05 : 0.72;
        }
        if (this.controls) {
            this.controls.autoRotateSpeed = active ? 0.05 : 0.035;
        }
    }
}
export default App;