{
  lib,
  pkgs,
  utils,
  ...
}:
let
  vendorfw = pkgs.requireFile {
    name = "vendorfw";
    hashMode = "recursive";
    hash = "sha256-tTQYYxEOWTYCePwohNVzJhf2rbBmRt2fJzgDfGa7tlE=";
    message = "
      nix-store --add-fixed sha256 --recursive /efi/vendorfw/
      nix hash path  --algo sha256             /efi/vendorfw/
    ";
  };
in
{
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "vendorfw"
    ];

  systemd.network.enable = true;
  systemd.network.networks = {
    "10-end0" = {
      name = "end0";
      DHCP = "yes";
    };
    "10-wld0" = {
      name = "wld0";
      DHCP = "yes";
      dhcpV4Config.RouteMetric = 2048;
      ipv6AcceptRAConfig.RouteMetric = 2048;
    };
  };

  systemd.network.wait-online = {
    anyInterface = true;
    extraArgs = [ "--ipv4" ];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernel.sysctl."vm.mmap_rnd_bits" = 31;
  boot.kernelModules = [ "tpm_vtpm_proxy" ];

  hardware.asahi = {
    enable = true;
    peripheralFirmwareDirectory = vendorfw;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLQwaWXeJipSuAB+lV202yJOtAgJSNzuldH7JAf2jji nickcao@mainframe"
  ];

  networking = {
    hostName = "armchair";
    domain = "nichi.link";
  };

  services.openssh.enable = true;

  system.extraDependencies = [ vendorfw ];

  environment.systemPackages = with pkgs; [
    vim
    git
    tmux
    lm_sensors
  ];

  users.groups.vtpm = { };
  services.udev.extraRules = ''
    KERNEL=="vtpmx", GROUP="vtpm", MODE="0660", TAG+="systemd"
    # go-attestation falls back to the raw device for the virtual TPM.
    SUBSYSTEM=="tpm", KERNEL=="tpm[0-9]*", GROUP="tss", MODE="0660"
  '';

  cloud.services.swtpm = {
    unit = {
      Requires = [ "dev-vtpmx.device" ];
      After = [ "dev-vtpmx.device" ];
    };
    config = {
      ExecStart = utils.escapeSystemdExecArgs [
        (lib.getExe pkgs.swtpm)
        "chardev"
        "--vtpm-proxy"
        "--tpm2"
        "--tpmstate"
        "dir=/var/lib/swtpm,mode=0600"
      ];
      StateDirectory = "swtpm";
      StateDirectoryMode = "0700";
      SupplementaryGroups = [ "vtpm" ];
      PrivateUsers = false;
      PrivateDevices = false;
      CapabilityBoundingSet = [ "CAP_SYS_ADMIN" ];
      AmbientCapabilities = [ "CAP_SYS_ADMIN" ];
      DevicePolicy = "closed";
      DeviceAllow = [ "/dev/vtpmx rw" ];
      RestartSec = 10;
    };
  };

  cloud.spire.agent.tpm = true;

  hardware.graphics.enable = true;

  virtualisation.podman.enable = true;

  environment.baseline.enable = true;

  system.stateVersion = "25.05";

}
