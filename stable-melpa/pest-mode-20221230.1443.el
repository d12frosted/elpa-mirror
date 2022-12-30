;;; pest-mode.el --- Major mode for editing Pest files -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2020  ksqsf

;; Author: ksqsf <i@ksqsf.moe>
;; URL: https://github.com/ksqsf/pest-mode
;; Package-Version: 20221230.1443
;; Package-Commit: 4a367a0fb9f9ac9cff8b1798335f6248d4cb3467
;; Keywords: languages
;; Version: 0.1
;; Package-Requires: ((emacs "26.3"))

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides GNU Emacs major modes for editing Pest
;; grammar files.  Currently, it supports syntax highlighting,
;; indentation, imenu integration.

;; Syntax checking is available from flymake-pest or flycheck-pest.

;; Also, you can use `pest-test-grammar' to open a new buffer, in
;; which you can experiment with your language defined by the
;; grammar.  In this new buffer, you can use `pest-analyze-input'
;; (default keybinding: C-c C-c) to analyze the input, which will
;; give you an analysis report of the structure.  Also, if
;; `eldoc-mode' is enabled, put the point anywhere under an
;; grammatical element, a path on the parse tree will be shown in
;; the minibuffer.

;;; Code:

(require 'subr-x)
(require 'rx)
(require 'imenu)
(require 'json)
(require 'eldoc)
(require 'xref)

(eval-when-compile (require 'cl-lib))

(defgroup pest nil
  "Support for Pest grammar files."
  :group 'languages)

(defcustom pest-pesta-executable
  (executable-find "pesta")
  "Location of pesta executable."
  :type 'file
  :group 'pest)



(defvar pest--highlights
  `((,(rx "'" (char alpha) "'")                         . font-lock-string-face)
    (,(rx (or "SOI" "EOI" "@" "+" "*" "?" "~"))         . font-lock-keyword-face)
    (,(rx (+ (or alpha "_")) (* (or (char alnum) "_"))) . font-lock-variable-name-face)))

(defconst pest-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?' "\"" table)
    (modify-syntax-entry ?\" "\"" table)

    (modify-syntax-entry ?/ ". 12" table)
    (modify-syntax-entry ?\n ">" table)
    table))

(defun pest-indent-line (&optional indent)
  "Indent the current line according to the Pest syntax, or supply INDENT."
  (interactive "P")
  (let ((pos (- (point-max) (point)))
        (indent (or indent (pest--calculate-indentation)))
        (shift-amt nil)
        (beg (progn (beginning-of-line) (point))))
    (skip-chars-forward " \t")
    (if (null indent)
        (goto-char (- (point-max) pos))
      (setq shift-amt (- indent (current-column)))
      (unless (zerop shift-amt)
        (delete-region beg (point))
        (indent-to indent))
      (when (> (- (point-max) pos) (point))
        (goto-char (- (point-max) pos))))))

(defun pest--calculate-indentation ()
  "Calculate the indentation of the current line."
  (let (indent)
    (save-excursion
      (back-to-indentation)
      (let* ((ppss (syntax-ppss))
             (depth (car ppss))
             (paren-start-pos (cadr ppss))
             (base (* 4 depth))
             (rule-sep-limit (max paren-start-pos (line-beginning-position)))
             (rule-sep (save-excursion
                         (or (looking-at "|")
                             (re-search-backward "|" rule-sep-limit t)))))
        (unless (= depth 0)
          (setq indent base)
          (if (looking-at "\\s)")
              (setq indent (- base 4))
            (if rule-sep
              (setq indent (- base 2)))))))
    indent))



(defvar pest--rule-regexp (rx bol
                              (group (+ (or alpha "_") (* (or (char alnum) "_"))))
                              (* blank)
                              "=" (* blank) (or (and "_" (* blank) "{")
                                                (and "@" (* blank) "{")
                                                (and "!" (* blank) "{")
                                                (and "$" (* blank) "{")
                                                "{")))

(defun pest--match-rule-name ()
  "Extract the rule name from last match."
  (match-string-no-properties 1))

(defun pest-imenu-prev-index-position ()
  "Jumps to the beginning of the previous rule."
  (re-search-backward pest--rule-regexp (point-min) t))

