{
  config,
  pkgs,
  lib,
  utils,
  inputs,
  ...
}:
let
  conf = {
    default_server_config = {
      "m.homeserver" = {
        base_url = config.services.matrix-synapse.settings.public_baseurl;
        server_name = config.services.matrix-synapse.settings.server_name;
      };
    };
    show_labs_settings = true;
  };
  b2 = {
    endpoint = "https://s3.us-east-005.backblazeb2.com";
    bucket = "nichi-matrix";
  };
  inherit (config.services.matrix-synapse.settings) media_store_path;
in
{

  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
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
      matrix-synapse = {
        owner = config.systemd.services.matrix-synapse.serviceConfig.User;
      };
      matrix-synapse-oidc = {
        owner = config.systemd.services.matrix-synapse.serviceConfig.User;
      };
      matrix-synapse-s3 = {
        restartUnits = [ config.systemd.services.matrix-synapse.name ];
      };
      matterbridge = { };
      bouncer = {
        restartUnits = [ config.systemd.services.bouncer.name ];
      };
    };
  };

  systemd.timers.matrix-synapse-s3-upload = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      FixedRandomDelay = true;
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "4h";
    };
  };

  systemd.services.matrix-synapse-s3-upload.serviceConfig = {
    Type = "oneshot";
    inherit (config.systemd.services.matrix-synapse.serviceConfig) User Group;
    EnvironmentFile = [ config.sops.secrets.matrix-synapse-s3.path ];
    StateDirectory = [ "matrix-synapse-s3-upload" ];
    WorkingDirectory = "%S/matrix-synapse-s3-upload";
    BindReadOnlyPaths = [
      "${
        (pkgs.formats.yaml { }).generate "database.yaml" {
          postgres = {
            inherit (config.services.matrix-synapse.settings.database.args) database;
          };
        }
      }:%S/matrix-synapse-s3-upload/database.yaml"
    ];
    ExecStart = with config.services.matrix-synapse.package.plugins; [
      (utils.escapeSystemdExecArgs [
        (lib.getExe matrix-synapse-s3-storage-provider)
        "--no-progress"
        "update"
        # KeyError: 'password'
        # "--homeserver-config-path"
        # config.services.matrix-synapse.configFile
        media_store_path
        "1h"
      ])
      (utils.escapeSystemdExecArgs [
        (lib.getExe matrix-synapse-s3-storage-provider)
        "--no-progress"
        "upload"
        "--delete"
        "--endpoint-url"
        b2.endpoint
        media_store_path
        b2.bucket
      ])
    ];
  };

  systemd.services.matrix-synapse.serviceConfig = {
    LoadCredential = [
      "telegram:/var/lib/mautrix-telegram/telegram-registration.yaml"
    ];
    EnvironmentFile = [
      config.sops.secrets.matrix-synapse-s3.path
    ];
  };

  services.matrix-synapse = {
    enable = true;
    withJemalloc = true;
    plugins = with config.services.matrix-synapse.package.plugins; [
      matrix-synapse-s3-storage-provider
    ];
    settings = {
      server_name = "nichi.co";
      public_baseurl = "https://matrix.nichi.co";
      signing_key_path = config.sops.secrets.matrix-synapse.path;

      dynamic_thumbnails = true;
      allow_public_rooms_over_federation = true;
      app_service_config_files = [ "/run/credentials/matrix-synapse.service/telegram" ];

      enable_registration = true;
      registration_requires_token = true;

      media_storage_providers = [
        {
          module = "s3_storage_provider.S3StorageProviderBackend";
          store_local = true;
          store_remote = true;
          store_synchronous = true;
          config = {
            bucket = b2.bucket;
            endpoint_url = b2.endpoint;
          };
        }
      ];

      listeners = [
        {
          bind_addresses = [ "127.0.0.1" ];
          port = config.lib.ports.synapse;
          tls = false;
          type = "http";
          x_forwarded = true;
          resources = [
            {
              compress = true;
              names = [
                "client"
                "federation"
              ];
            }
          ];
        }
      ];

      media_retention = {
        remote_media_lifetime = "14d";
      };

      oidc_providers = [
        {
          idp_id = "keycloak";
          idp_name = "id.nichi.co";
          issuer = "https://id.nichi.co/realms/nichi";
          client_id = "synapse";
          client_secret_path = config.sops.secrets.matrix-synapse-oidc.path;
          scopes = [
            "openid"
            "profile"
          ];
          allow_existing_users = true;
          backchannel_logout_enabled = true;
          user_mapping_provider.config = {
            confirm_localpart = true;
            localpart_template = "{{ user.preferred_username }}";
            display_name_template = "{{ user.name }}";
          };
        }
      ];

      experimental_features = {
        # Room summary api
        msc3266_enabled = true;
        # Removing account data
        msc3391_enabled = true;
        # Thread notifications
        msc3773_enabled = true;
        # Remotely toggle push notifications for another client
        msc3881_enabled = true;
        # Remotely silence local notifications
        msc3890_enabled = true;
      };

      rc_admin_redaction = {
        per_second = 1000;
        burst_count = 10000;
      };
    };
  };

  systemd.services.mautrix-telegram.serviceConfig.RuntimeMaxSec = 86400;

  services.mautrix-telegram = {
    enable = true;
    environmentFile = config.sops.secrets.mautrix-telegram.path;
    serviceDependencies = [ config.systemd.services.matrix-synapse.name ];
    settings = {
      homeserver = {
        address = "http://127.0.0.1:${toString config.lib.ports.synapse}";
        domain = config.services.matrix-synapse.settings.server_name;
      };
      appservice = {
        address = "http://127.0.0.1:${toString config.lib.ports.mautrix-telegram}";
        database = "postgres:///mautrix-telegram?host=/run/postgresql";
        hostname = "127.0.0.1";
        port = config.lib.ports.mautrix-telegram;
        provisioning.enabled = false;
      };
      bridge = {
        displayname_template = "{displayname}";
        public_portals = true;
        delivery_error_reports = true;
        incoming_bridge_error_reports = true;
        bridge_matrix_leave = false;
        relay_user_distinguishers = [ ];
        create_group_on_invite = false;
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
          "@i:steamedfish.org" = "user";
        };
        relaybot = {
          authless_portals = false;
        };
      };
      telegram = {
        api_id = 611335;
        api_hash = "d524b414d21f4d37f08684c1df41ac9c";
        device_info = {
          app_version = "3.5.2";
        };
        force_refresh_interval_seconds = 3600;
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
    configPath = toString (
      (pkgs.formats.toml { }).generate "config.toml" {
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
            Server = config.services.matrix-synapse.settings.public_baseurl;
            HTMLDisable = true;
            KeepQuotedReply = true;
          };
        };
      }
    );
  };

  cloud.services.bouncer.config = {
    ExecStart = utils.escapeSystemdExecArgs [
      (lib.getExe inputs.bouncer.packages.${pkgs.system}.default)
      "--listen-address"
      "127.0.0.1:${toString config.lib.ports.bouncer}"
    ];
    EnvironmentFile = [ config.sops.secrets.bouncer.path ];
  };

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [ { host = [ "bouncer.nichi.co" ]; } ];
      handle = [
        {
          handler = "reverse_proxy";
          upstreams = [ { dial = "127.0.0.1:${toString config.lib.ports.bouncer}"; } ];
        }
      ];
    }
    {
      match = [ { host = [ "matrix.nichi.co" ]; } ];
      handle = [
        {
          handler = "subroute";
          routes = [
            {
              match = [
                {
                  path = [
                    "/_matrix/*"
                    "/_synapse/*"
                  ];
                }
              ];
              handle = [
                {
                  handler = "reverse_proxy";
                  upstreams = [ { dial = "127.0.0.1:${toString config.lib.ports.synapse}"; } ];
                }
              ];
            }
            {
              handle = [
                {
                  handler = "headers";
                  response.set = {
                    X-Frame-Options = [ "SAMEORIGIN" ];
                    X-Content-Type-Options = [ "nosniff" ];
                    X-XSS-Protection = [ "1; mode=block" ];
                    Content-Security-Policy = [ "frame-ancestors 'self'" ];
                  };
                }
                {
                  handler = "file_server";
                  root = "${pkgs.element-web.override { inherit conf; }}";
                }
              ];
            }
          ];
        }
      ];
    }
  ];
}
