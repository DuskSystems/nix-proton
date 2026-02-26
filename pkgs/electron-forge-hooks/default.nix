{
  stdenv,
  electron,
  zip,
  makeSetupHook,
}:

let
  tags = {
    x86_64-linux = "linux-x64";
    armv7l-linux = "linux-armv7l";
    aarch64-linux = "linux-arm64";
    x86_64-darwin = "darwin-x64";
    aarch64-darwin = "darwin-arm64";
  };

  platform = tags."${stdenv.hostPlatform.system}" or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
{
  forgeConfigHook = makeSetupHook {
    name = "forge-config-hook";

    substitutions = {
      electronVersion = electron.version;
      electronPath = "${electron}/libexec/electron";
      zip = "${zip}/bin/zip";
      zipName = "electron-v${electron.version}-${platform}.zip";
    };
  } ./forge-config-hook.sh;
}
