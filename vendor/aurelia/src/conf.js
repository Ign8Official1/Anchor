import {Pane} from 'tweakpane';
import * as EssentialsPlugin from '@tweakpane/plugin-essentials';

class Conf {
    gui = null;

    roughness = 0.4;
    metalness = 0.2;
    transmission = 0.7;
    color = 0xffffff; //0xf4aaff;
    iridescence = 0.0;
    iridescenceIOR = 2.33;

    runSimulation = true;
    showVerletSprings = false;

    constructor() { }

    init(options = {}) {
        if (options.embed) {
            this.gui = {
                begin: () => {},
                end: () => {},
                update: () => {},
            };
            this.fpsGraph = {
                begin: () => {},
                end: () => {},
            };
            this.embed = true;
            this.embedJellyfishCount = options.embedJellyfishCount ?? 8;
            this.embedRiseBase = options.embedRiseBase ?? 0.42;
            this.embedRiseSpeed = options.embedRiseSpeed ?? 1.55;
            this.embedSpawnBoostSeconds = options.embedSpawnBoostSeconds ?? 1.4;
            this.embedMotionSpeed = options.embedMotionSpeed ?? 0.52;
            this.embedSubdivisions = options.embedSubdivisions ?? 20;
            return;
        }

        this.embed = false;
        this.embedJellyfishCount = 10;
        this.embedRiseBase = 1;
        this.embedRiseSpeed = 1;
        this.embedSpawnBoostSeconds = 0;
        this.embedMotionSpeed = 1;
        this.embedSubdivisions = 40;

        const gui = new Pane()
        gui.registerPlugin(EssentialsPlugin);

        const stats = gui.addFolder({
            title: "stats",
            expanded: false,
        });
        this.fpsGraph = stats.addBlade({
            view: 'fpsgraph',
            label: 'fps',
            rows: 2,
        });

        /*const settings = gui.addFolder({
            title: "settings",
            expanded: false,
        });*/
        //settings.addBinding(this, "wireframe");
        //settings.addBinding(this, "iridescence", { min: 0.01, max: 1.0, step: 0.01 });
        //settings.addBinding(this, "iridescenceIOR", { min: 1.00, max: 2.33, step: 0.01 });

        this.gui = gui;
    }

    update() {
    }

    begin() {
        this.fpsGraph?.begin();
    }
    end() {
        this.fpsGraph?.end();
    }

}
export const conf = new Conf();