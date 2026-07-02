# greple 高速化検討資料 — ripgrep の取り込みを中心に

- 作成日: 2026-07-02
- 対象: App-Greple 10.04 (master 6625a99)
- 計測環境: macOS 15 (Darwin 24.6) / Apple Silicon / perl 5.42.2 / ripgrep 15.1.0 (+pcre2, NEON SIMD)

## 1. 要旨

ripgrep の高速性を greple に取り込む方法として、以下の 5 案を検討した。

| 案 | 概要 | 効果 | 工数 | 判定 |
|----|------|------|------|------|
| A | rg をファイルレベルのプリフィルタに使う | 大（多ファイル検索） | 小 | **推奨** |
| B | rg --json の位置情報を greple 内部位置に変換 | ほぼ無し〜逆効果 | 中 | 非推奨 |
| C | Rust ライブラリ (grep crates) を FFI で呼ぶ | 小 | 大 | 非推奨 |
| D | greple 全体を Rust で書き直す | 大 | 特大 | 非推奨（別プロジェクトなら可） |
| E | Perl 内部の改善（並列化・マッチ後処理最適化） | 中 | 小〜中 | **併用推奨** |

結論を先に述べると、**実測の結果、greple の遅さの主因は正規表現スキャンではない**。
ボトルネックは (1) マッチ後の Perl データ構造処理、(2) ファイルごとの逐次処理オーバーヘッド、(3) 並列性の欠如であり、
「ripgrep に正規表現マッチを肩代わりさせて位置情報をもらう」方式（案 B/C）は、
高速化したい部分がそもそも支配的コストでないため効果が出ない。
ユーザーが以前試して「うまく使えなかった」のは位置表現の非互換だけでなく、この構造的な理由による。

一方、**「マッチしないファイルに greple の処理を一切走らせない」プリフィルタ方式（案 A）は、
rg の並列走査・ファイルスキップの強みをそのまま享受でき、位置変換も不要**。
実測でも大規模ツリー検索で 5 倍以上（ツリーが大きくマッチが疎なほど拡大）の改善を確認した。

## 2. 現状分析: greple のアーキテクチャ

サブエージェントによるコード調査結果の要点（file:line は現 master 基準）。

### 2.1 処理モデル

- **slurp 方式**: ファイル全体を 1 スカラ文字列として読む（`script/greple:989-1023`）。
  行単位ストリーミングではない。
- **文字単位オフセット**: 入力は `binmode STDIN, ":encoding($file_code)"`（`script/greple:1226`）で
  読み込み時にデコードされ、以後の検索・領域演算はすべて **Perl 内部文字列上の文字オフセット**で行われる。
  `Regions.pm` の `match_regions`（`lib/App/Greple/Regions.pm:97-117`）は
  `pos() - length(${^MATCH})` で `[from, to]` を算出する。
- **領域代数**: `--inside/--outside/--include/--exclude`、ブロック構築、must/need/allow 判定は
  すべて `[from, to]` ペア配列に対する集合演算（`Regions.pm`, `Grep.pm`）。
- **Perl 正規表現への依存**: `/p` + `${^MATCH}`、`pos()`、`\G` + `\X`（`Pattern.pm:134`）、
  可変長後読み、ユーザーパターンの Perl 方言全般。
- **モジュール結合点**: `--inside '&func'` 等の関数パターンは `$_` にファイル内容が入った状態で
  呼ばれ、`[from, to]` の領域リストを返す（`Grep.pm:444-457`）。`--begin/--end/--postgrep/--print`
  も同様に Perl コードが検索パイプラインへ直接介入する。
- **逐次処理**: ファイルループ（`script/greple:1119-1162`）は単一プロセス・単一スレッド。
  並列処理は一切ない（fork は find.pm の外部コマンド起動と PGP 復号のみ）。
- **入力フィルタ**: `--if` は外部コマンドの出力を STDIN 経由で検索対象にする（`Filter.pm:87-111`）。
  検索対象が元ファイルのバイト列と一致しない場合がある点は、外部エンジン統合時の制約になる。

### 2.2 ベンチマーク

コーパス: UTF-8 日英混在テキスト 26MB / 30 万行（および同内容を 100 行 × 3000 ファイルに分割したツリー）。
warm cache、3 回計測の代表値。

**単一ファイル（26MB）**

