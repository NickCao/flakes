{ ... }:
{
  power.ups = {
    enable = true;
    mode = "none";
    upsd.enable = true;
    ups.cp1500 = {
      driver = "usbhid-ups";
      port = "auto";
    };
  };
}
