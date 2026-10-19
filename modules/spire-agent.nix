{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.cloud.spire.agent;
in
{
  options.cloud.spire.agent = {
    enable = lib.mkEnableOption "SPIRE agent";
    tpm = lib.mkEnableOption "spire tpm attestation";
  };

  config = lib.mkIf cfg.enable {
    systemd.services.spire-agent.serviceConfig = {
      AmbientCapabilities = lib.mkIf (!cfg.tpm) [
        "CAP_NET_BIND_SERVICE"
      ];
    };

    services.spire.agent.enable = true;
    services.spire.agent.settings = {
      agent = {
        rebootstrap_mode = "auto";
        server_address = "spire.nichi.co";
        server_port = 9443;
        trust_domain = "nichi.link";
        trust_bundle_url = "https://spire.nichi.co";
        trust_bundle_format = "spiffe";
      };
      plugins = {
        KeyManager.memory = { };
        NodeAttestor = {
          http_challenge = lib.mkIf (!cfg.tpm) {
            plugin_data = {
              hostname = config.networking.fqdn;
              port = 81;
            };
          };
          tpm = lib.mkIf cfg.tpm {
            plugin_cmd = lib.getExe' pkgs.spire-tpm-plugin "tpm_attestor_agent";
            plugin_data = { };
          };
        };
        WorkloadAttestor.systemd = { };
        WorkloadAttestor.unix = { };
      };
    };
  };
}
