{ config, pkgs, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
    secrets = {
      restic = { };
      backup = { };
      canopus = { };
      vault = { };
    };
  };

  services.gateway.enable = true;
  services.sshcert.enable = true;
  services.metrics.enable = true;

  systemd.tmpfiles.rules = [ "d /data/download 0770 download download - -" ];
  users.groups.download = { };
  users.users.download = { isSystemUser = true; group = "download"; };
  cloud.services.qbittorrent-nox.config = {
    ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --webui-port=1999 --profile=/data/download";
    User = "download";
    Group = "download";
    BindPaths = [ "/data/download" ];
    MemoryLimit = "10G";
  };

  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.nichi.co";
      listen-http = "127.0.0.1:8008";
      behind-proxy = true;
    };
  };

  services.vaultwarden = {
    enable = true;
    config = {
      signupsAllowed = false;
      sendsAllowed = false;
      emergencyAccessAllowed = false;
      orgCreationUsers = "none";
      domain = "https://vault.nichi.co";
      rocketAddress = "127.0.0.1";
      rocketPort = 8003;
    };
    environmentFile = config.sops.secrets.vault.path;
  };

  cloud.services.blog.config = {
    ExecStart = "${pkgs.serve}/bin/serve -l 127.0.0.1:8007 -p ${pkgs.blog}";
  };

  cloud.services.canopus.config = {
    MemoryLimit = "5G";
    SystemCallFilter = null;
    ExecStart = "${pkgs.python3.withPackages (ps: with ps;[ python-telegram-bot ])}/bin/python ${pkgs.writeText "canopus.py" ''
      from telegram.ext import Updater
      from telegram import Update
      from telegram.ext import CallbackContext
      from telegram.ext import CommandHandler
      import subprocess
      import os
      updater = Updater(token=os.environ['BOT_TOKEN'])
      dispatcher = updater.dispatcher
      def eval(update: Update, context: CallbackContext):
          expr = "with import <nixpkgs> {};" + update.message.text.split(maxsplit=1)[-1]
          try:
              res = subprocess.run(["${pkgs.canopus}/bin/canopus", "${pkgs.nixpkgs}", expr], capture_output=True, timeout=5)
              context.bot.send_message(chat_id=update.effective_chat.id, text=res.stdout.decode("utf-8"))
          except Exception as e:
              context.bot.send_message(chat_id=update.effective_chat.id, text="evaluation timed out")
      dispatcher.add_handler(CommandHandler('eval', eval))
      updater.start_polling()
    ''}";
    EnvironmentFile = config.sops.secrets.canopus.path;
  };

  services.traefik = {
    dynamicConfigOptions = {
      http = {
        routers = {
          vault = {
            rule = "Host(`vault.nichi.co`)";
            entryPoints = [ "https" ];
            service = "vault";
          };
          blog = {
            rule = "Host(`nichi.co`)";
            entryPoints = [ "https" ];
            middlewares = [ "blog" ];
            service = "blog";
          };
          ntfy = {
            rule = "Host(`ntfy.nichi.co`)";
            entryPoints = [ "https" ];
            service = "ntfy";
          };
        };
        middlewares = {
          blog.headers = {
            stsSeconds = 31536000;
            stsIncludeSubdomains = true;
            stsPreload = true;
          };
        };
        services = {
          vault.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://127.0.0.1:8003"; }];
          };
          blog.loadBalancer = {
            servers = [{ url = "http://127.0.0.1:8007"; }];
          };
          ntfy.loadBalancer = {
            servers = [{ url = "http://127.0.0.1:8008"; }];
          };
        };
      };
    };
  };

  documentation.nixos.enable = false;
}
