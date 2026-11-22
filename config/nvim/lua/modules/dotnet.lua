-- Module "dotnet": C# through easy-dotnet.nvim (Roslyn, build, run, test, NuGet, project files).
-- The .NET SDK comes from the system. `samebench apply` installs two .NET tools at the versions
-- pinned in envs/dotnet/tools.txt into SAMEBENCH_DOTNET_TOOLS, a folder that only Neovim has
-- on its PATH:
--   EasyDotnet              dotnet-easydotnet, the server behind the plugin
--   roslyn-language-server  the C# language server, started by `dotnet-easydotnet roslyn start`
-- With both on the PATH nothing installs itself: the plugin would otherwise run
-- `dotnet tool install -g EasyDotnet`, and its server
-- `dotnet tool install --global roslyn-language-server --prerelease`, both unpinned. So the
-- plugin never loads while one of the two is missing.
--
-- Opening a C# project makes the language server evaluate the MSBuild files and run
-- design-time builds, which runs build targets from the folder. There is no mode without
-- that, so the plugin only loads in a folder you trusted: `dev` asks once per project folder
-- and hands the answer to the session, and Neovim has to be started in that folder or below
-- it (lua/samebench/trust.lua). TRUST="all" trusts every folder. Everywhere else the plugin
-- stays unloaded and C# gets Tree-sitter highlighting only.

local trust = require("samebench.trust")
local trusted = trust.trusted()

local data = vim.env.XDG_DATA_HOME or (vim.env.HOME .. "/.local/share")
local tools = vim.env.SAMEBENCH_DOTNET_TOOLS or (data .. "/samebench/dotnet-tools")
if vim.fn.isdirectory(tools) == 1 and not (":" .. vim.env.PATH .. ":"):find(":" .. tools .. ":", 1, true) then
  vim.env.PATH = tools .. ":" .. vim.env.PATH
end
-- Both pinned tools are in place, so neither the plugin nor its server has a reason to install one
local ready = vim.fn.executable(tools .. "/dotnet-easydotnet") == 1
  and vim.fn.executable(tools .. "/roslyn-language-server") == 1
local active = trusted and ready

-- Files that make a folder a .NET project (the same ones `dev` looks for)
local function dotnet_marker(name)
  return name:match("%.slnx?$") ~= nil or name:match("%.[cf]sproj$") ~= nil
end

-- Not active: say why once per Neovim session, the first time a file inside a .NET project opens.
if not active then
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("samebench_dotnet_trust", { clear = true }),
    pattern = { "cs", "fsharp", "razor", "xml", "solution" },
    callback = function(ev)
      if vim.g.samebench_dotnet_trust_note then
        return true -- already said, drop the autocommand
      end
      -- of the XML files only the ones that belong to MSBuild
      local name = vim.api.nvim_buf_get_name(ev.buf)
      local msbuild = dotnet_marker(name) or name:match("%.props$") or name:match("%.targets$")
      if vim.bo[ev.buf].filetype == "xml" and not msbuild then
        return
      end
      if vim.bo[ev.buf].buftype ~= "" or not vim.fs.root(ev.buf, dotnet_marker) then
        return
      end
      vim.g.samebench_dotnet_trust_note = true
      vim.schedule(function()
        local why = "This folder is not trusted, so the C# language server is off and you get highlighting only.\n"
          .. trust.hint
        if trusted then
          why = "The .NET tools of samebench are not installed, so the C# language server is off.\n"
            .. "Run samebench apply, it needs a .NET SDK 10 or newer on this machine."
        end
        vim.notify(why, vim.log.levels.INFO, { title = "samebench dotnet" })
      end)
      return true
    end,
  })
end

