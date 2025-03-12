{ config, ... }:
{

  sops.secrets.tailscale = {
    sopsFile = ./secrets.yaml;
    restartUnits = [
      config.systemd.services.tailscaled.name
      config.systemd.services.tailscaled-autoconnect.name
    ];
  };

  services.gravity.bird.routes = [
    ''route 2a0c:b641:69c:7a10::/60 from ::/0 via "tailscale0"''
  ];

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
      "--accept-dns=false"
    ];
  };

}
