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
- [nixpkgs doesn't support yarn berry yet](https://github.com/NixOS/nixpkgs/issues/254369).
- [Opening links on NixOS may not work by default](https://github.com/NixOS/nixpkgs/issues/160923).
- Arboard feature fix should be handled by Proton, not via a patch. (Support Ticket #3578937)
- There's a bug with the Mail client on Wayland not working on initial launch. Opening with X11 once, then using Wayland from then on works fine. (Support Ticket #3578963)
- Protons release process is a little spotty, with old tags/branches being deleted when their repos are re-synced.
- No MacOS support currently.
