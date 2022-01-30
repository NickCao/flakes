{ lib
, fetchFromGitHub
, mkYarnPackage
, buildGo117Module
, makeWrapper
, v2ray
, v2ray-geoip
, v2ray-domain-list-community
, symlinkJoin
}:
let
  pname = "v2raya";
  version = "48d7b5658beae6b76b21f1f09f9d5f2bd62af3d5";
  src = fetchFromGitHub {
    owner = "SCP-2000";
    repo = "v2rayA";
    rev = version;
    sha256 = "sha256-MO53mxQGbeMWrIGHTvwkl7DRfWeqP/Or+Hv0Jin22vQ=";
  };
  web = mkYarnPackage {
    inherit pname version;
    src = "${src}/gui";
    buildPhase = ''
      ln -s $src/postcss.config.js postcss.config.js
      OUTPUT_DIR=$out yarn --offline build
    '';
    distPhase = "true";
    dontInstall = true;
    dontFixup = true;
  };
in
buildGo117Module {
  inherit pname version;
  src = "${src}/service";
  vendorSha256 = "sha256-E3UAOaUo28Bztmsy1URr6VNAT7Ice3Gqlh47rnLcHWg=";
  subPackages = [ "." ];
  nativeBuildInputs = [ makeWrapper ];
  preBuild = ''
    cp -a ${web} server/router/web
  '';
  postInstall = ''
    wrapProgram $out/bin/v2rayA \
      --prefix PATH ":" "${lib.makeBinPath [ v2ray.core ]}" \
      --prefix XDG_DATA_DIRS ":" ${symlinkJoin {
        name = "assets";
        paths = [ v2ray-geoip v2ray-domain-list-community ];
      }}/share
  '';
  meta = with lib; {
    description = "A Linux web GUI client of Project V which supports V2Ray, Xray, SS, SSR, Trojan and Pingtunnel";
    homepage = "https://github.com/v2rayA/v2rayA";
    license = licenses.agpl3;
  };
}
