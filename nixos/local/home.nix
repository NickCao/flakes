{ pkgs, config, ... }:
let
  toJSONDrv = (pkgs.formats.json { }).generate "";
  toTOMLDrv = (pkgs.formats.toml { }).generate "";
  toYAMLDrv = (pkgs.formats.yaml { }).generate "";
  mkWrap = name: cmd: pkgs.writeShellScriptBin name "exec ${cmd} \"$@\"";
  fbk = pkgs.fetchurl {
    url = "https://pbs.twimg.com/media/ElphQpaU4AAt9Bv?format=jpg";
    name = "fubuki.jpg";
    hash = "sha256-541/iI7scwyyEOxZAYFql4X/W5xmg5hUfeDJbtJ+voE=";
  };
in
{
  systemd.user = {
    services = {
      mako = {
        Unit.PartOf = [ "sway-session.target" ];
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.mako}/bin/mako";
          RestartSec = 3;
          Restart = "always";
        };
        Install.WantedBy = [ "sway-session.target" ];
      };
      swayidle = {
        Unit.PartOf = [ "sway-session.target" ];
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.swayidle}/bin/swayidle -w";
          RestartSec = 3;
          Restart = "always";
        };
        Install.WantedBy = [ "sway-session.target" ];
      };
    };
  };
  gtk = {
    enable = true;
    theme = {
      package = pkgs.materia-theme;
      name = "Materia";
    };
    iconTheme = {
      package = pkgs.numix-icon-theme-circle;
      name = "Numix-Circle";
    };
    font = {
      package = pkgs.roboto;
      name = "Roboto";
      size = 11;
    };
  };
  qt = {
    enable = true;
    platformTheme = "gtk";
  };
  wayland.windowManager.sway = {
    enable = true;
    package = null;
    config = {
      modifier = "Mod4";
      terminal = "alacritty";
      startup = [
        { command = "alacritty"; }
        { command = "chromium"; }
        { command = "telegram-desktop"; }
      ];
      assigns = {
        "1" = [{ app_id = "Alacritty"; }];
        "2" = [{ class = "Chromium-browser"; }];
        "3" = [{ app_id = "telegramdesktop"; }];
      };
      window.commands = [
        {
          criteria = { app_id = "pavucontrol"; };
          command = "floating enable, sticky enable, resize set width 550 px height 600px, move position cursor, move down 35";
        }
        {
          criteria = { urgent = "latest"; };
          command = "focus";
        }
      ];
      gaps = {
        inner = 5;
        outer = 5;
        smartGaps = true;
      };
      keybindings =
        let
          modifier = config.wayland.windowManager.sway.config.modifier;
        in
        pkgs.lib.mkOptionDefault {
          "${modifier}+d" = "exec ${pkgs.rofi}/bin/rofi -show run";
          "${modifier}+Shift+l" = "exec loginctl lock-session";
          "${modifier}+space" = null;
          "Print" = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" $HOME/Pictures/screenshot-$(date +\"%Y-%m-%d-%H-%M-%S\").png";
        };
      input = {
        "1739:32552:MSFT0001:01_06CB:7F28_Touchpad" = {
          natural_scroll = "enabled";
          tap = "enabled";
        };
      };
      output = {
        eDP-1 = {
          bg = "${fbk} fill";
        };
      };
      bars = [{
        mode = "dock";
        command = "${pkgs.waybar}/bin/waybar";
        position = "top";
        workspaceButtons = true;
        workspaceNumbers = true;
        trayOutput = "*";
      }];
      floating.criteria = [
        { app_id = "blueberry.py"; }
      ];
    };
  };
  accounts.email.maildirBasePath = "${config.xdg.dataHome}/maildir";
  accounts.email.accounts.nickcao = rec {
    address = "nickcao@nichi.co";
    gpg = {
      key = "068A56CEF48FA2C1";
      signByDefault = true;
    };
    imap = {
      host = "hel0.nichi.link";
      tls.enable = true;
    };
    smtp = {
      inherit (imap) host;
      tls.enable = true;
    };
    mbsync = {
      enable = true;
      create = "both";
      remove = "both";
    };
    msmtp = {
      enable = true;
    };
    neomutt = {
      enable = true;
      extraMailboxes = [ "Archive" "Drafts" "Junk" "Sent" "Trash" ];
    };
    passwordCommand = "cat ${config.xdg.configHome}/mail/password";
    primary = true;
    realName = "Nick Cao";
    userName = address;
  };
  home.packages = with pkgs; [
    waypipe
    xdg-utils
    blueberry
    pavucontrol
    brightnessctl
    ripgrep
    rnix-lsp
    ranger
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
    go_1_17
    sops
    (mkWrap "mc" "${minio-client}/bin/mc --config-dir ${config.xdg.configHome}/mc")
    (mkWrap "terraform" "${coreutils}/bin/env TF_PLUGIN_CACHE_DIR=${config.xdg.cacheHome}/terraform CHECKPOINT_DISABLE=1 ${terraform}/bin/terraform")
    restic
    libarchive
  ];

  home.sessionVariables = {
    EDITOR = "hx";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    GOOGLE_DEFAULT_CLIENT_ID = "77185425430.apps.googleusercontent.com";
    GOOGLE_DEFAULT_CLIENT_SECRET = "OTJgUOQcT7lO7GsGZq2G4IlT";
    LIBVA_DRIVER_NAME = "iHD";
    # cache
    XCOMPOSECACHE = "${config.xdg.cacheHome}/compose";
    __GL_SHADER_DISK_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    # config
    PARALLEL_HOME = "${config.xdg.configHome}/parallel";
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

  services.mbsync.enable = true;
  programs = {
    bash = {
      enable = true;
      profileExtra = ''
        if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
          exec sway
        fi
      '';
    };
    mako = {
      enable = true;
      extraConfig = ''
        on-button-right=exec ${pkgs.mako}/bin/makoctl menu -n "$id" ${pkgs.rofi}/bin/rofi -dmenu -p 'action: '
      '';
    };
    msmtp.enable = true;
    mbsync.enable = true;
    neomutt = {
      enable = true;
      vimKeys = true;
      checkStatsInterval = 10;
      sidebar = {
        enable = true;
      };
    };
    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
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
        merge.tool = "meld";
        mergetool.meld = {
          path = "${pkgs.meld}/bin/meld";
          useAutoMerge = true;
        };
        mergetool = {
          keepBackup = false;
          keepTemporaries = false;
          writeToTemp = true;
        };
        pull.rebase = true;
        init.defaultBranch = "master";
        fetch.prune = true;
        merge.conflictStyle = "diff3";
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
        b = "brightnessctl";
        freq = "sudo ${pkgs.linuxPackages.cpupower}/bin/cpupower frequency-set -g";
        vim = "hx";
        vi = "hx";
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
          size = 14;
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
      matchBlocks = {
        "rpi" = {
          hostname = "rpi.nichi.link";
          user = "root";
        };
        "unmatched" = {
          hostname = "10.0.1.3";
          proxyJump = "rpi";
        };
      };
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

  home.file = {
    ".local/share/fcitx5/rime/default.custom.yaml".text = ''
      patch:
        schema_list:
          - schema: double_pinyin_flypy
    '';
    ".local/share/fcitx5/rime/double_pinyin_flypy.custom.yaml".text = ''
      patch:
        translator/preedit_format: []
        translator/dictionary: luna_pinyin.extended
    '';
    ".local/share/fcitx5/rime/luna_pinyin.extended.dict.yaml".text = ''
      ---
      name: luna_pinyin.extended
      version: "0.1"
      sort: by_weight
      use_preset_vocabulary: true
      import_tables:
        - luna_pinyin
        - zhwiki
      ...  
    '';
    ".local/share/fcitx5/rime/zhwiki.dict.yaml".source = "${pkgs.rime-pinyin-zhwiki}/share/rime-data/zhwiki.dict.yaml";
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
      "helix/config.toml".source = toTOMLDrv {
        theme = "onedark";
        editor = {
          shell = [ "/bin/sh" "-c" ];
        };
        lsp = {
          display-messages = true;
        };
      };
      "waybar/config".source = toJSONDrv (import ./waybar.nix);
      "waybar/style.css".source = ./waybar.css;
      "swaylock/config".text = ''
        show-failed-attempts
        daemonize
        image=${fbk}
        scaling=fill
        effect-blur=7x5
        effect-vignette=0.5:0.5
      '';
      "swayidle/config".text = ''
        lock "${pkgs.swaylock-effects}/bin/swaylock"
        timeout 900 "${pkgs.swaylock-effects}/bin/swaylock"
        timeout 905 'swaymsg "output * dpms off"' resume 'swaymsg "output * dpms on"'
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
    };
  };
}
