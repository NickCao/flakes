{ config, pkgs, inputs, ... }:
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
      u2f = { mode = "0444"; };
      "wireless/tsinghua" = { };
      "wireless/home" = { };
      "wireless/alt" = { };
    };
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  systemd.tmpfiles.rules = [
    "C /var/lib/iwd/Tsinghua-Secure.8021x - - - - ${config.sops.secrets."wireless/tsinghua".path}"
    "C /var/lib/iwd/CMCC-39rG-5G.psk      - - - - ${config.sops.secrets."wireless/home".path}"
    "C /var/lib/iwd/CMCC-EGfY.psk         - - - - ${config.sops.secrets."wireless/alt".path}"
  ];

  nix = {
    package = pkgs.nixVersions.stable;
    nrBuildUsers = 0;
    settings = {
      trusted-users = [ "root" "nickcao" ];
      substituters = pkgs.lib.mkForce [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://cache.nixos.org"
        "https://cache.nichi.co"
      ];
      trusted-public-keys = [ "hydra.nichi.co-0:P3nkYHhmcLR3eNJgOAnHDjmQLkfqheGyhZ6GLrUVHwk=" ];
      auto-optimise-store = true;
      flake-registry = "/etc/nix/registry.json";
      experimental-features = [ "nix-command" "flakes" "ca-derivations" "auto-allocate-uids" "cgroups" ];
      builders-use-substitutes = true;
      keep-derivations = true;
      auto-allocate-uids = true;
      use-cgroups = true;
    };
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
    "nvidia-x11"
    "uhk-agent"
    "uhk-udev-rules"
  ];

  networking = {
    hostName = "local";
    domain = "nichi.link";
    firewall.enable = false;
    useNetworkd = true;
    useDHCP = false;
    wireless.iwd = {
      enable = true;
      package = pkgs.iwd-thu;
    };
  };
  systemd.network.wait-online = {
    anyInterface = true;
    ignoredInterfaces = [ "gravity" "gravity-bind" ];
  };
  systemd.network.networks = {
    wlan0 = {
      name = "wlan0";
      DHCP = "yes";
      dhcpV4Config.RouteMetric = 2048;
      dhcpV6Config.RouteMetric = 2048;
    };
    enp7s0 = {
      name = "enp7s0";
      DHCP = "yes";
    };
  };

  time.timeZone = "Asia/Shanghai";

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
    binfmt.emulatedSystems = [ "aarch64-linux" "riscv64-linux" ];
    tmpOnTmpfs = true;
    initrd = {
      kernelModules = [ "i915" ];
      availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" ];
      systemd.enable = true;
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
      privateKeyFile = "${config.users.users.nickcao.home}/Documents/secureboot/db.key";
      publicKeyFile = "${config.users.users.nickcao.home}/Documents/secureboot/db.crt";
    };
    kernel = {
      sysctl = {
        "kernel.panic" = 10;
        "kernel.sysrq" = 1;
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = with config.boot.kernelPackages; [
      (callPackage "${inputs.dhack}/dhack.nix" { })
    ];
    kernelParams = [
      "mitigations=off"
      "nowatchdog"
      "intel_iommu=on"
      "iommu=pt"
      # "intel_pstate=passive"
    ];
    kernelModules = [ "ec_sys" "uhid" "kvm-intel" "dhack" ];
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
    vmVariant = {
      users.users.nickcao = {
        password = "passwd";
        passwordFile = pkgs.lib.mkForce null;
      };
      services.gravity.enable = pkgs.lib.mkForce false;
      environment.persistence."/persist" = pkgs.lib.mkForce { };
    };
  };

  hardware = {
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      open = true;
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
      extraPackages = with pkgs; [ intel-media-driver ];
    };
  };

  programs.ssh.extraConfig = ''
    Host *.nichi.link
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null
  '';

  systemd.services.nix-daemon.serviceConfig.Environment = [
    "https_proxy=http://127.0.0.1:1080"
    "http_proxy=http://127.0.0.1:1080"
  ];

  systemd.services.iwd.serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";

  services.greetd = {
    enable = true;
    settings = {
      default_session.command = "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd ${pkgs.writeShellScript "sway" ''
        export $(/run/current-system/systemd/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)
        exec sway
      ''}";
    };
  };

  services = {
    resolved = {
      dnssec = "false";
      llmnr = "false";
    };
    restic.backups.persist = {
      repository = "sftp:backup:backup";
      passwordFile = config.sops.secrets.restic.path;
      paths = [ "/persist" ];
      extraBackupArgs = [ "--exclude-caches" ];
      timerConfig = {
        OnBootSec = "15min";
      };
    };
    pcscd.enable = true;
    fstrim.enable = true;
    logind.lidSwitch = "ignore";
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
    journald = {
      extraConfig = ''
        SystemMaxUse=1G
      '';
    };
    udev = {
      packages = [ pkgs.yubikey-personalization pkgs.libu2f-host ];
      extraRules =
        let
          power = pkgs.writeShellScript "power" ''
            ${config.boot.kernelPackages.cpupower}/bin/cpupower frequency-set --governor $1
          '';
        in
        ''
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0666"
          SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${power} powersave"
          SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${power} performance"
        '';
    };
    xserver = {
      # videoDrivers = [ "nvidia" ];
    };
    stratis.enable = true;
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

  fonts.enableDefaultFonts = false;
  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-emoji
    jetbrains-mono
    (nerdfonts.override { fonts = [ "JetBrainsMono" "RobotoMono" ]; })
  ];
  fonts.fontconfig.defaultFonts = pkgs.lib.mkForce {
    serif = [ "Noto Serif" "Noto Serif CJK SC" ];
    sansSerif = [ "Noto Sans" "Noto Sans CJK SC" ];
    monospace = [ "JetBrains Mono" ];
    emoji = [ "Noto Color Emoji" ];
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
  };

  zramSwap.enable = true;

  hardware.keyboard.uhk.enable = true;

  system.stateVersion = "20.09";
  documentation.nixos.enable = false;
}
