{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchNpmDeps,
  npmHooks,
  nodejs,
  zip,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "proton-vpn-firefox";
  version = "1f6dcf2be5abd1e5809860df54cbb21ade75343d";

  src = fetchFromGitHub {
    owner = "ProtonVPN";
    repo = "proton-vpn-browser-extension";
    rev = finalAttrs.version;
    hash = "sha256-HhuHY275NIc8c9FYbxROLdqFNplWwhEtSbMITk8wfTU=";
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
      pname
      version
      src
      postPatch
      ;

    hash = "sha256-m/gXKDLqmoIN1g7WeYX3+2RRIXJLAkVXqxxyGw00gh8=";
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
    changelog = "https://github.com/ProtonVPN/proton-vpn-browser-extension/blob/${finalAttrs.src.rev}/changelog.md";
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    license = [ lib.licenses.gpl3Plus ];
    platforms = lib.platforms.all;
    maintainers = [ lib.maintainers.cathalmullan ];
  };
})
