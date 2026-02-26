#!/usr/bin/env -S nix develop --command bash
set -euxo pipefail
shopt -s globstar

nixfmt --width=120 --check **/*.nix
typos
zizmor --pedantic .github

nix build .#proton-mail-desktop
nix build .#proton-pass-desktop
nix build .#proton-pass-firefox
nix build .#proton-vpn-firefox
