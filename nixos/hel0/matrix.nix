{ config, pkgs, ... }:
{
  sops = {
    secrets = {
      mautrix-telegram = { };
      matrix-synapse = { owner = "matrix-synapse"; };
      mjolnir = { owner = "mjolnir"; };
      matterbridge = { };
    };
  };

  cloud.services.element-web.config =
    let
      conf = {
        default_server_config = {
          "m.homeserver" = {
            base_url = "https://nichi.co";
            server_name = "nichi.co";
          };
        };
        brand = "Nichi Yorozuya";
      };
    in
    {
      ExecStart = "${pkgs.serve}/bin/serve -l 127.0.0.1:8005 -p ${pkgs.element-web.override { inherit conf; }}";
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
      gateway = [
        {
          enable = true;
          name = "archlinux-cn";
          inout = [
            {
              account = "irc.libera";
              channel = "#archlinux-cn";
            }
            {
              account = "matrix.nichi";
              channel = "#archlinux-cn:nichi.co";
            }
          ];
        }
        {
          enable = true;
          name = "archlinux-cn-offtopic";
          inout = [
            {
              account = "irc.libera";
              channel = "#archlinux-cn-offtopic";
            }
            {
              account = "matrix.nichi";
              channel = "#archlinux-cn-offtopic:nichi.co";
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
      element = {
        rule = "Host(`matrix.nichi.co`)";
        entryPoints = [ "https" ];
        service = "element";
      };
    };
    services = {
      element.loadBalancer = {
        servers = [{ url = "http://127.0.0.1:8005"; }];
      };
      synapse.loadBalancer = {
        passHostHeader = true;
        servers = [{ url = "http://127.0.0.1:8196"; }];
      };
    };
  };
}
