#!/usr/bin/env bash
set -euxo pipefail

PACKAGE="./pkgs/proton-pass-desktop/default.nix"
BERRY_LOCK="./pkgs/proton-pass-desktop/yarn.lock"
CARGO_LOCK="./pkgs/proton-pass-desktop/Cargo.lock"

OLD_VERSION=$(nix eval --raw .#proton-pass-desktop.version)
NEW_VERSION=$(curl "https://api.github.com/repos/ProtonMail/WebClients/git/refs/tags" | jq -r '[.[] | select(.ref | contains("proton-pass@")) | .ref | split("/")[2] | split("proton-pass@")[1] | select(contains("-") | not)] | sort | last')
if [ "$OLD_VERSION" = "$NEW_VERSION" ]; then
  exit 0
fi

OLD_SRC_HASH=$(nix eval --raw .#proton-pass-desktop.src.outputHash)
NEW_SRC_HASH=$(nix-prefetch-github ProtonMail WebClients --json --rev "proton-pass@${NEW_VERSION}" | jq -r '.hash')

OLD_BERRY_HASH=$(nix eval --raw .#proton-pass-desktop.berryOfflineCache.outputHash)
OLD_CARGO_HASH=$(nix eval --raw .#proton-pass-desktop.cargoDeps.vendorStaging.outputHash)

TEMP_DIR=$(mktemp -d)
pushd "$TEMP_DIR"
git clone https://github.com/ProtonMail/WebClients.git
cd WebClients
git checkout "proton-pass@$NEW_VERSION"

yarn install --refresh-lockfile --no-immutable
NEW_BERRY_HASH=$(prefetch-berry-deps yarn.lock)

cd applications/pass-desktop/native
cargo add arboard --features wayland-data-control
fetch-cargo-vendor-util create-vendor-staging Cargo.lock vendor
NEW_CARGO_HASH=$(nix-hash --type sha256 --sri vendor)

popd

rm "$BERRY_LOCK"
cp "$TEMP_DIR/WebClients/yarn.lock" "$BERRY_LOCK"
rm "$CARGO_LOCK"
cp "$TEMP_DIR/WebClients/applications/pass-desktop/native/Cargo.lock" "$CARGO_LOCK"

sed -i "s|$OLD_VERSION|$NEW_VERSION|g" "$PACKAGE"
sed -i "s|$OLD_SRC_HASH|$NEW_SRC_HASH|g" "$PACKAGE"
sed -i "s|$OLD_BERRY_HASH|$NEW_BERRY_HASH|g" "$PACKAGE"
sed -i "s|$OLD_CARGO_HASH|$NEW_CARGO_HASH|g" "$PACKAGE"

rm -rf $TEMP_DIR
