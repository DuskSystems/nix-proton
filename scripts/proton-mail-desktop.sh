#!/usr/bin/env bash
set -euxo pipefail

PACKAGE="./pkgs/proton-mail-desktop/default.nix"
BERRY_LOCK="./pkgs/proton-mail-desktop/yarn.lock"

OLD_VERSION=$(nix eval --raw .#proton-mail-desktop.version)
NEW_VERSION=$(curl "https://api.github.com/repos/ProtonMail/WebClients/branches" | jq -r '[.[] | select(.name | contains("release/inbox-desktop@")) | .name | split("release/inbox-desktop@")[1]] | sort | last')
if [ "$OLD_VERSION" = "$NEW_VERSION" ]; then
  exit 0
fi

if [ "$NEW_VERSION" = "null" ]; then
  exit 0
fi

OLD_SRC_HASH=$(nix eval --raw .#proton-mail-desktop.src.outputHash)
NEW_SRC_HASH=$(nix-prefetch-github ProtonMail WebClients --json --rev "release/inbox-desktop@${NEW_VERSION}" | jq -r '.hash')

OLD_BERRY_HASH=$(nix eval --raw .#proton-mail-desktop.berryOfflineCache.outputHash)
TEMP_DIR=$(mktemp -d)
pushd "$TEMP_DIR"
git clone https://github.com/ProtonMail/WebClients.git
cd WebClients
git checkout "release/inbox-desktop@$NEW_VERSION"

yarn install --refresh-lockfile --no-immutable
NEW_BERRY_HASH=$(prefetch-berry-deps yarn.lock)

popd

rm $BERRY_LOCK
cp $TEMP_DIR/WebClients/yarn.lock $BERRY_LOCK

sed -i "s|$OLD_VERSION|$NEW_VERSION|g" "$PACKAGE"
sed -i "s|$OLD_SRC_HASH|$NEW_SRC_HASH|g" "$PACKAGE"
sed -i "s|$OLD_BERRY_HASH|$NEW_BERRY_HASH|g" "$PACKAGE"

rm -rf $TEMP_DIR
