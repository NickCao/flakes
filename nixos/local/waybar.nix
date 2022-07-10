{ pkgs }:
{
  layer = "top";
  height = 35;
  modules-left = [
    "sway/workspaces"
    "sway/mode"
  ];
  modules-center = [
    "sway/window"
  ];
  modules-right = [
    "idle_inhibitor"
    "pulseaudio"
    "memory"
    "temperature"
    "backlight"
    "battery"
    "clock"
    "tray"
  ];
  "sway/workspaces" = {
    all-outputs = true;
    format = "{name} {icon}";
    format-icons = { "1" = ""; "2" = ""; "3" = ""; "4" = ""; default = ""; focused = ""; urgent = ""; };
  };
  idle_inhibitor = {
    format = "{icon}";
    format-icons = { activated = ""; deactivated = ""; };
  };
  pulseaudio = {
    format = "{volume}% {icon} {format_source}";
    format-bluetooth = "{volume}% {icon}  {format_source}";
    format-bluetooth-muted = " {icon}  {format_source}";
    format-icons = {
      car = "";
      default = [ "" "" "" ];
      hands-free = "";
      headphone = "";
      headset = "";
      phone = "";
      portable = "";
    };
    format-muted = " {format_source}";
    format-source = "{volume}% ";
    format-source-muted = "";
    on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
  };
  backlight = {
    format = "{percent}% {icon}";
    format-icons = [ "" "" ];
    on-scroll-down = "${pkgs.brightnessctl}/bin/brightnessctl set 3%-";
    on-scroll-up = "${pkgs.brightnessctl}/bin/brightnessctl set +3%";
  };
  battery = {
    format = "{capacity}% {icon}";
    format-alt = "{time} {icon}";
    format-charging = "{capacity}% ";
    format-icons = [ "" "" "" "" "" ];
    format-plugged = "{capacity}% ";
    states = { critical = 10; warning = 20; };
  };
  clock = {
    format = "{:%m-%d %H:%M}";
    tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
  };
  memory = {
    format = "{}% ";
  };
  temperature = {
    critical-threshold = 100;
    format = "{temperatureC}°C {icon}";
    format-icons = [ "" "" "" ];
    interval = 10;
    thermal-zone = 9;
  };
  tray = {
    icon-size = 25;
    spacing = 10;
  };
}
