{ config, pkgs, lib, ... }: {

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    settings = {
      max_connections = 100;
      shared_buffers = "2GB";
      effective_cache_size = "6GB";
      maintenance_work_mem = "512MB";
      checkpoint_completion_target = 0.9;
      wal_buffers = "16MB";
      default_statistics_target = 100;
      random_page_cost = 1.1;
      effective_io_concurrency = 200;
      work_mem = "5242kB";
      min_wal_size = "1GB";
      max_wal_size = "4GB";
      max_worker_processes = 4;
      max_parallel_workers_per_gather = 2;
      max_parallel_workers = 4;
      max_parallel_maintenance_workers = 2;
    };
  };

  services.postgresqlBackup = {
    enable = true;
    location = "/var/lib/backup/postgresql";
    compression = "zstd";
    startAt = "weekly";
  };

  sops = {
    secrets = {
      mautrix-telegram = { };
      matrix-synapse = { owner = "matrix-synapse"; };
      mjolnir = { owner = "mjolnir"; };
      matterbridge = { };
    };
  };

  systemd.services.mjolnir.after = [ "matrix-synapse.service" ];
  systemd.services.matrix-synapse.serviceConfig.LoadCredential = [
    "telegram:/var/lib/mautrix-telegram/telegram-registration.yaml"
  ];
  services.matrix-synapse = {
    enable = true;
    withJemalloc = true;
    settings = {
      server_name = "nichi.co";
      public_baseurl = "https://nichi.co";
      signing_key_path = config.sops.secrets.matrix-synapse.path;

      enable_search = true;
      dynamic_thumbnails = true;
      allow_public_rooms_over_federation = true;
      app_service_config_files = [ "/run/credentials/matrix-synapse.service/telegram" ];

      enable_registration = true;
      registration_requires_token = true;

      listeners = [{
        bind_addresses = [ "127.0.0.1" ];
        port = 8196;
        tls = false;
        type = "http";
        x_forwarded = true;
        resources = [{
          compress = true;
          names = [ "client" "federation" ];
        }];
      }];
    };
  };

  services.mjolnir = {
    enable = true;
    settings = {
      protectAllJoinedRooms = true;
    };
    managementRoom = "#moderators:nichi.co";
    homeserverUrl = "https://nichi.co";
    accessTokenFile = config.sops.secrets.mjolnir.path;
    pantalaimon.username = "mjolnir";
  };

  services.mautrix-telegram = {
    enable = true;
    environmentFile = config.sops.secrets.mautrix-telegram.path;
    serviceDependencies = [ "matrix-synapse.service" ];
    settings = {
      homeserver = {
        address = "http://127.0.0.1:8196";
        domain = "nichi.co";
      };
      appservice = {
        address = "http://127.0.0.1:29317";
        database = "postgres:///mautrix-telegram?host=/run/postgresql";
        hostname = "127.0.0.1";
        port = 29317;
        provisioning.enabled = false;
      };
      bridge = {
        displayname_template = "{displayname}";
        public_portals = true;
        delivery_error_reports = true;
        bridge_matrix_leave = false;
        relay_user_distinguishers = [ ];
        animated_sticker = {
          target = "webp";
          convert_from_webm = true;
        };
        state_event_formats = {
          join = "";
          leave = "";
          name_change = "";
        };
        permissions = {
          "*" = "relaybot";
          "@nickcao:nichi.co" = "admin";
          "@lilydjwg:mozilla.org" = "admin";
        };
      };
      telegram = {
        api_id = 611335;
        api_hash = "d524b414d21f4d37f08684c1df41ac9c";
        device_info = {
          app_version = "3.5.2";
        };
      };
      logging = {
        loggers = {
          mau.level = "WARNING";
          telethon.level = "WARNING";
        };
      };
    };
  };

  systemd.services.matterbridge.serviceConfig.EnvironmentFile = config.sops.secrets.matterbridge.path;
  services.matterbridge = {
    enable = true;
    configPath = toString ((pkgs.formats.toml { }).generate "config.toml" {
      gateway =
        let
          mkGateway = channel: {
            enable = true;
            name = channel;
            inout = [
              {
                account = "irc.libera";
                channel = "#${channel}";
              }
              {
                account = "matrix.nichi";
                channel = "#${channel}:nichi.co";
              }
            ];
          };
        in
        [
          (mkGateway "archlinux-cn")
          (mkGateway "archlinux-cn-offtopic")
          (mkGateway "archlinux-cn-game")
        ];
      irc = {
        libera = {
          ColorNicks = true;
          MessageDelay = 100;
          MessageLength = 400;
          MessageSplit = true;
          Nick = "nichi_bot";
          RealName = "bridge bot by nichi.co";
          RemoteNickFormat = "[{NICK}] ";
          Server = "irc.libera.chat:6697";
          NickServNick = "nichi_bot";
          UseTLS = true;
          UseSASL = true;
          Charset = "utf-8";
        };
      };
      matrix = {
        nichi = {
          Login = "matterbridge";
          RemoteNickFormat = "[{NICK}] ";
          Server = "https://nichi.co";
          HTMLDisable = true;
          KeepQuotedReply = true;
        };
      };
    });
  };

  services.traefik.dynamicConfigOptions.http = {
    routers = {
      matrix = {
        rule = "Host(`nichi.co`) && PathPrefix(`/_matrix`)";
        entryPoints = [ "https" ];
        service = "synapse";
      };
      synapse = {
        rule = "Host(`nichi.co`) && PathPrefix(`/_synapse`)";
        entryPoints = [ "https" ];
        service = "synapse";
      };
    };
    services = {
      synapse.loadBalancer = {
        passHostHeader = true;
        servers = [{ url = "http://127.0.0.1:8196"; }];
      };
    };
  };

}