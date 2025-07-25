{
  config,
  pkgs,
  lib,
  ...
}:
{

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.nickcao = import ./home.nix;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      passwd.neededForUsers = true;
      u2f = {
        mode = "0444";
      };
      "wireless/eduroam" = { };
      "wireless/redhat" = { };
    };
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  systemd.tmpfiles.settings = {
    "10-iwd" = {
      "/var/lib/iwd/eduroam.8021x".C.argument = config.sops.secrets."wireless/eduroam".path;
      "/var/lib/iwd/Red Hat Wi-Fi.psk".C.argument = config.sops.secrets."wireless/redhat".path;
    };
  };

  nix = {
    package = pkgs.nixVersions.stable;
    channel.enable = false;
    settings = {
      trusted-users = [
        "root"
        "nickcao"
      ];
      substituters = lib.mkAfter [ "https://cache.nichi.co" ];
      trusted-public-keys = [ "hydra.nichi.co-0:P3nkYHhmcLR3eNJgOAnHDjmQLkfqheGyhZ6GLrUVHwk=" ];
      auto-optimise-store = true;
      flake-registry = "/etc/nix/registry.json";
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
        "auto-allocate-uids"
        "cgroups"
      ];
      builders-use-substitutes = true;
      keep-derivations = true;
      auto-allocate-uids = true;
      use-cgroups = true;
      use-xdg-base-directories = true;
    };
  };

  nixpkgs.config = {
    allowUnfreePredicate =
      pkg:
      builtins.elem (pkgs.lib.getName pkg) [
        "uhk-agent"
        "uhk-udev-rules"
      ];

    allowNonSource = false;
    allowNonSourcePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "go"
        "uhk-agent"
        "sof-firmware"
        "adoptopenjdk-hotspot-bin"
        "temurin-bin"
        "cargo-bootstrap"
        "rustc-bootstrap"
        "rustc-bootstrap-wrapper"
        "electron"
      ];
  };

  networking = {
    hostName = "mainframe";
    domain = "nichi.link";
    firewall.enable = false;
    useNetworkd = true;
    useDHCP = false;
    wireless.iwd.enable = true;
  };

  systemd.network.networks = {
    "10-wlan0" = {
      name = "wlan0";
      DHCP = "yes";
      dhcpV4Config.RouteMetric = 2048;
      dhcpV6Config.RouteMetric = 2048;
    };
    "11-eth" = {
      matchConfig = {
        Kind = "!*";
        Type = "ether";
      };
      DHCP = "yes";
    };
  };

  time.timeZone = "America/New_York";

  i18n = {
    defaultLocale = "C.UTF-8";
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.plasma6Support = true;
      fcitx5.waylandFrontend = true;
      fcitx5.addons = [
        pkgs.qt6Packages.fcitx5-chinese-addons
        pkgs.fcitx5-pinyin-zhwiki
      ];
    };
  };

  boot = {
    tmp.useTmpfs = true;
    initrd = {
      systemd.enable = true;
      kernelModules = [ "amdgpu" ];
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usb_storage"
        "sd_mod"
      ];
    };
    loader = {
      timeout = 0;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/efi";
      };
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
    kernel = {
      sysctl = {
        "kernel.panic" = 10;
        "kernel.sysrq" = 1;
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "ia32_emulation=0"
      "amdgpu.dcdebugmask=0x10"
    ];
    kernelModules = [ "kvm-amd" ];
    enableContainers = false;
  };

  virtualisation.podman.enable = true;

  hardware = {
    cpu.amd.updateMicrocode = true;
    bluetooth.enable = true;
    graphics.enable = true;
    sensor.iio.enable = true;
    rtl-sdr.enable = true;
  };

  services.fwupd = {
    enable = true;
    extraRemotes = [ "lvfs-testing" ];
  };

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
    askPassword = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session.command = "${lib.getExe pkgs.greetd.tuigreet} --cmd niri-session";
    };
  };

  services = {
    logind.powerKey = "suspend";
    resolved = {
      dnssec = "false";
      llmnr = "false";
      extraConfig = ''
        MulticastDNS=off
      '';
    };
    dbus.implementation = "broker";
    pcscd.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
    journald = {
      extraConfig = ''
        SystemMaxUse=1G
      '';
    };
    udev.packages = [
      pkgs.yubikey-personalization
      pkgs.libu2f-host
    ];
    udev.extraRules = ''
      # AIOC
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="7388", MODE="0666"
    '';
    fprintd.enable = true;
    power-profiles-daemon.enable = true;
  };

  programs = {
    adb.enable = true;
    dconf.enable = true;
    command-not-found.enable = false;
  };

  users = {
    mutableUsers = false;
    users = {
      nickcao = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets.passwd.path;
        extraGroups = [
          "wheel"
          "dialout"
          "plugdev"
        ];
      };
    };
  };

  environment.pathsToLink = [ "/share/fish" ];
  environment.backup.enable = true;

  security.pam.services.swaylock = { };
  security.pam.u2f = {
    enable = true;
    control = "sufficient";
    settings = {
      cue = true;
      authfile = config.sops.secrets.u2f.path;
    };
  };
  security.sudo.extraConfig = ''
    Defaults lecture="never"
  '';
  security.polkit.enable = true;

  fonts = {
    enableDefaultPackages = false;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-emoji
      jetbrains-mono
      nerd-fonts.jetbrains-mono
      nerd-fonts.roboto-mono
    ];
    fontconfig.defaultFonts = pkgs.lib.mkForce {
      serif = [
        "Noto Serif"
        "Noto Serif CJK SC"
      ];
      sansSerif = [
        "Noto Sans"
        "Noto Sans CJK SC"
      ];
      monospace = [ "JetBrains Mono" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

  environment.persistence."/persist" = {
    directories = [ "/var" ];
    files = [ "/etc/machine-id" ];
    users.nickcao = {
      directories = [
        "Documents"
        "Downloads"
        "Pictures"
        "Projects"
        ".cache"
        ".local"
        ".mozilla"
        ".ssh"
        ".thunderbird"
        ".config/fcitx5"
      ];
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
    configPackages = [ pkgs.niri ];
  };

  services.zram-generator = {
    enable = true;
    settings.zram0 = {
      compression-algorithm = "zstd";
      zram-size = "ram";
    };
  };

  hardware.keyboard.uhk.enable = true;

  environment.stub-ld.enable = false;

  documentation.nixos.enable = false;

  system.stateVersion = "24.05";
}
