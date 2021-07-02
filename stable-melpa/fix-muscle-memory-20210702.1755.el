;;; fix-muscle-memory.el --- Simple hacks to fix muscle memory problems

;; Copyright (C) 2012-2016 Jonathan Arkell

;; Author: Jonathan Arkell <jonnay@jonnay.net>
;; Created: 5 Oct 2012
;; Keywords: spelling typing
;; Package-Version: 20210702.1755
;; Package-Commit: b8d4b8025d758762f4459c70c3a7a209ead865ed
;; Version: 0.94

;; This file is not part of GNU Emacs.
;; Released under the GPL v3.0

;;; Commentary:
;; 
;;    When spell correcting, this package forces you to fix your mistakes
;;    three times to re-write your muscle memory into typing it correctly.
;; 
;; * Motivation
;; 
;;    I used to type 'necessary' wrong... ALL THE TIME.  I misspelled it so
;;    often that it became part of my muscle memory.  It is one of *THOSE*
;;    words for me.  There are others, that by muscle or brain memory,
;;    are "burned in" as a particular pattern.
;; 
;;    This is an attempt to break that pattern, by forcing you to re-type
;;    your misspelled words 3 times.  This should help overcome any broken
;;    muscle and brain memory.
;; 
;; * Usage
;; 
;; ** Fixing Spelling Mistakes 
;;    - Step 1 :: Require this file
;;    - Step 2 :: Use M-$ to check the spelling of your misspelled word
;;    - Step 3 :: follow the directions of the prompt
;; 
;; ** Fixing Spelling Mistakes Automagickally
;; 
;;    If you want, you can customize the
;;    `fix-muscle-memory-load-problem-words' variable, and that will
;;    force you to fix the typos when you make them, rather than at
;;    spell-check time.  Alternatively just call
;;    `fix-muscle-memory-load-problem-words' with nil and an alist of
;;    problem words in the format of (("tyop" . "typo")).
;; 
;;    Because this uses abbrev mode, you will need to make sure to enable
;;    it.
;; 
;; ** Helping with Extended commands
;; 
;;   If you find yourself using `execute-extended-command' in place of a
;;   keybinding, using this will help train you.  The first three
;;   instances of the same extended command will go through normally.
;;   The next time however you will be told the key-combo to use and then
;;   prompted to enter it three times.
;; 
;;   Customize `fix-muscle-memory-enable-extended-command' and you're off
;;   to the races.
;; 
;; ** Getting out
;;   
;;   Entering in the wrong answer more than 6 times or so will exit out
;;   of the loop.  Alternatively C-g (quit) will get you out as well.
;; 
;; ** Super Kawaii
;; 
;;   Customize the variable `fix-muscle-memory-use-emoji' to true to use
;;   cute emoji icons along with text. 
;; 
;; ** Easy Setup with use-package
;; #+begin_src emacs-lisp
;; (use-package 'fix-muscle-memory
;;   :init
;;   (setq fix-muscle-memory-use-emoji t)
;;   :config
;;   (fix-muscle-memory-load-problem-words 'foo
;;                                         '(("teh" . "the")
;;                                           ("comptuer" . "computer")
;;                                           ("destory" . "destroy")
;;                                           ("occured" . "occurred")))
;;   (add-hook 'text-mode-hook 'abbrev-mode)
;;   (add-hook 'prog-mode-hook 'abbrev-mode)
;; 
;;   (turn-on-fix-muscle-memory-on-extended-command))
;; #+end_src
;; 
;; * Changelog
;; 
;;    - v 0.1 :: First Version.
;;    - v 0.2 ::
;;      - Minor documentation fix.
;;    - v 0.3 ::
;;      - Fix bug when using Ispell.
;;    - v 0.90 :: Almost ready for 1.0!
;;      - Gave it it's own repository (finally).
;;      - Added abbrev hook for fixing as-you-type-mistakes.
;;      - properly manage the response back from `ispell-command-loop'.
;;      - Added cute emoji.  I couldn't help myself.
;;      - Added fix-muscle-memory-extended-command
;;    - v 0.91 ::
;;      - Fix Spelling mistakes in code.
;;    - v 0.92 ::
;;      - Package format fixes from syohex
;;    - v 0.93 ::
;;      - Forgot to include emoji jiggerypokery. :(
;;    - v 0.94 ::
;;      - Emacs 27 compatability fix.

;;; Code:



(defcustom fix-muscle-memory-use-emoji nil
  "Use emoji characters in prompts."
  :group 'fix-muscle-memory
  :type 'boolean)

(defun fix-muscle-memory-emoji (chars)
  "Helper function for spitting out emoji"
  (if fix-muscle-memory-use-emoji
      chars
    ""))

(defun fix-muscle-memory-load-problem-words (sym values)
  "Remove existing problem words and re-set them.

This also checks `abbrev-expand-function' and sets that if
required.

`SYM' is just there for customize.
`VALUES' is a list of word pairs."
  ; remove the old abbrevs
  (when (boundp 'fix-muscle-memory-problem-words)
    (dolist (word-pair fix-muscle-memory-problem-words)
      (define-abbrev global-abbrev-table (car word-pair) nil)))
  ; set the new
  (dolist (word-pair values)
          (define-abbrev global-abbrev-table
            (car word-pair)
            (cdr word-pair)
            nil
            :system t))
  (unless (eq abbrev-expand-function #'fix-muscle-memory-expand-abbrev)
      (setq emagician-actual-abbrev-function abbrev-expand-function)
      (setq abbrev-expand-function #'fix-muscle-memory-expand-abbrev))
  (setq fix-muscle-memory-problem-words values))

(defcustom fix-muscle-memory-problem-words
  '()
  "A list of problematic words that should be immediately fixed.
This is a lit of cons cells, with the car being the typo and the
cdr the fix.
If you edit this outside of customize, you will need to use
`fix-muscle-memory-load-problem-words' function instead."
  :group 'fix-muscle-memory
  :type '(repeat (cons string string))
  :set 'fix-muscle-memory-load-problem-words)

(defun turn-on-fix-muscle-memory-on-extended-command ()
  "Help the user use bound keys instead of M-x.

When `execute-extended-command' is used to run a command that
can be executed through a bound key instead, the user is notified
of the key.  After 3 uses of the same command, the user is then
prompted to enter that key 3 times in an attempt to rewire their
brain.

If the user has `suggest-key-binding' bound, they will be
notified in the message area which keycombo to use on the first
three extended command uses.

If helm-command is loaded, then `helm-M-x' will also be
extended."
  (interactive)
  (fix-muscle-memory-enable-ec-advice 'execute-extended-command)
  (eval-after-load 'helm-command '(fix-muscle-memory-enable-ec-advice 'helm-M-x)))

(defun turn-off-fix-muscle-memory-on-extended-command ()
  "Turn off the extended command processing"
  (interactive)
  (fix-muscle-memory-disable-ec-advice 'execute-extended-command)
  (eval-after-load 'helm-command '(fix-muscle-memory-disable-ec-advice 'helm-M-x)))

(defun fix-muscle-memory-disable-ec-advice (target-fn-sym)
  "Remove advice from TARGET-FN-SYM."
  (advice-remove target-fn-sym
                 #'fix-muscle-memory-extended-command-advice))

(defun fix-muscle-memory-enable-ec-advice (target-fn-sym)
  "Add advice to TARGET-FN-SYM"
  (unless (advice-member-p
           #'fix-muscle-memory-extended-command-advice
           target-fn-sym)
    (advice-add target-fn-sym
                :after
                #'fix-muscle-memory-extended-command-advice
                '(name fix-muscle-memory-command-advice))))

(when nil
  (advice-mapc (lambda (a b) (message "%S %S" a b))
               #'execute-extended-command)

  (advice-mapc (lambda (a b) (message "%S %S" a b)) #'fix-muscle-memory-extended-command-advice)

  (progn (debug)
         (advice-member-p #'fix-muscle-memory-extended-command-advice
                          #'execute-extended-command))

  (progn (turn-on-fix-muscle-memory-on-extended-command)))

(defun fix-muscle-memory-on-extended-command-custom (&optional _customize turn-on)
  "Function for _CUSTOMIZE to TURN-ON."
  (if turn-on 
     (turn-on-fix-muscle-memory-on-extended-command)
     (turn-off-fix-muscle-memory-on-extended-command)))

(defcustom fix-muscle-memory-enable-extended-command nil
  "Enable/disable fixing muscle memory on commands.

Whether or not to prompt the user to re-type keybindings when
  execute-extended-command is used."
  :set 'fix-muscle-memory-on-extended-command-custom
  :group 'fix-muscle-memory)


(defvar emagician-actual-abbrev-function nil
  "Actual abbreviation function.

`fix-muscle-memory' should just handle this for you
transparently.")

(defvar emagician/commands-with-bindings
  (make-hash-table :test 'equal)
  "Store which keys have been run and how many times.")

(defun fix-muscle-memory-correct-user-with-the-ruler (the-problem the-solution)
  "The user correction function.

This function helps fix a bug in the user when they type `THE-PROBLEM'.
We make the user type `THE-SOLUTION' 3 times to fix it."
  (beep)
  (let* ((required-corrections 3)
         (attempts 0))
    (while (< attempts required-corrections)
      (when (< attempts -6) (error "Too many failed attempts! %s"
                                   (fix-muscle-memory-emoji "😿")))
      (setq attempts
            (+ attempts (if (string= (read-string
                                      (format "Bad User *whack*. %s Please fix '%s' with '%s' (%d/%d): "
                                              (fix-muscle-memory-emoji "🙇📏")
                                              the-problem
                                              the-solution
                                              attempts
                                              required-corrections))
                                  the-solution)
                         1
                       (progn (beep) -1)))))))

(defun fix-muscle-memory-in-ispell (orig-fn miss guess word start end)
  "Advice function to run after an Ispell word has been selected.
`ORIG-FN' `MISS' `GUESS' `WORD' `START' `END' are all advice fns."
  (let ((return-value (funcall orig-fn miss guess word start end)))
    (when (stringp return-value)
      (fix-muscle-memory-correct-user-with-the-ruler word return-value))
    return-value))

(advice-add 'ispell-command-loop :around #'fix-muscle-memory-in-ispell)

(defun fix-muscle-memory-expand-abbrev ()
  "Expansion function for fix-muscle-memory.
This function doesn't change the expansion at all, it only forces
the user to fix it if the abbrev matches one of the
`fix-muscle-memory-problem-words'."
  (let* ((abbrev (funcall emagician-actual-abbrev-function))
         (word (assoc (symbol-name abbrev) fix-muscle-memory-problem-words)))
    (when (and abbrev word)
      (fix-muscle-memory-correct-user-with-the-ruler (car word) (cdr word)))
    abbrev))

(defun emagician/make-muscle-memory (the-problem the-solution)
  "The user binding habit creation function.

This function adds a feature to the user user so that instead of
using the extended command `THE-PROBLEM'.they learn to use the
keybinding (as a vector) `THE-SOLUTION' by typing it 3 times."
  (beep)
  (let* ((required-corrections 3)
         (attempts 0)
         (last-k-error " "))
    (while (< attempts required-corrections)
      (when (< attempts -6) (error "Too many failed attempts! %s"
                                   (fix-muscle-memory-emoji "😿")))
      (pcase (read-key-sequence
              (format "%sLearning is fun!  Execute '%s' with '%s' %s(%d/%d): "
                      (fix-muscle-memory-emoji "🐰💭 ")
                      the-problem
                      the-solution
                      last-k-error
                      attempts
                      required-corrections))
        ((pred (equal (kbd the-solution)))
         (setq last-k-error (fix-muscle-memory-emoji "✅"))
         (setq attempts (1+ attempts)))
        ((pred (equal (kbd "C-g")))
         (setq attempts required-corrections)
         (message "Okay, Giving up."))
        (k-error
         (beep)
         (setq last-k-error (format "%s %s "
                                    (if fix-muscle-memory-use-emoji
                                        "❌"
                                      "WRONG")
                                    k-error))
         (setq attempts (1- attempts)))))))

(defun fix-muscle-memory-extended-command-advice (arg &optional command-name)
  "Advice around to suggest a command and bug user.

Same args as `execute-extended-command'.  ARG for a prefix arg
and COMMAND-NAME is the command to execute."
  (let* ((fn (and (stringp command-name)
                  (intern-soft command-name)))
         (binding (and suggest-key-bindings
                       (not executing-kbd-macro)
                       (where-is-internal fn overriding-local-map t)))
         (waited (and binding
                      (sit-for
                       (cond
                        ((zerop (length (current-message))) 0)
                        ((numberp suggest-key-bindings) suggest-key-bindings)
                        (t 2))))))
    (when (and fn binding (key-description binding) waited)
      (if (>= 3 (puthash command-name
                        (1+ (gethash command-name
                                     emagician/commands-with-bindings
                                     0))
                        emagician/commands-with-bindings))
          (with-temp-message
              (format "You can run the command `%s' with %s"
                      fn
                      (key-description binding))
            (sit-for (if (numberp suggest-key-bindings)
                         suggest-key-bindings
                       2)))
        (emagician/make-muscle-memory fn
                                      (key-description binding))))))


(provide 'fix-muscle-memory)

;;; fix-muscle-memory.el ends here
