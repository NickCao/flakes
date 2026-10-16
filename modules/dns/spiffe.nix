{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
{
  config = lib.mkIf config.services.knot.enable {
    services.knot.settings.server = {
      key-file = "/run/knot-spiffe/svid_key.pem";
      cert-file = "/run/knot-spiffe/svid.pem";
      ca-file = [ "/run/knot-spiffe/svid_bundle.pem" ];
    };

    systemd.services.spiffe-knot = {
      requiredBy = [ config.systemd.services.knot.name ];
      before = [ config.systemd.services.knot.name ];
      requires = [ config.systemd.services.spire-agent.name ];
      after = [ config.systemd.services.spire-agent.name ];
    };

    cloud.services.spiffe-knot.config = {
      Type = "notify";
      NotifyAccess = "all";
      User = config.systemd.services.knot.serviceConfig.User;
      Group = config.systemd.services.knot.serviceConfig.Group;
      RuntimeDirectory = "knot-spiffe";
      RuntimeDirectoryMode = "0700";
      ExecStart = utils.escapeSystemdExecArgs [
        (lib.getExe pkgs.spiffe-helper)
        "-config"
        ((pkgs.formats.json { }).generate "spiffe-knot.json" {
          agent_address = "/run/spire/agent/public/api.sock";
          cert_dir = "/run/knot-spiffe";
          svid_file_name = "svid.pem";
          svid_key_file_name = "svid_key.pem";
          svid_bundle_file_name = "svid_bundle.pem";
          cmd = pkgs.writeShellScript "reload-knot-svid" ''
            ${pkgs.systemd}/bin/systemd-notify --ready
            if [ -S /run/knot/knot.sock ]; then
              exec ${config.services.knot.package}/bin/knotc --socket /run/knot/knot.sock -b reload
            fi
          '';
        })
      ];
    };
  };
}
