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
      passwd.neededForUsers = true;
      u2f = { mode = "0444"; };
      wireless = { };
      restic = { };
    };
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  nix = {
    package = pkgs.nixVersions.stable;
    settings = {
      trusted-users = [ "root" "nickcao" ];
      substituters = pkgs.lib.mkBefore [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" "https://cache.nichi.co" ];
      trusted-public-keys = [ "hydra.nichi.co-0:P3nkYHhmcLR3eNJgOAnHDjmQLkfqheGyhZ6GLrUVHwk=" ];
      auto-optimise-store = true;
      flake-registry = "/etc/nix/registry.json";
      experimental-features = [ "nix-command" "flakes" "ca-derivations" "impure-derivations" ];
      builders-use-substitutes = true;
      keep-derivations = true;
    };
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
    "nvidia-x11"
  ];

  networking = {
    hostName = "local";
    domain = "nichi.link";
    firewall.enable = false;
    useNetworkd = true;
    useDHCP = false;
    hosts = {
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
  systemd.network.wait-online = {
    anyInterface = true;
    ignoredInterfaces = [ "gravity" "gravity-bind" ];
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
      address = [ "10.0.1.1/24" ];
      networkConfig = {
        DHCPServer = true;
      };
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
    initrd.kernelModules = [ "i915" ];
    loader = {
      timeout = 0;
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
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
    spiceUSBRedirection.enable = true;
  };

  hardware = {
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      open = false;
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

  programs.ssh = {
    knownHosts = {
      "@cert-authority *.nichi.link".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEe0p7erHjrkNKcY/Kp6fvZtxLcl0hVMVMQPhQrPDZKp";
    };
    extraConfig = ''
      Host hel0.nichi.link
        IdentityFile ${config.users.users.nickcao.home}/.ssh/id_ed25519
    '';
  };

  services = {
    resolved = {
      dnssec = "false";
      llmnr = "false";
    };
    restic.backups = {
      hel0 = {
        repository = "sftp:nickcao@hel0.nichi.link:backup";
        passwordFile = config.sops.secrets.restic.path;
        paths = [ "/persistent" ];
        extraBackupArgs = [ "--exclude-caches" ];
        timerConfig = {
          OnBootSec = "15min";
        };
      };
    };
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
        extraGroups = [ "wheel" ];
      };
    };
  };

  environment.pathsToLink = [ "/share/fish" ];

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

  systemd.services."user@".serviceConfig.Delegate = [ "cpu" ];

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
        ".config/nheko"
      ];
    };
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };

  system.stateVersion = "20.09";
  documentation.nixos.enable = false;
}
