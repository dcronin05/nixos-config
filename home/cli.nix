# ==============================================================================
# UNIVERSAL CLI ENVIRONMENT (THE CORE SYSTEM)
# ==============================================================================
# Please maintain this modular structure unless a redesign is explicitly requested.
#
# This file is the absolute source of truth for the CLI environment.
# EVERY machine (macOS, NixOS, WSL) imports this file via `base.nix`.
#
# 1. Packages (`home.packages`):
#    We install tools like `btop`, `wget`, `lsd`, `sops` here instead of in
#    `modules/common.nix`. Why? Because macOS doesn't use `common.nix`. 
#    By putting them here in Home Manager, we guarantee 100% cross-platform 
#    parity for the user's terminal environment.
#
# 2. Terminal Theming:
#    The Starship prompt, Zellij, and Neovim are heavily customized using 
#    EXPLICIT 24-bit TrueColor HEX CODES (e.g. #f92672).
#    This is intentionally done to make the terminal "agnostic" so it looks 
#    identical everywhere, regardless of the host terminal emulator's theme.
#
# 3. Universal Background Automations:
#    While `cli.nix` exports universal PATHs (like `~/.local/bin`), proprietary 
#    binaries like `moshi-hook` are extracted into their own modules (e.g. `moshi.nix`)
#    and imported by `base.nix` to keep this file purely declarative.
# ==============================================================================
{ config, pkgs, lib, hostColor ? "#66d9ef", ... }:

