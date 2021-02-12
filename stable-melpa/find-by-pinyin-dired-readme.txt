Place this file somewhere (say ~/.emacs/lisp), add below code into your .emacs:
(add-to-list 'load-path "~/.emacs.d/lisp/")
(require 'find-by-pinyin-dired)

Then `M-x find-by-pinyin-dired' or `M-x find-by-pinyin-in-project-dired'.

  - If `find-by-pinyin-no-punc-p' is `t': English punctuation is converted to
    Chinese punctuation.

  - If `find-by-pinyin-traditional-p' is `t': traditional Chinese characters are used
    instead of simplified Chinese characters.

  - If `find-by-pinyin-only-chinese-p' is `t': the resulting regular expression doesn't
    contain the English letter.
