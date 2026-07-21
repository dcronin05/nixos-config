{ config, pkgs, ... }:

{
  home.stateVersion = "24.05";
  
  # User-level terminal configurations
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    
    settings = {
      format = "$username$hostname$git_branch$git_status$python$nodejs$c$docker_context$memory_usage$jobs$status$cmd_duration$time$battery$line_break$directory$character";
      add_newline = true;
      username = {
        show_always = true;
        style_user = "bold #bb9af7";
        style_root = "bold #f7768e";
        format = "[$user]($style)";
      };
      hostname = {
        ssh_only = false;
        style = "bold #7dcfff";
        format = "@[$hostname]($style) ";
      };
      directory = {
        style = "bold #7aa2f7";
        format = "[ $path]($style) ";
        truncation_length = 4;
        truncation_symbol = "…/";
      };
      git_branch = {
        symbol = " ";
        style = "bold #9ece6a";
        format = "on [$symbol$branch]($style) ";
      };
      git_status = {
        style = "#9ece6a";
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
        style = "bold #e0af68";
        format = "via [$symbol$version]($style) ";
      };
      nodejs = {
        symbol = " ";
        style = "bold #9ece6a";
        format = "via [$symbol$version]($style) ";
      };
      c = {
        symbol = " ";
        style = "bold #7dcfff";
        format = "via [$symbol$version]($style) ";
      };
      docker_context = {
        symbol = " ";
        style = "bold #7aa2f7";
        format = "docker [$symbol$context]($style) ";
      };
      memory_usage = {
        disabled = false;
        threshold = -1;
        symbol = "󰍛 ";
        style = "bold #ff9e64";
        format = "using [$symbol$ram]($style) ";
      };
      jobs = {
        symbol = " ";
        style = "bold #7aa2f7";
        format = "with [$symbol$number suspended]($style) ";
      };
      status = {
        disabled = false;
        style = "bold #f7768e";
        format = "exited [$symbol$int]($style) ";
        symbol = "✘ ";
      };
      cmd_duration = {
        min_time = 2000;
        style = "bold #e0af68";
        format = "took [ $duration]($style) ";
      };
      time = {
        disabled = false;
        time_format = "%R";
        style = "#7aa2f7";
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
        success_symbol = "[❯](bold #bb9af7)";
        error_symbol = "[✗](bold #f7768e)";
      };
      line_break = {
        disabled = false;
      };
    };
  };
  programs.zellij.enable = true;
  programs.zsh.enable = true;
  
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "dcronin05";
        email = "daniel@dcron.in";
      };
      safe = {
        directory = "/home/dcronin05";
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
      "wsl" = {
        HostName = "100.79.77.74";
        User = "dcronin05";
        Port = "2299";
      };
      "vps" = {
        HostName = "162.212.157.166";
        User = "dcronin05";
      };
      "nix" = {
        HostName = "192.168.1.170";
        User = "dcronin05";
      };
    };
  };
}
