[![sync](https://github.com/DuskSystems/nix-proton/actions/workflows/sync.yml/badge.svg)](https://github.com/DuskSystems/nix-proton/actions/workflows/sync.yml)
[![ci](https://github.com/DuskSystems/nix-proton/actions/workflows/ci.yml/badge.svg)](https://github.com/DuskSystems/nix-proton/actions/workflows/ci.yml)

# `nix-proton`

Nix expressions for Proton applications and extensions, built from source.

## Packages

- `proton-mail-desktop`
- `proton-pass-desktop`
- `proton-pass-firefox`
- `proton-vpn-firefox`

### Firefox Extensions

The extensions are compatible with the `home-manager` Firefox module.

Since they are unsigned, they will only work with the 'Dev Edition' of Firefox.

You'll need the following config too:

```nix
{
  "xpinstall.signatures.required" = false;
}
```

## Upstreaming

I'll likely upstream this into nixpkgs eventually, but there's a few blockers/concerns:
- [Opening links on NixOS may not work by default](https://github.com/NixOS/nixpkgs/issues/160923).
- [Replace custom Electron hooks with upstream hooks](https://github.com/NixOS/nixpkgs/pull/487711)
- Protons release process is a little spotty, with old tags/branches being deleted when their repos are re-synced.
- No MacOS support currently.
