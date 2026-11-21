-- Set up lazy.nvim, hardened:
--  * lazy.nvim itself is pinned to the commit from lazy-lock.json
--  * no automatic update check, no luarocks, no plugin specs from project folders
--  * modules (SAMEBENCH_MODULES from the profile) control what is loaded in addition

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
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

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  local commit = locked_commit("lazy.nvim")
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", repo, lazypath })
  if vim.v.shell_error == 0 and commit then
    out = vim.fn.system({ "git", "-C", lazypath, "checkout", "--quiet", commit })
  end
  if vim.v.shell_error ~= 0 then
    vim.fn.delete(lazypath, "rf") -- never start from a checkout that is not the locked commit
    vim.api.nvim_echo({ { "Failed to load lazy.nvim:\n", "ErrorMsg" }, { out } }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

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