-- The EasyDotnet server asks api.nuget.org (always nuget.org, never the feeds in your NuGet
-- configuration) for newer versions of itself and of roslyn-language-server when it starts,
-- at most every 6 hours, and keeps the time of the last check in
-- <temp folder>/easy-dotnet/last-*update-check.txt. It has no option for that. A check time
-- in the future makes it skip the request. This is best effort and depends on how the
-- current server works. New versions come through envs/dotnet/tools.txt instead.
--
-- On Linux the temp folder is /tmp, which every user of the machine shares. So the files are
-- only written into a folder that belongs to you and that nobody else can write to. Each one
-- is written under another name and then renamed, which replaces a link somebody may have put
-- in its place instead of writing through it. Otherwise nothing is written and the server
-- does its check.
local function skip_server_update_checks()
  local uv = vim.uv
  local dir = uv.os_tmpdir() .. "/easy-dotnet"
  local st = uv.fs_lstat(dir)
  if not st then
    uv.fs_mkdir(dir, 448) -- 0700
    st = uv.fs_lstat(dir)
  end
  -- 18 is 0022: writable for the group or for everyone
  if not st or st.type ~= "directory" or st.uid ~= uv.getuid() or bit.band(st.mode, 18) ~= 0 then
    return
  end
  local c = uv.constants
  for _, name in ipairs({ "last-update-check.txt", "last-roslyn-update-check.txt" }) do
    local tmp = dir .. "/" .. name .. ".samebench"
    uv.fs_unlink(tmp)
    -- O_EXCL: only a new file, never an existing one or a link
    local fd = uv.fs_open(tmp, bit.bor(c.O_WRONLY, c.O_CREAT, c.O_EXCL), 420) -- 0644
    if fd then
      uv.fs_write(fd, '{ "LastCheckTime": "9999-01-01T00:00:00Z" }\n')
      uv.fs_close(fd)
      if not uv.fs_rename(tmp, dir .. "/" .. name) then
        uv.fs_unlink(tmp)
      end
    end
  end
end

local function dotnet(command)
  return "<cmd>Dotnet " .. command .. "<cr>"
end

-- The plugin looks for its server with `dotnet easydotnet -v` and installs the newest one
-- when that fails, unless this file says it is installed. Both tools are in place here
-- (see "ready"), so the file is written up front and that path is never taken.
local function mark_server_installed()
  local dir = vim.fn.stdpath("data") .. "/easy-dotnet"
  if pcall(vim.fn.mkdir, dir, "p") and vim.fn.filereadable(dir .. "/easy_dotnet_installed") == 0 then
    pcall(vim.fn.writefile, { "installed" }, dir .. "/easy_dotnet_installed")
  end
end

-- Every trigger that loads the plugin only exists in a trusted folder with the tools in place
local triggers = {}
if active then
  triggers.ft = { "cs", "fsharp", "razor" }
  triggers.event = {}
  for _, pattern in ipairs({ "*.sln", "*.slnx", "*.csproj", "*.fsproj", "*.props", "*.targets" }) do
    table.insert(triggers.event, "BufReadPre " .. pattern)
    table.insert(triggers.event, "BufNewFile " .. pattern)
  end
  triggers.cmd = "Dotnet"
  triggers.keys = {
    { "<leader>Db", dotnet("build"), desc = "Build" },
    { "<leader>Dr", dotnet("run"), desc = "Run" },
    { "<leader>Dt", dotnet("testrunner"), desc = "Test runner" },
    { "<leader>DT", dotnet("test"), desc = "Run tests" },
    { "<leader>DR", dotnet("restore"), desc = "Restore packages" },
    { "<leader>Dd", dotnet("diagnostic"), desc = "Workspace diagnostics" },
  }
end

return {
  {
    "GustavEikaas/easy-dotnet.nvim",
    -- lua/plugins/modules.lua names this plugin for every machine, so it is always installed
    -- and pinned. Here it only gets what loads it. `cond = trusted` would not do: lazy.nvim
    -- does not install a plugin whose cond is false.
    lazy = true,
    ft = triggers.ft,
    event = triggers.event,
    cmd = triggers.cmd,
    keys = triggers.keys,
    dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim" },
    init = function()
      if active then
        mark_server_installed()
        skip_server_update_checks()
      end
    end,
    opts = {
      picker = "snacks",
      lsp = {
        enabled = true,
        suggest_updates = false, -- only hides the message, the request itself is skipped above
      },
      debugger = { auto_register_dap = false }, -- no nvim-dap in this setup
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    -- c_sharp and razor for the code, xml for project files. easy-dotnet also highlights SQL,
    -- JSON and XML inside C# strings (json is in the core list).
    opts = { ensure_installed = { "c_sharp", "xml", "razor", "sql" } },
  },
  {
    "folke/which-key.nvim",
    opts = { spec = active and { { "<leader>D", group = "dotnet" } } or {} },
  },
}
