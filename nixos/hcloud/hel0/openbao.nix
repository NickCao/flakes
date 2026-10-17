{
  lib,
  config,
  utils,
  pkgs,
  ...
}:
{
  sops.secrets.openbao = {
    restartUnits = [ config.systemd.services.openbao.name ];
  };

  systemd.services.openbao = {
    restartIfChanged = lib.mkForce true; # auto unseal
    serviceConfig.LoadCredential = [
      "current_key:${config.sops.secrets.openbao.path}"
    ];
  };

  services.openbao = {
    enable = true;
    settings = {
      api_addr = "unix:///run/openbao/openbao.sock";
      disable_clustering = true;
      ui = true;
      listener.unix = {
        type = "unix";
        address = "/run/openbao/openbao.sock";
      };
      seal.static = {
        current_key_id = "1792247485"; # date "+%s"
        current_key = "file:///run/credentials/openbao.service/current_key";
      };
      storage.pebbledb = {
        path = "/var/lib/openbao";
      };
      initialize.spiffe.request = [
        {
          type = "enable-jwt";
          operation = "update";
          path = "sys/auth/spiffe";
          data = {
            type = "jwt";
          };
        }
        {
          type = "config-jwt";
          operation = "update";
          path = "auth/spiffe/config";
          data = {
            jwks_url = "http://127.0.0.1:7529/keys";
            skip_jwks_validation = true;
          };
        }
        {
          type = "admin-policy";
          operation = "update";
          path = "sys/policies/acl/admin";
          data.policy = ''
            path "*" {
              capabilities = [
                "create", "read", "update", "patch", "delete", "list", "sudo"
              ]
            }
          '';
        }
        {
          type = "admin-role";
          operation = "update";
          path = "auth/spiffe/role/admin";
          data = {
            role_type = "jwt";
            user_claim = "sub";
            bound_audiences = [ "openbao" ];
            bound_subject = "spiffe://nichi.link/nickcao";

            token_policies = [ "admin" ];
            token_ttl = "15m";
            token_max_ttl = "1h";
          };
        }
      ];
    };
  };

  cloud.ghostunnel.servers.spiffe-openbao = {
    listen = "[::]:9545";
    target = "unix:/run/openbao/openbao.sock";
    allowURIs = [ "spiffe://nichi.link/openbao-agent-proxy" ];
  };

  cloud.services.spiffe-openbao.config.User = "openbao";

  cloud.services.spire-oidc-discovery-provider.config = {
    ExecStart = utils.escapeSystemdExecArgs [
      (lib.getExe' pkgs.spire "oidc-discovery-provider")
      "-config"
      ((pkgs.formats.json { }).generate "spire-oidc-discovery-provider.json" {
        domains = [ "127.0.0.1" ];
        insecure_addr = "127.0.0.1:7529";
        allow_insecure_scheme = true;
        workload_api = {
          socket_path = "/run/spire/agent/public/api.sock";
          trust_domain = "nichi.link";
        };
      })
    ];
  };
}
