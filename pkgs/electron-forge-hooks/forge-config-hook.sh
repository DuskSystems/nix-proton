forgeConfigHook() {
  echo "Executing forgeConfigHook"

  CONFIG_FILE=$1
  if [ -z "$CONFIG_FILE" ]; then
    echo "Error: No forge config file specified" >&2
    echo "Usage: forgeConfigHook <path/to/forge.config.js>" >&2
    exit 1
  fi

  if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Forge config file not found: $CONFIG_FILE" >&2
    echo "Usage: forgeConfigHook <path/to/forge.config.js>" >&2
    exit 1
  fi

  export ELECTRON_CUSTOM_VERSION="@electronVersion@"
  ZIP_NAME="@zipName@"
  ZIP_HASH=$(echo -n "https://github.com/electron/electron/releases/download/v$ELECTRON_CUSTOM_VERSION" | sha256sum | cut -d ' ' -f 1)

  if [ ! -d "$XDG_CACHE_HOME" ]; then
    export XDG_CACHE_HOME="$(mktemp -d)"
    mkdir -p "$XDG_CACHE_HOME"
  fi

  CACHE_DIR="$XDG_CACHE_HOME/electron/$ZIP_HASH"
  mkdir -p "$CACHE_DIR"

  ELECTRON_TMP=$(mktemp -d)
  cp -r @electronPath@/* $ELECTRON_TMP
  chmod -R u+w $ELECTRON_TMP

  (cd "$ELECTRON_TMP" && zip -r "$CACHE_DIR/$ZIP_NAME" .)
  chmod 644 "$CACHE_DIR/$ZIP_NAME"

  ZIP_CHECKSUM=$(sha256sum "$CACHE_DIR/$ZIP_NAME" | cut -d ' ' -f 1)
  substituteInPlace "$CONFIG_FILE" \
    --replace-fail "packagerConfig: {" "packagerConfig: { download: { checksums: { \"$ZIP_NAME\": \"$ZIP_CHECKSUM\" } },"

  echo "Finished forgeConfigHook"
}
