{ pkgs, config, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      vault-agent-roleid = { mode = "0444"; };
      vault-agent-secretid = { mode = "0444"; };
    };
    sshKeyPaths = [ "/var/lib/sops.key" ];
  };
  networking = {
    hostName = "sea0";
    domain = "nichi.link";
  };
  services.dns = {
    enable = true;
  };
  services.cluster.enable = true;
}
