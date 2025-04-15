#!/usr/bin/env bash
set -euxo pipefail

PACKAGE="./pkgs/proton-mail-desktop/default.nix"
BERRY_LOCK="./pkgs/proton-mail-desktop/yarn.lock"

OLD_VERSION=$(nix eval --raw .#proton-mail-desktop.version)
OLD_SRC_HASH=$(nix eval --raw .#proton-mail-desktop.src.outputHash)

NEW_VERSION=$(curl "https://api.github.com/repos/ProtonMail/WebClients/branches" | jq -r '[.[] | select(.name | contains("release/inbox-desktop@")) | .name | split("release/inbox-desktop@")[1]] | sort | last')
NEW_SRC_HASH=$(nix-prefetch-github ProtonMail WebClients --json --rev "release/inbox-desktop@${NEW_VERSION}" | jq -r '.hash')

if [ "$OLD_VERSION" = "$NEW_VERSION" ] && [ "$OLD_SRC_HASH" = "$NEW_SRC_HASH" ]; then
  exit 0
fi

OLD_BERRY_HASH=$(nix eval --raw .#proton-mail-desktop.berryOfflineCache.outputHash)

TEMP_DIR=$(mktemp -d)
pushd "$TEMP_DIR"
git clone https://github.com/ProtonMail/WebClients.git
cd WebClients
git checkout "release/inbox-desktop@$NEW_VERSION"
rm -rf .git

yarn install --refresh-lockfile --no-immutable
NEW_BERRY_HASH=$(prefetch-berry-deps yarn.lock)

popd

rm $BERRY_LOCK
cp $TEMP_DIR/WebClients/yarn.lock $BERRY_LOCK

sed -i "s|$OLD_VERSION|$NEW_VERSION|g" "$PACKAGE"
sed -i "s|$OLD_SRC_HASH|$NEW_SRC_HASH|g" "$PACKAGE"
sed -i "s|$OLD_BERRY_HASH|$NEW_BERRY_HASH|g" "$PACKAGE"

rm -rf $TEMP_DIR
