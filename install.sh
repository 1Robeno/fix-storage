#!/bin/sh
# fix-storage installer
#
#   curl -fsSL https://raw.githubusercontent.com/govijr/fix-storage/main/install.sh | sh
#
# Options (pass after `sh -s --`):
#   --version <x.y.z>   install a specific release instead of the latest
#   --uninstall         remove fix-storage
#
# Environment:
#   FIX_STORAGE_HOME     where the app lives        (default: ~/.fix-storage)
#   FIX_STORAGE_BIN      where the command is linked (default: ~/.local/bin)
#   FIX_STORAGE_REPO     GitHub repo to install from (default: govijr/fix-storage)
#   FIX_STORAGE_TARBALL  install from this local .tgz or URL instead of a release
#
# Nothing here needs sudo. Everything installs into your home folder.

set -eu

REPO="${FIX_STORAGE_REPO:-govijr/fix-storage}"
APP_HOME="${FIX_STORAGE_HOME:-$HOME/.fix-storage}"
BIN_DIR="${FIX_STORAGE_BIN:-$HOME/.local/bin}"
MIN_NODE_MAJOR=20
MIN_NODE_MINOR=11

if [ -t 1 ]; then
  BOLD="$(printf '\033[1m')"; DIM="$(printf '\033[2m')"; RED="$(printf '\033[31m')"
  GREEN="$(printf '\033[32m')"; YELLOW="$(printf '\033[33m')"; RESET="$(printf '\033[0m')"
else
  BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; RESET=""
fi

