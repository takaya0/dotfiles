{ pkgs, ... }:

{
  imports = [
    ./homebrew.nix
  ];

  # Enable experimental features
  nix.settings.experimental-features = "nix-command flakes";

  # Auto upgrade nix package and the daemon service
  services.nix-daemon.enable = true;

  # macOS system settings
  system = {
    stateVersion = 5;

    defaults = {
      dock = {
        autohide = true;
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
