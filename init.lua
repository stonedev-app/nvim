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
  -- tokyonight.nvim
  -- カラースキーム（配色テーマ）
  -- -------------------------------------------------------------------------
  -- 役割：
  --   Neovim 全体の配色を設定する。背景・構文ハイライト・LSP フロートウィンドウ
  --   など Neovim のすべての UI に色がつき、視認性が大幅に向上する。
  --
  -- なぜ tokyonight にしたか：
  --   ・Neovim 向けに最適化されており、LSP・Treesitter との相性が良い
  --   ・深い紺背景にパープル・グリーン系のハイライトで目が疲れにくい
  --   ・Neovim コミュニティでの採用率が高く、他プラグインとの見た目の統一がとりやすい
  --
  -- GitHub: https://github.com/folke/tokyonight.nvim
  -- 必要環境: なし
  -- ===========================================================================
  {
    "folke/tokyonight.nvim",
    lazy = false,     -- 起動時に即読み込む（カラースキームは遅延読み込み不可）
    priority = 1000,  -- 他のプラグインより先に読み込んで配色を確定させる
    config = function()
      vim.cmd.colorscheme("tokyonight")
    end,
  },

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
      vim.fn["mkdp#util#install_sync"](1)
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

  -- ===========================================================================
  -- LSP（Language Server Protocol）: IDE 相当の定義ジャンプ・補完・参照を実現
  -- ---------------------------------------------------------------------------
  -- 役割：
  --   言語サーバー（clangd 等）と通信し、定義に飛ぶ（gd）・ホバードキュメント
  --   （K）・参照一覧（gr）・シンボルのリネーム（<leader>rn）を提供する。
  --   キーマップは後述の LspAttach autocmd で設定する。
  --
  -- なぜ LSP か（ctags ではなく）：
  --   ctags は静的なテキスト解析でタグファイルを生成するため手動更新が必要で、
  --   C++ のテンプレートやオーバーロードに弱い。LSP はコードを意味的に理解し
  --   リアルタイムで動作するため、精度と利便性が大きく上回る。
  --
  -- 3 プラグインの役割分担：
  --   mason.nvim          : LSP サーバーを Neovim 内から install/管理する GUI
  --                         （:Mason コマンドで操作できる）
  --   mason-lspconfig.nvim: mason と nvim-lspconfig を橋渡しし自動インストール
  --   nvim-lspconfig      : 各言語サーバーの設定を Neovim に読み込む
  --
  -- 言語を増やす場合：
  --   ensure_installed に追加 → lspconfig.<server>.setup({}) を追加するだけ
  --
  -- 必要環境: なし（mason が LSP サーバーを自動ダウンロードする）
  -- ===========================================================================
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- LSP サーバーのインストールと管理を Neovim 内で完結させる
      { "williamboman/mason.nvim", config = true },
      -- mason でインストールしたサーバーを lspconfig へ自動連携する
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      -- 使いたい LSP サーバーを列挙する（mason が自動でインストールする）
      -- 言語を増やす場合はここにサーバー名を追加するだけでよい
      require("mason-lspconfig").setup({
        ensure_installed = {
          "clangd",   -- C / C++（PlatformIO / Arduino を含む）
        },
      })

      -- clangd: C/C++ 向け LSP サーバー
      -- PlatformIO の場合は compile_commands.json が必要:
      --   プロジェクトルートで `pio run --target compiledb` を一度実行すること
      -- vim.lsp.enable は Neovim 0.11 の新 API。
      -- nvim-lspconfig がサーバーのデフォルト設定を vim.lsp.config に登録済みなので
      -- ここでは「有効化する」だけでよい（旧: require("lspconfig").clangd.setup({})）
      vim.lsp.enable("clangd")
    end,
  },

  -- ===========================================================================
  -- nvim-treesitter
  -- -------------------------------------------------------------------------
  -- 役割：
  --   ファイルの内容をシンタックスツリーとして解析し、正確な構文ハイライトと
  --   インデント補助を提供する。Neovim 組み込みの正規表現ベースのハイライトより
  --   正確で、ネストが深い構造や複雑な文法でも色が崩れにくい。
  --
  -- なぜ nvim-treesitter にしたか：
  --   ・Verilog（.v）は組み込みの正規表現ベースハイライトでは module 宣言・
  --     always ブロック・ポート一覧などが正しく色付けされないことが多い
  --   ・nvim-treesitter に "systemverilog" パーサーが公式収録されており、
  --     SystemVerilog は Verilog の上位互換なので .v ファイルにも適用できる
  --   ・Neovim 公式が推奨するハイライト基盤であり、tokyonight.nvim も
  --     Treesitter のトークングループに合わせて配色を最適化している
  --   ・将来的に他言語を追加する際も install() の引数にパーサー名を足すだけでよい
  --
  -- .v ファイルの filetype 判定について：
  --   Neovim は .v ファイルの中身を読んで filetype を自動判別する。
  --   行末に ; がある、または module 名( のパターンがあれば "verilog" と判定される。
  --   通常の Verilog ファイルであれば追加設定なしで本パーサーが適用される。
  --
  -- GitHub: https://github.com/nvim-treesitter/nvim-treesitter
  -- 必要環境: C コンパイラ（cc / gcc / clang）が PATH に存在すること
  --   macOS では Xcode Command Line Tools に付属（xcode-select --install で入る）
  --   パーサーの初回ビルド時のみ使用する。以降は不要。
  -- ===========================================================================
  {
    "nvim-treesitter/nvim-treesitter",

    -- パーサー（言語ごとの文法定義 .so ファイル）を更新するコマンド
    -- インストール・アップデート時に自動実行される
    build = ":TSUpdate",

    -- ファイルを開いたときに遅延読み込みする
    event = { "BufReadPost", "BufNewFile" },

    config = function()
      -- verilog パーサーが未インストールなら自動インストールする
      -- 新 API では ensure_installed は廃止。インストール関数を直接呼ぶ。
      -- systemverilog パーサーが未インストールなら自動インストールする
      -- 新 API では ensure_installed は廃止。インストール関数を直接呼ぶ。
      -- ※ 旧版の "verilog" パーサーは廃止済み。"systemverilog" が後継。
      local installed = require("nvim-treesitter.config").get_installed()
      if not vim.tbl_contains(installed, "systemverilog") then
        require("nvim-treesitter.install").install({ "systemverilog" }, { summary = true })
      end

      -- verilog ファイルを開いたとき Treesitter ハイライトを有効化する
      -- filetype は "verilog" だが、パーサーは "systemverilog" を明示的に指定する
      -- （SystemVerilog は Verilog の上位互換なので .v ファイルにも適用できる）
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "verilog",
        callback = function(ev)
          pcall(vim.treesitter.start, ev.buf, "systemverilog")
        end,
        desc = "verilog ファイルで Treesitter ハイライトを有効化",
      })
    end,
  },

})

-- =============================================================================
-- フロートウィンドウ設定
-- =============================================================================
-- Neovim 0.11 の winborder オプションで全フロートウィンドウに枠をつける
-- （LSP ホバー・診断・補完候補など、すべての浮き上がりウィンドウに適用される）
vim.o.winborder = "rounded"

-- =============================================================================
-- LSP キーマップ設定
-- =============================================================================
-- なぜ LspAttach autocmd 経由で書くのか：
--   LSP サーバーが接続されたバッファにだけ有効なキーマップを設定できる。
--   直接 vim.keymap.set で書くと「LSP が不要なバッファ」にも gd が割り当たり
--   意図しない動作を引き起こす恐れがある。
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local opts = { buffer = ev.buf }
    -- gd : 定義に移動（関数・型・変数の宣言箇所へジャンプ）
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    -- gr : 参照一覧を表示（この関数がどこで使われているかを一覧表示）
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    -- K  : ホバードキュメント表示（型情報・関数シグネチャ・説明を表示）
    vim.keymap.set("n", "K",  vim.lsp.buf.hover, opts)
    -- <leader>rn : シンボルのリネーム（参照箇所をまとめて一括変更）
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
  end,
  desc = "LSP が接続されたバッファにキーマップを設定",
})
