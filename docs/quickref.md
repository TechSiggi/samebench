# Quick reference

`Space` is the leader key. Press it and wait, which-key shows the rest. Close this window with `q`.
Full version with everything: docs/cheatsheet.md

## Neovim

| Keys            | Action                                  |
|-----------------|-----------------------------------------|
| `Space Space`   | find a file                             |
| `Space /`       | search the project                      |
| `Space e`       | file explorer                           |
| `Shift h / l`   | previous / next tab, `Space bd` closes  |
| `gd` / `gr`     | definition / references                 |
| `K`             | documentation under the cursor          |
| `Space cr`      | rename                                  |
| `Space ca`      | quick fix                               |
| `Space cf`      | format (`Space uf` toggles on save)     |
| `gcc` / `gc`    | comment line / selection                |
| `Space xx`      | list of problems                        |
| `Space gg`      | lazygit                                 |

## Windows and tmux

| Keys            | Action                                  |
|-----------------|-----------------------------------------|
| `Ctrl h/j/k/l`  | move across Neovim windows and panes    |
| `Ctrl b` `z`    | zoom pane                               |
| `Ctrl b` `1-3`  | switch window                           |
| `Ctrl b` `s/L`  | pick a session / back to the last one   |
| `Ctrl b` `d`    | leave session, it keeps running         |
| `Ctrl b` `g`    | lazygit popup                           |
| `Ctrl b` `o`    | open JupyterLab (same as `jlab`)        |
| `Ctrl b` `[`    | scroll and copy, `q` ends it            |

## Notebooks (session started with `dev -j`)

| Keys            | Action                                  |
|-----------------|-----------------------------------------|
| `Space jk`      | connect the kernel console              |
| `Space jj`      | run cell (selection in visual mode)     |
| `Space jn`      | run cell and move on                    |
| `Space ja`      | run everything up to here               |
| `]j` / `[j`     | next / previous cell                    |
| `Space jc / jm` | new code / markdown cell                |
| `:w`            | save back into the .ipynb               |

## .NET (module `dotnet`, in a trusted folder)

| Keys            | Action                                  |
|-----------------|-----------------------------------------|
| `Space Db / Dr` | build / run a project                   |
| `Space Dt / DT` | test runner / run the tests             |
| `Space DR`      | restore packages                        |
| `Space Dd`      | diagnostics of the whole solution       |
| `:Dotnet`       | everything else, `Tab` lists it         |

## lazygit

| Keys            | Action                                  |
|-----------------|-----------------------------------------|
| `Space`         | stage / unstage                         |
| `c`             | commit                                  |
| `P` / `p`       | push / pull                             |
| `?` / `q`       | all keys / quit                         |

## Shell

| Command            | Action                                  |
|--------------------|-----------------------------------------|
| `dev`, `dev -j`    | open workspace, with Jupyter            |
| `dev -s`, `-k`     | list sessions, stop this one            |
| `jlab`             | open JupyterLab                         |
| `samebench doctor` | check this machine                      |
