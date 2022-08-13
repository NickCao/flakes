{ config, pkgs, lib, ... }:
{
  sops.secrets.shadowsocks = {
    sopsFile = ./secrets.yaml;
    restartUnits = [ "shadowsocks.service" ];
  };
  cloud.services.shadowsocks.config = {
    ExecStart = "${pkgs.shadowsocks-rust}/bin/ssserver -c %d/config";
    LoadCredential = "config:${config.sops.secrets.shadowsocks.path}";
  };
}
