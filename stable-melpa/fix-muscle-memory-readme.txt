
   When spell correcting, this package forces you to fix your mistakes
   three times to re-write your muscle memory into typing it correctly.

* Motivation

   I used to type 'necessary' wrong... ALL THE TIME.  I misspelled it so
   often that it became part of my muscle memory.  It is one of *THOSE*
   words for me.  There are others, that by muscle or brain memory,
   are "burned in" as a particular pattern.

   This is an attempt to break that pattern, by forcing you to re-type
   your misspelled words 3 times.  This should help overcome any broken
   muscle and brain memory.

* Usage

** Fixing Spelling Mistakes
   - Step 1 :: Require this file
   - Step 2 :: Use M-$ to check the spelling of your misspelled word
   - Step 3 :: follow the directions of the prompt

** Fixing Spelling Mistakes Automagickally

   If you want, you can customize the
   `fix-muscle-memory-load-problem-words' variable, and that will
   force you to fix the typos when you make them, rather than at
   spell-check time.  Alternatively just call
   `fix-muscle-memory-load-problem-words' with nil and an alist of
   problem words in the format of (("tyop" . "typo")).

   Because this uses abbrev mode, you will need to make sure to enable
   it.

** Helping with Extended commands

  If you find yourself using `execute-extended-command' in place of a
  keybinding, using this will help train you.  The first three
  instances of the same extended command will go through normally.
  The next time however you will be told the key-combo to use and then
  prompted to enter it three times.

  Customize `fix-muscle-memory-enable-extended-command' and you're off
  to the races.

** Getting out

  Entering in the wrong answer more than 6 times or so will exit out
  of the loop.  Alternatively C-g (quit) will get you out as well.

** Super Kawaii

  Customize the variable `fix-muscle-memory-use-emoji' to true to use
  cute emoji icons along with text.

** Easy Setup with use-package
#+begin_src emacs-lisp
(use-package 'fix-muscle-memory
  :init
  (setq fix-muscle-memory-use-emoji t)
  :config
  (fix-muscle-memory-load-problem-words 'foo
                                        '(("teh" . "the")
                                          ("comptuer" . "computer")
                                          ("destory" . "destroy")
                                          ("occured" . "occurred")))
  (add-hook 'text-mode-hook 'abbrev-mode)
  (add-hook 'prog-mode-hook 'abbrev-mode)

  (turn-on-fix-muscle-memory-on-extended-command))
#+end_src

* Changelog

   - v 0.1 :: First Version.
   - v 0.2 ::
     - Minor documentation fix.
   - v 0.3 ::
     - Fix bug when using Ispell.
   - v 0.90 :: Almost ready for 1.0!
     - Gave it it's own repository (finally).
     - Added abbrev hook for fixing as-you-type-mistakes.
     - properly manage the response back from `ispell-command-loop'.
     - Added cute emoji.  I couldn't help myself.
     - Added fix-muscle-memory-extended-command
   - v 0.91 ::
     - Fix Spelling mistakes in code.
   - v 0.92 ::
     - Package format fixes from syohex
   - v 0.93 ::
     - Forgot to include emoji jiggerypokery. :(
   - v 0.94 ::
     - Emacs 27 compatability fix.
