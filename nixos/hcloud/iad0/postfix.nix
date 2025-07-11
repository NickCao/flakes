{
  config,
  lib,
  pkgs,
  ...
}:
let
  mkKeyVal = opt: val: [
    "-o"
    (opt + "=" + val)
  ];
  mkOpts = opts: lib.concatLists (lib.mapAttrsToList mkKeyVal opts);
in
{
  sops.secrets = {
    dkim-20230826 = {
      owner = config.services.rspamd.user;
      path = "/var/lib/rspamd/dkim.key";
    };
  };

  systemd.services.postfix.serviceConfig = {
    PrivateTmp = true;
    ExecStartPre = ''
      ${pkgs.openssl}/bin/openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout /tmp/selfsigned.key -out /tmp/selfsigned.crt -batch
    '';
  };

  services.postfix = {
    enable = true;
    hostname = config.networking.fqdn;
    mapFiles.senders = builtins.toFile "senders" ''
      nickcao@nichi.co      nickcao
    '';
    mapFiles.aliases = builtins.toFile "aliases" ''
      hostmaster@nichi.link nickcao@nichi.co
      hostmaster@nichi.co   nickcao@nichi.co
      postmaster@nichi.link nickcao@nichi.co
      postmaster@nichi.co   nickcao@nichi.co
      noc@nichi.co          nickcao@nichi.co
    '';
    config = {
      smtp_tls_security_level = "may";

      smtpd_tls_chain_files = [
        "/tmp/selfsigned.key"
        "/tmp/selfsigned.crt"
      ];
      smtpd_tls_security_level = "may";
      smtpd_relay_restrictions = [
        "permit_sasl_authenticated"
        "defer_unauth_destination"
      ];

      virtual_transport = "lmtp:unix:/run/dovecot2/lmtp";
      virtual_mailbox_domains = [
        "nichi.co"
        "nichi.link"
      ];
      virtual_alias_maps = "hash:/etc/postfix/aliases";

      lmtp_destination_recipient_limit = "1";
      recipient_delimiter = "+";
      disable_vrfy_command = true;

      milter_default_action = "accept";
      smtpd_milters = [ "unix:/run/rspamd/postfix.sock" ];
      non_smtpd_milters = [ "unix:/run/rspamd/postfix.sock" ];
      internal_mail_filter_classes = [ "bounce" ];
    };
    masterConfig = {
      lmtp = {
        args = [ "flags=O" ];
      };
      smtp = {
        args = [
          "-o"
          "inet_protocols=ipv4"
        ];
      };
      "127.0.0.1:submission" = {
        type = "inet";
        private = false;
        command = "smtpd";
        args = mkOpts {
          smtpd_tls_security_level = "none";
          smtpd_sasl_auth_enable = "yes";
          smtpd_sasl_type = "dovecot";
          smtpd_sasl_path = "/run/dovecot2/auth-postfix";
          smtpd_sender_login_maps = "hash:/etc/postfix/senders";
          smtpd_client_restrictions = "permit_sasl_authenticated,reject";
          smtpd_sender_restrictions = "reject_sender_login_mismatch";
          smtpd_recipient_restrictions = "reject_non_fqdn_recipient,reject_unknown_recipient_domain,permit_sasl_authenticated,reject";
          smtpd_upstream_proxy_protocol = "haproxy";
        };
      };
    };
  };

  services.rspamd = {
    enable = true;
    workers = {
      controller = {
        bindSockets = [ "localhost:11334" ];
      };
      rspamd_proxy = {
        bindSockets = [
          {
            mode = "0666";
            socket = "/run/rspamd/postfix.sock";
          }
        ];
      };
    };
    locals = {
      "worker-controller.inc".text = ''
        secure_ip = ["127.0.0.1", "::1"];
      '';
      "worker-proxy.inc".text = ''
        upstream "local" {
          self_scan = yes;
        }
      '';
      "redis.conf".text = ''
        servers = "127.0.0.1:${toString config.services.redis.servers.rspamd.port}";
      '';
      "classifier-bayes.conf".text = ''
        autolearn = true;
      '';
      "dkim_signing.conf".text = ''
        path = "${config.sops.secrets.dkim-20230826.path}";
        selector = "20230826";
        allow_username_mismatch = true;
        allow_envfrom_empty = true;
      '';
    };
  };

  services.redis.servers.rspamd = {
    enable = true;
    port = 16380;
  };
}
