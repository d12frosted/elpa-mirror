
 This package is for users of both Emacs and Anki, who'd like to
 make Anki cards in Org mode.  With this package, Anki cards can be
 made from an Org buffer like below (inspired by org-drill):

 * Sample                  :emacs:lisp:programming:
   :PROPERTIES:
   :ANKI_DECK: Computing
   :ANKI_NOTE_TYPE: Basic
   :END:
 ** Front
    How to say "hello world" in elisp?
 ** Back
    #+BEGIN_SRC emacs-lisp
      (message "Hello, world!")
    #+END_SRC

 This package extends Org-mode's built-in HTML backend to generate
 HTML for contents of note fields with specific syntax (e.g. latex)
 translated to Anki style.

 For this package to work, you have to setup these external dependencies:
 - Anki
 - AnkiConnect, an Anki addon that runs an RPC server over HTTP to expose
                Anki functions as APIs, for installation instructions see
                https://github.com/FooSoft/anki-connect#installation
 - curl

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
