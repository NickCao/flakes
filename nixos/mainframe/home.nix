{ pkgs, lib, config, ... }:
let
  cst = "${./chisato.jpg}";
  cst-blurred = pkgs.runCommand "chisato.jpg"
    {
      nativeBuildInputs = with pkgs;[ imagemagick ];
    } ''
    convert -blur 14x5 ${cst} $out
  '';
  tide = pkgs.fishPlugins.tide.src;
in
{
  gtk = {
    enable = true;
    font = {
      package = pkgs.roboto;
      name = "Roboto";
      size = 11;
    };
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
  };
  wayland.windowManager.sway = {
    enable = true;
    systemd = {
      enable = true;
      xdgAutostart = true;
    };
    wrapperFeatures.gtk = true;
    config = {
      modifier = "Mod4";
      terminal = "systemd-run-app alacritty";
      startup = [
        { command = "systemd-run-app alacritty"; }
        { command = "systemd-run-app firefox"; }
        { command = "systemd-run-app telegram-desktop"; }
        { command = "systemd-run-app thunderbird"; }
      ];
      assigns = {
        "1" = [{ app_id = "Alacritty"; }];
        "2" = [{ app_id = "firefox"; }];
        "3" = [{ app_id = "org.telegram.desktop"; }];
        "4" = [{ app_id = "thunderbird"; }];
        "5" = [{ app_id = "qemu"; }];
      };
      window.commands = [
        {
          criteria = { app_id = "pavucontrol"; };
          command = "floating enable, sticky enable, resize set width 650 px height 600px, move position cursor, move down 60";
        }
        {
          criteria = { app_id = "lxqt-openssh-askpass"; };
          command = "floating enable";
        }
        {
          criteria = { class = "lxqt-openssh-askpass"; };
          command = "floating enable";
        }
        {
          criteria = { title = "Extension: \\(Bitwarden - Free Password Manager\\) - Bitwarden — Mozilla Firefox"; };
          command = "floating enable, move scratchpad, scratchpad show";
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
        lib.mkOptionDefault {
          "${modifier}+h" = "focus left";
          "${modifier}+j" = "focus down";
          "${modifier}+k" = "focus up";
          "${modifier}+l" = "focus right";
          "${modifier}+s" = "split toggle";
          "${modifier}+b" = null;
          "${modifier}+v" = null;
          "${modifier}+w" = null;
          "${modifier}+d" = "exec ${lib.getExe pkgs.rofi-wayland} -show run -run-command 'systemd-run-app {cmd}'";
          "${modifier}+Shift+l" = "exec loginctl lock-session";
          "${modifier}+space" = null;
          "Print" = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" $HOME/Pictures/screenshot-$(date +\"%Y-%m-%d-%H-%M-%S\").png";
          "XF86AudioPlay" = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
          "XF86AudioPause" = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
          "XF86AudioNext" = "exec ${pkgs.playerctl}/bin/playerctl next";
          "XF86AudioPrev" = "exec ${pkgs.playerctl}/bin/playerctl previous";
        };
      input = {
        "2362:628:PIXA3854:00_093A:0274_Touchpad" = {
          natural_scroll = "enabled";
          tap = "enabled";
        };
        "1:1:AT_Translated_Set_2_keyboard" = {
          xkb_options = "ctrl:nocaps";
        };
      };
      output = {
        eDP-1 = {
          bg = "${cst} fill";
          scale = "1.5";
        };
        DP-2 = {
          scale = "1.5";
        };
      };
      workspaceOutputAssign = [{
        workspace = "9";
        output = "DP-2";
      }];
      bars = [ ];
    };
  };
  programs.swaylock.settings = {
    show-failed-attempts = true;
    daemonize = true;
    image = "${cst-blurred}";
    scaling = "fill";
  };
  programs.neovim = {
    enable = true;
    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      everforest
      luasnip
      vim-lastplace
      editorconfig-nvim
      lualine-nvim
      which-key-nvim
      lualine-lsp-progress
      leap-nvim
    ];
    extraConfig = ''
      :source ${./nvim.lua}
    '';
  };
  programs.firefox = {
    enable = true;
    policies = {
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
        "browser.urlbar.autoFill.adaptiveHistory.enabled" = true;
        "browser.tabs.closeWindowWithLastTab" = false;
        "media.peerconnection.enabled" = false;
      };
      ExtensionSettings = {
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
        };
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
      };
    };
  };

  home.pointerCursor = {
    package = pkgs.gnome.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
    gtk.enable = true;
  };

  home.packages = with pkgs; [
    nix-update
    nix-init
    compsize
    uhk-agent
    rage
    pinentry-gtk2
    # sioyek
    texlab
    tectonic
    systemd-run-app
    picocom
    thunderbird
    mpv
    telegram-desktop
    nixpkgs-review
    xdg-utils
    pavucontrol
    brightnessctl
    ripgrep
    nil
    ncdu
    mode
    yubikey-manager
    wireguard-tools
    nixpkgs-fmt
    smartmontools
    python3
    knot-dns
    tree
    mtr
    go
    gopls
    sops
    restic
    libarchive
    wl-clipboard
    wl-mirror
  ];

  systemd.user.sessionVariables = {
    SOPS_AGE_KEY_FILE = "$HOME/Documents/key.txt";
    # cache
    CARGO_HOME = "${config.xdg.cacheHome}/cargo";
    # state
    HISTFILE = "${config.xdg.stateHome}/bash_history";
    # shit
    PYTHONSTARTUP = (
      pkgs.writeText "start.py" ''
        import readline
        readline.write_history_file = lambda *args: None
      ''
    ).outPath;
  };

  services.mako = {
    enable = true;
    extraConfig = ''
      on-button-right=exec ${pkgs.mako}/bin/makoctl menu -n "$id" ${lib.getExe pkgs.rofi-wayland} -dmenu -p 'action: '
    '';
  };

  programs = {
    # pandoc.enable = true;
    jq.enable = true;
    lf.enable = true;
    waybar = {
      enable = true;
      settings = [ (import ./waybar.nix { inherit pkgs; }) ];
      style = builtins.readFile ./waybar.css;
      systemd.enable = true;
    };
    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
    };
    git = {
      enable = true;
      userEmail = "nickcao@nichi.co";
      userName = "Nick Cao";
      signing.key = "~/.ssh/id_ed25519_sk_signing";
      extraConfig = {
        commit.gpgSign = true;
        gpg = {
          format = "ssh";
          ssh.allowedSignersFile = toString (pkgs.writeText "allowed_signers" ''
          '');
        };
        merge.conflictStyle = "diff3";
        merge.tool = "vimdiff";
        mergetool = {
          keepBackup = false;
          keepTemporaries = false;
          writeToTemp = true;
        };
        pull.rebase = true;
        init.defaultBranch = "master";
        fetch.prune = true;
      };
    };
    fish = {
      enable = true;
      plugins = [{
        name = "tide";
        src = tide;
      }];
      shellInit = ''
        set fish_greeting

        function fish_user_key_bindings
          fish_vi_key_bindings
          bind f accept-autosuggestion
        end

        string replace -r '^' 'set -g ' < ${tide}/functions/tide/configure/icons.fish | source
        string replace -r '^' 'set -g ' < ${tide}/functions/tide/configure/configs/lean.fish | source
        string replace -r '^' 'set -g ' < ${tide}/functions/tide/configure/configs/lean_16color.fish | source
        set -g tide_prompt_add_newline_before false

        set fish_color_normal normal
        set fish_color_command blue
        set fish_color_quote yellow
        set fish_color_redirection cyan --bold
        set fish_color_end green
        set fish_color_error brred
        set fish_color_param cyan
        set fish_color_comment red
        set fish_color_match --background=brblue
        set fish_color_selection white --bold --background=brblack
        set fish_color_search_match bryellow --background=brblack
        set fish_color_history_current --bold
        set fish_color_operator brcyan
        set fish_color_escape brcyan
        set fish_color_cwd green
        set fish_color_cwd_root red
        set fish_color_valid_path --underline
        set fish_color_autosuggestion white
        set fish_color_user brgreen
        set fish_color_host normal
        set fish_color_cancel --reverse
        set fish_pager_color_prefix normal --bold --underline
        set fish_pager_color_progress brwhite --background=cyan
        set fish_pager_color_completion normal
        set fish_pager_color_description B3A06D --italics
        set fish_pager_color_selected_background --reverse
      '';
      shellAliases = {
        b = "brightnessctl";
        p = "powerprofilesctl";
      };
      shellAbbrs = {
        rebuild = "nixos-rebuild --use-remote-sudo -v -L --flake ~/Projects/flakes";
      };
    };
    tmux = {
      enable = true;
      baseIndex = 1;
      escapeTime = 10;
      shell = "${pkgs.fish}/bin/fish";
      keyMode = "vi";
      terminal = "screen-256color";
      extraConfig = ''
        set -g status-position top
        set -g set-clipboard on
        set -g mouse on
        set -g status-right ""
        set -g renumber-windows on
        set -ga terminal-overrides ",alacritty:Tc"
        new-session -s main
      '';
    };
    alacritty = {
      enable = true;
      settings = {
        import = [ ./alacritty.yml ];
        font = { size = 15.0; };
        shell = {
          program = "${pkgs.tmux}/bin/tmux";
          args = [ "new-session" "-t" "main" ];
        };
      };
    };
    ssh = {
      enable = true;
      serverAliveInterval = 30;
      matchBlocks = {
        "*.lab.pacman-thu.org" = {
          user = "nickcao";
          proxyJump = "pacman";
          forwardAgent = true;
        };
        "*.sc.team" = {
          user = "nickcao";
          proxyJump = "pacman";
          forwardAgent = true;
        };
        "pacman" = {
          user = "nickcao";
          hostname = "166.111.68.163";
          port = 2222;
        };
        "hydra" = {
          user = "root";
          hostname = "k17-plct.nichi.link";
          port = 9022;
        };
        "*.nichi.link" = {
          user = "root";
          extraOptions = {
            StrictHostKeyChecking = "no";
            UserKnownHostsFile = "/dev/null";
            LogLevel = "ERROR";
          };
        };
      };
      extraConfig = ''
        CheckHostIP no
      '';
    };
  };
  services = {
    swayidle = {
      enable = true;
      timeouts = [
        { timeout = 900; command = "/run/current-system/systemd/bin/systemctl suspend"; }
      ];
      events = [
        { event = "lock"; command = "${pkgs.swaylock}/bin/swaylock"; }
        { event = "before-sleep"; command = "/run/current-system/systemd/bin/loginctl lock-session"; }
      ];
    };
  };

  xdg = {
    enable = true;
    configFile = {
      "go/env".text = ''
        GOPATH=${config.xdg.cacheHome}/go
        GOBIN=${config.xdg.stateHome}/go/bin
      '';
    };
  };

  home.stateVersion = "21.11";
}
