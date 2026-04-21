{ ... }:
{
  flake.modules.homeManager.users-saifs-core-programs =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        neofetch
        nil
        nixd
        jetbrains-mono
        nerd-fonts.jetbrains-mono
        monocraft
        tmux
        fastfetch
        bitwarden-cli

        # devenv stuff, maybe move to shells...
        go
        zig
        nodejs
        clang
        python3
        gnumake
        claude-code

        cargo
        rustc
        rust-analyzer

        firecracker
      ];
    };
}
