{
  pkgs,
  self,
  inputs,
  data,
  ...
}:
{

  # provision secrets

  # su - hydra
  # hydra-create-user nickcao@nichi.co --type github --full-name "Nick Cao" --role admin
  # create terraform user

  # podman run --rm --detach --name=hydra --rootfs --ulimit=host --pids-limit=-1 --systemd=always --network=slirp4netns \
  #   --no-hosts -p=80:80 -p=443:443 -p=9022:22 --privileged /data/hydra /nix/var/nix/profiles/system/init

  nixpkgs.overlays = [ self.overlays.default ];

  imports = [
    self.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    ./hydra.nix
  ];

  boot.isContainer = true;

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  networking = {
    useDHCP = false;
    hostName = "hydra";
    domain = "nichi.link";
  };

  cloud.caddy.enable = true;
  services.openssh.enable = true;
  services.metrics.enable = true;

  users.users.root.openssh.authorizedKeys.keys = data.keys;

  environment.baseline.enable = true;
  environment.systemPackages = with pkgs; [
    git
    nixpkgs-review
    htop
    tmux
  ];

  # https://github.com/NixOS/nixpkgs/issues/157449
  boot.specialFileSystems."/run".options = [ "rshared" ];

  system.stateVersion = "24.05";
}
