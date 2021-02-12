Overview:

guide-key.el displays the available key bindings automatically and dynamically.
guide-key aims to be an alternative of one-key.el.

Here are some features of this library.
- guide-key automatically pops up the keys following your favorite
  prefixes. Moreover, even if you change key bindings, guide-key follows the
  change dynamically.
- guide-key can highlight particular commands. This makes it easy to find a
  command you are looking for, and to learn its key binding.
- guide-key doesn't overwrite existing commands and key bindings, so there
  is no interference with `describe-key' and `describe-bindings'.


Installation:

I added guide-key to MELPA. You can install guide-key with package.el.
Because guide-key depends on popwin.el, popwin.el is also installed.

If you don't have package.el, please download popwin.el and guide-key.el
directly from https://github.com/m2ym/popwin-el and
https://github.com/kai2nenobu/guide-key, and then put them in your
`load-path'.


Basic usage:

You just add your favorite prefix keys to `guide-key/guide-key-sequence'
as below.

  (require 'guide-key)
  (setq guide-key/guide-key-sequence '("C-x r" "C-x 4"))
  (guide-key-mode 1) ; Enable guide-key-mode

When you press these prefix keys, key bindings are automatically
popped up after a short delay (1 second by default).

To activate guide-key for any key sequence instead of just the ones
listed above then use:

  (setq guide-key/guide-key-sequence t)

guide-key can highlight commands which match a specified regular expression.
Key bindings following "C-x r" are rectangle family, register family and
bookmark family.  If you want to highlight only rectangle family
commands, put this setting in your init.el.

  (setq guide-key/highlight-command-regexp "rectangle")

This feature makes it easy to find commands and learn their key bindings.
If you want to highlight all families, you can specify multiple regular
expressions and faces as below.

  (setq guide-key/highlight-command-regexp
        '("rectangle"
          ("register" . font-lock-type-face)
          ("bookmark" . font-lock-warning-face)))

If an element of `guide-key/highlight-command-regexp' is cons, its car
means a regular expression to highlight, and its cdr means a face put on
command names.

Moreover, prefix commands are automatically highlighted.

Depending on your level of emacs experience, you may want a shorter or
longer delay between pressing a key and the appearance of the guide
buffer.  This can be controlled by setting `guide-key/idle-delay':

  (setq guide-key/idle-delay 0.1)

The guide buffer is displayed only when you pause between keystrokes
for longer than this delay, so it will keep out of your way when you
are typing key sequences that you already know well.

I've confirmed that guide-key works well in these environments.
- Emacs 24.2, Ubuntu 12.04 or Windows 7 64bit
- Emacs 23.3, Ubuntu 12.04 or Windows 7 64bit
- Emacs 22.3, Windows 7 64bit
- Emacs 24.3.1, OS X 10.9
If popwin works, I think guide-key will work as well. You can use
guide-key with Emacs working in terminal.


Advanced usage:

It is bothering to add many prefixes to `guide-key/guide-key-sequence'.
`guide-key/recursive-key-sequence-flag' releases you from this problem.
If `guide-key/recursive-key-sequence-flag' is non-nil, guide-key checks a
input key sequence recursively. That is, if "C-x 8 ^" is an input key
sequence, guide-key checks whether `guide-key/guide-key-sequence' includes
"C-x 8" and "C-x".

For example, if you configure as below,

  (setq guide-key/guide-key-sequence '("C-x"))
  (setq guide-key/recursive-key-sequence-flag t)

the guide buffer is popped up when you input "C-x r", "C-x 8" and
any other prefixes following "C-x".


You can add extra settings in a particular mode. Please use
`guide-key/add-local-guide-key-sequence',
`guide-key/add-local-highlight-command-regexp' and the hook of
that mode.


This code is a example of org-mode.

  (defun guide-key/my-hook-function-for-org-mode ()
    (guide-key/add-local-guide-key-sequence "C-c")
    (guide-key/add-local-guide-key-sequence "C-c C-x")
    (guide-key/add-local-highlight-command-regexp "org-"))
  (add-hook 'org-mode-hook 'guide-key/my-hook-function-for-org-mode)

In respect of `guide-key/guide-key-sequence', you can add mode specific key
sequences without `guide-key/add-local-guide-key-sequence'. For example,
configure as below.

  (setq guide-key/guide-key-sequence
        '("C-x r" "C-x 4"
          (org-mode "C-c C-x")
          (outline-minor-mode "C-c @")))

In this case, if the current major mode is `org-mode', guide key bindings
following "C-c C-x".  If `outline-minor-mode' is enabled, guide key bindings
following "C-c @".


`guide-key' can work with key-chord.el.  If you want to guide key bindings
following key chord, you need to execute
`guide-key/key-chord-hack-on'.  Then, add your favorite key chord to
`guide-key/guide-key-sequence' as below.

  (key-chord-define global-map "@4" 'ctl-x-4-prefix)

  (guide-key/key-chord-hack-on)
  (setq guide-key/guide-key-sequence '("<key-chord> @ 4" "<key-chord> 4 @"))

If =guide-key/recursive-key-sequence-flag= is non-nil, more simple.

  (guide-key/key-chord-hack-on)
  (setq guide-key/recursive-key-sequence-flag t)
  (setq guide-key/guide-key-sequence '("<key-chord>"))

In this case, key bindings are popped up when you type any of key chords.

This hack *may be dangerous* because it advices primitive functions;
`this-command-keys' and `this-command-keys-vector'.


Here are some functions and variables which control guide-key.
- `guide-key-mode':
  guide-key-mode is implemented as a minor mode.
  Excuting M-x guide-key-mode toggles whether guide-key is enabled or
  not.  Because guide-key-mode is a global minor mode, guide-key-mode is
  enabled in all buffers or disabled in all buffers.
- `guide-key/popup-window-position':
  This variable controls where a guide-key buffer is popped up. A value of
  this variable is one of `right', `bottom', `left', `top'. The default
  value is `right'.
- `guide-key/polling-time':
  This variable controls a polling time. The default value is 0.1 (in seconds).
- `guide-key/idle-delay':
  This variable controls the delay between starting a key sequence and
  popping up the guide buffer. The default value is 1.0 (in seconds),
  which means that guide-key will keep out of your way unless you hesitate
  in the middle of a key sequence .  Set this to 0.0 to revert to the old
  default behavior.
- `guide-key/text-scale-amount':
  This variable controls the size of text in guide buffer. The default
  value is 0 (it means default size in Emacs). If you want to enlarge
  text, set positive number. Otherwise, set negative number.

Enjoy!
