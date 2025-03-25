#!/usr/bin/env bash
set -euxo pipefail

PACKAGE="./pkgs/proton-vpn-firefox/default.nix"

OLD_VERSION=$(nix eval --raw .#proton-vpn-firefox.version)
NEW_VERSION=$(curl "https://api.github.com/repos/ProtonVPN/proton-vpn-browser-extension/commits/main" | jq -r '.sha')
if [ "$OLD_VERSION" = "$NEW_VERSION" ]; then
  exit 0
fi

OLD_SRC_HASH=$(nix eval --raw .#proton-vpn-firefox.src.outputHash)
NEW_SRC_HASH=$(nix-prefetch-github ProtonVPN proton-vpn-browser-extension --json --rev "$NEW_VERSION" | jq -r '.hash')

OLD_NPM_HASH=$(nix eval --raw .#proton-vpn-firefox.npmDeps.outputHash)
TEMP_DIR=$(mktemp -d)
pushd "$TEMP_DIR"
git clone https://github.com/ProtonVPN/proton-vpn-browser-extension.git
cd proton-vpn-browser-extension
git checkout "$NEW_VERSION"

NEW_NPM_HASH=$(prefetch-npm-deps package-lock.json)

popd

sed -i "s|$OLD_VERSION|$NEW_VERSION|g" "$PACKAGE"
sed -i "s|$OLD_SRC_HASH|$NEW_SRC_HASH|g" "$PACKAGE"
sed -i "s|$OLD_NPM_HASH|$NEW_NPM_HASH|g" "$PACKAGE"

rm -rf $TEMP_DIR
