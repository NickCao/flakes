{ pkgs, config, ... }:
{
  boot.loader.grub.device = "/dev/sda";
  fileSystems."/" = {
    label = "nixos";
    fsType = "ext4";
    autoResize = true;
  };

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
}
