Fact: There is a way to do something faster, but you forgot.

Dwight K. Schrute-mode or `schrute-mode` for short, is a minor global mode
that will help you to remember that there is a better way to do
something.  By better I mean using commands like `avy-goto-line` instead of
making several invocations of `next-line` in a row with either `C-<down>` or
`C-n` keybindings.  If your memory is like mine, you'll often forget those
features are available, if you commit the mistake of taking the long route,
`schrute-mode` will be there to save the day... just don't forget to
configure it!.

How to configure

add something like this to your Emacs configuration:

(setf schrute-shortcuts-commands '((avy-goto-line   . (next-line previous-line))
                                   (avy-goto-word-1 . (left-char right-char))))

(schrute-mode) ;; and turn on the minor mode.
