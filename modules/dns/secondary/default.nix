{ config, lib, data, ... }:
with lib;
let
  cfg = config.services.dns.secondary;
in
{
  options.services.dns.secondary = {
    enable = mkEnableOption "secondary dns service";
  };
  config = mkIf cfg.enable {
    sops.secrets = {
      "quic/key" = {
        owner = config.systemd.services.knot.serviceConfig.User;
        restartUnits = [ "knot.service" ];
        sopsFile = ../../../zones/secrets.yaml;
      };
      "quic/cert" = {
        owner = config.systemd.services.knot.serviceConfig.User;
        restartUnits = [ "knot.service" ];
        sopsFile = ../../../zones/secrets.yaml;
      };
    };
    services.knot = {
      enable = true;
      settings = {
        server = {
          async-start = true;
          tcp-reuseport = true;
          tcp-fastopen = true;
          edns-client-subnet = true;
          automatic-acl = true;
          listen = [ "0.0.0.0" "::" ];
          listen-quic = [ "0.0.0.0" "::" ];
          key-file = config.sops.secrets."quic/key".path;
          cert-file = config.sops.secrets."quic/cert".path;
        };

        log = [{
          target = "syslog";
          any = "info";
        }];

        remote = [
          {
            id = "transfer";
            address = [
              data.nodes.iad0.ipv4
              data.nodes.iad0.ipv6
            ];
            quic = true;
            cert-key = "ZvTOnBFFp0WBMFOu62pjGrYVeBOQK3STxJu99C9BuGA=";
          }
          {
            id = "cloudflare";
            address = [
              "1.1.1.1"
              "1.0.0.1"
              "2606:4700:4700::1111"
              "2606:4700:4700::1001"
            ];
          }
        ];

        mod-dnsproxy = [{
          id = "cloudflare";
          remote = "cloudflare";
          fallback = true;
          address = [
            "2a0c:b641:69c::/48"
            "2001:470:4c22::/48"
          ];
        }];

        template = [
          {
            id = "default";
            global-module = "mod-dnsproxy/cloudflare";
          }
          {
            id = "member";
            master = "transfer";
            zonemd-verify = true;
          }
        ];

        zone = [{
          domain = "firstparty";
          master = "transfer";
          catalog-role = "interpret";
          catalog-template = "member";
        }];
      };
    };
  };
}
