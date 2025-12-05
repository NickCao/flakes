{ config, pkgs, ... }:
let
  cfg = config.services.dovecot2;
  maildir = "/var/spool/mail";
in
{
  sops.secrets.dovecot = {
    owner = cfg.user;
    reloadUnits = [ "dovecot2.service" ];
  };

  systemd.tmpfiles.rules = [ "d ${maildir} 0700 ${cfg.mailUser} ${cfg.mailGroup} -" ];

  environment.systemPackages = [ pkgs.dovecot_pigeonhole ];

  services.dovecot2 = {
    enable = true;
    mailUser = "dovemail";
    mailGroup = "dovemail";
    sieve.extensions = [ "fileinto" ];
    sieve.scripts = {
      after = builtins.toFile "after.sieve" ''
        require "fileinto";
        if header :is "X-Spam" "Yes" {
            fileinto "Junk";
            stop;
        }
      '';
    };
    enableLmtp = true;
    enablePAM = false;
    enableDHE = false;
    mailPlugins.perProtocol.lmtp.enable = [ "sieve" ];
    mailLocation = "maildir:~";
    mailboxes = {
      Drafts = {
        auto = "subscribe";
        specialUse = "Drafts";
      };
      Sent = {
        auto = "subscribe";
        specialUse = "Sent";
      };
      Trash = {
        auto = "subscribe";
        specialUse = "Trash";
      };
      Junk = {
        auto = "subscribe";
        specialUse = "Junk";
      };
      Archive = {
        auto = "subscribe";
        specialUse = "Archive";
      };
    };
    pluginSettings = {
      sieve_after = "/var/lib/dovecot/sieve/after";
    };
    extraConfig = ''
      listen = 127.0.0.1
      haproxy_trusted_networks = 127.0.0.1/8

      auth_username_format   = %Ln

      mail_home = ${maildir}/%u

      passdb {
        driver = passwd-file
        args = ${config.sops.secrets.dovecot.path}
      }

      userdb {
        driver = static
        args = uid=${cfg.mailUser} gid=${cfg.mailGroup}
      }

      service imap-login {
        unix_listener imap-caddy {
          mode    = 0666
        }
        inet_listener imap {
          port = 0
        }
        inet_listener imaps {
          port = 0
        }
      }

      service auth {
        unix_listener auth-postfix {
          mode = 0660
          user = postfix
          group = postfix
        }
      }
    '';
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
