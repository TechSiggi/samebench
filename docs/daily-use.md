# Daily use

[← Back to the overview](../README.md)

Three small commands come with this setup. `dev` opens your workspace, `jlab` opens JupyterLab, and `samebench` takes care
of the setup itself. All three are plain shell scripts in [`bin/`](../bin), so you can read every line they run.

## Starting a workspace

```bash
dev                  # workspace for the current folder
dev ~/code/project   # workspace for another folder
```

Every workspace is a tmux session named after its folder. If it is already running, `dev` simply takes you back
into it, with the editor, the agent and any kernel exactly where you left them. That also holds when an SSH
connection drops in between.

<p align="center">
  <img alt="The three layouts: code, agent and code with Jupyter" src="assets/layouts.svg" width="100%">
</p>

| Layout | Start it with | What you see |
|---|---|---|
| `code` | `dev` | Neovim on top, a terminal bottom left, the agent bottom right. This is the default everywhere |
| `agent` | `dev -l agent` | The agent on the left with 30 percent of the width, Neovim on the right for reviewing |
| `code` with Jupyter | `dev -j` | Like `code`, plus a JupyterLab window and a kernel from the project's `.venv` |

A second tmux window called `shell` is always there for anything else. Switch windows with <kbd>Ctrl</kbd>+<kbd>b</kbd>
and then the number. The first `dev -j` in a project asks before it installs anything, and the
[notebook guide](notebooks.md#a-typical-day-with-notebooks) explains each question.

When the folder has a `.venv`, it is active for the whole session. Neovim's language servers (ruff and ty), the
agent and the terminal all see the project's packages without you activating anything. The one exception is a
`.venv` that came with the repository itself. `dev` leaves it alone and tells you so.

## Working on a frontend

With the [`web` module](configuration.md#the-web-module), `dev` in a TypeScript or Angular project gives you
completion, go to definition, rename and error hints, in component classes and in templates. Node and npm come
from mise and are on the `PATH` of the whole session.

The first `dev` in a frontend project asks whether you trust the folder. With a yes the editor uses the project's
own TypeScript and runs its ESLint and prettier. With a no you still get completion, navigation and type errors
from samebench's own servers. [Trusted project folders](configuration.md#trusted-project-folders) shows the
question and how to change your answer.

`dev` starts the language servers and never your application. Install the project's packages and start the
development server yourself in the terminal pane at the bottom left.

```bash
npm ci
npx ng serve --ssl      # the project's own Angular CLI, or: npm start
```

A frontend and its backend usually live in two repositories. Give each one its own session with `dev` in its
folder, and switch between them with <kbd>Ctrl</kbd>+<kbd>b</kbd> then <kbd>s</kbd>. Both development servers keep
running in their sessions. On a VM over SSH, the [installation guide](installation.md#a-frontend-development-server-on-the-vm)
shows how to reach the server from your local browser.

## Working on a backend

With the [`dotnet` module](configuration.md#the-dotnet-module), `dev` in a .NET project gives you C# with
completion, go to definition, rename, quick fixes and diagnostics for the whole solution. The `dotnet` command
itself comes from the SDK of your system.

The first `dev` in a .NET project asks the [same question](configuration.md#trusted-project-folders). The C#
language server has to load the project, and that runs build targets from it, so there is no half way here. With
a yes you get everything above, with a no C# files have syntax highlighting only.

As with a frontend, `dev` never starts your application. Do that in the terminal pane.

```bash
dotnet restore
dotnet run --project src/Api      # or: dotnet watch
```

Inside Neovim, <kbd>Space</kbd> <kbd>D</kbd> opens the .NET keys for building, running and testing, and `:Dotnet`
has the rest, such as adding a NuGet package. The [cheat sheet](cheatsheet.md#net) lists them. Packages you add
this way come from the feeds in your own NuGet configuration, and `dotnet restore` warns about known
vulnerabilities in them by itself.

## Managing sessions

| Command | What it does |
|---|---|
| `dev -s` | List the running sessions |
| `dev -k` | Stop the session of the current folder, including the agent, the kernel and JupyterLab |
| `dev -k ~/code/project` | Stop the session of another folder |
| `dev -r` | Stop and rebuild, for example `dev -r -j` to add Jupyter or `dev -r -l agent` for the other layout |
| <kbd>Ctrl</kbd>+<kbd>b</kbd> then <kbd>d</kbd> | Leave the session and let it keep running |

> [!CAUTION]
> `dev -k` doesn't ask. Save your work in Neovim first with `:wa`. When the last session is gone, the tmux server
> behind `dev` stops as well.

`dev` runs on its own tmux server (`tmux -L samebench`) with the configuration from this repository. Your own tmux, if you
have one, never sees these sessions, and plain `tmux ls` won't list them. Use `dev -s` instead.

## Opening JupyterLab

```bash
jlab
```

`jlab` finds the JupyterLab that belongs to the current folder and does two things. It prints the address with the
login token as a clickable link, and it opens your browser wherever that is possible.

| Where you are | What happens |
|---|---|
| macOS | The browser opens |
| WSL | Your Windows browser opens |
| Linux with a desktop | The browser opens |
| Linux over SSH | You get the link, <kbd>Ctrl</kbd>+click or <kbd>Cmd</kbd>+click opens it locally |

Your clipboard is never touched. Inside a session, <kbd>Ctrl</kbd>+<kbd>b</kbd> then <kbd>o</kbd> does the same as
typing `jlab`. For the SSH case, the [installation guide](installation.md#linux-vm-over-ssh) shows the port
forwarding and an optional PowerShell function that opens the browser without a click.

## The daily check

The first `dev` of the day spends about a second on two questions. Are there known vulnerabilities in the installed
versions, and is the repository on GitHub newer than your copy? If everything is fine you see a single line. When
something important comes up, `dev` asks you what to do before it opens the workspace. The details are in
[updates and security](updates-and-security.md).

## Where to look things up

Inside Neovim, <kbd>Space</kbd> <kbd>H</kbd> opens a short [cheat sheet](quickref.md). The
[full cheat sheet](cheatsheet.md) has every key for Neovim, tmux, lazygit, notebooks and .NET. When you press
<kbd>Space</kbd> and wait a moment, which-key shows all the options at that point.
