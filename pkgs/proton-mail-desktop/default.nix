{
  lib,
  stdenv,
  fetchFromGitHub,

  yarn-berry_4,
  nodejs,

  forgeConfigHook,
  electron,
  zip,

  autoPatchelfHook,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,

  alsa-lib,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  flac,
  glib,
  gtk3,
  libffi,
  libgbm,
  libgcc,
  libGL,
  libjpeg,
  libnotify,
  libpng,
  libX11,
  libxcb,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libxkbcommon,
  libXrandr,
  libxslt,
  nspr,
  nss,
  pango,
  pulseaudio,
  systemd,
}:

{
  version,
  rev,
  srcHash,
  missingHashes ? null,
  yarnOfflineCacheHash,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "proton-mail-desktop";
  inherit version;

  src = fetchFromGitHub {
    owner = "ProtonMail";
    repo = "WebClients";
    inherit rev;
    hash = srcHash;
  };

  postPatch = ''
    # Fix hardcoded desktop file path.
    substituteInPlace applications/inbox-desktop/src/utils/protocol/default_mailto_linux.ts \
      --replace-fail "/usr/share/applications" "$out/share/applications"

    # Add missing config file.
    mkdir -p packages/config/mail
    echo '{ "appConfig": { "sentryDesktop": "" } }' > packages/config/mail/appConfig.json

    patchShebangs .
  '';

  nativeBuildInputs = [
    yarn-berry_4.yarnBerryConfigHook
    yarn-berry_4
    nodejs

    forgeConfigHook
    electron
    zip

    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus
    expat
    flac
    glib
    gtk3
    libffi
    libgbm
    libgcc
    libGL
    libjpeg
    libnotify
    libpng
    libX11
    libxcb
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libxkbcommon
    libXrandr
    libxslt
    nspr
    nss
    pango
    pulseaudio
    systemd
  ];

  env = {
    YARN_ENABLE_SCRIPTS = "0";
  };

  inherit missingHashes;
  yarnOfflineCache = yarn-berry_4.fetchYarnBerryDeps {
    inherit (finalAttrs)
      src
      postPatch
      missingHashes
      ;

    hash = yarnOfflineCacheHash;
  };

  postConfigure = ''
    forgeConfigHook applications/inbox-desktop/forge.config.ts
  '';

  buildPhase = ''
    yarn workspace proton-inbox-desktop package
  '';

  installPhase = ''
    mkdir -p $out/share/proton-mail
    cp -r applications/inbox-desktop/out/**/* $out/share/proton-mail

    mkdir -p $out/share/proton-mail/resources/assets
    cp -rL applications/inbox-desktop/assets/* $out/share/proton-mail/resources/assets

    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp $out/share/proton-mail/resources/assets/linux/icon.svg $out/share/icons/hicolor/scalable/apps/proton-mail.svg

    mkdir -p $out/share/applications
    copyDesktopItems

    mkdir -p $out/bin
    ln -s "$out/share/proton-mail/Proton Mail" $out/bin/proton-mail

    wrapProgram "$out/share/proton-mail/Proton Mail" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath finalAttrs.buildInputs}" \
      --set CHROME_DEVEL_SANDBOX $out/share/proton-mail/chrome-sandbox \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "Proton Mail";
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
