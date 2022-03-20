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
      minio.restartUnits = [ "minio.service" ];
      meow.restartUnits = [ "meow.service" ];
      vault = { };
      tsig = { sopsFile = ../../modules/dns/secondary/secrets.yaml; owner = "knot"; };
      gravity = { owner = "knot"; sopsFile = ./zones.yaml; };
      gravity_reverse = { owner = "knot"; sopsFile = ./zones.yaml; };
      srt = { };
    };
  };

  services.gateway.enable = true;
  services.sshcert.enable = true;
  services.metrics.enable = true;

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
    package = pkgs.hydra-unstable.override {
      nix = pkgs.nixVersions.stable.overrideAttrs (_: {
        patches = [
          (pkgs.fetchurl {
            url = "https://github.com/NixOS/nix/commit/33603df68144e124edc4f147d1a67884d131f5a4.patch";
            sha256 = "sha256-KJgMcjCjtgTRHxyhfLtKBej5Q9X5RVOEb2dTejJJEYk=";
          })
        ];
      });
    };
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
      <githubstatus>
        jobs = personal:flakes:.*
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

  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers.tagging = {
    image = "quay.io/numendacil/test:latest";
    extraOptions = [ "--network=slirp4netns" "--memory=4G" ];
    ports = [ "127.0.0.1:19000:8501" ];
  };

  cloud.services.carinae = {
    exec = "${pkgs.carinae}/bin/carinae -l 127.0.0.1:8004";
    envFile = config.sops.secrets.carinae.path;
  };

  cloud.services.meow = {
    exec = "${pkgs.meow}/bin/meow";
    envFile = config.sops.secrets.meow.path;
  };

  systemd.services.canopus.serviceConfig = {
    MemoryLimit = lib.mkForce "5G";
    SystemCallFilter = lib.mkForce null;
  };
  cloud.services.canopus = {
    exec = "${pkgs.python3.withPackages (ps: with ps;[ python-telegram-bot ])}/bin/python ${pkgs.writeText "canopus.py" ''
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
    envFile = config.sops.secrets.canopus.path;
  };

  cloud.services.srt-live-transmit = {
    exec = ''${pkgs.srt}/bin/srt-live-transmit \
              srt://[::]:5001?mode=listener&latency=2000&passphrase=''${PASSPHRASE} \
              srt://[::]:5002?mode=listener&latency=2000'';
    envFile = config.sops.secrets.srt.path;
  };

  services.minio = {
    enable = true;
    browser = false;
    listenAddress = "127.0.0.1:9000";
    rootCredentialsFile = config.sops.secrets.minio.path;
  };

  services.traefik = {
    dynamicConfigOptions = {
      http = {
        routers = {
          minio = {
            rule = "Host(`s3.nichi.co`)";
            entryPoints = [ "https" ];
            service = "minio";
          };
          meow = {
            rule = "Host(`pb.nichi.co`)";
            entryPoints = [ "https" ];
            service = "meow";
          };
          tagging = {
            rule = "Host(`tagging.nichi.co`)";
            entryPoints = [ "https" ];
            service = "tagging";
            middlewares = [ "compress" ];
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
          minio.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://${config.services.minio.listenAddress}"; }];
          };
          meow.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://127.0.0.1:8002"; }];
          };
          tagging.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://127.0.0.1:19000"; }];
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
