{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "fcct";
  version = "2021-02-01";

  src = fetchFromGitHub {
    owner = "coreos";
    repo = "fcct";
    rev = "91961d1cd38fb15e26605f0e96e597f62143ffb1"; # tags/v*
    sha256 = "0gxaj2fy889fl5vhb4s89rhih9a65aqjsz2yffhi5z4fa2im8szv";
  };

  vendorSha256 = null;

  subPackages = [ "internal" ];
  postInstall = ''
    mv $out/bin/internal $out/bin/fcct
  '';

  meta = with lib; {
    description = "Fedora CoreOS Config Transpiler";
    homepage = "https://coreos.github.io/fcct";
    license = licenses.gpl3Only;
  };
}
