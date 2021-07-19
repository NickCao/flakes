{ source, buildGoModule, lib }:
buildGoModule rec {
  inherit (source) pname version src;
  vendorSha256 = "sha256-1H1zTRzX6a4mBSHIJvLeVC9GIKE8qUvwbgfRw297vq4=";
  postPatch = ''
    rm internal/courier/smtp_test.go
    rm internal/courier/mda_test.go
  '';
  meta = with lib; {
    description = "an SMTP (email) server with a focus on simplicity, security, and ease of operation.";
    homepage = "https://blitiri.com.ar/p/chasquid/";
    license = licenses.asl20;
  };
}
