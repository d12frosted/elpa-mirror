This package lets you key binds that normally terminal Emacs can
not use in XTerm. (i.e., C-M-g)

Summary of available key binds:

 | Modifiers  | Description                          |
 |:-----------|:-------------------------------------|
 | S          | space key with shift
 | C          | [2-8] (note: xterm.el supports other key binds)
 | C-S        | [A-Z]
 | C-M        | "g" and space keys
 | M-S        | [A-Z]
 | C-M-S      | [A-Z]
 | s or s-S   | from space to "~" (almost 8 bits characters without control sequences)
 | H or H-S   | same as s-S, but use Hyper modifier

Usage for XTerm:

You may need to configure your .Xresources file if you don't use
XTerm yet. (You can update by xrdb command)

   -- configuration
   XTerm*VT100.eightBitInput: false
   XTerm*vt100.formatOtherKeys: 1
   -- end of configuration

Put below configuration to your .emacs

-- configuration --
(require ’cl-lib)
(add-hook
 'tty-setup-hook
 '(lambda ()
    (cl-case (assoc-default 'terminal-initted (terminal-parameters))
      (terminal-init-xterm
       (xterm-keybinder-setup)))))
-- configuration end --

Then start your emacs with xterm and the option.

-- shell script example --
  #!/bin/sh
  xtermopt=path/to/this-repository/xterm-option
  eval "xterm -xrm `${xtermopt}` -e emacsclient -t -a ''"
-- shell script example end --


Note:
You may need following configuration at .Xresources and update it by
xrdb command.

Usage for URxvt:

Put below configuration to your .emacs

  (require 'cl-lib)
  (add-hook
   'tty-setup-hook
   '(lambda ()
      (cl-case (assoc-default 'terminal-initted (terminal-parameters))
        (terminal-init-rxvt
         (when (getenv "COLORTERM" (selected-frame))
           (urxvt-keybinder-setup))))))

Start URxvt daemon:

  $ urxvtd -q -o -f

Then start your emacs using emacs-urxvt-client file.

$ emacs_urxvt_client=/path/to/emacs-urxvt-client \
  ${emacs-urxvt-client} -e emacscliet -t &

(The main content of emacs-urxvt-client file is just a configuration
to use emacs keybindings.)
