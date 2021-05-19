{
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
