#!/usr/bin/env bash
set -euo pipefail

# Installs the host dependencies this Neovim config needs (a C compiler for
# treesitter, ripgrep, fd, lazygit, node + tree-sitter-cli, and a clipboard
# bridge). Assumes nvim itself and this repo (cloned to ~/.config/nvim) are
# already in place. Safe to re-run.
#
# On NixOS, dependencies are declared in nix/packages.nix instead, meant to
# be imported into your home-manager config — this script just points there
# and exits, since there's no apt/brew to shell out to.

if [ -f /etc/NIXOS ]; then
  cat <<'EOF'
NixOS detected. Host dependencies for this config are declared in
nix/packages.nix instead of being installed here — import it into your
home-manager config, e.g.:

  home.packages = import "${inputs.nvim-config}/nix/packages.nix" { inherit pkgs; };

Nothing to do here.
EOF
  exit 0
fi

is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

install_fnm_and_node() {
  if ! command -v fnm >/dev/null 2>&1; then
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
  fi
  export PATH="$HOME/.local/share/fnm:$PATH"
  eval "$(fnm env)"
  fnm install --lts
  npm install -g tree-sitter-cli markdownlint-cli2
}

install_win32yank() {
  mkdir -p "$HOME/.local/bin"
  command -v unzip >/dev/null 2>&1 || sudo apt-get install -y unzip
  curl -fsSL -o /tmp/win32yank.zip \
    https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip
  unzip -o /tmp/win32yank.zip -d "$HOME/.local/bin" win32yank.exe
  chmod +x "$HOME/.local/bin/win32yank.exe"
}

case "$(uname -s)" in
  Linux)
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update
      sudo apt-get install -y build-essential ripgrep fd-find lazygit
      mkdir -p "$HOME/.local/bin"
      ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
      if is_wsl; then
        install_win32yank
      else
        sudo apt-get install -y xclip
      fi
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y gcc gcc-c++ make ripgrep fd-find lazygit xclip
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -Sy --noconfirm base-devel ripgrep fd lazygit xclip
    else
      echo "Unrecognized Linux package manager — install manually: a C compiler, ripgrep, fd, lazygit" >&2
      exit 1
    fi
    ;;
  Darwin)
    if ! command -v brew >/dev/null 2>&1; then
      echo "Homebrew not found — install it first: https://brew.sh" >&2
      exit 1
    fi
    brew install ripgrep fd lazygit
    xcode-select --install 2>/dev/null || true
    ;;
  *)
    echo "Unrecognized OS: $(uname -s) — install manually: a C compiler, ripgrep, fd, lazygit, node" >&2
    exit 1
    ;;
esac

install_fnm_and_node

echo
echo "Done. Make sure \$HOME/.local/bin is on PATH, then open nvim and run :checkhealth."
