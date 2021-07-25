{ source, buildGoModule, lib }:
buildGoModule rec {
  inherit (source) pname version src vendorSha256;
  excludedPackages = "integrationtest";
  meta = with lib; {
    description = "dump ACME data from traefik to certificates";
    homepage = "https://github.com/ldez/traefik-certs-dumper";
    license = licenses.asl20;
  };
}
