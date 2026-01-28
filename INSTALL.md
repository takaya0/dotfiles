# インストール手順

## 前提条件

- macOS (Apple Silicon)
- sudo権限

## ステップ1: Nixのインストール

ターミナルを開いて以下のコマンドを実行してください：

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

インストール中にパスワードの入力を求められます。

インストールが完了したら、ターミナルを再起動してください：

```bash
exec zsh
```

## ステップ2: Nixが正しくインストールされたか確認

```bash
nix --version
```

バージョン情報が表示されれば成功です。

## ステップ3: nix-darwinの初回適用

dotfilesディレクトリで以下のコマンドを実行してください：

```bash
cd ~/dotfiles
./scripts/bootstrap.sh
```

このスクリプトは以下の処理を実行します：

1. `nix flake update` - 依存関係のロック
2. `nix run nix-darwin -- switch --flake .` - nix-darwinの初回ビルドと適用

## ステップ4: シェルの再起動

設定を反映するため、ターミナルを再起動してください：

```bash
exec zsh
```

## 検証

以下のコマンドで設定が正しく適用されているか確認できます：

### 1. シンボリックリンクの確認

```bash
ls -la ~/.config/wezterm/
ls -la ~/.config/zed/
ls -la ~/.claude/
```

dotfilesリポジトリへのシンボリックリンクが作成されているはずです。

### 2. Homebrewパッケージの確認

```bash
brew list --cask
```

`darwin/homebrew.nix`で宣言したCaskがインストールされているはずです。

### 3. Nixパッケージの確認

```bash
which rg
which fd
which bat
```

これらのコマンドが `/nix/store/` 配下を指しているはずです。

### 4. zsh + preztoの確認

```bash
echo $SHELL
```

`/run/current-system/sw/bin/zsh` が表示されるはずです。

## トラブルシューティング

### 「darwin-rebuild: command not found」と表示される

パスが正しく設定されていない可能性があります。

```bash
# パスを確認
echo $PATH

# シェルを再起動
exec zsh
```

それでも解決しない場合は、以下のコマンドでパスを手動で追加してください：

```bash
export PATH="/run/current-system/sw/bin:$PATH"
```

### Homebrewパッケージが削除される

`darwin/homebrew.nix` の `onActivation.cleanup = "zap"` により、宣言されていないパッケージは自動削除されます。保持したいパッケージは `darwin/homebrew.nix` の `casks` または `brews` に追加してください。

### 設定が反映されない

```bash
# 設定を再適用
darwin-rebuild switch --flake ~/dotfiles

# より詳細なログを表示
darwin-rebuild switch --flake ~/dotfiles --show-trace
```

## 次のステップ

設定を変更した場合は、以下のコマンドで反映できます：

```bash
darwin-rebuild switch --flake ~/dotfiles
```

依存関係を更新する場合は：

```bash
cd ~/dotfiles
nix flake update
darwin-rebuild switch --flake ~/dotfiles
```
