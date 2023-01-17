{ config, pkgs, ... }:
let
  cfg = config.services.dovecot2;
  maildir = "/var/spool/mail";
in
{
  systemd.tmpfiles.rules = [
    "d ${maildir} 0700 ${cfg.mailUser} ${cfg.mailGroup} -"
  ];
  services.dovecot2 = {
    enable = true;
    modules = [ pkgs.dovecot_pigeonhole ];
    mailUser = "dovemail";
    mailGroup = "dovemail";
    sieveScripts = {
      after = builtins.toFile "after.sieve" ''
        require "fileinto";
        if header :is "X-Spam" "Yes" {
            fileinto "Junk";
            stop;
        }
      '';
    };
    configFile = pkgs.writeText "dovecot.conf" ''
      listen = 127.0.0.1
      haproxy_trusted_networks = 127.0.0.1/8
      protocols = imap lmtp
      ssl = no
      base_dir = /run/dovecot2

      default_internal_user  = ${cfg.user}
      default_internal_group = ${cfg.group}
      disable_plaintext_auth = no
      auth_username_format   = %Ln

      mail_home = ${maildir}/%u
      mail_location = maildir:~
      mail_uid=${cfg.mailUser}
      mail_gid=${cfg.mailGroup}

      passdb {
        driver = ldap
        args = ${pkgs.writeText "dovecot-ldap.conf" ''
          uris = ldap://127.0.0.1:3893
          base = dc=nichi
          auth_bind_userdn = cn=%u,dc=nichi
          auth_bind = yes
        ''}
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

      service auth {
        unix_listener auth-postfix {
          mode = 0660
          user = postfix
          group = postfix
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
        imap.address = ":993";
        submission.address = ":465";
        ldaps.address = ":636";
      };
    };
    dynamicConfigOptions = {
      tcp = {
        routers = {
          imap = {
            rule = "HostSNI(`${config.networking.fqdn}`)";
            entryPoints = [ "imap" ];
            service = "imap";
            tls.certResolver = "le";
          };
          submission = {
            rule = "HostSNI(`${config.networking.fqdn}`)";
            entryPoints = [ "submission" ];
            service = "submission";
            tls.certResolver = "le";
          };
          ldaps = {
            rule = "HostSNI(`ldap.nichi.co`)";
            entryPoints = [ "ldaps" ];
            service = "ldap";
            tls.certResolver = "le";
          };
        };
        services = {
          imap.loadBalancer = {
            proxyProtocol = { };
            servers = [{ address = "127.0.0.1:8143"; }];
          };
          submission.loadBalancer = {
            proxyProtocol = { };
            servers = [{ address = "127.0.0.1:587"; }];
          };
          ldap.loadBalancer = {
            servers = [{ address = "127.0.0.1:3893"; }];
          };
        };
      };
    };
  };
}
