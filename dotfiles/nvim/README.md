# nvim-config

Personal, portable, hardware-agnostic [LazyVim](https://github.com/LazyVim/LazyVim)-based Neovim config. Goal: clone this to any machine, get the same terminal-based IDE, with as little manual setup as possible.

## Usage

### Non-Nix machines (Linux/macOS)

1. Install Neovim (>= 0.11) any way you like.
2. Clone this repo to `~/.config/nvim`.
3. Run `./bootstrap.sh` — installs the host dependencies this config needs (see below).
4. Open `nvim`, run `:checkhealth` to confirm everything's green.

`bootstrap.sh` detects your package manager (`apt`, `dnf`, `pacman` on Linux; `brew` on macOS) and is safe to re-run. On WSL it also installs `win32yank` for clipboard integration with Windows.

### NixOS / home-manager

Don't run `bootstrap.sh` — on NixOS it detects `/etc/NIXOS` and no-ops, since there's no `apt`/`brew` to shell out to. Instead, pull this repo in as a flake input and import `nix/packages.nix`:

```nix
# flake.nix
inputs.nvim-config = {
  url = "github:dcronin05/nvim-config";
  flake = false;  # this repo is a plain source tree, not a flake
};
```

```nix
# a home-manager module, with nvim-config threaded through via extraSpecialArgs
{ config, pkgs, nvim-config, ... }:
{
  xdg.configFile."nvim".source = nvim-config;
  home.packages = import "${nvim-config}/nix/packages.nix" { inherit pkgs; };
}
```

This is exactly how [`nixos-config`](https://github.com/dcronin05/nixos-config) consumes it (see `home/neovim.nix` there for the real, working example, and that repo's README for how the pinning/rebuild workflow works in practice).

**Important:** a flake input is pinned by `flake.lock` — pushing here doesn't affect a Nix-managed machine until its lock file is explicitly updated (`nix flake lock --update-input nvim-config`) and rebuilt.

## Host dependencies

Both `bootstrap.sh` and `nix/packages.nix` install the same conceptual list — kept in two forms because Nix and apt/brew/dnf use different package names. **Update both together** when a plugin adds a new external tool requirement:

| Tool | Why |
|---|---|
| C compiler (`gcc`) | `nvim-treesitter` builds parsers natively on the host |
| `tree-sitter` (CLI) | same, required alongside the compiler |
| `ripgrep` | live grep / picker search |
| `fd` | file explorer / picker fuzzy search |
| `lazygit` | git UI integration |
| `node` + `npm` | some Mason-installed LSP servers; `tree-sitter-cli` itself is installed via npm |

Not included, and intentionally so: `fzf` and `luarocks` (unused by this config's actual plugin set — LazyVim's health check flags them as generically optional, but nothing here needs them), and any clipboard tool (machine/display-context-dependent — WSL needs `win32yank` specifically, a headless SSH-only box needs none at all, so `bootstrap.sh` only installs one on WSL and leaves it to you elsewhere).

## Structure

- `lua/config/` — core options, keymaps, autocmds.
- `lua/plugins/` — plugin specs, LazyVim-style (one file per plugin/group).
- `bootstrap.sh` — non-Nix host dependency installer.
- `nix/packages.nix` — the same dependency list, importable by a home-manager module.
