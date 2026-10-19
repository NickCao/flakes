{ lib, pkgs, ... }:
{
  lib.openbao.mkAgent =
    {
      role,
      runtimeDir,
      templates,
    }:
    ''
      ${lib.getExe pkgs.spiffe-helper} \
        -config ${pkgs.writeText "${role}-spiffe-helper.hcl" ''
          daemon_mode = false
          agent_address = "/run/spire/agent/public/api.sock"

          jwt_svids = [{
            jwt_audience = "openbao"
            jwt_svid_file_name = "${runtimeDir}/jwt_svid.token"
          }]
        ''}
      ${lib.getExe pkgs.openbao} agent -exit-after-auth \
        -config ${pkgs.writeText "${role}-openbao-agent.hcl" ''
          vault {
            address = "http://127.0.0.1:8200"
          }
          auto_auth {
            method "jwt" {
              mount_path = "auth/spiffe"
              config {
                path = "${runtimeDir}/jwt_svid.token"
                role = "${role}"
              }
            }
          }
          template_config {
            exit_on_retry_failure = true
          }
          ${lib.concatMapStringsSep "\n" (template: ''
            template {
              error_on_missing_key = true
              perms = "0600"
              contents = <<EOT
            ${lib.removeSuffix "\n" template.contents}
            EOT
              destination = "${template.destination}"
            }
          '') templates}
        ''}
    '';
}
