-- Shows, for the .NET tools pinned in envs/dotnet/tools.txt, what the NuGet feed has.
-- Runs with `nvim -l` from `samebench update` and changes nothing.
--
--   nvim -l dotnet-tool-news.lua <tools.txt>     (run it in the home folder)
--
-- The versions come from `dotnet package search`, which asks the feeds of your NuGet
-- configuration with your credentials. The publish dates come from the same feeds, through
-- the registration resource of the NuGet protocol, where a feed answers that without a login.
-- Only the package ids are sent. Exit 0 = shown, 1 = no feed could be asked.

local tools_file = arg[1]
local DAY = 24 * 60 * 60

local function run(cmd)
  local ok, job = pcall(vim.system, cmd, { text = true })
  if not ok then
    return nil
  end
  local r = job:wait(60000)
  return r.code == 0 and r.stdout or nil
end

local function json(text)
  local ok, value = pcall(vim.json.decode, text or "")
  return ok and type(value) == "table" and value or nil
end

local function fetch(url)
  return json(run({ "curl", "--proto", "=https", "--tlsv1.2", "-fsSL", "--compressed", "--max-time", "20", url }))
end

local function parse(v)
  local ok, version = pcall(vim.version.parse, v)
  return ok and version or nil
end

local function newer(a, b) -- is version string a newer than b?
  local va, vb = parse(a), parse(b)
  return va ~= nil and (vb == nil or vim.version.gt(va, vb))
end

-- The publish date of every version of a package, from the feeds that answer: version = "YYYY-MM-DD"
local function publish_dates(id, sources)
  local dates = {}
  for _, source in ipairs(sources) do
    local base
    for _, res in ipairs((fetch(source) or {}).resources or {}) do
      if res["@type"] == "RegistrationsBaseUrl/3.6.0" then
        base = res["@id"]
      end
    end
    if type(base) == "string" and base:match("^https://") then
      local index = fetch(base:gsub("/$", "") .. "/" .. id:lower() .. "/index.json")
      for _, page in ipairs(index and index.items or {}) do
        local leaves = page.items or (fetch(page["@id"]) or {}).items or {}
        for _, leaf in ipairs(leaves) do
          local e = type(leaf.catalogEntry) == "table" and leaf.catalogEntry or {}
          local day = type(e.published) == "string" and e.published:match("^(%d%d%d%d%-%d%d%-%d%d)")
          -- nuget.org gives unlisted versions the year 1900
          if type(e.version) == "string" and day and not day:match("^1900") then
            dates[e.version:lower()] = dates[e.version:lower()] or day
          end
        end
      end
    end
  end
  return dates
end

local function age_days(day)
  local y, m, d = day:match("^(%d+)%-(%d+)%-(%d+)$")
  return math.floor((os.time() - os.time({ year = y, month = m, day = d, hour = 12 })) / DAY)
end

local function with_date(version, dates)
  local day = dates[version:lower()]
  return day and ("%s (%s)"):format(version, day) or version
end

-- Feeds of the NuGet configuration that are switched on ("E <url>")
local sources = {}
for line in (run({ "dotnet", "nuget", "list", "source", "--format", "short" }) or ""):gmatch("[^\n]+") do
  local url = line:match("^E%s+(https://%S+)")
  if url then
    table.insert(sources, url)
  end
end

local asked = false
for line in io.lines(tools_file) do
  local id, pinned = line:match("^([%w][%w._-]*)%s+(%d[%w.+-]*)%s*$")
  if id then
    local prerelease = pinned:find("-", 1, true) ~= nil
    local cmd = { "dotnet", "package", "search", id, "--exact-match", "--format", "json" }
    if prerelease then
      table.insert(cmd, "--prerelease")
    end
    local result = json(run(cmd))
    local dates = publish_dates(id, sources)
    io.write(("   %-26s pinned %s\n"):format(id, with_date(pinned, dates)))
    if not result or type(result.searchResult) ~= "table" then
      io.write(("   %-26s the feed gave no answer\n"):format(""))
    else
      for _, source in ipairs(result.searchResult) do
        local newest, settled
        local failed = type(source.problems) == "table" and #source.problems > 0
        asked = asked or not failed
        for _, pkg in ipairs(type(source.packages) == "table" and source.packages or {}) do
          local v = type(pkg.version) == "string" and pkg.version or ""
          if parse(v) and (prerelease or not v:find("-", 1, true)) then
            if newer(v, newest) then
              newest = v
            end
            local day = dates[v:lower()]
            if day and age_days(day) >= 7 and newer(v, settled) then
              settled = v
            end
          end
        end
        local name = tostring(source.sourceName or "feed"):gsub("[%c]", "")
        if failed then
          io.write(("   %-26s %s could not be asked\n"):format("", name))
        elseif not newest then
          io.write(("   %-26s %s does not have this package\n"):format("", name))
        elseif not newer(newest, pinned) then
          io.write(("   %-26s nothing newer on %s\n"):format("", name))
        else
          local day = dates[newest:lower()]
          local note = ""
          if day and age_days(day) < 7 then
            note = (", only %d days old"):format(age_days(day))
          elseif not day then
            note = ", publish date not available"
          end
          io.write(("   %-26s newest on %s: %s%s\n"):format("", name, with_date(newest, dates), note))
          if settled and settled ~= newest and newer(settled, pinned) then
            io.write(("   %-26s newest that is at least 7 days old: %s\n"):format("", with_date(settled, dates)))
          end
          local a, b = parse(pinned), parse(newest)
          if a and b and a.major ~= b.major then
            io.write(("   %-26s %d to %d is a new major version\n"):format("", a.major, b.major))
          end
        end
      end
    end
  end
end

os.exit(asked and 0 or 1)
