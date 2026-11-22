-- Security check for samebench. Runs with `nvim -l` (Neovim is there anyway) and
-- only needs curl, no further dependencies.
--
--   nvim -l samebench-check.lua <repo> <jupyter-venv> <output> [project folder] [web folder]
--
-- Asks OSV.dev (an open vulnerability database that includes the GitHub
-- security advisories and PyPI) about the INSTALLED versions of
--   * the tools in mise.lock (where OSV has a matching package)
--   * the Jupyter tool (the packages installed in its environment)
--   * the web language servers (the npm packages installed in their folder, a note only)
--   * optionally a project's uv.lock (a note only, never changed)
-- Only package names and versions are sent, and from a project only the
-- packages that come from PyPI. The project's own name and packages from
-- other indexes stay on the machine.
--
-- Output: one line per finding, fields separated by "|":
--   severity|kind|ecosystem|package|version|id|fixed-in|summary|tool
-- kind = tool | jupyter | web | project; tool = mise name (only for kind=tool)
-- Exit 0 = checked (file written), 2 = no complete answer from OSV.dev.

local repo, venv, out_file, project, web = arg[1], arg[2], arg[3], arg[4], arg[5]
local API = "https://api.osv.dev/v1"

-- mise tool to OSV package (Neovim and tmux have no matching package there).
-- OSV has no ecosystem for Node.js itself. The Bitnami one lists the advisories of the
-- Node.js project by Node version, with the version that fixes each of them.
local TOOL_MAP = {
  ["node"] = { "Bitnami", "node" },
  ["aqua:astral-sh/uv"] = { "PyPI", "uv" },
  ["aqua:astral-sh/ruff"] = { "PyPI", "ruff" },
  ["aqua:astral-sh/ty"] = { "PyPI", "ty" },
  ["aqua:jesseduffield/lazygit"] = { "Go", "github.com/jesseduffield/lazygit" },
  ["aqua:BurntSushi/ripgrep"] = { "crates.io", "ripgrep" },
  ["aqua:sharkdp/fd"] = { "crates.io", "fd-find" },
  ["aqua:tree-sitter/tree-sitter"] = { "crates.io", "tree-sitter-cli" },
}

