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

  users.users = {
    nickcao = {
      isNormalUser = true;
      extraGroups = [ "video" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLQwaWXeJipSuAB+lV202yJOtAgJSNzuldH7JAf2jji nickcao@mainframe"
      ];
    };
    ryan = {
      isNormalUser = true;
      extraGroups = [ "video" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBuY5QsJN/wdYf0WpRk76Qxt9f/iwQU642m4P2JZ5glE"
      ];
    };
  };

  networking.hostName = "armchair";

  services.openssh = {
    enable = true;
    settings = {
      GatewayPorts = "clientspecified";
    };
  };

  systemd.services.bird.after = [ "network-online.target" ];
  systemd.services.bird.wants = [ "network-online.target" ];

  services.gravity = {
    enable = true;
    reload.enable = true;
    address = [ "2a0c:b641:69c:a230::1/128" ];
    bird = {
      enable = true;
      routes = [ "route 2a0c:b641:69c:a230::/60 from ::/0 unreachable" ];
      pattern = "grv*";
    };
    ipsec = {
      enable = true;
      organization = "nickcao";
      commonName = "armchair";
      port = 13000;
      interfaces = [
        "wlan0"
        "end0"
      ];
      endpoints = [
        {
          serialNumber = "0";
          addressFamily = "ip4";
        }
        {
          serialNumber = "1";
          addressFamily = "ip6";
        }
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    waypipe
    uv
    python3
    lm_sensors
    docker-compose
  ];

  hardware.graphics.enable = true;
  hardware.asahi.useExperimentalGPUDriver = true;
  hardware.asahi.experimentalGPUInstallMode = "driver";

  virtualisation.podman.enable = true;

  environment.baseline.enable = true;

  system.stateVersion = "25.05";

}
