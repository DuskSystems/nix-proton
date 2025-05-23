{
  buildProtonMailDesktop,
}:

buildProtonMailDesktop {
  version = "1.9.0";

  rev = "release/inbox-desktop@1.9.0";
  srcHash = "sha256-FZrvM4IPqRwp5/g6Bsaeu8y1MctlLIJ+pYz6RWikO8w=";

  missingHashes = ./missing-hashes.json;
  yarnOfflineCacheHash = "sha256-IIxgYuAtpuDya+KJWDM28xMfRzrhjrKkkxX+Bq9q1zo=";
}
