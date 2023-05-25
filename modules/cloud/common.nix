{ config, pkgs, modulesPath, data, self, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    self.nixosModules.default
    self.nixosModules.shadowsocks
    self.nixosModules.cloud.disko
  ];

  sops = {
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  users.users.root.openssh.authorizedKeys.keys = data.keys;

  cloud.caddy.enable = true;
  services.metrics.enable = true;
  services.openssh.enable = true;

  boot = {
    tmp.useTmpfs = true;
    loader.grub.device = config.disko.devices.disk.vda.device;
  };

  networking = {
    useNetworkd = true;
    useDHCP = false;
    domain = "nichi.link";
  };

  system.build.install = pkgs.writeShellApplication {
    name = "install";
    text = ''
      # copy disko script
      nix --extra-experimental-features nix-command copy \
        --from "https://cache.nichi.co" \
        --option trusted-public-keys "hydra.nichi.co-0:P3nkYHhmcLR3eNJgOAnHDjmQLkfqheGyhZ6GLrUVHwk=" \
        ${config.system.build.diskoScript}
      # run disko script
      ${config.system.build.diskoScript}
      # copy sops key
      mkdir -p /mnt/persist/var/lib/
      (umask 0077 && curl -s http://169.254.169.254/latest/user-data -o /mnt/persist/var/lib/sops.key)
      # install
      nixos-install --root /mnt --system ${config.system.build.toplevel} \
        --no-channel-copy --no-root-passwd \
        --option extra-substituters "https://cache.nichi.co" \
        --option trusted-public-keys "hydra.nichi.co-0:P3nkYHhmcLR3eNJgOAnHDjmQLkfqheGyhZ6GLrUVHwk="
      reboot
    '';
    checkPhase = ''
      mkdir -p $out/nix-support
      echo "file install $out/bin/install" >> $out/nix-support/hydra-build-products
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
