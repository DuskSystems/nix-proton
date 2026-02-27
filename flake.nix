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

          proton-mail = prev.callPackage pkgs/proton-mail { };
          proton-pass = prev.callPackage pkgs/proton-pass { };
        };
      };

      # nix build .#<name>
      packages = perSystemPkgs (pkgs: {
        proton-mail = pkgs.proton-mail;
        proton-pass = pkgs.proton-pass;
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
