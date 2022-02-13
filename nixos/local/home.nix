{ pkgs, config, ... }:
let
  mkWrap = name: cmd: pkgs.writeShellScriptBin name "exec ${cmd} \"$@\"";
  fbk = pkgs.fetchurl {
    url = "https://pbs.twimg.com/media/ElphQpaU4AAt9Bv?format=jpg";
    name = "fubuki.jpg";
    hash = "sha256-541/iI7scwyyEOxZAYFql4X/W5xmg5hUfeDJbtJ+voE=";
  };
  fbk-blurred = pkgs.runCommand "fubuki.png"
    {
      nativeBuildInputs = with pkgs;[ imagemagick ];
    } ''
    convert -blur 14x5 ${fbk} $out
  '';
in
{
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
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
  };
  qt = {
    enable = true;
    platformTheme = "gtk";
  };
  wayland.windowManager.sway = {
    enable = true;
    extraOptions = [ "--unsupported-gpu" ];
    wrapperFeatures.gtk = true;
    config = {
      modifier = "Mod4";
      terminal = "foot";
      startup = [
        { command = "foot"; }
        { command = "firefox"; }
        { command = "telegram-desktop"; }
      ];
      assigns = {
        "1" = [{ app_id = "foot"; }];
        "2" = [{ app_id = "firefox"; }];
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
          "XF86AudioPlay" = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
          "XF86AudioPause" = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
          "XF86AudioNext" = "exec ${pkgs.playerctl}/bin/playerctl next";
          "XF86AudioPrev" = "exec ${pkgs.playerctl}/bin/playerctl previous";
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
      bars = [ ];
      floating.criteria = [
        { app_id = "blueberry.py"; }
      ];
    };
  };
  programs.helix = {
    enable = true;
    settings = {
      theme = "solarized_dark";
      editor = {
        shell = [ "/bin/sh" "-c" ];
      };
      lsp = {
        display-messages = true;
      };
    };
  };
  programs.firefox = {
    enable = true;
    package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
      forceWayland = true;
      extraPolicies = {
        PasswordManagerEnabled = false;
        DisableFirefoxAccounts = true;
        DisablePocket = true;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
        Proxy = {
          Mode = "manual";
          SOCKSProxy = "127.0.0.1:1080";
          SOCKSVersion = 5;
          UseProxyForDNS = true;
        };
        Preferences = {
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        };
        ExtensionSettings = {
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          };
        };
      };
    };
    profiles = {
      default = {
        settings = {
          "fission.autostart" = true;
          "media.ffmpeg.vaapi.enabled" = true;
          "media.rdd-ffmpeg.enabled" = true;
        };
      };
    };
  };
  home.packages = with pkgs; [
    nix-top
    thunderbird
    helix
    mpv
    tdesktop
    nixpkgs-review
    waypipe
    xdg-utils
    blueberry
    pavucontrol
    brightnessctl
    ripgrep
    rnix-lsp
    lf
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
    smartmontools
    rait
    python3
    knot-dns
    tree
    mtr
    go_1_17
    gopls
    sops
    restic
    libarchive
    (mkWrap "mc" "${minio-client}/bin/mc --config-dir ${config.xdg.configHome}/mc")
    (mkWrap "terraform" "${coreutils}/bin/env CHECKPOINT_DISABLE=1 ${
      terraform.withPlugins (ps: with ps; [ vultr sops minio gandi ])
        }/bin/terraform")
  ];

  home.sessionVariables = {
    EDITOR = "hx";
    LIBVA_DRIVER_NAME = "iHD";
    # cache
    __GL_SHADER_DISK_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    CARGO_HOME = "${config.xdg.cacheHome}/cargo";
    # state
    HISTFILE = "${config.xdg.stateHome}/bash_history";
    LESSHISTFILE = "${config.xdg.stateHome}/lesshst";
    # shit
    PYTHONSTARTUP = (
      pkgs.writeText "start.py" ''
        import readline
        readline.write_history_file = lambda *args: None
      ''
    ).outPath;
  };

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
    waybar = {
      enable = true;
      settings = [ (import ./waybar.nix) ];
      style = builtins.readFile ./waybar.css;
      systemd.enable = true;
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
      homedir = "${config.xdg.stateHome}/gnupg";
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
        set fish_color_normal normal
        set fish_color_command 93a1a1
        set fish_color_quote 657b83
        set fish_color_redirection 6c71c4
        set fish_color_end 268bd2
        set fish_color_error dc322f
        set fish_color_param 839496
        set fish_color_comment 586e75
        set fish_color_match --background=brblue
        set fish_color_selection white --bold --background=brblack
        set fish_color_search_match bryellow --background=black
        set fish_color_history_current --bold
        set fish_color_operator 00a6b2
        set fish_color_escape 00a6b2
        set fish_color_cwd green
        set fish_color_cwd_root red
        set fish_color_valid_path --underline
        set fish_color_autosuggestion 586e75
        set fish_color_user brgreen
        set fish_color_host normal
        set fish_color_cancel -r
        set fish_pager_color_completion B3A06D
        set fish_pager_color_description B3A06D
        set fish_pager_color_prefix cyan --underline
        set fish_pager_color_progress brwhite --background=cyan
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
        set -g status-position top
        set -g set-clipboard on
        set -g mouse on
        set -g status-right ""
        set -gs escape-time 10
        set -g renumber-windows on
        set -g base-index 1
        new-session -s main
      '';
    };
    foot = {
      enable = true;
      settings = {
        main = {
          shell = "${pkgs.tmux}/bin/tmux new-session -t main";
          font = "JetBrains Mono:size=10";
        };
        cursor = {
          color = "002b36 93a1a1";
        };
        colors = {
          background = "002b36";
          foreground = "839496";
          regular0 = "073642";
          regular1 = "dc322f";
          regular2 = "859900";
          regular3 = "b58900";
          regular4 = "268bd2";
          regular5 = "d33682";
          regular6 = "2aa198";
          regular7 = "eee8d5";
          bright0 = "002b36";
          bright1 = "cb4b16";
          bright2 = "586e75";
          bright3 = "657b83";
          bright4 = "839496";
          bright5 = "6c71c4";
          bright6 = "93a1a1";
          bright7 = "fdf6e3";
          selection-foreground = "93a1a1";
          selection-background = "073642";
        };
      };
    };
    ssh = {
      enable = true;
      compression = true;
      serverAliveInterval = 30;
      matchBlocks = {
        "*.sc.team" = {
          user = "nickcao";
          proxyJump = "scjump";
          forwardAgent = true;
        };
        "scjump" = {
          user = "nickcao";
          hostname = "166.111.68.163";
          port = 2222;
        };
        "unmatched" = {
          proxyJump = "rpi";
          user = "root";
          hostname = "fe80::72b3:d5ff:fe92:f9ff%%eth0";
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
    swayidle = {
      enable = true;
      timeouts = [
        { timeout = 900; command = "${pkgs.swaylock}/bin/swaylock"; }
        { timeout = 905; command = ''swaymsg "output * dpms off"''; resumeCommand = ''swaymsg "output * dpms on"''; }
      ];
      events = [
        { event = "lock"; command = "${pkgs.swaylock}/bin/swaylock"; }
      ];
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
      "swaylock/config".text = ''
        show-failed-attempts
        daemonize
        image=${fbk-blurred}
        scaling=fill
      '';
      "go/env".text = ''
        GOPATH=${config.xdg.cacheHome}/go
        GOBIN=${config.xdg.stateHome}/go/bin
        GO111MODULE=on
        GOPROXY=https://goproxy.cn
        GOSUMDB=sum.golang.google.cn
      '';
    };
  };

  home.stateVersion = "21.11";
}
