{ config, lib, pkgs, ... }:
let
  domains = lib.concatStringsSep " " [ "nichi.co" "nichi.link" ];
in
{
  sops.secrets = {
    dkim.restartUnits = [ "maddy.service" ];
  };
  systemd.packages = [ pkgs.maddy ];
  environment.systemPackages = [ pkgs.maddy ];
  users.users.maddy.isSystemUser = true;
  users.users.maddy.group = "maddy";
  users.groups.maddy = { };
  environment.etc."maddy/maddy.conf".text = ''
    hostname ${config.networking.fqdn}
    autogenerated_msg_domain nichi.co
    tls off

    target.lmtp local_mailboxes {
        targets unix:///run/dovecot2/lmtp-maddy
    }

    smtp tcp://[::]:25 {
        tls self_signed
        source ${domains} {
            reject 501 5.1.8 "Use Submission for outgoing SMTP"
        }
        dmarc yes
        check {
            require_mx_record
            dkim
            spf {
                softfail_action quarantine
            }
            dnsbl zen.spamhaus.org
        }
        default_source {
            destination ${domains} {
                modify {
                    replace_rcpt static {
                        entry postmaster@nichi.co nickcao@nichi.co
                        entry hostmaster@nichi.co nickcao@nichi.co
                        entry noc@nichi.co nickcao@nichi.co
                    }
                }
                deliver_to &local_mailboxes
            }
            default_destination {
                reject 550 5.1.1 "User doesn't exist"
            }
        }
    }

    smtp tcp://127.0.0.1:587 {
        source ${domains} {
            destination ${domains} {
                deliver_to &local_mailboxes
            }
            default_destination {
                modify {
                    modify.dkim {
                        domains ${domains}
                        selector default
                        key_path {env:CREDENTIALS_DIRECTORY}/dkim.key
                    }
                }
                deliver_to &remote_queue
            }
        }
        default_source {
            reject 501 5.1.8 "Non-local sender domain"
        }
    }

    target.remote outbound_delivery {
    }

    target.queue remote_queue {
        target &outbound_delivery
        bounce {
            destination ${domains} {
                deliver_to &local_mailboxes
            }
            default_destination {
                reject 550 5.0.0 "Refusing to send DSNs to non-local addresses"
            }
        }
    }
  '';
  systemd.services.maddy = {
    wantedBy = [ "multi-user.target" ];
    restartTriggers = [ config.environment.etc."maddy/maddy.conf".source ];
    serviceConfig = {
      LoadCredential = [
        "dkim.key:${config.sops.secrets.dkim.path}"
      ];
    };
  };
}
