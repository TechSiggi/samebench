# Security policy

This repository sets up development machines, so a mistake in it can reach every machine that uses it. Reports
are very welcome.

## Reporting a problem

Please don't open a public issue for a security problem. Use GitHub's private reporting instead, under
**Security → Report a vulnerability** in this repository. Describe what you found, how to reproduce it and which
platform you used. You will get an answer as soon as possible.

## What counts

- A way to make `samebench`, `dev` or `jlab` run or download something that is not pinned and verified
- An install that happens without the question that should come before it
- A way for a project, a notebook or a remote machine to execute code through these scripts, or through the
  language servers and formatters of Neovim in a folder you have not trusted
- A way to make the editor plugins or their servers install a program by themselves, for example the .NET tools
  of the `dotnet` module in a version that is not the pinned one
- JupyterLab, the kernel or a forwarded port becoming reachable from outside `127.0.0.1`
- Anything that weakens the checks described in [updates and security](docs/updates-and-security.md)

Vulnerabilities in the tools themselves, such as Neovim, tmux or uv, belong with their projects. The daily check
of this setup picks them up once they are published.

## Supported versions

Only the latest state of the default branch is supported.
