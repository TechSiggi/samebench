-- Icons without a Nerd Font (profile setting ICONS="unicode"):
-- all glyphs are replaced by plain Unicode characters or letters
-- that every terminal renders with system fonts (no question-mark boxes).
-- With ICONS="nerd" this file has no effect, and the LazyVim defaults apply.

if vim.env.SAMEBENCH_ICONS == "nerd" then
  return {}
end

local kinds = {}
for _, k in ipairs({
  "Array", "Boolean", "Class", "Codeium", "Color", "Control", "Constant", "Constructor", "Copilot",
  "Enum", "EnumMember", "Event", "Field", "File", "Folder", "Function", "Interface", "Key", "Keyword",
  "Method", "Module", "Namespace", "Null", "Number", "Object", "Operator", "Package", "Property",
  "Reference", "Snippet", "String", "Struct", "Supermaven", "TabNine", "Text", "TypeParameter",
  "Unit", "Value", "Variable",
}) do
  kinds[k] = ""
end
kinds.Collapsed = "▸ "

local diagnostics = { Error = "✘ ", Warn = "▲ ", Hint = "⚑ ", Info = "● " }

return {
  {
    "LazyVim/LazyVim",
    opts = {
      icons = {
        misc = { dots = "…" },
        ft = { octo = "", gh = "", ["markdown.gh"] = "" },
        dap = {
          Stopped = { "→ ", "DiagnosticWarn", "DapStoppedLine" },
          Breakpoint = "● ",
          BreakpointCondition = "◆ ",
          BreakpointRejected = { "○ ", "DiagnosticError" },
          LogPoint = ".>",
        },
        diagnostics = diagnostics,
        git = { added = "+ ", modified = "~ ", removed = "- " },
        kinds = kinds,
      },
    },
  },

  -- File icons as letters instead of glyphs
  { "nvim-mini/mini.icons", opts = { style = "ascii" } },

  -- Explorer, search, start screen
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = opts.picker or {}
      opts.picker.prompt = "› "
      opts.picker.icons = vim.tbl_deep_extend("force", opts.picker.icons or {}, {
        files = { dir = "▸ ", dir_open = "▾ ", file = "  " },
        keymaps = { nowait = "» " },
        undo = { saved = "● " },
        ui = { live = "◉ ", selected = "● ", unselected = "○ " },
        git = {
          commit = "◇ ", staged = "●", added = "+", deleted = "-", ignored = "·",
          modified = "~", renamed = "→", unmerged = "!", untracked = "?",
        },
        diagnostics = diagnostics,
        lsp = { unavailable = "×", enabled = "● ", disabled = "○ ", attached = "◉ " },
        kinds = kinds,
      })
      local dash = opts.dashboard and opts.dashboard.preset
      if dash and dash.keys then
        for _, key in ipairs(dash.keys) do
          key.icon = "› "
        end
      end
    end,
  },

  -- Tab bar: symbols without glyphs
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        buffer_close_icon = "×",
        close_icon = "×",
        modified_icon = "●",
        left_trunc_marker = "‹",
        right_trunc_marker = "›",
      },
    },
  },

  -- Key help without glyphs
  {
    "folke/which-key.nvim",
    opts = {
      icons = {
        mappings = false,
        keys = {
          Up = "↑ ", Down = "↓ ", Left = "← ", Right = "→ ",
          C = "C-", M = "M-", D = "D-", S = "S-",
          CR = "⏎ ", Esc = "Esc ", NL = "⏎ ", BS = "⌫ ", Space = "␣ ", Tab = "⇥ ",
          ScrollWheelDown = "↓ ", ScrollWheelUp = "↑ ",
          F1 = "F1", F2 = "F2", F3 = "F3", F4 = "F4", F5 = "F5", F6 = "F6",
          F7 = "F7", F8 = "F8", F9 = "F9", F10 = "F10", F11 = "F11", F12 = "F12",
        },
      },
    },
  },

  -- Command line without glyphs
  {
    "folke/noice.nvim",
    opts = {
      cmdline = {
        format = {
          cmdline = { icon = ":" },
          search_down = { icon = "/ " },
          search_up = { icon = "? " },
          filter = { icon = "$" },
          lua = { icon = "lua" },
          help = { icon = "?" },
          calculator = { icon = "=" },
          input = { icon = "› " },
        },
      },
    },
  },
}
