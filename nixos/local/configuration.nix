{ config, pkgs, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.nickcao = import ./home.nix;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.rait.restartUnits = [ "gravity.service" ];
    secrets.v2ray.restartUnits = [ "v2ray.service" ];
    secrets."db.key" = { };
    secrets."db.crt" = { };
    secrets.passwd.neededForUsers = true;
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  nix = {
    autoOptimiseStore = true;
    binaryCaches = pkgs.lib.mkBefore [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" "https://s3.nichi.co/cache" ];
    binaryCachePublicKeys = [ "hydra.nichi.co-0:P3nkYHhmcLR3eNJgOAnHDjmQLkfqheGyhZ6GLrUVHwk=" ];
    trustedUsers = [ "root" "nickcao" ];
    package = pkgs.nixUnstable;
    systemFeatures = [ "benchmark" "big-parallel" "kvm" "nixos-test" "recursive-nix" ];
    extraOptions = ''
      flake-registry = /etc/nix/registry.json
      experimental-features = nix-command flakes ca-derivations
      builders-use-substitutes = true
      keep-outputs = true
      keep-derivations = true
    '';
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
    "nvidia-persistenced"
    "nvidia-x11"
  ];

  networking = {
    hostName = "local";
    domain = "nichi.link";
    firewall.enable = false;
    networkmanager.enable = true;
    # networkmanager.wifi.backend = "iwd";
    networkmanager.extraConfig = ''
      [main]
      rc-manager = unmanaged
      [keyfile]
      path = /var/lib/NetworkManager/system-connections
    '';
    hosts = {
      "2a0c:b641:69c:7864:0:4:8d6:7c9b" = [ "k11-plct" ];
    };
  };

  time.timeZone = "Asia/Shanghai";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-rime
        fcitx5-gtk
        libsForQt5.fcitx5-qt
        fcitx5-configtool
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

  virtualisation = {
    podman.enable = true;
    virtualbox.host.enable = true;
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
      domains = [ "nichi.link" ];
      dnssec = "true";
    };
    power-profiles-daemon.enable = true;
    pcscd.enable = true;
    fstrim.enable = true;
    logind.lidSwitch = "ignore";
    pipewire = {
      enable = true;
      pulse.enable = true;
      jack.enable = true;
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
    sway = {
      enable = true;
      extraOptions = [ "--my-next-gpu-wont-be-nvidia" ];
      wrapperFeatures.gtk = true;
    };
    nm-applet = {
      enable = true;
      indicator = true;
    };
    adb.enable = true;
    chromium = {
      enable = true;
      extensions = [ "padekgcemlokbadohgkifijomclgjgif" "cjpalhdlnbpafiamejdnhcphjbkeiagm" ];
    };
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
    authFile = pkgs.writeText "u2f-mappings" ''
      nickcao:8KGtTGZAEfnsqPDCY3MQFv3Ef9njqy39JHgc5WDC8aiekH1mGS5hq1XmT+og8TpaxgMPzHs7G/oa58RyLw/Odw==,At2tDFQSBa+P+GPNVLPzVzHpVOfS4l+mJOFhCThAf2VEeBVf315Wocy9kFRDr05QdGPlwcOkXOao4Dja6cl7/w==,es256,+presence
    '';
    control = "sufficient";
    cue = true;
  };

  fonts.fonts = with pkgs; [
    roboto
    jetbrains-mono
    nerdfonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-extra
    noto-fonts-emoji
  ];

  environment.persistence."/persistent" = {
    directories = [
      "/var/log"
      "/var/db"
      "/var/lib"
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  system.stateVersion = "20.09";
}
