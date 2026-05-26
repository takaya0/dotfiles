---
name: chezmoi-sync
description: chezmoi で管理されたファイルのホームディレクトリとソース（dotfiles）間の同期を行う。差分確認、方向選択、ファイル単位の取り込み/スキップをサポート。「chezmoi同期」「ホームの設定を取り込む」「dotfilesを適用」「設定を同期」「ローカルの内容を取り込む」「chezmoi apply」「chezmoi diff」「設定ファイルの差分」などで起動。dotfiles リポジトリでの作業中に設定の同期が話題になったら積極的に使用する。
---

# chezmoi-sync

chezmoi のソースディレクトリ（dotfiles）とホームディレクトリ間でファイルを同期する。

## 前提知識

chezmoi は2つの場所を管理している：

| 場所 | 説明 | 例 |
|------|------|-----|
| ソース (source) | dotfiles リポジトリ内のファイル | `~/dotfiles/dot_zshrc` |
| ターゲット (destination) | ホームディレクトリの実ファイル | `~/.zshrc` |

`chezmoi diff` の出力は `diff -u <destination> <target>` 形式：
- `-` 行: 現在のホームディレクトリの内容
- `+` 行: ソースが適用した場合の内容（chezmoi apply した結果）

## ワークフロー

### Step 1: 差分の確認

```bash
chezmoi diff
```

差分がなければ「同期済み」と報告して終了。

### Step 2: 差分の分類

差分があるファイルごとに以下を調査する：

1. `chezmoi diff -- <target_path>` で個別の差分内容を確認
2. `git log --oneline --follow -- <source_path>` でソース側の変更履歴を確認
3. 差分の性質を判断する材料をユーザーに提示

差分には以下のパターンがある（**どちらが正しいかの判断はユーザーに委ねる**）：

| パターン | 例 | 説明 |
|---------|-----|------|
| ソースが新しい | Renovate がバージョン更新済み | ホームにまだ apply されていない |
| ホームが新しい | ユーザーが手動で設定変更 | ソースに取り込まれていない |
| 不明 | 両方変更されている | ユーザーの判断が必要 |

ソース側の git 履歴（Renovate PR、手動コミット等）は参考情報として提示するが、どちらが「正しい」かは断定しない。

### Step 3: ユーザーに同期方向を確認

変更があるファイルごとに AskUserQuestion で同期方向を確認する。AskUserQuestion は最大4問まで同時に送れるため、差分ファイルが多い場合は4ファイルずつバッチで質問する。

各質問には以下を含める：
- header: ファイル名（短縮形、例: `mise/config`）
- question: 差分の要約と git 履歴の参考情報を含めた説明。ユーザーが判断できる十分な情報を提供する
- options: 以下の3択

```
options:
  - label: "ホーム側を採用"
    description: "ホームの内容をソース（dotfiles）に取り込む（chezmoi re-add）"
  - label: "ソース側を採用"
    description: "ソースの内容をホームに適用する（chezmoi apply）"
  - label: "スキップ"
    description: "このファイルは変更しない"
```

例：

```javascript
AskUserQuestion({
  questions: [
    {
      question: "~/.config/mise/config.toml に差分があります。\n\nホーム: node=\"24.15.0\", ruby=\"4.0.3\"\nソース: node=\"24.16.0\", ruby=\"4.0.5\"\n\ngit履歴: Renovate PRでバージョン更新済み（#13, #15）",
      header: "mise/config",
      options: [
        { label: "ホーム側を採用", description: "ホームの内容をソースに取り込む" },
        { label: "ソース側を採用", description: "ソースの内容をホームに適用する" },
        { label: "スキップ", description: "このファイルは変更しない" }
      ],
      multiSelect: false
    },
    {
      question: "~/.claude/settings.json に差分があります。\n\nホーム: codex パーミッション /tmp/codex/、warp プラグインあり\nソース: codex パーミッション /tmp/codex_*、warp プラグインなし\n\ngit履歴: 27af1a7 で更新",
      header: "claude/settings",
      options: [
        { label: "ホーム側を採用", description: "ホームの内容をソースに取り込む" },
        { label: "ソース側を採用", description: "ソースの内容をホームに適用する" },
        { label: "スキップ", description: "このファイルは変更しない" }
      ],
      multiSelect: false
    }
  ]
})
```

### Step 4: 同期の実行

#### ホーム → ソース

通常ファイルの場合：

```bash
chezmoi re-add <target_path>
```

**テンプレートファイル（.tmpl）の場合、`re-add` では更新されない。** ソースファイルを直接編集する：

1. `chezmoi source-path <target_path>` でソースパスを特定
2. ソースファイルを Read で読む
3. ホームの実ファイルの内容と比較
4. Edit でソースファイルを更新
5. バイト単位で一致させる（末尾改行にも注意）

テンプレート構文（`{{ .variable }}`）が含まれるファイルは、展開後の値ではなくテンプレート構文を維持すること。

#### ソース → ホーム

```bash
chezmoi apply <target_path>
```

複数ファイルをまとめて適用する場合：

```bash
chezmoi apply
```

### Step 5: 検証

```bash
chezmoi diff
```

スキップしたファイル以外の差分が残っていないことを確認する。差分が残っている場合は原因を調査して対処する。

### Step 6: コミット（ソースに変更があった場合のみ）

ソース側に変更があった場合、`git status` を表示してコミットするか確認する。コミットは自動で行わず、ユーザーの指示を待つ。
