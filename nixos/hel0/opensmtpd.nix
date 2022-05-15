{ config, lib, pkgs, ... }:
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
  services.postfix = {
    enable = true;
    hostname = config.networking.fqdn;
    networksStyle = "host";
    enableSubmission = true;
    enableSubmissions = false;
    mapFiles.senders = builtins.toFile "senders" ''
      nickcao@nichi.co nickcao
    '';
    config = {
      mydestination = "";
      disable_vrfy_command = true;
      virtual_transport = "lmtp:unix:/run/dovecot2/lmtp";
      virtual_mailbox_domains = [ "nichi.co" "nichi.link" ];
      lmtp_destination_recipient_limit = "1";
      milter_default_action = "accept";
      smtpd_milters = [ "inet:127.0.0.1:11332" ];
      non_smtpd_milters = [ "inet:127.0.0.1:11332" ];
    };
    submissionOptions = {
      smtpd_tls_security_level = "none";
      smtpd_sasl_auth_enable = "yes";
      smtpd_sasl_type = "dovecot";
      smtpd_sasl_path = "/run/dovecot2/auth-postfix";
      smtpd_sender_login_maps = "hash:/etc/postfix/senders";
      smtpd_client_restrictions = "permit_sasl_authenticated,reject";
      smtpd_sender_restrictions = "reject_sender_login_mismatch";
      smtpd_recipient_restrictions = "reject_non_fqdn_recipient,reject_unknown_recipient_domain,permit_sasl_authenticated,reject";
    };
    masterConfig = {
      "lmtp" = {
        args = [ "flags=O" ];
      };
    };
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
      rspamd_proxy = {
        bindSockets = [ "127.0.0.1:11332" ];
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
