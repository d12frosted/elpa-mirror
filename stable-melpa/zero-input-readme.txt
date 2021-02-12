zero-input is a Chinese input method framework for Emacs, implemented as an
Emacs minor mode.

zero-input-pinyin is bundled with zero, to use pinyin input method, add to
~/.emacs file:

  (require 'zero-input)
  (zero-input-set-default-im "pinyin")
  ;; Now you may bind a key to zero-input-mode to make it easy to
  ;; switch on/off the input method.
  (global-set-key (kbd "<f5>") 'zero-input-mode)

Now in any Emacs buffer, you may press F5 and start typing pinyin string.

zero-input supports Chinese punctuation mapping.  There are three modes,
none, basic, and full.  The default is basic mode, which only map most
essential punctuations.  You can cycle zero-punctuation-level in current
buffer by C-c , , You can change default Chinese punctuation level:

  (setq-default zero-input-punctuation-level
    zero-input-punctuation-level-full)

zero-input supports full-width mode.  You can toggle full-width mode in
current buffer by C-c , . You can enable full-width mode by default:

  (setq-default zero-input-full-width-p t)

For other features, you may check README file at
https://gitlab.emacsos.com/sylecn/zero-el/

zero-input.el is auto-generated from multiple other files.  See
zero-input.el.in and build.py for details.  It's created because
package-lint doesn't support multi-file package yet.  See issue #111 at
https://github.com/purcell/package-lint/issues/111
