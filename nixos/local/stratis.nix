{ config, pkgs, ... }:
let package = pkgs.stratisd.override { clevisSupport = true; }; in
{
  systemd.packages = [ package ];
  services.dbus.packages = [ package ];
  services.udev.packages = [ package ];
  systemd.services.stratisd.wantedBy = [ "sysinit.target" ];
}
