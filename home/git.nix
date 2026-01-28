{ ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "yataka";
        email = "ytk.koizumi@gmail.com";
      };

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

      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        lg = "log --graph --oneline --all --decorate";
      };
    };
  };
}