| コマンド | マッチ行数 | 時間 |
|---|---:|---:|
| `rg -c fox` | 95,984 | 0.010s |
| `grep -c fox` | 95,984 | 0.009s |
| `perl -ne '$c++ if /fox/'`（UTF-8 デコード込み） | 95,984 | 0.035s |
| `greple -c fox` | 95,984 | **0.82s** |
| `greple -c 高速` | 115,860 | **0.96s** |
| `greple -c <マッチ0件>` | 0 | **0.12s** |
| `greple`（/dev/null、起動コストのみ） | — | 0.044s |

**多ファイル（3000 ファイル / 計 26MB）**

| コマンド | 時間 |
|---|---:|
| `rg -c <マッチ0件> tree/`（並列） | 0.034s |
| `rg -j1 -c <マッチ0件> tree/`（単一スレッド） | 0.036s |
| `rg -l 高速 tree/`（全ファイルマッチ） | 0.047s |
| `greple -Mdig -c <マッチ0件> --dig tree` | **0.88s** |
| `greple -Mdig -c 高速 --dig tree` | **1.6s** |

**プリフィルタ効果（3000 ファイル中 5 ファイルのみにマッチする希少パターン）**

| コマンド | 時間 |
|---|---:|
| `greple -Mdig -l zebra --dig tree` | 0.30s |
| `rg -l zebra tree/ \| greple --readlist -l zebra` | **0.058s** |

### 2.3 ボトルネックの分解

上の数値から greple の 1 実行あたりのコスト内訳を分解できる。

| フェーズ | 実測値 | 備考 |
|---|---|---|
| 起動（モジュールロード・オプション処理） | 44ms | Getopt::EX 等。どの方式でも残る下限 |
| デコード + 正規表現スキャン | 約 80ms / 26MB | マッチ 0 件時 0.124s − 起動 44ms |
| **マッチ後処理**（Match/Block 構築・領域演算・カウント） | **約 7µs / マッチ** | 10 万マッチで 0.7〜0.9s。**支配的コスト** |
| ファイルごとのオーバーヘッド | 約 0.25ms / ファイル | open・binmode・slurp 等 |

**含意**: rg が 26MB を 10ms で走査するのに対し greple のスキャンフェーズは 80ms — 差は 8 倍だが
絶対値は小さい。マッチが多い場合の 0.8〜1.0s の大半はスキャンではなく
**マッチ後の Perl 側処理**であり、これは初期マッチ列挙を外部化しても消えない。
つまり「rg に位置を出させる」方式の理論上の改善上限は、このワークロードでは 1 割程度しかない。

## 3. ripgrep 側の事実確認

### 3.1 `--json` 出力（実測確認済み）

```json
{"type":"match","data":{"path":{"text":"sample.txt"},
 "lines":{"text":"foo 高速 bar\n"},"line_number":1,"absolute_offset":0,
 "submatches":[{"match":{"text":"高速"},"start":4,"end":10}]}}
```

- `absolute_offset` は行頭の絶対バイトオフセット、`submatches` の `start/end` は行内バイトオフセット。
- **トランスコード時（`-E euc-jp` や BOM 検出時）のオフセットは、変換後 UTF-8 バイト列基準**
  （EUC-JP ファイルで実測確認: `高速` → start:4, end:10 = UTF-8 バイト位置）。
  `--pre` フィルタや解凍も同様に変換後基準。
- 非 UTF-8 データは base64（`bytes` キー）で表現される。

したがって「rg の出すオフセットは常に UTF-8 バイト単位」とみなせ、greple の文字オフセットへの
変換は数学的には整合的に定義できる（オフセットは昇順に届くので O(N) の一回走査で変換可能）。
**位置変換そのものは技術的障害ではない**。障害は次節以降で述べるコスト構造にある。

### 3.2 案 B の実測: JSON 経由のオーバーヘッド

| 処理 | 時間 |
|---|---:|
| `rg --json fox corpus.txt`（96k マッチ、JSON 26MB 出力） | 0.09s |
| ↑を Perl (JSON::PP) でパース | **8.0s** |
| （参考）現行 greple の同検索全体 | 0.82s |

マッチ多数時、JSON のパースだけで現行 greple の 10 倍の時間がかかる（コア モジュール JSON::PP の場合。
JSON::XS を追加依存にすれば数百 ms 程度まで縮むが、それでも byte→char 変換・
ブロック構築を加えると現行との差はほぼ消える）。
マッチ少数時はそもそもスキャンフェーズ（80ms）しか削れない。**どちらのケースでも割に合わない。**

### 3.3 libripgrep（grep crates）

