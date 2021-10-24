{ fetchurl }:
{
  "org/gnome/desktop/background" = {
    picture-uri = "file://${fetchurl {
      url = "https://pbs.twimg.com/media/ElphQpaU4AAt9Bv?format=jpg";
      name = "fubuki.jpg";
      hash = "sha256-541/iI7scwyyEOxZAYFql4X/W5xmg5hUfeDJbtJ+voE=";
      }}";
  };

  "org/gnome/desktop/screensaver" = {
    picture-uri = "file://${fetchurl {
      url = "https://i.pximg.net/img-original/img/2021/09/21/22/56/43/42732108_p0.jpg";
      curlOpts = "-H referer:https://www.pixiv.net/";
      hash = "sha256-Tix/HzEo3h2hKye27MUpi10gVFeo7HC1ukHdqHVcVKg=";
      }}";
  };

  "org/gnome/shell" = {
    disable-user-extensions = false;
  };

  "org/gnome/desktop/interface" = {
    clock-show-weekday = false;
    document-font-name = "Roboto 11";
    enable-animations = true;
    font-antialiasing = "rgba";
    font-hinting = "slight";
    font-name = "Roboto 11";
    gtk-im-module = "ibus";
    gtk-theme = "Materia";
    icon-theme = "Numix-Circle";
    show-battery-percentage = true;
  };

  "org/gnome/desktop/peripherals/touchpad" = {
    click-method = "areas";
    tap-to-click = true;
    two-finger-scrolling-enabled = true;
  };

  "org/gnome/desktop/wm/preferences" = {
    button-layout = "appmenu:minimize,maximize,close";
    titlebar-font = "Roboto Bold 11";
  };

  "org/gnome/mutter" = {
    attach-modal-dialogs = true;
    dynamic-workspaces = true;
    edge-tiling = true;
    focus-change-on-pointer-rest = true;
    workspaces-only-on-primary = true;
  };
}
