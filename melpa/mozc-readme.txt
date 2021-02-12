mozc-mode is a minor mode to input Japanese text using Mozc server.
mozc-mode directly communicates with Mozc server and you can use
all features of Mozc, such as suggestion and prediction as well as
regular conversion.

Supported Emacs version and environment:

mozc-mode supports Emacs version 22.1 and later.

How to set up mozc-mode:

1. Environment settings

You need to install a helper program called 'mozc_emacs_helper'.
You may need to set PATH environment variable to the program, or
set `mozc-helper-program-name' to the path to the program.
You need to install this mozc.el as well.

Most of Unix-like distributions install the helper program to
/usr/bin/mozc_emacs_helper and mozc.el to an appropriate site-lisp
directory (/usr/share/emacs/site-lisp/emacs-mozc for example)
by default, and you may have nothing to do on your side.

2. Settings in your init file

mozc-mode supports LEIM (Library of Emacs Input Method) and
you only need the following settings in your init file
(~/.emacs.d/init.el or ~/.emacs).

  (require 'mozc)  ; or (load-file "/path/to/mozc.el")
  (setq default-input-method "japanese-mozc")

Having the above settings, just type \C-\\ which is bound to
`toggle-input-method' by default.

Note for advanced users:
mozc-mode is provided as a minor-mode and it's able to work
without LEIM.  You can directly enable mozc-mode by running
`mozc-mode' command.

3. Customization

3.1. Server-side customization

By the design policy, Mozc maintains most of user settings on
the server side.  Clients, including mozc.el, of Mozc do not
have many user settings on their side.

You can change a variety of user settings through a GUI command
line tool 'mozc_tool' which must be shipped with the mozc server.
The command line tool may be installed to /usr/lib/mozc or /usr/lib
directory.
You need a command line option '--mode=config_dialog' as the
following.

  $ /usr/lib/mozc/mozc_tool --mode=config_dialog

Then, it shows a GUI dialog to edit your user settings.

Note these settings are effective for all the clients of Mozc,
not limited to mozc.el.

3.2. Client-side customization.

Only the customizable item on mozc.el side is the key map for kana
input.  When you've chosen kana input rather than roman input,
a kana key map is effective, and you can customize it.

There are two built-in kana key maps, one for 106 JP keyboards and
one for 101 US keyboards.  You can choose one of them by setting
`mozc-keymap-kana' variable.

  ;; for 106 JP keyboards
  (setq mozc-keymap-kana mozc-keymap-kana-106jp)

  ;; for 101 US keyboards
  (setq mozc-keymap-kana mozc-keymap-kana-101us)

For advanced users, there are APIs for more detailed customization
or even creating your own key map.
See `mozc-keymap-get-entry', `mozc-keymap-put-entry',
`mozc-keymap-remove-entry', and `mozc-keymap-make-keymap' and
`mozc-keymap-make-keymap-from-flat-list'.
