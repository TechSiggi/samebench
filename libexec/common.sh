# Output and question helpers shared by bin/samebench and bin/dev (sourced, not run).

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok() { printf '\033[1;32m ok\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !!\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31m xx\033[0m %s\n' "$*" >&2; exit 1; }

# ask "question" returns 0 for yes. Reads from the terminal even when stdin is redirected.
ask() {
  local answer=""
  printf '%s [y/N] ' "$1" >&2
  { read -r answer </dev/tty || read -r answer || true; } 2>/dev/null
  case "$answer" in y | Y | yes | j | J) return 0 ;; esac
  return 1
}

# short_hash <length>: the first characters of the SHA-256 of stdin
short_hash() { (sha256sum 2>/dev/null || shasum -a 256) | cut -c1-"$1"; }
