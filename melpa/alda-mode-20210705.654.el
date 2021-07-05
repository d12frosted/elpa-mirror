;;; alda-mode.el --- An Alda major mode -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2017 Jay Kamat
;; Author: Jay Kamat <jaygkamat@gmail.com>
;; Version: 0.3.0
;; Package-Version: 20210705.654
;; Package-Commit: 4de011d572e958a377fb16daae05a1b411f0c8ad
;; Keywords: alda, highlight
;; URL: http://gitlab.com/jgkamat/alda-mode
;; Package-Requires: ((emacs "24.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; This package provides syntax highlighting and basic alda integration.
;; Activate font-lock-mode to use the syntax features, and run 'alda-play-region' to play song files
;;
;; Variables:
;; alda-binary-location: Set to the location of the binary executable.
;; If nil, alda-mode will search for your binary executable on your path
;; If set to a string, alda-mode will use that binary instead of 'alda' on your path.
;; Ex: (setq alda-binary-location "/usr/local/bin/alda")
;; Ex: (setq alda-binary-location nil) ;; Use default alda location
;; alda-ess-keymap: Whether to add the default ess keymap.
;; If nil, alda-mode will not add the default ess keymaps.
;; Ex: (setq alda-ess-keymap nil) ;; before (require 'alda)

;;; Constants:

(defconst +alda-output-buffer+ "*alda-output*")
(defconst +alda-output-name+ "alda-playback")
(defconst +alda-comment-str+ "#")
(defconst +alda-marker-name+ "alda-mode-internal-marker")

(require 'comint)
(require 'subr-x)

;;; Code:
;;;; -- Variables --
(defvar *alda-history*
  ""
  "Holds the history to be sent to alda.
If you are experiencing problems, try clearing your history with 'alda-history-clear'.")

;;;; -- Region playback functions --

(defgroup Alda nil
  "Alda customization options"
  :group 'applications)

(defgroup alda-mode-inf
  nil
  "Mode to interact with a Alda interpreter."
  :group 'Alda
  :tag "Inferior Alda")

(defcustom alda-binary-location nil
  "Alda binary location for `alda-mode'.
When set to nil, will attempt to use the binary found on your $PATH.
This must be a _full_ path to your alda binary."
  :type 'string
  :group 'Alda)

;;;; -- Alda inferior process definitions --

(defconst alda-inf-buffer-name "*inferior-alda*")

(define-derived-mode alda-mode-inf comint-mode "Inferior Alda"
  "Major mode for interacting with a Alda interpreter.

\\{inferior-alda-mode-map\\}"
  (define-key alda-mode-inf-map [(meta return)] 'comint-accumulate)

  ;; Comint configuration
  (make-local-variable 'comint-input-sender)
  (setq comint-input-sender 'alda-input-sender))

(defun alda-input-sender (proc string)
  (comint-send-string proc string)
  (comint-send-string proc "\n"))

(defun alda-interpreter-running-p-1 ()
  ;; True iff a Alda interpreter is currently running in a buffer.
  (comint-check-proc alda-inf-buffer-name))

(defun alda-check-or-start-interpreter ()
  (unless (alda-interpreter-running-p-1)
    (alda-run-alda)))

(defun alda-location ()
  "Return what 'alda' should be called as in the shell based on 'alda-binary-location' or the path."
  (if alda-binary-location
    alda-binary-location
    (locate-file "alda" exec-path)))

(defun alda-repl ()
  "Return the 'alda' repl start command"
  (format "%s repl" (alda-location)))

(defun alda-run-alda ()
  "Run a Alda interpreter in an Emacs buffer"
  (interactive)
  (let* ((cmd-line (alda-repl))
         (cmd/args (split-string cmd-line)))
    (unless (alda-interpreter-running-p-1)
      (set-buffer
        (apply 'make-comint "inferior-alda" (car cmd/args) nil (cdr cmd/args)))
      (alda-mode-inf)
      (pop-to-buffer alda-inf-buffer-name))))

(defun alda-switch-to-interpreter ()
  "Switch to buffer containing the interpreter"
  (interactive)
  (alda-check-or-start-interpreter)
  (switch-to-buffer-other-window alda-inf-buffer-name))

(defcustom alda-ess-keymap t
  "Whether to use ess keymap in 'alda-mode'.
When set to nil, will not set any ess keybindings"
  :type 'boolean
  :group 'Alda)

(defcustom alda-play-region-in-repl nil
  "Whether to send alda code region to repl in 'alda-mode'.
When set to nil, will not set to repl"
  :type 'boolean
  :group 'Alda)

(defun alda-run-cmd (&rest args)
  "Run a given alda command with specified args.
Argument ARGS a list of arguments to pass to alda"
  (interactive "sEnter alda command: ")
  (if (not (alda-location))
      (message "Alda was not found on your $PATH and alda-binary-location was nil.")
    (apply #'start-process +alda-output-name+ +alda-output-buffer+
           (alda-location) args)))

(defun alda-play-text (text)
  "Plays the specified TEXT in alda.
This does include any history you might have added.
ARGUMENT TEXT The text to play with alda."
  (let* ((use-marker (> (length (string-trim *alda-history*)) 0)))
    (alda-run-cmd "play"
                  "-F"
                  (if use-marker +alda-marker-name+ "")
                  "--code"
                  (concat
                   *alda-history*
                   (when use-marker
                     (concat "\n%" +alda-marker-name+ "\n"))
                   text))))

(defun alda-stop ()
  "Stop current alda playback."
  (alda-run-cmd "stop"))

(defun alda-play-file ()
  "Plays the current buffer's file in alda.
This does not include any history that you may have added"
  (interactive)
  (alda-run-cmd "play" "--file" (buffer-file-name)))

;; This is the replacement for the old 'alda append' command
;; Previously, command history was stored on the server, now it is stored on the client.
;; 'alda-mode' is your client, so we will take care of history for you!
;; These commands are in beta, so report an issue if you find any problems!
(defun alda-history-append-text (text)
  "Append the specified TEXT to the alda server instance.
ARGUMENT TEXT The text to append to the current alda server."
  (setq *alda-history* (concat *alda-history* "\n" text)))


(defun alda-history-clear ()
  "Clears the current alda history.
This can help resolve problems if you are having problems running your score"
  (interactive)
  (setq *alda-history* ""))

(defun alda-history-append-region (start end)
  "Append the current selection to the alda history.
Argument START The start of the selection to append from.
Argument END The end of the selection to append from."
  (interactive "r")
  (if (eq start end)
    (message "no mark was set")
    (alda-history-append-text (buffer-substring-no-properties start end))))

(defun alda-history-append-buffer ()
  "Append the current buffer to alda history."
  (interactive)
  (alda-history-append-text (buffer-string)))

(defun alda-history-append-block ()
  "Append the selected block of alda code to history."
  (interactive)
  (save-excursion
    (mark-paragraph)
    (alda-history-append-region (region-beginning) (region-end))))

(defun alda-history-append-line ()
  "Append the current line of alda code to history."
  (interactive)
  (alda-history-append-region (line-beginning-position) (line-end-position)))

(defun alda-inf-eval-region (start end)
  "Send current region to Alda interpreter."
  (interactive "r")
  (alda-check-or-start-interpreter)
  (comint-send-region alda-inf-buffer-name start end)
  (comint-send-string alda-inf-buffer-name "\n"))

(defun alda-play-region (start end)
  "Plays the current selection in alda.
Argument START The start of the selection to play from.
Argument END The end of the selection to play from."
  (interactive "r")
  (if (eq start end)
    (message "No mark was set!")
    (if alda-play-region-in-repl
      (alda-inf-eval-region start end)
      (alda-play-text (buffer-substring-no-properties start end)))))

;; If evil is found, make evil commands as well.
(eval-when-compile
  (unless (require 'evil nil 'noerror)
    ;; Evil must be sourced in order to define this macro
    (defmacro evil-define-operator (name &rest _)
      ;; Define a dummy instead if not present.
      `(defun ,name () (interactive) (message "Evil was not present while compiling alda-mode. Recompile with evil installed!")))))

;; Macro will be expanded based on the above dummy/evil load
(evil-define-operator alda-evil-play-region (beg end _type _register _yank-hanlder)
  "Plays the text from BEG to END."
  :move-point nil
  :repeat nil
  (interactive "<R><x><y>")
  (alda-play-region beg end))

(evil-define-operator alda-evil-history-append-region (beg end _type _register _yank-hanlder)
  "Appends the text from BEG to END to alda history."
  :move-point nil
  :repeat nil
  (interactive "<R><x><y>")
  (alda-history-append-region beg end))

;; Renamed stop -> down for consistency
(defun alda-down ()
  "Stops songs from playing, and cleans up idle alda runner processes.
Because alda runs in the background, the only way to do this is with alda restart as of now."
  (interactive)
  (shell-command (concat (alda-location) " down"))
  (delete-process +alda-output-buffer+))

;;;; -- Font Lock Regexes --
(let
  ;; Prevent regexes from taking up memory
  ((alda-instrument-regexp "\\([a-zA-Z]\\{2\\}[A-Za-z0-9_\-]*\\)\\(\s*\\(\"[A-Za-z0-9_\-]*\"\\)\\)?:")
   (alda-voice-regexp "\\([Vv][0-9]+\\):")
   (alda-timing-regexp "[a-gA-GrR][\s+-]*\\([~.0-9\s/]*\\(m?s\\)?\\)")
   (alda-repeating-regexp "\\(\\*[0-9]+\\)")
   (alda-cramming-regexp "\\({\\|}\\)")
   (alda-grouping-regexp "\\(\\[\\|\\]\\)")
   (alda-accidental-regexp "\\([a-gA-GrR]\s*[-+]+\\)")
   (alda-bar-regexp "\\(|\\)")
   (alda-set-octave-regexp "\\(o[0-9]+\\)")
   (alda-shift-octave-regexp "\\(>\\|<\\)")
   (alda-variable-regexp "\\(([a-zA-Z-]+!?\s+\\(\\([0-9]+\\)\\|\\(\\[\\(:[a-zA-Z]+\s?\\)+\\]\\)\\))\\)")
   (alda-markers-regexp "\\([@%][a-zA-Z]\\{2\\}[a-zA-Z0-9()+-]*\\)"))

  (defvar alda-highlights nil
    "Font lock highlights for 'alda-mode'")
  (setq alda-highlights
    `((,alda-bar-regexp . (1 font-lock-comment-face))
      (,alda-voice-regexp . (1 font-lock-function-name-face))
      (,alda-instrument-regexp . (1 font-lock-type-face))
      (,alda-variable-regexp . (1 font-lock-variable-name-face))
      (,alda-set-octave-regexp . (1 font-lock-constant-face))
      (,alda-shift-octave-regexp . (1 font-lock-constant-face))
      (,alda-markers-regexp . (1 font-lock-builtin-face))
      (,alda-timing-regexp . (1 font-lock-builtin-face))
      (,alda-repeating-regexp . (1 font-lock-builtin-face))
      (,alda-cramming-regexp . (1 font-lock-builtin-face))
      (,alda-grouping-regexp . (1 font-lock-builtin-face))
      (,alda-accidental-regexp . (1 font-lock-preprocessor-face)))))

;;;; -- Indention code --

;; A duplicate of asm-mode.el with changes
;; changes were made to the naming convention and to how the labels are calculated.
(defun alda-indent-line ()
  "Auto-indent the current line."
  (interactive)
  (let* ((savep (point))
          (indent (condition-case nil
                    (save-excursion
                      (forward-line 0)
                      (skip-chars-forward " \t")
                      (if (>= (point) savep) (setq savep nil))
                      (max (alda-calculate-indentation) 0))
                    (error 0))))
    (if savep
      (save-excursion (indent-line-to indent))
      (indent-line-to indent))))

(defun alda-indent-prev-level ()
  "Indent this line to the indention level of the previous non-whitespace line."
  (save-excursion
    (forward-line -1)
    (while (and
             (not (eq (point) (point-min))) ;; Point at start of bufffer
             ;; Point has a empty line
             (let ((match-str (buffer-substring-no-properties (line-beginning-position) (line-end-position))))
               (or (string-match "^\\s-*$" match-str)) (eq 0 (length match-str))))
      (forward-line -1))
    (current-indentation)))


(defun alda-calculate-indentation ()
  "Calculates indentation for `alda-mode' code."
  (or
    ;; Flush labels to the left margin.
    (and (looking-at "[A-Za-z0-9\" \\t-]+:\\s-*") 0)
    ;; All comments indention are the previous line's indention.
    (and (looking-at +alda-comment-str+) (alda-indent-prev-level))
    ;; The rest goes at the first tab stop.
    (or (indent-next-tab-stop 0))))

(defun alda-colon ()
  "Insert a colon; if it follows a label, delete the label's indentation."
  (interactive)
  (let ((labelp nil))
    (save-excursion
      (skip-chars-backward "A-Za-z\"\s\t")
      (if (setq labelp (bolp)) (delete-horizontal-space)))
    (call-interactively 'self-insert-command)
    (when labelp
      (delete-horizontal-space)
      (tab-to-tab-stop))))

(defun alda-play-block ()
  "Plays the selected block of alda code."
  (interactive)
  (save-excursion
    (mark-paragraph)
    (alda-play-region (region-beginning) (region-end))))

(defun alda-play-line ()
  "Plays the current line of alda code."
  (interactive)
  (alda-play-region (line-beginning-position) (line-end-position)))

(defun alda-play-buffer ()
  "Plays the current buffer of alda code."
  (interactive)
  (alda-play-text (buffer-string)))

;;;; -- Alda Keymaps --
;; TODO determine standard keymap for alda-mode

(defvar alda-mode-map nil "Keymap for `alda-mode'.")
(when (not alda-mode-map) ; if it is not already defined

  ;; assign command to keys
  (setq alda-mode-map (make-sparse-keymap))
  (define-key alda-mode-map (kbd ":") 'alda-colon)

  (define-key alda-mode-map [menu-bar alda-mode] (cons "Alda" (make-sparse-keymap)))
  (define-key alda-mode-map [menu-bar alda-mode alda-colon]
    '(menu-item "Insert Colon" alda-colon
       :help "Insert a colon; if it follows a label, delete the label's indentation"))

  ;; Add alda-ess-keymap if requested
  (when alda-ess-keymap
    (define-key alda-mode-map "\C-c\C-i" 'alda-run-alda)
    (define-key alda-mode-map "\C-c\C-r" 'alda-play-region)
    (define-key alda-mode-map "\C-c\C-c" 'alda-play-block)
    (define-key alda-mode-map "\C-c\C-n" 'alda-play-line)
    (define-key alda-mode-map "\C-c\C-b" 'alda-play-buffer)
    (define-key alda-mode-map "\C-c\C-z" 'alda-switch-to-interpreter)))

;;;; -- Alda Syntax Table --

(defvar alda-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">" table)
    table))


;;;; -- Alda Mode Definition --

;;;###autoload
(define-derived-mode alda-mode prog-mode
  "Alda"
  "A major mode for alda-lang, providing syntax highlighting and basic indention."

  ;; Set alda comments
  (setq comment-start +alda-comment-str+)
  (setq comment-padding " ")
  (setq comment-start-skip (concat +alda-comment-str+ "\\s-*"))
  (setq comment-multi-line (concat +alda-comment-str+ " "))
  ;; Comments should use the indention of the last line
  (setq comment-indent-function #'alda-indent-prev-level)

  ;; Set custom mappings
  (use-local-map alda-mode-map)
  (setq indent-line-function 'alda-indent-line)

  ;; Set alda highlighting
  (setq font-lock-defaults '(alda-highlights)))

;; Open alda files in alda-mode
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.alda\\'" . alda-mode))

(provide 'alda-mode)

;;; alda-mode.el ends here
