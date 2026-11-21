# Configuration

[← Back to the overview](../README.md)

Settings live in three places. A profile describes a kind of machine, `local.sh` holds what concerns one machine
only, and the files under [`config/`](../config) define how the tools look and behave everywhere.

## Profiles

A profile is a small shell file in [`profiles/`](../profiles). You choose it once with `samebench apply <profile>`, and
every later `samebench` command remembers it.

```bash
samebench apply mac      # or: samebench apply linux
```

Every setting has a built-in default, and a profile only lists what differs from it. Both profiles that ship
with the repository set the same three, `MODULES="core python"`, `AGENT_CMD="claude"` and `ICONS="nerd"`.

| Setting | Default | Values | Meaning |
|---|---|---|---|
| `MODULES` | `"core"` | names from `modules/` | Which modules are installed |
| `LAYOUT` | `code` | `code` · `agent` | The layout `dev` opens without `-l` |
| `AGENT_CMD` | empty | `claude`, `copilot`, … | The coding agent started in the layout. Without one, that pane is a plain shell |
| `UV_PYTHON_DOWNLOADS` | `manual` | `manual` · `automatic` | `manual` means uv only installs Python after you confirm |
| `JUPYTER` | `ondemand` | `ondemand` · `yes` · `no` | Install the Jupyter tool on the first `dev -j`, right away, or never |
| `ICONS` | `unicode` | `nerd` · `unicode` | Real icons and round pills, or plain characters that work everywhere |
| `ACTIVATE` | `global` | `global` · `dev` | Tools from mise in every shell, or only inside `dev` sessions |
| `CHECK` | `daily` | `daily` · `off` | The daily security and repository check when `dev` starts |
| `UPDATER` | `no` | `yes` · `no` | Whether this machine maintains the lockfiles, usually set in `local.sh` |

After changing a profile, run `samebench apply` again. `samebench doctor` shows the settings that are in effect.

## Settings for one machine only

`~/.config/samebench/local.sh` is read after the profile and is not part of the repository. It is the right place for
anything that only concerns one machine.

```bash
# ~/.config/samebench/local.sh
UPDATER="yes"      # this machine maintains the lockfiles
ACTIVATE="dev"     # tools from mise only inside dev sessions
JUPYTER="no"       # never install Jupyter here
```

For tmux, `~/.config/tmux/local.conf` works the same way.

## Modules

A module groups tools that belong together. `core` brings Neovim, tmux, lazygit, ripgrep, fd and tree-sitter.
`python` adds uv, ruff and ty, plus the Python settings for Neovim.

To add a module, for example `web` for Angular, create `modules/web/tools.toml` with the tools mise should install.
Neovim settings for it go into `config/nvim/lua/modules/web.lua`. Add the module to a profile, then run
`samebench update` to lock it and `samebench apply` to install it.

## The look

The whole setup shares one visual style, called Liquid Glass, on every machine.

- **Neovim** uses Tokyo Night in the moon variant with a transparent background, mint as the accent colour,
  italic comments, a highlighted current line and rounded borders. A path bar above each code window shows the
  project and the file, with `●` for unsaved changes.
- **tmux** has a transparent status bar with mint pills. The session pill turns orange while <kbd>Ctrl</kbd>+<kbd>b</kbd>
  is active. The focused pane is solid and easy to read, the others stay glassy. The git branch of the active pane
  sits on the right, and every pane title shows the program running in it.
- **lazygit** gets mint borders with round corners and never checks for updates on its own.
- **The kernel console** shows its prompts in mint.

The glass effect itself comes from your terminal. On a Mac, use a profile like *Clear Dark* with about 80 percent
opacity. On Windows, set the background opacity in Windows Terminal to about 80 percent and enable acrylic.

| File | What it styles |
|---|---|
| [`config/nvim/lua/plugins/theme.lua`](../config/nvim/lua/plugins/theme.lua) | Colours, status line, tab bar |
| [`config/nvim/lua/plugins/icons_unicode.lua`](../config/nvim/lua/plugins/icons_unicode.lua) | Icons without a Nerd Font |
| [`config/tmux/tmux.conf`](../config/tmux/tmux.conf) | tmux, status bar and panes |
| [`config/lazygit/config.yml`](../config/lazygit/config.yml) | lazygit colours |
| [`config/jupyter/jupyter_console_config.py`](../config/jupyter/jupyter_console_config.py) | Console prompts |

## Editor behaviour worth knowing

Format on save is off, so you don't reformat other people's code by accident. Format by hand with
<kbd>Space</kbd> <kbd>c</kbd> <kbd>f</kbd>, or toggle automatic formatting with <kbd>Space</kbd> <kbd>u</kbd> <kbd>f</kbd>.

Neovim checks for changes made by the agent whenever you switch focus and after a second of idle time, and it
tells you when a file was reloaded from disk.

`ty` is still a 0.0.x release. If it gets in your way, replace it with another language server in
[`config/nvim/lua/modules/python.lua`](../config/nvim/lua/modules/python.lua).
