-- Custom keymaps (in addition to the LazyVim defaults).
-- Overview: press <Space> and wait a moment, which-key shows everything.
-- Short cheat sheet: <Space>H (docs/quickref.md)

local map = vim.keymap.set

-- Ctrl+h/j/k/l: move between Neovim windows AND tmux panes.
-- At the edge of Neovim it continues seamlessly into the next tmux pane (agent, console).
local function navigate(wincmd, tmux_dir)
  return function()
    local before = vim.api.nvim_get_current_win()
    vim.cmd.wincmd(wincmd)
    if vim.api.nvim_get_current_win() == before and vim.env.TMUX then
      vim.system({ "tmux", "select-pane", "-" .. tmux_dir })
    end
  end
end
map("n", "<C-h>", navigate("h", "L"), { desc = "Window left (also tmux)" })
map("n", "<C-j>", navigate("j", "D"), { desc = "Window below (also tmux)" })
map("n", "<C-k>", navigate("k", "U"), { desc = "Window above (also tmux)" })
map("n", "<C-l>", navigate("l", "R"), { desc = "Window right (also tmux)" })

-- Open the cheat sheet
map("n", "<leader>H", function()
  local file = vim.fn.resolve(vim.fn.stdpath("config")) .. "/../../docs/quickref.md"
  file = vim.fn.fnamemodify(file, ":p")
  local ok = pcall(function()
    Snacks.win({ file = file, width = 0.85, height = 0.85, wo = { wrap = false, conceallevel = 2 } })
  end)
  if not ok then
    vim.cmd.tabedit(file)
  end
end, { desc = "Cheat sheet (short version)" })
