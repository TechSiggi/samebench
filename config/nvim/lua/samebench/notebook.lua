-- Notebook workflow without plugins
--
-- Open:    analysis.ipynb  →  libexec/nb-convert creates the hidden shadow file
--          .analysis.nb.py (cells marked with "# %%") and Neovim edits that file.
--          Language servers, search etc. work as with normal Python.
-- Save:    the shadow file is written back into analysis.ipynb, existing
--          outputs are kept.
-- Agent:   if someone (e.g. Claude) changes the .ipynb, the shadow file is
--          regenerated automatically (as long as you have no unsaved
--          changes).
-- Run:     cells are sent via tmux to a `jupyter console` attached to the
--          same kernel as the notebook in the browser (libexec/jupyter-attach).
--
-- Git ignores the shadow files through your global ignore list (`samebench apply`),
-- nothing is changed in the repository itself.

local M = {}
local uv = vim.uv or vim.loop
local ns = vim.api.nvim_create_namespace("samebench_notebook")
local WARN, ERROR = vim.log.levels.WARN, vim.log.levels.ERROR

local REPO = vim.env.SAMEBENCH_REPO or vim.fn.fnamemodify(vim.fn.resolve(vim.fn.stdpath("config")), ":h:h")
local CELL = "^# %%%%" -- line starts with "# %%"
local SHELLS = { bash = true, zsh = true, sh = true, fish = true, dash = true, ["-bash"] = true, ["-zsh"] = true }

-- Is a Python/Jupyter console running in the pane? (code is only sent then)
local function is_console(cmd)
  cmd = cmd:lower()
  return cmd:find("python", 1, true) ~= nil or cmd:find("jupyter", 1, true) ~= nil
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Notebook" })
end

local function run(cmd, stdin)
  local ok, obj = pcall(vim.system, cmd, { text = true, stdin = stdin })
  if not ok then
    return false, "", tostring(obj)
  end
  local res = obj:wait()
  return res.code == 0, res.stdout or "", res.stderr or ""
end

-- Python of the Jupyter tool, nil until `dev -j` has installed it
local function tool_python()
  local python = (vim.env.SAMEBENCH_JUPYTER_VENV or "") .. "/bin/python"
  return vim.fn.executable(python) == 1 and python or nil
end

-- convert("to-py", notebook, shadow) or convert("to-ipynb", shadow, notebook).
-- Only the Jupyter tool converts, in isolated mode, never a jupytext from the
-- project's .venv (see libexec/nb-convert).
local function convert(direction, source, target)
  local python = tool_python()
  if not python then
    return false, "The Jupyter tool is missing. Run `dev -j` once to install it."
  end
  local ok, _, err = run({ python, "-I", REPO .. "/libexec/nb-convert", direction, source, target })
  return ok, err
end

local function stamp(path)
  local st = uv.fs_stat(path)
  return st and (st.mtime.sec .. "." .. st.mtime.nsec .. ":" .. st.size) or nil
end

local function shadow_of(nb)
  local dir, name = vim.fn.fnamemodify(nb, ":p:h"), vim.fn.fnamemodify(nb, ":t:r")
  return dir .. "/." .. name .. ".nb.py"
end

local function notebook_of(shadow)
  local dir, tail = vim.fn.fnamemodify(shadow, ":p:h"), vim.fn.fnamemodify(shadow, ":t")
  local name = tail:match("^%.(.+)%.nb%.py$")
  return name and (dir .. "/" .. name .. ".ipynb") or nil
end

------------------------------------------------------------------ Files ----

-- Does another Neovim that is still running have the shadow file open?
local function open_elsewhere(path)
  local base = vim.fn.stdpath("state") .. "/swap/" .. (vim.fn.fnamemodify(path, ":p"):gsub("/", "%%"))
  for _, ext in ipairs({ ".swp", ".swo", ".swn" }) do
    if uv.fs_stat(base .. ext) then
      local info = vim.fn.swapinfo(base .. ext)
      if info.pid and info.pid > 0 and info.pid ~= vim.fn.getpid() and uv.kill(info.pid, 0) == 0 then
        return true
      end
    end
  end
  return false
end

