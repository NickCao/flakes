{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
let
  cfg = config.cloud.ghostunnel;
  commonOptions = {
    listen = lib.mkOption {
      type = lib.types.nonEmptyStr;
      description = "TCP, Unix socket, or systemd socket address to listen on.";
    };
    target = lib.mkOption {
      type = lib.types.nonEmptyStr;
      description = "Address to forward connections to.";
    };
  };
  mkServices =
    mode:
    lib.mapAttrs (
      _: tunnel: {
        config.ExecStart = utils.escapeSystemdExecArgs (
          [
            (lib.getExe pkgs.ghostunnel)
            mode
            "--shutdown-timeout=5s"
            "--use-workload-api-addr=unix:///run/spire/agent/public/api.sock"
            "--listen=${tunnel.listen}"
            "--target=${tunnel.target}"
          ]
          ++ (
            if mode == "server" then
              map (uri: "--allow-uri=${uri}") tunnel.allowURIs
            else
              [ "--verify-uri=${tunnel.verifyURI}" ]
          )
        );
      }
    );
in
{
  options.cloud.ghostunnel = {
    servers = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = commonOptions // {
            allowURIs = lib.mkOption {
              type = lib.types.nonEmptyListOf lib.types.nonEmptyStr;
              description = "SPIFFE IDs allowed to connect.";
            };
          };
        }
      );
    };
    clients = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = commonOptions // {
            verifyURI = lib.mkOption {
              type = lib.types.nonEmptyStr;
              description = "Expected server SPIFFE ID.";
            };
          };
        }
      );
    };
  };

  config.cloud.services = lib.mkMerge [
    (mkServices "server" cfg.servers)
    (mkServices "client" cfg.clients)
  ];
}
