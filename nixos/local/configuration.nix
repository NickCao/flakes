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
    binaryCaches = pkgs.lib.mkForce [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" "https://cache.nichi.workers.dev" "https://nichi.cachix.org" ];
    binaryCachePublicKeys = [ "nichi.cachix.org-1:ZWn4Jui6odEcNEMjcHM/WXbDSVO4Ai+jrzWHf+pqwj0=" ];
    trustedUsers = [ "root" "nickcao" ];
    package = pkgs.nixFlakes;
    extraOptions = ''
      flake-registry = /etc/nix/registry.json
      experimental-features = nix-command flakes ca-references ca-derivations
      builders-use-substitutes = true
      keep-outputs = true
      keep-derivations = true
    '';
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
    "nvidia-x11"
    "nvidia-settings"
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

  powerManagement.cpuFreqGovernor = "powersave";

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
    '';
    enableContainers = false;
  };

  virtualisation = {
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
    fstrim.enable = true;
    packagekit.enable = false;
    logind.lidSwitch = "ignore";
    gnome.core-utilities.enable = false;
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
    udev = {
      packages = [ pkgs.yubikey-personalization pkgs.libu2f-host ];
      extraRules = ''
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6001", MODE="0666"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0113|0114|0115|0116|0120|0200|0402|0403|0406|0407|0410", TAG+="uaccess"
      '';
    };
    xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      videoDrivers = [ "nvidia" ];
    };
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
          "2a0c:b641:69c:7864:0:5:0:3"
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
          " shortcuts
          noremap <C-x> <Esc>:x<CR>
          noremap <C-s> <Esc>:w<CR>
          noremap <C-q> <Esc>:q!<CR>
          set number
          set background=light
          set clipboard+=unnamedplus
          colorscheme solarized
          let g:netrw_liststyle = 3 " tree style
          let g:netrw_banner = 0 " no banner
          let g:netrw_browse_split = 3 " new tab
          let g:airline_theme = 'solarized'
          set tabstop=2 shiftwidth=2 expandtab smarttab
          " cycle through completions with tab
          inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
          inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
          set completeopt=menuone,noinsert,noselect
          set shortmess+=c
          lua << EOF
          local nvim_lsp = require('lspconfig')
          local on_attach = function(client, bufnr)
            require('completion').on_attach()
            local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
            local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end
            buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')
            local opts = { noremap=true, silent=true }
            buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
            buf_set_keymap('n', 'gi', '<Cmd>lua vim.lsp.buf.implementation()<CR>', opts)
            buf_set_keymap('n', 'gr', '<Cmd>lua vim.lsp.buf.references()<CR>', opts)
            buf_set_keymap('n', '<Space>h', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
            buf_set_keymap('n', '<Space>rn', '<Cmd>lua vim.lsp.buf.rename()<CR>', opts)
            buf_set_keymap('n', '<Space>f', '<Cmd>lua vim.lsp.buf.formatting()<CR>', opts)
          end
          nvim_lsp['gopls'].setup { on_attach = on_attach, cmd = { '${pkgs.gopls}/bin/gopls' } }
          nvim_lsp['rust_analyzer'].setup { on_attach = on_attach, cmd = { '${pkgs.rust-analyzer}/bin/rust-analyzer' } }
          nvim_lsp['yamlls'].setup { on_attach = on_attach, cmd = { '${pkgs.yaml-language-server}/bin/yaml-language-server', '--stdio'} }
          nvim_lsp['terraformls'].setup { on_attach = on_attach, cmd = { '${pkgs.terraform-ls}/bin/terraform-ls', 'serve' }, filetypes = { 'tf' } }
          EOF
        '';
        packages.vim = {
          start = with pkgs.vimPlugins; [
            # solarized themes make my day
            vim-colors-solarized
            # nice and lean status line
            vim-airline
            vim-airline-themes
            # lsp client config
            nvim-lspconfig
            completion-nvim
            # misc
            vim-nix
            vim-lastplace
          ];
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
    (
      writeShellScriptBin "xterm" ''
        exec ${alacritty}/bin/alacritty "$@"
      ''
    )
    virt-manager
    quartus-prime-lite
    mode
    (chromium.override { commandLineArgs = "--enable-features=VaapiVideoDecoder"; })
    v2ray
    v2ray-geoip
    v2ray-domain-list-community
    (qv2ray.override { plugins = [ qv2ray-plugin-ss ]; })
    mpv
    yubikey-manager
    tdesktop
    materia-theme
    numix-icon-theme-circle
    gnome3.gnome-tweaks
    gnome3.nautilus
    gnome3.gnome-screenshot
    gnome3.baobab
    gnome3.eog
    gnomeExtensions.appindicator
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
