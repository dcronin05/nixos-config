{ config, pkgs, lib, ... }:

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
        style = "bold #66d9ef";
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
  programs.zsh = {
    enable = true;
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
      };
      "pxe" = {
        HostName = "dcron.in";
        User = "root";
        Port = "2206";
      };
      "tower-wsl" = {
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

  # GitHub CLI and Auto-Authentication
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  # home.activation.ghAuth = config.lib.dag.entryAfter ["sops-nix"] ''
  #   $DRY_RUN_CMD ${pkgs.gh}/bin/gh auth login --with-token < ${config.sops.secrets.github_token.path}
  # '';
}
