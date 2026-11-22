-- Module "web": settings only, NO additional plugins.
-- Node comes from mise (modules/web/tools.toml). The language servers come from envs/web
-- (package-lock.json with integrity hashes), installed by `samebench apply` with
-- `npm ci --ignore-scripts` into SAMEBENCH_WEB_LSP. Every server is started from there by
-- its absolute path. nvim-lspconfig would otherwise prefer a vscode-*-language-server from
-- the project's node_modules/.bin, which is code from the project.
--
-- The servers can also load code from the project you open: its own TypeScript, its Angular
-- language service, tsserver plugins named in tsconfig.json, and ESLint with its JavaScript
-- configuration. They only do that in a folder you trusted: `dev` asks once per project
-- folder and hands the answer to the session, and Neovim has to be started in that folder
-- or below it (lua/samebench/trust.lua). TRUST="all" trusts every folder. Everywhere else,
-- also in a Neovim started without `dev`, the restricted mode applies: TypeScript and the
-- Angular language service come from the samebench environment, ESLint and prettier stay
-- off, and the JSON server downloads no schemas.

local data = vim.env.XDG_DATA_HOME or (vim.env.HOME .. "/.local/share")
local env = vim.env.SAMEBENCH_WEB_LSP or (data .. "/samebench/web-lsp")
local nm = env .. "/node_modules"
local bin = nm .. "/.bin/"
local trust = require("samebench.trust")
local trusted = trust.trusted()

-- Angular templates. Neovim only says "htmlangular" when one of the first 40 lines holds
-- Angular syntax (@if, *ngFor, ng-template, ...), and new projects (Angular 20 and later)
-- name templates app.html instead of app.component.html. So every .html file inside an
-- Angular workspace counts as a template.
vim.filetype.add({
  pattern = {
    [".*%.html"] = {
      function(path)
        if vim.fs.root(path, { "angular.json", "nx.json" }) then
          return "htmlangular"
        end
      end,
      { priority = 1 },
    },
  },
})

-- Restricted mode: say so once per Neovim session, the first time a file inside a web
-- project opens.
if not trusted then
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("samebench_web_trust", { clear = true }),
    pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact", "html", "htmlangular", "css", "scss" },
    callback = function(ev)
      if vim.g.samebench_web_trust_note then
        return true -- already said, drop the autocommand
      end
      local markers = { "package.json", "tsconfig.json", "angular.json", "nx.json" }
      if vim.bo[ev.buf].buftype ~= "" or not vim.fs.root(ev.buf, markers) then
        return
      end
      vim.g.samebench_web_trust_note = true
      vim.schedule(function()
        vim.notify(
          "This folder is not trusted, so the project's own TypeScript, ESLint and prettier are off.\n" .. trust.hint,
          vim.log.levels.INFO,
          { title = "samebench web" }
        )
      end)
      return true
    end,
  })
end

-- Start <name> from the samebench environment, never from the project. A function on
-- purpose: with a list, lspconfig's eslint config would put "yarn exec" in front of it in
-- Yarn PnP projects, which runs the Yarn release the project ships.
local function env_cmd(name)
  return function(dispatchers, config)
    return vim.lsp.rpc.start({ bin .. name, "--stdio" }, dispatchers, { cwd = config and config.root_dir })
  end
end

