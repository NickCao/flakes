{ config, pkgs, ... }:
let
  flake-registry = pkgs.writeText "flake-registry.json" (builtins.toJSON {
    flakes = [
      {
        from = { id = "p"; type = "indirect"; };
        to = { owner = "NixOS"; ref = "nixos-unstable-small"; repo = "nixpkgs"; type = "github"; };
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
      [ "https://mirrors4.tuna.tsinghua.edu.cn/nix-channels/store" "https://r.nichi.co/https:/cache.nixos.org" "https://nichi.cachix.org" ];
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

  nixpkgs.config.allowUnfree = true;

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
    kernelPackages = pkgs.linuxPackages_latest.extend
      (self: super: {
        virtualbox = super.virtualbox.overrideAttrs (attrs: {
          patches = [
            (builtins.fetchurl {
              url = "https://pb.nichi.co/steak-denial-penalty";
              sha256 =
                "sha256:04wp9fggyid8drfc4z7rd9bq56z54532js7azw5nnbydhjxaigwd";
            })
          ];
        });
      });
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
      #nvidiaPersistenced = true;
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
    pipewire = {
      enable = true;
      package = pkgs.pipewire.overrideAttrs (attrs: {
        src = pkgs.fetchFromGitLab {
          domain = "gitlab.freedesktop.org";
          owner = "pipewire";
          repo = "pipewire";
          rev = "4b076549f743b8fd6d1b0346c9b878282b88ca6a";
          sha256 = "sha256-xLilT2zxzf+WK1JEuQNxVvpj3Ma9QTGO43E42I0bAHs=";
        };
        buildInputs = attrs.buildInputs ++ [ pkgs.fdk_aac ];
      });
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
          [ "/.cn/china" "/.tsinghua.edu.cn/china" "/cache.nixos.org/china" ];
        bind = [ "127.0.0.53:53" ];
        server = [
          "127.0.0.1 -group china -exclude-default-group"
          "2a0c:b641:69c:f254:0:5:0:3"
        ];
        server-https = [ "https://1.0.0.1/dns-query" ];
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

  environment.etc."machine-id".text = "c9943e5a9c6c416184c4b49c733607b4";
  environment.etc."rait/rait.conf".source = "/run/secrets/rait";
  environment.etc."rait/babeld.conf".text = ''
    random-id true
    export-table 254
    local-path-readwrite /run/babeld.ctl

    # to make babeld happy
    interface foo

    redistribute ip 2a0c:b641:690::/44 ge 64 le 64 allow
    redistribute local deny
  '';

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

  environment.systemPackages = with pkgs; [
    (pkgs.writeShellScriptBin "prime-run" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec -a "$0" "$@"
    '')
    steam-run-native
    cachix
    ldns
    nixpkgs-fmt
    tree
    mtr
    gcc
    gnumake
    patchage
    auth-thu
    jq
    terraform_0_14
    python3
    hugo
    nfs-utils
    google-cloud-sdk
    v2ray.core
    v2ray-geoip
    v2ray-domain-list-community
    qv2ray
    rait
    mpv
    (pkgs.vscode-with-extensions.override {
      vscodeExtensions = (with pkgs.vscode-extensions;
        [ redhat.vscode-yaml bbenoist.Nix ]
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [{
          name = "terraform";
          publisher = "hashicorp";
          version = "2.3.0";
          sha256 = "sha256-GJv6zSEwv6aAgyz8h8JHKdMjOV77lyQQwGVNky3CJhk=";
        }]);
    })
    terraform-ls
    yubikey-manager
    tdesktop
    materia-theme
    wireguard-tools
    smartmontools
    numix-icon-theme-circle
    gnome3.gnome-tweak-tool
    gnomeExtensions.appindicator
    chromium
    jetbrains.clion
    jetbrains.goland
    minio-client
  ];

  environment.gnome3.excludePackages = with pkgs.gnome3; [
    geary
    gnome-terminal
    gnome-calculator
    gnome-calendar
    gnome-characters
    gnome-clocks
    gnome-contacts
    gnome-font-viewer
    gnome-maps
    gnome-logs
    gnome-music
    gnome-weather
    simple-scan
    gedit
    totem
    yelp
    cheese
    pkgs.gnome-connections
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
