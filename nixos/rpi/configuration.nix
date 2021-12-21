{ config, pkgs, lib, modulesPath, ... }:
let
  mkService = { ExecStart, SupplementaryGroups ? [ ], ConditionPathExists ? null }: {
    unitConfig = {
      StartLimitIntervalSec = 0;
      inherit ConditionPathExists;
    };
    serviceConfig = {
      DynamicUser = true;
      Restart = "always";
      inherit ExecStart SupplementaryGroups;
    };
    wantedBy = [ "multi-user.target" ];
  };
  openocdConfig = pkgs.writeText "unmatched.conf" ''
    bindto 0.0.0.0
    
    adapter speed   10000
    adapter driver  ftdi
    
    ftdi_device_desc "Dual RS232-HS"
    ftdi_vid_pid 0x0403 0x6010
    ftdi_layout_init 0x0008 0x001b
    ftdi_layout_signal nSRST -oe 0x0020 -data 0x0020
    
    set _CHIPNAME riscv
    transport select jtag
    jtag newtap $_CHIPNAME cpu -irlen 5
    
    target create $_CHIPNAME.cpu1 riscv -chain-position $_CHIPNAME.cpu -coreid 1 -rtos hwthread
    target create $_CHIPNAME.cpu2 riscv -chain-position $_CHIPNAME.cpu -coreid 2
    target create $_CHIPNAME.cpu3 riscv -chain-position $_CHIPNAME.cpu -coreid 3
    target create $_CHIPNAME.cpu4 riscv -chain-position $_CHIPNAME.cpu -coreid 4
    target smp $_CHIPNAME.cpu1 $_CHIPNAME.cpu2 $_CHIPNAME.cpu3 $_CHIPNAME.cpu4
    
    init
  '';
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

  systemd.services.ddns = {
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      EnvironmentFile = config.sops.secrets.etcd.path;
    };
    script = ''
      ${pkgs.etcd_3_4}/bin/etcdctl --endpoints https://etcd.nichi.co:443 --user $USER --password $PASSWORD \
        put /dns/link/nichi/dyn/rpi/x1 $(${pkgs.jo}/bin/jo ttl=30 host=$(${pkgs.curl}/bin/curl -s -4 https://canhazip.com))
      ${pkgs.etcd_3_4}/bin/etcdctl --endpoints https://etcd.nichi.co:443 --user $USER --password $PASSWORD \
        put /dns/link/nichi/dyn/rpi/x2 $(${pkgs.jo}/bin/jo ttl=30 host=$(${pkgs.curl}/bin/curl -s -6 https://canhazip.com))
    '';
  };

  systemd.timers.ddns = {
    timerConfig = {
      OnCalendar = "*:0/5";
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
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0666"
    SUBSYSTEMS=="gpio", MODE="0666"
  '';

  systemd.services.ustreamer = mkService {
    ExecStart = "${pkgs.ustreamer}/bin/ustreamer -r 1920x1080 -s :: -p 8080";
    SupplementaryGroups = [ "video" ];
  };
  systemd.services.serial = mkService {
    ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:8081,reuseaddr,fork FILE:/dev/ttyUSB1,b115200,raw,nonblock,echo=0";
    SupplementaryGroups = [ "dialout" ];
  };
  systemd.services.openocd = mkService {
    ExecStart = "${pkgs.openocd}/bin/openocd -f ${openocdConfig}";
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
  ];

  documentation.nixos.enable = false;
}
