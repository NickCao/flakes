{ config, pkgs, ... }:
let
  cfg = config.services.dovecot2;
  maildir = "/var/spool/mail";
in
{
  sops.secrets.dovecot = {
    owner = cfg.user;
  };
  systemd.tmpfiles.rules = [
    "d ${maildir} 0700 ${cfg.mailUser} ${cfg.mailGroup} -"
  ];
  services.dovecot2 = {
    enable = true;
    modules = [ pkgs.dovecot_pigeonhole ];
    mailUser = "dovemail";
    mailGroup = "dovemail";
    sieveScripts = {
      after = builtins.toFile "spam.sieve" ''
        require "fileinto";
        if header :is "X-Spam-Flag" "Yes" {
            fileinto "Junk";
            stop;
        }
      '';
    };
    configFile = pkgs.writeText "dovecot.conf" ''
      listen = 127.0.0.1
      haproxy_trusted_networks = 127.0.0.1/8
      protocols = imap submission lmtp
      ssl = no
      base_dir = /run/dovecot2

      default_internal_user  = ${cfg.user}
      default_internal_group = ${cfg.group}
      disable_plaintext_auth = no
      auth_username_format   = %Ln

      submission_relay_host    = 127.0.0.1
      submission_relay_port    = 587
      submission_relay_trusted = yes

      mail_home = ${maildir}/%u
      mail_location = maildir:~
      mail_uid=${cfg.mailUser}
      mail_gid=${cfg.mailGroup}

      passdb {
        driver = passwd-file
        args = ${config.sops.secrets.dovecot.path}
      }

      userdb {
        driver = static
        args = uid=${cfg.mailUser} gid=${cfg.mailGroup}
      }

      service imap-login {
        inet_listener imap {
          port    = 8143
          haproxy = yes
        }
        inet_listener imaps {
          port = 0
        }
      }

      service submission-login {
        inet_listener submission {
          port    = 8587
          haproxy = yes
        }
      }

      service lmtp {
        unix_listener lmtp-maddy {
          mode = 0600
          user = maddy
        }
      }

      protocol lmtp {
        mail_plugins = $mail_plugins sieve
      }

      namespace inbox {
        inbox = yes
        mailbox Drafts {
          auto = subscribe
          special_use = \Drafts
        }
        mailbox Sent {
          auto = subscribe
          special_use = \Sent
        }
        mailbox Trash {
          auto = subscribe
          special_use = \Trash
        }
        mailbox Junk {
          auto = subscribe
          special_use = \Junk
        }
        mailbox Archive {
          auto = subscribe
          special_use = \Archive
        }
      }

      plugin {
        sieve_after = /var/lib/dovecot/sieve/after
      }
    '';
  };
  services.traefik = {
    staticConfigOptions = {
      entryPoints = {
        imap = {
          address = ":993";
          http.tls.certResolver = "le";
        };
        submission = {
          address = ":465";
          http.tls.certResolver = "le";
        };
      };
    };
    dynamicConfigOptions = {
      tcp = {
        routers = {
          imap = {
            rule = "HostSNI(`${config.networking.fqdn}`)";
            entryPoints = [ "imap" ];
            service = "imap";
            tls = { };
          };
          submission = {
            rule = "HostSNI(`${config.networking.fqdn}`)";
            entryPoints = [ "submission" ];
            service = "submission";
            tls = { };
          };
        };
        services = {
          imap.loadBalancer = {
            proxyProtocol = { };
            servers = [{ address = "127.0.0.1:8143"; }];
          };
          submission.loadBalancer = {
            proxyProtocol = { };
            servers = [{ address = "127.0.0.1:8587"; }];
          };
        };
      };
    };
  };
}
