{ pkgs, config, ... }:
let
  toTOMLDrv = v: (pkgs.formats.toml { }).generate "" v;
in
{
  home.packages = with pkgs; [ gopls go sops update-nix-fetchgit drone-cli buildifier kubectl kubernetes-helm ];
  systemd.user.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
    KO_DOCKER_REPO = "quay.io/nickcao";
    LESSHISTFILE = "-";
    __GL_SHADER_DISK_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    TF_CLI_CONFIG_FILE = "${config.xdg.configHome}/terraformrc";
  };
  programs = {
    vim = {
      enable = true;
      plugins = with pkgs.vimPlugins; [ vim-lastplace pkgs.tabnine-vim ];
      extraConfig = ''
        set viminfo+=n${config.xdg.cacheHome}/viminfo

        " file explorer
        let g:netrw_liststyle = 3
        let g:netrw_banner = 0
        let g:netrw_browse_split = 3
        let g:netrw_winsize = 25

        " line number
        set number
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
        set -x PATH ${config.home.homeDirectory}/Bin $PATH
        set -x SOPS_PGP_FP 068A56CEF48FA2C1
        function fish_user_key_bindings
          fish_vi_key_bindings
        end
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

  xdg.enable = true;
  xdg = {
    configFile = {
      "autostart/telegramdesktop.desktop" = {
        text = ''
          [Desktop Entry]
          Version=1.0
          Name=Telegram Desktop
          Type=Application
          Exec=${pkgs.tdesktop}/bin/telegram-desktop -workdir ${config.xdg.dataHome}/TelegramDesktop/ -autostart
          Terminal=false
        '';
      };
      "autostart/qv2ray.desktop" = {
        text = ''
          [Desktop Entry]
          Version=1.0
          Name=Qv2ray
          Type=Application
          Exec=${pkgs.qv2ray}/bin/qv2ray
          Terminal=false
        '';
      };
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
