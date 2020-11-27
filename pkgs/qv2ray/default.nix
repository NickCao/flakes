{ symlinkJoin, makeWrapper, libsForQt5, lib }:

let
  qv2ray = libsForQt5.callPackage ./qv2ray.nix { };
  ssr = libsForQt5.callPackage ./plugins/ssr.nix { };
in symlinkJoin {
  inherit (qv2ray) name meta;
  paths = [ qv2ray ssr ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/qv2ray --prefix XDG_DATA_DIRS : $out/share
  '';
}
