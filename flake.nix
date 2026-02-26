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
          inherit (final.electron-forge-hooks) forgeConfigHook;

          proton-mail-desktop = prev.callPackage pkgs/proton-mail-desktop { };
          proton-pass-desktop = prev.callPackage pkgs/proton-pass-desktop { };
          proton-pass-firefox = prev.callPackage pkgs/proton-pass-firefox { };
          proton-vpn-firefox = prev.callPackage pkgs/proton-vpn-firefox { };
        };
      };

      # nix build .#<name>
      packages = perSystemPkgs (pkgs: {
        proton-mail-desktop = pkgs.proton-mail-desktop;
        proton-pass-desktop = pkgs.proton-pass-desktop;
        proton-pass-firefox = pkgs.proton-pass-firefox;
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
            # GitHub
            gh
            zizmor

            # Spellchecking
            typos
            typos-lsp

            # Nix
            nix-update
            nixfmt
            nixd
            nil
          ];
        };
      });
    };
}
