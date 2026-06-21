There are two types of search: for pinyin (pīnyīn) and for Chinese
characters (汉字) text.

You can use both or select one of them.
Pinyin without tones is used for input.
Input is transformed to regex expression like:
"\\([嗯唔][爱哀挨埃癌]\\|[乃奶奈耐氖艿鼐柰]\\|n\\([ūúǔùǖǘǚǜ]\\s-*e\\|ü[ēéěè]\\)\\)"

Configuration in ~/.emacs or ~/.emacs.d/init.el:

(require 'pinyin-isearch)
(pinyin-isearch--load) ; force loading (optional) before mode

;; Usage:

M-x pinyin-isearch-mode
C-u C-s for normal search.
or
C-s M-s p/h/s - to activate (p)inyin or (h) Chonese characters (s)trict
Chinese characters search submode.
or without activation of minor mode
M-x pinyin-isearch-forward/backward

Customization:

M-x customize-group RET pinyin-isearch

This package depends on Quail minor mode (input multilingual text
easily) and uses it's translation table (named Quail map).
It is possible to adopt this code to many other languages.

Search variants:

By default active search for both pinyin and chinese characters
 with fallback to normal characters. Fallback works for characters
 after pinyin or chinese, not from fist one.

;; Other packages:

- Modern navigation in major modes https://github.com/Anoncheg1/firstly-search
- Ediff no 3-th window	https://github.com/Anoncheg1/ediffnw
- Dired history		https://github.com/Anoncheg1/dired-hist
- Selected window contrast	https://github.com/Anoncheg1/selected-window-contrast
- Copy link to clipboard	https://github.com/Anoncheg1/emacs-org-links
- Solution for "callback hell"	https://github.com/Anoncheg1/emacs-async1
- Restore buffer state	https://github.com/Anoncheg1/emacs-unmodified-buffer1
- outline.el usage		https://github.com/Anoncheg1/emacs-outline-it
- Dates for Org-mode headers	https://github.com/Anoncheg1/emacs-org-history
- Call LLMs and agents from Org-mode cui blocks https://github.com/Anoncheg1/emacs-cui

;; Donate:

- BTC (Bitcoin) address: 1CcDWSQ2vgqv5LxZuWaHGW52B9fkT5io25
- USDT (Tether) address: TVoXfYMkVYLnQZV3mGZ6GvmumuBfGsZzsN
- TON (Telegram) address: UQC8rjJFCHQkfdp7KmCkTZCb5dGzLFYe2TzsiZpfsnyTFt9D

;; TODO:
- fallback to latin search in pinyin or chinese characters was not
 found.
