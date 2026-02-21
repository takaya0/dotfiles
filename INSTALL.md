# インストール手順

## 前提条件

- macOS (Apple Silicon)
- sudo権限

## ステップ1: Homebrewのインストール

ターミナルを開いて以下のコマンドを実行してください：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

インストール後、シェルにHomebrewのパスを追加します：

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

## ステップ2: dotfilesのクローン

```bash
git clone https://github.com/yataka/dotfiles.git ~/dotfiles
```

すでにクローン済みの場合はスキップ。

## ステップ3: chezmoiのインストールと適用

```bash
cd ~/dotfiles
./scripts/bootstrap.sh
```

このスクリプトは以下の処理を実行します：

1. `chezmoi` をHomebrewでインストール
2. `chezmoi init --source=~/dotfiles` で初期化
3. `chezmoi diff` で変更内容を確認
4. 確認後 `chezmoi apply` で設定を適用（Homebrewパッケージインストール含む）

## ステップ4: シェルの再起動

設定を反映するため、ターミナルを再起動してください：

```bash
exec zsh
```

## 検証

以下のコマンドで設定が正しく適用されているか確認できます：

### 1. 設定ファイルの確認

```bash
ls -la ~/.config/wezterm/
ls -la ~/.config/zed/
ls -la ~/.config/karabiner/
ls -la ~/.config/mise/
ls -la ~/.claude/
```

### 2. Homebrewパッケージの確認

```bash
which rg fd bat eza zoxide fzf delta jq yq gh mise
```

### 3. Git設定の確認

```bash
git config --global user.name
git config --global user.email
```

### 4. macOS設定の確認

```bash
defaults read com.apple.dock autohide
defaults read NSGlobalDomain KeyRepeat
```

## 設定の更新

dotfilesを変更した後は以下を実行：

```bash
chezmoi apply
```

変更内容を事前確認したい場合：

```bash
chezmoi diff
chezmoi apply
```

## トラブルシューティング

### chezmoi apply が失敗する

```bash
# 詳細ログで実行
chezmoi apply --verbose

# 差分のみ確認
chezmoi diff
```

### Homebrewパッケージが足りない

`.chezmoidata.yaml` の `brews` または `casks` にパッケージ名を追加し、再適用：

```bash
chezmoi apply
```

### Preztoが読み込まれない

chezmoiが `.zprezto` をgit-repoとして取得していない場合：

```bash
chezmoi update
```
