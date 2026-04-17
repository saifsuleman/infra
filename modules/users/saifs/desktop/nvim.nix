{ ... }:
{
  flake.modules.homeManager.users-saifs-desktop-nvim =
    { pkgs, ... }:
    {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;

        plugins = with pkgs.vimPlugins; [
          # Telescope
          telescope-nvim
          plenary-nvim

          # Treesitter
          (nvim-treesitter.withPlugins (p: [
            p.nix
            p.lua
            p.bash
            p.json
            p.yaml
            p.toml
            p.markdown
            p.python
            p.rust
            p.go
            p.javascript
            p.typescript
            p.kotlin
          ]))

          # LSP
          nvim-lspconfig

          # Harpoon
          harpoon2

          # Theme
          neovim-ayu
        ];
      };

      home.packages = with pkgs; [
        # LSP servers
        lua-language-server
        nil # nix lsp
        kotlin-language-server
        # Telescope dependencies
        ripgrep
        fd
      ];

      xdg.configFile.nvim.source = ./nvim;
    };
}
