{ config, pkgs, modulesPath, data, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (import ../.).default
    (import ../.).cloud.disko
  ];

  sops = {
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  users.users.root.openssh.authorizedKeys.keys = data.keys;

  services.gateway.enable = true;
  services.metrics.enable = true;
  services.sshcert.enable = true;
  services.openssh.enable = true;

  boot = {
    tmpOnTmpfs = true;
    loader.grub.device = "/dev/vda";
  };

  networking = {
    useNetworkd = true;
    useDHCP = false;
    domain = "nichi.link";
  };

  system.build.install = pkgs.writeShellApplication {
    name = "install";
    text = ''
      ${config.system.build.disko}

      mkdir -p /mnt/persist/var/lib/
      (umask 0077 && curl -s http://169.254.169.254/latest/user-data -o /mnt/persist/var/lib/sops.key)

      nixos-install --root /mnt --system ${builtins.unsafeDiscardStringContext config.system.build.toplevel} \
        --no-channel-copy --no-root-passwd \
        --option extra-substituters "https://cache.nichi.co" \
        --option trusted-public-keys "hydra.nichi.co-0:P3nkYHhmcLR3eNJgOAnHDjmQLkfqheGyhZ6GLrUVHwk="

      reboot
    '';
  };

  environment.persistence."/persist" = {
    directories = [
      "/var"
    ];
  };

  environment.baseline.enable = true;

  system.stateVersion = "22.05";
}
