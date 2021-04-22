{ source, buildGoModule, fetchFromGitHub, lib }:
buildGoModule rec {
  inherit (source) pname version src;
  vendorSha256 = null;
  doCheck = false;
  subPackages = [ "." ];
  meta = with lib; {
    description = "a tool for building and deploying Golang applications to Kubernetes";
    homepage = "https://github.com/google/ko";
    license = licenses.asl20;
  };
}
