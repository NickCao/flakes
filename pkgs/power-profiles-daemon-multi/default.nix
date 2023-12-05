{ power-profiles-daemon }:

power-profiles-daemon.overrideAttrs {
  patches = [ ./multiple-drivers.patch ];
}