{
  home.stateVersion = "24.05";
  
  home.packages = with pkgs; [
    lsd
    tree
    vim
    wget
    curl
    btop
    htop
    zip
    unzip
    sops
    mosh
    eternal-terminal
  ];

  
  # User-level terminal configurations
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    
    settings = {
      format = "$username$hostname$git_branch$git_status$python$nodejs$c$docker_context$memory_usage$jobs$status$cmd_duration$time$battery$line_break$directory$character";
      add_newline = true;
      command_timeout = 1000;
      username = {
        show_always = true;
        style_user = "bold #ae81ff";
        style_root = "bold #f92672";
        format = "[$user]($style)";
      };
      hostname = {
        ssh_only = false;
        style = "bold ${hostColor}";
        format = "@[$hostname]($style) ";
      };
      directory = {
        style = "bold #66d9ef";
        format = "[ $path]($style) ";
        truncation_length = 4;
        truncation_symbol = "…/";
      };
      git_branch = {
        symbol = " ";
        style = "bold #a6e22e";
        format = "on [$symbol$branch]($style) ";
      };
      git_status = {
        style = "#a6e22e";
        format = "([$all_status$ahead_behind]($style) )";
        conflicted = "🏳 ";
        ahead = "⇡ ";
        behind = "⇣ ";
        diverged = "⇕ ";
        untracked = "? ";
        stashed = "$ ";
        modified = "! ";
        staged = "+ ";
        renamed = "» ";
        deleted = "✘ ";
      };
      python = {
        symbol = " ";
        style = "bold #e6db74";
        format = "via [$symbol$version]($style) ";
      };
      nodejs = {
        symbol = " ";
        style = "bold #a6e22e";
        format = "via [$symbol$version]($style) ";
      };
      c = {
        symbol = " ";
        style = "bold #66d9ef";
        format = "via [$symbol$version]($style) ";
      };
      docker_context = {
        symbol = " ";
        style = "bold #66d9ef";
        format = "docker [$symbol$context]($style) ";
      };
      memory_usage = {
        disabled = false;
        threshold = -1;
        symbol = "󰍛 ";
        style = "bold #fd971f";
        format = "using [$symbol$ram]($style) ";
      };
      jobs = {
        symbol = " ";
        style = "bold #66d9ef";
        format = "with [$symbol$number suspended]($style) ";
      };
      status = {
        disabled = false;
        style = "bold #f92672";
        format = "exited [$symbol$int]($style) ";
        symbol = "✘ ";
      };
      cmd_duration = {
        min_time = 2000;
        style = "bold #e6db74";
        format = "took [ $duration]($style) ";
      };
      time = {
        disabled = false;
        time_format = "%R";
        style = "#66d9ef";
        format = "at [ $time]($style) ";
      };
      battery = {
        full_symbol = " ";
        charging_symbol = " ";
        discharging_symbol = " ";
        display = [
            { threshold = 20; style = "red"; }
            { threshold = 100; style = "yellow"; }
        ];
      };
      character = {
        success_symbol = "[❯](bold #ae81ff)";
        error_symbol = "[✗](bold #f92672)";
      };
      line_break = {
        disabled = false;
      };
    };
  };
  programs.zellij = {
    enable = true;
    settings = {
      theme = "monokai-dimmed";
      themes = {
        monokai-dimmed = {
          fg = "#c5c8c6";
          bg = "#1e1e1e";
          black = "#3b3a32";
          red = "#f92672";
          green = "#a6e22e";
          yellow = "#e6db74";
          blue = "#66d9ef";
          magenta = "#ae81ff";
          cyan = "#a1efe4";
          white = "#f8f8f2";
          orange = "#fd971f";
        };
      };
    };
  };

  programs.tmux = {
    enable = true;
    clock24 = true;
    mouse = true;
    terminal = "tmux-256color";
    extraConfig = ''
      # TrueColor Support
      set -ga terminal-overrides ",*256col*:Tc"

      # Powerline Monokai Dimmed Theme
      set -g status-style "bg=#1e1e1e,fg=#c5c8c6"
      
      # Protect status edges from aggressive mobile truncation
      set -g status-left-length 100
      set -g status-right-length 100
      set -g status-justify right
      
      # Define all styles as variables to completely eliminate comma parsing bugs
      set -g @host_start "#[fg=${hostColor},bg=#1e1e1e]#[fg=#1e1e1e,bg=${hostColor},bold] "
      set -g @host_end " #[fg=${hostColor},bg=#1e1e1e]"
      
      set -g @session_start " #[fg=#a6e22e,bg=#1e1e1e]#[fg=#1e1e1e,bg=#a6e22e,bold] "
      set -g @session_end " #[fg=#a6e22e,bg=#1e1e1e] "
      
      set -g @dot "#[fg=#555555,bg=#1e1e1e]•"
      set -g @pill_start "#[fg=#3b3a32,bg=#1e1e1e]#[fg=#c5c8c6,bg=#3b3a32] "
      set -g @pill_end " #[fg=#3b3a32,bg=#1e1e1e]"
      
      set -g @pill_cur_start "#[fg=#66d9ef,bg=#1e1e1e]#[fg=#1e1e1e,bg=#66d9ef,bold] "
      set -g @pill_cur_end " #[fg=#66d9ef,bg=#1e1e1e]"
      
      # Status Left (Host Name + Dynamic Session Name)
      set -g status-left "#{@host_start}#{=/10/…/:host_short}#{@host_end}#{@session_start}#{?#{e|<:#{client_width},#{e|+:60,#{e|*:13,#{session_windows}}}},#{=/10/…/:session_name},#{session_name}}#{@session_end}"

      # Window Tabs (Dynamic: Dots -> Truncated Pills -> Full Pills)
      set -g window-status-separator " "
      set -g window-status-format "#{?#{e|<:#{client_width},#{e|+:30,#{e|*:13,#{session_windows}}}},#{@dot},#{@pill_start}#I:#{?#{e|<:#{client_width},#{e|+:40,#{e|*:13,#{session_windows}}}},#{=/10/…/:window_name},#{window_name}}#{@pill_end}}"
      set -g window-status-current-format "#{@pill_cur_start}#I:#{?#{e|<:#{client_width},#{e|+:40,#{e|*:13,#{session_windows}}}},#{=/10/…/:window_name},#{window_name}}#{@pill_cur_end}"
      
      # Status Right (Empty, user relies on prompt clock)
      set -g status-right ""
      
      # Minimal borders
      set -g pane-border-style "fg=#3b3a32"
      set -g pane-active-border-style "fg=#66d9ef"
      
      # Mobile toggle hotkey (Prefix + b)
      bind-key b set-option status
    '';
  };

  programs.zsh = {
    enable = true;
    envExtra = ''
      export GEMINI_API_KEY="$(cat ${config.sops.secrets.google_ai_api_key.path})"
      export GOOGLE_AI_API_KEY="$(cat ${config.sops.secrets.google_ai_api_key.path})"
    '';
    initContent = ''
      # Ensure local bin is universally in the PATH
      export PATH="$HOME/.local/bin:$PATH"

      # Source home-manager session variables in non-login shells
      if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
      fi

      # Enable case-insensitive completion
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
    '';
    shellAliases = lib.optionalAttrs pkgs.stdenv.isLinux {
      nix-gens = "nixos-rebuild list-generations | (read -r header; echo \"$header\"; tac)";
    };
  };
  
  programs.git = {
    enable = true;
    settings = {
      init = {
        defaultBranch = "main";
      };
      user = {
        name = "dcronin05";
        email = "daniel@dcron.in";
      };
      safe = {
        directory = "${config.home.homeDirectory}";
      };
    };
  };
  
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        SetEnv = {
          TERM = "xterm-256color";
        };
      };
      "debian-vm" = {
        HostName = "100.125.115.8";
        User = "dcronin05";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };
      "tower" = {
        HostName = "100.79.77.74";
        User = "dcron";
      };
      "macmini" = {
        HostName = "100.117.198.24";
        User = "dcronin05";
      };
      "macbook" = {
        HostName = "100.76.154.2";
        User = "dcronin05";
      };
      "gpantz" = {
        HostName = "gpantz.castor.usbx.me";
        User = "gpantz";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };
      "pxe" = {
        HostName = "100.77.245.93";
        User = "root";
        Port = "2206";
      };
      "forge" = {
        HostName = "100.102.85.118";
        User = "dcronin05";
        Port = "2299";
      };
      "vps" = {
        HostName = "162.212.157.166";
        User = "dcronin05";
      };
      "nexus" = {
        HostName = "100.66.213.97";
        User = "dcronin05";
      };
    };
  };

  # SOPS Configuration for User Space
  sops.defaultSopsFile = ../secrets/secrets.yaml;
  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  sops.secrets.github_token = {};
  sops.secrets.google_ai_api_key = {};

  home.sessionVariables = {
  };

  # GitHub CLI and Auto-Authentication
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  # home.activation.ghAuth = config.lib.dag.entryAfter ["sops-nix"] ''
  #   $DRY_RUN_CMD ${pkgs.gh}/bin/gh auth login --with-token < ${config.sops.secrets.github_token.path}
  # '';
}
