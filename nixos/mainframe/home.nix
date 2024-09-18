{
  pkgs,
  lib,
  config,
  ...
}:
let
  cst = "${./chisato.jpg}";
  cst-blurred = pkgs.runCommand "chisato.jpg" { nativeBuildInputs = with pkgs; [ imagemagick ]; } ''
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

  programs.swaylock = {
    enable = true;
    settings = {
      show-failed-attempts = true;
      daemonize = true;
      image = "${cst-blurred}";
      scaling = "fill";
    };
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
      FirefoxHome = {
        Search = true;
        TopSites = false;
        SponsoredTopSites = false;
        Highlights = false;
        Pocket = false;
        SponsoredPocket = false;
        Snippets = false;
        Locked = true;
      };
      FirefoxSuggest = {
        SponsoredSuggestions = false;
        Locked = true;
      };
      Proxy = {
        Mode = "manual";
        SOCKSProxy = "127.0.0.1:1080";
        SOCKSVersion = 5;
        UseProxyForDNS = true;
      };
      DNSOverHTTPS = {
        Enabled = true;
        ProviderURL = "https://dns.google/dns-query";
        Locked = true;
        Fallback = false;
      };
      Preferences = {
        "browser.urlbar.autoFill.adaptiveHistory.enabled" = true;
        "browser.tabs.closeWindowWithLastTab" = false;
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
        "@testpilot-containers" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi";
        };
      };
    };
  };
  programs.thunderbird = {
    enable = true;
    package = pkgs.thunderbird-128;
    profiles.default = {
      isDefault = true;
    };
  };

  home.pointerCursor = {
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
    gtk.enable = true;
  };

  home.packages = with pkgs; [
    nix-update
    nix-init
    # compsize
    uhk-agent
    rage
    pinentry-gtk2
    texlab
    tectonic
    systemd-run-app
    picocom
    mpv
    telegram-desktop
    nixpkgs-review
    xdg-utils
    pavucontrol
    brightnessctl
    ripgrep
    nil
    ncdu
    yubikey-manager
    nixfmt-rfc-style
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
    wdisplays
    kubectl
    kind
    niri
  ];

  systemd.user.sessionVariables = {
    SOPS_AGE_KEY_FILE = "$HOME/Documents/key.txt";
    QT_QPA_PLATFORMTHEME = "gtk3";
    # cache
    CARGO_HOME = "${config.xdg.cacheHome}/cargo";
    # state
    HISTFILE = "${config.xdg.stateHome}/bash_history";
    # shit
    PYTHONSTARTUP =
      (pkgs.writeText "start.py" ''
        import readline
        readline.write_history_file = lambda *args: None
      '').outPath;
  };

  services.mako.enable = true;

  programs = {
    # pandoc.enable = true;
    man.generateCaches = false;
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
    fuzzel = {
      enable = true;
      settings = {
        main.horizontal-pad = 10;
      };
    };
    git = {
      enable = true;
      userEmail = "nickcao@nichi.co";
      userName = "Nick Cao";
      signing.key = "~/.ssh/id_ed25519";
      extraConfig = {
        commit.gpgSign = true;
        gpg = {
          format = "ssh";
          ssh.allowedSignersFile = toString (pkgs.writeText "allowed_signers" '''');
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
      plugins = [
        {
          name = "tide";
          src = tide;
        }
      ];
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

        fish_config theme choose fish\ default
        set fish_color_autosuggestion white
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
        import = [ ./alacritty.toml ];
        font = {
          size = 15.0;
        };
        shell = {
          program = "${pkgs.tmux}/bin/tmux";
          args = [
            "new-session"
            "-t"
            "main"
          ];
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
        "bandit" = {
          user = "terrier003";
          hostname = "ec521.bu.edu";
          port = 10001;
        };
      };
      extraConfig = ''
        CheckHostIP no
      '';
    };
  };

  systemd.user.services.swaybg = {
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Unit = {
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${lib.getExe pkgs.swaybg} -i ${cst} -m fill";
      Restart = "on-failure";
    };
  };

  systemd.user.services.swayidle.Unit.After = [ "graphical-session.target" ];

  services = {
    swayidle = {
      enable = true;
      timeouts = [
        {
          timeout = 900;
          command = "/run/current-system/systemd/bin/systemctl suspend";
        }
      ];
      events = [
        {
          event = "lock";
          command = "${pkgs.swaylock}/bin/swaylock";
        }
        {
          event = "before-sleep";
          command = "/run/current-system/systemd/bin/loginctl lock-session";
        }
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
      "niri/config.kdl".source = ./niri.kdl;
    };
  };

  home.file =
    lib.mapAttrs'
      (name: package: {
        name = ".config/autostart/${name}.desktop";
        value = {
          source = "${package}/share/applications/${name}.desktop";
        };
      })
      {
        "Alacritty" = config.programs.alacritty.package;
        "firefox" = config.programs.firefox.finalPackage;
        "thunderbird" = config.programs.thunderbird.package;
        "org.telegram.desktop" = pkgs.telegram-desktop;
      };

  home.stateVersion = "24.05";
}
