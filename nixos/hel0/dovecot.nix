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
    mailUser = "dovemail";
    mailGroup = "dovemail";
    configFile = pkgs.writeText "dovecot.conf" ''
      listen = 127.0.0.1
      haproxy_trusted_networks = 127.0.0.1/8
      protocols = imap submission lmtp
      ssl = no

      default_internal_user  = ${cfg.user}
      default_internal_group = ${cfg.group}
      disable_plaintext_auth = no
      auth_username_format   = %Ln

      submission_relay_host    = 127.0.0.1
      submission_relay_port    = 587
      submission_relay_trusted = yes

      mail_location = maildir:${maildir}/%u
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
    '';
  };
}
