{
  buildProtonPassFirefox,
}:

buildProtonPassFirefox {
  version = "1.31.1.2";

  rev = "proton-pass@1.31.1.2";
  srcHash = "sha256-06D6D0Vza9eAKfMy0neAUaDHtZaO+cfNRKgV2Yvay7M=";

  missingHashes = ./missing-hashes.json;
  yarnOfflineCacheHash = "sha256-qcd0KSZBdLyCMXWxVBk0kwtwfDEklxSZ2GStPLb/ct0=";
}
