{ source, buildGoModule }:
buildGoModule {
  inherit (source) pname version src vendorSha256;
}
