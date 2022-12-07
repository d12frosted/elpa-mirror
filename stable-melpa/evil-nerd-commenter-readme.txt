
This program emulates nerd-commenter.vim by Marty Grenfell.

It helps you comment/uncomment multiple lines without selecting them.

`M-x evilnc-default-hotkeys` assigns hotkey `M-;` to
`evilnc-comment-or-uncomment-lines'

`M-x evilnc-comment-or-uncomment-lines` comment or uncomment lines.

`M-x evilnc-quick-comment-or-uncomment-to-the-line` will comment/uncomment
from current line to specified line.
The last digit(s) of line number is parameter of the command.

For example, `C-u 9 evilnc-quick-comment-or-uncomment-to-the-line` comments
code from current line to line 99 if you current line is 91.

Though this program could be used *independently*, it's recommended to
us it with Evil.

Evil makes you take advantage of power of Vi to comment lines.
For example, you can press key `99,ci` to comment out 99 lines.

Setup:

If comma is your leader key, as most Vim users do, setup is one liner,
  (evilnc-default-hotkeys)

Or else you can set up key bindings of below commands by yourself.
  `evilnc-comment-or-uncomment-lines'
  `evilnc-quick-comment-or-uncomment-to-the-line'
  `evilnc-comment-and-kill-ring-save'
  `evilnc-copy-and-comment-lines'
  `evilnc-comment-or-uncomment-paragraphs'
  `evilnc-comment-box'
  `evilnc-toggle-invert-comment-line-by-line'
  `evilnc-copy-and-comment-operator'
  `evilnc-comment-operator'
  `evilnc-comment-or-uncomment-html-tag'
  `evilnc-comment-or-uncomment-html-paragraphs'

Set up `evilnc-original-above-comment-when-copy-and-comment'
to decide which style to use in `evilnc-copy-and-comment-lines'
and `evilnc-copy-and-comment-operator',
  - Place the commented out text above original text
  - Or place the original text above commented out text

`evilnc-yank-and-comment-operator' (un)comment&yank text in one shot.

Comment text object "c" is defined.  It can have multi-lines.
Press "vac" to select outer object (comment with limiters).
Press "vic" to select inner object (comment without limiter).
You can assign other key instead of "c" to the text object by
customizing `evilnc-comment-text-object'.  Either,
  (setq evilnc-comment-text-object "c")
  (evilnc-default-hotkeys)

Or,
  (setq evilnc-comment-text-object "a")
  (define-key evil-inner-text-objects-map evilnc-comment-text-object 'evilnc-inner-commenter)
  (define-key evil-outer-text-objects-map evilnc-comment-text-object 'evilnc-outer-commenter)

You can list of comments in current buffer through using imenu.
by setup `imenu-create-index-function' to `evilnc-imenu-create-index-function',

  (defun counsel-imenu-comments ()
    (interactive)
    (let* ((imenu-create-index-function 'evilnc-imenu-create-index-function))
      (unless (featurep 'counsel) (require 'counsel))
      (counsel-imenu)))

For certain major modes, you need manual setup to override its original
keybindings,

(defun matlab-mode-hook-config ()
  (local-set-key (kbd "M-;") 'evilnc-comment-or-uncomment-lines))
(add-hook 'matlab-mode-hook 'matlab-mode-hook-config)

Most commands call `evilnc-comment-or-uncomment-region-function'.
You can modify this variable to customize the comment style,

  (with-eval-after-load 'evil-nerd-commenter
    (defun my-comment-or-uncomment-region (start end)
      (let* ((comment-start "aaa")
             (comment-end "bbb"))
        (evilnc-comment-or-uncomment-region-internal start end)))
    (setq evilnc-comment-or-uncomment-region-function
          'my-comment-or-uncomment-region))

See "Options Controlling Comments" in Emacs manual for comment options.

See https://github.com/redguardtoo/evil-nerd-commenter for detail.
