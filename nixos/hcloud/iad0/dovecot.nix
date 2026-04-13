{ config, pkgs, ... }:
let
  cfg = config.services.dovecot2;
  maildir = "/var/spool/mail";
in
{
  sops.secrets.dovecot = {
    owner = cfg.settings.default_internal_user;
    reloadUnits = [ "dovecot2.service" ];
  };

  systemd.tmpfiles.rules = [
    "d ${maildir} 0700 ${cfg.settings.mail_uid} ${cfg.settings.mail_gid} -"
  ];

  environment.systemPackages = [ pkgs.dovecot_pigeonhole ];

  services.dovecot2 = {
    enable = true;
    package = pkgs.dovecot;
    enablePAM = false;
    settings = {
      dovecot_config_version = "2.4.3";
      dovecot_storage_version = "2.4.0";

      auth_allow_cleartext = true; # TLS terminated by caddy
      auth_mechanisms = [
        "plain"
        "login"
      ];
      auth_username_format = "%{user | username | lower}";

      listen = "127.0.0.1";
      haproxy_trusted_networks = "127.0.0.1/8";
      ssl = false;

      mail_driver = "maildir";
      mail_uid = "dovemail";
      mail_gid = "dovemail";

      protocols = {
        imap = true;
        lmtp = true;
      };
      mail_home = "${maildir}/%{user}";
      mail_path = "~";
      "passdb passwd-file" = {
        driver = "passwd-file";
        passwd_file_path = config.sops.secrets.dovecot.path;
      };
      "userdb static" = {
        driver = "static";
        fields = {
          uid = cfg.settings.mail_uid;
          gid = cfg.settings.mail_gid;
        };
      };
      "namespace inbox" = {
        inbox = true;
        "mailbox Drafts" = {
          auto = "subscribe";
          special_use = "\\Drafts";
        };
        "mailbox Junk" = {
          auto = "subscribe";
          special_use = "\\Junk";
        };
        "mailbox Sent" = {
          auto = "subscribe";
          special_use = "\\Sent";
        };
        "mailbox Trash" = {
          auto = "subscribe";
          special_use = "\\Trash";
        };
        "mailbox Archive" = {
          auto = "subscribe";
          special_use = "\\Archive";
        };
      };
      "protocol lmtp" = {
        mail_plugins.sieve = true;
      };
      "sieve_script spam" = {
        sieve_script_type = "after";
        path = pkgs.writeText "spam.sieve" ''
          require "fileinto";
          if header :is "X-Spam" "Yes" {
              fileinto "Junk";
              stop;
          }
        '';
      };
      service = [
        {
          _section.name = "imap-login";
          "unix_listener imap-caddy".mode = 0666;
          "inet_listener imap".port = 0;
          "inet_listener imaps".port = 0;
        }
        {
          _section.name = "auth";
          "unix_listener auth-postfix" = {
            mode = 0660;
            user = "postfix";
            group = "postfix";
          };
        }
      ];
    };
  };

  systemd.sockets.caddy-imap = {
    socketConfig = {
      ListenStream = [ "993" ];
      Service = config.systemd.services.caddy.name;
    };
    wantedBy = [ "sockets.target" ];
  };

  systemd.sockets.caddy-submission = {
    socketConfig = {
      ListenStream = [ "465" ];
      Service = config.systemd.services.caddy.name;
    };
    wantedBy = [ "sockets.target" ];
  };

  cloud.caddy.settings.apps.layer4.servers = {
    imap = {
      listen = [ "fdname/${config.systemd.sockets.caddy-imap.name}" ];
      routes = [
        {
          handle = [
            {
              handler = "tls";
              connection_policies = [
                {
                  alpn = [ "imap" ];
                  match = {
                    sni = [ config.networking.fqdn ];
                  };
                }
              ];
            }
            {
              handler = "proxy";
              upstreams = [ { dial = [ "unix//run/dovecot2/imap-caddy" ]; } ];
            }
          ];
        }
      ];
    };
    submission = {
      listen = [ "fdname/${config.systemd.sockets.caddy-submission.name}" ];
      routes = [
        {
          handle = [
            {
              handler = "tls";
              connection_policies = [
                {
                  match = {
                    sni = [ config.networking.fqdn ];
                  };
                }
              ];
            }
            {
              handler = "proxy";
              upstreams = [ { dial = [ "127.0.0.1:587" ]; } ];
              proxy_protocol = "v2";
            }
          ];
        }
      ];
    };
  };
}
