import { defineConfig } from "vite";

const repo = process.env.GITHUB_REPOSITORY?.split("/")[1] ?? "Anchor";
const pagesBase = process.env.GITHUB_PAGES ? `/${repo}/` : "/";

export default defineConfig({
  base: pagesBase,
  build: {
    outDir: "dist",
    assetsDir: "assets",
  },
});
