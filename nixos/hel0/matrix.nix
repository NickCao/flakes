{ config, lib, pkgs, ... }:
{
  sops = {
    secrets = {
      mautrix-telegram = { };
      matrix = { };
      matterbridge = { };
    };
  };

  boot.kernel.sysctl."net.ipv6.ip_nonlocal_bind" = 1;

  services.postgresql.authentication = ''
    local dendrite dendrite peer
    local mautrix-telegram mautrix-telegram peer
  '';

  systemd.services.dendrite.serviceConfig.LoadCredential = [
    "matrix:${config.sops.secrets.matrix.path}"
    "mautrix-telegram:/var/lib/mautrix-telegram/telegram-registration.yaml"
  ];

  cloud.services.element-web = {
    exec = "${pkgs.serve}/bin/serve -l 127.0.0.1:8005 -p ${pkgs.element-web}";
  };

  systemd.services.dendrite.after = [ "postgresql.service" ];
  services.dendrite =
    let
      database = {
        connection_string = "postgres:///dendrite?host=/run/postgresql";
        max_open_conns = 20;
      };
    in
    {
      enable = true;
      httpAddress = "127.0.0.1:8008";
      settings = {
        global = {
          server_name = "nichi.co";
          private_key = "/$CREDENTIALS_DIRECTORY/matrix";
          jetstream = {
            storage_path = "$STATE_DIRECTORY/nats";
          };
        };
        logging = [{
          type = "std";
          level = "warn";
        }];
        app_service_api = {
          inherit database;
          config_files = [
            "/$CREDENTIALS_DIRECTORY/mautrix-telegram"
          ];
        };
        client_api = {
          registration_disabled = true;
          rate_limiting.enabled = false;
        };
        media_api = {
          inherit database;
          max_file_size_bytes = 104857600;
          dynamic_thumbnails = true;
        };
        room_server = {
          inherit database;
        };
        push_server = {
          inherit database;
        };
        mscs = {
          inherit database;
          mscs = [ "msc2444" "msc2753" "msc2836" "msc2946" ];
        };
        sync_api = {
          inherit database;
          real_ip_header = "X-Real-IP";
        };
        key_server = {
          inherit database;
        };
        federation_api = {
          inherit database;
          key_perspectives = [{
            server_name = "matrix.org";
            keys = [
              {
                key_id = "ed25519:auto";
                public_key = "Noi6WqcDj0QmPxCNQqgezwTlBKrfqehY1u2FyWP9uYw";
              }
              {
                key_id = "ed25519:a_RXGa";
                public_key = "l8Hft5qXKn1vfHrg3p4+W8gELQVo8N13JkluMfmn2sQ";
              }
            ];
          }];
        };
        user_api = {
          account_database = database;
          device_database = database;
        };
      };
    };

  services.mautrix-telegram = {
    enable = true;
    environmentFile = config.sops.secrets.mautrix-telegram.path;
    serviceDependencies = [ "dendrite.service" ];
    settings = {
      homeserver = {
        address = "http://${config.services.dendrite.httpAddress}";
        domain = "nichi.co";
        enablePresence = false;
      };
      appservice = {
        address = "http://127.0.0.1:29317";
        database = "postgres:///mautrix-telegram?host=/run/postgresql";
        hostname = "127.0.0.1";
        port = 29317;
        provisioning.enabled = false;
      };
      bridge = {
        permissions = {
          "*" = "relaybot";
          "@nickcao:nichi.co" = "admin";
          "@lilydjwg:mozilla.org" = "admin";
        };
        displayname_template = "{displayname}";
        sync_create_limit = 0;
        delivery_error_reports = true;
        sync_direct_chats = true;
        inline_images = false;
        tag_only_on_create = false;
        bridge_matrix_leave = false;
        relay_user_distinguishers = [ ];
        state_event_formats = {
          join = "";
          leave = "";
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

  services.matterbridge = {
    enable = true;
    envFile = config.sops.secrets.matterbridge.path;
    settings = {
      gateway = [
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
              channel = "#telegram-archlinux-cn-offtopic:matrix.org";
            }
          ];
        }
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
              channel = "#telegram-archlinux-cn:matrix.org";
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
          UseSASL = true;
          NickServNick = "nichi_bot";
          NickServPassword = "$IRC_PASSWORD";
          UseTLS = true;
          IgnoreNicks = "HoroBot";
        };
      };
      matrix = {
        nichi = {
          Login = "matterbridge";
          Password = "$MATRIX_PASSWORD";
          RemoteNickFormat = "[{NICK}] ";
          Server = "https://matrix.nichi.co";
          IgnoreNicks = "寂しい賢狼ホロ";
        };
      };
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers = {
      matrix = {
        rule = "Host(`matrix.nichi.co`) && PathPrefix(`/_matrix`)";
        entryPoints = [ "https" ];
        service = "dendrite";
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
      dendrite.loadBalancer = {
        passHostHeader = true;
        servers = [{ url = "http://${config.services.dendrite.httpAddress}"; }];
      };
    };
  };
}
