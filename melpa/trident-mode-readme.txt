This is an Emacs minor mode and collection of commands for working with
Parenscript code in SLIME and sending it to the browser via Skewer. The goal
is to create an environment for hacking Parenscript which fits as naturally
as possible into the Lisp style of interactive development.

** Installation

Trident is available on MELPA, meaning a simple =M-x package-install RET
trident-mode RET= will install both it and its dependencies.

To enable MELPA, if you haven't already, add something like the following to
your Emacs configuration:

  (require 'package)
  (add-to-list 'package-archives
               '("melpa" . "http://melpa.milkbox.net/packages/") t)
  (package-initialize)

The dependencies that will be installed are:
  - SLIME
  - Skewer
  - dash.el

Trident also requires a Common Lisp implementation and Parenscript.
Quicklisp is the best way to install Parenscript.

** Setup

To enable trident-mode in a SLIME buffer: M-x trident-mode.

To have lisp-mode, slime-mode, and trident-mode all enable automatically for
any file with an extension of ".paren":

  (add-to-list 'auto-mode-alist (cons "\\.paren\\'" 'lisp-mode))
  (add-hook 'lisp-mode-hook
            #'(lambda ()
                (when (and buffer-file-name
                           (string-match-p "\\.paren\\>" buffer-file-name))
                  (unless (slime-connected-p)
                    (save-excursion (slime)))
                  (trident-mode +1))))

Parenscript must be loaded in your Common Lisp image, and you'll probably
also want to import its symbols:

  (ql:quickload :parenscript)
  (use-package :parenscript)

With the above taken care of it's time to skewer the browser. See Skewer's
README for detailed information on the multiple ways you can connect to a
site - including sites on servers you don't control.

The fastest way to simply try things out is to run M-x run-skewer. Skewer
will load an empty page in your browser and connect to it. You can
immediately begin using Trident's evaluation commands (described below); to
additionally open a JavaScript REPL you can run M-x skewer-repl.

** Commands

*** Code expansion commands

These commands generate JavaScript from the Parenscript code and display it
but don't send it to the browser for evaluation:

   - trident-expand-sexp
   - trident-expand-last-expression
   - trident-expand-defun
   - trident-expand-region
   - trident-expand-buffer
   - trident-expand-dwim

From within an expansion buffer you can press e to send the JavaScript to
the browser, w to copy it to the kill ring, s to save it to a file (you'll
be prompted for the destination) or q to dismiss the buffer. The copy
command, w, acts on the region if it's active or the entire buffer
otherwise.

Additionally, you can use M-x trident-compile-buffer-to-file to expand the
current buffer and save the generated code directly to a file.

*** Code evaluation commands

These commands first compile the Parenscript code to JavaScript and then
immediately send to it the browser to be evaluated:

   - trident-eval-sexp
   - trident-eval-last-expression
   - trident-eval-defun
   - trident-eval-region
   - trident-eval-buffer
   - trident-eval-dwim

** Key bindings

The traditional set of code evaluation key bindings is a poor fit for
Trident,since they would shadow SLIME's equivalent commands and that's
probably not what you want. That leaves us without a clear convention to
follow, so by default we don't establish any key bindings at all. However,
the function trident-add-keys-with-prefix will add two-key key bindings for
all commands behind a prefix of your choice.

For example: (trident-add-keys-with-prefix "C-c C-e"). The key sequence for
trident-eval-region is "e r", so it's now bound to "C-c" "C-e er"

The full list of key bindings trident-add-keys-with-prefix will establish
is:

   - "e RET" -- trident-eval-sexp
   - "e e" -- trident-eval-last-expression
   - "e d" -- trident-eval-defun
   - "e r" -- trident-eval-region
   - "e b" -- trident-eval-buffer
   - "e SPC" -- trident-eval-dwim
   - "x RET" -- trident-expand-sexp
   - "x e" -- trident-expand-last-expression
   - "x d" -- trident-expand-defun
   - "x r" -- trident-expand-region
   - "x b" -- trident-expand-buffer
   - "x SPC" -- trident-expand-dwim

Evaluation commands begin with an "e", expansion commands with "x". The
second letter is generally mnemonic but not always. The -sexp commands use
RET in correspondence to slime-expand-1, and the -dwim commands use the
space bar because it's easy and comfortable to hit.

Please consider these keys provisional, and let me know if you have any
ideas for improving the arrangement.

If you really want to shadow SLIME's key bindings in buffers where
trident-mode is active you could do something like this:

  (defun steal-slime-keys-for-trident! ()
    ;; Don't affect all SLIME buffers, just where invoked
    (make-local-variable 'slime-mode-map)
    (let ((map slime-mode-map))
      (define-key map (kbd "C-x C-e") nil)
      (define-key map (kbd "C-c C-r") nil)
      (define-key map (kbd "C-M-x")   nil)
      (define-key map (kbd "C-c C-k") nil)
      (define-key map (kbd "C-c C-m") nil))
    (let ((map trident-mode-map))
      (define-key map (kbd "C-x C-e") 'trident-eval-last-expression)
      (define-key map (kbd "C-c C-r") 'trident-eval-region)
      (define-key map (kbd "C-M-x")   'trident-eval-defun)
      (define-key map (kbd "C-c C-k") 'trident-eval-buffer)
      (define-key map (kbd "C-c C-m") 'trident-expand-sexp)))

  (add-hook 'trident-mode-hook 'steal-slime-keys-for-trident!)

** Other amenities

slime-selector is a great feature and Trident can optionally integrate with
it. If you call trident-add-slime-selector-methods, two entries related to
trident-mode will be added. One, invoked with p, will take you to the most
recently visited buffer where trident-mode is active (excluding buffers
which are already visible). The other, on P, will take you to a scratch
buffer with trident-mode enabled, creating the buffer if necessary.

Speaking of the scratch buffer, the trident-scratch command will take you
straight there.

** Still do be done

   - Add some tests.
   - Better documentation.
   - Look into adding a REPL.
   - See if more integration with SLIME is possible.
   - Command(s) for compiling to a file.
   - Similar support for CL-WHO and/or CSS-LITE?
   - Add support for Customize.

** Contributing

Contributions are very welcome. Since I've just started working on this and
don't have everything figured out yet, please first contact me on GitHub or
send me an email so we can talk before you start working on something.
