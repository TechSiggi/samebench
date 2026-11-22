-- Plugins that belong to an optional module, named here for EVERY machine.
--
-- lazy-lock.json is one list for all machines, and lazy.nvim writes it again from the plugins
-- it knows whenever it installs or restores something. A plugin that only a module's file
-- names would lose its pin on every machine without that module, and `samebench apply`
-- compares every pinned plugin with its checkout. So such a plugin is declared here without
-- anything that loads it. It is checked out everywhere, at its locked commit, and stays
-- unloaded. What loads it (file types, commands, keys) and its settings are in
-- lua/modules/<module>.lua, which only exists for lazy.nvim when the module is active.

return {
  { "GustavEikaas/easy-dotnet.nvim", lazy = true }, -- module "dotnet"
}
