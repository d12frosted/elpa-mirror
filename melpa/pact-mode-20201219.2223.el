;;; pact-mode.el --- Mode for Pact, a LISPlike smart contract language. -*- lexical-binding: t; -*-

;; Copyright (c) 2016 - 2019 Stuart Popejoy

;; Author: Stuart Popejoy
;; Maintainer: Stuart Popejoy <stuart@kadena.io>
;; Maintainer: Emily Pillmore <emily@kadena.io>
;; Maintainer: Colin Woodbury <colin@kadena.io>
;; Keywords: pact, lisp, languages, blockchain, smartcontracts, tools, mode
;; Package-Version: 20201219.2223
;; Package-Commit: f48a4faf5f8f8435423bda3888eca6ee67ee13a9
;; Version: 0.0.5-git
;; URL: https://github.com/kadena-io/pact-mode
;; Package-Requires: ((emacs "24.3"))

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; A major mode for editing Pact, a smart contract language, in Emacs.
;; See `http://kadena.io/pact'.

;;; Change Log:

;; Version 0.0.5
;;   Enable syntax highlighting for new keywords.

;;; Code:

(require 'semantic)
(require 'semantic/bovine/el)
(require 'inf-lisp)

(defconst pact-symbols "%#+_&$@<>=^?*!|/-"
  "Regexp match for non-alphanumerics in pact symbols.")

(defconst pact-identifier
  (concat "[[:alnum:]][[:alnum:]" pact-symbols "]*")
  "Regexp match for valid pact identifiers.")

(defconst pact-font-lock-keywords
  `( ;; Function definition (anything that starts with def and is not
    ;; listed above)
    (,(concat "\\(def[^ \r\n\t]*\\)"
              "\\>"
              "[ \r\n\t]*"
              "\\(" pact-identifier "\\)?")
     (1 font-lock-keyword-face)
     (2 font-lock-function-name-face nil t))
    ;; Special forms
    (,(concat
       "("
       (regexp-opt
        '("module" "list" "let*" "let"
          "step" "use" "step-with-rollback"
          "interface" "implements" "if" "bless") t)
       "\\>")
     1 font-lock-keyword-face)
    ;; Macros similar to let, when, and while
    (,(rx symbol-start
          (or "let" "when" "while") "-"
          (1+ (or (syntax word) (syntax symbol)))
          symbol-end)
     0 font-lock-keyword-face)
    ;; Global constants - nil, true, false
    (,(concat
       "\\<"
       (regexp-opt
        '("true" "false") t)
       "\\>")
     0 font-lock-constant-face)
    ;; Number literals
    (,"\\b\\([[:digit:][[:digit:].]*\\)\\b" 0 'font-lock-constant-face)
    ;; Highlight `code` marks, just like `elisp'.
    (,(rx "`" (group-n 1 (optional "#'")
                       (+ (or (syntax symbol) (syntax word)))) "`")
     (1 'font-lock-constant-face prepend))
    )
  "Default expressions to highlight in Pact mode.")

;;;###autoload
(define-derived-mode pact-mode lisp-mode "Pact"
  "Major more for editing Pact smart contracts and test scripts."
  :group 'pact
  (setq-local font-lock-defaults
              '((pact-font-lock-keywords)
                nil nil nil nil
                (font-lock-mark-block-function . mark-defun)))
  (setq-local indent-tabs-mode nil)
  (setq-local semantic-function-argument-separation-character " ")
  (setq-local semantic-function-argument-separator " ")
  (setq-local semantic--parse-table semantic--elisp-parse-table)
  (setq-local inferior-lisp-program "pact")
  (setq-local inferior-lisp-load-command "(load \"%s\" true)\n")
  (setq-local electric-indent-inhibit t)
  (semantic-mode)
  (substitute-key-definition 'lisp-load-file 'pact-load-file lisp-mode-map)
  (substitute-key-definition 'lisp-compile-defun 'pact-compile lisp-mode-map)
  )

;;;###autoload
(defface pact-error-face
  '((((supports :underline (:style wave)))
     :underline (:style wave :color "#dc322f"))
    (t
     :inherit error))
  "Face used for marking error lines."
  :group 'pact-mode)

;;;###autoload
(defface pact-warning-face
  '((((supports :underline (:style wave)))
     :underline (:style wave :color "#b58900"))
    (t
     :inherit warning))
  "Face used for marking warning lines."
  :group 'pact-mode)

(defun pact-load-file (prompt)
  "Load current buffer into pact inferior process.
With prefix, prompt for file to load."
  (interactive "P")
  (let ((fname
         (if prompt
             (expand-file-name (read-file-name "Load pact file: " nil nil t))
           (buffer-name))))
    (inferior-lisp inferior-lisp-program)
    (lisp-load-file fname)))

