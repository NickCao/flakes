{ config, ... }:
{

  sops.secrets.tailscale = {
    sopsFile = ./secrets.yaml;
    restartUnits = [
      config.systemd.services.tailscaled.name
      config.systemd.services.tailscaled-autoconnect.name
    ];
  };

  systemd.services.tailscaled.environment.TS_DEBUG_FIREWALL_MODE = "nftables";

  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets.tailscale.path;
    disableTaildrop = true;
    extraUpFlags = [
      "--reset"
      "--login-server=https://headscale.nichi.co"
      "--netfilter-mode=off"
      "--advertise-tags=tag:exit-node"
      "--advertise-exit-node"
      "--snat-subnet-routes=false"
      "--stateful-filtering=false"
      "--accept-dns=false"
    ];
  };

}
