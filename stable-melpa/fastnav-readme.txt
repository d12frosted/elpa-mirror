Inspired by zap-to-char, this library defines different routines operating on
the next/previous N'th occurrence of a character.  When invoking one of these
commands, the user is interactively queried for a character while the
potential target positions are highlighted.

For example, META-s (jump-to-char-forward) highlights the next occurrences of
each character and prompts for one.  Once the user picks a char, the point is
moved to that position.  Subsequent invocations of META-s before picking a
character increases N, that is, the second, third, etc. occurrences are
highlighted and targeted.

The fastnav-sprint-forward/backward commands apply iterative
jumping until return/C-G is hit, making it possible to reach any
point of the text with just a few keystrokes.

To use it, simply put this file under ~/.emacs.d/, add (require 'fastnav) to
your emacs initialization file and define some key bindings, for example:

(global-set-key "\M-z" 'fastnav-zap-up-to-char-forward)
(global-set-key "\M-Z" 'fastnav-zap-up-to-char-backward)
(global-set-key "\M-s" 'fastnav-jump-to-char-forward)
(global-set-key "\M-S" 'fastnav-jump-to-char-backward)
(global-set-key "\M-r" 'fastnav-replace-char-forward)
(global-set-key "\M-R" 'fastnav-replace-char-backward)
(global-set-key "\M-i" 'fastnav-insert-at-char-forward)
(global-set-key "\M-I" 'fastnav-insert-at-char-backward)
(global-set-key "\M-j" 'fastnav-execute-at-char-forward)
(global-set-key "\M-J" 'fastnav-execute-at-char-backward)
(global-set-key "\M-k" 'fastnav-delete-char-forward)
(global-set-key "\M-K" 'fastnav-delete-char-backward)
(global-set-key "\M-m" 'fastnav-mark-to-char-forward)
(global-set-key "\M-M" 'fastnav-mark-to-char-backward)

(global-set-key "\M-p" 'fastnav-sprint-forward)
(global-set-key "\M-P" 'fastnav-sprint-backward)

This library can be originally found at:
  http://www.emacswiki.org/emacs/FastNav
Package.el compatible version can be found at
  https://github.com/gleber/fastnav.el
it has been uploaded to ELPA and Marmalade

; Changes Log:
  2010-02-05: Fix for org mode, all commands were broken.
              Fix for electric characters in certain modes.
  2010-02-11: Yet another minor fix for switching to next/previous char.
  2010-05-28: Added sprint commands.
  2010-08-06: Make fastnav compatible with package.el
  2011-08-10: Add fastnav- prefix to autoload-ed functions
