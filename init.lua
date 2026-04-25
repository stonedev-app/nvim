-- =============================================================================
-- キーマッピング基本設定
-- =============================================================================

-- <leader> キーをスペースに変更
-- デフォルトは \ だが、スペースの方が押しやすいため変更する
-- ※ lazy.nvim の読み込みより前に設定する必要がある
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- =============================================================================
-- lazy.nvim ブートストラップ
-- nvim起動時に毎回実行され、lazy.nvim本体がなければ自動でダウンロードする
-- stdpath("data") は Macなら ~/.local/share/nvim に相当する
-- =============================================================================

-- lazy.nvimのインストール先パスを決める
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- lazy.nvim がまだインストールされていなければ git clone する
-- 2回目以降の起動ではここはスキップされる
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone",
    "--filter=blob:none",          -- 必要なファイルだけ取得（高速化）
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",             -- 安定版を使う
    lazypath,                      -- クローン先
  })
end

-- lazy.nvimのパスをnvimのランタイムパスの先頭に追加する
-- これをしないとnvimがlazy.nvimを認識できない
vim.opt.rtp:prepend(lazypath)

-- =============================================================================
-- プラグイン定義
-- ここに { } でプラグインを足していく
-- =============================================================================
require("lazy").setup({

  -- ===========================================================================
  -- markdown-preview.nvim
  -- マークダウンファイルをブラウザでリアルタイムプレビューするプラグイン
  -- Neovimでの編集内容がブラウザに即時反映され、スクロール位置も同期される
  -- GitHub: https://github.com/iamcco/markdown-preview.nvim
  -- 必要環境: Node.js（初回インストール時に npm install が実行される）
  --   未インストールの場合: brew install node
  -- ===========================================================================
  {
    "iamcco/markdown-preview.nvim",

    -- このコマンドを実行したときにプラグインを読み込む（遅延読み込み）
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },

    -- マークダウンファイルを開いたときだけ読み込む（他のファイルタイプでは不要）
    ft = { "markdown" },

    -- 初回インストール時に自動でビルドする（プラグイン内部の依存パッケージを取得）
    -- ここを実行しないとプレビューサーバーが起動しない
    build = "cd app && npm install",

    -- プラグイン読み込み前に実行する初期設定
    init = function()
      -- プレビュー対象のファイルタイプを指定（markdown のみ）
      vim.g.mkdp_filetypes = { "markdown" }
    end,

    -- キーマッピング（マークダウンファイルを開いているときだけ有効）
    -- 主なコマンド:
    --   :MarkdownPreview       → プレビュー開始（ブラウザが自動で開く）
    --   :MarkdownPreviewStop   → プレビュー停止
    --   :MarkdownPreviewToggle → トグル（下のキーマップでも同じ操作ができる）
    keys = {
      {
        "<leader>mp",                      -- キー: スペース + m + p
        "<cmd>MarkdownPreviewToggle<cr>",  -- プレビューのオン/オフをトグル
        ft = "markdown",                   -- マークダウンファイルを開いているときのみ有効
        desc = "Markdown Preview Toggle",  -- which-key などで表示される説明
      },
    },
  },

  -- ===========================================================================
  -- lazygit.nvim
  -- Neovim のフローティングウィンドウで lazygit を開くプラグイン
  -- ファイル編集中にそのまま Git 操作ができ、閉じると元のバッファに戻れる
  -- GitHub: https://github.com/kdheepak/lazygit.nvim
  -- 必要環境: lazygit がインストール済みであること
  --   未インストールの場合: brew install lazygit
  -- ===========================================================================
  {
    "kdheepak/lazygit.nvim",

    -- このコマンドを実行したときにプラグインを読み込む（遅延読み込み）
    cmd = {
      "LazyGit",               -- lazygit をフローティングウィンドウで開く
      "LazyGitConfig",         -- lazygit の設定ファイルを開く
      "LazyGitCurrentFile",    -- 現在のファイルの Git ログを開く
      "LazyGitFilter",         -- プロジェクトの Git ログを開く
      "LazyGitFilterCurrentFile", -- 現在のファイルの Git ログをフィルタして開く
    },

    -- plenary.nvim は Neovim プラグイン開発用のユーティリティライブラリ
    -- lazygit.nvim が内部で使用するため自動でインストールされる
    dependencies = {
      "nvim-lua/plenary.nvim",
    },

    -- キーマッピング
    keys = {
      {
        "<leader>gg",          -- キー: スペース + g + g
        "<cmd>LazyGit<cr>",    -- lazygit をフローティングウィンドウで開く
        desc = "LazyGit",
      },
      {
        "<leader>gf",                       -- キー: スペース + g + f
        "<cmd>LazyGitCurrentFile<cr>",      -- 現在のファイルの Git ログを表示
        desc = "LazyGit Current File",
      },
    },
  },

})
