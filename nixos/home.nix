{ pkgs, ... }:
let
  dark = {
    bright = {
      black = "#002b36";
      blue = "#839496";
      cyan = "#93a1a1";
      green = "#586e75";
      magenta = "#6c71c4";
      red = "#cb4b16";
      white = "#fdf6e3";
      yellow = "#657b83";
    };
    cursor = {
      cursor = "#839496";
      text = "#002b36";
    };
    normal = {
      black = "#073642";
      blue = "#268bd2";
      cyan = "#2aa198";
      green = "#859900";
      magenta = "#d33682";
      red = "#dc322f";
      white = "#eee8d5";
      yellow = "#b58900";
    };
    primary = {
      background = "#002b36";
      foreground = "#839496";
    };
  };
  light = {
    bright = {
      black = "#002b36";
      blue = "#839496";
      cyan = "#93a1a1";
      green = "#586e75";
      magenta = "#6c71c4";
      red = "#cb4b16";
      white = "#fdf6e3";
      yellow = "#657b83";
    };
    cursor = {
      cursor = "#657b83";
      text = "#fdf6e3";
    };
    normal = {
      black = "#073642";
      blue = "#268bd2";
      cyan = "#2aa198";
      green = "#859900";
      magenta = "#d33682";
      red = "#dc322f";
      white = "#eee8d5";
      yellow = "#b58900";
    };
    primary = {
      background = "#fdf6e3";
      foreground = "#657b83";
    };
  };
in
{
  home.packages = with pkgs; [ sops update-nix-fetchgit drone-cli buildifier ];
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
    go = {
      enable = true;
      goBin = "Bin";
      goPath = ".cache/go";
    };
    gpg = {
      enable = true;
      settings = { };
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
        set -x PATH /home/nickcao/Bin /home/nickcao/.local/bin $PATH
        set -x SOPS_PGP_FP 068A56CEF48FA2C1
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
        colors = light;
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
  xdg = {
    configFile = {
      "autostart/gnome-keyring-ssh.desktop" = {
        text = ''
          [Desktop Entry]
          Type=Application
          Name=gnome-keyring-ssh
          Exec=${pkgs.coreutils}/bin/true
        '';
      };
      "go/env" = {
        text = ''
          GO111MODULE=on
          GOPROXY=https://goproxy.cn
          GOSUMDB=sum.golang.google.cn
        '';
      };
      "containers/storage.conf" = {
        text = ''
          [storage]
          driver = "btrfs"
          rootless_storage_path = "$HOME/Data/Containers/"
        '';
      };
    };
  };
}
