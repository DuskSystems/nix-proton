{
  description = "nix-proton";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };
  };

  # nix flake show
  outputs =
    {
      self,
      nixpkgs,
      ...
    }:

    let
      perSystem = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;

      systemPkgs = perSystem (
        system:

        import nixpkgs {
          inherit system;

          overlays = [
            self.overlays.default
          ];
        }
      );

      perSystemPkgs = f: perSystem (system: f (systemPkgs.${system}));
    in
    {
      overlays = {
        default = final: prev: {
          electron-forge-hooks = prev.callPackage pkgs/electron-forge-hooks { };
          inherit (final.electron-forge-hooks)
            forgeConfigHook
            ;

          fetch-cargo-vendor-util = prev.writers.writePython3Bin "fetch-cargo-vendor-util" {
            libraries = with prev.python3Packages; [
              requests
            ];
            flakeIgnore = [
              "E501"
            ];
          } (builtins.readFile "${prev.path}/pkgs/build-support/rust/fetch-cargo-vendor-util.py");

          buildProtonMailDesktop = prev.callPackage pkgs/proton-mail-desktop { };
          proton-mail-desktop = prev.callPackage pkgs/proton-mail-desktop/stable { };
          proton-mail-desktop-nightly = prev.callPackage pkgs/proton-mail-desktop/nightly { };

          buildProtonPassDesktop = prev.callPackage pkgs/proton-pass-desktop { };
          proton-pass-desktop = prev.callPackage pkgs/proton-pass-desktop/stable { };
          proton-pass-desktop-nightly = prev.callPackage pkgs/proton-pass-desktop/nightly { };

          buildProtonPassFirefox = prev.callPackage pkgs/proton-pass-firefox { };
          proton-pass-firefox = prev.callPackage pkgs/proton-pass-firefox/stable { };
          proton-pass-firefox-nightly = prev.callPackage pkgs/proton-pass-firefox/nightly { };

          buildProtonVpnFirefox = prev.callPackage pkgs/proton-vpn-firefox { };
          proton-vpn-firefox = prev.callPackage pkgs/proton-vpn-firefox/stable { };
        };
      };

      # nix build .#<name>
      packages = perSystemPkgs (pkgs: {
        proton-mail-desktop = pkgs.proton-mail-desktop;
        proton-mail-desktop-nightly = pkgs.proton-mail-desktop-nightly;

        proton-pass-desktop = pkgs.proton-pass-desktop;
        proton-pass-desktop-nightly = pkgs.proton-pass-desktop-nightly;

        proton-pass-firefox = pkgs.proton-pass-firefox;
        proton-pass-firefox-nightly = pkgs.proton-pass-firefox-nightly;

        proton-vpn-firefox = pkgs.proton-vpn-firefox;
      });

      devShells = perSystemPkgs (pkgs: {
        # nix develop
        default = pkgs.mkShell {
          name = "nix-proton-shell";

          env = {
            # Nix
            NIX_PATH = "nixpkgs=${nixpkgs.outPath}";
          };

          buildInputs = with pkgs; [
            # Update
            curl
            jq
            gnused
            nix-prefetch-git
            nix-prefetch-github
            prefetch-npm-deps
            nodejs
            yarn-berry_4
            yarn-berry_4.yarn-berry-fetcher
            fetch-cargo-vendor-util
            cargo

            # Nix
            nixfmt-rfc-style
            nixd
            nil
          ];
        };
      });
    };
}
