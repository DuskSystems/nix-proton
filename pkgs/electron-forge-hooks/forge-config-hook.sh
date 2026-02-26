forgeConfigHook() {
  CONFIG_FILE=$1
  if [[ -z "$CONFIG_FILE" || ! -f "$CONFIG_FILE" ]]; then
    exit 1
  fi

  export ELECTRON_CUSTOM_VERSION="@electronVersion@"
  ZIP_NAME="@zipName@"
  ZIP_HASH=$(echo -n "https://github.com/electron/electron/releases/download/v$ELECTRON_CUSTOM_VERSION" | sha256sum | cut -d ' ' -f 1)

  if [[ ! -d "$XDG_CACHE_HOME" ]]; then
    export XDG_CACHE_HOME="$(mktemp -d)"
  fi

  CACHE_DIR="$XDG_CACHE_HOME/electron/$ZIP_HASH"
  mkdir -p "$CACHE_DIR"

  ELECTRON_TMP=$(mktemp -d)
  cp -r @electronPath@/* $ELECTRON_TMP
  chmod -R u+w $ELECTRON_TMP

  (cd "$ELECTRON_TMP" && @zip@ -r "$CACHE_DIR/$ZIP_NAME" .)
  chmod 644 "$CACHE_DIR/$ZIP_NAME"

  ZIP_CHECKSUM=$(sha256sum "$CACHE_DIR/$ZIP_NAME" | cut -d ' ' -f 1)
  substituteInPlace "$CONFIG_FILE" \
    --replace-fail "packagerConfig: {" "packagerConfig: { download: { checksums: { \"$ZIP_NAME\": \"$ZIP_CHECKSUM\" } },"
}
