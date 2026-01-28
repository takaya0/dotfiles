{ pkgs, ... }:

{
  imports = [
    ./homebrew.nix
  ];

  # Determinate Nix manages the daemon; disable nix-darwin management
  nix.enable = false;

  # Primary user for system-activated settings
  system.primaryUser = "yataka";

  # macOS system settings
  system = {
    stateVersion = 5;

    defaults = {
      dock = {
        autohide = false;
        show-recents = false;
        mru-spaces = false;
      };

      finder = {
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
        QuitMenuItem = true;
      };

      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        "com.apple.swipescrolldirection" = false;
      };
    };
  };

  # Packages available to all users
  environment.systemPackages = with pkgs; [
    vim
  ];

  # Shell configuration
  programs.zsh.enable = true;

  # User configuration
  users.users.yataka = {
    name = "yataka";
    home = "/Users/yataka";
  };
}
