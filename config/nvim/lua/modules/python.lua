-- Module "python": settings only, NO additional plugins.
-- The ruff + ty language servers come from mise (modules/python/tools.toml).
-- The notebook workflow is our own code: lua/samebench/notebook.lua

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruff = {}, -- linter/formatter (fast error hints, quick fixes)
        ty = {}, -- type checking, autocomplete, go to definition
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "python", "requirements" } },
  },
  {
    "stevearc/conform.nvim",
    opts = { formatters_by_ft = { python = { "ruff_format" } } },
  },
  {
    "folke/which-key.nvim",
    opts = { spec = { { "<leader>j", group = "jupyter" } } },
  },
}
