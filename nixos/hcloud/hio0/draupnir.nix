{ config, ... }:
{
  sops.secrets.draupnir = {
    restartUnits = [ config.systemd.services.draupnir.name ];
  };
  services.draupnir = {
    enable = true;
    settings = {
      homeserverUrl = config.services.matrix-synapse.settings.public_baseurl;
      managementRoom = "#moderation:nichi.co";
    };
    secrets = {
      accessToken = config.sops.secrets.draupnir.path;
    };
  };
}
