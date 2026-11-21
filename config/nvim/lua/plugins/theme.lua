-- "Liquid Glass" look, the same on Mac AND Linux.
--
-- * Tokyo Night "moon" with a transparent background: the terminal's glass
--   effect (macOS: profile "Clear Dark", 80 % opacity) shines through.
-- * Mint accent color, italic comments, current line highlighted.
-- * Icons: profile setting ICONS (SAMEBENCH_ICONS). "nerd" = real icons and round
--   pills (Nerd Font required), otherwise Unicode/letters (lua/plugins/icons_unicode.lua).
--
-- Only plugins that LazyVim ships anyway, nothing extra is downloaded.

local nerd = vim.env.SAMEBENCH_ICONS == "nerd"

local C = {
  accent = "#8ff0c8", -- Mint
  violet = "#c3a6ff",
  pink = "#ff9ecf",
  orange = "#ffc27a",
  blue = "#8ec5ff",
  green = "#c3e88d",
  red = "#ff757f",
  dark = "#14162a", -- text on accent surfaces
  surface = "#2a2e45", -- subtle surfaces (pills, bars, current line)
  muted = "#6b7089",
  border = "#3b4261", -- inactive borders, as in tmux and lazygit
  fg = "#c8d3f5",
}

-- Highlights for the tab bar (bufferline spec below), all groups transparent
local tabbar = {
  buffer_selected = { bg = "NONE", fg = C.accent, bold = true, italic = false },
  modified_selected = { bg = "NONE", fg = C.accent },
  tab_selected = { bg = "NONE", fg = C.accent },
}
for _, group in ipairs({
  "fill", "background", "buffer_visible", "separator", "separator_visible", "separator_selected", "modified",
  "modified_visible", "duplicate", "duplicate_visible", "duplicate_selected", "offset_separator", "tab",
  "tab_separator", "tab_separator_selected", "trunc_marker",
}) do
  tabbar[group] = { bg = "NONE" }
end

return {
  -- Color scheme ------------------------------------------------------------
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "moon",
      transparent = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        sidebars = "transparent",
        floats = "transparent",
      },
      on_highlights = function(hl, c)
        -- Borders, titles and icons in mint
        for _, group in ipairs({
          "FloatBorder", "Directory", "SnacksDashboardHeader", "SnacksDashboardIcon", "SnacksIndentScope",
          "SnacksPickerBorder", "SnacksPickerInputBorder", "SnacksPickerBoxBorder", "SnacksPickerPrompt",
          "WhichKeyBorder", "NoiceCmdlinePopupBorder", "NoiceCmdlineIcon",
        }) do
          hl[group] = { fg = C.accent }
        end
        for _, group in ipairs({
          "CursorLineNr", "FloatTitle", "SnacksDashboardKey", "SnacksPickerTitle", "SnacksPickerInputTitle",
          "SnacksPickerBoxTitle",
        }) do
          hl[group] = { fg = C.accent, bold = true }
        end
        -- Transparent tab and status lines
        for _, group in ipairs({ "TabLineFill", "StatusLine", "StatusLineNC" }) do
          hl[group] = { bg = "NONE" }
        end
        hl.CursorLine = { bg = C.surface }
        hl.Visual = { bg = "#3a4060" }
        hl.WinSeparator = { fg = C.border }
        hl.SnacksPickerListBorder = { fg = C.border }
        hl.SnacksDashboardDesc = { fg = c.fg }
        hl.SnacksPickerDir = { fg = C.muted }
        -- Git status in the explorer
        hl.SnacksPickerGitStatusModified = { fg = C.orange }
        hl.SnacksPickerGitStatusAdded = { fg = C.green }
        hl.SnacksPickerGitStatusDeleted = { fg = C.red }
        hl.SnacksPickerGitStatusUntracked = { fg = C.muted }
        hl.SnacksPickerGitStatusStaged = { fg = C.accent }
        -- Path bar above the code (lua/samebench/winbar.lua)
        hl.WinBar = { fg = C.muted, bg = "NONE" }
        hl.WinBarNC = { fg = C.muted, bg = "NONE" }
        hl.SamebenchWinbarFile = { fg = C.accent, bold = true }
        hl.SamebenchWinbarModified = { fg = C.orange }
        -- Notebook cells (lua/samebench/notebook.lua)
        hl.SamebenchCellBar = { bg = C.surface }
        hl.SamebenchCellTitle = { fg = C.accent, bg = C.surface, bold = true }
        hl.SamebenchCellRule = { fg = C.muted, bg = C.surface }
        hl.SamebenchCellDone = { fg = C.accent, bg = C.surface }
        hl.SamebenchCellMarkdown = { fg = C.violet, italic = true }
      end,
    },
  },

  { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight" } },

  -- lazygit (<Space>gg) uses the same configuration as in tmux (LG_CONFIG_FILE)
  { "folke/snacks.nvim", opts = { lazygit = { configure = false } } },

  -- Status line: mode as a mint pill, the rest transparent and plain
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local function mode(color)
        return {
          a = { fg = C.dark, bg = color, gui = "bold" },
          b = { fg = color, bg = C.surface },
          c = { fg = C.muted, bg = "NONE" },
        }
      end
      -- File name/type only for real files (not the explorer, start page, search)
      local function is_file()
        return vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) ~= ""
      end
      local icons = LazyVim.config.icons
      opts.options.theme = {
        normal = mode(C.accent),
        insert = mode(C.violet),
        visual = mode(C.pink),
        replace = mode(C.orange),
        command = mode(C.blue),
        terminal = mode(C.blue),
        inactive = mode(C.muted),
      }
      opts.options.icons_enabled = nerd
      if nerd then
        -- round pill ends (Powerline half circles from the Nerd Font)
        opts.options.section_separators = { left = "\u{e0b4}", right = "\u{e0b6}" }
      else
        opts.options.section_separators = { left = "", right = "" }
      end
      opts.options.component_separators = { left = "", right = "" }
      opts.sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch" },
        lualine_c = {
          {
            "diagnostics",
            symbols = {
              error = icons.diagnostics.Error,
              warn = icons.diagnostics.Warn,
              info = icons.diagnostics.Info,
              hint = icons.diagnostics.Hint,
            },
          },
          {
            "filename",
            path = 1,
            cond = is_file,
            symbols = { modified = " ●", readonly = " ×", unnamed = "", newfile = "[new]" },
            -- Notebooks: show the .ipynb instead of the hidden shadow file
            fmt = function(str)
              return (str:gsub("%.([^/]+)%.nb%.py", "%1.ipynb"))
            end,
          },
        },
        lualine_x = {
          { "diff", symbols = { added = icons.git.added, modified = icons.git.modified, removed = icons.git.removed } },
          { "filetype", colored = false, cond = is_file },
        },
        lualine_y = { { "progress", cond = is_file } },
        lualine_z = { { "location", cond = is_file } },
      }
    end,
  },

  -- Tab bar at the top: transparent, active file in mint
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        show_buffer_close_icons = false,
        show_close_icon = false,
        separator_style = { "", "" },
        indicator = { style = "none" },
      },
      highlights = tabbar,
    },
  },
}
