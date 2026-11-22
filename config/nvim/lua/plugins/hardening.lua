-- Security hardening of LazyVim: nothing silently downloads programs from the network.
-- Programs only come from the pinned lists of this repository, installed by `samebench apply`:
-- tools from mise (mise.lock, checksums), the language servers of the web module from
-- envs/web (package-lock.json, integrity hashes) and the .NET tools of the dotnet module
-- from envs/dotnet/tools.txt (exact versions). Plugins come from lazy-lock.json (exact commits).

return {
  -- Mason off: it would download language servers from many sources (some via npm)
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },

  -- Autocomplete in pure Lua instead of a prebuilt binary from GitHub releases
  {
    "saghen/blink.cmp",
    opts = {
      fuzzy = {
        implementation = "lua",
        prebuilt_binaries = { download = false },
      },
    },
  },

  -- Only language servers that samebench installs (lua_ls is not one of them)
  {
    "neovim/nvim-lspconfig",
    opts = { servers = { lua_ls = { enabled = false } } },
  },

  -- Disable formatters that aren't available without Mason (otherwise warnings)
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.lua = {}
      opts.formatters_by_ft.sh = {}
      opts.formatters_by_ft.fish = {}
    end,
  },

  -- Treesitter: only the parsers that are really needed.
  -- Modules add their languages (e.g. lua/modules/python.lua).
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = {
        "bash",
        "diff",
        "gitcommit",
        "json",
        "lua",
        "luadoc",
        "markdown",
        "markdown_inline",
        "query",
        "regex",
        "toml",
        "vim",
        "vimdoc",
        "yaml",
      }
    end,
  },
}
