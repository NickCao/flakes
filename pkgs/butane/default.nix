{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "butane";
  version = "2021-04-05";

  src = fetchFromGitHub {
    owner = "coreos";
    repo = "butane";
    rev = "782fc8492b4ed2871ac8acd0f9a6e91c9477d846"; # tags/v*
    sha256 = "1s4rkq7mj1lyi8h47jyfy3qygfxhrmpihdy8rcnn55gcy04lm0qc";
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
