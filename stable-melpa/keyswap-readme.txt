keyswap is a minor mode that allows swapping the commands of two keys.
It comes with a default set of keys to swap of the number keys and their
shifted counterparts along with the '-' and '_' key.
This is different to the function `keyboard-translate' as swaps may be done
on a per-major-mode basis.
This is generally useful in programming languages where symbols are more
often used than numbers.

To use keyswap-mode, make sure this file is in the Emacs load-path:
  (add-to-list 'load-path "/path/to/directory/or/file")

Then require keyswap:
  (require 'keyswap)

To toggle between swapped and not-swapped sets of keys, use the command
(keyswap-mode) or M-x keyswap-mode

Keys are swapped on a major-mode basis.
If you change the swapped keys in one buffer these changes are propagated to
all other major modes.

The set of keys to swap is stored in the buffer local `keyswap-pairs'
variable.
This variable is an alist of vectors ready for passing to `define-key' that
should be swapped when `keyswap-mode' is turned on.
Its default is to swap all number keys and their shifted alternatives, along
with the - and _ keys.

In order to change the current swapped keys one should modify this list with
`keyswap-add-pairs' or `keyswap-remove-pairs', and then run
`keyswap-update-keys' like so
(keyswap-add-pairs ?\: ?\;)
(keyswap-remove-pairs ?\- ?\_)
(keyswap-update-keys)

Without running `keyswap-update-keys' the changes in `keyswap-pairs' will not
be propagated into the action of `keyswap-mode'.

There are some provided hooks for common modifications of `keyswap-pairs'
that modify the pairs to swap and call `keyswap-update-keys' accordingly.
These are `keyswap-include-braces' to swap [ and ] with { and },
`keyswap-include-quotes' to swap ' with ", `keyswap-tac-underscore-exception'
to *not* swap - and _, and finally `keyswap-colon-semicolon' to swap : and ;.

It is recommended to turn on `keyswap-mode' by default in programming buffers
with
(add-hook 'prog-mode-hook 'keyswap-mode)

and then add modifications for each major-mode you desire accordingly, e.g.

(with-eval-after-load 'cc-vars
  (add-hook 'c-mode-common-hook 'keyswap-include-quotes))

(with-eval-after-load 'lisp-mode
  (add-hook 'emacs-lisp-mode-hook 'keyswap-tac-underscore-exception)
  (add-hook 'lisp-mode-hook 'keyswap-tac-underscore-exception))

To toggle between having keys swapped and not, just turn on and off
`keyswap-mode'.

Some common packages like `paredit' change bindings on some keys.
In order to keep the `keyswap-mode' mappings in sync it is recommended you
add `keyswap-update-keys' to the relevant hook.
(add-hook 'paredit-mode-hook 'keyswap-update-keys)

One package that requires more than the normal amount of configuration is the
`wrap-region' package.
Because this changes the bindings on certain keys, it requires
`keyswap-update-keys' to be in its hook.
(add-hook 'wrap-region-mode-hook 'keyswap-update-keys)
Due to the way that it falls back to inserting a single character when the
region is not active, you need an advice around `wrap-region-fallback' that
ensures `keyswap-mode' is not on at the time it is called.
  (defadvice wrap-region-fallback (around keyswap-negate protect activate)
    "Ensure that `keyswap-mode' is not active when
    `wrap-region-fallback' is getting called."
    (let ((currently-on keyswap-mode))
      (when currently-on (keyswap-mode 0))
      ad-do-it
      (when currently-on (keyswap-mode 1))))


Though the conveniance functions don't account for key chords (e.g. C-x j r),
the utility functions work well with them.
Hence you can manually swap these with code similar to the below.
(push (cons [?\ ?r ?j] [?\ ?r ?\ ]) keyswap-pairs)
(keyswap-update-keys)


In order to have the same swapped keys in `isearch-mode' as in the buffer
you're currently editing, you can add
(add-hook 'isearch-mode-hook 'keyswap-isearch-start-hook)
into your config.

To have swapped keys when using `avy', you can have
(with-eval-after-load 'avy (keyswap-avy-integrate))
in your config.
