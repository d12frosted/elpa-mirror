Configuration sample
(require 'bpe)
(setq ;; whether ask or not if you update your blog post by using bpe
      bpe:no-ask t
      ;; Set your language configuration if needed
      ;; default is your LANG environment.
      bpe:lang "ja_JP.UTF-8"
      ;; do not use --draft when updating(note your view count may disappear)
      bpe:use-real-post-when-updating t)
