{ pkgs, config, ... }:
let
  toTOMLDrv = v: (pkgs.formats.toml { }).generate "" v;
in
{
  home.packages = with pkgs; [
    kubeseal
    prime-run
    wireguard-tools
    steam-run-native
    jq
    auth-thu
    nixpkgs-fmt
    cachix
    smartmontools
    minio-client
    terraform_0_14
    rait
    hugo
    python3
    ldns
    tree
    mtr
    gopls
    go_1_16
    sops
    update-nix-fetchgit
    kubectl
    ko
    kubeone
    fcct
    restic
  ];

  systemd.user.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
    SOPS_PGP_FP = "068A56CEF48FA2C1";
    KO_DOCKER_REPO = "quay.io/nickcao";
    XCOMPOSECACHE = "${config.xdg.cacheHome}/compose";
    LESSHISTFILE = "${config.xdg.cacheHome}/lesshst";
    __GL_SHADER_DISK_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    KUBECONFIG = "${config.xdg.configHome}/kubeconfig";
    TF_CLI_CONFIG_FILE = "${config.xdg.configHome}/terraformrc";
    PYTHONSTARTUP = (pkgs.writeText "start.py" ''
      import readline
      readline.set_auto_history(False)
    '').outPath;
  };

  programs = {
    vim = {
      enable = true;
      plugins = with pkgs.vimPlugins; [ vim-lastplace vim-autoformat vim-airline vim-airline-themes pkgs.tabnine-vim ];
      extraConfig = ''
        set viminfo+=n${config.xdg.cacheHome}/viminfo
        let g:airline_theme = 'solarized'

        " file explorer
        let g:netrw_liststyle = 3
        let g:netrw_banner = 0
        let g:netrw_browse_split = 3
        let g:netrw_winsize = 25
        let g:netrw_dirhistmax = 0

        " line number
        set number

        " format
        let g:formatdef_nixpkgs_fmt = '"${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt"'
        let g:formatdef_prettier_yaml = '"${pkgs.nodePackages.prettier}/bin/prettier --parser yaml"'
        let g:formatdef_terraform = '"${pkgs.terraform_0_14}/bin/terraform fmt -"'
        let g:formatters_nix = [ 'nixpkgs_fmt' ]
        let g:formatters_yaml = [ 'prettier_yaml' ]
        let g:formatters_tf = [ 'terraform' ]
      '';
    };
    direnv = {
      enable = true;
      enableNixDirenvIntegration = true;
    };
    bat = {
      enable = true;
      config = {
        theme = "Solarized (light)";
      };
    };
    gpg = {
      enable = true;
      settings = {
        trust-model = "tofu";
      };
    };
    git = {
      enable = true;
      userEmail = "nickcao@nichi.co";
      userName = "Nick Cao";
      signing = {
        signByDefault = true;
        key = "A1E513A77CC0D91C8806A4EB068A56CEF48FA2C1";
      };
      extraConfig = {
        pull.rebase = false;
        init.defaultBranch = "master";
      };
    };
    fish = {
      enable = true;
      shellInit = ''
        set fish_greeting
      '';
      shellAliases = {
        freq = "sudo ${pkgs.linuxPackages.cpupower}/bin/cpupower frequency-set -g";
      };
    };
    starship = {
      enable = true;
      settings = {
        add_newline = false;
        gcloud = { disabled = true; };
        battery = { disabled = true; };
      };
    };
    tmux = {
      enable = true;
      shell = "${pkgs.fish}/bin/fish";
      keyMode = "vi";
      newSession = true;
      extraConfig = ''
        set -g mouse on
        set -g status-right ""
      '';
    };
    alacritty = {
      enable = true;
      settings = {
        font = {
          normal = { family = "JetBrains Mono"; };
          size = 13;
        };
        colors = (import ./alacritty.nix).light;
        shell = {
          program = "${pkgs.tmux}/bin/tmux";
          args = [ "attach" ];
        };
      };
    };
  };
  services = {
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
    };
  };
  home = {
    file = {
      ".ssh/authorized_keys" = {
        text = "";
      };
      ".ssh/config" = {
        text = ''
          Match User core
            StrictHostKeyChecking no
            UserKnownHostsFile /dev/null
          Host *
            CheckHostIP no
            ServerAliveInterval 60
        '';
      };
    };
  };

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      desktop = "$HOME";
      templates = "$HOME";
      music = "$HOME";
      videos = "$HOME";
      publicShare = "$HOME";
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/tg" = [ "telegramdesktop.desktop" ];
      };
    };
    configFile = {
      "gnome-initial-setup-done".text = "yes";
      "go/env" = {
        text = ''
          GOPATH=${config.xdg.cacheHome}/go
          GOBIN=${config.home.homeDirectory}/Bin
          GO111MODULE=on
          GOPROXY=https://goproxy.cn
          GOSUMDB=sum.golang.google.cn
        '';
      };
      "containers/storage.conf" = {
        source = toTOMLDrv {
          storage = {
            driver = "btrfs";
            rootless_storage_path = "${config.home.homeDirectory}/Data/Containers/";
          };
        };
      };
    };
  };
}