-- Open the shadow file in the current window. If a swap file exists:
-- it belongs to a running Neovim → open read-only,
-- it is orphaned (e.g. after a crash) → open normally.
local function edit_shadow(shadow)
  local id = vim.api.nvim_create_autocmd("SwapExists", {
    callback = function()
      local info = vim.fn.swapinfo(vim.v.swapname)
      local alive = info.pid and info.pid > 0 and uv.kill(info.pid, 0) == 0
      vim.v.swapchoice = alive and "o" or "e"
    end,
  })
  local elsewhere = open_elsewhere(shadow)
  pcall(vim.cmd.edit, vim.fn.fnameescape(shadow))
  vim.api.nvim_del_autocmd(id)
  if elsewhere then
    vim.bo.readonly = true
  end
end

local function open_notebook(ev)
  local nb = vim.fn.fnamemodify(ev.match, ":p")
  local shadow = shadow_of(nb)
  local buf = ev.buf
  local existing = vim.fn.bufnr(shadow)
  if existing > 0 and vim.api.nvim_buf_is_loaded(existing) then
    -- already open: don't regenerate (would put unsaved changes at risk);
    -- check_external detects external changes when entering the buffer
  elseif open_elsewhere(shadow) then
    -- open in another Neovim: do NOT overwrite its file
    notify("This notebook is already open in another Neovim. Read-only here.", WARN)
  elseif not uv.fs_stat(nb) then
    -- new notebook: start with an empty cell
    vim.fn.writefile({ "# %%", "" }, shadow)
  else
    local ok, err = convert("to-py", nb, shadow)
    if not ok then
      -- fallback: show the raw data (JSON) so nothing gets lost
      notify("Could not convert the notebook:\n" .. err, ERROR)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.fn.readfile(nb))
      vim.bo[buf].modified = false
      vim.bo[buf].filetype = "json"
      return
    end
  end
  vim.schedule(function()
    local wins = vim.fn.win_findbuf(buf)
    for _, win in ipairs(wins) do
      vim.api.nvim_win_call(win, function()
        edit_shadow(shadow)
      end)
    end
    local sbuf = vim.fn.bufnr(shadow)
    if sbuf > 0 then
      vim.b[sbuf].samebench_notebook = nb
      vim.b[sbuf].samebench_nb_stamp = stamp(nb)
    end
    if vim.api.nvim_buf_is_valid(buf) and #vim.fn.win_findbuf(buf) == 0 then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end)
end

local function save_notebook(ev)
  local shadow = vim.fn.fnamemodify(ev.match, ":p")
  local nb = vim.b[ev.buf].samebench_notebook or notebook_of(shadow)
  if not nb then
    return
  end
  local ok, err = convert("to-ipynb", shadow, nb)
  if ok then
    vim.b[ev.buf].samebench_notebook = nb
    vim.b[ev.buf].samebench_nb_stamp = stamp(nb)
  else
    notify("Notebook NOT saved:\n" .. err, ERROR)
  end
end

-- Was the .ipynb changed externally (agent, git pull, browser)?
local function check_external(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local nb = vim.b[buf].samebench_notebook
  if not nb then
    return
  end
  local now = stamp(nb)
  if not now or now == vim.b[buf].samebench_nb_stamp then
    return
  end
  if vim.bo[buf].modified then
    if vim.b[buf].samebench_nb_warned ~= now then
      vim.b[buf].samebench_nb_warned = now
      notify(
        "The notebook was changed externally, but you have unsaved changes.\n"
          .. "Saving (:w) overwrites the external changes, :e! discards yours.",
        WARN
      )
    end
    return
  end
  local shadow = vim.api.nvim_buf_get_name(buf)
  local ok, err = convert("to-py", nb, shadow)
  if not ok then
    notify("Reload failed:\n" .. err, ERROR)
    return
  end
  vim.b[buf].samebench_nb_stamp = now
  vim.api.nvim_buf_call(buf, function()
    local view = vim.fn.winsaveview()
    vim.cmd("silent! edit!")
    vim.fn.winrestview(view)
  end)
  notify("Notebook changed externally, reloaded.")
end

------------------------------------------------------------------- Cells ----

-- Line range (1-based, inclusive) of the cell around `lnum`
local function cell_bounds(buf, lnum)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local s, e = 1, #lines
  for i = lnum, 1, -1 do
    if lines[i]:match(CELL) then
      s = i
      break
    end
  end
  for i = lnum + 1, #lines do
    if lines[i]:match(CELL) then
      e = i - 1
      break
    end
  end
  return s, e, lines
end

local function is_markdown(header)
  return header and header:match(CELL) and header:match("%[markdown%]") ~= nil
end

local function cell_code(buf, lnum)
  local s, e, lines = cell_bounds(buf, lnum)
  local header = lines[s]
  if is_markdown(header) then
    return nil, s, e
  end
  local first = header and header:match(CELL) and s + 1 or s
  local code = vim.list_slice(lines, first, e)
  return code, s, e
end

-- Remove trailing blank lines; nil if only comments/blank lines are left
local function clean(code)
  while #code > 0 and code[#code]:match("^%s*$") do
    table.remove(code)
  end
  for _, l in ipairs(code) do
    if not l:match("^%s*$") and not l:match("^%s*#") then
      return code
    end
  end
end

------------------------------------------------------------------- tmux ----

local function tmux(args, stdin)
  local cmd = { "tmux" }
  vim.list_extend(cmd, args)
  return run(cmd, stdin)
end

local function pane_alive(id)
  local ok, out = tmux({ "list-panes", "-a", "-F", "#{pane_id}" })
  return ok and (out .. "\n"):find(id .. "\n", 1, true) ~= nil
end

-- Find the pane for the kernel console (layout "code": terminal bottom left)
-- or create one (layout "agent")
local function repl_pane(create)
  if not vim.env.TMUX or not vim.env.TMUX_PANE then
    notify("Neovim is not running in tmux. Please start it with `dev`.", WARN)
    return nil
  end
  local _, out = tmux({ "show-options", "-wqv", "-t", vim.env.TMUX_PANE, "@samebench_repl" })
  local pane = vim.trim(out)
  if pane ~= "" and pane_alive(pane) then
    return pane
  end
  if not create then
    return nil
  end
  local ok, id = tmux({
    "split-window", "-d", "-h", "-l", "40%", "-t", vim.env.TMUX_PANE,
    "-c", vim.fn.getcwd(), "-P", "-F", "#{pane_id}",
  })
  if not ok then
    notify("Could not open a tmux pane.", ERROR)
    return nil
  end
  pane = vim.trim(id)
  tmux({ "set-option", "-w", "-t", vim.env.TMUX_PANE, "@samebench_repl", pane })
  tmux({ "select-pane", "-t", pane, "-T", "kernel" })
  return pane
end

local function pane_command(pane)
  local _, out = tmux({ "display-message", "-p", "-t", pane, "#{pane_current_command}" })
  return vim.trim(out)
end

-- Start the kernel console (connects to the kernel of the notebook in the browser)
function M.connect()
  local pane = repl_pane(true)
  if not pane then
    return
  end
  local current = pane_command(pane)
  if not SHELLS[current] then
    notify("The kernel pane is already running \"" .. current .. "\". To restart, press Ctrl+d there and then <Space>jk again.", WARN)
    return
  end
  local python = tool_python()
  if not python then
    notify("Jupyter tool is missing. Restart the session with `dev -r -j`.", ERROR)
    return
  end
  local target = vim.b.samebench_notebook or vim.api.nvim_buf_get_name(0)
  local cmd = table.concat({
    vim.fn.shellescape(python),
    "-I",
    vim.fn.shellescape(REPO .. "/libexec/jupyter-attach"),
    vim.fn.shellescape(target),
  }, " ")
  tmux({ "send-keys", "-t", pane, "-l", cmd })
  tmux({ "send-keys", "-t", pane, "Enter" })
end

local function send(code)
  local pane = repl_pane(false)
  if not pane then
    notify("No kernel console. Press <Space>jk first.", WARN)
    return false
  end
  -- Safety net: only send code to a running Python/Jupyter console,
  -- never type into a shell or another program
  local current = pane_command(pane)
  if not is_console(current) then
    notify("No console is running in the kernel pane (\"" .. current .. "\"). Press <Space>jk first.", WARN)
    return false
  end
  local text = table.concat(code, "\n")
  tmux({ "load-buffer", "-b", "samebench_cell", "-" }, text)
  tmux({ "paste-buffer", "-p", "-d", "-b", "samebench_cell", "-t", pane })
  tmux({ "send-keys", "-t", pane, "Enter" })
  -- if the code ends indented (e.g. a for loop), IPython needs a second Enter
  if code[#code]:match("^%s") then
    tmux({ "send-keys", "-t", pane, "Enter" })
  end
  return true
end

-------------------------------------------------------------- Cell bars ----
-- "# %%" lines are shown as a bar "Cell 3 · Code ──── ✓ 12:03",
-- markdown cells in violet italics. Purely visual: the file stays unchanged.

local ns_bar = vim.api.nvim_create_namespace("samebench_notebook_bars")
local done = {} -- [buf][extmark-id] = time of the last run

local function decorate(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns_bar, 0, -1)
  local win = vim.fn.win_findbuf(buf)[1]
  if not win then
    return
  end
  local info = vim.fn.getwininfo(win)[1]
  local width = info.width - info.textoff
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local n, md_start = 0, nil
  local function close_markdown(last)
    if md_start and last >= md_start then
      vim.api.nvim_buf_set_extmark(buf, ns_bar, md_start - 1, 0, {
        end_row = last, end_col = 0, hl_group = "SamebenchCellMarkdown", priority = 150,
      })
    end
    md_start = nil
  end
  for i, line in ipairs(lines) do
    if line:match(CELL) then
      close_markdown(i - 1)
      n = n + 1
      local is_md = line:match("%[markdown%]") ~= nil
      local label = vim.trim(line:gsub("^# %%%%", ""):gsub("%[markdown%]", ""))
      local title = (" Cell %d · %s%s "):format(n, is_md and "Markdown" or "Code", label ~= "" and (" · " .. label) or "")
      local stamp_txt = ""
      for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns, { i - 1, 0 }, { i - 1, -1 }, {})) do
        local t = done[buf] and done[buf][m[1]]
        if t then
          stamp_txt = " ✓ " .. t .. " "
        end
      end
      local rule = math.max(1, width - vim.fn.strdisplaywidth(title) - vim.fn.strdisplaywidth(stamp_txt))
      vim.api.nvim_buf_set_extmark(buf, ns_bar, i - 1, 0, {
        virt_text = { { title, "SamebenchCellTitle" }, { string.rep("─", rule), "SamebenchCellRule" }, { stamp_txt, "SamebenchCellDone" } },
        virt_text_pos = "overlay",
        line_hl_group = "SamebenchCellBar",
        priority = 200,
      })
      if is_md then
        md_start = i + 1
      end
    end
  end
  close_markdown(#lines)
end

-- Remember the run (an invisible mark moves along when lines shift)
local function mark(buf, line)
  for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns, { line - 1, 0 }, { line - 1, -1 }, {})) do
    vim.api.nvim_buf_del_extmark(buf, ns, m[1])
  end
  local id = vim.api.nvim_buf_set_extmark(buf, ns, line - 1, 0, {})
  done[buf] = done[buf] or {}
  done[buf][id] = os.date("%H:%M")
  decorate(buf)
