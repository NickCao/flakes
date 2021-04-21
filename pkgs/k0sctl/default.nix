{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "k0sctl";
  version = "2021-04-19";

  src = fetchFromGitHub {
    owner = "k0sproject";
    repo = "k0sctl";
    rev = "3bacbf5283ca5b7510c3157b7eb157d9a27d3bac"; # tags/v*
    sha256 = "1fj00y9zf7pwlpkk9djsqscwl68lsh8q6r5nr15f2rn45wfrvm1g";
  };

  vendorSha256 = "sha256-Cv8Huor4WdlPvfZkuyim1plM+afqbbig9F8oRQNyfRo=";
  subPackages = [ "." ];

  meta = with lib; {
    homepage = "https://github.com/k0sproject/k0sctl";
    license = licenses.asl20;
  };
}
