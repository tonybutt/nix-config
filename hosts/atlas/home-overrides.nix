{
  programs.waybar.settings.mainBar."hyprland/workspaces".persistent-workspaces = {
    "1" = [ "*" ];
    "2" = [ "*" ];
    "3" = [ "*" ];
    "4" = [ "*" ];
    "5" = [ "*" ];
    "6" = [ "*" ];
    "7" = [ "*" ];
    "8" = [ "*" ];
    "9" = [ "*" ];
    "10" = [ "*" ];
  };

  wayland.windowManager.hyprland.settings.workspace = [
    "1, monitor:desc:Dell Inc. DELL S3220DGF BG9TF43, default:true"
    "2, monitor:desc:Dell Inc. DELL S3220DGF BG9TF43"
    "3, monitor:desc:Dell Inc. DELL S3220DGF BG9TF43"
    "4, monitor:desc:Dell Inc. DELL S3220DGF BG9TF43"
    "5, monitor:desc:Dell Inc. DELL S3220DGF BG9TF43"
    "6, monitor:desc:Dell Inc. DELL U2718Q 4K8X703P0N8L, default:true"
    "7, monitor:desc:Dell Inc. DELL U2718Q 4K8X703P0N8L"
    "8, monitor:desc:Dell Inc. DELL U2718Q 4K8X703P0N8L"
    "9, monitor:desc:Dell Inc. DELL U2718Q 4K8X703P0N8L"
    "10, monitor:desc:Dell Inc. DELL U2718Q 4K8X703P0N8L"
  ];
  modules = {
    hyprland.monitors = [
      {
        name = "eDP-2";
        resolution = "highres@highrr";
        scale = "1.25";
        enabled = false;
      }
      {
        name = "desc:Dell Inc. DELL S3220DGF BG9TF43";
        position = "0x0";
      }
      {
        name = "desc:Dell Inc. DELL U2718Q 4K8X703P0N8L";
        position = "auto-right";
        resolution = "highres@high";
      }
    ];
  };
}
