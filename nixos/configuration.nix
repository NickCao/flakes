{ config, pkgs, ... }:
let
  flake-registry = pkgs.writeText "flake-registry.json" (builtins.toJSON {
    flakes = [
      {
        from = { id = "f"; type = "indirect"; };
        to = { path = "${config.users.users.nickcao.home}/Projects/flakes"; type = "path"; };
      }
    ];
    version = 2;
  });
in
{
  imports = [ ./hardware.nix ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.nickcao = import ./home.nix;
  };

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.rait = { };
  sops.sshKeyPaths = [ "/var/lib/ssh/ssh_host_rsa_key" ];

  nix = {
    autoOptimiseStore = true;
    binaryCaches =
      [ "https://mirrors4.bfsu.edu.cn/nix-channels/store" "https://r.nichi.co/https:/cache.nixos.org" "https://nichi.cachix.org" ];
    binaryCachePublicKeys = [ "nichi.cachix.org-1:ZWn4Jui6odEcNEMjcHM/WXbDSVO4Ai+jrzWHf+pqwj0=" ];
    trustedUsers = [ "root" "nickcao" ];
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes ca-references
      builders-use-substitutes = true
      flake-registry = ${flake-registry}
      keep-outputs = true
      keep-derivations = true
    '';
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
    "goland"
    "steam"
    "steam-original"
    "steam-runtime"
    "nvidia-x11"
    "nvidia-settings"
    "vimplugin-tabnine-vim"
  ];

  networking = {
    hostName = "local";
    domain = "nichi.link";
    firewall.enable = false;
    networkmanager.dns = "dnsmasq";
    networkmanager.wifi.backend = "iwd";
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

  powerManagement.cpuFreqGovernor = "schedutil";

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernel = {
      sysctl = {
        "dev.i915.perf_stream_paranoid" = 0;
        "kernel.panic" = 10;
        "kernel.sysrq" = 1;
      };
    };
    kernelPackages = pkgs.linuxPackages_5_10;
    kernelParams = pkgs.lib.mkAfter [
      "mitigations=off"
      "nowatchdog"
      "systemd.unified_cgroup_hierarchy=1"
      "intel_iommu=on"
      "iommu=pt"
      "intel_pstate=passive"
    ];
    kernelModules = [ "ec_sys" ];
    extraModprobeConfig = ''
      options i915 enable_guc=2
      options i915 enable_fbc=1
      options i915 fastboot=1
      options nvidia NVreg_DynamicPowerManagement=0x02
    '';
  };

  virtualisation = {
    virtualbox = { host = { enable = true; }; };
    podman = { enable = true; };
  };

  hardware = {
    pulseaudio.enable = false;
    cpu = { intel = { updateMicrocode = true; }; };
    bluetooth = { enable = true; };
    nvidia = {
      prime = {
        offload.enable = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
    opengl = {
      enable = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [ intel-media-driver ];
    };
  };

  services = {
    gnome3.core-utilities.enable = false;
    gnome3.gnome-keyring.enable = pkgs.lib.mkForce false;
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
        # Enable runtime PM for NVIDIA VGA/3D controller devices on driver bind
        ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
        ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"

        # Disable runtime PM for NVIDIA VGA/3D controller devices on driver unbind
        ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="on"
        ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"
      '';
      extraHwdb = ''
        evdev:input:b0005v05ACp024F*
          KEYBOARD_KEY_70039=backspace
      '';
    };
    xserver = {
      enable = true;
      displayManager = { gdm = { enable = true; }; };
      desktopManager = { gnome3 = { enable = true; }; };
      videoDrivers = [ "nvidia" ];
    };
    pcscd = { enable = true; };
    smartdns = {
      enable = true;
      settings = with pkgs; {
        conf-file = [
          "${smartdns-china-list}/accelerated-domains.china.smartdns.conf"
          "${smartdns-china-list}/apple.china.smartdns.conf"
          "${smartdns-china-list}/google.china.smartdns.conf"
        ];
        nameserver =
          [ "/cache.nixos.org/china" "/.6in4.dev/china" ];
        bind = [ "127.0.0.53:53" ];
        server = [
          "127.0.0.1 -group china -exclude-default-group"
          "2a0c:b641:69c:f254:0:5:0:3"
        ];
        server-https = [
          "https://223.5.5.5/dns-query -group china -exclude-default-group"
          "https://101.6.6.6:8443/dns-query"
        ];
      };
    };
  };

  programs = {
    command-not-found = { enable = false; };
    vim = { defaultEditor = true; };
    steam = { enable = true; };
  };

  users = {
    mutableUsers = false;
    users = {
      nickcao = {
        isNormalUser = true;
        hashedPassword =
          "$6$n7lnnelApqi$ulDiRUraojX4zlMiuP4qP./qGZYbTGKVqTsN5z.5HlAGgIy23WMpxBA5fjFyY.RGOepAaZV8cK0tt3duMgVy30";
        extraGroups = [ "wheel" "networkmanager" ];
      };
    };
  };

  environment.etc = {
    "nixos/flake.nix".source = config.users.users.nickcao.home + "/Projects/flakes/flake.nix";
    "machine-id".text = "34df62c767c846d5a93eb2d6f05d9e1d";
    "rait/rait.conf".source = config.sops.secrets.rait.path;
    "rait/babeld.conf".text = ''
      random-id true
      export-table 254
      local-path-readwrite /run/babeld.ctl

      # to make babeld happy
      interface foo

      redistribute ip 2a0c:b641:690::/44 ge 64 le 64 allow
      redistribute local deny
    '';
  };

  systemd.services.gravity = {
    description = "the gravity overlay network";
    serviceConfig = {
      ExecStartPre = "${pkgs.iproute}/bin/ip netns add gravity";
      ExecStopPost = "${pkgs.iproute}/bin/ip netns del gravity";
      ExecStart =
        "${pkgs.iproute}/bin/ip netns exec gravity ${pkgs.babeld}/bin/babeld -S '' -I '' -c /etc/rait/babeld.conf";
      ExecStartPost = [
        "${pkgs.rait}/bin/rait up"
        "${pkgs.iproute}/bin/ip link add gravity address 00:00:00:00:00:01 type veth peer host address 00:00:00:00:00:02 netns gravity"
        "${pkgs.iproute}/bin/ip link set up gravity"
        "${pkgs.iproute}/bin/ip route add default via fe80::200:ff:fe00:2 dev gravity"
        "${pkgs.iproute}/bin/ip addr replace 2a0c:b641:69c:99cc::2/64 dev gravity"
        "${pkgs.iproute}/bin/ip -n gravity link set up lo"
        "${pkgs.iproute}/bin/ip -n gravity link set up host"
        "${pkgs.iproute}/bin/ip -n gravity addr replace 2a0c:b641:69c:99cc::1/64 dev host"
      ];
      ExecReload = "${pkgs.rait}/bin/rait sync";
    };
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
  };

  security.pam.u2f = {
    enable = true;
    authFile = pkgs.writeText "u2f-mappings" ''
      nickcao:8KGtTGZAEfnsqPDCY3MQFv3Ef9njqy39JHgc5WDC8aiekH1mGS5hq1XmT+og8TpaxgMPzHs7G/oa58RyLw/Odw==,At2tDFQSBa+P+GPNVLPzVzHpVOfS4l+mJOFhCThAf2VEeBVf315Wocy9kFRDr05QdGPlwcOkXOao4Dja6cl7/w==,es256,+presence
    '';
    control = "sufficient";
    cue = true;
  };

  environment.systemPackages = with pkgs; [
    prime-run
    steam-run-native
    cachix
    ldns
    nixpkgs-fmt
    tree
    mtr
    auth-thu
    jq
    terraform_0_14
    python3
    hugo
    v2ray.core
    v2ray-geoip
    v2ray-domain-list-community
    qv2ray
    rait
    mpv
    terraform-ls
    yubikey-manager
    tdesktop
    materia-theme
    wireguard-tools
    smartmontools
    numix-icon-theme-circle
    chromium
    minio-client
    jetbrains.goland
    gnome3.gnome-tweak-tool
    gnome3.nautilus
    gnome3.gnome-screenshot
    gnome3.baobab
    gnomeExtensions.appindicator
  ];

  fonts.fonts = with pkgs; [
    roboto
    jetbrains-mono
    powerline-fonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-extra
    noto-fonts-emoji
  ];

  system.stateVersion = "20.09";
}
