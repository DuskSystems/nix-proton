{
  lib,
  stdenv,
  fetchFromGitHub,

  yarn-berry_4,
  nodejs,

  zip,
  jq,
}:

{
  version,
  rev,
  srcHash,
  missingHashes ? null,
  yarnOfflineCacheHash,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "proton-pass-firefox";
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
    yarn-berry_4.yarnBerryConfigHook
    yarn-berry_4
    nodejs

    zip
    jq
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

  buildPhase = ''
    pushd applications/pass-extension
    yarn run config
    cp src/app/config.ts src/app/config.ff-release.ts
    yarn run build:extension:ff
    pushd dist
    zip -r 78272b6fa58f4a1abaac99321d503a20@proton.me.xpi .
    popd
    popd
  '';

  installPhase = ''
    mkdir -p $out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}
    cp applications/pass-extension/dist/*.xpi $out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}
  '';

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
