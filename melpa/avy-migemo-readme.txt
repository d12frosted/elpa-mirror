This package is a minor mode of avy for using migemo.

Migemo which is a library for incremental search has Japanese dictionaries.
It could be used as abbreviation matching for other languages
by preparing user's migemo dictionaries or customizing `avy-migemo-get-function'.

`avy-migemo-get-function' can also use `char-fold-to-regexp' as below.
(setq avy-migemo-get-function 'char-fold-to-regexp)


The following functions are provided:

  + avy-migemo-goto-char
  + avy-migemo-goto-char-2
  + avy-migemo-goto-char-in-line
  + avy-migemo-goto-char-timer
  + avy-migemo-goto-subword-1
  + avy-migemo-goto-word-1
  + avy-migemo-isearch
  + avy-migemo-org-goto-heading-timer
  + avy-migemo--overlay-at
  + avy-migemo--overlay-at-full
  + avy-migemo--read-candidates

 These are the same as avy's predefined functions
 except for adding candidates via migemo (simply using migemo instead of `regexp-quote').

The following extensions are available:

  + avy-migemo-e.g.zzz-to-char.el
  + avy-migemo-e.g.ivy.el
  + avy-migemo-e.g.swiper.el
  + avy-migemo-e.g.counsel.el

Further information is available from:
https://github.com/momomo5717/avy-migemo  (README.org or README.jp.org)

Setup:
(add-to-list 'load-path "/path/to/avy-migemo")
(require 'avy-migemo)
;; `avy-migemo-mode' overrides avy's predefined functions using `advice-add'.
(avy-migemo-mode 1)
(global-set-key (kbd "M-g m m") 'avy-migemo-mode)

;; If you would like to restrict the length of displayed keys within 2
;; for `avy-style' of at-full, `avy-migemo-at-full-max' provides it.
(custom-set-variables '(avy-migemo-at-full-max 2))
