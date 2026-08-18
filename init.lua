-- =============================================================================
-- エディタ基本設定
-- =============================================================================

-- 行番号を表示する
vim.opt.number = true

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
  -- 必要環境: Node.js（プレビュー用バイナリのインストールに必要）
  -- ===========================================================================
  {
    "iamcco/markdown-preview.nvim",

    -- このコマンドを実行したときにプラグインを読み込む（遅延読み込み）
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },

    -- マークダウンファイルを開いたときだけ読み込む（他のファイルタイプでは不要）
    ft = { "markdown" },

    -- 初回インストール時にプラグイン公式の install 関数を実行する
    -- install_sync はプレビュー用バイナリをダウンロードする方式（要 Node.js）
    -- （npm install 方式だと yarn.lock の差分検知エラーが発生するため避ける）
    build = function()
      -- ビルド時点ではプラグインの autoload 関数が未ロードなので
      -- lazy.nvim の load() で先にプラグインを読み込んでから install 関数を呼ぶ
      require("lazy").load({ plugins = { "markdown-preview.nvim" } })
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
  --   ensure_installed に追加 → vim.lsp.enable("<server>") を追加するだけ
  --
  -- ただし rust-analyzer は例外的に mason 管理にしない：
  --   rustup がツールチェインの一部として rust-analyzer を管理しており
  --   （rustup component add rust-analyzer）、rustup update で rustc 本体と
  --   バージョンが同期される。mason にも重複インストールさせると二重管理に
  --   なるため、ensure_installed には加えず PATH 上の rust-analyzer
  --   （rustup 管理）を nvim-lspconfig のデフォルト設定でそのまま使う。
  --
  -- 必要環境:
  --   ・mason 管理のサーバー（clangd 等）: なし（mason が自動ダウンロード）
  --   ・rust-analyzer: rustup で Rust ツールチェインをインストール済みであること
  --     （rustup component add rust-analyzer で追加。詳細は README.md 参照）
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
      -- PlatformIO/ESP-IDFは独自パスのgcc（xtensa/riscv32等）を使うため、
      -- --query-driver で許可しないとシステムインクルードが解決できない
      -- （未許可だと stdlib.h 等が file not found になる）
      -- PlatformIO: compile_commands.jsonはコンパイラをベア名で書くため、
      --   cmd_env.PATH で toolchain-*/bin を解決させる必要がある
      --   （生成には `pio run --target compiledb` が必要）
      -- ESP-IDF (eim): `idf.py build` で build/compile_commands.json が
      --   自動生成され、コンパイラはフルパスで書かれるためPATH解決は不要
      vim.lsp.config("clangd", {
        cmd = {
          "clangd",
          "--query-driver=" .. vim.uv.os_homedir() .. "/.platformio/packages/**/bin/*,"
            .. vim.uv.os_homedir() .. "/.espressif/tools/*/*/*/bin/*",
        },
        cmd_env = {
          PATH = table.concat(
            vim.fn.glob(vim.uv.os_homedir() .. "/.platformio/packages/toolchain-*/bin", false, true),
            ":"
          ) .. ":" .. (vim.env.PATH or ""),
        },
      })
      -- vim.lsp.enable は Neovim 0.11 の新 API。
      -- nvim-lspconfig がサーバーのデフォルト設定を vim.lsp.config に登録済みなので
      -- ここでは「有効化する」だけでよい（旧: require("lspconfig").clangd.setup({})）
      vim.lsp.enable("clangd")

      -- rust-analyzer: Rust 向け LSP サーバー
      -- clangd と違い query-driver のような特殊設定は不要で、Cargo.toml のある
      -- ディレクトリを自動で root_dir として認識してくれる（nvim-lspconfig の
      -- デフォルト設定のまま使えるため vim.lsp.config は呼ばず enable するだけ）
      vim.lsp.enable("rust_analyzer")
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
  --   ・組み込みの正規表現ベースハイライトは複雑な文法（Verilog の always
  --     ブロック等）で色が崩れやすい
  --   ・Neovim 公式が推奨するハイライト基盤であり、tokyonight.nvim も
  --     Treesitter のトークングループに合わせて配色を最適化している
  --   ・パーサーはヘッダ等の実体解決をしないため、clangd と違い
  --     PlatformIO/ESP-IDF のようなボード固有パスが未解決でも
  --     ハイライトには影響しない（マイコン向けソースコードも綺麗に色付けできる）
  --
  -- 対応言語は下記 config 内の filetype_parsers テーブルで管理する。
  -- 増やす場合は { filetype = "パーサー名" } を1行足すだけでよい
  -- （filetype とパーサー名が異なる非自明なケースだけ理由をその場に注記する）。
  --
  -- GitHub: https://github.com/nvim-treesitter/nvim-treesitter
  -- 必要環境:
  --   ・C コンパイラ（cc / gcc / clang）が PATH に存在すること
  --     macOS では Xcode Command Line Tools に付属（xcode-select --install で入る）
  --   ・tree-sitter-cli が PATH に存在すること
  --     brew install tree-sitter はライブラリのみのため別途 brew install tree-sitter-cli が必要
  --   いずれもパーサーの初回ビルド時のみ使用する。以降は不要。
  -- ===========================================================================
  {
    "nvim-treesitter/nvim-treesitter",

    -- パーサー（言語ごとの文法定義 .so ファイル）を更新するコマンド
    -- インストール・アップデート時に自動実行される
    build = ":TSUpdate",

    -- ファイルを開いたときに遅延読み込みする
    event = { "BufReadPost", "BufNewFile" },

    config = function()
      -- filetype => 使用する Treesitter パーサー名
      local filetype_parsers = {
        -- SystemVerilog は Verilog の上位互換なので .v (filetype=verilog) にも適用できる
        verilog = "systemverilog",
        c = "c",
        cpp = "cpp",
      }

      -- 新 API では ensure_installed は廃止。未インストールのパーサーだけ install() する
      local installed = require("nvim-treesitter.config").get_installed()
      local to_install = {}
      for _, parser in pairs(filetype_parsers) do
        if not vim.tbl_contains(installed, parser) and not vim.tbl_contains(to_install, parser) then
          table.insert(to_install, parser)
        end
      end
      if #to_install > 0 then
        require("nvim-treesitter.install").install(to_install, { summary = true })
      end

      -- 対象 filetype を開いたとき対応するパーサーで Treesitter ハイライトを有効化する
      vim.api.nvim_create_autocmd("FileType", {
        pattern = vim.tbl_keys(filetype_parsers),
        callback = function(ev)
          pcall(vim.treesitter.start, ev.buf, filetype_parsers[vim.bo[ev.buf].filetype])
        end,
        desc = "Treesitter ハイライトを有効化",
      })
    end,
  },

  -- ===========================================================================
  -- oil.nvim
  -- -------------------------------------------------------------------------
  -- 役割：
  --   ディレクトリをバッファとして開き、テキスト編集の感覚でファイル操作
  --   （作成・削除・リネーム・移動）ができるファイラー。保存（:w）すると
  --   実際のファイルシステムに変更が反映される。
  --
  -- なぜ oil.nvim にしたか（neo-tree.nvim ではなく）：
  --   ・ツリー常駐型ではなく「今いる場所を編集する」スタイルで、通常の
  --     バッファ操作と同じキー操作がそのまま使える（学習コストが低い）
  --   ・設定なしのデフォルトで十分実用的で、まずはシンプルに試したい
  --     という方針に合う
  --
  -- 起動キー：
  --   `-` で現在のファイルの親ディレクトリを開く（vim-vinegar 風の慣習。
  --   oil.nvim 公式 README 推奨の割り当て）。素の Vim では「前の行の
  --   先頭非空白文字へ移動」に割り当たっているが未使用のため上書きする。
  --
  -- GitHub: https://github.com/stevearc/oil.nvim
  -- 必要環境: なし（Lua 製・外部依存なし）
  -- ===========================================================================
  {
    "stevearc/oil.nvim",

    -- 起動キーを押したときだけ読み込む（遅延読み込み）
    keys = {
      {
        "-",
        function()
          require("oil").open()
        end,
        desc = "Oil: 親ディレクトリを開く",
      },
    },

    -- セットアップを呼ぶだけ。設定はデフォルトのままで十分使える。
    config = function()
      require("oil").setup({})

      -- なぜこの設定が必要か：
      --   lazygit は cwd 基準で git リポジトリを探すため、oil でディレクトリを
      --   移動しても cwd が追従しないと、移動先の別リポジトリを認識できない。
      --
      -- なぜ User OilEnter ではなく BufEnter を使うか：
      --   OilEnter は「そのディレクトリ用バッファが初めて作られたとき」だけ
      --   発火する一度きりのイベント。oil はディレクトリごとに別バッファを持ち、
      --   一度訪れたディレクトリのバッファは再利用されるため、
      --   「上位へ移動 → 元のディレクトリへ戻る」という操作をすると
      --   2回目はバッファが再利用されて OilEnter が発火せず、cwd が
      --   移動前（上位ディレクトリ）のまま取り残されるバグがあった。
      --   BufEnter はバッファに入るたびに毎回発火するため、これを使うことで
      --   再訪問時にも確実に cwd が追従する。
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "oil://*",
        callback = function()
          local dir = require("oil").get_current_dir()
          if dir then
            vim.cmd.cd(dir)
          end
        end,
        desc = "oil でディレクトリ移動時に cwd を追従させる（lazygit が移動先のリポジトリを正しく認識できるように）",
      })
    end,
  },

  -- ===========================================================================
  -- fzf-lua
  -- -------------------------------------------------------------------------
  -- 役割：
  --   ファイル名のあいまい検索（Files）とプロジェクト全体の全文検索（Live Grep）
  --   を提供する。oil.nvim が「今いる場所を編集する」役割なのに対し、
  --   fzf-lua は「ファイル名・内容から一発でジャンプする」検索役を担う。
  --
  -- なぜ fzf-lua にしたか（telescope.nvim ではなく）：
  --   ・インストール済みの fzf バイナリをそのまま呼び出すため、使い慣れた
  --     fzf のマッチング挙動・キー操作がほぼそのまま Neovim に持ち込める
  --     （telescope の fzf-native 拡張は fzf 本体ではなく C で書き直した
  --     互換アルゴリズムで、ビルドに make が別途必要）
  --   ・Lua 製で本リポジトリの他プラグインと書きぶりが揃う
  --   ・telescope は LSP ピッカーや Git ピッカーまで抱える総合フレームワーク
  --     だが、本設定では LSP ナビゲーション（gd / gr）を素の vim.lsp.buf で
  --     直接使っており重複が大きいため見送った
  --
  -- まずはシンプルに、ファイル検索と全文検索の2機能だけを有効化する。
  -- バッファ一覧・最近開いたファイル等は必要になったときに追加する。
  --
  -- GitHub: https://github.com/ibhagwan/fzf-lua
  -- 必要環境:
  --   ・fzf（ファジーファインダー本体）: brew install fzf
  --   ・ripgrep（全文検索に使用）: brew install ripgrep
  -- ===========================================================================
  {
    "ibhagwan/fzf-lua",

    -- キーマッピング（押したときだけ読み込む遅延読み込み）
    keys = {
      {
        "<leader>ff",                      -- キー: スペース + f + f
        function()
          require("fzf-lua").files()
        end,
        desc = "fzf-lua: ファイル検索",
      },
      {
        "<leader>fg",                      -- キー: スペース + f + g
        function()
          require("fzf-lua").live_grep()
        end,
        desc = "fzf-lua: 全文検索",
      },
    },

    -- セットアップを呼ぶだけ。設定はデフォルトのままで十分使える。
    config = function()
      require("fzf-lua").setup({})
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
-- LSP 設定（キーマップ・補完）
-- =============================================================================
-- completeopt: LSP補完（<C-x><C-o>）の候補メニュー表示を設定する。
-- 候補表示後は <C-n>/<C-p> で選択、<C-y> で確定、<C-e> で補完前の状態に戻す。
vim.opt.completeopt:append({ "menuone", "noselect" })

-- 関数補完を確定すると、引数プレースホルダー入りのスニペットが展開される。
-- <Tab>/<S-Tab> でプレースホルダー間を順に移動できる。
-- "i" = 挿入モード、"s" = セレクトモード。プレースホルダーは選択済み状態
-- （セレクトモード）で表示されるため、両方のモードで効くようにする。
vim.keymap.set({ "i", "s" }, "<Tab>", function()
  if vim.snippet.active({ direction = 1 }) then
    return "<Cmd>lua vim.snippet.jump(1)<CR>"
  end
  return "<Tab>"
end, { expr = true })

vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
  if vim.snippet.active({ direction = -1 }) then
    return "<Cmd>lua vim.snippet.jump(-1)<CR>"
  end
  return "<S-Tab>"
end, { expr = true })

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

-- <leader>e : カーソル行の診断メッセージをフローティングウィンドウで表示
-- vim.diagnostic は LSP 専用ではない汎用機能なので、LspAttach を待たずに設定する
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "診断メッセージを表示" })
