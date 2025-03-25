{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchBerryDeps,

  berryConfigHook,
  nodejs,
  yarn-berry,

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

let
  tags = {
    x86_64-linux = "linux-x64";
    armv7l-linux = "linux-armv7l";
    aarch64-linux = "linux-arm64";
    x86_64-darwin = "darwin-x64";
    aarch64-darwin = "darwin-arm64";
  };

  platform = tags."${stdenv.hostPlatform.system}" or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation (finalAttrs: {
  pname = "proton-mail-desktop";
  version = "1.9.0";

  src = fetchFromGitHub {
    owner = "ProtonMail";
    repo = "WebClients";
    rev = "proton-inbox-desktop@${finalAttrs.version}";
    hash = "sha256-wsjP8S14Z+mbPaxiTE3AeT55TbJVlgG1oT+2QvOMs/4=";
  };

  postPatch = ''
    cp ${./yarn.lock} yarn.lock

    # Fix hardcoded desktop file path.
    substituteInPlace applications/inbox-desktop/src/utils/protocol/default_mailto_linux.ts \
      --replace-fail "/usr/share/applications" "$out/share/applications"

    # Add missing config file.
    mkdir -p packages/config/mail
    echo '{ "appConfig": { "sentryDesktop": "" } }' > packages/config/mail/appConfig.json

    # Electron Forge tries to do checksum verification over the network.
    substituteInPlace applications/inbox-desktop/forge.config.ts \
      --replace-fail "packagerConfig: {" "packagerConfig: { download: { unsafelyDisableChecksums: true, },"

    patchShebangs .
  '';

  nativeBuildInputs = [
    berryConfigHook
    nodejs
    yarn-berry

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

  berryOfflineCache = fetchBerryDeps {
    inherit (finalAttrs)
      pname
      version
      src
      postPatch
      ;

    hash = "sha256-9wc948jbnvuRVH62hPgJ9mHXrvhq7FzXBuvpoAcCXvc=";
  };

  env = {
    ELECTRON_CUSTOM_VERSION = "${electron.version}";
  };

  buildPhase = ''
    export HOME=$(mktemp -d)
    ZIP_FILE="electron-v${electron.version}-${platform}.zip"
    ZIP_HASH=$(echo -n "https://github.com/electron/electron/releases/download/v${electron.version}" | sha256sum | cut -d ' ' -f 1)
    mkdir -p $HOME/.cache/electron/$ZIP_HASH

    ELECTRON=$(mktemp -d)
    cp -r ${electron}/libexec/electron/* $ELECTRON
    chmod -R u+w $ELECTRON

    pushd $ELECTRON
    zip -r $HOME/.cache/electron/$ZIP_HASH/$ZIP_FILE .
    popd

    chmod 644 $HOME/.cache/electron/$ZIP_HASH/$ZIP_FILE
    chmod -R u+w $HOME/.cache

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
    changelog = "https://github.com/ProtonMail/WebClients/blob/${finalAttrs.src.tag}/applications/inbox-desktop/CHANGELOG.md";
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    license = [ lib.licenses.gpl3Plus ];
    mainProgram = "proton-mail";
    maintainers = [ lib.maintainers.cathalmullan ];
  };
})