say() { printf '%s\n' "$*"; }
step() { printf '%s›%s %s\n' "$DIM" "$RESET" "$*"; }
warn() { printf '%swarning:%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
fail() { printf '%serror:%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }

uninstall() {
  step "removing $APP_HOME"
  rm -rf "$APP_HOME"
  if [ -L "$BIN_DIR/fix-storage" ]; then
    step "removing $BIN_DIR/fix-storage"
    rm -f "$BIN_DIR/fix-storage"
  fi
  say "${GREEN}fix-storage is uninstalled.${RESET}"
}

check_node() {
  command -v node >/dev/null 2>&1 || fail "fix-storage needs Node.js ${MIN_NODE_MAJOR}.${MIN_NODE_MINOR} or newer.
       Install it with:  brew install node   (or from https://nodejs.org)"
  command -v npm >/dev/null 2>&1 || fail "npm was not found. It normally comes with Node.js."
  version="$(node -p 'process.versions.node')"
  major="$(printf '%s' "$version" | cut -d. -f1)"
  minor="$(printf '%s' "$version" | cut -d. -f2)"
  if [ "$major" -lt "$MIN_NODE_MAJOR" ] || { [ "$major" -eq "$MIN_NODE_MAJOR" ] && [ "$minor" -lt "$MIN_NODE_MINOR" ]; }; then
    fail "fix-storage needs Node.js ${MIN_NODE_MAJOR}.${MIN_NODE_MINOR} or newer; you have $version.
       Update it with:  brew upgrade node"
  fi
}

# The newest release's version. Resolved once, so the package and its
# checksum come from the same release even if a new one is published meanwhile.
latest_version() {
  url="$(curl -fsSLI --retry 3 -o /dev/null -w '%{url_effective}' "https://github.com/$REPO/releases/latest")" ||
    fail "could not reach https://github.com/$REPO/releases/latest"
  tag="${url##*/}"
  case "$tag" in
    v[0-9]*) printf '%s' "${tag#v}" ;;
    *) fail "no release found at https://github.com/$REPO/releases (latest resolved to $url)" ;;
  esac
}

tarball_url() {
  if [ -n "${FIX_STORAGE_TARBALL:-}" ]; then
    printf '%s' "$FIX_STORAGE_TARBALL"
  else
    printf 'https://github.com/%s/releases/download/v%s/fix-storage.tgz' "$REPO" "${VERSION#v}"
  fi
}

# Checks a download against the .sha256 file published next to it. Releases
# always publish one, so for them a missing checksum is an error; a custom
# FIX_STORAGE_TARBALL URL is checked only when it has one.
verify() {
  file="$1"
  url="$2"
  if ! curl -fsL --retry 3 -o "$file.sha256" "$url.sha256"; then
    [ -n "${FIX_STORAGE_TARBALL:-}" ] || fail "could not download the checksum $url.sha256"
    warn "no checksum at $url.sha256; installing unverified"
    return 0
  fi
  expected="$(cut -d' ' -f1 <"$file.sha256")"
  actual="$(shasum -a 256 "$file" | cut -d' ' -f1)"
  [ "$expected" = "$actual" ] || fail "checksum mismatch for $url
       expected $expected
       got      $actual"
  step "checksum verified"
}

install() {
  [ "$(uname -s)" = "Darwin" ] || fail "fix-storage is for macOS only."
  check_node

  if [ -z "$VERSION" ] && [ -z "${FIX_STORAGE_TARBALL:-}" ]; then
    VERSION="$(latest_version)"
  fi
  source="$(tarball_url)"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT INT TERM

  case "$source" in
    http://* | https://*)
      step "downloading ${source}"
      curl -fsSL --retry 3 -o "$tmp/fix-storage.tgz" "$source" ||
        fail "could not download $source
       Check the version exists at https://github.com/$REPO/releases"
      verify "$tmp/fix-storage.tgz" "$source"
      ;;
    *)
      [ -f "$source" ] || fail "no such file: $source"
      cp "$source" "$tmp/fix-storage.tgz"
      ;;
  esac

  # Install next to the old copy and swap at the end, so a failed install leaves the old one working.
  step "installing into $APP_HOME ${DIM}(this also fetches the graphics runtime, about 100 MB)${RESET}"
  staging="$APP_HOME.new"
  rm -rf "$staging"
  mkdir -p "$staging"
  printf '{ "name": "fix-storage-install", "private": true }\n' >"$staging/package.json"
  if ! (cd "$staging" && npm install --omit=dev --no-fund --no-audit --loglevel=error "$tmp/fix-storage.tgz" >"$tmp/npm.log" 2>&1); then
    cat "$tmp/npm.log" >&2
    rm -rf "$staging"
    fail "npm install failed (log above)."
  fi
  rm -rf "$APP_HOME"
  mv "$staging" "$APP_HOME"

  mkdir -p "$BIN_DIR"
  ln -sf "$APP_HOME/node_modules/.bin/fix-storage" "$BIN_DIR/fix-storage"
  installed="$(node -p "require('$APP_HOME/node_modules/fix-storage/package.json').version")"

  say ""
  say "${GREEN}${BOLD}fix-storage ${installed} is installed.${RESET}"
  case ":$PATH:" in
    *":$BIN_DIR:"*)
      say "Run ${BOLD}fix-storage${RESET} to see what is filling your disk."
      ;;
    *)
      shell_rc="$HOME/.zshrc"
      case "${SHELL:-}" in */bash) shell_rc="$HOME/.bash_profile" ;; esac
      say ""
      warn "$BIN_DIR is not on your PATH. Add it with:"
      say ""
      say "  echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> $shell_rc && source $shell_rc"
      say ""
      say "Then run ${BOLD}fix-storage${RESET}."
      ;;
  esac
  say "${DIM}Tip: fix-storage --dry-run lets you try everything without deleting anything.${RESET}"
}

VERSION=""
ACTION="install"
while [ $# -gt 0 ]; do
  case "$1" in
    --version) [ $# -ge 2 ] || fail "--version needs a value"; VERSION="$2"; shift 2 ;;
    --version=*) VERSION="${1#*=}"; shift ;;
    --uninstall) ACTION="uninstall"; shift ;;
    -h | --help) sed -n '2,17p' "$0" 2>/dev/null || true; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done

# Everything above only defines things; this last line runs them, so a
# half-downloaded script does nothing.
if [ "$ACTION" = "uninstall" ]; then uninstall; else install; fi
