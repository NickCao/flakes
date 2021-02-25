{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "ko";
  version = "2021-02-19";

  src = fetchFromGitHub {
    owner = "google";
    repo = "ko";
    rev = "a6442e66741f64627a95012194bfb7f022c05d61"; # tags/v*
    sha256 = "sha256-D8nwGW5vHLIwe9jpFFyxe1WckAcdJKrOeLHR25hsFiM=";
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
