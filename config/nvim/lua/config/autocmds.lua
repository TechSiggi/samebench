-- Custom autocommands (in addition to the LazyVim defaults).

local group = vim.api.nvim_create_augroup("samebench_autocmds", { clear = true })

-- Open the explorer on the left at startup (when Neovim is started without a file,
-- e.g. via `dev`). Toggle it any time with <Space>e.
if vim.g.samebench_explorer_on_start ~= false and vim.fn.argc(-1) == 0 then
  vim.schedule(function()
    pcall(function()
      Snacks.explorer()
    end)
  end)
end

-- Notice changes by the coding agent quickly: LazyVim checks on focus
-- change; additionally after 1 s of idle time (updatetime) if you stay in the editor.
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  group = group,
  callback = function()
    if vim.fn.mode() ~= "c" and vim.fn.getcmdwintype() == "" then
      vim.cmd("silent! checktime")
    end
  end,
})

-- Make it visible when a file was reloaded after an external change
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = group,
  callback = function(ev)
    vim.notify("Changed externally and reloaded: " .. vim.fn.fnamemodify(ev.file, ":~:."), vim.log.levels.INFO)
  end,
})
