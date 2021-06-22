{ source, buildGoModule, fetchFromGitHub, lib }:
buildGoModule rec {
  inherit (source) pname version src;
  vendorSha256 = "sha256-bsXXWyeZXZLV6igEvyvPpS92FruGiLDx/5CCTKPe0EU=";
  subPackages = [ "." ];
  meta = with lib; {
    homepage = "https://github.com/k0sproject/k0sctl";
    license = licenses.asl20;
  };
}
