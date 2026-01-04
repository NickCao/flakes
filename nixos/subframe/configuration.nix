{
  pkgs,
  ...
}:

{
  # sops = {
  #   age = {
  #     keyFile = "/var/lib/sops.key";
  #     sshKeyPaths = [ ];
  #   };
  #   gnupg.sshKeyPaths = [ ];
  # };

  networking = {
    useNetworkd = true;
    useDHCP = false;
  };

  systemd.network.networks = {
    "10-eth0" = {
      name = "eth0";
      DHCP = "yes";
    };
  };

  systemd.network.wait-online = {
    anyInterface = true;
    extraArgs = [ "--ipv4" ];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLQwaWXeJipSuAB+lV202yJOtAgJSNzuldH7JAf2jji nickcao@mainframe"
  ];

  networking.hostName = "subframe";

  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    tmux
    lm_sensors
  ];

  virtualisation.incus = {
    enable = true;
    package = pkgs.incus;
    ui.enable = true;
    preseed = {
      config = {
        "core.https_address" = ":8443";
      };
    };
  };

  environment.baseline.enable = true;

  system.stateVersion = "25.11";
}
