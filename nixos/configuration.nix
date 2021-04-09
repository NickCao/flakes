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
    sshKeyPaths = [ "/var/lib/ssh/ssh_host_rsa_key" ];
  };

  nix = {
    autoOptimiseStore = true;
    binaryCaches = [ "https://mirrors4.bfsu.edu.cn/nix-channels/store" "https://cache.nichi.workers.dev" "https://nichi.cachix.org" "https://nix-community.cachix.org" ];
    binaryCachePublicKeys = [ "nichi.cachix.org-1:ZWn4Jui6odEcNEMjcHM/WXbDSVO4Ai+jrzWHf+pqwj0=" "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
    trustedUsers = [ "root" "nickcao" ];
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes ca-references
      builders-use-substitutes = true
      keep-outputs = true
      keep-derivations = true
    '';
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
    "goland"
    "nvidia-x11"
    "nvidia-settings"
    "vimplugin-tabnine-vim"
    "quartus-prime-lite-unwrapped"
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

  powerManagement.cpuFreqGovernor = "schedutil";

  boot = {
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
    kernelPackages = pkgs.linuxPackages_testing;
    kernelParams = [
      "quiet"
      "udev.log_level=3"
      "mitigations=off"
      "nowatchdog"
      "systemd.unified_cgroup_hierarchy=1"
      "intel_iommu=on"
      "iommu=pt"
      "intel_pstate=passive"
    ];
    kernelModules = [ "ec_sys" ];
    extraModprobeConfig = ''
      options i915 enable_guc=0
      options i915 enable_fbc=1
      options i915 fastboot=1
      blacklist ideapad_laptop
    '';
  };

  virtualisation = {
    kvmgt = {
      enable = true;
      vgpus = {
        i915-GVTg_V5_4 = {
          uuid = [ "ccde96df-75f1-4846-bb66-4454f1482029" ];
        };
      };
    };
    libvirtd.enable = true;
    podman.enable = true;
  };

  hardware = {
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

  services = {
    logind.lidSwitch = "ignore";
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
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6001", MODE="0666"
      '';
    };
    xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome3.enable = true;
      videoDrivers = [ "nvidia" ];
    };
    pcscd.enable = true;
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
    neovim = {
      enable = true;
      package = pkgs.neovim-nightly;
      vimAlias = true;
      viAlias = true;
      defaultEditor = true;
      configure = {
        customRC = ''
          set number
          set background=light
          colorscheme solarized
          let g:netrw_liststyle = 3 " tree style
          let g:netrw_banner = 0 " no banner
          let g:netrw_browse_split = 3 " new tab
          let g:airline_theme = 'solarized'
          set tabstop=2 shiftwidth=2 expandtab smarttab
          " auto format
          let g:formatdef_nix = '"${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt"'
          let g:formatdef_yaml = '"${pkgs.nodePackages.prettier}/bin/prettier --parser yaml"'
          let g:formatdef_tf = '"${pkgs.terraform_0_14}/bin/terraform fmt -"'
          let g:formatters_nix = [ 'nix' ]
          let g:formatters_yaml = [ 'yaml' ]
          let g:formatters_tf = [ 'tf' ]
        '';
        packages.vim = {
          start = with pkgs.vimPlugins; [ solarized nvim-lspconfig vim-nix vim-lastplace vim-autoformat vim-airline vim-airline-themes ];
        };
      };
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
        hashedPassword = "$6$n7lnnelApqi$ulDiRUraojX4zlMiuP4qP./qGZYbTGKVqTsN5z.5HlAGgIy23WMpxBA5fjFyY.RGOepAaZV8cK0tt3duMgVy30";
        extraGroups = [ "wheel" "networkmanager" "libvirtd" ];
      };
    };
  };

  environment.etc = {
    "nixos/flake.nix".source = config.users.users.nickcao.home + "/Projects/flakes/flake.nix";
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
    virt-manager
    fcitx5-pinyin-zhwiki-rime
    quartus-prime-lite
    mode
    chromium
    v2ray
    v2ray-geoip
    v2ray-domain-list-community
    (qv2ray.override { plugins = [ qv2ray-plugin-ss qv2ray-plugin-ssr ]; })
    mpv
    yubikey-manager
    tdesktop
    materia-theme
    numix-icon-theme-circle
    jetbrains.goland
    gnome3.gnome-tweak-tool
    gnome3.nautilus
    gnome3.gnome-screenshot
    gnome3.baobab
    gnome3.eog
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
