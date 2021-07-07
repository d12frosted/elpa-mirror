;;; cryptol-mode.el --- Cryptol major mode for Emacs -*- lexical-binding: t; -*-

;; Copyright (c) 2013-2016 Austin Seipp.

;; Author:    Austin Seipp <aseipp [@at] pobox [dot] com>
;; URL:       http://github.com/thoughtpolice/cryptol-mode
;; Package-Version: 20190531.2051
;; Package-Commit: 81ebbde83f7cb75b2dfaefc09de6a1703068c769
;; Keywords:  cryptol cryptography
;; Version:   0.1.0
;; Released:  3 March 2013

;; This file is not part of GNU Emacs.

;;; License:

;; Copyright (C) 2013-2016 Austin Seipp
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;; [ GPLv3 license: http://www.gnu.org/licenses/gpl-3.0.txt ]

;;; Commentary:

;; This package provides a major mode for editing, compiling and
;; running Cryptol code.
;;
;; For more information about Cryptol, check out the homepage and
;; documentation: http://www.cryptol.net/
;;
;; For usage info, release notes and bugs, check the homepage.

;;; TODO:

;; * Indentation mode:
;;  - Maybe something like Haskell-mode?
;; * Better highlighting and syntax recognition:
;;  - Function names in particular.
;; * Interactive features:
;;  - Run 'check' or 'exhaust' on identifier (see REPL notes below.)
;;  - Prove function equivalence between top-level named identifiers.
;; * REPL integration:
;;  - Run 'check', 'exhaust', or 'prove' on given function/theorem.
;;  - Automatically run batch-mode files.
;; * Cross platformness:
;;  - Works OK on Linux, OS X
;;  - Untested on Windows

;;; Known bugs:

;; * Literate file support is non-existant.
;; * Indentation support is also non-existant.
;; * Highlighting is rather haphazard, but fairly complete.

(require 'comint)
(require 'shell)
(require 'easymenu)
(require 'font-lock)
(require 'generic-x)
(require 'thingatpt)
(require 'ansi-color)

;;; -- Customization variables -------------------------------------------------

(defconst cryptol-mode-version "0.1.0"
  "The version of `cryptol-mode'.")

(defgroup cryptol nil
  "A Cryptol major mode."
  :group 'languages)

(defcustom cryptol-tab-width tab-width
  "The tab width to use when indenting."
  :type  'integer
  :group 'cryptol)

(defcustom cryptol-command "cryptol"
  "The Cryptol command to use for evaluating code."
  :type  'string
  :group 'cryptol)

(defcustom cryptol-args-repl '("--color=always")
  "The arguments to pass to `cryptol-command' when starting a
   REPL. Note that currently these only apply to Cryptol 1"
  :type  'list
  :group 'cryptol)

(defcustom cryptol-lib-path '()
  "A list of paths, to be passed to cryptol in the CRYPTOLPATH environment
   variable. Use this to specify external libraries to load."
  :type  'list
  :group 'cryptol)

(defcustom cryptol-mode-hook nil
  "Hook called by `cryptol-mode'."
  :type  'hook
  :group 'cryptol)

(defcustom cryptol-repl-hook nil
  "Hook called when `cryptol-repl' is invoked."
  :type 'hook
  :group 'cryptol)

(defvar cryptol-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-l") 'cryptol-repl)
    map)
  "Keymap for `cryptol-mode'.")

(defvar *cryptol-pathsep*
  ":" ;; TODO FIXME: windows uses ';' it seems
  )

;;; -- Language Syntax ---------------------------------------------------------

(defvar cryptol-string-regexp "\"\\.\\*\\?")

(defvar cryptol-symbols-regexp
  (regexp-opt '( "\\" "->" "<-" "=>" "=" "." ":" ".." "..." "|" "<|" "|>" )
              'symbols))

(defvar cryptol-symbols2-regexp "[!#$%&*+./:<=>?@\\^|~-]+")

(defvar cryptol-consts-regexp
  (regexp-opt '( "True" "False" "inf" "fin" ) 'words))

(defvar cryptol-type-regexp "\\<[[:upper:]]\\w*")

(defvar cryptol-keywords-regexp
  (regexp-opt '("else" "include" "property" "let" "newtype" "primitive"
                "extern" "module" "then" "import" "infixl" "parameter"
                "if" "newtype" "type" "as" "infixr" "constraint"
                "private" "pragma" "where" "hiding" "infix") 'words))

;;; -- Syntax table and highlighting -------------------------------------------

(defvar cryptol-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?/ "_ 124" st)
    (modify-syntax-entry ?* "_ 23bn" st)
    (modify-syntax-entry ?! "_" st)
    (modify-syntax-entry ?# "_" st)
    (modify-syntax-entry ?$ "_" st)
    (modify-syntax-entry ?% "_" st)
    (modify-syntax-entry ?. "_" st)
    (modify-syntax-entry ?: "_" st)
    (modify-syntax-entry ?? "_" st)
    (modify-syntax-entry ?@ "_" st)
    (modify-syntax-entry ?\\ "_" st)
    (modify-syntax-entry ?^ "_" st)
    (modify-syntax-entry ?~ "_" st)
    (modify-syntax-entry ?_ "w" st)
    (modify-syntax-entry ?' "w" st)
    (modify-syntax-entry ?\n ">" st)
    st)
  "Syntax table for `cryptol-mode'.")

(defvar cryptol-font-lock-defaults
  `((,cryptol-string-regexp   . font-lock-string-face)
    (,cryptol-symbols-regexp  . font-lock-builtin-face)
    (,cryptol-symbols2-regexp . font-lock-variable-name-face)
    (,cryptol-keywords-regexp . font-lock-keyword-face)
    (,cryptol-consts-regexp   . font-lock-constant-face)
    (,cryptol-type-regexp     . font-lock-type-face)
    ))

;;; -- Utilities, cryptol info, etc. -------------------------------------------

(defvar *cryptol-version* nil)

(defun process-lines-cryptol (&rest args)
  "Run cryptol with the specified arguments."
  (when (not (eq nil args))
    (apply 'process-lines (append (list cryptol-command) args))))

(defun get-cryptol-version ()
  "Get the version information supported by `cryptol-mode'"
  (if (not (eq nil *cryptol-version*))
      *cryptol-version*
    (let ((cryptol-version
           (split-string
             (car (process-lines-cryptol "-v")))))
      (setq *cryptol-version*
              (mapconcat 'identity (nthcdr 1 cryptol-version) ""))
      *cryptol-version*)))

;;;###autoload
(defun cryptol-version ()
  "Show the `cryptol-mode' version in the echo area."
  (interactive)
  (let ((cryptol-ver-out (get-cryptol-version)))
    (message (concat "cryptol-mode v" cryptol-mode-version
                     ", using Cryptol version " cryptol-ver-out))))

;;; -- REPL interaction --------------------------------------------------------

(defvar cryptol-repl-process nil
  "The active Cryptol subprocess corresponding to the current buffer.")

(defvar cryptol-repl-process-buffer nil
  "*Buffer used for communication with Cryptol subprocess for current buffer.")

(defvar cryptol-repl-comint-prompt-regexp
  "^\\*?[[:upper:]][\\._[:alnum:]]*\\( \\*?[[:upper:]][\\._[:alnum:]]*\\)*> "
  "A regexp that matches the Cryptol prompt.")

(defun cryptol-repl ()
  "Launch a Cryptol REPL using `cryptol-command' as an inferior executable."
  (interactive)

  (message "Starting Cryptol REPL via `%s'." cryptol-command)
  ;; Set up the environment via CRYPTOLPATH
  (let ((emacs-paths (mapconcat 'identity cryptol-lib-path *cryptol-pathsep*))
	(priorenv    (getenv "CRYPTOLPATH"))
	(extra       (if (eq '() cryptol-lib-path) "" *cryptol-pathsep*)))
    (let ((result (concat emacs-paths extra priorenv)))
      (if (not (eq "" result))
	  (setenv "CRYPTOLPATH" result))))

  (let ((args cryptol-args-repl))
    (setq cryptol-repl-process-buffer
          (apply 'make-comint
                 "cryptol" cryptol-command nil
                 (if (eq nil (buffer-file-name))
                     args
                   (append args (list buffer-file-name))))))

  (setq cryptol-repl-process
        (get-buffer-process cryptol-repl-process-buffer))

  ;; Select REPL buffer and track `:cd' changes etc.
  (set-buffer cryptol-repl-process-buffer)
  (make-local-variable 'shell-cd-regexp)
  (make-local-variable 'shell-dirtrackp)

  (setq shell-cd-regexp ":cd")
  (setq shell-dirtrackp t)
  (add-hook 'comint-input-filter-functions 'shell-directory-tracker nil 'local)

  (setq comint-prompt-regexp cryptol-repl-comint-prompt-regexp)

  (add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)
  (add-to-list 'comint-output-filter-functions 'ansi-color-process-output)
  (add-hook 'comint-output-filter-functions 'cryptol-repl--highlight-output-locations nil t)
  (add-hook 'comint-output-filter-functions 'cryptol-repl--highlight-error-warning nil t)

  (setq comint-input-autoexpand nil)
  (setq comint-process-echoes nil)

  ;; Run hooks and clear message buffer
  (run-hooks 'cryptol-repl-hook)
  (pop-to-buffer "*cryptol*")
  (message ""))

(defvar cryptol-repl--location-regexp
  (rx (seq "at "
           (group-n 6 (seq (group-n 1 (1+ (not (any ?\:)))) ":" (group-n 2 (1+ digit)) ":" (group-n 3 (1+ digit))
                           (zero-or-one (seq "--" (group-n 4 (1+ digit)) ":" (group-n 5 (1+ digit))))))))
  "Regexp matching Cryptol REPL source locations.")

(defun cryptol-repl--select-range-relative (start-line start-column end-line end-column)
  "Select the range from START-LINE and START-COLUMN to END-LINE and END-COLUMN.

This function assumes that the buffer has been narrowed or
widened such that `point-min' returns the position that the line
and columns are relative to."
  (goto-char (point-min))
  (forward-line (1- start-line))
  (forward-char (1- start-column))
  (let ((start-pos (point)))
    (when (and end-line end-column)
      (goto-char (point-min))
      (forward-line (1- end-line))
      (forward-char (1- end-column))
      (let ((end-pos (point)))
        (push-mark end-pos t t)
        (goto-char start-pos)))))

(defun cryptol-repl--highlight-output-locations (_orig)
  "Add highlighted overlays to Cryptol source locations."
  (save-excursion
    (save-restriction
      (widen)
      (narrow-to-region comint-last-output-start
                        (process-mark cryptol-repl-process))
      (goto-char (point-min))
      (while (re-search-forward cryptol-repl--location-regexp nil t)
        (let ((file (match-string 1))
              (line (string-to-number (match-string 2)))
              (column (string-to-number (match-string 3)))
              (end-line (let ((str (match-string 4)))
                          (and str (string-to-number str))))
              (end-column (let ((str (match-string 5)))
                            (and str (string-to-number str))))
              (start (match-beginning 6))
              (end (match-end 6))
              (input-start (marker-position comint-last-input-start))
              (input-end (marker-position comint-last-input-end)))
          (let ((overlay (make-overlay start end))
                (keymap (let ((map (make-sparse-keymap))
                              (goto-pos #'(lambda ()
                                            (interactive)
                                            (if (string= file "<interactive>")
                                                (with-current-buffer cryptol-repl-process-buffer
                                                  (save-restriction
                                                    (narrow-to-region input-start input-end)
                                                    (cryptol-repl--select-range-relative line column
                                                                                         end-line end-column)))
                                              (let ((file-buffer (save-excursion (find-file file))))
                                                (with-current-buffer file-buffer
                                                  (save-restriction
                                                    (widen)
                                                    (cryptol-repl--select-range-relative line column
                                                                                         end-line end-column)))
                                                (pop-to-buffer file-buffer))))))
                          (define-key map (kbd "RET") goto-pos)
                          (define-key map (kbd "<mouse-2>") goto-pos)
                          (define-key map (kbd "<mouse-1>") goto-pos)
                          map)))
            (overlay-put overlay 'face 'link)
            (overlay-put overlay 'mouse-face 'highlight)
            (overlay-put overlay 'help-echo "mouse-2: jump to this location")
            (overlay-put overlay 'keymap keymap)))))))

(defvar cryptol-repl--error-or-warning-regexp
  (rx (or (group-n 1 "[error]") (group-n 2 "[warning]")))
  "Regexp matching errors (group 1) or warnings (group 2).")

(defun cryptol-repl--highlight-error-warning (_orig)
  "Add highlighted overlays to Cryptol error or warning markers."
  (save-excursion
    (save-restriction
      (widen)
      (narrow-to-region comint-last-output-start
                        (process-mark cryptol-repl-process))
      (goto-char (point-min))
      (while (re-search-forward cryptol-repl--error-or-warning-regexp nil t)
        (let ((errorp (match-string 1))
              (warningp (match-string 2))
              (start (match-beginning 0))
              (end (match-end 0)))
          (let ((overlay (make-overlay start end)))
            (overlay-put overlay 'face (cond (errorp 'compilation-error)
                                             (warningp 'compilation-warning)
                                             (t nil)))))))))

;;; ----------------------------------------------------------------------------
;;; -- Mode entry --------------------------------------------------------------

;;; ------------------------------------
;;; -- Cryptol mode

;; Major mode for cryptol code
;;;###autoload
(define-derived-mode cryptol-mode fundamental-mode "Cryptol"
  "Major mode for editing Cryptol code."

  ;; Syntax highlighting
  (setq font-lock-defaults '((cryptol-font-lock-defaults)))

  ;; Indentation, no tabs
  (set (make-local-variable 'tab-width) cryptol-tab-width)
  (setq indent-tabs-mode nil)

  ;; Comment syntax for M-;
  (set (make-local-variable 'comment-start) "//")
  (set (make-local-variable 'comment-end) ""))
(provide 'cryptol-mode)

;;; ------------------------------------
;;; -- Literate cryptol mode

;; Major mode for literate cryptol code
;;;###autoload
(define-derived-mode literate-cryptol-mode fundamental-mode "Literate Cryptol"
  "Major mode for editing Literate Cryptol code."

  ;; Syntax highlighting
  (setq font-lock-defaults '((lcryptol-font-lock-defaults)))

  ;; Indentation, no tabs
  (set (make-local-variable 'tab-width) cryptol-tab-width)
  (setq indent-tabs-mode nil))
(provide 'literate-cryptol-mode)

;;; ------------------------------------
;;; -- Batch file mode

;; Major mode used for .scr files (batch files)
;;;###autoload
(define-generic-mode 'cryptol-batch-mode
  '("#")                               ;; comments start with #
  '("autotrace" "bind_file" "browse"
    "cd" "check" "compile" "config"
    "definition" "deltr" "edit"
    "equals" "exhaust" "fm" "genTests"
    "getserial" "help" "info"
    "install-runtime" "isabelle"
    "isabelle-b" "isabelle-i" "let"
    "load" "print" "prove" "quit"
    "reload" "runWith" "safe" "sat"
    "script" "sendserial" "set" "sfm"
    "showtr" "trace" "translate"
    "type" "version")
  '((":" . 'font-lock-builtin)         ;; ':' is a builtin
    ("@" . 'font-lock-operator))       ;; '@' is an operator
  nil nil                              ;; autoload is set below
  "A mode for Cryptol batch files")
(provide 'cryptol-batch-mode)

;;; -- Autoloading -------------------------------------------------------------

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.cry$\\|\\.cyl$"  . cryptol-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.lcry$\\|\\.lcyl$" . literate-cryptol-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.scr$"  . cryptol-batch-mode))

;;; cryptol-mode.el ends here
