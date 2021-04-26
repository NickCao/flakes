{ pkgs, config, ... }:
let
  toTOMLDrv = v: (pkgs.formats.toml { }).generate "" v;
  mkWrap = name: cmd: pkgs.writeShellScriptBin name "exec ${cmd} \"$@\"";
in
{
  home.packages = with pkgs; [
    clang_12
    rust-bin.nightly.latest.minimal
    age
    pandoc
    prime-run
    wireguard-tools
    jq
    auth-thu
    nixpkgs-fmt
    cachix
    smartmontools
    rait
    python3
    ldns
    tree
    mtr
    go_1_16
    sops
    kustomize
    update-nix-fetchgit
    (mkWrap "mc" "${minio-client}/bin/mc --config-dir ${config.xdg.configHome}/mc")
    (mkWrap "kubectl" "${kubectl}/bin/kubectl --cache-dir=${config.xdg.cacheHome}/kube --kubeconfig=${config.xdg.configHome}/kubeconfig")
    (mkWrap "terraform" "${coreutils}/bin/env TF_PLUGIN_CACHE_DIR=${config.xdg.cacheHome}/terraform CHECKPOINT_DISABLE=1 ${terraform_0_15}/bin/terraform")
    ko
    butane
    restic
    libarchive
  ];

  systemd.user.sessionVariables = {
    GOOGLE_DEFAULT_CLIENT_ID = "77185425430.apps.googleusercontent.com";
    GOOGLE_DEFAULT_CLIENT_SECRET = "OTJgUOQcT7lO7GsGZq2G4IlT";
    LIBVA_DRIVER_NAME = "iHD";
    # cache
    XCOMPOSECACHE = "${config.xdg.cacheHome}/compose";
    __GL_SHADER_DISK_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    # config
    REGISTRY_AUTH_FILE = "${config.xdg.configHome}/containers/auth.json";
    # data
    HISTFILE = "${config.xdg.dataHome}/bash_history";
    LESSHISTFILE = "${config.xdg.dataHome}/lesshst";
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    # shit
    PYTHONSTARTUP = (pkgs.writeText "start.py" ''
      import readline
      readline.write_history_file = lambda *args: None
    '').outPath;
  };

  programs = {
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
      homedir = "${config.xdg.dataHome}/gnupg";
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
        pull.rebase = true;
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
      extraConfig = ''
        set -g mouse on
        set -g status-right ""
        set -gs escape-time 10
        set -g default-terminal "tmux-256color"
        set -ga terminal-overrides ",alacritty:Tc"
        new-session -s main
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
          args = [ "new-session" "-t" "main" ];
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
        "image/jpeg" = [ "org.gnome.eog.desktop" ];
        "image/jpg" = [ "org.gnome.eog.desktop" ];
        "image/png" = [ "org.gnome.eog.desktop" ];
      };
    };
    configFile = {
      "gnome-initial-setup-done".text = "yes";
      "autostart/qv2ray.desktop".text = ''
        [Desktop Entry]
        Name=qv2ray
        GenericName=V2Ray Frontend
        Exec=bash -c "sleep 5; qv2ray"
        Terminal=false
        Icon=qv2ray
        Categories=Network
        Type=Application
        StartupNotify=false
        X-GNOME-Autostart-enabled=true
      '';
      "autostart/telegramdesktop.desktop".text = ''
        [Desktop Entry]
        Version=1.0
        Name=Telegram Desktop
        Comment=Official desktop version of Telegram messaging app
        Exec=telegram-desktop -workdir ${config.xdg.dataHome}/TelegramDesktop/ -autostart
        Icon=telegram
        Terminal=false
        StartupWMClass=TelegramDesktop
        Type=Application
        Categories=Chat;Network;InstantMessaging;Qt;
        MimeType=x-scheme-handler/tg;
        Keywords=tg;chat;im;messaging;messenger;sms;tdesktop;
        X-GNOME-UsesNotifications=true
      '';
      "go/env".text = ''
        GOPATH=${config.xdg.cacheHome}/go
        GOBIN=${config.xdg.dataHome}/go/bin
        GO111MODULE=on
        GOPROXY=https://goproxy.cn
        GOSUMDB=sum.golang.google.cn
      '';
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
