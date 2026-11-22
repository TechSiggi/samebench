-- May the editor tools of this Neovim load code from the project (see bin/dev, "Trust")?
--
-- `dev` puts two values into the environment of a session:
--   SAMEBENCH_TRUSTED      "1" when you trusted the folder, "0" otherwise
--   SAMEBENCH_TRUSTED_DIR  the trusted folder, a line from ~/.config/samebench/trusted
-- The answer is yes when the first is "1" and Neovim was started in that folder or below it.
-- A shell of a trusted session that moves to another folder and starts Neovim there gets a
-- no. With TRUST="all" there is no folder (env.sh sets SAMEBENCH_TRUSTED=1 for every shell),
-- and every folder counts.
--
-- The folder Neovim was started in decides, once. A file from somewhere else that you open
-- in a trusted Neovim is handled like the files of the trusted folder.

local M = {}

local function decide()
  if vim.env.SAMEBENCH_TRUSTED ~= "1" then
    return false
  end
  local dir = vim.env.SAMEBENCH_TRUSTED_DIR
  if dir == nil or dir == "" then
    return true
  end
  if dir:sub(1, 1) ~= "/" then
    return false
  end
  local cwd = vim.uv.cwd()
  cwd = cwd and vim.uv.fs_realpath(cwd) -- the physical folder, as dev stores it
  if not cwd then
    return false
  end
  dir = dir:gsub("/+$", "") -- "/" becomes "", and then every absolute folder is below it
  return cwd == dir or cwd:sub(1, #dir + 1) == dir .. "/"
end

local answer

--- true when project code may run in this Neovim. Decided on the first call and kept.
function M.trusted()
  if answer == nil then
    answer = decide()
  end
  return answer
end

--- The sentence both modules add to their note: what to do when `dev` does not ask.
M.hint = "dev asks about it when it builds the session (dev -r for a running one).\n"
  .. "If it does not ask, add the folder as a line to ~/.config/samebench/trusted."

return M
