[![sync](https://github.com/DuskSystems/nix-proton/actions/workflows/sync.yml/badge.svg)](https://github.com/DuskSystems/nix-proton/actions/workflows/sync.yml)
[![ci](https://github.com/DuskSystems/nix-proton/actions/workflows/ci.yml/badge.svg)](https://github.com/DuskSystems/nix-proton/actions/workflows/ci.yml)

# `nix-proton`

Nix expressions for Proton applications, built from source.

## Packages

- `proton-mail-desktop`
- `proton-pass-desktop`

## Upstreaming

I'll likely upstream this into nixpkgs eventually, but there's a few blockers/concerns:
- [Opening links on NixOS may not work by default](https://github.com/NixOS/nixpkgs/issues/160923).
- [Replace custom Electron hooks with upstream hooks](https://github.com/NixOS/nixpkgs/pull/487711)
- [Protons release process is a little spotty, with old tags/branches being deleted when their repos are re-synced](https://github.com/ProtonMail/WebClients/issues/464).
- No MacOS support currently.
