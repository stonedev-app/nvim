-- =============================================================================
-- エディタ基本設定
-- =============================================================================

-- ---------------------------------------------------------------------------
-- インデント設定（静的デフォルト・フォールバック値）
-- ---------------------------------------------------------------------------
-- これは「他に何も指示がない時の基準値」として機能する。
-- 実際にファイルを開くと、後段で動く下記の仕組みが必要に応じて上書きする：
--   1. ファイルタイプ別プラグイン（Makefile を tab 強制にする等）
--   2. .editorconfig（プロジェクトに置いてあれば Neovim が自動で読む）
--   3. guess-indent.nvim（ファイル内容を見て実際のインデントに合わせる）
--
-- なぜこの設定が必要か：
--   Neovim の素のデフォルトは「タブ文字でインデント」。
--   現代の多くのプロジェクト（特に C++/Python/JS など）はスペース派が主流で、
--   タブ派ファイルにスペースが混ざる/その逆 が起きると差分がぐちゃぐちゃになる。
--   そこでスペースに統一した上で、必要なファイルだけ後段で上書きする方針にする。
--
-- なぜ全部 4 で揃えるか：
--   tabstop と shiftwidth が違うと「見た目の幅」と「実際のインデント幅」が
--   ズレて事故るため、同じ値にするのが定石。
--   4 は C++/Java/Python など多くの言語のデファクト。
--   2 スペース派のファイル（YAML, JS など）は guess-indent.nvim が自動で 2 に直す。
vim.opt.expandtab   = true  -- Tab キーや自動インデントで「タブ文字」ではなく「スペース」を挿入する
vim.opt.tabstop     = 4     -- 既存ファイル内のタブ文字 1 個を画面上で何スペース幅に見せるか
vim.opt.shiftwidth  = 4     -- 自動インデント 1 段階のスペース数（o / O / >> / << / == で使う値）
vim.opt.softtabstop = 4     -- Tab キーを押したときに挿入されるスペースの数（expandtab と組で使う）

-- ---------------------------------------------------------------------------
-- コメント自動継続を無効化
-- ---------------------------------------------------------------------------
-- なぜこの設定を入れるか：
--   Neovim はデフォルトで、コメント行（// 〜 や -- 〜 など）で
--   o / O / Enter を押すと、新しい行の先頭にも自動でコメント記号を
--   挿入する。これは「複数行コメントを続けて書く」場面では便利だが、
--   実際には「コメントの下にコードを書きたい」場面の方が圧倒的に多く、
--   毎回コメント記号を消す手間が発生する。そこで自動継続だけを切る。
--
-- 外すフラグ：
--   r : Insert モードで Enter を押したときのコメント継続
--   o : Normal モードで o / O を押したときのコメント継続
--   ※ c（コメント内自動改行）と j（J で結合時に記号を消す）は便利なので残す
--
-- なぜ autocmd 経由で書くのか：
--   ここで素朴に vim.opt.formatoptions:remove({"r","o"}) と書いても、
--   ファイルを開いた瞬間に Neovim 同梱の filetype プラグイン
--   （$VIMRUNTIME/ftplugin/c.vim 等）が formatoptions を setlocal で
--   上書きするため、起動時に外したフラグが復活してしまう。
--   FileType イベントは ftplugin の後に発火するので、そこで再度外す。
--
-- なぜ vim.opt_local を使うか：
--   ftplugin は :setlocal で buffer-local に設定する。これを上書きするには
--   同じ buffer-local スコープ（vim.opt_local）で外す必要がある。
--   vim.opt（global）で外しても、buffer-local 値が残り効かない。
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    vim.opt_local.formatoptions:remove({ "r", "o" })
  end,
  desc = "コメント行の次の行に自動でコメント記号を挿入しない",
})

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
  -- 必要環境: なし（事前ビルド済みバイナリを自動ダウンロードする方式を使用）
  -- ===========================================================================
  {
    "iamcco/markdown-preview.nvim",

    -- このコマンドを実行したときにプラグインを読み込む（遅延読み込み）
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },

    -- マークダウンファイルを開いたときだけ読み込む（他のファイルタイプでは不要）
    ft = { "markdown" },

    -- 初回インストール時にプラグイン公式の install 関数を実行する
    -- 事前ビルド済みバイナリをダウンロードするため Node.js / npm 不要
    -- （npm install 方式だと yarn.lock の差分検知エラーが発生するため避ける）
    build = function()
      -- ビルド時点ではプラグインの autoload 関数が未ロードなので
      -- :Lazy load で先にプラグインを読み込んでから install 関数を呼ぶ
      vim.cmd([[Lazy load markdown-preview.nvim]])
      vim.fn["mkdp#util#install"]()
    end,

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
        "<leader>gf",                             -- キー: スペース + g + f
        "<cmd>LazyGitFilterCurrentFile<cr>",      -- 現在のファイルを変更したコミットだけに絞って表示
        desc = "LazyGit Current File",
      },
    },
  },

  -- ===========================================================================
  -- guess-indent.nvim
  -- -------------------------------------------------------------------------
  -- 役割：
  --   ファイルを開いたとき、中身を見てインデントスタイル（タブかスペースか・
  --   何スペース幅か）を自動推測し、tabstop / shiftwidth / expandtab を
  --   そのファイルに合うように上書きしてくれる。
  --   VSCode の "Detect Indentation from content" と同じ体験を Neovim で実現する。
  --
  -- なぜ入れるか：
  --   init.lua の静的デフォルトだけだと、たとえば「2スペースで書かれた YAML」を
  --   開いても 4 スペースで上書きしてしまい、既存ファイルとインデントが混ざる。
  --   このプラグインがあると「開いたファイルの流儀に合わせる」が自動で実現する。
  --
  -- なぜ guess-indent.nvim にしたか（vim-sleuth ではなく）：
  --   ・純 Lua 製で本 init.lua の他のコードと書きぶりが揃う
  --   ・1ms 以下で動くため起動が遅くならない
  --   ・依存ゼロ・設定ゼロで運用が楽
  --   ・vim-sleuth は Vimscript 製で歴史があるが、今回は新規導入なので Lua 版を採用
  --
  -- 検出できなかった場合：
  --   init.lua のデフォルト値（4 スペース）にフォールバックする。
  --
  -- GitHub: https://github.com/NMAC427/guess-indent.nvim
  -- 必要環境: なし（Lua 製・依存ゼロ・外部バイナリ不要・Windows でも動く）
  -- ===========================================================================
  {
    "NMAC427/guess-indent.nvim",

    -- 「ファイルを開いた直後」に動かしたいので、そのタイミングで遅延読み込みする
    --   BufReadPost : 既存ファイルを読み込み完了した直後（ここで中身をスキャン）
    --   BufNewFile  : 新規ファイルを開いた直後（中身は空なので何もしないが念のため）
    event = { "BufReadPost", "BufNewFile" },

    -- セットアップを呼ぶだけ。設定はデフォルトのままで十分使える。
    -- （カスタマイズしたい場合は setup({ ... }) の中にオプションを書く）
    config = function()
      require("guess-indent").setup({})
    end,
  },

})
