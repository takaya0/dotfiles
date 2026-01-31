{ config, pkgs, ... }:

{
  imports = [
    ./shell/zsh.nix
    ./git.nix
    ./packages.nix
    ./vscode.nix
  ];

  home = {
    username = "yataka";
    homeDirectory = "/Users/yataka";
    stateVersion = "24.11";

    # Link dotfiles config files
    file = {
      ".claude/settings.json".source = ../config/claude/settings.json;
      ".claude/rules".source = ../config/claude/rules;
      ".claude/commands".source = ../config/claude/commands;
      ".claude/agents".source = ../config/claude/agents;
      ".claude/skills".source = ../config/claude/skills;
      "Library/Application Support/Code/User/settings.json".source = ../config/vscode/settings.json;
      "Library/Application Support/Cursor/User/settings.json".source = ../config/cursor/settings.json;
    };
  };

  # XDG Base Directory
  xdg = {
    enable = true;

    configFile = {
      "wezterm".source = ../config/wezterm;
      "zed/settings.json".source = ../config/zed/settings.json;
      "karabiner/karabiner.json".source = ../config/karabiner/karabiner.json;
      "mise/config.toml".source = ../config/mise/config.toml;
    };
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
