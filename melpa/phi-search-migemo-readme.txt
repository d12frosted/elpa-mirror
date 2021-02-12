This script provides "phi-search"-based Japanese incremental
search, powered by "migemo".

phi-search, migemo をインストールしこのファイルをロードすると、"M-x
phi-search-migemo-toggle" で migemo の有効/無効を切り替えることがで
きます。 phi-search-default-map にキーバインドを追加しておいても便利
です。

  (define-key phi-search-default-map (kbd "M-m") 'phi-search-toggle-migemo)

"phi-search-migemo", "phi-search-migemo-backward" は、 phi-search を
起動し migemo を有効にするところまでをひとまとめにしたコマンドです。
migemo がデフォルトで有効になっていて欲しい場合は、 "phi-search",
"phi-search-backward" の代わりにこれらの関数を使うと便利です。たんに
正規表現で検索をしたい場合は、前置引数を渡すことで migemo を無効のま
ま起動することもできます。
