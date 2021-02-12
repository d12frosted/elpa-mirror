This minor is for users who;
- dislike setting `elscreen-display-tab' to `t', because which highjacks `header-line-format'
  which you reserved for the other purpose such as `which-func-mode' or alike.
- dislike the tab menu is displayed at the top.

[Usage]
(require 'elscreen)
(elscreen-start)
(require 'elscreen-tab)
(elscreen-tab-mode)  ; Enable `elscreen-tab'.

(elscreen-tab-set-position 'right) ; Show on the right side.
(elscreen-tab-set-position 'top) ; Show at the top.
(elscreen-tab-set-position 'left) ; Show on the left side.
(elscreen-tab-set-position 'bottom) ; Show at the bottom.
(elscreen-tab-mode -1)  ; Disable `elscreen-tab'.
