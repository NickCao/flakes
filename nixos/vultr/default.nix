{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    (
      { config, pkgs, ... }:
        {
          environment.etc."ssh/keys" = {
            mode = "0555";
            text = ''
              #!${pkgs.runtimeShell}
              ${pkgs.curl}/bin/curl https://gitlab.com/NickCao.keys
            '';
          };
          services.openssh = {
            enable = true;
            authorizedKeysCommand = "/etc/ssh/keys";
          };
          networking = {
            firewall.enable = false;
          };
          boot.loader.grub.device = "/dev/vda";
          fileSystems."/" = {
            device = "/dev/disk/by-label/nixos";
            fsType = "ext4";
            autoResize = true;
          };
          system.build.image = import "${nixpkgs}/nixos/lib/make-disk-image.nix" {
            inherit pkgs config;
            inherit (pkgs) lib;
          };
        }
    )
  ];
}
