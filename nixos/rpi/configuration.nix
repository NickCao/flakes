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

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
    secrets = {
      wireless = { };
      etcd = { };
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
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      EnvironmentFile = config.sops.secrets.etcd.path;
    };
    script = ''
      ${pkgs.etcd_3_4}/bin/etcdctl --command-timeout=20s --dial-timeout=20s --endpoints https://etcd.nichi.co:443 --user $USER --password $PASSWORD \
        put /dns/link/nichi/dyn/rpi/x1 $(${pkgs.jo}/bin/jo ttl=30 host=$(${pkgs.curl}/bin/curl -s -4 https://canhazip.com))
      ${pkgs.etcd_3_4}/bin/etcdctl --command-timeout=20s --dial-timeout=20s --endpoints https://etcd.nichi.co:443 --user $USER --password $PASSWORD \
        put /dns/link/nichi/dyn/rpi/x2 $(${pkgs.jo}/bin/jo ttl=30 host=$(${pkgs.curl}/bin/curl -s -6 https://canhazip.com))
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
