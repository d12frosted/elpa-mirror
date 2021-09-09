;;; fancy-dabbrev.el --- Like dabbrev-expand with preview and popup menu -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2018-2021 Joel Rosdahl
;;
;; Author: Joel Rosdahl <joel@rosdahl.net>
;; Version: 1.1
;; Package-Version: 20210909.752
;; Package-Commit: 9435ad63c1c4756f574ae98d2d63ecf1189ec832
;; License: BSD-3-clause
;; Package-Requires: ((emacs "25.1") (popup "0.5.3"))
;; URL: https://github.com/jrosdahl/fancy-dabbrev
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are met:
;;
;; * Redistributions of source code must retain the above copyright notice,
;;   this list of conditions and the following disclaimer.
;;
;; * Redistributions in binary form must reproduce the above copyright notice,
;;   this list of conditions and the following disclaimer in the documentation
;;   and/or other materials provided with the distribution.
;;
;; * Neither the name of the copyright holder nor the names of its contributors
;;   may be used to endorse or promote products derived from this software
;;   without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
;; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
;; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;; POSSIBILITY OF SUCH DAMAGE.
;;
;; ============================================================================
;;
;;; Commentary:
;;
;; fancy-dabbrev essentially wraps the Emacs built-in dabbrev functionality,
;; with two improvements:
;;
;; 1. Preview: If fancy-dabbrev-mode is enabled, a preview of the first
;;    expansion candidate will be shown when any text has been entered. If
;;    fancy-dabbrev-expand then is called, the candidate will be expanded.
;;
;; 2. Popup menu: The first call to fancy-dabbrev-expand will expand the
;;    entered word prefix just like dabbrev-expand. But the second call will
;;    show a popup menu with other candidates (with the second candidate
;;    selected). The third call will advance to the third candidate, etc. It is
;;    also possible to go back to a previous candidate by calling
;;    fancy-dabbrev-backward. Selection from the menu can be canceled with C-g.
;;    Any cursor movement or typing will hide the menu again.
;;
;;
;; INSTALLATION
;; ============
;;
;; To load fancy-dabbrev, store fancy-dabbrev.el in your Emacs load path and
;; put something like this in your Emacs configuration file:
;;
;;   ;; Load fancy-dabbrev.el:
;;   (require 'fancy-dabbrev)
;;
;;   ;; Enable fancy-dabbrev previews everywhere:
;;   (global-fancy-dabbrev-mode)
;;
;;   ;; Bind fancy-dabbrev-expand and fancy-dabbrev-backward to your keys of
;;   ;; choice:
;;   (global-set-key (kbd "TAB") 'fancy-dabbrev-expand)
;;   (global-set-key (kbd "<backtab>") 'fancy-dabbrev-backward)
;;
;;   ;; If you want TAB to indent the line like it usually does when the cursor
;;   ;; is not next to an expandable word, use 'fancy-dabbrev-expand-or-indent
;;   ;; instead:
;;   (global-set-key (kbd "TAB") 'fancy-dabbrev-expand-or-indent)
;;
;;
;; CONFIGURATION
;; ============
;;
;; fancy-dabbrev-expand uses dabbrev-expand under the hood, so most dabbrev-*
;; configuration options affect fancy-dabbrev-expand as well. For instance, if
;; you want to use fancy-dabbrev-expand when programming, you probably want to
;; use these dabbrev settings:
;;
;;   ;; Let dabbrev searches ignore case and expansions preserve case:
;;   (setq dabbrev-case-distinction nil)
;;   (setq dabbrev-case-fold-search t)
;;   (setq dabbrev-case-replace nil)
;;
;; Here are fancy-dabbrev's own configuration options:
;;
;; * fancy-dabbrev-expansion-context (default: 'after-symbol)
;;
;;   Where to try to perform expansion. If 'after-symbol, only try to expand
;;   after a symbol (as determined by thing-at-point). If
;;   'after-symbol-or-space, also make it possible to expand after a space  (the
;;   first expansion candidate will then be based on the previous symbol). If
;;   'after-non-space, enable expansion after any non-space character. If
;;   'almost-everywhere, enable exansion everywhere except at empty lines.
;;
;; * fancy-dabbrev-expansion-on-preview-only (default: nil)
;;
;;   Only expand when a preview is shown or expansion ran for the last command.
;;   This has the advantage that fancy-dabbrev-expand-or-indent always falls
;;   back to calling fancy-dabbrev-indent-command when there is nothing to
;;   expand.
;;
;; * fancy-dabbrev-indent-command (default: 'indent-for-tab-command)
;;
;;   The indentation command used for fancy-dabbrev-expand-or-indent.
;;
;; * fancy-dabbrev-menu-height (default: 10)
;;
;;   How many expansion candidates to show in the menu.
;;
;; * fancy-dabbrev-no-expansion-for (default: '(multiple-cursors-mode))
;;
;;   A list of variables which, if bound and non-nil, will inactivate
;;   fancy-dabbrev expansion. The variables typically represent major or minor
;;   modes. When inactive, fancy-dabbrev-expand will fall back to running
;;   dabbrev-expand.
;;
;; * fancy-dabbrev-no-preview-for (default: '(iedit-mode isearch-mode
;;   multiple-cursors-mode))
;;
;;   A list of variables which, if bound and non-nil, will inactivate
;;   fancy-dabbrev preview. The variables typically represent major or minor
;;   modes.
;;
;; * fancy-dabbrev-preview-context (default: 'at-eol)
;;
;;   When to show the preview. If 'at-eol, only show the preview if no other
;;   text (except whitespace) is to the right of the cursor. If
;;   'before-non-word, show the preview whenever the cursor is not immediately
;;   before (or inside) a word. If 'everywhere, always show the preview after
;;   typing.
;;
;; * fancy-dabbrev-preview-delay (default: 0.0)
;;
;;   How long (in seconds) to wait until displaying the preview after a
;;   keystroke. Set this to e.g. 0.2 if you think that it's annoying to get a
;;   preview immediately after writing some text.
;;
;; * fancy-dabbrev-self-insert-commands (default (self-insert-command
;;   org-self-insert-command))
;;
;;   A list of commands after which to show a preview.
;;
;; * fancy-dabbrev-sort-menu (default nil)
;;
;;   If nil, the popup menu will show matching candidates in the order that
;;   repeated calls to dabbrev-expand would return (i.e., first candidates
;;   before the cursor, then after the cursor and then from other buffers). If
;;   t, the candidates (except the first one) will be sorted.
;;
;;
;; WHY?
;; ====
;;
;; There are many other Emacs packages for doing more or less advanced
;; auto-completion in different ways. After trying out some of the more popular
;; ones and not clicking with them, I kept coming back to dabbrev due to its
;; simplicity. Since I missed the preview feature and a way of selecting
;; expansions candidates from a menu if the first candidate isn't the right
;; one, I wrote fancy-dabbrev.
;;
;; Have fun!
;;
;; /Joel Rosdahl <joel@rosdahl.net>

;;; Code:

(require 'cl-lib)
(require 'dabbrev)
(require 'popup)

(defgroup fancy-dabbrev nil
  "Fancy dabbrev."
  :group 'fancy-dabbrev)

(defcustom fancy-dabbrev-menu-height 10
  "How many expansion candidates to show in the menu."
  :type 'integer
  :group 'fancy-dabbrev)

(defcustom fancy-dabbrev-sort-menu
  nil
  "Determine the order of matching candidates in the popup menu.

If nil, the popup menu will show matching candidates in the order
that repeated calls to ‘dabbrev-expand’ would return (i.e., first
candidates before the cursor, then after the cursor and then from
other buffers). If t, the candidates (except the first one) will
be sorted."
  :type 'boolean
  :group 'fancy-dabbrev)

(defcustom fancy-dabbrev-preview-delay 0.0
  "How long to wait until displaying the preview after a keystroke.

The value is in seconds."
  :type 'float
  :group 'fancy-dabbrev)

(defcustom fancy-dabbrev-expansion-context
   'after-symbol
  "Where to try to perform expansion.

If 'after-symbol, only try to expand after a symbol (as determined
by `thing-at-point'). If 'after-symbol-or-space, also make it
possible to expand after a space (the first expansion candidate
will then be based on the previous symbol). If 'after-non-space,
enable expansion after any non-space character. If
'almost-everywhere, enable exansion everywhere except at empty lines."
  :type '(choice
          (const :tag "Only after a symbol" after-symbol)
          (const :tag "Only after a symbol or space" after-symbol-or-space)
          (const :tag "After any non-space character" after-non-space)
          (const :tag "Almost everywhere" almost-everywhere))
  :group 'fancy-dabbrev)

(defcustom fancy-dabbrev-indent-command
   'indent-for-tab-command
  "The indent command to use for `fancy-dabbrev-expand-or-indent'."
  :type 'symbol
  :group 'fancy-dabbrev)

(defcustom fancy-dabbrev-preview-context
  'at-eol
  "When to show the preview.

If 'at-eol, only show the preview if no other text (except
whitespace) is to the right of the cursor. If 'before-non-word,
show the preview whenever the cursor is not immediately
before (or inside) a word. If 'everywhere, always show the
preview after typing."
  :type '(choice (const :tag "Only at end of lines" at-eol)
                 (const :tag "When cursor is not immediately before a word"
                        before-non-word)
                 (const :tag "Everywhere" everywhere))
  :group 'fancy-dabbrev)

(defcustom fancy-dabbrev-expansion-on-preview-only nil
  "Only expand when a preview is shown or expansion ran for the last command.

This has the advantage that `fancy-dabbrev-expand-or-indent'
always falls back to calling `fancy-dabbrev-indent-command'
when there is nothing to expand."
  :type 'boolean
  :group 'fancy-dabbrev)

(defcustom fancy-dabbrev-no-expansion-for
  '(multiple-cursors-mode)
  "Determine when to disable expansion.

This is a list of variables which, if bound and non-nil, will
inactivate fancy-dabbrev expansion. The variables typically
represent major or minor modes. When inactive,
`fancy-dabbrev-expand' will fall back to running
`dabbrev-expand'."
  :type '(repeat variable)
  :group 'fancy-dabbrev)

(defcustom fancy-dabbrev-no-preview-for
  '(iedit-mode isearch-mode multiple-cursors-mode)
  "Determine when to disable preview.

This is a list of variables which, if bound and non-nil, will
inactivate fancy-dabbrev preview. The variables typically
represent major or minor modes."
  :type '(repeat variable)
  :group 'fancy-dabbrev)

(defcustom fancy-dabbrev-self-insert-commands
  '(self-insert-command org-self-insert-command)
  "A list of commands after which to show a preview."
  :type '(repeat function)
  :group 'fancy-dabbrev)

(defconst fancy-dabbrev--commands
  '(fancy-dabbrev-expand
    fancy-dabbrev-expand-or-indent
    fancy-dabbrev-backward))

(defvar fancy-dabbrev-mode nil)

(defvar fancy-dabbrev--popup nil
  "The state of the popup menu.")

(defvar fancy-dabbrev--expansions nil
  "A list of candidate expansions retrieved via `dabbrev-expand'.")

(defvar fancy-dabbrev--selected-expansion nil
  "Index of selected expansion in `fancy-dabbrev--expansions'.")

(defvar fancy-dabbrev--entered-abbrev nil
  "Current prefix that we want to expand.")

(defvar fancy-dabbrev--preview-overlay nil
  "The state of the preview overlay.")

(defvar fancy-dabbrev--preview-overlay-was-visible nil
  "The preview overlay visibility before running a command.")

(defvar fancy-dabbrev--preview-timer nil
  "The state of the preview timer.")

(defface fancy-dabbrev-menu-face
  '((t (:inherit popup-face)))
  "Face for the fancy-dabbrev menu.")

(defface fancy-dabbrev-selection-face
  '((t (:inherit popup-menu-selection-face)))
  "Face for the selected item in the fancy-dabbrev menu.")

(defface fancy-dabbrev-preview-face
  '((t (:inherit shadow :underline t)))
  "Face for the preview.")

;;;###autoload
(defun fancy-dabbrev-expand ()
  "Expand previous word \"dynamically\", potentially with a popup menu.

This function executes `dabbrev-expand' when called the first
time. Seqsequent calls will execute `dabbrev-expand' while
showing a popup menu with the expansion candidates."
  (interactive)
  (unless (fancy-dabbrev--expand)
    (error "No expansion possible here")))

;;;###autoload
(defun fancy-dabbrev-expand-or-indent ()
  "Expand previous word \"dynamically\" or indent.

This function executes `fancy-dabbrev-expand' if the cursor is
after an expandable prefix, otherwise `indent-for-tab-command'."
  (interactive)
  (unless (fancy-dabbrev--expand)
    (call-interactively fancy-dabbrev-indent-command)))

;;;###autoload
(defun fancy-dabbrev-backward ()
  "Select the previous expansion candidate.

If run after `fancy-dabbrev-expand', this function selects the
previous expansion candidate in the menu."
  (interactive)
  (if (and fancy-dabbrev--expansions
           (fancy-dabbrev--is-fancy-dabbrev-command last-command))
      (fancy-dabbrev--expand-again nil)
    (setq fancy-dabbrev--expansions nil)
    (error "No previous expansion candidate")))

(defmacro fancy-dabbrev--with-advice (fn-orig where fn-advice &rest body)
  "Execute BODY with advice added WHERE using FN-ADVICE temporarily added to FN-ORIG."
  `(let ((fn-advice-var ,fn-advice))
     (unwind-protect
         (progn
           (advice-add ,fn-orig ,where fn-advice-var)
           ,@body)
       (advice-remove ,fn-orig fn-advice-var))))

(defmacro fancy-dabbrev--with-suppressed-message (&rest body)
  "[internal] Run BODY with the message function disabled entirely."
  `(fancy-dabbrev--with-advice
    'message :override '(lambda (&rest args) nil) ,@body))

(defmacro fancy-dabbrev--with-suppressed-message-advice (function-sym &rest body)
  "[internal] Advise FUNCTION-SYM to run BODY with `message' disabled."
  `(fancy-dabbrev--with-advice
    ,function-sym
    :around '(lambda (fn-orig &rest args)
               (fancy-dabbrev--with-suppressed-message (apply fn-orig args)))
    ,@body))

;; Messages from dabbrev--find-expansion ("Scanning for dabbrevs...done")
;; are suppressed since they are annoying when searching for a candidate
;; for the preview.
(defmacro fancy-dabbrev--without-progress-reporter (&rest body)
  "[internal] Run BODY with the progress reporter with `message' disabled."
  `(fancy-dabbrev--with-suppressed-message-advice
    'make-progress-reporter
    (fancy-dabbrev--with-suppressed-message-advice
     'progress-reporter-update
     (fancy-dabbrev--with-suppressed-message-advice
      'progress-reporter-done
      ,@body))))

(defun fancy-dabbrev--looking-back-at-expandable ()
  "[internal] Return non-nil if point is after something to expand."
  (cond ((eq fancy-dabbrev-expansion-context 'after-symbol)
         (thing-at-point 'symbol))
        ((eq fancy-dabbrev-expansion-context 'after-symbol-or-space)
         (and (not (eq (point) (line-beginning-position)))
              (save-excursion
                (re-search-backward
                 "[^[:space:]]" (line-beginning-position) 'noerror)
                (thing-at-point 'symbol))))
        ((eq fancy-dabbrev-expansion-context 'after-non-space)
         (looking-back "[^[:space:]]" (line-beginning-position)))
        ((eq fancy-dabbrev-expansion-context 'almost-everywhere)
         (looking-back "[^[:space:]] *" (line-beginning-position)))))

(defun fancy-dabbrev--in-previewable-context ()
  "[internal] Return non-nil if point is in a previewable context."
  (cond ((eq fancy-dabbrev-preview-context 'at-eol)
         (looking-at "[[:space:]]*$"))
        ((eq fancy-dabbrev-preview-context 'before-non-word)
         (looking-at "$\\|[^[:word:]_]"))
        ((eq fancy-dabbrev-preview-context 'everywhere)
         t)
        (t nil)))

(defun fancy-dabbrev--is-fancy-dabbrev-command (command)
  "[internal] Return non-nil if COMMAND is a fancy-dabbrev command."
  (memq command fancy-dabbrev--commands))

(defun fancy-dabbrev--is-self-insert-command ()
  "[internal] Return non-nil if COMMAND is a \"self-insert command\"."
  (memq this-command fancy-dabbrev-self-insert-commands))

(defun fancy-dabbrev--any-bound-and-true (variables)
  "[internal] Return non-nil if any of VARIABLES is bound and non-nil."
  (cl-some (lambda (x) (and (boundp x) (symbol-value x))) variables))

(defun fancy-dabbrev--expand ()
  "[internal] Perform expansion.

The function returns non-nil if an expansion was made, otherwise
nil."
  (let ((last-command-did-expand
         (and (fancy-dabbrev--is-fancy-dabbrev-command last-command)
              fancy-dabbrev--expansions)))
    (if (and (not last-command-did-expand)
             (or (not (fancy-dabbrev--looking-back-at-expandable))
                 (and fancy-dabbrev-expansion-on-preview-only
                      (not fancy-dabbrev--preview-overlay-was-visible))))
        (setq fancy-dabbrev--expansions nil)
      (if (fancy-dabbrev--any-bound-and-true fancy-dabbrev-no-expansion-for)
          (fancy-dabbrev--without-progress-reporter
           (dabbrev-expand nil))
        (add-hook 'post-command-hook #'fancy-dabbrev--post-command-hook)
        (if last-command-did-expand
            (fancy-dabbrev--expand-again t)
          (fancy-dabbrev--expand-first-time)))
      t)))

(defun fancy-dabbrev--pre-command-hook ()
  "[internal] Function run from `pre-command-hook'."
  (setq fancy-dabbrev--preview-overlay-was-visible nil)
  (when fancy-dabbrev--preview-overlay
    (setq fancy-dabbrev--preview-overlay-was-visible t)
    (delete-overlay fancy-dabbrev--preview-overlay)
    (setq fancy-dabbrev--preview-overlay nil)))

(defun fancy-dabbrev--post-command-hook ()
  "[internal] Function run from `post-command-hook'."
  (when (timerp fancy-dabbrev--preview-timer)
    (cancel-timer fancy-dabbrev--preview-timer)
    (setq fancy-dabbrev--preview-timer nil))
  (unless (fancy-dabbrev--is-fancy-dabbrev-command this-command)
    (fancy-dabbrev--on-exit))
  (when (and fancy-dabbrev-mode
             (not (fancy-dabbrev--any-bound-and-true
                   fancy-dabbrev-no-preview-for))
             (not (minibufferp (current-buffer)))
             (fancy-dabbrev--is-self-insert-command))
    (setq fancy-dabbrev--preview-timer
          (run-with-idle-timer
           fancy-dabbrev-preview-delay nil #'fancy-dabbrev--preview))))

(defun fancy-dabbrev--abbrev-start-location ()
  "[internal] Determine the start location of the abbreviation."
  (- dabbrev--last-abbrev-location (length fancy-dabbrev--entered-abbrev)))

(defun fancy-dabbrev--insert-expansion (expansion)
  "[internal] Insert EXPANSION at point."
  (delete-region (fancy-dabbrev--abbrev-start-location) (point))
  (insert expansion))

(defun fancy-dabbrev--get-expansion ()
  "[internal] Get expansion from dabbrev-expand."
  ;; Messages from dabbrev--find-expansion ("Scanning for dabbrevs...done")
  ;; are suppressed since they are annoying when searching for a candidate
  ;; for the preview.
  (fancy-dabbrev--without-progress-reporter
   (let* ((abbrev fancy-dabbrev--entered-abbrev)
          (expansion
           (dabbrev--find-expansion abbrev 0 dabbrev-case-fold-search)))
     (and expansion
          (with-temp-buffer
            (insert abbrev)
            (dabbrev--substitute-expansion abbrev abbrev expansion nil)
            (buffer-string))))))

(defun fancy-dabbrev--get-first-expansion ()
  "[internal] Return the first expansion candidate."
  (dabbrev--reset-global-variables)
  (setq fancy-dabbrev--entered-abbrev (dabbrev--abbrev-at-point))
  (fancy-dabbrev--get-expansion))

(defun fancy-dabbrev--preview ()
  "[internal] Show the preview."
  (when (and (fancy-dabbrev--looking-back-at-expandable)
             (fancy-dabbrev--in-previewable-context))
    (let ((expansion (fancy-dabbrev--get-first-expansion)))
      (when expansion
        (let ((expansion
               (substring expansion (length fancy-dabbrev--entered-abbrev))))
          (setq fancy-dabbrev--preview-overlay (make-overlay (point) (point)))
          (add-text-properties 0 1 '(cursor 1) expansion)
          (add-text-properties
           0 (length expansion) '(face fancy-dabbrev-preview-face) expansion)
          (overlay-put
           fancy-dabbrev--preview-overlay 'after-string expansion))))))

(defun fancy-dabbrev--expand-first-time ()
  "[internal] Insert expansion the first time.

This function fetches the first expansion and inserts it at point."
  (setq fancy-dabbrev--expansions nil)
  (let* ((expansion (fancy-dabbrev--get-first-expansion)))
    (if (null expansion)
        (error "No expansion found for \"%s\"" fancy-dabbrev--entered-abbrev)
      (setq fancy-dabbrev--expansions (list expansion))
      (fancy-dabbrev--insert-expansion expansion))))

(defun fancy-dabbrev--get-popup-point ()
  "[internal] Determine where to place the menu.

The menu is normally placed directly under point, but if point is
near the right window edge or on a wrapped line, the menu is
placed first at the next line to avoid a misrendered menu."
  (let ((start (fancy-dabbrev--abbrev-start-location))
        (line-width (- (line-end-position) (line-beginning-position))))
    (if (> line-width (window-width))
        (save-excursion
          (goto-char start)
          (forward-line)
          (point))
      start)))

(defun fancy-dabbrev--expand-again (next)
  "[internal] Expand again, i.e. not the first time.

This function first creates and displays the menu if not already
created and then steps forward if NEXT is non-nil, otherwise
backward. The chosen expansion candidate is also inserted at
point."
  (fancy-dabbrev--init-expansions)
  (unless fancy-dabbrev--popup
    (setq fancy-dabbrev--popup
          (popup-create
           (fancy-dabbrev--get-popup-point)
           (apply #'max (mapcar #'length fancy-dabbrev--expansions))
           fancy-dabbrev-menu-height
           :around t
           :face 'fancy-dabbrev-menu-face
           :selection-face 'fancy-dabbrev-selection-face))
    (popup-set-list fancy-dabbrev--popup fancy-dabbrev--expansions)
    (popup-draw fancy-dabbrev--popup))
  (let ((diff))
    (if next
        (progn
          (popup-next fancy-dabbrev--popup)
          (setq diff 1))
      (popup-previous fancy-dabbrev--popup)
      (setq diff -1))
    (setq fancy-dabbrev--selected-expansion
          (mod (+ fancy-dabbrev--selected-expansion diff)
               (length fancy-dabbrev--expansions))))
  (fancy-dabbrev--insert-expansion
   (nth fancy-dabbrev--selected-expansion fancy-dabbrev--expansions)))

(defun fancy-dabbrev--init-expansions ()
  "[internal] Initialize the list of candidate expansions."
  (when (= (length fancy-dabbrev--expansions) 1)
    ;; If the length of fancy-dabbrev--expansions is one we have only retrieved
    ;; the first candidate, either via preview or via the first expansion, so
    ;; ask dabbrev for the full list of candidates.
    (let ((i 1)
          expansion
          new-expansions)
      (while (and (< i fancy-dabbrev-menu-height)
                  (setq expansion (fancy-dabbrev--get-expansion)))
        (setq new-expansions (cons expansion new-expansions))
        (setq i (1+ i)))
      (setq fancy-dabbrev--expansions
            (cons (car fancy-dabbrev--expansions)
                  (if fancy-dabbrev-sort-menu
                      (sort new-expansions
                            (if (fboundp #'string-collate-lessp)
                                #'string-collate-lessp
                              #'string<))
                    (reverse new-expansions))))
      (setq fancy-dabbrev--selected-expansion 0))))

(defun fancy-dabbrev--on-exit ()
  "[internal] Function run when executing another command.

That is, if `this-command' is not one of
`fancy-dabbrev--commands'."
  (when fancy-dabbrev--popup
    (popup-delete fancy-dabbrev--popup)
    (setq fancy-dabbrev--popup nil)
    (setq fancy-dabbrev--expansions nil)
    (setq fancy-dabbrev--selected-expansion nil)))

(defadvice keyboard-quit (before fancy-dabbrev--expand activate)
  "[internal] Revert expansion if the user quits with `keyboard-quit'."
  (when (fancy-dabbrev--is-fancy-dabbrev-command last-command)
    (fancy-dabbrev--insert-expansion fancy-dabbrev--entered-abbrev)))

;;;###autoload
(define-minor-mode fancy-dabbrev-mode
  "Toggle `fancy-dabbrev-mode'.

With a prefix argument ARG, enable `fancy-dabbrev-mode' if ARG is
positive, and disable it otherwise. If called from Lisp, enable
the mode if ARG is omitted or nil.

When `fancy-dabbrev-mode' is enabled, fancy-dabbrev's preview
functionality is activated."
  :lighter " FD"
  :init-value nil
  (if fancy-dabbrev-mode
      (progn
        (add-hook 'pre-command-hook #'fancy-dabbrev--pre-command-hook nil t)
        (add-hook 'post-command-hook #'fancy-dabbrev--post-command-hook nil t))
    (remove-hook 'pre-command-hook #'fancy-dabbrev--pre-command-hook t)
    (remove-hook 'post-command-hook #'fancy-dabbrev--post-command-hook t)

    ;; Clean up runtime state.
    (when fancy-dabbrev--preview-overlay
      (delete-overlay fancy-dabbrev--preview-overlay)
      (setq fancy-dabbrev--preview-overlay nil))
    (when (timerp fancy-dabbrev--preview-timer)
      (cancel-timer fancy-dabbrev--preview-timer)
      (setq fancy-dabbrev--preview-timer nil))))

;;;###autoload
(define-globalized-minor-mode global-fancy-dabbrev-mode
  fancy-dabbrev-mode
  (lambda () (fancy-dabbrev-mode 1)))

(provide 'fancy-dabbrev)

;;; fancy-dabbrev.el ends here
