-- Entry point: load lazy.nvim + LazyVim (lua/config/lazy.lua)
require("config.lazy")

-- Path bar above the code (project › file)
require("samebench.winbar").setup()

-- Notebook workflow (own code, no plugin), only with module "python"
if vim.g.samebench_modules.python or vim.g.samebench_modules.all then
  require("samebench.notebook").setup()
end
