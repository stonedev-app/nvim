# Neovim 設定

## キーマッピング

`<leader>` キーはスペースキーです。

### Markdown プレビュー

`.md` ファイルを開いているときのみ有効です。

| キー | コマンド | 説明 |
|---|---|---|
| `Space` `m` `p` | `:MarkdownPreviewToggle` | ブラウザプレビューのオン/オフ |
| — | `:MarkdownPreview` | プレビュー開始 |
| — | `:MarkdownPreviewStop` | プレビュー停止 |

### Git (lazygit)

| キー | コマンド | 説明 |
|---|---|---|
| `Space` `g` `g` | `:LazyGit` | lazygit を開く（プロジェクト全体） |
| `Space` `g` `f` | `:LazyGitFilterCurrentFile` | 現在のファイルの Git 履歴を開く |

lazygit を閉じるときは `q` または `Ctrl+c` です。

#### インストール

lazygit 本体を事前にインストールしておく必要があります。

**macOS:**
```sh
brew install lazygit
```

**Windows:**
```sh
winget install JesseDuffield.lazygit
```

## インデント

ファイルの中身からインデントスタイル（タブ／スペース・幅）を自動検出します（VSCode の "Detect Indentation" 相当）。

| 状況 | 動作 |
|---|---|
| スペースで書かれたファイル | スペースでインデント（幅はファイルに合わせる） |
| タブで書かれたファイル（Makefile 等） | タブでインデント |
| 検出できない場合 | スペース 4 つにフォールバック |

プラグイン（`guess-indent.nvim`）は初回起動時に自動インストールされます。追加作業は不要です。
