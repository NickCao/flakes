{ pkgs }:
let
  mkSpan = abbr: content: "<span color='#8aadf4'>${abbr}</span> ${content}";
in
{
  margin = "3px 3px 3px";
  height = 40;
  layer = "top";
  "custom/nixos" = {
    format = "";
    interval = "once";
    tooltip = false;
  };
  "custom/separator" = {
    format = "|";
    interval = "once";
    tooltip = false;
  };
  modules-left = [
    "custom/nixos"
    "niri/workspaces"
    "custom/separator"
    "niri/window"
  ];
  modules-right = [
    "tray"
    "custom/separator"
    "idle_inhibitor"
    "custom/separator"
    "pulseaudio"
    "custom/separator"
    "memory"
    "custom/separator"
    "temperature"
    "custom/separator"
    "backlight"
    "custom/separator"
    "battery"
    "custom/separator"
    "clock"
  ];
  "niri/workspaces" = {
    all-outputs = true;
    format = "{icon}";
    format-icons = {
      "terminal" = "";
      "browser" = "";
      "chat" = "";
      "mail" = "󰇮";
    };
  };
  "niri/window" = { };
  idle_inhibitor = {
    format = mkSpan "IDLE" "{icon}";
    format-icons = {
      activated = "OFF";
      deactivated = "ON";
    };
  };
  pulseaudio = {
    format = "{volume}% {icon} {format_source}";
    format-bluetooth = "{volume}% {icon}  {format_source}";
    format-bluetooth-muted = " {icon}  {format_source}";
    format-icons = {
      car = "";
      default = [
        ""
        ""
        ""
      ];
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
    format = mkSpan "BRI" "{percent}%";
    on-scroll-down = "${pkgs.brightnessctl}/bin/brightnessctl set 1%-";
    on-scroll-up = "${pkgs.brightnessctl}/bin/brightnessctl set +1%";
  };
  battery = {
    interval = 10;
    format = mkSpan "BAT" "{capacity}% {power:.1f}W";
    format-charging = mkSpan "CHG" "{capacity}% {power:.1f}W";
  };
  clock = {
    format = "{:%a %b %d %H:%M}";
    tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
  };
  memory = {
    format = mkSpan "MEM" "{percentage}%";
  };
  temperature = {
    format = mkSpan "TEMP" "{temperatureC}°C";
    interval = 10;
    thermal-zone = 3;
  };
  tray = {
    icon-size = 25;
    spacing = 10;
  };
}
