
Visit https://github.com/kuanyui/kaomoji.el
to see screenshot & usage guide.

======= Usage =======
(require 'kaomoji), then M-x `kaomoji'

=== Customization ===
Variables:

`kaomoji-table' : The main table contains '(((ALIAS ...) . KAOMOJI) ...)
You can customize like this to append new items to this talbe:

(setq kaomoji-table
      (append '((("angry" "furious") . "(／‵Д′)／~ ╧╧ ")
                (("angry" "punch") . "#ﾟÅﾟ）⊂彡☆))ﾟДﾟ)･∵"))
              kaomoji-table))

`kaomoji-patterns-inserted-along-with' : When your input (from Helm
minibuffer) contains any of the patterns, insert the input along
with the kaomoji.

(setq kaomoji-patterns-inserted-along-with nil) to disable this
function.

`kaomoji-insert-user-input-at' : 'left-side or 'right-side
