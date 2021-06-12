{ pkgs, config, ... }:
{
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers = {
    n8n = {
      image = "docker.io/n8nio/n8n:0.123.1";
      volumes = [ "/data/n8n:/home/node/.n8n" ];
      ports = [ "127.0.0.1:8080:5678" ];
      environmentFiles = [ config.sops.secrets.n8n.path ];
      environment = {
        N8N_BASIC_AUTH_ACTIVE = "true";
      };
    };
  };
}
