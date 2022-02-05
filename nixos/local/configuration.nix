{ config, pkgs, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.nickcao = import ./home.nix;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      rait.restartUnits = [ "gravity.service" ];
      v2ray.restartUnits = [ "v2ray.service" ];
      "db.key" = { };
      "db.crt" = { };
      passwd.neededForUsers = true;
      u2f = { mode = "0444"; };
      wireless = { };
      auth-thu = {
        owner = "nickcao";
      };
      restic-passwd = { };
      restic = { };
    };
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  nix = {
    package = pkgs.nixUnstable;
    settings = {
      trusted-users = [ "root" "nickcao" ];
      substituters = pkgs.lib.mkBefore [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" "https://s3.nichi.co/cache" ];
      trusted-public-keys = [ "hydra.nichi.co-0:P3nkYHhmcLR3eNJgOAnHDjmQLkfqheGyhZ6GLrUVHwk=" ];
      auto-optimise-store = true;
      flake-registry = "/etc/nix/registry.json";
      experimental-features = [ "nix-command" "flakes" "ca-derivations" ];
      builders-use-substitutes = true;
      keep-outputs = true;
      keep-derivations = true;
    };
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
    "nvidia-persistenced"
    "nvidia-x11"
  ];

  networking = {
    hostName = "local";
    domain = "nichi.link";
    firewall.enable = false;
    useNetworkd = true;
    useDHCP = false;
    hosts = {
      "2a0c:b641:69c:7864:0:4:8d6:7c9b" = [ "k11-plct" ];
      "104.21.75.85" = [ "api.nichi.workers.dev" ];
    };
    wireless = {
      enable = true;
      userControlled.enable = true;
      environmentFile = config.sops.secrets.wireless.path;
      networks."Tsinghua-Secure" = {
        authProtocols = [ "WPA-EAP" ];
        auth = ''
          proto=RSN
          pairwise=CCMP
          eap=PEAP
          phase2="auth=MSCHAPV2"
          identity="@IDENTITY@"
          password="@PASSWORD@"
        '';
      };
      networks."CMCC-39rG-5G".psk = "@HOME@";
      networks."CMCC-EGfY".psk = "@ALT@";
    };
  };
  systemd.network.networks = {
    wlp0s20f3 = {
      name = "wlp0s20f3";
      DHCP = "yes";
      dhcpV4Config.RouteMetric = 2048;
      dhcpV6Config.RouteMetric = 2048;
      dns = [ "8.8.8.8" "8.8.4.4" "2001:4860:4860::8888" "2001:4860:4860::8844" ];
    };
    enp7s0 = {
      name = "enp7s0";
      DHCP = "yes";
    };
  };
  systemd.services.systemd-networkd-wait-online.serviceConfig.ExecStart = [ "" "${pkgs.systemd}/lib/systemd/systemd-networkd-wait-online --any" ];

  time.timeZone = "Asia/Shanghai";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-chinese-addons
        fcitx5-pinyin-zhwiki
      ];
    };
  };

  powerManagement.cpuFreqGovernor = "powersave";

  boot = {
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    tmpOnTmpfs = true;
    consoleLogLevel = 0;
    initrd.kernelModules = [ "i915" ];
    loader = {
      timeout = 0;
      efi.canTouchEfiVariables = true;
      secureboot = {
        enable = true;
        signingKeyPath = config.sops.secrets."db.key".path;
        signingCertPath = config.sops.secrets."db.crt".path;
      };
    };
    kernel = {
      sysctl = {
        "kernel.panic" = 10;
        "kernel.sysrq" = 1;
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
    kernelParams = [
      "quiet"
      "udev.log_level=3"
      "mitigations=off"
      "nowatchdog"
      "systemd.unified_cgroup_hierarchy=1"
      "intel_iommu=on"
      "iommu=pt"
      # "intel_pstate=passive"
    ];
    kernelModules = [ "ec_sys" ];
    extraModprobeConfig = ''
      options i915 enable_guc=2
      options i915 enable_fbc=1
      options i915 fastboot=1
      blacklist ideapad_laptop
      options kvm_intel nested=1
    '';
    enableContainers = false;
  };

  environment.systemPackages = [ config.boot.kernelPackages.usbip ];

  virtualisation = {
    podman.enable = true;
  };

  hardware = {
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      nvidiaSettings = false;
      nvidiaPersistenced = true;
      modesetting.enable = true;
    };
    pulseaudio.enable = false;
    cpu.intel.updateMicrocode = true;
    bluetooth.enable = true;
    nvidia = {
      prime = {
        offload.enable = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
      powerManagement = {
        enable = true;
        finegrained = true;
      };
    };
    opengl = {
      enable = true;
      extraPackages = with pkgs; [ intel-media-driver ];
    };
  };

  services = {
    resolved = {
      dnssec = "true";
      llmnr = "false";
    };
    restic.backups = {
      s3 = {
        repository = "s3:https://s3.nichi.co/offsite";
        passwordFile = config.sops.secrets.restic-passwd.path;
        environmentFile = config.sops.secrets.restic.path;
        paths = [ "/persistent" ];
        extraBackupArgs = [ "--exclude-caches" ];
        timerConfig = {
          OnBootSec = "15min";
        };
      };
    };
    power-profiles-daemon.enable = true;
    pcscd.enable = true;
    fstrim.enable = true;
    logind.lidSwitch = "ignore";
    pipewire = {
      enable = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
      media-session.enable = false;
    };
    journald = {
      extraConfig = ''
        SystemMaxUse=15M
      '';
    };
    udev = {
      packages = [ pkgs.yubikey-personalization pkgs.libu2f-host ];
      extraRules = ''
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0666"
      '';
    };
    xserver = {
      videoDrivers = [ "nvidia" ];
    };
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
        passwordFile = config.sops.secrets.passwd.path;
        extraGroups = [ "wheel" "networkmanager" ];
      };
    };
  };

  environment.pathsToLink = [ "/share/fish" ];
  environment.etc = {
    "nixos/flake.nix".source = config.users.users.nickcao.home + "/Projects/flakes/flake.nix";
  };

  security.pam.u2f = {
    enable = true;
    authFile = config.sops.secrets.u2f.path;
    control = "sufficient";
    cue = true;
  };
  security.sudo.extraConfig = ''
    Defaults lecture="never"
  '';

  fonts.enableDefaultFonts = false;
  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-emoji
    jetbrains-mono
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];
  fonts.fontconfig.defaultFonts = pkgs.lib.mkForce {
    serif = [ "Noto Serif" "Noto Serif CJK SC" ];
    sansSerif = [ "Noto Sans" "Noto Sans CJK SC" ];
    monospace = [ "JetBrains Mono" ];
    emoji = [ "Noto Color Emoji" ];
  };

  environment.persistence."/persistent" = {
    directories = [
      "/var/log"
      "/var/lib"
      "/var/cache"
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
        ".config/mc"
      ];
    };
  };

  system.stateVersion = "20.09";
}
