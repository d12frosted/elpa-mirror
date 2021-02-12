This script provides a minor-mode that improves
backward/forward-word behavior for Japanese words.

tinysegmenter.el とこのファイルを load-path の通ったディレクトリに置
いて、ロードする。

  (require 'jaword)

"jaword-mode" で jaword-mode の有効を切り替える。すべてのバッファで
有効にするには "global-jaword-mode" を用いる。

jaword-mode は subword-mode と同時に有効にすることができないが、
jaword-mode はデフォルトで "hogeFugaPiyo" のような単語を３つの独立し
た単語として扱う。これを無効にするためには、
"jaword-enable-subword" を nil に設定する。

  (setq jaword-enable-subword nil)
