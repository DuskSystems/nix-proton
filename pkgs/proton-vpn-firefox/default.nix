{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchNpmDeps,
  npmHooks,
  nodejs,
  zip,
}:

{
  version,
  rev,
  srcHash,
  npmDepsHash,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "proton-vpn-firefox";
  inherit version;

  src = fetchFromGitHub {
    owner = "ProtonVPN";
    repo = "proton-vpn-browser-extension";
    inherit rev;
    hash = srcHash;
  };

  postPatch = ''
    patchShebangs .
  '';

  nativeBuildInputs = [
    npmHooks.npmConfigHook
    nodejs
    zip
  ];

  npmDeps = fetchNpmDeps {
    inherit (finalAttrs)
      src
      postPatch
      ;

    hash = npmDepsHash;
  };

  buildPhase = ''
    npm run pack-ff
    mv vpn-proton-firefox.zip vpn@proton.ch.xpi
  '';

  installPhase = ''
    mkdir -p $out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}
    cp *.xpi $out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}
  '';

  meta = {
    description = "Proton VPN Firefox Extension";
    homepage = "https://protonvpn.com";
    changelog = "https://github.com/ProtonVPN/proton-vpn-browser-extension/blob/main/changelog.md";
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    license = [ lib.licenses.gpl3Plus ];
    platforms = lib.platforms.all;
    maintainers = [ lib.maintainers.cathalmullan ];
  };
})
