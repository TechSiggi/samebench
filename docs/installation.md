# Installation

[← Back to the overview](../README.md)

Every machine gets a **profile**, a small file that sets what differs from the built-in defaults. Two profiles
ship with the repository, and the [configuration guide](configuration.md#profiles) explains every setting.

| Profile | For |
|---|---|
| `mac` | A Mac with Apple silicon |
| `linux` | Ubuntu or Debian on x64 or arm64, which includes a VM over SSH and WSL |

With both profiles, Python only comes from uv after you confirm, and the Jupyter tool is installed on the first
`dev -j`.

Before anything is installed, `samebench` shows you a plan with every program, its version, the way it is verified and
the exact download URL. Nothing happens until you say yes. You can look at that plan on its own at any time. On a
machine that is not set up yet, call `samebench` by its path and name the profile.

```bash
samebench plan                         # on a machine that is set up
~/samebench/bin/samebench plan linux   # on a new machine
```

## macOS

1. Install a terminal you like. [Ghostty](https://ghostty.org) is signed and already ships the icons of a Nerd Font.
2. Install Apple's developer tools, which bring git and a C compiler.
   ```bash
   xcode-select --install
   ```
3. Clone the repository and run `samebench apply` with the `mac` profile.
   ```bash
   git clone https://github.com/TechSiggi/samebench ~/Development/samebench
   ~/Development/samebench/bin/samebench apply mac
   ```
4. Install your coding agent. For Claude Code, use the official installer from Anthropic, read the script first, and
   turn on `/sandbox` once inside Claude.
5. Open a new terminal and start your first workspace with `dev ~/path/to/project`.

`samebench apply` loads the profile, checks the system, shows the plan and asks. Only after your yes it downloads the one
program it fetches itself, the version manager mise. The version and the SHA-256 sums for the supported platforms sit
at the top of [`bin/samebench`](../bin/samebench). When the download does not match, `samebench` stops and installs nothing.
Everything else comes through mise and the lockfiles.

## Linux

```bash
sudo apt-get update && sudo apt-get install -y git curl ca-certificates build-essential unattended-upgrades
git clone https://github.com/TechSiggi/samebench ~/samebench
~/samebench/bin/samebench apply linux
```

Python from apt is not needed. When a project wants Python, uv offers to install a matching version and waits for
your answer. `unattended-upgrades` keeps the system packages patched with the distribution's signed security
updates, and `samebench apply` warns when it is missing.

## Linux VM over SSH

On the VM itself you follow the Linux steps above. Everything runs there, including Neovim, the agent, `dev -j` and
JupyterLab. On the computer you sit at, you only run `ssh`, for example from PowerShell in Windows Terminal or from
the macOS Terminal.

To reach JupyterLab in your local browser, SSH forwards the ports, which is what VS Code does for you
automatically. Add this once to your SSH config. On Windows it lives in `C:\Users\<you>\.ssh\config`, on a Mac in
`~/.ssh/config`.

```ssh-config
Host my-vm
  HostName <ip-or-dns-name>
  User <user>
  IdentityFile ~/.ssh/id_ed25519_my_vm
  ForwardAgent no
  LocalForward 8888 127.0.0.1:8888
  LocalForward 8889 127.0.0.1:8889
  LocalForward 8890 127.0.0.1:8890
```

Three ports let you run up to three `dev -j` sessions at the same time. Each forward only listens on `127.0.0.1` of
your own computer, so other devices on your network can't reach JupyterLab, and the token protects it on top of
that. `ForwardAgent no` matters too, because otherwise the agent on the VM could use your local SSH keys.

After `ssh my-vm` and `dev -j`, type `jlab`. A program on the VM can't open the browser on your computer, and that
is intentional, so `jlab` prints a clickable link instead. <kbd>Ctrl</kbd>+click opens it in Windows Terminal,
<kbd>Cmd</kbd>+click on a Mac.

<details>
<summary><b>Optional: type <code>jlab</code> in PowerShell and the browser opens</b></summary>

<br>

Put this function into your PowerShell profile (`notepad $PROFILE`). It asks the VM for the address over your
normal SSH connection and opens it locally.

```powershell
function jlab([string]$Folder = "") {
  $url = ssh my-vm "~/samebench/bin/jlab --url $Folder"
  if ($url -match '^http://127\.0\.0\.1:(8888|8889|8890)/lab\?token=[0-9a-f]+$') { Start-Process $url }
  else { Write-Host "No JupyterLab found. Is dev -j running on the VM?" }
}
```

The function only ever opens `127.0.0.1` on one of the forwarded ports with a token in the expected format. Even a
manipulated answer from the VM could not send your browser anywhere else. With several `dev -j` sessions,
`jlab demo` picks the right one.

</details>

> [!NOTE]
> Reconnecting is painless. If the SSH connection drops, run `ssh my-vm` and `dev` again. The session, the kernel and
> the agent kept running on the VM the whole time.

If the VM runs in a cloud, open only port 22 in its firewall and ideally only for your own IP. Log in with keys only.
If the VM has a **cloud identity** attached, such as an instance role or a managed identity, any process on it, the
agent included, can request tokens for that cloud. Remove the identity or keep its rights minimal.

## WSL on Windows

Follow the Linux steps inside your WSL distribution. A few things are different from a regular Linux machine.

Keep the repository and your projects inside the Linux file system, for example in `~/projects`. Under `/mnt/c`
everything is slow, and file permissions and file watching don't behave properly.

Use Windows Terminal. For the `nerd` icons, install a Nerd Font on the Windows side and select it there. Otherwise
put `ICONS="unicode"` into `~/.config/samebench/local.sh` and run `samebench apply` again.

`jlab` opens JupyterLab directly in your Windows browser, because WSL forwards `127.0.0.1` on its own.

> [!WARNING]
> Inside WSL every Linux process, the agent included, can read your Windows drives under `/mnt/c` and start Windows
> programs such as `powershell.exe`. The agent's sandbox limits this, but the door is there. You can close it in
> `/etc/wsl.conf` with `[automount] enabled=false` and `[interop] enabled=false`. After that, `jlab` can no longer open
> the browser and shows the link instead. `samebench doctor` reminds you of this on WSL.

## Machines with an existing setup

`samebench` never deletes or uninstalls anything it did not create, and it doesn't replace configuration files that
belong to someone else without keeping a copy.

| Already there | What happens |
|---|---|
| Your own `~/.config/nvim` | Stays as it is. This setup uses its own folder `~/.config/samebench-nvim` |
| Your own tmux and `tmux.conf` | Stay as they are. `dev` runs its own tmux server |
| `~/.config/uv/uv.toml` with your own uv settings | Stays unchanged |
| uv, Jupyter or Python from Homebrew, pip or apt | Stay installed, and `samebench plan` lists them |
| A mise of another version in `~/.local/bin` | Is kept as `mise.backup-<date>` with a warning, and the pinned version takes its place |
| `~/.config/mise/config.toml` | Is kept as a backup copy and replaced by a link into the repository |
| `.zshrc`, `.bashrc`, global git config | Get one addition each, nothing is replaced |

On a machine where other tools should behave exactly as before, set the activation to `dev`. Then the tools
from mise only appear inside `dev` sessions, and every other shell, VS Code Remote included, stays the way it was.
Machine specific settings go into `~/.config/samebench/local.sh`, which is not part of the repository.

```bash
# ~/.config/samebench/local.sh
ACTIVATE="dev"     # only inside dev sessions
JUPYTER="no"       # never install Jupyter on this machine
```

Details of a single machine, such as mirror URLs or host names, never belong in the repository. Keep them in
`local.sh` or in the machine's own configuration files.

## Behind a proxy

Nothing in this repository sets or changes proxy settings. curl, git, mise and uv all read the standard variables
`HTTPS_PROXY`, `HTTP_PROXY` and `NO_PROXY` from your environment. A machine that already reaches the internet through
a proxy therefore needs no extra step for `samebench` or the daily check.

A few things are worth knowing.

- A proxy that inspects TLS traffic presents its own certificates. curl, git and mise trust the system certificate
  store. uv brings its own list and only looks at the system store when you ask for it, with `system-certs = true`
  in `~/.config/uv/uv.toml` or `UV_SYSTEM_CERTS=1` in your environment. `samebench` never touches that file.
- Downloads are still compared with the checksums in the lockfiles, so a file that changes on the way is rejected.
- Requests to JupyterLab on `127.0.0.1` never go through a proxy. <kbd>Space</kbd> <kbd>j</kbd> <kbd>k</kbd> ignores
  the proxy variables on purpose, because the login token must not leave the machine.
- Everyone behind the same proxy shares one address towards GitHub, and GitHub limits anonymous API requests per
  address. If `samebench apply` stops with a rate limit message, wait an hour or set `MISE_GITHUB_TOKEN` to a token that
  has no permissions at all.

## Taking it all away again

```bash
samebench remove
```

This removes the line in `.zshrc` and `.bashrc`, the additions to your global git config, all links (backups come
back) and running `dev` sessions. Afterwards it asks separately whether the installed programs, their data and the
caches should go too. If you say yes and `samebench` had put a mise of yours aside, that one comes back. Your
`local.sh` stays. Python versions installed by uv and its package cache live in `~/.local/share/uv` and
`~/.cache/uv`. They belong to uv, so they stay as well. A few small caches can stay too, from tree-sitter, from ty
and from the signature check in mise, because other programs may share them. `samebench remove` names them when they
exist.