(defun pest-imenu-extract-index-name ()
  "Extract rule name here.
Should be called right after `pest-imenu-prev-index-position'."
  (pest--match-rule-name))

(defun pest--rule-list (&optional buffer)
  "Extract a list of all rules in the current buffer or BUFFER."
  (with-current-buffer (or buffer (current-buffer))
    (save-excursion
      (save-restriction
        (widen)
        (goto-char (point-min))
        (cl-loop
         while (re-search-forward pest--rule-regexp nil t)
         collect (pest--match-rule-name))))))



(defvar-local pest--grammar-buffer nil)

(defun pest-test-grammar ()
  "Test the grammar in the current buffer on arbitrary input in a newly-created buffer, with real-time diagnosis messages."
  (interactive)
  (let ((grammar-buffer (current-buffer)))
    (message "Associate with grammar %s" grammar-buffer)
    (switch-to-buffer-other-window "*pest-input*")
    (pest-input-mode)
    (setq-local pest--grammar-buffer grammar-buffer)))



(defvar pest-mode-map
  (let ((map (make-sparse-keymap))
        (menu-map (make-sparse-keymap "Pest")))
    (set-keymap-parent map prog-mode-map)
    (define-key map (kbd "C-c C-t") #'pest-test-grammar)
    (define-key map [menu-bar pest] (cons "Pest" menu-map))
    (define-key menu-map [test-grammar]
      '(menu-item "Test grammar" pest-test-grammar
                  :help "Test this grammar on arbitrary input"))
    map)
  "Keymap for Pest mode.")

(defun pest-font-lock-syntactic-face-function (state)
  "Return syntactic face given STATE."
  (if (nth 3 state)
      font-lock-string-face
    font-lock-comment-face))



(defun pest--xref-backend ()
  "Return the xref backend identifier for pest."
  'pest)

(cl-defmethod xref-backend-definitions ((_backend (eql pest)) identifier)
  (save-excursion
    (goto-char (point-min))
    (cl-loop
     while (re-search-forward pest--rule-regexp nil t 1)
     if (string= identifier (pest--match-rule-name))
     collect (xref-make (pest--match-rule-name)
                        (xref-make-buffer-location (current-buffer)
                                                   (match-beginning 0))))))



;;;###autoload
(define-derived-mode pest-mode prog-mode "Pest"
  "Major mode for editing Pest files.

\\{pest-mode-map}"
  :syntax-table pest-mode-syntax-table
  (setq-local font-lock-defaults
              '(pest--highlights
                nil nil nil nil
                (font-lock-syntactic-face-function . pest-font-lock-syntactic-face-function)))
  (setq-local indent-line-function #'pest-indent-line)
  (setq-local comment-start "// ")
  (setq-local comment-end "")
  (setq-local imenu-prev-index-position-function #'pest-imenu-prev-index-position)
  (setq-local imenu-extract-index-name-function #'pest-imenu-extract-index-name)
  (add-hook 'xref-backend-functions #'pest--xref-backend))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.pest\\'" . pest-mode))
;;;###autoload
(add-to-list 'interpreter-mode-alist '("pest" . pest-mode))



(defvar-local pest--lang-analyze-proc nil)
(defvar-local pest--selected-rule nil)

(defun pest-select-rule ()
  "Select a rule for further analysis."
  (interactive)
  (unless pest--grammar-buffer
    (error "This buffer is not associated with a Pest grammar!"))
  (let* ((rules (pest--rule-list pest--grammar-buffer))
         (rule (completing-read "Start rule: " rules nil t)))
    (if (member rule rules)
        (setq-local pest--selected-rule rule)
      (error "You must select a valid rule!"))))

(defun pest-analyze-input (&optional no-switch)
  "Analyze the input and show a report of the parsing result in a new buffer.

By default, you'll be directed to the analysis report, unless the
flag NO-SWITCH is non-nil."
  (interactive)
  (unless pest-pesta-executable
    (error "Cannot find a suitable `pesta' executable"))
  (when (process-live-p pest--lang-analyze-proc)
    (kill-process pest--lang-analyze-proc))
  (if (null pest--selected-rule)
      (message "You haven't selected a rule to start; do so with `pest-select-rule'.")
    (let ((source (current-buffer))
          (selected-rule pest--selected-rule)
          (output (get-buffer-create "*pest-analyze*")))
      (message "Analyze with start rule: %s" selected-rule)
      (with-current-buffer output
        (delete-region (point-min) (point-max)))
      (setq pest--lang-analyze-proc
            (make-process
             :name "pest-analyze"
             :noquery t
             :connection-type 'pipe
             :buffer output
             :command `(,pest-pesta-executable "lang_analyze" ,selected-rule)
             :sentinel
             (lambda (proc _event)
               (when (eq 'exit (process-status proc))
                 (unwind-protect
                     (unless (with-current-buffer source (eq proc pest--lang-analyze-proc))
                       (message "Canceling obsolete analysis %s" proc)))
                 (unless no-switch
                   (switch-to-buffer-other-window output)
                   (goto-char (point-min)))))))
      (let* ((grammar (with-current-buffer pest--grammar-buffer
                        (buffer-string)))
             (input (with-current-buffer source (buffer-string)))
             (data-to-send (json-encode-list (list grammar input))))
        (process-send-string pest--lang-analyze-proc data-to-send)
        (process-send-eof pest--lang-analyze-proc)))))

(defun pest-input-eldoc ()
  "The `eldoc-documentation-function' for `pest-input-mode'."
  (unless pest-pesta-executable
    (error "Cannot find a suitable `pesta' executable"))
  (if (null pest--selected-rule)
      (message "You haven't selected a start rule; do so with `pest-select-rule'")
    (save-excursion
      (let* ((source (buffer-string))
             (selected-rule pest--selected-rule)
             (grammar (with-current-buffer pest--grammar-buffer (buffer-string)))
             (pos (save-restriction (widen) (point))))
        (with-temp-buffer
          (call-process-region (json-encode-list (list grammar source)) nil pest-pesta-executable
                               nil (current-buffer) nil
                               "lang_point" selected-rule (number-to-string pos))
          (string-trim-right (buffer-string)))))))

(defvar pest-input-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") #'pest-analyze-input)
    (define-key map (kbd "C-c C-r") #'pest-select-rule)
    map))

(define-derived-mode pest-input-mode text-mode "Pest-Input"
  "Major mode for input to test a Pest grammar file.  This mode should only be enabled with `pest-test-grammar'.

\\{pest-input-mode-map}"
  (setq-local eldoc-documentation-function #'pest-input-eldoc)
  (eldoc-mode))

(provide 'pest-mode)

;;; pest-mode.el ends here
