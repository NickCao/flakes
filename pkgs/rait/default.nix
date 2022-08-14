{ source, buildGoModule, lib }:

buildGoModule rec {
  inherit (source) pname version src vendorSha256;

  subPackages = [ "cmd/rait" ];

  meta = with lib; {
    description = "Redundant Array of Inexpensive Tunnels";
    homepage = "https://gitlab.com/NickCao/RAIT";
    license = licenses.asl20;
  };
}
