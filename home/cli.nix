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
    w3m # Used by aerc to render HTML emails in the terminal
  ];

  
  # User-level terminal configurations
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    
    settings = {
      format = "$directory$git_branch$git_status$python$nodejs$c$docker_context$memory_usage$jobs$status$cmd_duration$time$battery$line_break$os$username$hostname$character";
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
      os = {
        disabled = false;
        format = "[$symbol]($style) ";
        symbols = {
          Linux = "";
          CachyOS = "";
          Ubuntu = "";
          Macos = "";
          Arch = "";
          NixOS = "";
          Windows = "";
        };
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

  # Ensure Home Manager manages ~/.tmux.conf directly to prevent legacy unmanaged ~/.tmux.conf
  # files (which may hardcode non-portable shell paths like /usr/bin/zsh) from taking precedence
  # over Home Manager's XDG tmux configuration (~/.config/tmux/tmux.conf).
  home.file.".tmux.conf".text = ''
    source-file ~/.config/tmux/tmux.conf
  '';

  programs.zsh = {
    enable = true;
    envExtra = ''
      export PATH="$HOME/.local/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
      export GEMINI_API_KEY="$(cat ${config.sops.secrets.google_ai_api_key.path})"
      export GOOGLE_AI_API_KEY="$(cat ${config.sops.secrets.google_ai_api_key.path})"
    '';
    initContent = ''

      # Source home-manager session variables in non-login shells
      if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
      fi

      # Auto-brand Zellij sessions with the hostname
      if [[ -n "$ZELLIJ" && -n "$ZELLIJ_SESSION_NAME" ]]; then
        local current_host="[$(print -Pn "%m")]"
        if [[ "$ZELLIJ_SESSION_NAME" != "$current_host"* ]]; then
          command zellij action rename-session "$current_host $ZELLIJ_SESSION_NAME" 2>/dev/null || true
          export ZELLIJ_SESSION_NAME="$current_host $ZELLIJ_SESSION_NAME"
        fi
      fi

      # Auto-name default Tmux sessions based on the initial directory
      if [[ -n "$TMUX" ]]; then
        local current_session
        current_session=$(tmux display-message -p '#S' 2>/dev/null)
        # If the session is just a number (the default tmux naming scheme)
        if [[ "$current_session" =~ ^[0-9]+$ ]]; then
          local dir_name=$(basename "$PWD")
          tmux rename-session "$dir_name" 2>/dev/null || true
        fi
      fi

      # Enable case-insensitive completion
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

      # Set terminal tab title to current directory when idle
      set_tab_title_precmd() {
        local formatted_dir
        formatted_dir=$(print -Pn "%~")
        # Only emit the title sequence if the state actually changed to prevent resize lag
        if [[ "$_LAST_TAB_TITLE" != "dir:$formatted_dir" ]]; then
          if [[ -n "$TMUX" ]]; then
            print -Pn "\ek$formatted_dir\e\\"
          elif [[ -n "$ZELLIJ" ]]; then
            print -Pn "\e]0;$formatted_dir\a"
          else
            print -Pn "\e]0;[%m] $formatted_dir\a"
          fi
          _LAST_TAB_TITLE="dir:$formatted_dir"
        fi
      }
      precmd_functions+=(set_tab_title_precmd)

      # Set terminal tab title to the running command
      set_tab_title_preexec() {
        local cmd="$1"
        if [[ "$_LAST_TAB_TITLE" != "cmd:$cmd" ]]; then
          if [[ -n "$TMUX" ]]; then
            print -Pn "\ek$cmd\e\\"
          elif [[ -n "$ZELLIJ" ]]; then
            print -Pn "\e]0;$cmd\a"
          else
            print -Pn "\e]0;[%m] $cmd\a"
          fi
          _LAST_TAB_TITLE="cmd:$cmd"
        fi
      }
      preexec_functions+=(set_tab_title_preexec)
    '';
    shellAliases = lib.optionalAttrs pkgs.stdenv.isLinux {
      nix-gens = "nixos-rebuild list-generations | (read -r header; echo \"$header\"; tac)";
    };
  };
  
  programs.lsd = {
    enable = true;
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

  programs.aerc = {
    enable = true;
    extraConfig = {
      general = {
        # Because Home Manager symlinks configuration files into the read-only Nix Store,
        # aerc's default strict permission check (which requires 0600 permissions on accounts.conf)
        # fails and prevents aerc from starting.
        # We bypass this check using unsafe-accounts-conf = true. This is completely safe
        # here because we are using passwordCommand to dynamically pull the password from SOPS
        # at runtime, meaning no plain text secrets are actually stored in the 0444 accounts.conf.
        unsafe-accounts-conf = true;
      };
      ui = {
        sidebar-width = 25;
        sort = "-r date";
        dirlist-delay = "200ms";
      };
      viewer = {
        pager = "less -R";
        alternatives = "text/plain,text/html";
      };
      filters = {
        # Restore the default aerc filters that got wiped out by Home Manager
        "text/plain" = "wrap -w 100 | colorize";
        "text/html" = "w3m -T text/html -dump | colorize";
      };
    };
  };

  # Fastmail JMAP template (commented out for future use, securely load password from sops)
  /*
  accounts.email.accounts.fastmail = {
    primary = false;
    address = "daniel@dcron.in";
    userName = "daniel@dcron.in";
    realName = "Daniel Cronin";
    passwordCommand = "cat ${config.sops.secrets.fastmail_app_password.path}";
    aerc = {
      enable = true;
      extraAccounts = {
        source = "jmap://daniel%40dcron.in@api.fastmail.com/jmap/";
        outgoing = "smtp+plain://daniel%40dcron.in@smtp.fastmail.com:465";
      };
    };
  };
  */

  accounts.email.accounts.gmail = {
    primary = true;
    # Using the 'gmail.com' flavor auto-configures standard IMAP/SMTP endpoints for Gmail
    flavor = "gmail.com";
    address = "dcronin05@gmail.com";
    userName = "dcronin05@gmail.com";
    realName = "Daniel Cronin";
    # Google requires an App Password for IMAP/SMTP (standard passwords will not work).
    # Save it to your secrets.yaml file!
    # The command runs at runtime so the plain text password is never baked into the Nix store
    passwordCommand = "cat ${config.sops.secrets.gmail_app_password.path}";
    aerc = {
      # Automatically integrates this email account into the aerc UI
      enable = true;
    };
  };

  # SOPS Configuration for User Space
  sops.defaultSopsFile = ../secrets/secrets.yaml;
  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  sops.secrets.github_token = {};
  sops.secrets.google_ai_api_key = {};
  sops.secrets.gmail_app_password = {};

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
