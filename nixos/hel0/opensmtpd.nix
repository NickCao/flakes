{ config, lib, pkgs, ... }:
let
  aliases = builtins.toFile "aliases" ''
    postmaster nickcao
    hostmaster nickcao
    noc nickcao
  '';
in
{
  sops.secrets = {
    controller = {
      owner = "rspamd";
    };
    dkim = {
      owner = "rspamd";
      path = "/var/lib/rspamd/dkim.key";
    };
  };
  systemd.services.opensmtpd = {
    serviceConfig = {
      PrivateTmp = true;
      ExecStartPre = ''
        ${pkgs.openssl}/bin/openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout /tmp/selfsigned.key -out /tmp/selfsigned.crt -batch
      '';
    };
  };
  services.opensmtpd = {
    enable = true;
    serverConfiguration = ''
      table domains { "nichi.co", "nichi.link" }
      table aliases file:${aliases}

      pki selfsigned cert "/tmp/selfsigned.crt"
      pki selfsigned key "/tmp/selfsigned.key"

      filter "rspamd" proc-exec "${pkgs.opensmtpd-filter-rspamd}/bin/filter-rspamd"

      listen on enp41s0 tls pki "selfsigned" filter "rspamd"
      listen on lo port 587 filter "rspamd"

      action "delivery" lmtp "/run/dovecot2/lmtp" alias <aliases>
      action "outbound" relay helo hel0.nichi.link

      match from any for domain <domains> action "delivery"
      match from local for any action "outbound"
    '';
  };
  services.rspamd = {
    enable = true;
    workers = {
      controller = {
        bindSockets = [ "127.0.0.1:11334" ];
      };
      normal = {
        bindSockets = [ "127.0.0.1:11333" ];
      };
    };
    locals = {
      "worker-controller.inc".source = config.sops.secrets.controller.path;
      "redis.conf".text = ''
        servers = "127.0.0.1:${toString config.services.redis.servers.rspamd.port}";
      '';
      "actions.conf".text = ''
        reject = 15;
        add_header = 4;
        greylist = 3;
      '';
      "classifier-bayes.conf".text = ''
        autolearn = true;
      '';
      "dkim_signing.conf".text = ''
        path = "${config.sops.secrets.dkim.path}";
        selector = "default";
      '';
    };
  };
  boot.kernel.sysctl."vm.overcommit_memory" = 1;
  services.redis.servers.rspamd = {
    enable = true;
    port = 16380;
  };
  services.traefik = {
    dynamicConfigOptions = {
      http = {
        routers = {
          rspamd = {
            rule = "Host(`${config.networking.fqdn}`) && PathPrefix(`/rspamd`)";
            entryPoints = [ "https" ];
            service = "rspamd";
            middlewares = [ "rspamd" ];
          };
        };
        middlewares = {
          rspamd.stripPrefix = {
            prefixes = [ "/rspamd" ];
          };
        };
        services = {
          rspamd.loadBalancer.servers = [{
            url = "http://127.0.0.1:11334";
          }];
        };
      };
    };
  };
}
