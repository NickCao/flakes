{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "ko";
  version = "2021-04-10";

  src = fetchFromGitHub {
    owner = "google";
    repo = "ko";
    rev = "d4987345562115ab5b8985301d1f89bf70c91966"; # tags/v*
    sha256 = "sha256-Ogd7rnmk1CIh5smKLFKlJ77ccWXibBMR6+sa9jipElc=";
  };

  vendorSha256 = null;
  doCheck = false;
  subPackages = [ "." ];

  meta = with lib; {
    description = "a tool for building and deploying Golang applications to Kubernetes";
    homepage = "https://github.com/google/ko";
    license = licenses.asl20;
  };
}