end

--------------------------------------------------------------- Commands ----

function M.run_cell(opts)
  opts = opts or {}
  local buf = vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local code, s, e = cell_code(buf, lnum)
  code = code and clean(code)
  if code and send(code) then
    mark(buf, s)
  elseif not code then
    notify("Empty or markdown cell, nothing to run.")
  end
  if opts.next then
    local total = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_win_set_cursor(0, { math.min(e + 2, total), 0 })
  end
end

function M.run_above()
  local buf = vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local _, last_end = cell_bounds(buf, lnum)
  local line = 1
  while line <= last_end do
    local code, s, e = cell_code(buf, line)
    code = code and clean(code)
    if code then
      if not send(code) then
        return
      end
      mark(buf, s)
    end
    line = e + 1
  end
end

function M.run_selection()
  local s, e = vim.fn.line("v"), vim.fn.line(".")
  if s > e then
    s, e = e, s
  end
  local code = clean(vim.api.nvim_buf_get_lines(0, s - 1, e, false))
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  if code then
    send(code)
  end
end

function M.run_line()
  local line = vim.api.nvim_get_current_line()
  if not line:match("^%s*$") then
    send({ vim.trim(line) })
  end
end

function M.jump(dir)
  local buf = vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local i = lnum + dir
  while i >= 1 and i <= #lines do
    if lines[i]:match(CELL) then
      vim.api.nvim_win_set_cursor(0, { math.min(i + 1, #lines), 0 })
      return
    end
    i = i + dir
  end
end

function M.new_cell(kind)
  local buf = vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local _, e = cell_bounds(buf, lnum)
  local header = kind == "markdown" and "# %% [markdown]" or "# %%"
  local body = kind == "markdown" and "# " or ""
  vim.api.nvim_buf_set_lines(buf, e, e, false, { "", header, body })
  vim.api.nvim_win_set_cursor(0, { e + 3, #body })
  vim.cmd.startinsert({ bang = true })
end

-- Compare the notebook side by side with the last commit (code only, no outputs)
function M.diff_head()
  local nb = vim.b.samebench_notebook
  if not nb then
    notify("No notebook in this window.", WARN)
    return
  end
  local dir = vim.fn.fnamemodify(nb, ":h")
  local ok, out, err = run({ "git", "-C", dir, "show", "HEAD:./" .. vim.fn.fnamemodify(nb, ":t") })
  if not ok then
    notify("No version in the last commit:\n" .. err, WARN)
    return
  end
  local tmp = vim.fn.tempname()
  vim.fn.writefile(vim.split(out, "\n", { plain = true }), tmp .. ".ipynb", "b")
  local ok2, err2 = convert("to-py", tmp .. ".ipynb", tmp .. ".py")
  if not ok2 then
    notify(err2, ERROR)
    return
  end
  local lines = vim.fn.readfile(tmp .. ".py")
  vim.cmd("diffthis")
  vim.cmd("leftabove vnew")
  local b = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(b, 0, -1, false, lines)
  vim.bo[b].buftype, vim.bo[b].bufhidden, vim.bo[b].modifiable = "nofile", "wipe", false
  vim.bo[b].filetype = "python"
  pcall(vim.api.nvim_buf_set_name, b, "HEAD: " .. vim.fn.fnamemodify(nb, ":t"))
  vim.cmd("diffthis")
  vim.keymap.set("n", "q", "<cmd>diffoff! | bwipeout<cr>", { buffer = b, desc = "Close diff" })
  vim.cmd("wincmd p")
end

------------------------------------------------------------------- Setup ----

local function buffer_keymaps(buf)
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
  end
  map("n", "<leader>jk", M.connect, "Connect kernel (start console)")
  map("n", "<leader>jj", M.run_cell, "Run cell")
  map("n", "<leader>jn", function() M.run_cell({ next = true }) end, "Run cell and move on")
  map("n", "<leader>ja", M.run_above, "Run all cells up to here")
  map("n", "<leader>jl", M.run_line, "Run line")
  map("x", "<leader>jj", M.run_selection, "Run selection")
  map("n", "<leader>jc", function() M.new_cell("code") end, "New code cell below")
  map("n", "<leader>jm", function() M.new_cell("markdown") end, "New markdown cell below")
  map("n", "<leader>jd", M.diff_head, "Diff against last commit")
  map("n", "]j", function() M.jump(1) end, "Next cell")
  map("n", "[j", function() M.jump(-1) end, "Previous cell")
end

function M.setup()
  local group = vim.api.nvim_create_augroup("samebench_notebook", { clear = true })

  vim.api.nvim_create_autocmd("BufReadCmd", {
    group = group,
    pattern = "*.ipynb",
    callback = open_notebook,
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*.nb.py",
    callback = save_notebook,
  })

  vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "CursorHold" }, {
    group = group,
    pattern = "*.nb.py",
    callback = function(ev)
      check_external(ev.buf)
    end,
  })

  -- Adjust the bar width to the new window size
  vim.api.nvim_create_autocmd("WinResized", {
    group = group,
    callback = function()
      for _, win in ipairs(vim.v.event.windows or {}) do
        local buf = vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win)
        if buf and vim.bo[buf].filetype == "python" then
          decorate(buf)
        end
      end
    end,
  })

  -- Keymaps in Python files and notebooks
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "python",
    callback = function(ev)
      buffer_keymaps(ev.buf)
      -- Keep the cell bars up to date. FileType fires again on every reload of the buffer,
      -- so the autocommand of the last time goes first.
      vim.api.nvim_clear_autocmds({ group = group, buffer = ev.buf })
      vim.api.nvim_create_autocmd({ "BufWinEnter", "TextChanged", "TextChangedI", "InsertLeave" }, {
        group = group,
        buffer = ev.buf,
        callback = function()
          vim.schedule(function()
            decorate(ev.buf)
          end)
        end,
      })
      vim.schedule(function()
        decorate(ev.buf)
      end)
      local name = vim.api.nvim_buf_get_name(ev.buf)
      if name:match("%.nb%.py$") and not vim.b[ev.buf].samebench_notebook then
        vim.b[ev.buf].samebench_notebook = notebook_of(name)
        vim.b[ev.buf].samebench_nb_stamp = vim.b[ev.buf].samebench_notebook and stamp(vim.b[ev.buf].samebench_notebook)
      end
    end,
  })

  -- Clean up: delete shadow files on exit (only if everything is saved)
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local nb = vim.b[buf].samebench_notebook
        if nb and vim.api.nvim_buf_is_loaded(buf) and not vim.bo[buf].modified then
          os.remove(vim.api.nvim_buf_get_name(buf))
        end
      end
    end,
  })
end

return M
