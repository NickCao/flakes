{ config, pkgs, lib, ... }: {

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.nickcao = import ./home.nix;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      passwd.neededForUsers = true;
      u2f = { mode = "0444"; };
      "wireless/home" = { };
      "wireless/eduroam" = { };
    };
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  systemd.tmpfiles.settings = {
    "10-iwd" = {
      "/var/lib/iwd/Verizon_K3ND63.psk".C.argument = config.sops.secrets."wireless/home".path;
      "/var/lib/iwd/eduroam.8021x".C.argument = config.sops.secrets."wireless/eduroam".path;
    };
  };

  nix = {
    package = pkgs.nixVersions.stable;
    channel.enable = false;
    settings = {
      trusted-users = [ "root" "nickcao" ];
      substituters = lib.mkAfter [ "https://cache.nichi.co" ];
      trusted-public-keys = [ "hydra.nichi.co-0:P3nkYHhmcLR3eNJgOAnHDjmQLkfqheGyhZ6GLrUVHwk=" ];
      auto-optimise-store = true;
      flake-registry = "/etc/nix/registry.json";
      experimental-features = [ "nix-command" "flakes" "ca-derivations" "auto-allocate-uids" "cgroups" ];
      builders-use-substitutes = true;
      keep-derivations = true;
      auto-allocate-uids = true;
      use-cgroups = true;
      use-xdg-base-directories = true;
    };
  };

  nixpkgs.config = {
    allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
      "uhk-agent"
      "uhk-udev-rules"
    ];

    allowNonSource = false;
    allowNonSourcePredicate = pkg: builtins.elem (lib.getName pkg) [
      "uhk-agent"
      "sof-firmware"
      "adoptopenjdk-hotspot-bin"
      "cargo-bootstrap"
      "rustc-bootstrap"
      "rustc-bootstrap-wrapper"
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

  systemd.network.wait-online = {
    anyInterface = true;
    ignoredInterfaces = [ "gravity" ];
  };

  systemd.network.networks = {
    "10-wlan0" = {
      name = "wlan0";
      DHCP = "yes";
      dhcpV4Config.RouteMetric = 2048;
      dhcpV6Config.RouteMetric = 2048;
    };
  };

  time.timeZone = "America/New_York";

  i18n = {
    defaultLocale = "C.UTF-8";
    inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-chinese-addons
        fcitx5-pinyin-zhwiki
      ];
    };
  };

  boot = {
    tmp.useTmpfs = true;
    initrd = {
      systemd.enable = true;
      kernelModules = [
        "amdgpu"
      ];
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
      pkiBundle = "${config.users.users.nickcao.home}/Documents/secureboot";
    };
    kernel = {
      sysctl = {
        "kernel.panic" = 10;
        "kernel.sysrq" = 1;
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "rtc_cmos.use_acpi_alarm=1"
      "amdgpu.sg_display=0"
    ];
    kernelModules = [ "kvm-amd" ];
    enableContainers = false;
  };

  virtualisation.podman.enable = true;

  hardware = {
    cpu.amd.updateMicrocode = true;
    pulseaudio.enable = false;
    bluetooth.enable = true;
    opengl.enable = true;
    sensor.iio.enable = true;
    firmware = lib.mkBefore [
      # vaapi vp9 decoding glitches on rembrandt
      # https://gitlab.freedesktop.org/mesa/mesa/-/issues/8044
      (pkgs.fetchurl {
        name = "amdgpu-firmware-vcn";
        url = "https://gitlab.freedesktop.org/mesa/mesa/uploads/f51d221a24d4ac354e2d1d901613b594/vcn_4_0_2.bin";
        hash = "sha256-1xFS8//lTuDJFOt4F1hPOrBOKw0UQ6I/WUBNqKS92Yc=";
        downloadToTemp = true;
        recursiveHash = true;
        postFetch = ''
          install -Dm444 "$downloadedFile" "$out/lib/firmware/amdgpu/vcn_4_0_2.bin"
        '';
      })
    ];
  };

  services.fwupd.enable = true;

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
    askPassword = "${pkgs.gnome.seahorse}/libexec/seahorse/ssh-askpass";
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session.command = "${lib.getExe pkgs.greetd.tuigreet} --cmd ${pkgs.writeShellScript "sway" ''
        while read -r l; do
          eval export $l
        done < <(/run/current-system/systemd/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)

        exec systemd-cat --identifier=sway sway
      ''}";
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
    fstrim.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
    journald = {
      extraConfig = ''
        SystemMaxUse=1G
      '';
    };
    udev.packages = [ pkgs.yubikey-personalization pkgs.libu2f-host ];
    fprintd.enable = true;
    power-profiles-daemon.enable = true;
  };

  powerManagement.powertop.enable = true;

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
        extraGroups = [ "wheel" "kvm" ];
      };
    };
  };

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "-";
      item = "memlock";
      value = "unlimited";
    }
  ];

  environment.pathsToLink = [ "/share/fish" ];
  environment.backup.enable = true;

  security.pam.services.swaylock = { };
  security.pam.u2f = {
    enable = true;
    authFile = config.sops.secrets.u2f.path;
    control = "sufficient";
    cue = true;
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
      (nerdfonts.override { fonts = [ "JetBrainsMono" "RobotoMono" ]; })
    ];
    fontconfig.defaultFonts = pkgs.lib.mkForce {
      serif = [ "Noto Serif" "Noto Serif CJK SC" ];
      sansSerif = [ "Noto Sans" "Noto Sans CJK SC" ];
      monospace = [ "JetBrains Mono" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

  environment.persistence."/persist" = {
    directories = [
      "/var"
    ];
    files = [
      "/etc/machine-id"
    ];
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
    wlr.enable = true;
    config.common.default = "*";
  };

  services.zram-generator = {
    enable = true;
    settings.zram0 = {
      compression-algorithm = "zstd";
      zram-size = "ram";
    };
  };

  hardware.keyboard.uhk.enable = true;

  system.stateVersion = "23.11";

  documentation.nixos.enable = false;
}
