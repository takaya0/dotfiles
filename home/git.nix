{ ... }:

{
  programs.git = {
    enable = true;

    userName = "yataka";
    userEmail = "ytk.koizumi@gmail.com";

    extraConfig = {
      init = {
        defaultBranch = "main";
      };

      pull = {
        rebase = false;
      };

      core = {
        editor = "vim";
        autocrlf = "input";
      };

      color = {
        ui = "auto";
      };
    };

    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      lg = "log --graph --oneline --all --decorate";
    };
  };
}
