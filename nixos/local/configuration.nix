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
      wireless = { };
      restic = { };
      tsinghua-secure = { path = "/var/lib/iwd/Tsinghua-Secure.8021x"; };
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
      substituters = pkgs.lib.mkForce [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://cache.nixos.org"
        "https://cache.nichi.co"
      ];
      trusted-public-keys = [ "hydra.nichi.co-0:P3nkYHhmcLR3eNJgOAnHDjmQLkfqheGyhZ6GLrUVHwk=" ];
      auto-optimise-store = true;
      flake-registry = "/etc/nix/registry.json";
      experimental-features = [ "nix-command" "flakes" "ca-derivations" "impure-derivations" ];
      builders-use-substitutes = true;
      keep-derivations = true;
    };
  };

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
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/efi";
      systemd-boot.enable = true;
    };
    kernel = {
      sysctl = {
        "kernel.panic" = 10;
        "kernel.sysrq" = 1;
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = with config.boot.kernelPackages; [
      v4l2loopback
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

  environment.systemPackages = [ config.boot.kernelPackages.usbip ];

  virtualisation = {
    podman.enable = true;
    kvmgt = {
      enable = true;
      vgpus = {
        i915-GVTg_V5_4.uuid = [ "d577a7cf-2595-44d8-9c08-c67358dcf7ac" ];
      };
    };
    vmVariant = {
      virtualisation = {
        useDefaultFilesystems = false;
        fileSystems."/" = {
          fsType = "tmpfs";
          options = [ "defaults" "mode=755" ];
        };
      };
      boot.initrd.systemd.enable = pkgs.lib.mkForce false;
      users.users.nickcao = {
        password = "passwd";
        passwordFile = pkgs.lib.mkForce null;
      };
      services.gravity.enable = pkgs.lib.mkForce false;
      systemd.services.gravity-proxy.enable = false;
      environment.persistence."/persist" = pkgs.lib.mkForce { };
    };
  };

  hardware = {
    pulseaudio.enable = false;
    cpu.intel.updateMicrocode = true;
    bluetooth.enable = true;
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

  systemd.services.greetd.serviceConfig = {
    ExecStartPre = "${pkgs.util-linux}/bin/kill -SIGRTMIN+21 1";
    ExecStopPost = "${pkgs.util-linux}/bin/kill -SIGRTMIN+20 1";
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session.command = "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd sway";
    };
  };

  services = {
    nscd.enableNsncd = true;
    resolved = {
      dnssec = "false";
      llmnr = "false";
    };
    restic.backups = {
      hel0 = {
        repository = "sftp:nickcao@hel0.nichi.link:backup";
        passwordFile = config.sops.secrets.restic.path;
        paths = [ "/persist" ];
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
    stratis.enable = true;
  };

  programs = {
    # adb.enable = true;
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

  systemd.services."user@".serviceConfig.Delegate = [ "cpu" ];

  fonts.enableDefaultFonts = false;
  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-emoji
    jetbrains-mono
    (nerdfonts.override { fonts = [ "JetBrainsMono" "Noto" ]; })
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

  system.stateVersion = "20.09";
  documentation.nixos.enable = false;
}
