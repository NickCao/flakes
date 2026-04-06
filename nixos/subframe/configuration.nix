{
  config,
  pkgs,
  ...
}:

{
  sops = {
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
      plugins = [ pkgs.age-plugin-tpm ];
    };
    gnupg.sshKeyPaths = [ ];
    defaultSopsFile = ./secrets.yaml;
  };

  networking = {
    useNetworkd = true;
    useDHCP = false;
  };

  systemd.network.networks = {
    "10-eth0" = {
      name = "eth0";
      macvlan = [
        config.systemd.network.netdevs."10-eth0macvlan".netdevConfig.Name
      ];
    };
    "10-eth0macvlan" = {
      name = config.systemd.network.netdevs."10-eth0macvlan".netdevConfig.Name;
      DHCP = "yes";
      dhcpV4Config.RouteMetric = 512;
      ipv6AcceptRAConfig.RouteMetric = 512;
    };
  };

  systemd.network.netdevs = {
    "10-eth0macvlan" = {
      netdevConfig = {
        Kind = "macvlan";
        Name = "eth0macvlan";
      };
      macvlanConfig = {
        Mode = "bridge";
      };
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

  networking = {
    hostName = "subframe";
    domain = "nichi.link";
  };

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

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  environment.baseline.enable = true;

  systemd.tmpfiles.settings."10-chromeos" = {
    "/sys/class/leds/chromeos:white:power/brightness".w = {
      argument = "0";
    };
    "/sys/class/leds/chromeos:multicolor:charging/brightness".w = {
      argument = "0";
    };
  };

  services.timesyncd.enable = true;
  services.ntpd-rs.enable = false;

  # https://github.com/systemd/systemd/issues/36498
  boot.blacklistedKernelModules = [ "rtc_cmos" ];

  system.stateVersion = "25.11";
}
