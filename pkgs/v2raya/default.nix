{ lib, fetchFromGitHub, mkYarnPackage, buildGo117Module, makeWrapper, v2ray }:
let
  pname = "v2raya";
  version = "48cc58d54727ea4beaadea5c0fb4150356809b72";
  src = fetchFromGitHub {
    owner = "SCP-2000";
    repo = "v2rayA";
    rev = version;
    sha256 = "sha256-lLXg4KkdbOx8Sw8CPIQBkYpFJ5cX3immP0XcXkxKu78=";
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
  vendorSha256 = "sha256-ALy3Co461N1MJpiEUnjOoNswY4TkE9W8nfeNRNLRyfQ=";
  subPackages = [ "." ];
  nativeBuildInputs = [ makeWrapper ];
  preBuild = ''
    cp -a ${web} server/router/web
  '';
  postInstall = ''
    wrapProgram $out/bin/v2rayA \
      --prefix PATH ":" "${lib.makeBinPath [ v2ray ]}"
  '';
  meta = with lib; {
    description = "A Linux web GUI client of Project V which supports V2Ray, Xray, SS, SSR, Trojan and Pingtunnel";
    homepage = "https://github.com/v2rayA/v2rayA";
    license = licenses.agpl3;
  };
}
