{
  config,
  lib,
  utils,
  pkgs,
  ...
}:
{
  services.victorialogs = {
    enable = true;
    listenAddress = "127.0.0.1:9428";
  };

  cloud.services.spiffe-victorialogs.config = {
    ExecStart = utils.escapeSystemdExecArgs [
      (lib.getExe pkgs.ghostunnel)
      "server"
      "--use-workload-api-addr=unix:///run/spire/agent/public/api.sock"
      "--listen=[::]:9429"
      "--target=${config.services.victorialogs.listenAddress}"
      "--allow-uri=spiffe://nichi.link/systemd-journal-upload"
    ];
  };

  cloud.caddy.mtls = lib.singleton "logs.nichi.co";
  cloud.caddy.settings.apps.http.servers.default.routes = lib.singleton {
    match = lib.singleton {
      host = lib.singleton "logs.nichi.co";
    };
    handle = lib.singleton {
      handler = "reverse_proxy";
      upstreams = lib.singleton {
        dial = "${config.services.victorialogs.listenAddress}";
      };
    };
  };
}
