#!/usr/bin/env -S nix develop --command bash
set -euxo pipefail

nix-update --flake --use-update-script proton-mail-desktop
nix-update --flake --use-update-script proton-pass-desktop

if [[ -n "$(git status --porcelain)" ]]; then
  git config user.name "github-actions[bot]"
  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
  git add .
  git commit -m "$(date --utc --rfc-email)"
  git push
fi
