{ config, pkgs, lib, ... }:
{
  sops.secrets.ss = {
    sopsFile = ./secrets.yaml;
  };
  services.shadowsocks = {
    enable = true;
    port = 41287;
    encryptionMethod = "aes-256-gcm";
    passwordFile = config.sops.secrets.ss.path;
  };
}
