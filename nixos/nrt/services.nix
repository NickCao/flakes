{ pkgs, config, ... }:
{
  # TODO: force podman to use nftables
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers = {
    blog = {
      ports = [ "127.0.0.1:8080:8080" ];
      image = "quay.io/nickcao/blog";
    };
    meow = {
      ports = [ "127.0.0.1:8081:8080" ];
      image = "quay.io/nickcao/meow";
      environment = {
        BASE_URL = "https://pb.nichi.co";
        S3_BUCKET = "pastebin-nichi";
        S3_ENDPOINT = "https://s3.us-west-000.backblazeb2.com";
      };
      environmentFiles = [ config.sops.secrets.meow.path ];
    };
    woff = {
      ports = [ "127.0.0.1:8082:8080" ];
      image = "registry.gitlab.com/nickcao/functions/woff";
      environment = {
        RETURN_URL = "https://nichi.co";
      };
      environmentFiles = [ config.sops.secrets.woff.path ];
    };
  };
  services.traefik = {
    enable = true;
    staticConfigOptions = {
      entryPoints = {
        http = {
          address = ":80";
        };
      };
    };
    dynamicConfigOptions = {
      http = {
        routers = {
          blog = {
            rule = "Host(`nichi.co`)";
            service = "blog";
          };
          meow = {
            rule = "Host(`pb.nichi.co`)";
            service = "meow";
          };
          woff = {
            rule = "Host(`pay.nichi.co`)";
            service = "woff";
          };
          rait = {
            rule = "Host(`api.nichi.co`) && Path(`/rait`)";
            middlewares = [ "rait" ];
            service = "rait";
          };
        };
        middlewares.rait.replacePath = {
          path = "/gravity/combined.json";
        };
        services = {
          rait.loadBalancer = {
            passHostHeader = false;
            servers = [
              {
                url = "https://artifacts-nichi.s3.us-west-000.backblazeb2.com";
              }
            ];
          };
          blog.loadBalancer = {
            servers = [
              {
                url = "http://127.0.0.1:8080";
              }
            ];
          };
          meow.loadBalancer = {
            servers = [
              {
                url = "http://127.0.0.1:8081";
              }
            ];
          };
          woff.loadBalancer = {
            servers = [
              {
                url = "http://127.0.0.1:8082";
              }
            ];
          };
        };
      };
    };
  };
}
