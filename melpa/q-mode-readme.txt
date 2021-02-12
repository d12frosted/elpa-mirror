A major mode for editing q (the language written by Kx Systems,
see URL `http://www.kx.com') in Emacs.

Some of its major features include:

 - syntax highlighting (font lock),

 - interaction with inferior q[con] instance,

 - scans declarations and places them in a menu.

To load `q-mode' on-demand, instead of at startup, add this to your
initialization file

(autoload 'q-mode "q-mode")

The add the following to your initialization file to open all .k
and .q files with q-mode as major mode automatically:

(add-to-list 'auto-mode-alist '("\\.[kq]\\'" . q-mode))

If you load ess-mode, it will attempt to associate the .q extension
with S-mode.  To stop this, add the following lines to your
initialization file.

(defun remove-ess-q-extn ()
  (when (assoc "\\.[qsS]\\'" auto-mode-alist)
   (setq auto-mode-alist
         (remassoc "\\.[qsS]\\'" auto-mode-alist))))
(add-hook 'ess-mode-hook 'remove-ess-q-extn)
(add-hook 'inferior-ess-mode-hook 'remove-ess-q-extn)

Use `M-x q' to start an inferior q shell.  Or use `M-x q-qcon' to
create an inferior qcon shell to communicate with an existing q
process.  Both can be prefixed with the universal-argument `C-u` to
customize the arguments used to start the processes.

The first q[con] session opened becomes the activated buffer.
To open a new session and send code to the new buffer, it must be
actived.  Switch to the desired buffer and type `C-c M-RET' to
activate it.

Displaying tables with many columns will wrap around the buffer -
making the data hard to read.  You can use the
`toggle-truncate-lines' function to prevent the wrapping.  You can
then scroll left and right in the buffer to see all the columns.

The following commands are available to interact with an inferior
q[con] process/buffer.  `C-c C-l' sends a single line, `C-c C-f'
sends the surrounding function, `C-c C-r' sends the selected region
and `C-c C-b' sends the whole buffer. If prefixed with `C-u C-u',
or pressing `C-c M-j' `C-c M-f' `C-c M-r' respectively, will also
switch point to the active q process buffer for direct interaction.

If the source file exists on the same machine as the q process,
`C-c M-l' can be used to load the file associated with the active
buffer.

`M-x customize-group' can be used to customize the `q' group.
Specifically, the `q-program' and `q-qcon-program' variables can be
changed depending on your environment.

Q-mode indents each level based on `q-indent-step'.  To indent code
based on {}-, ()-, and []-groups instead of equal width tabs, you
can set this value to nil.

The variables `q-msg-prefix' and `q-msg-postfix' can be customized
to prefix and postfix every msg sent to the inferior q[con]
process.  This can be used to change directories before evaluating
definitions within the q process and then changing back to the root
directory.  To make the variables change values depending on which
file they are sent from, values can be defined in a single line a
the top of each .q file:

/ -*- q-msg-prefix: "system \"d .jnp\";"; q-msg-postfix: ";system \"d .\"";-*-

or at the end:

/ Local Variables:
/ q-msg-prefix: "system \"d .jnp\";"
/ q-msg-postfix: ";system \"d .\""
/ End:
