{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "k0sctl";
  version = "2021-03-11";

  src = fetchFromGitHub {
    owner = "k0sproject";
    repo = "k0sctl";
    rev = "57db32192b852671ee2f839f45e18d3cf0458142"; # tags/v*
    sha256 = "167763wd2j55k47ws7byvzcrdghv2scf4dmvasndk84k2y2qayml";
  };

  vendorSha256 = "sha256-DIrTDJp/VJzkjFdOkme95L7MqILIeyFEtVHYnsa5bks=";
  subPackages = [ "." ];

  meta = with lib; {
    homepage = "https://github.com/k0sproject/k0sctl";
    license = licenses.asl20;
  };
}
