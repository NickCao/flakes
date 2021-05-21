{ pkgs, config, ... }:
{
  # TODO: force podman to use nftables
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers = {
    blog = {
      ports = [ "8080:8080" ];
      image = "quay.io/nickcao/blog";
    };
    meow = {
      ports = [ "8081:8080" ];
      image = "quay.io/nickcao/meow";
      environment = {
        BASE_URL = "https://pb.nichi.co";
        S3_BUCKET = "pastebin-nichi";
        S3_ENDPOINT = "https://s3.us-west-000.backblazeb2.com";
      };
      environmentFiles = [ config.sops.secrets.meow.path ];
    };
    woff = {
      ports = [ "8082:8080" ];
      image = "registry.gitlab.com/nickcao/functions/woff";
      environment = {
        RETURN_URL = "https://nichi.co";
      };
      environmentFiles = [ config.sops.secrets.woff.path ];
    };
  };
}
