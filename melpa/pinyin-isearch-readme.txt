There are two types of search: for pinyin (pīnyīn) and for Chinese
characters (汉字) text.
查找有两种类型：一种是拼音（pīnyīn）查找，另一种是汉字（汉字）查找。

You can use both or select one of them.
你可以同时使用两种，或者只选一种。
Pinyin without tones is used for input.
输入时使用不带声调的拼音。
Input is transformed to regex expression like:
输入会被转化为类似这样的正则表达式：
"\\([嗯唔][爱哀挨埃癌]\\|[乃奶奈耐氖艿鼐柰]\\|n\\([ūúǔùǖǘǚǜ]\\s-*e\\|ü[ēéěè]\\)\\)"

Based on Emacs "chinese-sisheng", "chinese-py", "chinese-punct".

Configuration in ~/.emacs or ~/.emacs.d/init.el:

(require 'pinyin-isearch)
(pinyin-isearch-load) ; force loading (optional) before mode

;; Usage:

M-x pinyin-isearch-mode
C-u C-s for normal search.
or
C-s M-s p/h/s - to activate (p)inyin or (h) Chonese characters (s)trict
C-s M-s F1 - to see all keys

Usage without activation of minor mode:
M-x pinyin-isearch-forward/backward

Customization:

M-x customize-group RET pinyin-isearch

This package depends on Quail minor mode (input multilingual text
easily) and uses it's translation table (named Quail map).
It is possible to adopt this code to many other languages.

Search variants:

By default active search for both pinyin and chinese characters
 with fallback to latin normal characters.

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

;; Todo:

- ('’) in (Fāng'àn) apostrophe, syllable delimiter (隔音符号),
is a strict grammatical requirement used to prevent ambiguity.
Apostrophe use is rare, generally at word boundaries or within
compounds. to prevent misreading when a syllable starting
with a, e, or o follows another syllable directly.
- Upperacase for pinyin.
- Cangjie search
- method for  getting pinyin for chinese characters.
 ;; - allow connecting other input methods.
