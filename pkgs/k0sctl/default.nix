{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "k0sctl";
  version = "2021-03-31";

  src = fetchFromGitHub {
    owner = "k0sproject";
    repo = "k0sctl";
    rev = "410eca55cfefb632ae9443c91bbebb4c99969152"; # tags/v*
    sha256 = "19248jyx7kp0ibrzm7bj1zimaxc0zdc65h44hpmv67v7nm632wf6";
  };

  vendorSha256 = "sha256-DIrTDJp/VJzkjFdOkme95L7MqILIeyFEtVHYnsa5bks=";
  subPackages = [ "." ];

  meta = with lib; {
    homepage = "https://github.com/k0sproject/k0sctl";
    license = licenses.asl20;
  };
}
