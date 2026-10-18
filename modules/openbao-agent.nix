{ lib, pkgs, ... }:
{
  lib.openbao.mkAgent =
    { role, tokenPath, destination, contents }:
    ''
      ${lib.getExe' pkgs.spire "spire-agent"} api fetch jwt \
        -audience openbao \
        -socketPath /run/spire/agent/public/api.sock \
        -output json | ${lib.getExe pkgs.jq} -r '.[0].svids.[0].svid' \
        > ${tokenPath}
      ${lib.getExe pkgs.openbao} agent -exit-after-auth \
        -config ${pkgs.writeText "${role}-openbao-agent.hcl" ''
          vault {
            address = "http://127.0.0.1:8200"
          }
          auto_auth {
            method "jwt" {
              mount_path = "auth/spiffe"
              config {
                path = "${tokenPath}"
                role = "${role}"
              }
            }
          }
          template_config {
            exit_on_retry_failure = true
          }
          template {
            error_on_missing_key = true
            perms = "0600"
            contents = <<EOT
          ${lib.removeSuffix "\n" contents}
          EOT
            destination = "${destination}"
          }
        ''}
    '';
}
