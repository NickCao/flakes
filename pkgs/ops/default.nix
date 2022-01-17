{ source, buildGoModule, fetchFromGitLab, lib }:

buildGoModule rec {
  inherit (source) pname version src vendorSha256;

  subPackages = [ "." ];

  meta = with lib; {
    description = "ops - build and run nanos unikernels";
    homepage = "https://ops.city";
    license = licenses.mit;
  };
}
