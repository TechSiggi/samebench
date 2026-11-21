-- Plugin cooldown for `samebench update`. Runs inside the configured Neovim right
-- after `Lazy! check` has fetched every plugin:
--
--   nvim --headless "+Lazy! check" "+luafile lock-plugins.lua" +qa
--
-- Tools and Python packages only update to versions that are at least 7 days
-- old, because hijacked releases are usually found within days. This script
-- holds the Neovim plugins to the same rule. It only rewrites lazy-lock.json,
-- a following `Lazy! restore` checks the plugins out. For every plugin in the
-- lockfile it picks
--   * a plugin on a branch: the newest commit on origin/<branch> (first parent
--     line) that is at least DAYS old
--   * a plugin pinned to a version, tag or commit: the commit lazy.nvim itself
--     would choose, but only once that commit is at least DAYS old
-- and never moves a plugin backwards, with one exception. A plugin whose locked
-- commit is itself younger than DAYS did not get there through this rule: a new
-- LazyVim version brought it along and lazy.nvim installed its newest commit,
-- or the lockfile was written some other way. Such a plugin does move back, to
-- the commit chosen above. When nothing on it is old enough yet it stays where
-- it is and the script says so. Plugins that are not installed keep their
-- entry. Age means the committer date, which the author sets, so it is a
-- weaker signal than the release date a package registry records.
-- Any error ends Neovim with exit code 1.

local DAYS = 7 -- same as minimum_release_age in config/mise-global/settings.toml

local Config = require("lazy.core.config")
local Git = require("lazy.manage.git")
local Plugin = require("lazy.core.plugin")

local cutoff = os.time() - DAYS * 24 * 60 * 60

local function git(dir, ...)
  local res = vim.system({ "git", "-C", dir, ... }, { text = true }):wait()
  return res.code == 0, vim.trim(res.stdout or ""), vim.trim(res.stderr or "")
end

local function must(dir, ...)
  local ok, out, err = git(dir, ...)
  if not ok or out == "" then
    error(("git %s in %s failed: %s"):format(table.concat({ ... }, " "), dir, err), 0)
  end
  return out
end

local function commit_time(dir, commit)
  return tonumber(must(dir, "log", "-1", "--format=%ct", commit))
end

-- Is the locked commit itself younger than the rule allows? A commit that is
-- not in the checkout counts as old enough, the rule above then decides alone.
local function too_young(dir, commit)
  local ok, out = git(dir, "log", "-1", "--format=%ct", commit)
  local time = ok and tonumber(out) or nil
  return time ~= nil and time > cutoff
end

-- The commit this plugin should be locked to, or nil to keep the current one.
-- The second value is true when the current one is younger than DAYS.
local function choose(plugin, entry)
  local dir = plugin.dir
  local target = Git.get_target(plugin)
  local chosen
  if plugin.pin then
    return nil, false
  end
  local young = too_young(dir, entry.commit)
  if target.tag or plugin.commit then -- pinned by the spec
    chosen = must(dir, "rev-parse", "--verify", (target.commit or target.tag) .. "^{commit}")
    if commit_time(dir, chosen) > cutoff then
      return nil, young
    end
  else
    local tip = must(dir, "rev-parse", "--verify", "refs/remotes/origin/" .. entry.branch)
    local ok, out, err = git(dir, "rev-list", "-1", "--first-parent", "--before=@" .. cutoff, tip, "--")
    if not ok then
      error(("git rev-list in %s failed: %s"):format(dir, err), 0)
    elseif out == "" then
      return nil, young -- every commit on the branch is younger
    end
    chosen = out
  end
  if chosen == entry.commit then
    return nil, young
  end
  if not young and git(dir, "merge-base", "--is-ancestor", chosen, entry.commit) then
    return nil, false -- never backwards from a commit that is old enough
  end
  return chosen, young
end

local function main()
  local file = Config.options.lockfile
  local f = assert(io.open(file, "r"))
  local lock = vim.json.decode(f:read("*a"))
  f:close()

  local names = vim.tbl_keys(lock)
  table.sort(names)
  local moved = 0
  for _, name in ipairs(names) do
    local entry, plugin = lock[name], Config.plugins[name]
    if plugin and not plugin._.is_local and vim.fn.isdirectory(plugin.dir) == 1 then
      if Plugin.has_errors(plugin) then
        error(name .. ": `Lazy! check` reported errors, see :Lazy", 0)
      end
      if not Git.info(plugin.dir) then
        error(name .. ": " .. plugin.dir .. " is not a git checkout", 0)
      end
      local new, young = choose(plugin, entry)
      if new then
        local date = must(plugin.dir, "log", "-1", "--format=%cs", new)
        local why = young and (", back from a commit younger than %d days"):format(DAYS) or ""
        io.stdout:write(("  %-28s %s -> %s  (%s%s)\n"):format(name, entry.commit:sub(1, 7), new:sub(1, 7), date, why))
        entry.commit = new
        moved = moved + 1
      elseif young then
        local date = must(plugin.dir, "log", "-1", "--format=%cs", entry.commit)
        io.stdout:write(
          ("  %-28s stays at %s  (%s, nothing on it is %d days old yet)\n"):format(name, entry.commit:sub(1, 7), date, DAYS)
        )
      end
    end
  end
  io.stdout:write(("%d of %d plugins moved, only to commits at least %d days old\n"):format(moved, #names, DAYS))
  if moved == 0 then
    return
  end

  -- Same layout as lazy.nvim's own writer (lazy.manage.lock, M.update), which
  -- cannot be reused because it reads the commits from the checkouts
  local out = {}
  for _, name in ipairs(names) do
    local e = lock[name]
    out[#out + 1] = ([[  %q: { "branch": %q, "commit": %q }]]):format(name, e.branch, e.commit)
  end
  local tmp = file .. ".tmp"
  f = assert(io.open(tmp, "wb"))
  f:write("{\n", table.concat(out, ",\n"), "\n}\n")
  f:close()
  assert(os.rename(tmp, file))
end

local ok, err = pcall(main)
if not ok then
  io.stderr:write("lock-plugins: " .. tostring(err) .. "\n")
  vim.cmd("cquit 1")
end
