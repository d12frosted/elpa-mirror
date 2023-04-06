;;; nickel-mode.el --- A major mode for editing Nickel source code -*-lexical-binding: t-*-

;; Copyright (c) Tweag I/O Limited.

;; Version: 0.1
;; Package-Version: 20230406.910
;; Package-Commit: fea2152d591e46e19e4be6a7aca7fb0b1de15dd0
;; Author: The Nickel Team (nickel-lang@tweag.io)
;; Url: https://github.com/nickel-lang/nickel-mode
;; Created: 7 March 2023
;; Keywords: languages configuration-language configuration nickel infrastructure
;; Homepage: https://nickel-lang.org/
;; Package-Requires: ((emacs "24.3"))

;; This file is distributed under the terms of MIT license.

;;; Commentary:

;; This package implements a major-mode for editing Nickel source code.


;;; Code:

(defgroup nickel nil
  "Major mode for editing Nickel source code."
  :group 'languages
  :link '(url-link :tag "Site" "https://nickel-lang.org/")
  :link '(url-link :tag "Repository" "https://github.com/nickel-lang/nickel-mode"))

(defconst nickel-mode-keywords
  (regexp-opt '("if" "then" "else" "forall" "in" "let"
                "rec" "match" "fun" "import" "merge"
                "default" "doc" "optional" "priority" "force" "not_exported")
              'symbols))

(defconst nickel-mode-constants
  (regexp-opt '("true" "false" "null")
              'symbols))

(defconst nickel-mode-types
  (regexp-opt '("Dyn" "Number" "String" "Array" "Bool")
              'symbols))

(defconst nickel-mode-primops
  (regexp-opt '("%typeof%" "%assume%" "%array_lazy_assume%" "%dictionary_assume%"
                "%blame%" "%chng_pol%" "%polarity%" "%go_dom%" "%go_codom%" "%go_field%"
                "%go_array%" "%go_dict%" "%seal%" "%unseal%" "%embed%" "%record_map%"
                "%record_insert%" "%record_remove%" "%record_empty_with_tail%" "%record_seal_tail%"
                "%record_unseal_tail%" "%seq%" "%deep_seq%" "%force%" "%head%" "%tail%" "%length%"
                "%fields%" "%values%" "%pow%" "%trace%" "%has_field%" "%map%" "%elem_at%" "%generate%"
                "%rec_force%" "%rec_default%" "%serialize%" "%deserialize%")
              'symbols))


(defconst nickel-mode-identifiers (rx symbol-start alpha (* (or alpha ?\_ ?\')) symbol-end))
(defconst nickel-mode-enum-tags (rx symbol-start ?\` alpha (* (or alpha ?\_ ?\')) symbol-end))
(defconst nickel-mode-numbers (rx symbol-start (optional ?\-) (+ digit) (optional ?\. (+ digit)) symbol-end))
(defconst nickel-mode-operators
  (regexp-opt
   '("->" "\\[" "]" "," "|" ":" "=" "==" "|>"
     "!=" ")" "&&" "||" "{" "}" "(" "?" ";" "$" "&" "."
     "\"" "+" "-" "*" "/" "%" "@" "!" ".." "=>" "_" "<" ">"
     "<=" ">=" "[|" "|]" "++")))

(defconst nickel-mode-font-lock-keywords
  `((,nickel-mode-keywords . font-lock-keyword-face)
    (,nickel-mode-constants . font-lock-constant-face)
    (,nickel-mode-primops . font-lock-builtin-face)
    (,nickel-mode-enum-tags . font-lock-constant-face)
    (,nickel-mode-types . font-lock-type-face)
    (,nickel-mode-identifiers . font-lock-variable-name-face)
    (,nickel-mode-numbers . font-lock-constant-face)
    (,nickel-mode-operators . font-lock-builtin-face)))

(defun nickel-syntax-stringify ()
  "Having matched a multiline string, propertize the matched region."
  (unless (or (nth 3 (syntax-ppss)) (nth 4 (syntax-ppss)))
    (let ((start (match-beginning 0))
          (end (match-end 0)))
      (goto-char start)
      (skip-chars-forward "m%")
      (put-text-property (point) (1+ (point)) 'syntax-table (string-to-syntax "|"))
      (forward-char 1)
      (goto-char end)
      (skip-chars-backward "m%")
      (backward-char 1)
      (put-text-property (point) (1+ (point)) 'syntax-table (string-to-syntax "|")))))

(defconst nickel-syntax-propertize-function
  (syntax-propertize-rules
   ((rx "m" (group (+ "%")) ?\" (minimal-match (* (or nonl ?\n))) ?\" (backref 1))
    (0 (ignore (nickel-syntax-stringify))))
   ((rx ?\" (* not-newline) ?\")
    (0 (ignore (nickel-syntax-stringify)))))
  "A Nickel-specific `syntax-propertize-function'.")

;; Use Nickel mode for .ncl files
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.ncl\\'" . nickel-mode))

(defconst nickel-mode-syntax-table
  (let ((st (make-syntax-table)))
    ;; Handle comments
    (modify-syntax-entry ?# "<" st)
    (modify-syntax-entry ?\n ">" st)
    st))


;;;###autoload
(define-derived-mode nickel-mode prog-mode
  "Nickel"
  "Major mode for editing Nickel source code."
  :group 'nickel
  (setq font-lock-defaults '((nickel-mode-font-lock-keywords)))
  (set-syntax-table nickel-mode-syntax-table)
  (setq-local syntax-propertize-function nickel-syntax-propertize-function))


(provide 'nickel-mode)

;;; nickel-mode.el ends here

;; Local Variables:
;; indent-tabs-mode: nil
;; End:
