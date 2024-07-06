`mowie' let's you define smart commands that cycle through the
result of point-moving commands by consecutive repetitions.  The
package also offers a few point-moving commands.

While repeating the command that you defined using `mowie', it will
skip those point-moving commands that do not provide a point which
has not been visited in the running repetition so far.  In a
similar manner, it currently also avoids the point as it was right
before the repetition started.

`mowie' strives to be minimalistic rather than being generalizable.
If you want something different, consider copying and modifying the
code to your liking, or using an alternative package.

;; Examples:

Cycle through alternatives of `beginning-of-line' and
`end-of-line'!

  (defun my-beginning-of-line ()
    (interactive "^")
    (mowie
      #'beginning-of-line
      #'beginning-of-visual-line
      #'mowie-beginning-of-code
      #'mowie-beginning-of-comment
      #'mowie-beginning-of-comment-text))

  (defun my-end-of-line ()
    (interactive "^")
    (mowie
      #'end-of-line
      #'end-of-visual-line
      #'mowie-end-of-code))

  (keymap-substitute (current-global-map)
    #'move-beginning-of-line #'my-beginning-of-line)

  (keymap-substitute (current-global-map)
    #'move-end-of-line #'my-end-of-line)

Cycle through alternatives of `beginning-of-buffer' and
`end-of-buffer', e.g. in `message-mode'!

  (defun my-beginning-of-message ()
    (interactive "^")
    (mowie
      #'message-goto-body
      #'beginning-of-buffer))

  (defun my-end-of-message ()
    (interactive "^")
    (mowie
      #'message-goto-eoh
      #'end-of-buffer))

  (keymap-set message-mode-map "M-<" #'my-beginning-of-message)
  (keymap-set message-mode-map "M->" #'my-end-of-message)

;; Alternatives:

`mowie' differs from Alex Kost's `mwim' package and from Adam
Porter's `mosey' package by being minimalistic rather than complex;
by being opinionated rather than maximizing flexibility; and by not
providing any (rather opaque) macros.

But also `mowie' uses a unique algorithm that is probably not
reproducible with the other packages: First, it will call as few of
the provided position-functions as needed to determine a unique
position that hasn't been visited in the ongoing cycle of
subsequent repetitions.  And then, it will not move the cursor to
the closest determined position, but it will obey the order of
provided position-functions.  This is achieved with the
`this-command' and `last-command' variables.

;; Roadmap:

Consider introducing a user option determining if last-position
should be avoided while repeating.

Make this package work with `multiple-cursors'.
