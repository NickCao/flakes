{ config, lib, pkgs, ... }:
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
      hydra = { group = "hydra"; mode = "0440"; };
      hydra-github = { group = "hydra"; mode = "0440"; };
      carinae = { };
      canopus = { };
      plct = { owner = "hydra-queue-runner"; };
      vault = { };
      tsig = { sopsFile = ../../modules/dns/secondary/secrets.yaml; owner = "knot"; };
      gravity = { owner = "knot"; sopsFile = ./zones.yaml; };
      gravity_reverse = { owner = "knot"; sopsFile = ./zones.yaml; };
    };
  };

  services.gateway.enable = true;
  services.sshcert.enable = true;
  services.metrics.enable = true;

  services.libreddit = {
    enable = true;
    address = "127.0.0.1";
    port = 34123;
  };

  services.knot = {
    enable = true;
    keyFiles = [ config.sops.secrets.tsig.path ];
    extraConfig = builtins.readFile ./knot.conf + ''
      zone:
        - domain: firstparty
          template: catalog
        - domain: nichi.co
          file: ${pkgs."db.co.nichi"}
          dnssec-signing: off
          catalog-role: member
          catalog-zone: firstparty
        - domain: nichi.link
          file: ${pkgs."db.link.nichi"}
          catalog-role: member
          catalog-zone: firstparty
        - domain: scp.link
          file: ${pkgs."db.link.scp"}
          catalog-role: member
          catalog-zone: firstparty
        - domain: gravity
          file: ${config.sops.secrets.gravity.path}
          dnssec-signing: off
          catalog-role: member
          catalog-zone: firstparty
        - domain: 9.6.0.1.4.6.b.c.0.a.2.ip6.arpa
          file: ${config.sops.secrets.gravity_reverse.path}
          catalog-role: member
          catalog-zone: firstparty
    '';
  };

  services.hydra = {
    enable = true;
    listenHost = "127.0.0.1";
    hydraURL = "https://hydra.nichi.co";
    useSubstitutes = true;
    notificationSender = "hydra@nichi.co";
    buildMachinesFiles = [ "/etc/nix/machines" ];
    extraConfig = ''
      include ${config.sops.secrets.hydra.path}
      github_client_id = e55d265b1883eb42630e
      github_client_secret_file = ${config.sops.secrets.hydra-github.path}
      max_output_size = ${builtins.toString (32 * 1024 * 1024 * 1024)}
      <dynamicruncommand>
        enable = 1
      </dynamicruncommand>
      <githubstatus>
        jobs = misc:flakes:.*
        excludeBuildFromContext = 1
        useShortContext = 1
      </githubstatus>
    '';
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

  cloud.services.carinae.config = {
    ExecStart = "${pkgs.carinae}/bin/carinae -l 127.0.0.1:8004";
    EnvironmentFile = config.sops.secrets.carinae.path;
  };

  cloud.services.meow.config = {
    ExecStart = "${pkgs.meow}/bin/meow --listen 127.0.0.1:8002 --base-url https://pb.nichi.co --data-dir \${STATE_DIRECTORY}";
    StateDirectory = "meow";
    SystemCallFilter = null;
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

  systemd.services.postgresql.serviceConfig.TimeoutSec = pkgs.lib.mkForce 1200;

  services.traefik = {
    dynamicConfigOptions = {
      http = {
        routers = {
          libreddit = {
            rule = "Host(`red.nichi.co`)";
            entryPoints = [ "https" ];
            service = "libreddit";
          };
          meow = {
            rule = "Host(`pb.nichi.co`)";
            entryPoints = [ "https" ];
            service = "meow";
          };
          hydra = {
            rule = "Host(`hydra.nichi.co`)";
            entryPoints = [ "https" ];
            service = "hydra";
          };
          vault = {
            rule = "Host(`vault.nichi.co`)";
            entryPoints = [ "https" ];
            service = "vault";
          };
          cache = {
            rule = "Host(`cache.nichi.co`)";
            entryPoints = [ "https" ];
            service = "cache";
          };
        };
        middlewares = {
          compress.compress = { };
        };
        services = {
          libreddit.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://${config.services.libreddit.address}:${toString config.services.libreddit.port}"; }];
          };
          meow.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://127.0.0.1:8002"; }];
          };
          hydra.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://127.0.0.1:3000"; }];
          };
          vault.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://127.0.0.1:8003"; }];
          };
          cache.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://127.0.0.1:8004"; }];
          };
        };
      };
    };
  };
  documentation.nixos.enable = false;
}
