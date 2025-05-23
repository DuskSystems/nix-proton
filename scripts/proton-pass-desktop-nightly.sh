#!/usr/bin/env bash
set -euxo pipefail

cleanup() {
  if [ -n "${TEMP_DIR:-}" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
  fi
}
trap cleanup EXIT

PACKAGE="./pkgs/proton-pass-desktop/nightly/default.nix"
MISSING_HASHES="./pkgs/proton-pass-desktop/nightly/missing-hashes.json"

OLD_VERSION=$(nix eval --raw .#proton-pass-desktop-nightly.version)
OLD_SRC_HASH=$(nix eval --raw .#proton-pass-desktop-nightly.src.outputHash)

NEW_VERSION=$(curl -s "https://api.github.com/repos/ProtonMail/WebClients/commits/main" | jq -r '.sha')
NEW_SRC_HASH=$(nix-prefetch-github ProtonMail WebClients --json --rev "$NEW_VERSION" | jq -r '.hash')

if [ "$OLD_VERSION" = "$NEW_VERSION" ] && [ "$OLD_SRC_HASH" = "$NEW_SRC_HASH" ]; then
  exit 0
fi

OLD_BERRY_HASH=$(nix eval --raw .#proton-pass-desktop-nightly.yarnOfflineCache.outputHash)
OLD_CARGO_HASH=$(nix eval --raw .#proton-pass-desktop-nightly.cargoDeps.vendorStaging.outputHash)

TEMP_DIR=$(mktemp -d)
pushd "$TEMP_DIR"
git clone https://github.com/ProtonMail/WebClients.git
cd WebClients
git checkout "$NEW_VERSION"
rm -rf .git

yarn-berry-fetcher missing-hashes yarn.lock | tee missing-hashes.json
NEW_BERRY_HASH=$(yarn-berry-fetcher prefetch yarn.lock missing-hashes.json)

cd applications/pass-desktop/native
fetch-cargo-vendor-util create-vendor-staging Cargo.lock vendor
NEW_CARGO_HASH=$(nix-hash --type sha256 --sri vendor)

popd

rm -f "$MISSING_HASHES"
cp "$TEMP_DIR/WebClients/missing-hashes.json" "$MISSING_HASHES"

sed -i "s|$OLD_VERSION|$NEW_VERSION|g" "$PACKAGE"
sed -i "s|$OLD_SRC_HASH|$NEW_SRC_HASH|g" "$PACKAGE"
sed -i "s|$OLD_BERRY_HASH|$NEW_BERRY_HASH|g" "$PACKAGE"
sed -i "s|$OLD_CARGO_HASH|$NEW_CARGO_HASH|g" "$PACKAGE"
