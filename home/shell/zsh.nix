{ config, ... }:

{
  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    dotDir = config.home.homeDirectory;

    # Prezto configuration
    prezto = {
      enable = true;
      caseSensitive = false;
      color = true;

      extraConfig = ''
        zstyle ':prezto:module:utility' safe-ops 'no'
      '';

      pmodules = [
        "environment"
        "terminal"
        "editor"
        "history"
        "directory"
        "spectrum"
        "utility"
        "completion"
        "git"
        "syntax-highlighting"
        "history-substring-search"
        "autosuggestions"
        "prompt"
      ];

      editor = {
        keymap = "vi";
        dotExpansion = true;
      };

      prompt = {
        theme = "pure";
      };

      syntaxHighlighting = {
        highlighters = [
          "main"
          "brackets"
          "pattern"
          "cursor"
        ];
      };
    };

    # Shell aliases
    shellAliases = {
      ls = "ls --color=auto";
      ll = "ls -lah";
      grep = "grep --color=auto";
      ".." = "cd ..";
      "..." = "cd ../..";
    };

    # Additional initialization
    initContent = ''
      # mise activation
      if command -v mise &> /dev/null; then
        eval "$(mise activate zsh)"
      fi

      # bun completions
      if [ -s "/Users/yataka/.bun/_bun" ]; then
        source "/Users/yataka/.bun/_bun"
      fi

      # Custom PATH additions
      export PATH="$HOME/.bun/bin:$PATH"
    '';
  };
}
