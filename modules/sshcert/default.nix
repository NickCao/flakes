{ config, lib, ... }:
let
  cfg = config.services.sshcert;
in
with lib;
{
  options.services.sshcert = {
    enable = mkEnableOption "sign ssh certificate";
  };
  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = !config.services.openssh.startWhenNeeded;
      message = "sshcert: sshd socket activation is not supported";
    }];
    sops.secrets.sshca = {
      sopsFile = ./secrets.yaml;
      restartUnits = [ "sshd.service" ];
    };
    systemd.services.sshd.preStart = mkAfter (flip concatMapStrings config.services.openssh.hostKeys (k: ''
      if [ -s "${k.path}.pub" ] && [ -s "${config.sops.secrets.sshca.path}" ]; then
          ssh-keygen -s ${config.sops.secrets.sshca.path} -I ${config.networking.hostName} -h ${k.path}.pub
      fi
    ''));
    services.openssh.extraConfig = flip concatMapStrings config.services.openssh.hostKeys (k: ''
      HostCertificate ${k.path}-cert.pub
    '');
  };
}
