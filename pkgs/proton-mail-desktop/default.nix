{
  lib,
  stdenv,
  fetchFromGitHub,
  yarn-berry_4,
  nodejs,
  forgeConfigHook,
  electron,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "proton-mail-desktop";
  version = "1.12.1";

  src = fetchFromGitHub {
    owner = "ProtonMail";
    repo = "WebClients";
    rev = "release/inbox-desktop@${finalAttrs.version}";
    hash = "sha256-My4bm6XV+ikupHhKJ/n8INNjBNVpzD2gCgRCrpdFKVo=";
  };

  patches = [
    ./patches/fix-workspaces.patch
    ./patches/fix-wayland-crash.patch
  ];

  postPatch = ''
    cp ${./yarn.lock} yarn.lock

    # Fix hardcoded desktop file path
    substituteInPlace applications/inbox-desktop/src/utils/protocol/default_mailto_linux.ts \
      --replace-fail "/usr/share/applications" "$out/share/applications"

    patchShebangs .
  '';

  nativeBuildInputs = [
    yarn-berry_4
    yarn-berry_4.yarnBerryConfigHook
    nodejs
    forgeConfigHook
    electron
    makeWrapper
    copyDesktopItems
  ];

  env = {
    NODE_ENV = "production";
    YARN_ENABLE_SCRIPTS = "false";

    # Disable automatic updates by pretending to be a snap.
    IS_SNAP = "1";
  };

  missingHashes = ./missing-hashes.json;

  yarnOfflineCache = yarn-berry_4.fetchYarnBerryDeps {
    inherit (finalAttrs)
      src
      patches
      postPatch
      missingHashes
      ;

    hash = "sha256-Z5UBuS2gwiNeLTEe/KL6Vza77Qf3rbTQUArCiwpqCm8=";
  };

  postConfigure = ''
    forgeConfigHook applications/inbox-desktop/forge.config.ts
  '';

  buildPhase = ''
    yarn workspace proton-inbox-desktop package
  '';

  installPhase = ''
    mkdir -p $out/share/proton-mail
    cp -r applications/inbox-desktop/out/**/resources $out/share/proton-mail

    mkdir -p $out/share/proton-mail/resources/assets
    cp -rL applications/inbox-desktop/assets/* $out/share/proton-mail/resources/assets

    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp $out/share/proton-mail/resources/assets/linux/icon.svg $out/share/icons/hicolor/scalable/apps/proton-mail.svg

    mkdir -p $out/share/applications
    copyDesktopItems

    makeWrapper '${lib.getExe electron}' $out/bin/proton-mail \
      --add-flags "$out/share/proton-mail/resources/app.asar" \
      --set-default ELECTRON_FORCE_IS_PACKAGED 1
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "proton-mail";
      desktopName = "Proton Mail";
      genericName = "Email Client";
      comment = "Proton Mail Desktop Client";
      exec = "proton-mail %U";
      icon = "proton-mail";
      categories = [
        "Network"
        "Email"
      ];
      startupNotify = true;
      startupWMClass = "proton-mail";
      mimeTypes = [ "x-scheme-handler/mailto" ];
    })
  ];

  passthru = {
    updateScript = ./update.sh;
  };

  meta = {
    inherit (electron.meta) platforms;
    description = "Proton Mail Desktop Client";
    homepage = "https://proton.me/mail";
    changelog = "https://github.com/ProtonMail/WebClients/blob/main/applications/inbox-desktop/CHANGELOG.md";
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    license = [ lib.licenses.gpl3Plus ];
    mainProgram = "proton-mail";
    maintainers = [ lib.maintainers.cathalmullan ];
  };
})
