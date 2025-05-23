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
  cargoVendorHash,
  missingHashes ? null,
  yarnOfflineCacheHash,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "proton-pass-desktop";
  inherit version;

  src = fetchFromGitHub {
    owner = "ProtonMail";
    repo = "WebClients";
    inherit rev;
    hash = srcHash;
  };

  postPatch = ''
    patchShebangs .
  '';

  nativeBuildInputs = [
    rustPlatform.cargoSetupHook
    rustc
    cargo

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

  cargoRoot = "applications/pass-desktop/native";
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs)
      src
      postPatch
      cargoRoot
      ;

    hash = cargoVendorHash;
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
    forgeConfigHook applications/pass-desktop/forge.config.js
  '';

  buildPhase = ''
    # This is the same as running `yarn workspace proton-pass-desktop build:desktop`
    # Except we only build a native release for the current platform.
    pushd applications/pass-desktop

    pushd native
    yarn build
    popd

    yarn run config
    yarn electron-forge package
    popd
  '';

  installPhase = ''
    mkdir -p $out/share/proton-pass
    cp -r applications/pass-desktop/out/**/* $out/share/proton-pass

    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp $out/share/proton-pass/resources/assets/logo.svg $out/share/icons/hicolor/scalable/apps/proton-pass.svg

    mkdir -p $out/share/applications
    copyDesktopItems

    mkdir -p $out/bin
    ln -s "$out/share/proton-pass/Proton Pass" $out/bin/proton-pass

    wrapProgram "$out/share/proton-pass/Proton Pass" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath finalAttrs.buildInputs}" \
      --set CHROME_DEVEL_SANDBOX $out/share/proton-pass/chrome-sandbox \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "Proton Pass";
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
