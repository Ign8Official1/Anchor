import * as THREE from "three/webgpu";
import {iridescenceIOR, uniform} from "three/tsl";

import {noise2D, noise3D} from "./common/noise";

import {MedusaTentacles} from "./medusaTentacles";
import {MedusaBell} from "./medusaBell";
import {conf} from "./conf";
import {MedusaOralArms} from "./medusaOralArms";
import {MedusaBellGeometry} from "./medusaBellGeometry";
import {MedusaBellPattern} from "./medusaBellPattern";

export class Medusa {
    renderer = null;
    physics = null;
    object = null;
    bridge = null;
    medusaId = -1;
    noiseSeed = 0;
    time = 0;
    phase = 0;
    needsPositionUpdate = true;
    charge = 0;
    spawnBoostRemaining = 0;
    entryDelayRemaining = 0;
    hasStartedRising = false;
    embedLaneX = 0;
    embedLaneZ = 0;
    static uniforms = {};
    static embedEntryDelays = [];
    static embedInitialY = [];

    static prepareEmbedEntryOrder(count) {
        const order = Array.from({ length: count }, (_, i) => i);
        for (let i = order.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            const tmp = order[i];
            order[i] = order[j];
            order[j] = tmp;
        }

        const bandMin = -9;
        const bandMax = 14;
        Medusa.embedInitialY = order.map((rank, i) => {
            const t = count > 1 ? rank / (count - 1) : 0.5;
            return bandMin + t * (bandMax - bandMin) + (Math.random() - 0.5) * 1.2;
        });
        // Shuffled vertical slots, but everyone is on screen from frame one.
        Medusa.embedEntryDelays = order.map(() => 0);
    }

    static embedLanePosition(index, total) {
        const golden = Math.PI * (3 - Math.sqrt(5));
        const ring = index % 3;
        const radius = 6.2 + ring * 1.6;
        const angle = (index + 0.5) * golden * 2.15 + ring * 0.55;
        return {
            x: Math.cos(angle) * radius,
            z: Math.sin(angle) * radius * 0.78,
        };
    }

    static randomEmbedLane() {
        const angle = Math.random() * Math.PI * 2;
        const radius = 5.5 + Math.random() * 3.8;
        return {
            x: Math.cos(angle) * radius,
            z: Math.sin(angle) * radius * 0.78,
        };
    }

    placeEmbedAt(y, randomLane = false) {
        const lane = randomLane
            ? Medusa.randomEmbedLane()
            : Medusa.embedLanePosition(this.medusaId, conf.embedJellyfishCount);
        this.embedLaneX = lane.x;
        this.embedLaneZ = lane.z;
        this.transformationObject.position.set(this.embedLaneX, y, this.embedLaneZ);
    }

    placeEmbedInLowerHalf(randomLane = false) {
        const total = Math.max(conf.embedJellyfishCount, 1);
        const band = total > 1 ? this.medusaId / (total - 1) : 0.35;
        const y = -8.5 + band * 6.5 + (Math.random() - 0.5) * 1.8;
        this.placeEmbedAt(y, randomLane);
    }

    constructor(renderer, physics, bridge){
        this.renderer = renderer;
        this.physics = physics;
        this.object = new THREE.Object3D();
        this.transformationObject = new THREE.Object3D();
        this.object.add(this.transformationObject);

        this.time = Math.random() * 5;
        this.noiseSeed = Math.random() * 100.0;
        this.bridge = bridge;
        this.medusaId = this.bridge.registerMedusa(this);

        if (conf.embed) {
            const startY = Medusa.embedInitialY[this.medusaId] ?? (-6 + this.medusaId * 2.5);
            this.placeEmbedAt(startY, false);
            this.entryDelayRemaining = Medusa.embedEntryDelays[this.medusaId] ?? 0;
            this.hasStartedRising = true;
            this.spawnBoostRemaining = 0;
        } else {
            this.transformationObject.position.set((Math.random() - 0.5) * 10, (this.medusaId / 10 + Math.random() * 0.1 - 0.5) * 40, (Math.random() - 0.5) * 10);
        }

        this.createBellGeometry();

        this.updatePosition(0,0);
    }

