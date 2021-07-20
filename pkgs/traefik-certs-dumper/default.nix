{ source, buildGoModule, lib }:
buildGoModule rec {
  inherit (source) pname version src;
  vendorSha256 = "sha256-Z2+Eo6ZBL5z88k64B5HfQ9WT4/gOypw797M3PnYoNzQ=";
  excludedPackages = "integrationtest";
  meta = with lib; {
    description = "dump ACME data from traefik to certificates";
    homepage = "https://github.com/ldez/traefik-certs-dumper";
    license = licenses.asl20;
  };
}
