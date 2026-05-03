{ inputs, ... }:
{
  flake.modules.homeManager.users-saifs-desktop-programs =
    { pkgs, ... }:
    let
      unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
    in
    {
      home.packages = with pkgs; [
        ghostty
        unstable.zed-editor
        vesktop
        fuzzel
        spotify
        sway-contrib.grimshot
        playerctl
        brightnessctl
        bitwarden-desktop
        obsidian
        jetbrains.idea-ultimate
        jdk21
        mullvad-vpn
        lunar-client
        prismlauncher
        cutechess
      ];

      home.sessionVariables = {
        _JAVA_AWT_WM_NONREPARENTING = "1";
      };

      home.pointerCursor = {
        name = "macOS";
        package = pkgs.apple-cursor;
        size = 20;
        gtk.enable = true;
        hyprcursor.enable = true;
      };

      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = false;
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "text/html" = "zen.desktop";
          "x-scheme-handler/http" = "zen.desktop";
          "x-scheme-handler/https" = "zen.desktop";
        };
      };

      dconf.settings."org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };

      gtk = {
        enable = true;
        gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
        gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
      };

      xdg.configFile.hypr.source = ./hypr;
      xdg.configFile.ghostty.source = ./ghostty;
      xdg.configFile.niri.source = ./niri;
      xdg.configFile.tmux.source = ./tmux;
    };
}
