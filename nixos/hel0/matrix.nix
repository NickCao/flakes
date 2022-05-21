{ config, lib, pkgs, ... }:
{
  sops = {
    secrets = {
      mautrix-telegram = { };
      matrix-synapse = { owner = "matrix-synapse"; };
      matrix = { };
      matterbridge = { };
    };
  };

  boot.kernel.sysctl."net.ipv6.ip_nonlocal_bind" = 1;

  services.postgresql.authentication = ''
    local dendrite dendrite peer
    local mautrix-telegram mautrix-telegram peer
    local matrix-synapse matrix-synapse peer
  '';

  cloud.services.element-web.config = {
    ExecStart = "${pkgs.serve}/bin/serve -l 127.0.0.1:8005 -p ${pkgs.element-web}";
  };

  systemd.services.matrix-synapse.serviceConfig.LoadCredential = [
    "telegram:/var/lib/mautrix-telegram/telegram-registration.yaml"
  ];
  services.matrix-synapse = {
    enable = true;
    settings = {
      app_service_config_files = [ "/run/credentials/matrix-synapse.service/telegram" ];
      listeners = [{
        bind_addresses = [ "127.0.0.1" ];
        port = 8196;
        resources = [
          {
            compress = true;
            names = [ "client" ];
          }
          {
            compress = false;
            names = [ "federation" ];
          }
        ];
        tls = false;
        type = "http";
        x_forwarded = true;
      }];
      server_name = "nichi.co";
      public_baseurl = "https://matrix.nichi.co";
      dynamic_thumbnails = true;
      signing_key_path = config.sops.secrets.matrix-synapse.path;
    };
  };

  services.mautrix-telegram = {
    enable = true;
    environmentFile = config.sops.secrets.mautrix-telegram.path;
    serviceDependencies = [ "matrix-synapse.service" ];
    settings = {
      homeserver = {
        address = "http://127.0.0.1:8196";
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
        sync_direct_chats = false;
        inline_images = false;
        tag_only_on_create = false;
        bridge_matrix_leave = false;
        relay_user_distinguishers = [ ];
        bridge_notices.default = true;
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
          Server = "irc.ipv4.libera.chat:6665";
          UseSASL = true;
          NickServNick = "nichi_bot";
          NickServPassword = "$IRC_PASSWORD";
          # temporary workaround for connectivity issue
          UseTLS = false;
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
          HTMLDisable = true;
          KeepQuotedReply = true;
        };
      };
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers = {
      matrix = {
        rule = "Host(`matrix.nichi.co`) && PathPrefix(`/_matrix`)";
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
