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
in
{

  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    settings = {
      allow_alter_system = false;
      io_method = "io_uring";
      # https://pgtune.leopard.in.ua
      # DB Version: 18
      # OS Type: linux
      # DB Type: mixed
      # Total Memory (RAM): 8 GB
      # CPUs num: 4
      # Connections num: 100
      # Data Storage: ssd
      max_connections = 100;
      shared_buffers = "2GB";
      effective_cache_size = "6GB";
      maintenance_work_mem = "512MB";
      checkpoint_completion_target = 0.9;
      wal_buffers = "16MB";
      default_statistics_target = 100;
      random_page_cost = 1.1;
      effective_io_concurrency = 200;
      work_mem = "10082kB";
      huge_pages = "off";
      min_wal_size = "1GB";
      max_wal_size = "4GB";
      max_worker_processes = 4;
      max_parallel_workers_per_gather = 2;
      max_parallel_workers = 4;
      max_parallel_maintenance_workers = 2;
    };
    ensureUsers = [
      {
        name = "matrix-authentication-service";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [
      "matrix-authentication-service"
    ];
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
      matrix-synapse-s3 = {
        restartUnits = [ config.systemd.services.matrix-synapse.name ];
      };
      matterbridge = { };
      bouncer = {
        restartUnits = [ config.systemd.services.bouncer.name ];
      };
      "matrix-authentication-service/encryption" = { };
      "matrix-authentication-service/shared" = {
        owner = config.systemd.services.matrix-synapse.serviceConfig.User;
        restartUnits = [ config.systemd.services.matrix-synapse.name ];
      };
      "matrix-authentication-service/oidc-client-secret" = { };
      "matrix-authentication-service/keys/kwwU9cVvV2" = { };
      "matrix-authentication-service/keys/F3NNQzLmt4" = { };
      "matrix-authentication-service/keys/f6A0kQMjmd" = { };
      "matrix-authentication-service/keys/WNU225gZTr" = { };
    };
  };

  systemd.services.matrix-synapse.serviceConfig = {
    Environment = [
      "AWS_REQUEST_CHECKSUM_CALCULATION=when_required"
      "AWS_RESPONSE_CHECKSUM_VALIDATION=when_required"
    ];
    EnvironmentFile = [
      config.sops.secrets.matrix-synapse-s3.path
    ];
  };

  cloud.services.matrix-authentication-service.config =
    let
      configFile = (
        (pkgs.formats.yaml { }).generate "config.yaml" {
          http = {
            public_base = "https://matrix-auth.nichi.co/";
            issuer = "https://matrix-auth.nichi.co/";
            listeners = lib.singleton {
              name = "web";
              resources = [
                { name = "discovery"; }
                { name = "human"; }
                { name = "oauth"; }
                { name = "compat"; }
                { name = "graphql"; }
                { name = "assets"; }
              ];
              binds = lib.singleton {
                address = "127.0.0.1:${toString config.lib.ports.matrix-authentication-service}";
              };
            };
          };
          secrets = {
            encryption_file = "/run/credentials/matrix-authentication-service.service/encryption";
            keys = [
              {
                kid = "kwwU9cVvV2";
                key_file = "/run/credentials/matrix-authentication-service.service/key-kwwU9cVvV2";
              }
              {
                kid = "F3NNQzLmt4";
                key_file = "/run/credentials/matrix-authentication-service.service/key-F3NNQzLmt4";
              }
              {
                kid = "f6A0kQMjmd";
                key_file = "/run/credentials/matrix-authentication-service.service/key-f6A0kQMjmd";
              }
              {
                kid = "WNU225gZTr";
                key_file = "/run/credentials/matrix-authentication-service.service/key-WNU225gZTr";
              }
            ];
          };
          matrix = {
            kind = "synapse";
            homeserver = config.services.matrix-synapse.settings.server_name;
            secret_file = "/run/credentials/matrix-authentication-service.service/shared";
            endpoint = "http://127.0.0.1:${toString config.lib.ports.synapse}";
          };
          passwords = {
            enabled = true;
            schemes = [
              {
                version = 1;
                algorithm = "bcrypt";
                unicode_normalization = true;
              }
              {
                version = 2;
                algorithm = "argon2id";
              }
            ];
          };
          upstream_oauth2 = {
            providers = lib.singleton {
              synapse_idp_id = "oidc-keycloak";
              id = "01K34XRT1QHE1541KQ7HRRY15M";
              issuer = "https://id.nichi.co/realms/nichi";
              token_endpoint_auth_method = "client_secret_basic";
              client_id = "matrix-authentication-service";
              client_secret_file = "/run/credentials/matrix-authentication-service.service/oidc-client-secret";
              scope = "openid profile email";
              claims_imports = {
                localpart = {
                  action = "suggest";
                  template = "{{ user.preferred_username }}";
                };
                displayname = {
                  action = "suggest";
                  template = "{{ user.name }}";
                };
                email = {
                  action = "suggest";
                  template = "{{ user.email }}";
                  set_email_verification = "always";
                };
              };
            };
          };
        }
      );
      mas = [
        (lib.getExe pkgs.matrix-authentication-service)
        "--config"
        configFile
      ];
    in
    {
      MemoryDenyWriteExecute = false;
      LoadCredential = [
        "encryption:${config.sops.secrets."matrix-authentication-service/encryption".path}"
        "shared:${config.sops.secrets."matrix-authentication-service/shared".path}"
        "oidc-client-secret:${config.sops.secrets."matrix-authentication-service/oidc-client-secret".path}"
        "key-kwwU9cVvV2:${config.sops.secrets."matrix-authentication-service/keys/kwwU9cVvV2".path}"
        "key-F3NNQzLmt4:${config.sops.secrets."matrix-authentication-service/keys/F3NNQzLmt4".path}"
        "key-f6A0kQMjmd:${config.sops.secrets."matrix-authentication-service/keys/f6A0kQMjmd".path}"
        "key-WNU225gZTr:${config.sops.secrets."matrix-authentication-service/keys/WNU225gZTr".path}"
      ];
      ExecStartPre = [
        (lib.escapeShellArgs (
          mas
          ++ [
            "config"
            "check"
          ]
        ))
        (lib.escapeShellArgs (
          mas
          ++ [
            "config"
            "sync"
            "--prune"
          ]
        ))
      ];
      ExecStart = lib.escapeShellArgs (
        mas
        ++ [
          "server"
        ]
      );
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

      enable_authenticated_media = false;

      dynamic_thumbnails = true;
      allow_public_rooms_over_federation = true;
      url_preview_enabled = false;

      enable_registration = false;
      registration_requires_token = true;

      enable_local_media_storage = false;
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

      matrix_authentication_service = {
        enabled = true;
        endpoint = "http://127.0.0.1:${toString config.lib.ports.matrix-authentication-service}";
        secret_path = config.sops.secrets."matrix-authentication-service/shared".path;
      };

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
        # Remove legacy mentions
        msc4210_enabled = true;
        # MSC4293: Redact on Kick/Ban
        msc4293_enabled = true;
        # MSC4306: Thread Subscriptions
        # (and MSC4308: Thread Subscriptions extension to Sliding Sync)
        msc4306_enabled = true;
        # MSC4380: Invite blocking
        msc4380_enabled = true;
      };

      rc_admin_redaction = {
        per_second = 1000;
        burst_count = 10000;
      };

      rc_joins = {
        local = {
          per_second = 10000;
          burst_count = 10000;
        };
      };
    };
  };

  # systemd.services.mautrix-telegram.serviceConfig.RuntimeMaxSec = 3600;

  services.mautrix-telegram = {
    enable = true;
    environmentFile = config.sops.secrets.mautrix-telegram.path;
    serviceDependencies = [ config.systemd.services.matrix-synapse.name ];
    settings = {
      appservice = {
        address = "http://127.0.0.1:${toString config.lib.ports.mautrix-telegram}";
        hostname = "127.0.0.1";
        port = config.lib.ports.mautrix-telegram;

        username_template = "telegram_{{.}}";
        ephemeral_events = true;
        async_transactions = false;

        id = "telegram";
        bot = {
          username = "telegrambot";
          displayname = "Telegram bridge bot";
          avatar = "mxc://maunium.net/tJCRmUyJDsgRNgqhOgoiHWbX";
        };
      };
      backfill = {
        enabled = false;
        max_catchup_messages = 500;
        max_initial_messages = 50;
        queue = {
          batch_delay = 20;
          batch_size = 100;
          enabled = false;
          manual = false;
          max_batches = -1;
          max_batches_override = { };
        };
        threads = {
          max_initial_messages = 50;
        };
        unread_hours_threshold = 720;
      };
      bridge = {
        async_events = false;
        bridge_matrix_leave = false;
        bridge_notices = false;
        bridge_status_notices = "errors";
        cleanup_on_logout = {
          enabled = false;
          bad_credentials = {
            private = "nothing";
            relayed = "nothing";
            shared_has_users = "nothing";
            shared_no_users = "nothing";
          };
          manual = {
            private = "nothing";
            relayed = "nothing";
            shared_has_users = "nothing";
            shared_no_users = "nothing";
          };
        };
        command_prefix = "!tg";
        cross_room_replies = false;
        deduplicate_matrix_messages = false;
        enable_send_state_requests = false;
        kick_matrix_users = true;
        mute_only_on_create = true;
        no_bridge_info_state_key = false;
        only_bridge_tags = [
          "m.favourite"
          "m.lowpriority"
        ];
        permissions = {
          "*" = "relay";
          "@i:steamedfish.org" = "user";
          "@lilydjwg:mozilla.org" = "admin";
          "@nickcao:nichi.co" = "admin";
          "@mautrix:nichi.co" = "admin";
        };
        personal_filtering_spaces = false;
        phone_numbers_in_profile = false;
        portal_create_filter = {
          always_deny_from_login = [ ];
          list = [ ];
          mode = "deny";
        };
        private_chat_portal_meta = false;
        relay = {
          enabled = true;
          admin_only = true;
          allow_bridge = false;
          prefer_default = true;
          default_relays = [ 5296957089 ];
        };
        resend_bridge_info = false;
        revert_failed_state_changes = false;
        split_portals = false;
        tag_only_on_create = true;
        unknown_error_auto_reconnect = "5m";
        unknown_error_max_auto_reconnects = 10;
      };
      database = {
        max_conn_idle_time = null;
        max_conn_lifetime = null;
        max_idle_conns = 1;
        max_open_conns = 5;
        type = "postgres";
        uri = "postgres:///mautrix-telegram?host=/run/postgresql";
      };
      public_media.enabled = false;
      direct_media.enabled = false;
      double_puppet = {
        allow_discovery = false;
        secrets = { };
        servers = { };
      };
      encryption.allow = false;
      env_config_prefix = "MAUTRIX_TELEGRAM_";
      homeserver = {
        address = "http://127.0.0.1:${toString config.lib.ports.synapse}";
        async_media = true;
        domain = "nichi.co";
        message_send_checkpoint_endpoint = null;
        ping_interval_seconds = 0;
        software = "standard";
        status_endpoint = null;
        websocket = false;
      };
      logging = {
        min_level = "warn";
        writers = [
          {
            format = "pretty";
            type = "stdout";
          }
        ];
      };
      matrix = {
        delivery_receipts = false;
        federate_rooms = true;
        ghost_extra_profile_info = false;
        message_error_notices = true;
        message_status_events = false;
        sync_direct_chat_list = false;
        upload_file_threshold = 5242880;
      };
      network = {
        always_custom_emoji_reaction = false;
        always_tombstone_on_supergroup_migration = false;
        animated_sticker = {
          args = {
            fps = 25;
            height = 256;
            width = 256;
          };
          convert_from_webm = true;
          target = "webp";
        };
        api_hash = "d524b414d21f4d37f08684c1df41ac9c";
        api_id = 611335;
        contact_avatars = false;
        contact_names = false;
        device_info = {
          app_version = "auto";
          device_model = "mautrix-telegram";
          lang_code = "en";
          system_lang_code = "en";
          system_version = null;
        };
        disable_view_once = false;
        displayname_template = "{{ if .Deleted }}Deleted account {{ .UserID }}{{ else }}{{ .FullName }}{{ end }}";
        image_as_file_pixels = 16777216;
        max_member_count = -1;
        member_list = {
          max_initial_sync = 100;
          skip_deleted = true;
          sync_broadcast_channels = false;
        };
        ping = {
          interval_seconds = 30;
          timeout_seconds = 10;
        };
        saved_message_avatar = "mxc://maunium.net/XhhfHoPejeneOngMyBbtyWDk";
        sync = {
          create_limit = 15;
          direct_chats = true;
          login_sync_limit = 15;
          update_limit = 100;
        };
        takeout = {
          backward_backfill = false;
          dialog_sync = false;
          forward_backfill = false;
        };
      };
      provisioning = {
        allow_matrix_auth = false;
        debug_endpoints = false;
        enable_session_transfers = false;
        shared_secret = "disable";
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
            {
              enable = true;
              name = "MontageSubs";
              inout = [
                {
                  account = "irc.libera";
                  channel = "#MontageSubs";
                }
                {
                  account = "telegram.montagesubs";
                  channel = "-1002836409049";
                }
              ];
            }
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
        telegram = {
          montagesubs = {
            RemoteNickFormat = "{NICK} ";
            MessageFormat = "HTMLNick";
          };
        };
      }
    );
  };

  cloud.services.bouncer-anubis.config = {
    ExecStart = utils.escapeSystemdExecArgs [
      (lib.getExe pkgs.anubis)
      "-bind=127.0.0.1:${toString config.lib.ports.bouncer-anubis}"
      "-metrics-bind=127.0.0.1:${toString config.lib.ports.bouncer-anubis-metrics}"
      "-target=http://127.0.0.1:${toString config.lib.ports.bouncer}"
      "-serve-robots-txt"
      "-difficulty=4"
    ];
  };

  cloud.services.bouncer.unit.After = [ config.systemd.services.matrix-synapse.name ];
  cloud.services.bouncer.config = {
    ExecStart = utils.escapeSystemdExecArgs [
      (lib.getExe inputs.bouncer.packages.${pkgs.stdenv.hostPlatform.system}.default)
      "--listen-address"
      "127.0.0.1:${toString config.lib.ports.bouncer}"
    ];
    Environment = [ "RUST_LOG=warn" ];
    EnvironmentFile = [ config.sops.secrets.bouncer.path ];
  };

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [ { host = [ "bouncer.nichi.co" ]; } ];
      handle = [
        {
          handler = "reverse_proxy";
          upstreams = [ { dial = "127.0.0.1:${toString config.lib.ports.bouncer-anubis}"; } ];
        }
      ];
    }
    {
      match = [ { host = [ "matrix-auth.nichi.co" ]; } ];
      handle = lib.singleton {
        handler = "reverse_proxy";
        upstreams = [ { dial = "127.0.0.1:${toString config.lib.ports.matrix-authentication-service}"; } ];
      };
    }
    {
      match = [ { host = [ "matrix.nichi.co" ]; } ];
      handle = [
        {
          handler = "subroute";
          routes = [
            {
              match = lib.singleton {
                path_regexp.pattern = "^/_matrix/client/(.*)/(login|logout|refresh)";
              };
              handle = lib.singleton {
                handler = "reverse_proxy";
                upstreams = [ { dial = "127.0.0.1:${toString config.lib.ports.matrix-authentication-service}"; } ];
              };
            }
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
