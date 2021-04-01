{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "butane";
  version = "2021-02-01";

  src = fetchFromGitHub {
    owner = "coreos";
    repo = "butane";
    rev = "91961d1cd38fb15e26605f0e96e597f62143ffb1"; # tags/v*
    sha256 = "0gxaj2fy889fl5vhb4s89rhih9a65aqjsz2yffhi5z4fa2im8szv";
  };

  vendorSha256 = null;

  subPackages = [ "internal" ];
  postInstall = ''
    mv $out/bin/internal $out/bin/butane
  '';

  meta = with lib; {
    description = "Butane translates human-readable Butane Configs into machine-readable Ignition Configs";
    homepage = "https://coreos.github.io/butane";
    license = licenses.asl20;
  };
}
