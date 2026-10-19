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

          cert_dir = "${runtimeDir}"
          cert_file_mode = 0600
          svid_file_name = "svid.pem"
          svid_key_file_name = "svid_key.pem"
          svid_bundle_file_name = "svid_bundle.pem"

          jwt_svids = [{
            jwt_audience = "openbao"
            jwt_svid_file_name = "jwt_svid.token"
          }]
        ''}
      ${lib.getExe pkgs.openbao} agent -exit-after-auth \
        -config ${pkgs.writeText "${role}-openbao-agent.hcl" ''
          vault {
            address = "https://bao.nichi.co:9545"
            ca_cert = "${runtimeDir}/svid_bundle.pem"
            client_cert = "${runtimeDir}/svid.pem"
            client_key = "${runtimeDir}/svid_key.pem"
            tls_server_name = "openbao.nichi.link"
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
