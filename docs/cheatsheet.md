<div align="center">

# Cheat sheet

**Neovim** &nbsp;·&nbsp; **tmux** &nbsp;·&nbsp; **lazygit** &nbsp;·&nbsp; **Notebooks** &nbsp;·&nbsp; **.NET**

<sub><kbd>Space</kbd> is the leader key. Press it, wait a moment, and which-key shows what comes next.<br>
Inside Neovim, <kbd>Space</kbd> <kbd>H</kbd> opens the <a href="quickref.md">short version</a> of this page.</sub>

[← Back to the overview](../README.md)

</div>

<br>

<table>
<tr>
<td width="50%" valign="top">

### Getting around

| Keys | Action |
|---|---|
| <kbd>Space</kbd> <kbd>Space</kbd> | Find a file |
| <kbd>Space</kbd> <kbd>/</kbd> | Search the whole project |
| <kbd>Space</kbd> <kbd>e</kbd> | Toggle the file explorer |
| <kbd>Shift</kbd>+<kbd>h</kbd> · <kbd>Shift</kbd>+<kbd>l</kbd> | Previous · next tab |
| <kbd>Space</kbd> <kbd>b</kbd> <kbd>d</kbd> | Close the tab |
| <kbd>g</kbd> <kbd>d</kbd> · <kbd>g</kbd> <kbd>r</kbd> | Go to definition · references |
| <kbd>K</kbd> | Show documentation, like hovering |
| <kbd>]</kbd> <kbd>d</kbd> · <kbd>[</kbd> <kbd>d</kbd> | Next · previous diagnostic |

</td>
<td width="50%" valign="top">

### Editing

| Keys | Action |
|---|---|
| <kbd>Ctrl</kbd>+<kbd>s</kbd> | Save |
| <kbd>g</kbd> <kbd>c</kbd> <kbd>c</kbd> · <kbd>g</kbd> <kbd>c</kbd> | Comment a line · a selection |
| <kbd>Space</kbd> <kbd>c</kbd> <kbd>r</kbd> | Rename everywhere |
| <kbd>Space</kbd> <kbd>c</kbd> <kbd>a</kbd> | Code action, the quick fix |
| <kbd>Space</kbd> <kbd>c</kbd> <kbd>f</kbd> | Format the file |
| <kbd>Space</kbd> <kbd>u</kbd> <kbd>f</kbd> | Toggle format on save |
| <kbd>Space</kbd> <kbd>x</kbd> <kbd>x</kbd> | List of problems |
| <kbd>Ctrl</kbd>+<kbd>/</kbd> | Terminal inside Neovim |

</td>
</tr>
<tr>
<td width="50%" valign="top">

### Windows and panes

| Keys | Action |
|---|---|
| <kbd>Ctrl</kbd>+<kbd>h</kbd> <kbd>j</kbd> <kbd>k</kbd> <kbd>l</kbd> | Move left, down, up, right, across Neovim and tmux |
| <kbd>Space</kbd> <kbd>\|</kbd> · <kbd>Space</kbd> <kbd>-</kbd> | Split side by side · on top of each other |
| <kbd>Ctrl</kbd>+<kbd>b</kbd> then <kbd>z</kbd> | Zoom the pane, again to restore |
| <kbd>Ctrl</kbd>+<kbd>b</kbd> then <kbd>1</kbd> <kbd>2</kbd> <kbd>3</kbd> | Switch tmux window |
| <kbd>Ctrl</kbd>+<kbd>b</kbd> then <kbd>s</kbd> | Switch between sessions |
| <kbd>Ctrl</kbd>+<kbd>b</kbd> then <kbd>d</kbd> | Leave the session, it keeps running |
| <kbd>Ctrl</kbd>+<kbd>b</kbd> then <kbd>[</kbd> | Scroll and copy, <kbd>q</kbd> ends it |
| <kbd>Ctrl</kbd>+<kbd>b</kbd> then <kbd>Ctrl</kbd>+<kbd>l</kbd> | Clear the pane |

</td>
<td width="50%" valign="top">

### Git

| Keys | Action |
|---|---|
| <kbd>Space</kbd> <kbd>g</kbd> <kbd>g</kbd> | lazygit inside Neovim |
| <kbd>Ctrl</kbd>+<kbd>b</kbd> then <kbd>g</kbd> | lazygit as a tmux popup |
| <kbd>Space</kbd> <kbd>g</kbd> <kbd>h</kbd> <kbd>p</kbd> | Preview the change under the cursor |
| <kbd>Space</kbd> <kbd>g</kbd> <kbd>h</kbd> <kbd>d</kbd> | Side by side diff |

**Inside lazygit**

| Keys | Action |
|---|---|
| <kbd>Space</kbd> | Stage or unstage, <kbd>Enter</kbd> for single lines |
| <kbd>c</kbd> | Commit |
| <kbd>P</kbd> · <kbd>p</kbd> | Push · pull |
| <kbd>s</kbd> | Stash, <kbd>g</kbd> in the stash list brings it back |
| <kbd>b</kbd> | Branches |
| <kbd>?</kbd> · <kbd>q</kbd> | All keys · quit |

</td>
</tr>
</table>

### Notebooks

Start the session with `dev -j`. The keys below work in every notebook.

| Keys | Action | | Keys | Action |
|---|---|---|---|---|
| <kbd>Space</kbd> <kbd>j</kbd> <kbd>k</kbd> | Connect the kernel console | | <kbd>]</kbd> <kbd>j</kbd> · <kbd>[</kbd> <kbd>j</kbd> | Next · previous cell |
| <kbd>Space</kbd> <kbd>j</kbd> <kbd>j</kbd> | Run the cell or selection | | <kbd>Space</kbd> <kbd>j</kbd> <kbd>c</kbd> | New code cell |
| <kbd>Space</kbd> <kbd>j</kbd> <kbd>n</kbd> | Run and move on | | <kbd>Space</kbd> <kbd>j</kbd> <kbd>m</kbd> | New markdown cell |
| <kbd>Space</kbd> <kbd>j</kbd> <kbd>a</kbd> | Run everything up to here | | <kbd>Space</kbd> <kbd>j</kbd> <kbd>d</kbd> | Diff against the last commit |
| <kbd>Space</kbd> <kbd>j</kbd> <kbd>l</kbd> | Run the current line | | `jlab` or <kbd>Ctrl</kbd>+<kbd>b</kbd> then <kbd>o</kbd> | Open JupyterLab |

`:w` saves back into the `.ipynb` and keeps the outputs. Before typing in the browser, use
*File → Reload Notebook from Disk*.

### .NET

These keys exist with the [`dotnet` module](configuration.md#the-dotnet-module) in a folder you trusted. Completion,
go to definition, rename and quick fixes use the same keys as everywhere else.

| Keys | Action | | Keys | Action |
|---|---|---|---|---|
| <kbd>Space</kbd> <kbd>D</kbd> <kbd>b</kbd> | Build | | <kbd>Space</kbd> <kbd>D</kbd> <kbd>t</kbd> | Open the test runner |
| <kbd>Space</kbd> <kbd>D</kbd> <kbd>r</kbd> | Run a project | | <kbd>Space</kbd> <kbd>D</kbd> <kbd>T</kbd> | Run the tests |
| <kbd>Space</kbd> <kbd>D</kbd> <kbd>R</kbd> | Restore packages | | <kbd>Space</kbd> <kbd>D</kbd> <kbd>d</kbd> | Diagnostics of the whole solution |

`:Dotnet` followed by <kbd>Tab</kbd> lists everything else, such as `:Dotnet add`, `:Dotnet new`,
`:Dotnet outdated` and `:Dotnet secrets`.

### Commands

| Command | Action | | Command | Action |
|---|---|---|---|---|
| `dev` | Open the workspace | | `samebench plan` | Show what would change |
| `dev -j` | With Jupyter | | `samebench apply` | Set everything up |
| `dev -l agent` | Agent on the left | | `samebench update` | Monthly update day |
| `dev -s` | List sessions | | `samebench sync` | Take the repository's state |
| `dev -k` | Stop this session | | `samebench check` | Look for vulnerabilities |
| `dev -r` | Rebuild the session | | `samebench doctor` | Check this machine |

<details>
<summary><b>Vim basics</b></summary>

<br>

| Keys | Action |
|---|---|
| <kbd>i</kbd> · <kbd>a</kbd> · <kbd>o</kbd> | Insert before the cursor · after it · on a new line below |
| <kbd>Esc</kbd> | Back to normal mode, where you move and give commands |
| <kbd>v</kbd> · <kbd>V</kbd> | Select characters · whole lines |
| <kbd>y</kbd> · <kbd>d</kbd> · <kbd>p</kbd> | Copy · cut · paste |
| <kbd>u</kbd> · <kbd>Ctrl</kbd>+<kbd>r</kbd> | Undo · redo |
| <kbd>w</kbd> · <kbd>b</kbd> · <kbd>e</kbd> | Next word · previous word · end of word |
| <kbd>g</kbd> <kbd>g</kbd> · <kbd>G</kbd> | Top · bottom of the file |
| <kbd>c</kbd> <kbd>i</kbd> <kbd>w</kbd> | Change the word under the cursor |
| <kbd>.</kbd> | Repeat the last change |
| `:w` · `:q` · `:qa` | Save · close the window · quit Neovim |

Run `:Tutor` once. It takes about thirty minutes and is worth every one of them.

</details>

<details>
<summary><b>Coming from VS Code</b></summary>

<br>

| VS Code | Here |
|---|---|
| <kbd>Ctrl</kbd>+<kbd>P</kbd> | <kbd>Space</kbd> <kbd>Space</kbd> |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>F</kbd> | <kbd>Space</kbd> <kbd>/</kbd> |
| <kbd>Ctrl</kbd>+<kbd>B</kbd> | <kbd>Space</kbd> <kbd>e</kbd> |
| <kbd>F12</kbd> · <kbd>Shift</kbd>+<kbd>F12</kbd> | <kbd>g</kbd> <kbd>d</kbd> · <kbd>g</kbd> <kbd>r</kbd> |
| Hover | <kbd>K</kbd> |
| <kbd>F2</kbd> | <kbd>Space</kbd> <kbd>c</kbd> <kbd>r</kbd> |
| <kbd>Ctrl</kbd>+<kbd>.</kbd> | <kbd>Space</kbd> <kbd>c</kbd> <kbd>a</kbd> |
| <kbd>Ctrl</kbd>+<kbd>/</kbd> | <kbd>g</kbd> <kbd>c</kbd> <kbd>c</kbd> |
| Problems panel | <kbd>Space</kbd> <kbd>x</kbd> <kbd>x</kbd> |
| Integrated terminal | <kbd>Ctrl</kbd>+<kbd>/</kbd> |

</details>
