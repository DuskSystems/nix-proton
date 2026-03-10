{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  rustc,
  cargo,
  yarn-berry_4,
  nodejs,
  forgeConfigHook,
  electron,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,

  # Linux
  libxkbcommon,
}:

let
  napiTargets = {
    x86_64-linux = "x64-gnu";
    aarch64-linux = "arm64-gnu";
  };

  napiTarget = napiTargets."${stdenv.hostPlatform.system}" or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation (finalAttrs: {
  pname = "proton-pass";
  version = "1.35.0";

  src = fetchFromGitHub {
    owner = "ProtonMail";
    repo = "WebClients";
    rev = "proton-pass@${finalAttrs.version}";
    hash = "sha256-zQmos0+a43FvjJ+qU9B/wXrtXzFAXpJIXPGewFN0uIk=";
  };

  patches = [
    ./patches/fix-workspaces.patch
  ];

  postPatch = ''
    cp ${./yarn.lock} yarn.lock
    patchShebangs .

    substituteInPlace applications/pass-desktop/src/main.ts \
      --replace-fail "process.resourcesPath" "'$out/share/proton-pass/resources'"
  '';

  nativeBuildInputs = [
    rustPlatform.cargoSetupHook
    rustc
    cargo
    yarn-berry_4
    yarn-berry_4.yarnBerryConfigHook
    nodejs
    forgeConfigHook
    electron
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    libxkbcommon
  ];

  cargoRoot = "applications/pass-desktop/native";
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) src postPatch cargoRoot;
    hash = "sha256-1VJ7UkqOjvmCeNUxek7pp+ZK/oSEoU0ngERvkXrku1w=";
  };

  env = {
    NODE_ENV = "production";
    YARN_ENABLE_SCRIPTS = "false";
  };

  missingHashes = ./missing-hashes.json;

  yarnOfflineCache = yarn-berry_4.fetchYarnBerryDeps {
    inherit (finalAttrs)
      src
      patches
      postPatch
      missingHashes
      ;

    hash = "sha256-mj48nkktPBcF4NFQIK5FTJdrJ6IRDlYqqZ5vvAsJVww=";
  };

  postConfigure = ''
    forgeConfigHook applications/pass-desktop/forge.config.ts
  '';

  buildPhase = ''
    pushd applications/pass-desktop/native
    cargo build --release
    mv target/release/libnative.so native.linux-${napiTarget}.node
    popd

    yarn workspace proton-pass-desktop electron-forge package
  '';

  installPhase = ''
    mkdir -p $out/share/proton-pass
    cp -r applications/pass-desktop/out/**/resources $out/share/proton-pass

    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp $out/share/proton-pass/resources/assets/logo.svg $out/share/icons/hicolor/scalable/apps/proton-pass.svg

    mkdir -p $out/share/applications
    copyDesktopItems

    makeWrapper '${lib.getExe electron}' $out/bin/proton-pass \
      --add-flags "$out/share/proton-pass/resources/app.asar" \
      --set-default ELECTRON_FORCE_IS_PACKAGED 1
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "proton-pass";
      desktopName = "Proton Pass";
      genericName = "Password Manager";
      comment = "Proton Pass Desktop Client";
      exec = "proton-pass %U";
      icon = "proton-pass";
      categories = [ "Utility" ];
      startupNotify = true;
      startupWMClass = "proton-pass";
    })
  ];

  passthru = {
    updateScript = ./update.sh;
  };

  meta = {
    inherit (electron.meta) platforms;
    description = "Proton Pass Desktop Client";
    homepage = "https://proton.me/pass";
    changelog = "https://github.com/ProtonMail/WebClients/blob/main/applications/pass-desktop/CHANGELOG.md";
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    license = [ lib.licenses.gpl3Plus ];
    mainProgram = "proton-pass";
    maintainers = [ lib.maintainers.cathalmullan ];
  };
})
