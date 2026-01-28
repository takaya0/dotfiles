{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Modern CLI tools
    ripgrep     # Fast grep alternative
    fd          # Fast find alternative
    bat         # Cat with syntax highlighting
    eza         # Modern ls alternative
    zoxide      # Smart cd
    fzf         # Fuzzy finder
    delta       # Git diff viewer

    # Development tools
    jq          # JSON processor
    yq-go       # YAML processor
    gh          # GitHub CLI
    mise        # Runtime version manager

    # System utilities
    htop        # Process viewer
    tree        # Directory tree viewer
    wget        # File downloader
    curl        # HTTP client

    # Archive tools
    unzip
    gzip

    # Other utilities
    tldr        # Simplified man pages
    direnv      # Directory-based environment variables
  ];
}