-- Exact @angular/core version of the project, the installed one first, then package.json.
-- The files are only read as JSON.
local function angular_core_version(root)
  local function read_json(path)
    local ok, blob = pcall(vim.fn.readblob, path)
    if not ok then
      return {}
    end
    local okj, json = pcall(vim.json.decode, blob)
    return okj and type(json) == "table" and json or {}
  end
  local installed = read_json(root .. "/node_modules/@angular/core/package.json").version
  if type(installed) == "string" then
    return installed
  end
  local pkg = read_json(root .. "/package.json")
  local deps = type(pkg.dependencies) == "table" and pkg.dependencies or {}
  local dev = type(pkg.devDependencies) == "table" and pkg.devDependencies or {}
  local range = deps["@angular/core"] or dev["@angular/core"]
  return type(range) == "string" and range:match("%d+%.%d+%.%d+") or ""
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- TypeScript and JavaScript. TypeScript from the samebench environment is the default
        -- (vtsls itself bundles an older one). A trusted project uses its own TypeScript.
        vtsls = {
          cmd = env_cmd("vtsls"),
          settings = {
            typescript = {
              -- Automatic type acquisition would npm install @types packages in the background
              disableAutomaticTypeAcquisition = true,
              tsserver = { maxTsServerMemory = 4096 },
            },
            vtsls = {
              autoUseWorkspaceTsdk = trusted,
              typescript = { globalTsdk = nm .. "/typescript/lib" },
              -- No Angular plugin for tsserver. angularls already answers in .ts files, with
              -- references and rename that include the templates, and the plugin adds
              -- *.ngtypecheck.ts entries to the references. LazyVim's Angular extra names
              -- @angular/language-server as the plugin, which is the server itself and fails
              -- to load. The plugin would be @angular/language-service.
            },
          },
          -- In an Angular workspace angularls renames, also in templates. Two servers with
          -- rename would each ask for the new name.
          on_init = function(client)
            if client.root_dir and vim.fs.root(client.root_dir, { "angular.json", "nx.json" }) then
              client.server_capabilities.renameProvider = false
            end
          end,
        },
        angularls = {
          -- only inside an Angular workspace (lspconfig would also start it for a lone file)
          workspace_required = true,
          cmd = function(dispatchers, config)
            local root = (config and config.root_dir) or vim.fn.getcwd()
            -- First match wins. A trusted project comes first with its own node_modules, so
            -- TypeScript and the Angular language service fit the project. The samebench
            -- environment is the fallback, and the only place looked at otherwise.
            local probe = trusted and (root .. "/node_modules," .. nm) or nm
            return vim.lsp.rpc.start({
              bin .. "ngserver",
              "--stdio",
              "--tsProbeLocations",
              probe,
              "--ngProbeLocations",
              probe,
              "--angularCoreVersion",
              angular_core_version(root),
            }, dispatchers, { cwd = root })
          end,
        },
        -- ESLint always runs the project's own eslint and its JavaScript configuration
        eslint = { enabled = trusted, cmd = env_cmd("vscode-eslint-language-server") },
        html = { cmd = env_cmd("vscode-html-language-server") },
        cssls = { cmd = env_cmd("vscode-css-language-server") },
        jsonls = {
          cmd = env_cmd("vscode-json-language-server"),
          -- A JSON file can name a schema by URL, and the server would download it as soon as
          -- the file opens. In a folder that is not trusted it only reads schemas from disk.
          -- For http and https it then asks the editor, which answers with the reason.
          init_options = {
            provideFormatter = true,
            handledSchemaProtocols = not trusted and { "file" } or nil,
          },
          handlers = not trusted and {
            ["vscode/content"] = function()
              return nil,
                vim.lsp.rpc.rpc_response_error(
                  vim.lsp.protocol.ErrorCodes.InvalidRequest,
                  "samebench downloads no schemas in a folder that is not trusted"
                )
            end,
          } or nil,
        },
        ts_ls = { enabled = false },
        tsserver = { enabled = false },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "angular", "typescript", "tsx", "javascript", "html", "css", "scss" } },
  },
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      -- prettier is the project's own (conform takes it from the project's node_modules/.bin)
      -- and loads the project's configuration and plugins, so it is project code as well.
      -- Without it, formatting falls back to the language servers.
      if not trusted then
        return
      end
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs({ "typescript", "javascript", "html", "htmlangular", "css", "scss", "json" }) do
        opts.formatters_by_ft[ft] = { "prettier" }
      end
    end,
  },
}
