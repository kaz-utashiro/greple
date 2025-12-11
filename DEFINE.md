# DEFINE Pattern Support in -f Option

## Overview

greple の `-f` オプションで subst 辞書形式の DEFINE パターンをサポートする。

```
(?(DEFINE)(?<digit>\d+))
(?(DEFINE)(?<date>(?&digit)-(?&digit)-(?&digit)))
(?&date)  //  YYYY-MM-DD
```

## Usage

- `(?(DEFINE)...)` で始まる行は宣言のみに使用する
- 参照パターン（`(?&name)`）は別の行に記述する
- 同じ行にパターンと DEFINE を書きたい場合は、パターンを先に書き、DEFINE を最後に配置する
  - 例: `(?&digit)+(?(DEFINE)(?<digit>\d+))`
  - この書き方は Perl の正規表現マニュアルでも推奨されている
- DEFINE を先頭に書きたい場合は `(?:)` を前置する
  - 例: `(?:)(?(DEFINE)(?<digit>\d+))(?&digit)+`
  - `(?:)` は空文字列にマッチする non-capturing group で、パターンが続行される
  - 参考: `(?!)` や `(*FAIL)`, `(*F)` は常に失敗するため、パターン全体がマッチしなくなる

## Problem

### 現状の append メソッド

`lib/App/Greple/Pattern/Holder.pm` の `append` メソッドでは、各パターンを `qr//` で個別にコンパイルしてから結合している：

```perl
my $p = "(?x)\n  " . join("\n| ", map qr/$_/m, @p);
```

### 問題点

各パターンが個別にコンパイルされるため、DEFINE パターンと参照パターンが別々の要素にあると、コンパイル時に参照エラーが発生する：

```
Reference to nonexistent named group in regex
```

### 現在の回避策

`load_file` で DEFINE を参照する各パターンに、必要な DEFINE を追加している：

```perl
for my $p (@p) {
    # 各パターンに必要な DEFINE を追加
    $p .= "(?x:\n" . join("\n", values %define) . ")" if %define;
}
```

これにより `-dm` 出力で DEFINE が重複する：

```
(?^um:(?x)
  (?^um:(?&digit)+(?x:
(?(DEFINE)(?<digit>\d+))))
| (?^um:(?&digit){4}(?x:
(?(DEFINE)(?<digit>\d+)))))
```

## Potential Solution

理論的には、最終的な正規表現は1つなので、DEFINE は1箇所にあれば参照できるはず。

### 案: append メソッドの修正

DEFINE パターンは `qr//` でラップせず、文字列のまま結合する：

```perl
# DEFINE patterns should not be wrapped with qr//
my @compiled = map {
    /^\(\?!\)\(\?\(DEFINE\)/ ? $_ : qr/$_/m
} @p;
my $p = "(?x)\n  " . join("\n| ", @compiled);
```

または、`-f` で読み込んだパターンは全て文字列のまま結合するオプションを追加する。

### 検討事項

- `qr//` ラップの目的は何か？
- ラップしない場合の副作用は？
- DEFINE パターンのみ特別扱いするか、全体の動作を変えるか

## Resolution

修正済み（lib/App/Greple/Pattern/Holder.pm）:
- 元の実装では最後のパターンにのみ DEFINE を追加していたため、他のパターンからの参照が失敗していた
- 各パターンに必要な DEFINE を個別に追加するように修正
- DEFINE は `(?(DEFINE)...)` 構文により自身は何にもマッチしないため、重複しても実質的な問題はない
