# Documentation

[← Back to the overview](../README.md)

On a new machine, start with the installation guide. After that, daily use and the cheat sheet cover most days,
and the other guides are there for the moment you need them.

| Guide | What you find there |
|---|---|
| [Installation](installation.md) | Mac, Linux, a VM over SSH, WSL, proxies, machines that already have a setup, and how to remove everything |
| [Daily use](daily-use.md) | Layouts, sessions, `jlab` and the daily check |
| [Notebooks](notebooks.md) | Working with Jupyter notebooks, the shared kernel, Python and packages |
| [Updates and security](updates-and-security.md) | What is pinned where, what asks first, opening other people's repositories, update day, vulnerability checks, fixes, sync and signed commits |
| [Configuration](configuration.md) | Profiles and their defaults, `local.sh`, modules and the look |
| [How it works](architecture.md) | The scripts, what `samebench apply` does and where things live on a machine |
| [Cheat sheet](cheatsheet.md) | Every key for Neovim, tmux, lazygit and notebooks |
| [Quick reference](quickref.md) | The short version that <kbd>Space</kbd> <kbd>H</kbd> opens inside Neovim |

## Test status

The full setup has been tested on macOS. That covers all layouts, `dev -j` with and without `ipykernel` in the
project, the shared kernel between console and JupyterLab, the daily check, targeted fixes and signed syncing.
Linux and WSL have not had a complete run yet, so expect rough edges there and please report them.