ripgrep は `grep-matcher` / `grep-searcher` / `grep-printer` 等のクレート群に分割されており
（[libripgrep PR #1017](https://github.com/BurntSushi/ripgrep/pull/1017)）、
ライブラリとして再利用可能。正規表現エンジンは Rust regex（有限オートマトン + SIMD）と
PCRE2（`--pcre2` / `-P`、後読み・後方参照対応）の 2 系統。

- Rust regex は後読み・後方参照・`(?{...})` 非対応。greple ユーザーのパターン資産とは方言差がある。
- PCRE2 モードは Perl にかなり近いが、完全互換ではない。

## 4. 各案の詳細検討

### 案 A: rg をファイルレベルのプリフィルタに使う 【推奨】

**仕組み**: `rg -l pattern dir` で「マッチを含むファイル一覧」だけを rg に高速列挙させ、
greple は該当ファイルのみを従来どおり処理する。位置情報を受け渡さないので
バイト/文字オフセット問題・正規表現方言問題の影響を最小化できる。

```
rg -l --null pattern dir | greple --readlist pattern
```

既存機構がほぼそのまま使える:

- `--readlist`（`script/greple:1200-1201`）: STDIN からファイルリストを受け取る
- `find.pm` の `!command` 機構（`find.pm:80`）: 任意コマンドでファイルリストを生成
  （`dig.pm` が find の薄いラッパであるのと同じ構図で、`App::Greple::rg` モジュールを書ける）

**実装案**: `App::Greple::rg` モジュールを新設し、`greple -Mrg --rg <dir> pattern` で

1. greple のオプション処理後、検索パターンを取得
2. パターンを rg に渡せるか判定（関数パターン `&func` や Perl 固有機能は不可）
3. 渡せる場合 `rg -lP --sort path` でファイルリスト生成（`-P` で PCRE2 = Perl 方言に接近、
   `--sort` は並列性を殺すので出力順が問題になる場合のみ）
4. 渡せない場合は `rg --files`（ファイル列挙のみ）にフォールバック — それでも
   .gitignore 尊重・バイナリスキップの恩恵はある

**正しさの条件**: プリフィルタは「greple がマッチするファイルの上位集合」を返す必要がある。
注意点と対策:

| 懸念 | 対策 |
|---|---|
| 正規表現方言差（後読み等） | `-P` (PCRE2) を使う。変換不能なら素通しフォールバック |
| 行跨ぎパターン | `rg -U`（マルチライン）を付ける |
| 非 UTF-8 ファイル（--icode） | `rg -E <encoding>` にマッピング。guess 時は素通し |
| `--if` フィルタ対象（zip 等） | rg では判定不能 → 素通し（従来どおり greple が処理） |
| 大文字小文字 (`-i`) | `rg -i` を連動 |
| must/need の複数パターン | 各陽性パターンの OR で `-e` を並べれば上位集合になる |

安全側に倒す（迷ったら素通し）設計なら結果の正しさは保たれ、性能だけが段階的に向上する。

**効果**: マッチが疎な大規模ツリーで支配的な「マッチしないファイルの処理」を rg の速度
（並列走査 + .gitignore/バイナリスキップ）で消せる。実測 3000 ファイルで 5 倍、
実プロジェクトの巨大ツリーでは桁違いになる。greple の主用途（ドキュメント・コード検索）で
最も体感が大きいのはこのケース。

**得失まとめ**: 工数小（モジュール 1 個、コア変更ほぼ不要）。rg はオプショナルな外部依存
（無ければ従来動作）。greple の機能・モジュール互換性への影響ゼロ。
単一巨大ファイル・マッチ多数のケースには効かない（→ 案 E で補完）。

### 案 B: rg --json の位置情報を greple 内部位置に変換する 【非推奨】

ユーザーが以前検討した方式。技術的には §3.1 のとおり「rg のオフセットは変換後 UTF-8 バイト基準」
なので、昇順オフセットを 1 パスで文字位置に変換すれば greple の内部表現に載せること自体は可能。
しかし:

1. **改善上限が小さい**: 削れるのはスキャンフェーズ（26MB あたり ~80ms）のみ。
   マッチ後処理（支配的コスト）は greple 側に残る。
2. **JSON オーバーヘッドが逆効果**: マッチ多数時、JSON::PP でパースに 8 秒（実測）。
   JSON::XS を依存に加えても変換・構築コストで利得はほぼ相殺。
3. **機能制約が多い**: 関数パターン（`&func`）不可、`--inside/--outside` の領域パターンも
   同様に外部化しないと片手落ち、`--if` フィルタとの合成、正規表現方言差、
   マッチ 0 幅・重なり領域のセマンティクス差、等の互換性穴が多数。
4. 表示のためどのみち該当ファイルのデコードと slurp は必要で、I/O 面の節約もない。

**結論**: 実装しても現行比でほぼ速くならず、互換性リスクだけ増える。

### 案 C: Rust ライブラリ (grep crates) を FFI::Platypus で呼ぶ 【非推奨】

**技術的成立性は確認できる**:
[FFI::Platypus::Lang::Rust](https://metacpan.org/pod/FFI::Platypus::Lang::Rust)（0.17, 2023）と
[FFI::Build::File::Cargo](https://metacpan.org/pod/FFI::Build::File::Cargo) により、
CPAN ディストリビューションに Rust クレートを同梱し `cargo` でビルドする仕組みは確立している。
in-process なので JSON オーバーヘッドはなく、byte→char 変換テーブルを Rust 側で構築する等の
自由度も高い。

しかし:

1. **効果は案 B と同じ場所に限定される**: 初期マッチ列挙の高速化のみ。本気で速くするには
   領域代数（Regions.pm）とブロック構築（Grep.pm）ごと Rust に移す必要があり、そうなると
   関数パターンや `--postgrep` 等の Perl コールバックとの往復が発生して設計が複雑化する。
2. **配布コストが跳ね上がる**: インストールに Rust toolchain が必要になる。
   `cpanm App::Greple` で入る手軽さが失われる（Alien 化や事前ビルドバイナリ配布は保守負荷大）。
   オプショナル XS 的な二段構え（あれば使う）は二重実装の保守を意味する。
3. Perl↔Rust 境界での文字列コピー（26MB 級）も無視できない。

**結論**: 「工数大・利得小・配布リスク大」。greple の規模のツールに対して割に合わない。

### 案 D: greple 全体を Rust で書き直す 【greple としては非推奨】

技術的には可能で、性能は本物になる（マッチ後処理も含め 10〜100 倍級）。
問題はユーザー認識のとおり **Perl モジュールエコシステム**にある。

greple の価値の中核は `-Mdig`, `-Msubst`, `-Mmd`, `~/.greplerc`, Getopt::EX の
オプション展開機構であり、これらは「Perl コードが検索パイプラインに直接介入できる」
こと（`$_` にテキスト、`[from,to]` を返す関数、`__DATA__` のオプション定義、`__PERL__` 節）
に依存している。互換を保つ選択肢は:

| 方式 | 評価 |
|---|---|
| (a) Rust に Perl を埋め込む（libperl / [RuPerl](https://lib.rs/crates/ruperl)） | 実験的・ビルド最悪級。モジュール実行部分は結局 Perl 速度。Getopt::EX 互換のためほぼフル Perl が要る |
| (b) モジュールを別プロセス Perl で動かし IPC（領域リストを往復） | 設計としては最も筋が良いが、Getopt::EX 相当の再実装 + プロトコル設計で数人月級。26MB 級テキストの往復コストも発生 |
| (c) モジュールを Rust で書き直す | ユーザー認識どおり非現実的。サードパーティ・個人設定資産を切り捨てることになる |

さらに Getopt::EX 自体（オプション展開、autoload、.greplerc 解釈）の再現が必要で、
「greple 互換の Rust 版」は実質フルスクラッチの大規模プロジェクトになる。

**結論**: greple の後継としてやるなら「互換性を捨てた新ツール」として設計すべきで、
それは本資料のスコープ（greple の高速化）とは別の判断。現行ユーザー資産を守るなら選ばない。

### 案 E: Perl 内部の改善 【併用推奨】

ripgrep とは独立に、実測で見えたボトルネックへの直接対処。

- **E1: ファイル並列化**（効果: コア数倍、工数: 中）
  ファイルループ（`script/greple:1119-1162`）は各ファイル独立なので、
  fork ベース（MCE 等、あるいは自前 fork + 出力順序制御）で並列化できる。
  rg -j1 と rg（並列）の差が示すとおり、多ファイル時の並列化は確実に効く。
  案 A と直交なので併用可能。
- **E2: マッチ後処理の最適化**（効果: マッチ多数時に大、工数: 小〜中）
  7µs/マッチの内訳をプロファイルし、`-c`/`-l` 時は Match/Block オブジェクト構築を
  スキップする fast path を作る、`Clone::clone`（`Grep.pm:138`）を避ける等。
  「10 万マッチで 0.8s」の大半はここで、外部エンジンなしで削れる可能性が高い。
- **E3: re::engine::PCRE2**（効果: 小、工数: 小、リスク: 中）
  [re::engine::PCRE2](https://metacpan.org/pod/re::engine::PCRE2)（0.17, 2025-09、保守されているが bus factor 1）
  で JIT 正規表現化。ただしスキャンフェーズは支配的でないため優先度低。互換性問題の報告もある。

## 5. 総合比較

| 観点 | A: プリフィルタ | B: 位置変換 | C: FFI | D: Rust 化 | E: Perl 改善 |
|---|---|---|---|---|---|
| 多ファイル検索の高速化 | ◎（5〜100 倍） | △ | △ | ◎ | ○（コア数倍） |
| 単一ファイル・マッチ多数 | ×（効果なし） | ×（逆効果あり） | △ | ◎ | ○ |
| 機能・モジュール互換性 | ◎（影響なし） | △（穴多数） | △ | ×（要大再設計） | ◎ |
| 実装工数 | 小（数日） | 中 | 大 | 特大（数人月〜） | 小〜中 |
| 配布・インストール影響 | なし（rg は任意依存） | なし | Rust toolchain 必須 | 全面変更 | なし |
| 保守リスク | 小 | 中 | 大 | 大 | 小 |

## 6. 推奨ロードマップ

1. **短期**: `App::Greple::rg` モジュール（案 A）。
   `rg --files` フォールバック付きの安全設計なら互換性リスクなしに、
   最頻ユースケース（大ツリーからの検索）で最大の体感改善が得られる。
   rg 不在環境では従来動作なので依存も増えない。
2. **中期**: 案 E2（`-c`/`-l` fast path とマッチ後処理のプロファイリング・最適化）、
   続いて E1（ファイル並列化）。単一巨大ファイル・マッチ多数のケースを補完する。
3. **見送り**: 案 B・C は改善上限がスキャンフェーズ（全体の 1 割程度）に限られるため見送り。
   案 D は greple の高速化ではなく新規プロジェクトの判断として切り分ける。

## 7. 参考資料

- [ripgrep --json フォーマット（rg(1) manpage）](https://manpages.debian.org/testing/ripgrep/rg.1.en.html) — トランスコード時のオフセット規約を含む
- [ripgrep Discussion #2814: submatch オフセットの意味](https://github.com/BurntSushi/ripgrep/discussions/2814)
- [ripgrep Issue #1629: --json への encoding 情報追加要望](https://github.com/BurntSushi/ripgrep/issues/1629)
- [libripgrep PR #1017（クレート分割・PCRE2・JSON 出力）](https://github.com/BurntSushi/ripgrep/pull/1017) / [Issue #162](https://github.com/BurntSushi/ripgrep/issues/162)
- [FFI::Platypus::Lang::Rust](https://metacpan.org/pod/FFI::Platypus::Lang::Rust) / [FFI::Build::File::Cargo](https://metacpan.org/pod/FFI::Build::File::Cargo)
- [re::engine::PCRE2](https://metacpan.org/pod/re::engine::PCRE2) / [GitHub](https://github.com/rurban/re-engine-PCRE2/)
- [RuPerl — Rust with embedded Perl](https://foursixnine.io/blog/perl/rust/software/c/2024/05/01/ruperlrustwithembeddedperl.html) / [lib.rs/crates/ruperl](https://lib.rs/crates/ruperl)
- `@-`/`@+` の UTF-8 性能問題: https://qiita.com/kaz-utashiro/items/2facc87ea9ba25e81cd9（CLAUDE.md 記載）

## 付録: ベンチマーク再現方法

コーパス生成（26MB / 30 万行、日英混在 UTF-8）:

```sh
perl -Mutf8 -CO -e '
my @en = qw(the quick brown fox jumps over lazy dog alpha beta gamma delta
            epsilon system network protocol module function variable);
my @ja = ("検索","文字列","正規表現","高速","処理","日本語","テキスト","モジュール","変換","出力");
srand(42);
open my $fh, ">:utf8", "corpus.txt" or die;
for (1..300000) {
  my @w; for (1..12) { push @w, rand() < 0.4 ? $ja[int rand @ja] : $en[int rand @en] }
  print $fh join(" ", @w), "\n";
}'
mkdir tree && (cd tree && split -l 100 -a 4 ../corpus.txt f_ && for f in f_*; do mv $f $f.txt; done)
```

計測は `time` による 3 回実行の代表値。プリフィルタ実験は 5 ファイルに固有語を追記して実施。
