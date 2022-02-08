{ config, pkgs, lib, modulesPath, ... }:
let
  mkService = { ExecStart, SupplementaryGroups ? [ ] }: {
    unitConfig = {
      StartLimitIntervalSec = 0;
    };
    serviceConfig = {
      DynamicUser = true;
      Restart = "always";
      inherit ExecStart SupplementaryGroups;
    };
    wantedBy = [ "multi-user.target" ];
  };
in
{
  imports = [ (modulesPath + "/installer/sd-card/sd-image-aarch64.nix") ];
  disabledModules = [ "profiles/base.nix" ];

  nix.package = pkgs.nixVersions.stable;
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
    secrets = {
      wireless = { };
      tsig = { };
    };
  };

  services.resolved.dnssec = "false";
  systemd.services.systemd-networkd-wait-online.serviceConfig.ExecStart = [ "" "${pkgs.systemd}/lib/systemd/systemd-networkd-wait-online --any" ];
  systemd.services.usbipd = {
    unitConfig = {
      StartLimitIntervalSec = 0;
    };
    serviceConfig = {
      Restart = "always";
      ExecStart = "${config.boot.kernelPackages.usbip}/bin/usbipd";
    };
    wantedBy = [ "multi-user.target" ];
  };
  systemd.services.usbip-bind = {
    unitConfig = {
      StartLimitIntervalSec = 0;
      Requires = "usbipd.service";
    };
    serviceConfig = {
      RemainAfterExit = "yes";
      Restart = "on-failure";
      Type = "oneshot";
      ExecStart = [
        "${config.boot.kernelPackages.usbip}/bin/usbip bind -b 1-1.1"
        "${config.boot.kernelPackages.usbip}/bin/usbip bind -b 1-1.3"
      ];
      ExecStop = [
        "${config.boot.kernelPackages.usbip}/bin/usbip unbind -b 1-1.1"
        "${config.boot.kernelPackages.usbip}/bin/usbip unbind -b 1-1.3"
      ];
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.services.ddns = {
    path = with pkgs;[ curl knot-dns ];
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      LoadCredential = "tsig:${config.sops.secrets.tsig.path}";
    };
    script = ''
      set -e
      knsupdate -k ''${CREDENTIALS_DIRECTORY}/tsig << EOT
      server 65.21.32.182
      zone nichi.link
      origin nichi.link
      del rpi.dyn
      add rpi.dyn 30 A     `curl -s -4 https://canhazip.com`
      send
      EOT
    '';
  };

  systemd.timers.ddns = {
    timerConfig = {
      OnCalendar = "*:0/1";
    };
    wantedBy = [ "timers.target" ];
  };

  networking = {
    hostName = "rpi";
    domain = "nichi.link";
    useNetworkd = true;
    useDHCP = false;
    firewall.enable = false;
    wireless = {
      enable = true;
      environmentFile = config.sops.secrets.wireless.path;
      networks."Tsinghua-Secure" = {
        authProtocols = [ "WPA-EAP" ];
        auth = ''
          proto=RSN
          pairwise=CCMP
          eap=PEAP
          phase2="auth=MSCHAPV2"
          identity="@IDENTITY@"
          password="@PASSWORD@"
        '';
      };
    };
  };

  systemd.network.networks = {
    eth0 = {
      name = "eth0";
      DHCP = "yes";
      dhcpV4Config.RouteMetric = 2048;
      dhcpV6Config.RouteMetric = 2048;
      networkConfig.KeepConfiguration = "yes";
    };
    wlan0 = {
      name = "wlan0";
      DHCP = "yes";
      networkConfig.KeepConfiguration = "yes";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNPLArhyazrFjK4Jt/ImHSzICvwKOk4f+7OEcv2HEb7"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLQwaWXeJipSuAB+lV202yJOtAgJSNzuldH7JAf2jji"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpzrZLU0peDu1otGtP2GcCeQIkI8kmfHjnwpbfpWBkv"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7GmFmf0avCqYFIjhmq6TIOdPnzkVMYJLzlE4rqXLB4Q9BKXsRgpefAmd+OzqtbRjRM51ZKuV5rlMsF/QiuGU3qnE09JV97kiBCvWH30X9VVLjohjQCwbJRZzFXeW+9olILbjNbdBgYq0pe/41ohmq4cCNQ69u4+Hgf9XpEB7oJ4bzRuQZ/rrcl92zHqxS5QJZmKWiUcUGnQiN5XqwtHUdHhJ7qTzMEwWgtwRtVxVGIzauZU9Si89+amwyWkIOJwXh7oMcrqMyU110LpVeXs78vyjmYwTXGYDGlUnFaQ5FrkD/VoBgEhME9kZhDqyDVC6FxE5hNdtu3YaXWTTn0QMx"
  ];

  services.openssh = {
    enable = true;
    ports = [ 22 8122 ];
  };
  services.timesyncd.servers = [
    "101.6.6.172" # ntp.tuna.tsinghua.edu.cn
  ];
  services.udev.extraRules = ''
    SUBSYSTEMS=="gpio", MODE="0666"
  '';

  systemd.services.ustreamer = mkService {
    ExecStart = "${pkgs.ustreamer}/bin/ustreamer -r 1920x1080 -s :: -p 8080";
    SupplementaryGroups = [ "video" ];
  };
  systemd.services.powerd = mkService {
    ExecStart = "${(pkgs.python3.withPackages (ps: with ps;[ libgpiod flask ]))}/bin/python ${./powerd.py}";
  };

  environment.systemPackages = with pkgs;[
    socat
    openocd
    ttyd
    ustreamer
    ffmpeg
    libgpiod
    gdb
    config.boot.kernelPackages.usbip
  ];

  documentation.nixos.enable = false;

  boot.extraModulePackages = with config.boot.kernelPackages; [ usbip ];
  boot.kernelModules = [ "usbip_host" ];
}
