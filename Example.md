Greple Examples
===

---
## Keywords / キーワード


### find multiple words all / 全部ある行を表示する

	greple 'foo bar baz'
	greple -e foo -e bar -e baz
	
	x foo baz
	o foo bar baz
	o baz, bar and foo
	
	# yes, you can do it by grep, too.
	# grep foo | grep bar | grep baz

	# or with pcregrep
	# pcregep '^(?=.*foo)(?=.*bar)(?=.*baz)'

### negative match / あっては困る単語を指定する

	greple 'foo bar baz -yabba -dabba -doo'
	greple -e foo -e bar -e baz -v yabba -v dabba -v doo
	
	x foo bar
	o baz bar foo
	x foo bar baz doo
	
	# grep foo | grep bar | grep baz | egrep -v 'yabba|dabba|doo'

### alternative match / どれかひとつあればいいんだけど

	greple 'foo bar baz ?yabba ?dabba ?doo'
	greple 'foo bar baz yabba|dabba|doo'
	greple -e foo -e bar -e baz -e 'yabba|dabba|doo'
	
	greple '?foo|bar ?yabba|dabba'  # foo|bar|yabba|dabba
	greple 'foo|bar yabba|dabba'    # you want this? こーいうこと?

### cut down the match count / マッチに必要な数をまける

	greple --cut=1 'foo bar baz'

	o foo bar baz
	o foo baz
	o bar baz
	x foo

### allow negative match / ネガティブマッチを許す

	greple --allow=1 'foo -bar -baz'
	
	o foo bar
	o foo baz
	x foo bar baz

### narrow down the match result / 検索結果を絞り込む
	greple pattern *.html
	greple pattern *.html -v foo
	greple pattern *.html -v foo -v bar
	greple pattern *.html -v foo -v bar -v baz

	isn't this nice?
	これ、結構、よくないすか?

---
## Areas / 領域

### find `and` not in `command` / `command` に含まれない `and` を探す

	greple --outside=command and

### find from C comment / C のコメント部分を検索

	greple --inside='(?s)\/\*.*?\*\/'

### find from shell comment / シェルのコメントを検索する

	greple --inside='#.*'

### find variablish things from lines start with `my` / `my` ではじまる行から変数ぽいものを探す

	greple --inside='^\s*my\b.*' '[\$\@]\w+'

---
## Blocks / ブロック

### paragraph mode / パラグラフモード

	greple -p 'foo bar baz'

	# show preveous and next paragraph together
	# 前後のパラグラフも表示する	
	greple -pC1 'foo bar baz' …

### show paragraph not including pattern / 何かが含まれないパラグラフを表示する

	greple --nocolor --re '(.+\n)+' -v '(?i)pattern'

### show lines not including pattern / 何かが含まれない行を表示する

	use grep -v !

### show pages including pattern / ページ単位で表示する

	greple -n --block='(.*\n){1,66}' pattern

### show entire file / ファイル全体を表示する

	greple --block='(?s).*'

### show all comment blocks / コメントブロックを全部表示する

	greple -o --nocolor --re '\/\*(?s:.*?)\*\/' /usr/include/stdio.h


---
## Text / テキスト
### 複数行から検索する

	greple リゾート
	will match this text:
	は、こんなのもみつけてくれます。というか、日本語を処理する場合、そうでないと困ります。
	
		長い駅名を探すと「東京ディズニーランド・ステーション駅」「リ
		ゾートゲートウェイ・ステーション駅」「東京ディズニーシー・ス
		テーション駅」「南阿蘇水の生まれる里白水高原駅」などが…



### list up all Japanese Katakana words / 片仮名の単語を全部抜き出す

	greple -ho --nocolor --join '\p{utf8::InKatakana}[\n\p{utf8::InKatakana}]*'

### you like it? / 気に入ったらこんな風にどうぞ

	cat >> ~/.greplerc
	define :kana: \p{utf8::InKatakana}
	option --kanalist --color=never --only-matching --join --re ':kana:[:kana:\n]+'

### find `cyclic redundancy c*`

	greple -pi -e 'cyclic redundancy c\w+' rfc*
	greple -o --joinby=' ' -ie 'cyclic redundancy c\w+' rfc*

### find Kanji and not CJKUnifiedIdeographs / 漢字だけど CJKUnifiedIdeographs じゃない文字を探す

	greple --inside='\p{Han}+' '[^\s\p{InCJKUnifiedIdeographs}]'
	
	# This works, but quite slow.  Not recommended.
	# 動くけどチョー遅いからこんなことしちゃ駄目よ。

### guess data encoding / 文字コードを自動判定する

	greple --icode=guess

### specify data encoding / 文字コードを指定する

	greple --icode=euc-jp
	greple --icode=shif-jis

### specify guessing code set / 自動判定するコードを指定する

	greple --icode=utf8,euc-jp,shift-jis,7bit-jis

### add to guessing code set / 自動判定するコードを追加する

	greple --icode=+euc-kr

---
## Filter / フィルター

### expand tabs before seach / タブを展開してから検索する

	greple -n --if=expand
	
	# give better looking for tab indented text

### find from EXIF data / EXIF 情報を検索する

	greple --if='env LC_ALL=en_US exif -x /dev/stdin' 'Image_Description|Manufacturer' *.jpg
