{
  secondfront.hyprland.monitors = [
    {
      name = "eDP-1";
      width = 2880;
      height = 1920;
      refreshRate = 120;
      scale = "1.5";
    }
  ];
  wayland.windowManager.hyprland.bind = [
    "$mainmod, Return, exec, kitty"
  ];
}
