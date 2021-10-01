{ config, pkgs, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.nickcao = import ./home.nix;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.rait = { };
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  nix = {
    autoOptimiseStore = true;
    binaryCaches = pkgs.lib.mkForce [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" "https://mirror.sjtu.edu.cn/nix-channels/store" "https://nichi.cachix.org" ];
    binaryCachePublicKeys = [ "nichi.cachix.org-1:ZWn4Jui6odEcNEMjcHM/WXbDSVO4Ai+jrzWHf+pqwj0=" ];
    trustedUsers = [ "root" "nickcao" ];
    package = pkgs.nixUnstable;
    systemFeatures = [ "benchmark" "big-parallel" "kvm" "nixos-test" "recursive-nix" ];
    extraOptions = ''
      flake-registry = /etc/nix/registry.json
      experimental-features = nix-command flakes ca-references ca-derivations recursive-nix
      builders-use-substitutes = true
      keep-outputs = true
      keep-derivations = true
    '';
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
    "nvidia-x11"
  ];

  networking = {
    hostName = "local";
    domain = "nichi.link";
    firewall.enable = false;
    networkmanager.dns = "dnsmasq";
    # networkmanager.wifi.backend = "iwd";
    networkmanager.extraConfig = ''
      [main]
      rc-manager = unmanaged
      [keyfile]
      path = /var/lib/NetworkManager/system-connections
    '';
    nameservers = [ "127.0.0.53" ];
  };

  time.timeZone = "Asia/Shanghai";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enabled = "ibus";
      ibus.engines = with pkgs.ibus-engines; [ rime ];
    };
  };

  powerManagement.cpuFreqGovernor = "powersave";

  boot = {
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    tmpOnTmpfs = true;
    consoleLogLevel = 0;
    initrd.verbose = false;
    loader = {
      timeout = 0;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernel = {
      sysctl = {
        "kernel.panic" = 10;
        "kernel.sysrq" = 1;
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
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
      modesetting.enable = true;
      nvidiaSettings = false;
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
      driSupport32Bit = true;
      extraPackages = with pkgs; [ intel-media-driver ];
    };
  };

  xdg.portal.enable = pkgs.lib.mkForce false;

  services = {
    pcscd.enable = true;
    fstrim.enable = true;
    packagekit.enable = false;
    logind.lidSwitch = "ignore";
    gnome.core-utilities.enable = false;
    gnome.evolution-data-server.enable = pkgs.lib.mkForce false;
    gnome.gnome-keyring.enable = pkgs.lib.mkForce false;
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
    udev.packages = [ pkgs.yubikey-personalization pkgs.libu2f-host ];
    xserver = {
      enable = true;
      displayManager.gdm = {
        enable = true;
        wayland = true;
        nvidiaWayland = true;
      };
      desktopManager.gnome.enable = true;
      videoDrivers = [ "nvidia" ];
    };
    smartdns = {
      enable = true;
      settings = with pkgs; {
        log-level = "info";
        speed-check-mode = "none";
        conf-file = [
          "${smartdns-china-list}/accelerated-domains.china.smartdns.conf"
          "${smartdns-china-list}/apple.china.smartdns.conf"
          "${smartdns-china-list}/google.china.smartdns.conf"
        ];
        bind = [ "127.0.0.53:53" ];
        server-https = [
          "https://1.0.0.1/dns-query"
          "https://1.1.1.1/dns-query"
          "https://185.222.222.222/dns-query"
        ];
        server = [
          "127.0.0.1 -group china -exclude-default-group"
          "2a0c:b641:69c:7864:0:5:0:3"
        ];
      };
    };
  };

  programs = {
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
        hashedPassword = "$6$n7lnnelApqi$ulDiRUraojX4zlMiuP4qP./qGZYbTGKVqTsN5z.5HlAGgIy23WMpxBA5fjFyY.RGOepAaZV8cK0tt3duMgVy30";
        extraGroups = [ "wheel" "networkmanager" ];
      };
    };
  };

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

  environment.variables.EDITOR = "hx";
  environment.systemPackages = with pkgs; [
    helix
    (chromium.override { commandLineArgs = "--enable-gpu-rasterization --enable-zero-copy --enable-features=VaapiVideoDecoder"; })
    qvpersonal
    mpv
    tdesktop
    materia-theme
    numix-icon-theme-circle
    gnome.gnome-tweaks
    gnome.gnome-screenshot
    gnome40Extensions."appindicatorsupport@rgcjonas.gmail.com"
  ];

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
