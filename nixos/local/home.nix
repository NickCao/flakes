{ pkgs, config, ... }:
let
  toTOMLDrv = v: (pkgs.formats.toml { }).generate "" v;
  toYAMLDrv = v: (pkgs.formats.yaml { }).generate "" v;
  mkWrap = name: cmd: pkgs.writeShellScriptBin name "exec ${cmd} \"$@\"";
in
{
  home.packages = with pkgs; [
    ncdu
    mode
    yubikey-manager
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
    (mkWrap "mc" "${minio-client}/bin/mc --config-dir ${config.xdg.configHome}/mc")
    (mkWrap "terraform" "${coreutils}/bin/env TF_PLUGIN_CACHE_DIR=${config.xdg.cacheHome}/terraform CHECKPOINT_DISABLE=1 ${terraform}/bin/terraform")
    restic
    libarchive
  ];

  dconf.settings = import ./dconf.nix;

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
    PYTHONSTARTUP = (
      pkgs.writeText "start.py" ''
        import readline
        readline.write_history_file = lambda *args: None
      ''
    ).outPath;
  };

  programs = {
    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
        enableFlakes = true;
      };
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
        function fish_user_key_bindings
          fish_vi_key_bindings
          bind f accept-autosuggestion
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
        # shlvl = { disabled = false; symbol = ""; };
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
    ssh = {
      enable = true;
      compression = true;
      serverAliveInterval = 30;
      extraConfig = ''
        CheckHostIP no
      '';
    };
  };
  services = {
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
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
    configFile = {
      "qv2ray/plugin_settings/builtin_v2ray_support.json".source = (pkgs.formats.json {}).generate "v2ray.json" {
        AssetsPath = "${pkgs.symlinkJoin { name = "assets"; paths = [ pkgs.v2ray-geoip pkgs.v2ray-domain-list-community.data ]; }}/share/v2ray";
        CorePath = "${pkgs.v2ray.core}/bin/v2ray";
      };
      "gnome-initial-setup-done".text = "yes";
      "autostart/qv2ray.desktop".text = ''
        [Desktop Entry]
        Name=qv2ray
        GenericName=V2Ray Frontend
        Exec=qv2ray
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
        Exec=telegram-desktop -workdir ${config.xdg.dataHome}/TelegramDesktop/ -startintray
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
      "containers/storage.conf".source = toTOMLDrv {
        storage = {
          driver = "btrfs";
        };
      };
      "ibus/rime/default.custom.yaml".text = ''
        patch:
          schema_list:
            - schema: double_pinyin_flypy
      '';
      "ibus/rime/double_pinyin_flypy.custom.yaml".text = ''
        patch:
          translator/preedit_format: []
      '';
    };
  };
}
