There are two types of search: for pinyin (pīnyīn) and for Chinese
characters (汉字) text.

You can use both or select one of them.
Pinyin without tones is used for input.
Input is transformed to regex expression like:
"\\([嗯唔][爱哀挨埃癌]\\|[乃奶奈耐氖艿鼐柰]\\|n\\([ūúǔùǖǘǚǜ]\\s-*e\\|ü[ēéěè]\\)\\)"

Configuration in ~/.emacs or ~/.emacs.d/init.el:

(require 'pinyin-isearch)
(pinyin-isearch--activate) ; force loading (optional)
(pinyin-isearch-activate-submodes) ; to activate isearch submodes

Usage:

M-x pinyin-isearch-mode
C-u C-s for normal search.
or
C-s M-s p/h/s - to activate (p)inyin or (h) Chonese characters (s)trict
Chinese characters search submode.
or
M-x pinyin-isearch-forward/backward

Customization:

M-x customize-group RET pinyin-isearch

This package depends on Quail minor mode (input multilingual text
easily) and uses it's translation table (named Quail map).
It is possible to adopt this code to many other languages.
