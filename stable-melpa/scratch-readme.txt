
Scratch
=======

Scratch is an extension to Emacs that enables one to create scratch
buffers that are in the same mode as the current buffer.  This is
notably useful when working on code in some language; you may grab
code into a scratch buffer, and, by virtue of this extension, do so
using the Emacs formatting rules for that language.

Scratch is available from MELPA.


Usage
=====

- `M-x scratch' Immediately create a scratch buffer with the same
major mode as the current buffer’s.  If the region is active, copy
it to the scratch buffer.  If a scratch buffer already exists, pop
to it (and do nothing with the region).

- `C-u M-x scratch' Prompts for a major mode to create a scratch
buffer with.


Binding
=======

`C-c s' is a good mnemonic binding for scratch-el:


(define-key (current-global-map) "\C-cs" #'scratch)


Customization
=============

If you want to customize the behavior of all scratch buffers, you
can place hooks in `scratch-create-buffer-hook'.

For per-mode customizations, you can add a hook to the mode, and
check `scratch-buffer' inside it.  For example, to set a default
title on all `org-mode' scratch buffers, you could do:


(add-hook 'org-mode-hook
          (lambda ()
            (when scratch-buffer
              (save-excursion
                (goto-char (point-min))
                (insert "#+TITLE: Scratch\n\n")))))
