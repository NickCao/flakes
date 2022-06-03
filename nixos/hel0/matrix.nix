{ config, lib, pkgs, ... }:
{
  sops = {
    secrets = {
      mautrix-telegram = { };
      matrix-synapse = { owner = "matrix-synapse"; };
    };
  };

  cloud.services.element-web.config = {
    ExecStart = "${pkgs.serve}/bin/serve -l 127.0.0.1:8005 -p ${pkgs.element-web}";
  };

  systemd.services.matrix-synapse.serviceConfig.LoadCredential = [
    "telegram:/var/lib/mautrix-telegram/telegram-registration.yaml"
  ];
  services.matrix-synapse = {
    enable = true;
    withJemalloc = true;
    settings = {
      server_name = "nichi.co";
      public_baseurl = "https://matrix.nichi.co";
      signing_key_path = config.sops.secrets.matrix-synapse.path;

      enable_search = true;
      dynamic_thumbnails = true;
      allow_public_rooms_over_federation = true;
      app_service_config_files = [ "/run/credentials/matrix-synapse.service/telegram" ];

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
