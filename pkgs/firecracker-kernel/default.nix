{ stdenv, lib, fetchurl, linuxManualConfig, linux_4_14, writeShellScriptBin, firecracker, firectl }:
linuxManualConfig {
  inherit stdenv lib;
  inherit (linux_4_14) version src;
  allowImportFromDerivation = true;
  configfile = fetchurl {
    url = "https://raw.githubusercontent.com/firecracker-microvm/firecracker/200c2db7055e406125729c40e14acf47024c1420/resources/microvm-kernel-x86_64.config";
    sha256 = "sha256-AEbQtRD7cWWJIzynEorT35wrfZrHnbSJ8a0wkC8wliE=";
  };
}
