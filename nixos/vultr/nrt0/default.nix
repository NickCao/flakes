{ config, pkgs, ... }:
{

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.ranet.reloadUnits = [ "gravity.service" ];
  };

  services.gravity.config = config.sops.secrets.ranet.path;

  services.headscale = {
    enable = true;
    address = "127.0.0.1";
    port = 4953;
    settings = {
      server_url = "https://headscale.nichi.co";
      ephemeral_node_inactivity_timeout = "120s";
      prefixes = {
        allocation = "random";
      };
      dns.magic_dns = false;
      policy = {
        mode = "file";
        path = (pkgs.formats.json { }).generate "policy.json" {
          acls = [
            {
              action = "accept";
              src = [ "*" ];
              dst = [ "*:*" ];
            }
          ];
          tagOwners = {
            "tag:exit-node" = [
              "nickcao"
            ];
          };
          autoApprovers = {
            exitNode = [
              "tag:exit-node"
            ];
          };
        };
      };
    };
  };

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [ { host = [ "headscale.nichi.co" ]; } ];
      handle = [
        {
          handler = "reverse_proxy";
          upstreams = [ { dial = "127.0.0.1:${toString config.services.headscale.port}"; } ];
        }
      ];
    }
  ];

}
