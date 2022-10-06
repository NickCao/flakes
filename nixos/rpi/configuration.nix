{ config, pkgs, modulesPath, ... }:
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

  services.tftpd.enable = true;
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
        "${config.boot.kernelPackages.usbip}/bin/usbip bind -b 1-1.3"
      ];
      ExecStop = [
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
      server ${(import ../../zones/common.nix).nodes.iad0.ipv4}
      zone nichi.link
      origin nichi.link
      del rpi.dyn
      add rpi.dyn 30 A     `curl -s -4 https://canhazip.com`
      add rpi.dyn 30 AAAA  `curl -s -6 https://canhazip.com`
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
          phase1="tls_disable_tlsv1_0=0"
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
      address = [ "10.0.1.1/24" ];
      networkConfig = {
        DHCPServer = true;
        IPMasquerade = true;
        KeepConfiguration = "yes";
      };
    };
    wlan0 = {
      name = "wlan0";
      DHCP = "yes";
      networkConfig.KeepConfiguration = "yes";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = pkgs.keys ++ [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2X4EKIQTUUctgGnrXhHYddKzs69hXsmEK2ePBzSIwM"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7GmFmf0avCqYFIjhmq6TIOdPnzkVMYJLzlE4rqXLB4Q9BKXsRgpefAmd+OzqtbRjRM51ZKuV5rlMsF/QiuGU3qnE09JV97kiBCvWH30X9VVLjohjQCwbJRZzFXeW+9olILbjNbdBgYq0pe/41ohmq4cCNQ69u4+Hgf9XpEB7oJ4bzRuQZ/rrcl92zHqxS5QJZmKWiUcUGnQiN5XqwtHUdHhJ7qTzMEwWgtwRtVxVGIzauZU9Si89+amwyWkIOJwXh7oMcrqMyU110LpVeXs78vyjmYwTXGYDGlUnFaQ5FrkD/VoBgEhME9kZhDqyDVC6FxE5hNdtu3YaXWTTn0QMx"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCw9mmG3he9C9dLjOtjms9cn9vzijtowzno/5XQgomyReWiUItgL6AoyQF46DbJMkM2cNZQ/cQyqNS8zs5FDdWKTiHsVSEYYeCTeppHB9qqgjGx2slLrs7sQTgsF+D5ork98Wk4KUr8dmR4Q3rbBU9uQjSuda2H7Ye0sd8fnanT2ZKbK/SGgfQlU0KRoo2RC5p9VB7Siw1xnIM+oaCNw9UuBYBzKcF5/lbZXbJoIz953U6KJZ/A5wZR9VaV9y/xhvnNeiVz497yN5s0s+em4tjNnCCaeNlp6Tk9Y3d8OFKfaLxvKV7HbtWiQLN2eA/LmWLR5A5Q8jHH9xWX2dHGUuB9"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDI0OEpAkO3qXwF8eDMy1XtUYRQhoJ21ZdoqAeUBbKkYH0GmjkpA4hIUm+drqFf7tjzXAA2/kGJpvQ84aFzaMOqY+DaFnilu5dadR/faZ1SvYQyo+XJpV3yqtAiI4GJBzX1/ryB2uCclUgb89pMoXT1GkCitL0hLZPq2Qv/BSfcQXBl31vqYOrPwt9MoNu+1zZ/67/WaeQnLo+UQiLjMQXk37ANVkZGtOt8LaQOQ0xtiiY7QTfJWQ91VnokriHG1oxLlkvQtOw/x6kiuKR8crupG38pxdYjsKUu4i5Tx0GT4ejcQtIfvPPMLHN1q6eUUkGXn6j1ASiaSb1GZ7Zugpmt"
  ];
  users.users.tony.isNormalUser = true;
  users.users.tony.group = "nogroup";
  users.users.tony.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQChrGIIFf0wXFNcdMeG/+Yxl0NF/7pQ9y7Mp7PqEjhKLNm1qOGJHrwWItmKCdR7lIIutSJNVYt9j7SoJGYlIa39icVl+picZd6wPYfLze41JJmKrVZNf8CZDlUr4j/F/UjbGKINncrNKf9BCf9322fTgq/oVypvANVMsbCCHurqQZeF/UF74Vrdw/tMI0/D/HGu/UwjeWghKYkzeBfb+N892cxhcADNgLk3jKGJy1+XFt5EpIp7cy/zhUobghFRIH3qqgK4iydFw37UL3ZJ65KHBg+0f97aRadCfcmmo3PQ792HtUw4TYDNJd5Z9+Cm5EF5mBjGTswaNgbtxCUQ1jj1"
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

  services.uptimed.enable = true;

  environment.systemPackages = with pkgs;[
    socat
    riscv-openocd
    ttyd
    ustreamer
    ffmpeg
    libgpiod
    gdb
    config.boot.kernelPackages.usbip
    jtag-remote-server
    mtr
  ];

  documentation.nixos.enable = false;

  boot.extraModulePackages = with config.boot.kernelPackages; [ usbip ];
  boot.kernelModules = [ "usbip_host" ];
  system.stateVersion = "22.05";
}
