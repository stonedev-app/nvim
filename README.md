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
| `Space` `g` `f` | `:LazyGitCurrentFile` | 現在のファイルの Git 履歴を開く |

lazygit を閉じるときは `q` または `Ctrl+c` です。
