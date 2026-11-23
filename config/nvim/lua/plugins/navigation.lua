-- Ctrl+h/j/k/l moves through Neovim windows and tmux panes from everywhere
-- (config/nvim/lua/config/keymaps.lua and config/tmux/tmux.conf).
-- The file list of the explorer maps Ctrl+j/k to the next and previous entry by itself,
-- so Ctrl+j never left the explorer for the terminal and the agent below. j and k still
-- move through the list, and the search field of the explorer keeps Ctrl+j/k.
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            win = { list = { keys = { ["<c-j>"] = false, ["<c-k>"] = false } } },
          },
        },
      },
    },
  },
}
