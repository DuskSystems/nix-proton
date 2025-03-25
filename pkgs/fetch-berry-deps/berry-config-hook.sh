berryConfigHook(){
    echo "Executing berryConfigHook"

    mkdir -p "$TMP/home"
    export HOME="$TMP/home"

    export YARN_ENABLE_TELEMETRY=0
    yarn config set enableGlobalCache false
    yarn config set enableScripts false
    yarn config set cacheFolder "$berryOfflineCache"
    yarn config set supportedArchitectures --json "$(cat @berrySupportedArchs@)"

    yarn install --immutable --immutable-cache
    patchShebangs node_modules

    echo "Finished berryConfigHook"
}

postConfigureHooks+=(berryConfigHook)
