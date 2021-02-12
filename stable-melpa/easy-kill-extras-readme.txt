
This package contains extra functions for easy-kill/easy-mark:

* easy-mark-word
* easy-mark-sexp
* easy-mark-to-char
* easy-mark-up-to-char

  These are shorthand commands for easy-marking an aimed string at
  point.

* easy-kill-er-expand
* easy-kill-er-unexpand

  These work like `er/expand-region' and `er/contract-region',
  respectively, using the functionality of the `expand-region'
  package.

It also provides the following easy-kill/easy-mark targets:

* `buffer'

  This selects the whole buffer.

* `buffer-before-point'
* `buffer-after-point'

  These work like vi's gg/G commands, respectively.

* `backward-line-edge'
* `forward-line-edge'

  The former is like vi's ^/0 commands, and the latter is just like
  that in the opposite direction.

* `string-to-char-forward'
* `string-to-char-backward'
* `string-up-to-char-forward'
* `string-up-to-char-backward'

  These work like vi's f/F/t/T commands, respectively.

Experimental ace-jump integration into easy-kill is enabled by
default.  `ace-jump-*-mode' can be invoked for selection when in
easy-kill/easy-mark mode.  You can disable this feature via a
customize variable `easy-kill-ace-jump-enable-p'.

Experimental multiple-cursors-mode support for easy-kill is enabled
by default.  `easy-kill' and `easy-mark' will mostly work in
`multiple-cursors-mode'.

Suggested settings are as follows:

  ;; Upgrade `mark-word' and `mark-sexp' with easy-mark
  ;; equivalents.
  (global-set-key (kbd "M-@") 'easy-mark-word)
  (global-set-key (kbd "C-M-@") 'easy-mark-sexp)

  ;; `easy-mark-to-char' or `easy-mark-up-to-char' could be a good
  ;; replacement for `zap-to-char'.
  (global-set-key [remap zap-to-char] 'easy-mark-to-char)

  ;; Integrate `expand-region' functionality with easy-kill
  (define-key easy-kill-base-map (kbd "o") 'easy-kill-er-expand)
  (define-key easy-kill-base-map (kbd "i") 'easy-kill-er-unexpand)

  ;; Add the following tuples to `easy-kill-alist', preferrably by
  ;; using `customize-variable'.
  (add-to-list 'easy-kill-alist '(?^ backward-line-edge ""))
  (add-to-list 'easy-kill-alist '(?$ forward-line-edge ""))
  (add-to-list 'easy-kill-alist '(?b buffer ""))
  (add-to-list 'easy-kill-alist '(?< buffer-before-point ""))
  (add-to-list 'easy-kill-alist '(?> buffer-after-point ""))
  (add-to-list 'easy-kill-alist '(?f string-to-char-forward ""))
  (add-to-list 'easy-kill-alist '(?F string-up-to-char-forward ""))
  (add-to-list 'easy-kill-alist '(?t string-to-char-backward ""))
  (add-to-list 'easy-kill-alist '(?T string-up-to-char-backward ""))
