{ source, buildGoModule, lib, installShellFiles }:
buildGoModule rec {
  inherit (source) pname version src vendorSha256;
  postPatch = ''
    rm internal/courier/smtp_test.go
    rm internal/courier/mda_test.go
  '';
  postInstall = ''
    installManPage docs/man/*.1 docs/man/*.5
  '';
  excludedPackages = "\\(cmd/dovecot-auth-cli\\|cmd/spf-check\\)";
  nativeBuildInputs = [ installShellFiles ];
  outputs = [ "out" "man" ];
  meta = with lib; {
    description = "an SMTP (email) server with a focus on simplicity, security, and ease of operation.";
    homepage = "https://blitiri.com.ar/p/chasquid/";
    license = licenses.asl20;
  };
}
