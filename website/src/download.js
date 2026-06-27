export const REPO = "Ign8Official1/Anchor";
export const REPO_URL = `https://github.com/${REPO}`;

export const DOWNLOAD_URL = `https://github.com/${REPO}/releases/latest/download/Anchor.dmg`;
export const ZIP_URL = `https://github.com/${REPO}/releases/latest/download/Anchor-macOS.zip`;
export const INSTALL_SCRIPT_URL = `https://raw.githubusercontent.com/${REPO}/main/scripts/install.sh`;

export const INSTALL_CMD = `/bin/bash -c "$(curl -fsSL ${INSTALL_SCRIPT_URL})"`;

export const BUILD_CMD = `git clone ${REPO_URL}.git
cd Anchor
./build.sh
open dist/Anchor.app`;
