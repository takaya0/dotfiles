{ lib, ... }:

{
  # Install VS Code extensions via CLI on activation.
  home.activation.installVscodeExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    code_bin="code"
    if ! command -v "$code_bin" >/dev/null 2>&1; then
      if [ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
        code_bin="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
      else
        code_bin=""
      fi
    fi

    if [ -n "$code_bin" ]; then
      extensions=(
        "anthropic.claude-code"
        "atsushieno.language-review"
        "charliermarsh.ruff"
        "docker.docker"
        "github.copilot"
        "github.copilot-chat"
        "github.vscode-github-actions"
        "github.vscode-pull-request-github"
        "graphql.vscode-graphql-syntax"
        "hediet.vscode-drawio"
        "ms-azuretools.vscode-containers"
        "ms-azuretools.vscode-docker"
        "ms-python.debugpy"
        "ms-python.python"
        "ms-python.vscode-pylance"
        "ms-python.vscode-python-envs"
        "ms-vscode-remote.remote-containers"
        "yoavbls.pretty-ts-errors"
      )

      for ext in "''${extensions[@]}"; do
        "$code_bin" --install-extension "$ext" >/dev/null 2>&1 || true
      done
    fi
  '';
}
