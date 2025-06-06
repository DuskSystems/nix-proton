{
  buildProtonPassFirefox,
}:

buildProtonPassFirefox {
  version = "1.31.6";

  rev = "proton-pass@1.31.6";
  srcHash = "sha256-PA+67Wk+HyR8dvvrXDWrIB5yeaGxgMHoFK2aZk682ZI=";

  missingHashes = ./missing-hashes.json;
  yarnOfflineCacheHash = "sha256-zdAKU8DEFbGQTWjKB3xs+MsUwI3ncRy4Xc2GjqXCOqY=";
}
