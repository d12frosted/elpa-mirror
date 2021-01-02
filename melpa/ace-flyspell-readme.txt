______________

ACE-FLYSPELL

Junpeng Qiu
______________


Table of Contents
_________________

1 Setup
2 Usage
.. 2.1 `ace-flyspell-jump-word'
.. 2.2 `ace-flyspell-correct-word'
.. 2.3 `ace-flyspell-dwim'
3 Acknowledgment


[[file:http://melpa.org/packages/ace-flyspell-badge.svg]]
[[file:http://stable.melpa.org/packages/ace-flyspell-badge.svg]]

*UPDATE 2017-01-24*: Now use `avy' instead of `ace-jump-mode'.

Jump to and correct spelling errors using `avy' and flyspell. Inspired
by [abo-abo(Oleh Krehel)]'s [ace-link].


[[file:http://melpa.org/packages/ace-flyspell-badge.svg]]
http://melpa.org/#/ace-flyspell

[[file:http://stable.melpa.org/packages/ace-flyspell-badge.svg]]
http://stable.melpa.org/#/ace-flyspell

[abo-abo(Oleh Krehel)] https://github.com/abo-abo/

[ace-link] https://github.com/abo-abo/ace-link


1 Setup
=======

,----
| (add-to-list 'load-path "/path/to/ace-flyspell")
| (require 'ace-flyspell)
`----

Optional:
,----
| M-x ace-flyspell-setup
`----

If you call `M-x ace-flyspell-setup' , then this setup binds the
command `ace-flyspell-dwim' to C-., which is originally bound to
`flyspell-auto-correct-word' if you enable the `flyspell-mode'. Of
course, you can choose to change the key binding.

Usually, you should enable `flyspell-mode' because this package aims
to jump to and correct spelling errors detected by `flyspell', or at
least you need to run `flyspell-buffer' to detect spelling errors.


2 Usage
=======

There are three available commands:


2.1 `ace-flyspell-jump-word'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This command jumps to an spelling error using `avy', and move the
point to where the spelling error is.

The following demo shows the usage of `ace-flyspell-jump-word':
[./screencasts/ace-flyspell-jump-word.gif]

If you prefer this command to the following `ace-flyspell-dwim' (which
will be bound to C-. if you call `M-x ace-flyspell-setup'), you should
probably give it a key binding.


2.2 `ace-flyspell-correct-word'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This command is different from `ace-flyspell-jump-word' in the sense
that it aims to *correct* rather than *jump to* the spelling error. At
first, it looks like `ace-flyspell-jump-word', but after you jump to
the misspelt word, it will enter another /mode/, where you hit . to
invoke `flyspell-auto-correct-word' to correct the current misspelt
word and hit any other key to accept the correction and return to the
original position. You can also hit , to save the current word into
personal dictionary.

This command is useful when you're writing an article and want to
temporarily go back to some spelling error and return to where you
left off after fixing the error.


2.3 `ace-flyspell-dwim'
~~~~~~~~~~~~~~~~~~~~~~~

If the word under the cursor is misspelt, then this command is
identical to `flyspell-auto-correct-word', otherwise it will call
`ace-flyspell-correct-word' to jump to and correct some spelling
error.

This command is bound to C-. after you call `M-x ace-flyspell-setup'.

The following demo shows the usage of `ace-flyspell-dwim' (Since there
is no misspelt word at the cursor, `ace-flyspell-dwim' actually
performs the same thing as `ace-flyspell-correct-word' does):
[./screencasts/ace-flyspell-dwim.gif]


3 Acknowledgment
================

- [avy]
- [ace-link]


[avy] https://github.com/abo-abo/avy

[ace-link] https://github.com/abo-abo/ace-link
