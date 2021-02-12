--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

# Please note! mark-multiple has been superseded by multiple-cursors

It has all the functionality of mark-multiple, but with a more robust implementation
and more features.

To get the features from mark-multiple, use:

 - `mc/mark-more-like-this` in place of `mark-more-like-this`
 - `set-rectangular-region-anchor` as a more convenient replacement for `inline-string-rectangle`
 - or `mc/edit-lines` for a more familiar replacement for `inline-string-rectangle`
 - `mc/mark-sgml-tag-pair` in place of `rename-sgml-tag`

Read more about multiple-cursors on [its own page](https://github.com/magnars/multiple-cursors.el).

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

An emacs extension that sorta lets you mark several regions at once.

More precisely, it allows for one master region, with several mirror
regions. The mirrors are updated inline while you type. This allows for some
awesome functionality. Or at least, some more visually pleasing insert and
replace operations.

Video
-----
You can [watch an intro to mark-multiple at Emacs Rocks](http://emacsrocks.com/e08.html).

Done
----
* A general library for managing master and mirrors
* `mark-more-like-this` which selects next/previous substring in the buffer that
  matches the current region.
* `inline-string-rectangle` which works like `string-rectangle` but lets you
  write inline - making it less error prone.
* `rename-sgml-tag` which updates the matching tag while typing.
* `js2-rename-var` which renames the variable on point and all occurrences
  in its lexical scope.

Installation
------------

    git submodule add https://github.com/magnars/mark-multiple.el.git site-lisp/mark-multiple

Then add the modules you want to your init-file:

    (require 'inline-string-rectangle)
    (global-set-key (kbd "C-x r t") 'inline-string-rectangle)

    (require 'mark-more-like-this)
    (global-set-key (kbd "C-<") 'mark-previous-like-this)
    (global-set-key (kbd "C->") 'mark-next-like-this)
    (global-set-key (kbd "C-M-m") 'mark-more-like-this) ; like the other two, but takes an argument (negative is previous)

    (add-hook 'sgml-mode-hook
              (lambda ()
                (require 'rename-sgml-tag)
                (define-key sgml-mode-map (kbd "C-c C-r") 'rename-sgml-tag)))

Feel free to come up with your own keybindings.

Ideas for more
--------------
* `js-rename-local-var` which renames the variable at point in the local file.

Bugs and gotchas
----------------
* Adding a master and mirrors does not remove the active region. This might feel
  strange, but turns out to be practical.

* The current mark-multiple general library lets you do stupid shit, like adding
  overlapping mirrors. That's only a problem for people who want to write their
  own functions using `mm/create-master` and `mm/add-mirror`.

* Seems like there is some conflict with undo-tree.el, which sometimes clobbers
  the undo history. I might be doing something particularly stupid. Looking into it.

* Reverting the buffer with active marks makes them unremovable.

