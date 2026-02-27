#!/usr/bin/env nix-shell
#!nix-shell -i bash -p gh jq nix nix-update git yarn-berry_4 yarn-berry_4.passthru.yarn-berry-fetcher

set -euo pipefail

PACKAGE="$(readlink -f "pkgs/$UPDATE_NIX_PNAME")"

LATEST=$(
  gh api repos/ProtonMail/WebClients/git/matching-refs/tags/proton-pass@ --jq '.[].ref' \
    | cut -d '@' -f 2 \
    | sort -V \
    | tail -1
)

if [[ "$UPDATE_NIX_OLD_VERSION" == "$LATEST" ]]; then
  exit 0
fi

# Update version and source hash
nix-update --flake --version="$LATEST" --src-only "$UPDATE_NIX_PNAME"

# Regenerate `yarn.lock` and `missing-hashes.json`
WORKDIR=$(mktemp -d)
git clone \
  --depth 1 \
  --branch "proton-pass@$LATEST" \
  https://github.com/ProtonMail/WebClients "$WORKDIR"

pushd "$WORKDIR"
git apply $PACKAGE/patches/*.patch
yarn install --mode update-lockfile
cp yarn.lock "$PACKAGE/yarn.lock"
yarn-berry-fetcher missing-hashes yarn.lock > "$PACKAGE/missing-hashes.json"
popd

rm -rf "$WORKDIR"

# Update remaining hashes
nix-update --flake --version=skip "$UPDATE_NIX_PNAME"
