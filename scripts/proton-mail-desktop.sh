#!/usr/bin/env bash
set -euxo pipefail

cleanup() {
  if [ -n "${TEMP_DIR:-}" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
  fi
}
trap cleanup EXIT

PACKAGE="./pkgs/proton-mail-desktop/stable/default.nix"
MISSING_HASHES="./pkgs/proton-mail-desktop/stable/missing-hashes.json"

OLD_VERSION=$(nix eval --raw .#proton-mail-desktop.version)
OLD_SRC_HASH=$(nix eval --raw .#proton-mail-desktop.src.outputHash)

NEW_VERSION=$(curl "https://api.github.com/repos/ProtonMail/WebClients/branches" | jq -r '[.[] | select(.name | contains("release/inbox-desktop@")) | .name | split("release/inbox-desktop@")[1]] | sort | last')
NEW_SRC_HASH=$(nix-prefetch-github ProtonMail WebClients --json --rev "release/inbox-desktop@${NEW_VERSION}" | jq -r '.hash')

if [ "$OLD_VERSION" = "$NEW_VERSION" ] && [ "$OLD_SRC_HASH" = "$NEW_SRC_HASH" ]; then
  exit 0
fi

OLD_BERRY_HASH=$(nix eval --raw .#proton-mail-desktop.yarnOfflineCache.outputHash)

TEMP_DIR=$(mktemp -d)
pushd "$TEMP_DIR"
git clone https://github.com/ProtonMail/WebClients.git
cd WebClients
git checkout "release/inbox-desktop@$NEW_VERSION"
rm -rf .git

yarn-berry-fetcher missing-hashes yarn.lock | tee missing-hashes.json
NEW_BERRY_HASH=$(yarn-berry-fetcher prefetch yarn.lock missing-hashes.json)

popd

rm -f "$MISSING_HASHES"
cp "$TEMP_DIR/WebClients/missing-hashes.json" "$MISSING_HASHES"

sed -i "s|$OLD_VERSION|$NEW_VERSION|g" "$PACKAGE"
sed -i "s|$OLD_SRC_HASH|$NEW_SRC_HASH|g" "$PACKAGE"
sed -i "s|$OLD_BERRY_HASH|$NEW_BERRY_HASH|g" "$PACKAGE"