(defvar pact-compile-cmd "pact %s"
  "Command template for `pact-compile'")

(defvar pact-compile-history nil
  "Compile command history for `pact-compile'")

(defun pact-compile (prompt)
  "Compile current buffer. With prefix, prompt for compilation command."
  (interactive "P")
  (remove-overlays)
  (add-hook 'compilation-finish-functions 'pact-get-compile-errors)
  (let*
      ((defcmd (format pact-compile-cmd (buffer-name)))
       (cmd (if prompt
                (read-string "Compile pact with: " nil 'pact-compile-history defcmd)
              defcmd)))
    (compile cmd t)))


(defun pact-get-compile-errors (cmpbuf statusdesc)
  (when cmpbuf (set-buffer cmpbuf))
  (goto-char (point-min))
  (remove-hook 'compilation-finish-functions 'pact-get-compile-errors)
  (let ((first-err nil))
    (while
        (when-let
            ((proppos (next-single-property-change (point) 'compilation-message))
             (prop (get-text-property proppos 'compilation-message))
             (endpos (next-single-property-change proppos 'compilation-message))
             (loc (compilation--message->loc prop))
             (fs (compilation--loc->file-struct loc))
             (file (caar fs))
             (line (cadr loc))
             (col (car loc)))
          (goto-char endpos)
          ;;(message "%s %s %s" file line col)
          (when-let
              ((fbuf (get-buffer file))
               (msg (buffer-substring endpos (line-end-position))))
            (save-excursion
              (set-buffer fbuf)
              (goto-line line)
              (forward-char col)
              (let*
                  ((o (point))
                   (ovl (make-overlay o (+ 4 o))))
                (overlay-put ovl 'face 'pact-error-face)
                (overlay-put ovl 'help-echo msg)
                (unless first-err (setq first-err ovl)))))
          endpos))
    (if first-err
        (progn
          (set-buffer (overlay-buffer first-err))
          (goto-char (overlay-start first-err))
          (message (overlay-get first-err 'help-echo)))
      (message "No errors found"))))




(put 'module 'lisp-indent-function 'defun)
(put 'with-read 'lisp-indent-function 2)
(put 'with-default-read 'lisp-indent-function 2)
(put 'with-keyset 'lisp-indent-function 2)
(put 'bind 'lisp-indent-function 2)

(semantic-elisp-setup-form-parser
    (lambda (form start end)
      (let ((tags
             (condition-case foo
                 (semantic-parse-region start end nil 1)
               (error (message "MUNGE: %S" foo)
                      nil))))
        (if (semantic-tag-p (car-safe tags))
            tags;;TODO can't add a tag for the module itself without everything going south
          (semantic-tag-new-code (format "%S" (car form)) nil))))
  module
  )

(semantic-elisp-setup-form-parser
    (lambda (form _start _end)
      (semantic-tag-new-function
       (symbol-name (nth 1 form))
       "pact"
       (semantic-elisp-desymbolify-args (nth 2 form))
       :documentation (semantic-elisp-do-doc (nth 3 form))
       ))
  defpact)

(semantic-elisp-setup-form-parser
    (lambda (form _start _end)
      (let ((name (nth 1 form)))
        (semantic-tag-new-include
         (symbol-name (if (eq (car-safe name) 'quote)
                          (nth 1 name)
                        name))
         nil
         :directory (nth 2 form))))
  use
  )

(semantic-elisp-setup-form-parser
    (lambda (form _start _end)
      (semantic-tag-new-variable
       (symbol-name (cadr (nth 1 form)))
       "table"
       nil
       nil
       :constant-flag t
       ))
  create-table
  )

(semantic-elisp-setup-form-parser
    (lambda (form _start _end)
      (semantic-tag-new-variable
       (symbol-name (cadr (nth 1 form)))
       "keyset"
       nil
       nil
       :constant-flag t
       ))
  define-keyset
  )

(define-mode-local-override semantic-dependency-tag-file
  pact-mode (tag)
  "Find the file BUFFER depends on described by TAG."
  (let ((fname (concat "./" (semantic-tag-name tag) ".pact")))
    (message "go: %s %s" fname (file-exists-p fname))
    (semantic--tag-put-property tag 'dependency-file fname)))

;;;###autoload
(add-to-list 'auto-mode-alist
             '("\\.\\(pact\\|repl\\)\\'" . pact-mode))

(modify-syntax-entry ?\[ "(]" pact-mode-syntax-table)
(modify-syntax-entry ?\] ")\[" pact-mode-syntax-table)
(modify-syntax-entry ?\{ "(}" pact-mode-syntax-table)
(modify-syntax-entry ?\} ")\{" pact-mode-syntax-table)

(provide 'pact-mode)

;;; pact-mode.el ends here
