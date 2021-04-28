{ source, buildGoModule, fetchFromGitHub, lib }:
buildGoModule rec {
  inherit (source) pname version src;
  vendorSha256 = "sha256-7fT1FZXiSPyEvlOwXOQlpR6g+izTnTRDK9A+CnVWOTA=";
  subPackages = [ "." ];
  meta = with lib; {
    homepage = "https://github.com/k0sproject/k0sctl";
    license = licenses.asl20;
  };
}
