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

### Step 1: 差分の確認と一覧取得

```bash
chezmoi diff
```

差分がなければ「同期済み」と報告して終了。

差分がある場合、出力から変更ファイルの一覧を抽出する。`diff --git a/<path> b/<path>` の行からターゲットパスを収集する。差分の種類も識別する：

- **内容の変更**: 通常の diff hunk がある
- **パーミッションのみの変更**: `old mode` / `new mode` 行のみ
- **新規ファイル**: `new file mode` がある
- **削除**: `deleted file mode` がある

### Step 2: ファイルごとの調査と方向確認

各ファイルについて以下を調査し、AskUserQuestion でまとめて方向を確認する。

#### 調査内容

1. `chezmoi diff -- ~/<target_path>` で個別の差分内容を確認
2. `chezmoi source-path ~/<target_path>` でソースパスを特定（`.tmpl` かどうかも判明する）
3. `git log --oneline -3 --follow -- <source_path>` でソース側の直近の変更履歴を確認

これらの情報を元に、差分の要約をまとめる。

#### AskUserQuestion で方向確認

AskUserQuestion は最大4問まで同時に送れるため、差分ファイルが多い場合は4ファイルずつバッチで質問する。

各質問には以下を含める：
- header: ファイル名（短縮形、最大12文字。例: `mise/config`）
- question: 差分の要約と git 履歴の参考情報。ユーザーが判断できる十分な情報を提供する
- options: 以下の3択

```
options:
  - label: "ホーム側を採用"
    description: "ホームの内容をソース（dotfiles）に取り込む"
  - label: "ソース側を採用"
    description: "ソースの内容をホームに適用する"
  - label: "スキップ"
    description: "このファイルは変更しない"
```

パーミッションのみの差分や、`run_onchange_` スクリプトの展開結果（ホームに生成されるが管理対象外）など、同期不要な差分はユーザーに報告しつつスキップを推奨する。

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

### Step 3: 同期の実行

ユーザーの選択に基づいて同期を実行する。

#### ホーム側を採用（ホーム → ソース）

**通常ファイルの場合：**

```bash
chezmoi re-add ~/<target_path>
```

`re-add` 直後に必ず `git diff -- <source_path>` で変更内容を確認する。`re-add` が空振りする場合がある（特にテンプレートファイル）ため、期待した変更がソースに反映されているか検証する。

**テンプレートファイル（.tmpl）の場合：**

`chezmoi re-add` はテンプレートファイルを正しく更新できないことがある。ソースファイルを直接編集する：

1. `chezmoi source-path ~/<target_path>` でソースパスを特定（`.tmpl` で終わるかを確認）
2. ソースファイルを Read で読む
3. ホームの実ファイル（`~/<target_path>`）の内容を Read で読む
4. Edit でソースファイルを更新
5. 末尾改行まで一致させる（`xxd <file> | tail` でバイト単位の確認が有効）

テンプレート構文（`{{ .variable }}`）が含まれるファイルは、展開後の値ではなくテンプレート構文を維持すること。

#### ソース側を採用（ソース → ホーム）

```bash
chezmoi apply ~/<target_path>
```

### Step 4: 検証

```bash
chezmoi diff
```

スキップしたファイル以外の差分が残っていないことを確認する。差分が残っている場合は原因を調査して対処する。

### Step 5: コミット（ソースに変更があった場合のみ）

ソース側に変更があった場合、`git status` を表示してコミットするか確認する。コミットは自動で行わず、ユーザーの指示を待つ。
