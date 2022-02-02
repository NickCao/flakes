{ config, pkgs, lib, ... }:
let
  cfg = config.services.sshfp;
in
with lib;
{
  options.services.sshfp = {
    enable = mkEnableOption "SSHFP record";
    hostKeys = mkOption {
      type = types.path;
      description = "path to ssh host key";
    };
    server = mkOption {
      type = types.str;
      default = "hel0.nichi.link";
      description = "RFC 2136 server";
    };
  };
  config = lib.mkIf cfg.enable {
    sops.secrets.sshfp.sopsFile = ./secrets.yaml;
    services.sshfp = {
      hostKeys = mkOptionDefault (builtins.map (key: key.path) config.services.openssh.hostKeys);
    };
    systemd.services.sshfp = {
      after = [ "sshd.service" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs;[ knot-dns openssh gawk coreutils ];
      unitConfig = {
        ConditionPathExists = cfg.hostKeys;
      };
      serviceConfig = {
        Type = "oneshot";
        DynamicUser = true;
        LoadCredential = builtins.map (key: "${replaceChars ["/"] ["-"] key}:${key}") cfg.hostKeys ++ [
          "key:${config.sops.secrets.sshfp.path}"
        ];
      };
      script = ''
        set -euo pipefail
        knsupdate -k ''${CREDENTIALS_DIRECTORY}/key << EOT
        server ${cfg.server}
        zone ${config.networking.domain}
        origin ${config.networking.domain}
        ttl 30
        del ${config.networking.hostName} SSHFP
      '' + fold
        (key: acc:
          let
            record = ''ssh-keygen -y -f ''${CREDENTIALS_DIRECTORY}/${replaceChars ["/"] ["-"] key} | awk '{ print $2 }' | base64 -d | sha256sum | awk '{ print $1 }';'';
          in
          (acc + ''
            add ${config.networking.hostName} SSHFP 4 2 `${record}`
          '')) ""
        cfg.hostKeys + ''
        send
        EOT
      '';
    };
    systemd.paths.sshfp = {
      pathConfig = {
        PathChanged = cfg.hostKeys;
      };
    };
  };
}
