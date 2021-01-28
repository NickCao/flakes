{ pkgs, config, ... }:
let
  toTOMLDrv = v: (pkgs.formats.toml { }).generate "" v;
in
{
  home.packages = with pkgs; [ sops update-nix-fetchgit drone-cli buildifier ];
  systemd.user.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
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
            StrictHostKeyChecking=no
            UserKnownHostsFile=/dev/null
          Host *
            CheckHostIP=no
            ServerAliveInterval 60
        '';
      };
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
        source = toTOMLDrv {
          storage = {
            driver = "btrfs";
            rootless_storage_path = "$HOME/Data/Containers/";
          };
        };
      };
    };
  };
}
