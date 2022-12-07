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
    sops.secrets.tsig = { sopsFile = ../../../zones/secrets.yaml; owner = "knot"; };
    services.knot = {
      enable = true;
      keyFiles = [ config.sops.secrets.tsig.path ];
      extraConfig = ''
        server:
          async-start: true
          tcp-reuseport: true
          tcp-fastopen: true
          edns-client-subnet: true
          listen: 0.0.0.0
          listen: ::

        log:
          - target: syslog
            any: info

        remote:
          - id: transfer
            address: ${data.nodes.iad0.ipv4}
            address: ${data.nodes.iad0.ipv6}
            key: transfer
          - id: cloudflare
            address: 1.1.1.1
            address: 1.0.0.1
            address: 2606:4700:4700::1111
            address: 2606:4700:4700::1001

        mod-dnsproxy:
          - id: cloudflare
            remote: cloudflare
            fallback: on
            address: 2a0c:b641:69c::/48
            address: 2001:470:4c22::/48

        template:
          - id: default
            global-module: mod-dnsproxy/cloudflare
          - id: member
            master: transfer

        zone:
          - domain: firstparty
            master: transfer
            catalog-role: interpret
            catalog-template: member
      '';
    };
  };
}
