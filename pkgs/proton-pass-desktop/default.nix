{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchBerryDeps,

  rustPlatform,
  rustc,
  cargo,

  berryConfigHook,
  nodejs,
  yarn-berry,

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

stdenv.mkDerivation (finalAttrs: {
  pname = "proton-pass-desktop";
  version = "1.31.0.2";

  src = fetchFromGitHub {
    owner = "ProtonMail";
    repo = "WebClients";
    rev = "proton-pass@${finalAttrs.version}";
    hash = "sha256-YJ+rNydrmWuHYqx9HAHx/PIeUPQ048YGm4CNU50temM=";
  };

  postPatch = ''
    cp ${./yarn.lock} yarn.lock
    cp ${./Cargo.lock} applications/pass-desktop/native/Cargo.lock

    patchShebangs .
  '';

  nativeBuildInputs = [
    rustPlatform.cargoSetupHook
    rustc
    cargo

    berryConfigHook
    nodejs
    yarn-berry

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

  cargoRoot = "applications/pass-desktop/native";
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs)
      pname
      version
      src
      postPatch
      cargoRoot
      ;

    hash = "sha256-BJu75acPg9S4DhkG33OopHqyBKzBsg3WiD8wrtW2R9k=";
  };

  berryOfflineCache = fetchBerryDeps {
    inherit (finalAttrs)
      pname
      version
      src
      postPatch
      ;

    hash = "sha256-uRGq/51/kOczbHv02tmexvRTsJYfCrTpRf+/6DK1FFs=";
  };

  postConfigure = ''
    forgeConfigHook applications/pass-desktop/forge.config.js
  '';

  buildPhase = ''
    # This is the same as running `yarn workspace proton-pass-desktop build:desktop`
    # Except we only build a native release for the current platform.
    pushd applications/pass-desktop

    # Fix clipboard on Wayland.
    pushd native
    cargo add arboard --features wayland-data-control
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
    changelog = "https://github.com/ProtonMail/WebClients/blob/${finalAttrs.src.tag}/applications/pass-desktop/CHANGELOG.md";
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    license = [ lib.licenses.gpl3Plus ];
    mainProgram = "proton-pass";
    maintainers = [ lib.maintainers.cathalmullan ];
  };
})
