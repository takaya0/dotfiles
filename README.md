# dotfiles

macOS環境をNix + nix-darwin + Home Managerで宣言的に管理するdotfilesリポジトリ。

## 🎯 特徴

- **nix-darwin**: macOSシステム設定を宣言的に管理
- **Home Manager**: ユーザー環境とdotfilesを管理
- **Homebrew統合**: GUI アプリケーションは Homebrew Cask で管理
- **mise**: 言語ランタイムのバージョン管理

## 📁 構成

```
dotfiles/
├── flake.nix              # Nixエントリポイント
├── darwin/                # nix-darwin設定
│   ├── default.nix        # システム設定
│   └── homebrew.nix       # Homebrew管理
├── home/                  # Home Manager設定
│   ├── default.nix        # ユーザー環境
│   ├── git.nix            # Git設定
│   ├── packages.nix       # CLIツール
│   └── shell/
│       └── zsh.nix        # zsh + prezto設定
├── config/                # 設定ファイル
│   ├── wezterm/           # WezTerm設定
│   ├── zed/               # Zed設定
│   ├── karabiner/         # Karabiner設定
│   ├── mise/              # mise設定
│   └── claude/            # Claude Code設定
└── scripts/
    └── bootstrap.sh       # 初回セットアップ
```

## 🚀 セットアップ

### 1. Nixのインストール

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### 2. dotfilesのクローンと適用

```bash
cd ~/dotfiles
./scripts/bootstrap.sh
```

### 3. シェルの再起動

```bash
exec zsh
```

## 🔄 設定の更新

```bash
# dotfilesを編集後
darwin-rebuild switch --flake ~/dotfiles

# flake.lockを更新
nix flake update
darwin-rebuild switch --flake ~/dotfiles
```

## 📦 パッケージ管理方針

| カテゴリ | 管理方法 | 設定場所 |
|---------|---------|----------|
| CLIツール | Nix | `home/packages.nix` |
| 言語ランタイム | mise | `config/mise/config.toml` |
| GUIアプリ | Homebrew Cask | `darwin/homebrew.nix` |
| macOS固有CLI | Homebrew | `darwin/homebrew.nix` |

## 🛠️ 設定ファイルの編集

設定ファイルは `config/` 以下で管理され、Home Managerによって自動的にリンクされます。

- **WezTerm**: `config/wezterm/*.lua`
- **Zed**: `config/zed/settings.json`
- **Karabiner**: `config/karabiner/karabiner.json`
- **mise**: `config/mise/config.toml`
- **Claude Code**: `config/claude/`

## 📝 トラブルシューティング

### Homebrewパッケージが自動削除される

`darwin/homebrew.nix` の `onActivation.cleanup = "zap"` により、宣言されていないパッケージは自動削除されます。保持したいパッケージは `casks` または `brews` に追加してください。

### シンボリックリンクが正しく作成されない

```bash
# リンクの確認
ls -la ~/.config/wezterm
ls -la ~/.claude

# 再適用
darwin-rebuild switch --flake ~/dotfiles
```

## 🔗 参考リンク

- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [Home Manager](https://github.com/nix-community/home-manager)
- [nix-homebrew](https://github.com/zhaofengli-wip/nix-homebrew)