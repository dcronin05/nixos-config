# Portable/Rootless Servers — Design Doc (SHELVED, not implemented)

**Status: design only, deliberately not built yet.** Captured here so the reasoning survives even though implementation is on hold. Revisit when there's an actual server to build/test against and the appetite to finish it.

## Goal

Be able to log into any headless Linux server where I only have an unprivileged user account — no `sudo`, ever, on that box — and get my own environment (shell, prompt, multiplexer, git identity, a handful of CLI tools) set up as close to instantly as possible. Two motivating cases: `gpantz` (a server I own but don't have root on), and "any random server I'm handed for work or whatever," where the account, distro, and lockdown level are all unknown ahead of time.

## What was explored and rejected: Nix via `nix-portable`

The first design used [`nix-portable`](https://github.com/DavHau/nix-portable) (actively maintained; the older `nix-user-chroot` is explicitly unmaintained, ruled out) to run Nix without root and without a pre-existing `/nix`, then reuse this repo's existing `home-manager` config verbatim.

**Real structural problems found even before considering whether it works:**
- `home/base.nix` hardcodes `home.username = "dcronin05"` and a matching `homeDirectory`. Wrong for `gpantz` (whose account is literally `gpantz`) and unknowable for a random work account. Would have required a parallel profile using `builtins.getEnv "USER"`/`"HOME"` — which forces every `nix build`/`home-manager switch` invocation to run with `--impure`, since flake evaluation is pure by default and there's no other way to resolve an unknown-ahead-of-time account name.
- `homeConfigurations` keys are static (no wildcard/glob mechanism in the flake schema), so a random/unpredictable hostname needs one fixed flake key (e.g. `dcronin05@portable`) rather than the `dcronin05@$(hostname)` convention the other tiers use.

**Then the deeper reconsideration — is Nix even the right tool for this specific goal:**
1. **"Instantly" doesn't fit Nix's cost profile.** Even sidestepping every other issue, a first-time `nix build` on a fresh box has to fetch `nixpkgs`/`home-manager`/`sops-nix` and substitute a real dependency closure (glibc, zsh, starship, git, etc.) from `cache.nixos.org`. That's tens of seconds to a couple of minutes depending on the network — not "log in and immediately have my environment."
2. **The target environment is exactly the one most likely to break nix-portable's sandboxing.** "Any random work server" is a plausible candidate for a hardened corporate security baseline that disables unprivileged user namespaces outright (`unprivileged_userns_clone=0`) — nix-portable's documented fallback for that is `proot`, which works via `ptrace`, commonly blocked by the same class of hardening policy. Real chance both of nix-portable's mechanisms are unavailable simultaneously on precisely the boxes this was meant for.
3. (Separately, and lower-stakes: nix-portable's own docs list "managing nix profiles via `nix-env`" as a missing feature, which is what `home-manager switch`'s generation/rollback bookkeeping relies on. This one *does* have a clean fix — build the flake's `activationPackage` output directly and run `./result/activate`, skipping the unsupported piece entirely, since that's the same primitive `home-manager switch` itself is built on. Not what killed the plan, but worth remembering if Nix-based rootless deployment comes up again elsewhere.)

## Preferred direction (not built)

Stop trying to run Nix on the target at all. Instead:

1. **Render the plain-text config artifacts once, from this repo's real Nix source, on a machine that already has Nix** — the `.zshrc`/prompt setup, `starship.toml`, zellij config, `.gitconfig`, aliases. This keeps `cli.nix` as the one real source of truth; the rootless deploy path consumes a *pre-baked export* of it rather than a hand-maintained duplicate. (Exact mechanism not designed yet — likely a `nix build` of a derivation that just copies the relevant rendered files out of the home-manager activation package, run in CI or manually before a deploy, with the output committed or fetched fresh at deploy time.)
2. **A single dependency-free bootstrap script** that, on the target server: symlinks/copies those rendered files into place, and `curl`s a small number of static release binaries for anything worth having that the target's own package manager won't have or will have ancient — `starship` has its own official installer that targets a custom `--bin-dir` without root; `zellij`/`lsd`/`btop` ship static binaries directly on GitHub releases. No sandboxing, no `cache.nixos.org` dependency, no user-namespace/ptrace requirement — the only thing that has to work is `curl` and writing to your own home directory, which is true on literally any account you'd ever be given.
3. **Neovim explicitly out of scope for this tier** — the heavy toolchain (`gcc`, `nodejs`, `tree-sitter`) was already going to be opt-in-only even under the Nix design; doubly not worth it under a "minimal footprint, might touch this box once" model.

**Known cost of this direction, accepted deliberately:** two representations of "my environment" instead of one — the live Nix config for owned machines, and a rendered export for rootless ones. Mitigated by (1) above (render *from* the Nix source rather than hand-duplicating), but not eliminated — a change to `cli.nix` needs a re-render step remembered, not just a `git push`.

## Checklist for picking this back up

- [ ] Decide the exact rendering mechanism (derivation that extracts specific files from the activation package vs. a simpler hand-written Nix expression that just formats the same values `cli.nix` uses).
- [ ] Decide where the rendered output lives (committed to the repo vs. built fresh each deploy from a machine that has Nix).
- [ ] Write the actual bootstrap script (`bootstrap-portable.sh` or similar) — symlink rendered files, `curl` the static binaries above.
- [ ] Test end-to-end against a real target once one exists (`gpantz` was the original candidate — confirm SSH access is actually set up before testing).
- [ ] Decide the secrets question (was raised but not needed for this direction at all, since there's no Nix/sops-nix involved in the rootless path anymore) — if a rootless box ever needs a secret, that's a distinct, smaller problem (e.g. just `scp`ing one file) rather than anything sops-nix related.
