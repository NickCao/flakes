{ pkgs, config, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = { };
    sshKeyPaths = [ "/var/lib/sops.key" ];
  };
  networking = {
    hostName = "sea0";
    domain = "nichi.link";
  };
  services.dns = {
    enable = true;
  };
  services.consul = {
    enable = true;
    webUi = true;
    interface.bind = "enp1s0";
    interface.advertise = "enp1s0";
    extraConfig = {
      server = true;
      bootstrap_expect = 3;
      retry_join = [ "nrt0.nichi.link" "sin0.nichi.link" "sea0.nichi.link" ];
    };
  };
}
