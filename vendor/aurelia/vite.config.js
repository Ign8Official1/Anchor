import { defineConfig } from 'vite'
import tslOperatorPlugin from 'vite-plugin-tsl-operator'

export default defineConfig({
    base: './',
    server: {
        port: 1234,
    },
    build: {
        // Three.js WebGPU + TSL is ~1.2 MB minified; expected for this embed.
        chunkSizeWarningLimit: 1600,
        rollupOptions: {
            input: {
                main: 'index.html',
                embed: 'anchor-embed.html',
            },
            output: {
                manualChunks(id) {
                    if (id.includes('node_modules/three')) {
                        return 'three';
                    }
                    if (id.includes('node_modules/tweakpane')) {
                        return 'tweakpane';
                    }
                },
            },
        },
    },
    plugins: [
        tslOperatorPlugin({logs:false})
    ]
});