local function read(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local s = f:read("*a")
  f:close()
  return s
end

local function norm(name) -- normalise PyPI names
  return (name:lower():gsub("[-_.]+", "-"))
end

-- Start a request to OSV.dev (POST when a body is given), answer(job) waits for the decoded reply
local function request(path, body)
  local cmd = { "curl", "-sS", "--max-time", "8", "--proto", "=https", API .. path }
  if body then
    vim.list_extend(cmd, { "-H", "Content-Type: application/json", "--data-binary", "@-" })
  end
  return vim.system(cmd, { text = true, stdin = body })
end

-- An incomplete answer ends the check (exit 2), so a finding is never dropped silently
local function answer(job)
  local res = job:wait()
  local ok, data = pcall(vim.json.decode, res.code == 0 and res.stdout or "")
  if not ok or type(data) ~= "table" then
    os.exit(2)
  end
  return data
end

-- Compare versions: numbers numerically, everything else as text
local function cmp(a, b)
  local pa, pb = {}, {}
  for p in tostring(a):gsub("^v", ""):gmatch("[%w]+") do
    table.insert(pa, p)
  end
  for p in tostring(b):gsub("^v", ""):gmatch("[%w]+") do
    table.insert(pb, p)
  end
  for i = 1, math.max(#pa, #pb) do
    local x, y = pa[i] or "0", pb[i] or "0"
    local nx, ny = tonumber(x), tonumber(y)
    if nx and ny then
      if nx ~= ny then
        return nx < ny and -1 or 1
      end
    elseif x ~= y then
      return x < y and -1 or 1
    end
  end
  return 0
end

---------------------------------------------------------- Inventory ----
local items = {} -- { kind, eco, name, version, tool }

-- Tools: versions from mise.lock
local lock = read(repo .. "/config/mise-global/mise.lock") or ""
local current
for line in lock:gmatch("[^\n]+") do
  -- [[tools."aqua:owner/name"]], or without quotes for the core backend: [[tools.node]]
  local t = line:match("^%[%[tools%.(.-)%]%]$")
  if t then
    current = t:gsub('"', "")
  elseif current and line:match("^version = ") then
    local v = line:match('"([^"]+)"')
    local m = TOOL_MAP[current]
    if m and v then
      table.insert(items, { "tool", m[1], m[2], v, current })
    end
    current = nil
  end
end

-- Jupyter tool: the packages actually installed
if venv and venv ~= "" then
  for _, d in ipairs(vim.fn.glob(venv .. "/lib/python*/site-packages/*.dist-info", false, true)) do
    local n, v = vim.fn.fnamemodify(d, ":t"):match("^(.+)%-([^%-]+)%.dist%-info$")
    if n then
      table.insert(items, { "jupyter", "PyPI", norm(n), v, "" })
    end
  end
end

-- Web language servers: the npm packages actually installed (npm records them in
-- node_modules/.package-lock.json), every name and version once
if web and web ~= "" then
  local ok, tree = pcall(vim.json.decode, read(web .. "/node_modules/.package-lock.json") or "")
  local seen = {}
  for path, pkg in pairs(ok and type(tree) == "table" and type(tree.packages) == "table" and tree.packages or {}) do
    local n = path:match("^.*node_modules/(.+)$")
    local v = type(pkg) == "table" and not pkg.link and pkg.version
    if n and type(v) == "string" and not seen[n .. "@" .. v] then
      seen[n .. "@" .. v] = true
      table.insert(items, { "web", "npm", n, v, "" })
    end
  end
end

-- Project: uv.lock (notes only), packages from PyPI and nothing else
if project and project ~= "" then
  local name, version
  for line in (read(project .. "/uv.lock") or ""):gmatch("[^\n]+") do
    if line == "[[package]]" then
      name, version = nil, nil
    elseif line:match("^name = ") then
      name = name or line:match('"([^"]+)"')
    elseif line:match("^version = ") then
      version = version or line:match('"([^"]+)"')
    elseif name and version and line == 'source = { registry = "https://pypi.org/simple" }' then
      table.insert(items, { "project", "PyPI", norm(name), version, "" })
    end
  end
end

------------------------------------------------------------ Queries ----
local queries = {}
for _, it in ipairs(items) do
  table.insert(queries, { package = { ecosystem = it[2], name = it[3] }, version = it[4] })
end
local found = {} -- [index] = { ids }
for start = 1, #queries, 500 do
  local chunk = vim.list_slice(queries, start, start + 499)
  local res = answer(request("/querybatch", vim.json.encode({ queries = chunk })))
  if not res.results then
    os.exit(2)
  end
  for i, r in ipairs(res.results) do
    if r.vulns and #r.vulns > 0 then
      local ids = {}
      for _, v in ipairs(r.vulns) do
        table.insert(ids, v.id)
      end
      found[start + i - 1] = ids
    end
  end
end

-- Fetch the details of every finding in parallel
local jobs, details = {}, {}
for _, ids in pairs(found) do
  for _, id in ipairs(ids) do
    jobs[id] = jobs[id] or request("/vulns/" .. id)
  end
end
for id, job in pairs(jobs) do
  details[id] = answer(job)
end

-- Text from OSV.dev ends up in a "|" separated line and on your terminal
local function field(text)
  return (tostring(text or ""):gsub("[|%c]", " "))
end

local lines = {}
for idx, ids in pairs(found) do
  local it = items[idx]
  local ghsa_seen = {}
  for _, id in ipairs(ids) do
    if id:match("^GHSA") then
      ghsa_seen[id] = true
    end
  end
  for _, id in ipairs(ids) do
    local v = details[id]
    -- Show duplicates (PYSEC/GO/RUSTSEC with a GHSA alias) only once
    local dup = false
    if not id:match("^GHSA") then
      for _, a in ipairs(v.aliases or {}) do
        if ghsa_seen[a] then
          dup = true
        end
      end
    end
    if not dup then
      -- GitHub writes HIGH and MODERATE, Bitnami writes High and Medium
      local sev = tostring((v.database_specific and v.database_specific.severity) or "UNKNOWN"):upper()
      sev = sev == "MEDIUM" and "MODERATE" or sev
      local fixed
      for _, a in ipairs(v.affected or {}) do
        local pn = a.package and a.package.name or ""
        if (it[2] == "PyPI" and norm(pn) == it[3]) or pn == it[3] then
          for _, r in ipairs(a.ranges or {}) do
            for _, e in ipairs(r.events or {}) do
              if e.fixed and cmp(e.fixed, it[4]) > 0 and (not fixed or cmp(e.fixed, fixed) < 0) then
                fixed = e.fixed:gsub("^v", "")
              end
            end
          end
        end
      end
      local summary = v.summary or (v.details or ""):sub(1, 90)
      table.insert(lines, table.concat(vim.tbl_map(field, { sev, it[1], it[2], it[3], it[4], id, fixed or "", summary, it[5] }), "|"))
    end
  end
end

local order = { CRITICAL = 1, HIGH = 2, MODERATE = 3, LOW = 4, UNKNOWN = 5 }
table.sort(lines, function(a, b)
  local sa, sb = a:match("^[^|]+"), b:match("^[^|]+")
  if order[sa] ~= order[sb] then
    return (order[sa] or 9) < (order[sb] or 9)
  end
  return a < b
end)

local tmp = out_file .. ".tmp"
local f = assert(io.open(tmp, "w"))
for _, l in ipairs(lines) do
  f:write(l, "\n")
end
f:close()
os.rename(tmp, out_file)
os.exit(0)
