{ config, pkgs, ... }: {

  sops.secrets = {
    tuic-cfg = { sopsFile = ./secrets.yaml; restartUnits = [ "tuic.service" ]; };
    tuic-crt = { sopsFile = ./secrets.yaml; restartUnits = [ "tuic.service" ]; };
    tuic-key = { sopsFile = ./secrets.yaml; restartUnits = [ "tuic.service" ]; };
  };

  cloud.services.tuic = {
    config = {
      ExecStart = "${pkgs.tuic}/bin/tuic-server -c %d/cfg";
      LoadCredential = [
        "cfg:${config.sops.secrets.tuic-cfg.path}"
        "crt:${config.sops.secrets.tuic-crt.path}"
        "key:${config.sops.secrets.tuic-key.path}"
      ];
    };
  };

}
