-- Custom options (LazyVim loads this file automatically before the plugins).
-- LazyVim defaults: https://www.lazyvim.org/configuration/general

-- Don't format automatically on save: in other people's repositories this would
-- reformat their code and produce huge diffs.
-- Format manually: <Space>cf   ·   Toggle auto-format: <Space>uf
vim.g.autoformat = false

-- Over SSH inside tmux, "+y goes through "tmux load-buffer -w", and tmux passes it on to
-- the local clipboard (OSC 52). tmux blocks OSC 52 from programs in a pane, see tmux.conf.
-- Locally the system clipboard tool is used (LazyVim default).
if vim.env.TMUX and (vim.env.SSH_CONNECTION or vim.env.SSH_TTY) then
  vim.g.clipboard = "tmux"
end

-- Files from other people's repositories don't get to set editor options
vim.o.modeline = false

vim.o.winborder = "rounded" -- rounded borders for floating windows (Liquid Glass)
vim.opt.fillchars:append({ eob = " " }) -- no ~ below the end of the file
vim.opt.scrolloff = 8 -- always some context above/below the cursor
vim.opt.updatetime = 1000 -- CursorHold after 1 s (checks for changes by the agent)
