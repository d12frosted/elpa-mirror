 -----------

To install, copy this file somewhere in your load-path and add this line to
your .emacs:

   (require 'lusty-explorer)

To launch the explorer, run or bind the following commands:

   M-x lusty-file-explorer
   M-x lusty-buffer-explorer

And then use as you would `find-file' or `switch-to-buffer'. A split window
shows the *Lusty-Matches* buffer, which updates dynamically as you type
using a fuzzy matching algorithm.  One match is highlighted; you can move
the highlight using C-n / C-p (next, previous) and C-f / C-b (next column,
previous column).  Pressing TAB or RET will select the highlighted match
(with slightly different semantics).

To create a new buffer with the given name, press C-x e.  To open dired at
the current viewed directory, press C-x d.

Note: lusty-explorer.el benefits greatly from byte-compilation.  To byte-
compile this library:

   $ emacs -Q -batch -f batch-byte-compile lusty-explorer.el

(You can also do this from within Emacs, but it's best done in a clean
session.)  Then, restart Emacs or M-x load-library and choose the newly
generated lusty-explorer.elc file.

; Customization:
 --------------

To modify the keybindings, use something like:

  (add-hook 'lusty-setup-hook 'my-lusty-hook)
  (defun my-lusty-hook ()
    (define-key lusty-mode-map "\C-j" 'lusty-highlight-next))

Respects these variables:
  completion-ignored-extensions

Development:    <http://github.com/sjbach/lusty-emacs>
Further info:   <http://www.emacswiki.org/cgi-bin/wiki/LustyExplorer>


; Contributors:

Tassilo Horn
Jan Rehders
Hugo Schmitt
Volkan Yazici
René Kyllingstad
Alex Schroeder
Sasha Kovar
John Wiegley
Johan Walles
