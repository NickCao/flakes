{ source, buildGoModule, fetchFromGitHub, lib }:
buildGoModule rec {
  inherit (source) pname version src;
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
