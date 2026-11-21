-- Set up lazy.nvim, hardened:
--  * lazy.nvim itself is pinned to the commit from lazy-lock.json
--  * LazyVim is fetched the same way before lazy.nvim starts (see below)
--  * no automatic update check, no luarocks, no plugin specs from project folders
--  * modules (SAMEBENCH_MODULES from the profile) control what is loaded in addition

local lazyroot = vim.fn.stdpath("data") .. "/lazy"
local lazypath = lazyroot .. "/lazy.nvim"
local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"

local function locked_commit(name)
  local f = io.open(lockfile, "r")
  if not f then
    return nil
  end
  local ok, data = pcall(vim.json.decode, f:read("*a"))
  f:close()
  return ok and data[name] and data[name].commit or nil
end

-- fetch(name, repo, path, commit, branch): clone a plugin that is missing and check out its
-- locked commit. Neovim ends when that fails.
local function fetch(name, repo, path, commit, branch)
  if (vim.uv or vim.loop).fs_stat(path) then
    return
  end
  local clone = { "git", "clone", "--filter=blob:none" }
  if branch then
    table.insert(clone, "--branch=" .. branch)
  end
  local out = vim.fn.system(vim.list_extend(clone, { repo, path }))
  if vim.v.shell_error == 0 and commit then
    out = vim.fn.system({ "git", "-C", path, "checkout", "--quiet", commit })
  end
  if vim.v.shell_error ~= 0 then
    vim.fn.delete(path, "rf") -- never start from a checkout that is not the locked commit
    vim.api.nvim_echo({ { "Failed to load " .. name .. ":\n", "ErrorMsg" }, { out } }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

fetch("lazy.nvim", "https://github.com/folke/lazy.nvim.git", lazypath, locked_commit("lazy.nvim"), "stable")
vim.opt.rtp:prepend(lazypath)

-- Most plugins are named by LazyVim. While LazyVim is missing, lazy.nvim installs in two
-- rounds, and after the first round it forgets the locked commits of every plugin it has
-- not seen yet. Those plugins would then be installed, and loaded once, at their newest
-- commit. With LazyVim in place before lazy.nvim starts, one round installs everything at
-- its locked commit. Without a lockfile there is nothing to pin, and lazy.nvim fetches it.
local lazyvim_commit = locked_commit("LazyVim")
if lazyvim_commit then
  fetch("LazyVim", "https://github.com/LazyVim/LazyVim.git", lazyroot .. "/LazyVim", lazyvim_commit)
end

-- Active modules from the profile (set by `samebench apply`), e.g. "core python"
local modules = {}
for m in (vim.env.SAMEBENCH_MODULES or "core"):gmatch("%S+") do
  modules[m] = true
end
vim.g.samebench_modules = modules

local spec = {
  { "LazyVim/LazyVim", import = "lazyvim.plugins" },
  { import = "plugins" }, -- applies everywhere (lua/plugins/*.lua)
}
-- Module-specific settings: lua/modules/<module>.lua
local moddir = vim.fn.stdpath("config") .. "/lua/modules"
for _, file in ipairs(vim.fn.globpath(moddir, "*.lua", false, true)) do
  local m = vim.fn.fnamemodify(file, ":t:r")
  if modules.all or modules[m] then
    table.insert(spec, { import = "modules." .. m })
  end
end

require("lazy").setup({
  spec = spec,
  defaults = { lazy = false, version = false },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = false }, -- no background update check; updates only via `samebench update`
  change_detection = { notify = false },
  rocks = { enabled = false }, -- no luarocks/hererocks
  local_spec = false, -- a .lazy.lua in a project folder could add plugins that are not in the lockfile
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "zipPlugin" }, -- "tutor" stays: :Tutor for learning
    },
  },
})
