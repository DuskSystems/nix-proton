{
  stdenv,
  lib,
  yarn-berry,
  makeSetupHook,
  cacert,
  writeShellScriptBin,
}:

# Taken from: https://github.com/NixOS/nixpkgs/pull/355053

{
  fetchBerryDeps =
    let
      f =
        {
          name ? "offline",
          src,
          hash ? "",
          ...
        }@args:
        stdenv.mkDerivation (
          {
            inherit name src;

            dontInstall = true;

            nativeBuildInputs = [
              yarn-berry
              cacert
            ];

            env = {
              GIT_SSL_CAINFO = "${cacert}/etc/ssl/certs/ca-bundle.crt";
              NODE_EXTRA_CA_CERTS = "${cacert}/etc/ssl/certs/ca-bundle.crt";
            };

            configurePhase = ''
              runHook preConfigure

              export HOME="$NIX_BUILD_TOP"
              export YARN_ENABLE_TELEMETRY=0

              yarn config set enableGlobalCache false
              yarn config set cacheFolder $out
              yarn config set supportedArchitectures --json "$(cat ${./berry-supported-archs.json})"

              runHook postConfigure
            '';

            buildPhase = ''
              runHook preBuild
              mkdir -p $out
              yarn install --immutable --mode skip-build
              runHook postBuild
            '';

            outputHash = hash;
            outputHashAlgo = null;
            outputHashMode = "recursive";
          }
          // (removeAttrs args [
            "name"
            "src"
            "hash"
          ])
        );
    in
    lib.setFunctionArgs f (lib.functionArgs f);

  prefetch-berry-deps = writeShellScriptBin "prefetch-berry-deps" ''
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ $# -ne 1 ]]; then
      echo "Usage: prefetch-berry-deps <path/to/yarn.lock>"
      exit 1
    fi

    YARN_LOCK="$1"
    SRC="$(dirname "$(realpath $YARN_LOCK)")"

    OUTPUT=$(nix-build --expr "
      let
        pkgs = import <nixpkgs> {};
        berryLib = pkgs.callPackage ${toString ./.} {};
      in berryLib.fetchBerryDeps {
        src = $SRC;
        hash = pkgs.lib.fakeHash;
      }
    " 2>&1 || true)

    if grep -q "got:" <<< "$OUTPUT"; then
      echo "$OUTPUT" | grep "got:" | tr -d '[:space:]' | cut -d ':' -f 2
    else
      echo "Failed to prefetch hash:" >&2
      echo "$OUTPUT" >&2
      exit 1
    fi
  '';

  berryConfigHook = makeSetupHook {
    name = "berry-config-hook";

    substitutions = {
      berrySupportedArchs = ./berry-supported-archs.json;
    };

    propagatedBuildInputs = [
      yarn-berry
    ];

    meta = {
      description = "Install Node dependencies from an offline Yarn Berry cache";
    };
  } ./berry-config-hook.sh;
}
