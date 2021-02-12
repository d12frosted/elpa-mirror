owcmd.el provides a command to switch to the next window, run a
command, then switch back to the original window automatically.  Use
it to save keystrokes when you need to do just one thing in the other
window, like scroll the buffer, jump to a definition, paste some text,
or quit a temporary buffer.  It is a sort of generalization of the
built-in commands `scroll-other-window' and `scroll-other-window-down'.

This commentary provides a getting-started guide.  For additional
details including alternative packages and information for
contributors, see the README file at this package's homepage URL.

Installation:

Put owcmd.el somewhere in your `load-path', then load it.

  (require 'owcmd)

Quickstart:

To use the package, just bind the command `owcmd-execute-other-window'
to some key combination and you're ready to go.  No minor mode is
used.

  (define-key global-map (kbd "C-c w") #'owcmd-execute-other-window)

If you're using Evil, the following binding is recommended:

  (evil-global-set-key 'normal (kbd "C-w C-e") #'owcmd-execute-other-window)

Now every time you press the shortcut key, Emacs will temporarily
select the next window until you run another command.  You can press
the shortcut key multiple times to select a different target window.
Try this now, assuming you bound "C-c w" as above:

  - Open a file containing at least 5 lines and move point to line 1.
  - Type "C-x 2" to split the current window.
  - Type "C-c w <down>" to move point down one line in the other
    window (i.e., the window just opened).
  - Type "C-c w C-u 3 <down>" to move point down three more lines in
    the other window.
  - Type "C-x 2" to split the first window again.
  - Type "C-c w" several times to cycle through the open windows, then
    type a movement key to move point in the selected window.  Do this
    again, this time selecting a different window.  Notice that the
    original window gets reselected each time.

As this example shows, prefix arguments are supported by default.

Configuration:

You can configure the package's behavior through variables whose
names are prefixed with "owcmd-".  Here is one suggested
customization to try:

  ;; Use C-g to abort owcmd and stay in the selected window.
  (add-to-list 'owcmd-cancel-reselect-commands 'keyboard-quit)
