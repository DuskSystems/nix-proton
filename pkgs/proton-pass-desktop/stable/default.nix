{
  buildProtonPassDesktop,
}:

buildProtonPassDesktop {
  version = "1.31.5";

  rev = "proton-pass@1.31.5";
  srcHash = "sha256-QhKC3q0OWDCaYnQ0FZrS4eeCcI0T6QPK4vMAZ+pEwYE=";

  cargoVendorHash = "sha256-zdHAhCzLlw6rqDc6a5Kvx0pL/RsEjHaCRnhZv74XmUU=";

  missingHashes = ./missing-hashes.json;
  yarnOfflineCacheHash = "sha256-zdAKU8DEFbGQTWjKB3xs+MsUwI3ncRy4Xc2GjqXCOqY=";
}
