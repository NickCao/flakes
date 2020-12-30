{ stdenv, writeShellScriptBin, writeText, fetchurl, steam, dpkg, bubblewrap }:
let
  wechat-run = (steam.override {
    nativeOnly = true;
    extraPkgs = pkgs: [
      (stdenv.mkDerivation rec {
        pname = "wechat-wrapped";
        version = "2.0.0";

        src = fetchurl {
          url = "https://cdn-package-store6.deepin.com/appstore/pool/appstore/c/com.qq.weixin/com.qq.weixin_${version}_amd64.deb";
          sha256 = "0l5i3nvl241y4cwwv733b170bjqfipybm7ky277bhkm49jph808b";
        };

        phases = [ "installPhase" ];

        installPhase = ''
          ${dpkg}/bin/dpkg -x $src .
          mv usr/ $out/
          mv opt/apps/com.qq.weixin/ $out/share/
        '';
      })
    ];
  }).run;

  lsb-release = writeText "lsb-release" ''
    DISTRIB_ID=uos
    DISTRIB_RELEASE=20
    DISTRIB_DESCRIPTION=UnionTech OS 20
    DISTRIB_CODENAME=eagle 
  '';
  os-release = writeText "os-release" ''
    PRETTY_NAME=UnionTech OS Desktop 20 Pro
    NAME=uos
    VERSION_ID=20
    VERSION=20
    ID=uos
    HOME_URL=https://www.chinauos.com/
    BUG_REPORT_URL=http://bbs.chinauos.com
    VERSION_CODENAME=eagle
  '';
in
(writeShellScriptBin "wechat" ''
  ${wechat-run}/bin/steam-run ${bubblewrap}/bin/bwrap --dev-bind / / \
    --symlink ${os-release} /etc/os-release --symlink ${lsb-release} /etc/lsb-release \
    /usr/share/com.qq.weixin/files/wechat
'').overrideAttrs (attrs: { meta.only = stdenv.hostPlatform.isx86; })
