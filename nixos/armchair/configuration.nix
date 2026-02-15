{
  pkgs,
  ...
}:

{
  sops = {
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  systemd.network.networks = {
    "10-end0" = {
      name = "end0";
      DHCP = "yes";
    };
    "10-wlan0" = {
      name = "wlan0";
      DHCP = "yes";
      dhcpV4Config.RouteMetric = 2048;
      dhcpV6Config.RouteMetric = 2048;
    };
  };

  systemd.network.wait-online = {
    anyInterface = true;
    extraArgs = [ "--ipv4" ];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.wireless.iwd = {
    enable = true;
  };

  hardware.asahi.peripheralFirmwareDirectory = pkgs.requireFile {
    name = "asahi";
    hashMode = "recursive";
    hash = "sha256-iYDhbSPE8oO9tny1IUSpViUWx2O7PYr9jpopmftxTzU=";
    message = "
      nix-store --add-fixed sha256 --recursive /efi/asahi/
      nix hash path  --algo sha256             /efi/asahi/
    ";
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLQwaWXeJipSuAB+lV202yJOtAgJSNzuldH7JAf2jji nickcao@mainframe"
  ];

  networking.hostName = "armchair";

  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    tmux
    lm_sensors
  ];

  hardware.graphics.enable = true;

  virtualisation.podman.enable = true;

  environment.baseline.enable = true;

  system.stateVersion = "25.05";

}
