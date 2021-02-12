[![MELPA](https://melpa.org/packages/shr-tag-pre-highlight-badge.svg)](https://melpa.org/#/shr-tag-pre-highlight)

This package adds syntax highlighting support for code block in
HTML, rendered by `shr.el'.  The probably most famous user of
`shr.el' is EWW (the Emacs Web Wowser).

Example:

| Before               | After                                 |
| ------               | -----                                 |
| ![](eww-default.png) | ![](eww-with-syntax-highlighting.png) |

In above, I am using EWW to visit
https://emacs-china.org/t/eww/2949. And the color theme is
sanityinc-tomorrow-eighties, from Steve Purcell's
color-theme-sanityinc-tomorrow package

Installation:

This package is available from MELPA. If you use
[use-package](https://github.com/jwiegley/use-package) to manage the init
file, use something like the following:

(use-package shr-tag-pre-highlight
  :ensure t
  :after shr
  :config
  (add-to-list 'shr-external-rendering-functions
               '(pre . shr-tag-pre-highlight))
  (when (version< emacs-version "26")
    (with-eval-after-load 'eww
      (advice-add 'eww-display-html :around
                  'eww-display-html--override-shr-external-rendering-functions))))

Why is `eww-display-html' advised for Emacs version older than 26:

Unfortunately, EWW always overrides
`shr-external-rendering-functions' until
[this commit](http://git.savannah.gnu.org/cgit/emacs.git/commit/?id=45ebbc0301c8514a5f3215f45981c787cb26f915)
(2015-12), but Emacs 25.2 (latest release - 2017-4) doesn't include
this commit.  Thus if you want syntax highlighting in EWW, you have
to use devel version of Emacs (also know as emacs-26 at this
moment) or advice `eww-display-html' as above.