    createBellGeometry() {
        this.subdivisions = conf.embed ? conf.embedSubdivisions : 40; //has to be even

        this.bell = new MedusaBell(this);
        this.tentacles = new MedusaTentacles(this);
        this.arms = new MedusaOralArms(this);

        this.bell.createGeometry();
        this.tentacles.createGeometry();
        this.arms.createGeometry();
        //this.gut.createGeometry();

        this.object.add(this.bell.object);
        this.object.add(this.tentacles.object);
        this.object.add(this.arms.object);
    }

    async bake() { }

    updatePosition(delta, elapsed) {
        if (conf.embed && this.entryDelayRemaining > 0) {
            this.entryDelayRemaining = Math.max(0, this.entryDelayRemaining - delta);
            this.transformationObject.updateMatrix();
            return;
        }

        if (conf.embed && !this.hasStartedRising) {
            this.hasStartedRising = true;
            this.spawnBoostRemaining = conf.embedSpawnBoostSeconds;
        }

        const wobble = conf.embed ? 0.65 : 1;
        const time = this.time * 0.1;
        const rotX = noise3D(this.noiseSeed, 13.37, time) * Math.PI * 0.2 * wobble;
        const rotY = noise3D(this.noiseSeed, 12.37, time*0.1) * Math.PI * 0.4 * wobble;
        const rotZ = noise3D(this.noiseSeed, 11.37, time) * Math.PI * 0.2 * wobble;
        this.transformationObject.rotation.set(rotX,rotY,rotZ, "XZY");

        const baseRise = conf.embed ? conf.embedRiseBase : 1;
        let riseMul = baseRise;
        if (conf.embed && this.spawnBoostRemaining > 0) {
            riseMul = conf.embedRiseSpeed;
            this.spawnBoostRemaining = Math.max(0, this.spawnBoostRemaining - delta);
        }

        const speed = (1.0 + Math.sin(this.phase + 4.4) * 0.35 + this.charge * 1.0) * delta * riseMul;

        const offset = new THREE.Vector3(0,speed,0).applyEuler(this.transformationObject.rotation);
        this.transformationObject.position.add(offset);
        if (this.transformationObject.position.y > 22) {
            if (conf.embed) {
                // Re-enter at the bottom of the visible band — no long gaps off-screen.
                this.placeEmbedAt(-9 - Math.random() * 2.5, true);
                this.entryDelayRemaining = 0;
                this.hasStartedRising = true;
                this.spawnBoostRemaining = conf.embedSpawnBoostSeconds * 0.35;
            } else {
                const respawnY = -25;
                this.transformationObject.position.set((Math.random() - 0.5) * 10, respawnY, (Math.random() - 0.5) * 10);
            }
            this.needsPositionUpdate = true;
        }

        this.transformationObject.updateMatrix();
    }

    updatePointerInteraction(ray) {
        const dist = ray.distanceToPoint(this.transformationObject.position);
        this.charge += (1 - Math.min(Math.max(0, dist - 0.5), 1)) * 0.05;
        this.charge = Math.min(this.charge, 1.00);
        this.charge *= 0.95;
    }

    async update(delta, elapsed) {
        const motion = conf.embed ? conf.embedMotionSpeed : 1;
        this.time += delta * motion * (1.0 + noise2D(this.noiseSeed, elapsed*0.1) * 0.1 + this.charge * 0.5);
        const phaseRate = conf.embed ? 0.15 : 0.2;
        this.phase = ((this.time * phaseRate) % 1.0) * Math.PI * 2;
        this.updatePosition(delta, elapsed);
        //return await this.bridge.update();
    }


    static async initStatic(physics) {
        Medusa.uniforms.matrix = uniform(new THREE.Matrix4());
        Medusa.uniforms.phase = uniform(0);
        Medusa.uniforms.charge = uniform(0);

        MedusaBellPattern.createColorNode();
        MedusaBellGeometry.createMaterial(physics);
        MedusaTentacles.createMaterial(physics);
        MedusaOralArms.createMaterial(physics);

    }

    static setMouseRay(ray) { }

    static updateStatic() {
        const { roughness } = conf;
        MedusaBellGeometry.materialInner.roughness = roughness;
        MedusaBellGeometry.materialOuter.roughness = roughness;

    }

}
