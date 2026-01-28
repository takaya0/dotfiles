{ ... }:

{
  homebrew = {
    enable = true;

    taps = [
      "homebrew/core"
      "homebrew/cask"
    ];

    onActivation = {
      cleanup = "zap"; # Uninstall all packages not listed below
      autoUpdate = true;
      upgrade = true;
    };

    # GUI Applications via Cask
    casks = [
      "blender"
      "cursor"
      "discord"
      "jetbrains-toolbox"
      "mactex-no-gui"
      "notion"
      "raycast"
      "tableplus"
      "unity-hub"
      "visual-studio-code"
      "wezterm@nightly"
      "zed"
    ];

    # Formulas that are not available in nixpkgs or need to be installed via Homebrew
    brews = [
      "yt-dlp"
    ];
  };
}
