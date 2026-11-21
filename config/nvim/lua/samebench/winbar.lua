-- Path bar above every code window: "project › folder/file ●"
-- Only for real files (not the explorer, start page, search, help).
-- For notebooks the .ipynb is shown instead of the hidden shadow file.

local M = {}

function M.render()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  local nb = vim.b[buf].samebench_notebook
  if nb then
    name = nb
  end
  local root = vim.fn.getcwd()
  local rel = vim.fn.fnamemodify(name, ":p")
  if rel:sub(1, #root + 1) == root .. "/" then
    rel = rel:sub(#root + 2)
  else
    rel = vim.fn.fnamemodify(name, ":~")
  end
  local dir, file = rel:match("^(.*/)([^/]+)$")
  dir, file = dir or "", file or rel
  local esc = function(s)
    return (s:gsub("%%", "%%%%"))
  end
  local modified = vim.bo[buf].modified and " %#SamebenchWinbarModified#●" or ""
  return (" %s › %s%%#SamebenchWinbarFile#%s%s"):format(
    esc(vim.fn.fnamemodify(root, ":t")),
    esc(dir),
    esc(file),
    modified
  )
end

function M.setup()
  vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType" }, {
    group = vim.api.nvim_create_augroup("samebench_winbar", { clear = true }),
    callback = function(ev)
      local buf = ev.buf
      for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        local cfg = vim.api.nvim_win_get_config(win)
        local is_file = vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= ""
        if cfg.relative == "" and is_file then
          vim.wo[win].winbar = "%{%v:lua.require'samebench.winbar'.render()%}"
        elseif cfg.relative == "" then
          vim.wo[win].winbar = ""
        end
      end
    end,
  })
end

return M
