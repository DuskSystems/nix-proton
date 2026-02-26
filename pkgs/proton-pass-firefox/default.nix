{
  lib,
  stdenv,
  fetchFromGitHub,
  yarn-berry_4,
  nodejs,
  zip,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "proton-pass-firefox";
  version = "1.34.500";

  src = fetchFromGitHub {
    owner = "ProtonMail";
    repo = "WebClients";
    rev = "proton-pass@${finalAttrs.version}";
    hash = "sha256-paPyazt4HU9RDHSbZKDWchNRPYDoceGE01xdcx6VEs4=";
  };

  patches = [
    ./patches/fix-workspaces.patch
  ];

  postPatch = ''
    cp ${./yarn.lock} yarn.lock
    patchShebangs .
  '';

  nativeBuildInputs = [
    yarn-berry_4
    yarn-berry_4.yarnBerryConfigHook
    nodejs
    zip
  ];

  env = {
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

    hash = "sha256-xLpS2AHJKop5IwPMeJQzKZKM7+oPub3BMuh6Np1vOKs=";
  };

  buildPhase = ''
    yarn workspace proton-pass-extension build:extension:ff
    pushd applications/pass-extension/dist
    zip -r 78272b6fa58f4a1abaac99321d503a20@proton.me.xpi .
    popd
  '';

  installPhase = ''
    mkdir -p $out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}
    cp applications/pass-extension/dist/*.xpi $out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}
  '';

  passthru = {
    updateScript = ./update.sh;
  };

  meta = {
    description = "Proton Pass Firefox Extension";
    homepage = "https://proton.me/pass";
    changelog = "https://github.com/ProtonMail/WebClients/blob/main/applications/pass-extension/CHANGELOG.md";
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    license = [ lib.licenses.gpl3Plus ];
    platforms = lib.platforms.all;
    maintainers = [ lib.maintainers.cathalmullan ];
  };
})
