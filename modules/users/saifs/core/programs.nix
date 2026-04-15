{ ... }:
{
  flake.modules.homeManager.users-saifs-core-programs =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        neofetch
        go
        rustup
        zig
        nodejs
        gcc
        python3
        gnumake
        claude-code
        readline
        nil
        nixd
        jetbrains-mono
        nerd-fonts.jetbrains-mono
        monocraft
        tmux
        fastfetch
      ];
    };
}
