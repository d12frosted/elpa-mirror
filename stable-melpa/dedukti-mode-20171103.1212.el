;;; dedukti-mode.el --- Major mode for Dedukti files

;; Copyright 2013 Raphaël Cauderlier

;; Author: Raphaël Cauderlier
;; Version: 0.1
;; Package-Version: 20171103.1212
;; Package-Commit: d7c3505a1046187de3c3aeb144455078d514594e
;; License: CeCILL-B
;; Keywords: languages dedukti
;; URL: https://github.com/rafoo/dedukti-mode

;;; Commentary:
;; This file defines a major mode for editing Dedukti files.
;; Dedukti is a type checker for the lambda-Pi-calculus modulo.
;; It is a free software under the CeCILL-B license.
;; Dedukti is available at the following URL:
;; <https://www.rocq.inria.fr/deducteam/Dedukti/>

;; This major mode is defined using the generic major mode mechanism.

;;; Code:

(require 'generic-x)
(require 'compile)
(require 'smie)

;; Customization

(defgroup dedukti nil
  "Major mode for Dedukti files."
  :group 'languages)

(defcustom dedukti-path "/usr/bin/dkcheck"
  "Path to the Dedukti type-checker."
  :group 'dedukti
  :type '(file :must-match t))

(defcustom dedukti-compile-options '("-nc" "-e")
  "Options to pass to Dedukti to compile files."
  :group 'dedukti
  :type '(list string))

(defcustom dedukti-check-options '("-nc")
  "Options to pass to Dedukti to typecheck files."
  :group 'dedukti
  :type '(list string))

(defcustom dedukti-reduction-command "#SNF %s."
  "Format of the Dedukti command used for reduction.
Typical values are \"#WHNF %s.\" for head normalization and
\"#SNF %s.\" for strong normalization.")

;; Generic major mode

(defvar dedukti-id
  "[_a-zA-Z0-9][_a-zA-Z0-9!?']*"
  "Regexp matching Dedukti identifiers.")

(defvar dedukti-qualifier
  "[_a-zA-Z0-9]+"
  "Regexp matching Dedukti qualifiers.")

(defvar dedukti-qid
  (format "\\(\\<%s\\>\\.\\)?\\<%s\\>"
          dedukti-qualifier
          dedukti-id)
  "Regexp matching Dedukti qualified identifiers.")

(defvar dedukti-qid-back
  (format "\\(\\(%s\\)?\\.\\)?%s"
          dedukti-qualifier
          dedukti-id)
  "Regexp matching Dedukti qualified identifiers and their suffixes backward.
Since characters are added one by one,
expressions of the form `.id' are allowed.")

(defvar dedukti-symbolic-keywords
  '(":="        ; Definition
    ":"         ; Declaration, annotated lambdas and pis
    "-->"       ; Rewrite-rule
    "->"        ; Pi (dependant type constructor)
    "=>"        ; Lambda (function constructor)
    "\\[" "\\]" ; Rewrite-rule environment
    "(" ")"     ; Expression grouping
    "{" "}"     ; Dot patterns
    ","         ; Environment separator
    "."         ; Global context separator
    "~="        ; Conversion test
    )
  "List of non-alphabetical Dedukti keywords.")

;;;###autoload
(define-generic-mode
  dedukti-mode
  ;; Comments in Dedukti are enclosed by "(;" and ";)"
  '(("(;" . ";)"))
  ;; The alphabetical keywords in Dedukti: Type, def, and thm
  '("Type" "def" "thm")
  ;; Font-locking:
  `(
    ;; Pragmas are highlighted using preprocessor-face
    (,(format "^ *#\\(IMPORT\\|NAME\\|ASSERT\\)[ \t]+%s" dedukti-qualifier) .
     'font-lock-preprocessor-face)
    ;; Declared and defined symbols are highlighted using function-name-face
    (,(format "^ *def *%s *:=?" dedukti-id) .
     'font-lock-function-name-face)
    (,(format "^ *thm *%s *:=" dedukti-id) .
     'font-lock-function-name-face)
    (,(format "^ *%s *:[^=]" dedukti-id) .
     'font-lock-function-name-face)
    ;; Variables in binders are also highlighted using function-name-face
    (,(format "%s *:[^=]" dedukti-id) .
     'font-lock-function-name-face)
    ;; Identifiers are highlighted differently whether they are qualified
    (,(format "%s\\.%s" dedukti-qualifier dedukti-id) .
     'font-lock-constant-face)               ;; qualified identifiers
    (,dedukti-id .
     'font-lock-variable-name-face)          ;; identifiers
    ;; Non-alphabetic keywords are highlighted using keyword-face
    (,(regexp-opt dedukti-symbolic-keywords)
     . 'font-lock-keyword-face)
    )
  '(".dk\\'")                                    ;; use this mode for .dk files
  nil
  "Major mode for editing Dedukti source code files.")

;; This duplicates the last line of the mode definition
;; but is needed for auto-loading
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.dk\\'" . dedukti-mode))

;; Error handling

;; Errors from the compilation buffer

(add-to-list 'compilation-error-regexp-alist
    `(,(format
        "^ERROR file:\\(%s.dk\\) line:\\([0-9]+\\) column:\\([0-9]+\\)"
        dedukti-qualifier)
      1                                 ; file is the first group of the regexp
      2                                 ; line number is the second
      3                                 ; column number is the third
      2                                 ; level is 2 (error)
      ))

(add-to-list 'compilation-error-regexp-alist
    `(,(format
        "^WARNING file:\\(%s.dk\\) line:\\([0-9]+\\) column:\\([0-9]+\\)"
        dedukti-qualifier)
      1                                 ; file is the first group of the regexp
      2                                 ; line number is the second
      3                                 ; column number is the third
      1                                 ; level is 1 (warning)
      ))

;; Calling Dedukti

(defun dedukti-compile-file (&optional file)
  "Compile file FILE with Dedukti.
If no file is given, compile the file associated with the current buffer."
  (interactive)
  (let ((file (or file (buffer-file-name))))
    (when file    ; if current buffer is not linked to a file, do nothing
      (eval `(start-process
              "Dedukti compiler"
              ,(get-buffer-create "*Dedukti Compiler*")
              ,dedukti-path
              ,@dedukti-compile-options
              ,file)))))

(add-hook 'dedukti-mode-hook
          (lambda () (local-set-key (kbd "C-c c") 'dedukti-compile-file)))
(add-hook 'dedukti-mode-hook
          (lambda () (local-set-key (kbd "C-c C-c") 'compile)))

;; Indentation

;; This is a simplified grammar for Dedukti in SMIE format

(defvar dedukti-smie-grammar
  (smie-prec2->grammar
   (smie-bnf->prec2
    '((id)
      (prelude ("#NAME" "NAME"))
      (line ("NEWID" "TCOLON" term ".")
            ("def" "NEWID" "TCOLON" term ".")
            ("def" "NEWID" ":=" term ".")
            ("def" "NEWID" "TCOLON" term ":=" term ".")
            ("thm" "NEWID" ":=" term ".")
            ("thm" "NEWID" "TCOLON" term ":=" term ".")
            ("[" context "]" term "-->" term)
            ("[" context "]" term "-->" term "."))
      (context ("CID" "," context)
               ("CID"))
      (tdecl ("ID" "LCOLON" term)
             (term))
      (term ("_")
            (tdecl "->" term)
            (tdecl "=>" term)))
    '((assoc ",")
      (assoc "->" "=>" "LCOLON")
      ))))

(defun dedukti-smie-pragmap ()
  "Return non-nil if point is on a pragma line.
A pragma line is a line starting with a sharp (#) character."
  (save-excursion
    (back-to-indentation)
    (looking-at "#")))

(defun dedukti-smie-position ()
  "Tell in what part of a Dedukti file point is.
Return one of:
- 'comment when point is inside a comment
- 'pragma when point is in a line starting by a `#'
- 'context when point is in a rewrite context
           and not inside a sub-term
- 'top when point is before the first `:' or `:=' of the line
- nil otherwise"
  (cond
   ((nth 4 (syntax-ppss))
    'comment)
   ((dedukti-smie-pragmap)
    'pragma)
   ((looking-back "[[][^]]*")
    'context)
   ((looking-back "\\(#\\|\\.[^a-zA-Z0-9_]\\)[^.#:]*")
    'top)))

(defun dedukti-smie-position-debug ()
  "Print the current value of `dedukti-smie-position'."
  (interactive)
  (prin1 (dedukti-smie-position)))

(defun dedukti-smie-forward-token ()
  "Forward lexer for Dedukti."
  ;; Skip comments
  (forward-comment (point-max))
  (cond
   ;; Simple tokens
   ((looking-at (regexp-opt
                 '("def"
                   "thm"
                   ":="
                   "-->"
                   "->"
                   "=>"
                   ","
                   "."
                   "~="
                   "["
                   "]"
                   "#NAME"
                   "#IMPORT"
                   "#ASSERT")))
    (goto-char (match-end 0))
    (match-string-no-properties 0))
   ((looking-at ":")
    ;; There are three kinds of colons in Dedukti and they can hardly
    ;; be distinguished at parsing time;
    ;; Colons can be used in rewrite contexts (RCOLON),
    ;; in local bindings of -> and => (LCOLON)
    ;; and at toplevel (TCOLON).
    (prog1
        (pcase (dedukti-smie-position)
          (`top "TCOLON")
          (_ "LCOLON"))
      (forward-char)))
   ;; Identifier: discard the name and return its kind
   ((looking-at dedukti-qid)
    (goto-char (match-end 0))
    (pcase (dedukti-smie-position)
      (`pragma "NAME")
      (`context "CID")
      (`opaque "OPAQUEID")
      (`top "NEWID")
      (_ "ID")))
   ((looking-at "(") nil)
   (t (buffer-substring-no-properties
       (point)
       (progn (skip-syntax-forward "w_")
              (point))))))

(defun dedukti-forward ()
  "Move forward by one token or by a sexp."
  (interactive)
  (let ((beg (point)))
    (prog1
        (or (dedukti-smie-forward-token)
            (forward-sexp))
      (when (eq beg (point))
        (forward-char)))))

(defun dedukti-smie-forward-debug ()
  "Print the current value of `dedukti-smie-forward-token'."
  (interactive)
  (let ((v (dedukti-forward)))
    (when v (princ v))))

(defun dedukti-smie-backward-token ()
  "Backward lexer for Dedukti."
  (forward-comment (- (point)))
  (cond
   ((looking-back (regexp-opt
                 '(":="
                   "-->"
                   "->"
                   "=>"
                   ","
                   "."
                   "~="
                   "["
                   "]"
                   "#NAME"
                   "#IMPORT"
                   "#ASSERT"))
                  (- (point) 7))
    (goto-char (match-beginning 0))
    (match-string-no-properties 0))
   ((looking-back ":")
    (backward-char)
    (pcase (dedukti-smie-position)
      (`context "RCOLON")
      (`top "TCOLON")
      (_ "LCOLON")))
   ((looking-back dedukti-qid-back nil t)
    (goto-char (match-beginning 0))
    (pcase (dedukti-smie-position)
      (`pragma "NAME")
      (`context "CID")
      (`opaque "OPAQUEID")
      (`top "NEWID")
      (_ "ID")))
   ((looking-back ")") nil)
   (t (buffer-substring-no-properties
       (point)
       (progn (skip-syntax-backward "w_")
              (point))))))

(defun dedukti-backward ()
  "Move backward by one token or by a sexp."
  (interactive)
  (let ((beg (point)))
    (prog1
        (or (dedukti-smie-backward-token)
            (backward-sexp))
      (when (eq beg (point))
        (backward-char)))))

(defun dedukti-smie-backward-debug ()
  "Print the current value of `dedukti-smie-backward-token'."
  (interactive)
  (let ((v (dedukti-backward)))
    (when v (princ v))))

(defcustom dedukti-indent-basic 2 "Basic indentation for dedukti-mode.")

(defun dedukti-smie-rules (kind token)
  "SMIE indentation rules for Dedukti.
For the format of KIND and TOKEN, see `smie-rules-function'."
  (pcase (cons kind token)
    (`(:elem . basic) 0)
    ;; End of line
    (`(:after . "NAME") '(column . 0))
    (`(:after . ".") '(column . 0))

    ;; Rewrite-rules
    (`(:before . "[") '(column . 0))
    (`(:after . "]") (* 2 dedukti-indent-basic))
    (`(:before . "-->") `(column . ,(* 3 dedukti-indent-basic)))
    (`(:after . "-->") `(column . ,(* 2 dedukti-indent-basic)))
    (`(,_ . ",") (smie-rule-separator kind))

    ;; Toplevel
    (`(:before . "def") '(column . 0))
    (`(:before . "thm") '(column . 0))
    (`(:before . "TCOLON") (if (smie-rule-hanging-p)
                               dedukti-indent-basic
                             nil))
    (`(:after . "TCOLON") 0)
    (`(:before . ":=") 0)
    (`(:after . ":=") dedukti-indent-basic)
    ;; Terms
    (`(:after . "->") 0)
    (`(:after . "=>") 0)
    (`(:after . "ID")
     (unless (smie-rule-prev-p "ID") dedukti-indent-basic))
    ))

;; Standard SMIE installation

(defun dedukti-smie-setup ()
  "SMIE installation for the Dedukti grammar and major mode."
  (smie-setup dedukti-smie-grammar
              'dedukti-smie-rules
              :forward-token 'dedukti-smie-forward-token
              :backward-token 'dedukti-smie-backward-token
              ))

(add-hook 'dedukti-mode-hook 'dedukti-smie-setup)

(defun dedukti-rulep ()
  "Return non-nil if point is in a rewrite-rule.
The return value is a list (STARTCTX ENDCTX ARR END) where
STARTCTX is the position of the beginning of the phrase,
         before the opening bracket,
ENDCTX is the position of the end of the context,
       after the closing bracket,
ARR is the position of the beginning of the rewrite arrow,
END is the position just after the dot closing the rewrite-rule group."
  (let (startctx endctx arr end (start (point)))
    (save-excursion
      (and
       (re-search-backward "\\[" nil t)
       (setq startctx (point))
       (re-search-forward "\\]" nil t)
       (setq endctx (point))
       (re-search-forward "-->" nil t)
       (setq arr (- (point) 3))
       (re-search-forward "\\.[^a-zA-Z0-9_]" nil t)
       (setq end (- (point) 1))
       (>= end start)
       (list startctx endctx arr end)))))

(defun dedukti-beginning-of-phrase ()
  "Go to beginning of current phrase or rewrite-rule."
  (interactive)
  (let (rulep (dedukti-rulep))
    (cond
     (rulep (goto-char (car rulep)))
     ((dedukti-smie-pragmap) (back-to-indentation))
     ((re-search-backward "\\.[^a-zA-Z0-9_]" nil t)
      (forward-char))
     (t                  ; Could append on a comment before the first line
      (back-to-indentation)))))

(defun dedukti-rule-context-at-point ()
  "Return the rewrite-rule context of the rule under point."
  (let ((rulep (dedukti-rulep))
        var type context)
    (when rulep
      (save-excursion
        (goto-char (car rulep))
        (re-search-forward "\\[")
        (while (not (looking-back "\\]"))
          (forward-comment (point-max))
          (looking-at dedukti-id)
          (setq var (match-string-no-properties 0))
          (goto-char (match-end 0))
          (forward-comment (point-max))
          (re-search-forward ":")
          (forward-comment (point-max))
          (re-search-forward "\\([^],]*\\)[],]")
          (setq type (match-string-no-properties 1))
          (add-to-list 'context (cons var type) t)))
      context)))

(defun dedukti-goto-last-LCOLON ()
  "Go to the last local colon and return the position."
  (while (and
          (> (point) (point-min))
          (not (equal (dedukti-backward) "LCOLON"))))
  (point))

(defun dedukti-context-at-point ()
  "Return the Dedukti context at point.
This is a list of cons cells (id . type).
The context is the list of local bindings."
  (let ((start (point))
        phrase-beg var type context mid)
    (save-excursion
      (dedukti-beginning-of-phrase)
      (setq phrase-beg (point)))
    (save-excursion
      (while (> (setq start (dedukti-goto-last-LCOLON)) phrase-beg)
        (forward-comment (- (point)))
        (looking-back dedukti-id nil t)
        (setq var (match-string-no-properties 0))
        (goto-char (match-end 0))
        (forward-comment (point-max))
        (re-search-forward ":")
        (forward-comment (point-max))
        (setq mid (point))
        (forward-sexp)
        (setq type (buffer-substring-no-properties mid (point)))
        (add-to-list 'context (cons var type))
        (goto-char start)
        ))
    context))

(defun dedukti-insert-context (context)
  "Insert CONTEXT as dedukti declarations.
CONTEXT is a list of cons cells of strings."
  (dolist (cons context)
    (insert (car cons) " : " (cdr cons) ".\n")))

(defun dedukti-remove-debrujn (s)
  "Return a copy of string S without DeBrujn indices."
  (replace-regexp-in-string "\\[[0-9]+\\]" "" s nil t))

(defun dedukti-remove-newline (s)
  "Return a copy of string S without newlines."
  (replace-regexp-in-string "\n" "" s nil t))

(defun dedukti-eval-term-to-string (beg end &optional reduction-command)
  "Call Dedukti to reduce the selected term and return it as a string.
BEG and END are the positions delimiting the term.
REDUCTION-COMMAND is used to control the reduction strategy,
it defaults to `dedukti-reduction-command'."
  (let* ((rulep (dedukti-rulep))
         (phrase-beg (save-excursion (dedukti-beginning-of-phrase) (point)))
         (buffer (current-buffer))
         (rule-context (when rulep (dedukti-rule-context-at-point)))
         (context (dedukti-context-at-point))
         (term (buffer-substring-no-properties beg end)))
    (with-temp-file "tmp.dk"
      (erase-buffer)
      (insert-buffer-substring buffer nil phrase-beg)
      (insert "\n")
      (dedukti-insert-context rule-context)
      (dedukti-insert-context context)
      (insert (format (or
                       reduction-command
                       dedukti-reduction-command)
                      term)))
    (goto-char beg)
    (dedukti-remove-newline
     (dedukti-remove-debrujn
      (shell-command-to-string "dkcheck -nc tmp.dk 2> /dev/null")))))

(defun dedukti-eval (beg end &optional reduction-command)
  "Call Dedukti to reduce the selected term.
The result is displayed in the echo area.
BEG and END are the positions delimiting the term.
When called interactively, they are set to the region limits.
REDUCTION-COMMAND is used to control the reduction strategy,
it defaults to `dedukti-reduction-command'."
  (interactive "r\nsreduction command: ")
  (message (dedukti-eval-term-to-string beg end reduction-command)))

(defun dedukti-hnf (beg end)
  "Call Dedukti to reduce the selected term in head normal form.
The result is displayed in the echo area.
BEG and END are the positions delimiting the term.
When called interactively, they are set to the region limits."
  (interactive "r")
  (message (dedukti-eval-term-to-string beg end "#HNF %s.")))

(defun dedukti-wnf (beg end)
  "Call Dedukti to reduce the selected term in weak normal form.
The result is displayed in the echo area.
BEG and END are the positions delimiting the term.
When called interactively, they are set to the region limits."
  (interactive "r")
  (message (dedukti-eval-term-to-string beg end "#WNF %s.")))

(defun dedukti-snf (beg end)
  "Call Dedukti to reduce the selected term in string normal form.
The result is displayed in the echo area.
BEG and END are the positions delimiting the term.
When called interactively, they are set to the region limits."
  (interactive "r")
  (message (dedukti-eval-term-to-string beg end "#SNF %s.")))

(defun dedukti-reduce (beg end reduction-command)
  "Call Dedukti to reduce the selected term and replace it in place.
BEG and END are the positions delimiting the term.
When called interactively, they are set to the region limits.
REDUCTION-COMMAND is used to control the reduction strategy,
see variable `dedukti-reduction-command' for details.
The term is displayed in parens."
  (interactive "r\nsreduction command: ")
  (let ((result (dedukti-eval-term-to-string beg end reduction-command)))
    (delete-region beg end)
    (insert "(" result ")")))

(defun dedukti-reduce-hnf (beg end)
  "Same as `dedukti-reduce' using head reduction.
BEG and END are the positions delimiting the term.
When called interactively, they are set to the region limits."
  (interactive "r")
  (dedukti-reduce beg end "#HNF %s."))

(defun dedukti-reduce-wnf (beg end)
  "Same as `dedukti-reduce' using weak head reduction.
BEG and END are the positions delimiting the term.
When called interactively, they are set to the region limits."
  (interactive "r")
  (dedukti-reduce beg end "#WNF %s."))

(defun dedukti-reduce-snf (beg end)
  "Same as `dedukti-reduce' using strong reduction.
BEG and END are the positions delimiting the term.
When called interactively, they are set to the region limits."
  (interactive "r")
  (dedukti-reduce beg end "#SNF %s."))

(defun dedukti-step-before ()
  "Call `dedukti-reduce-step' before point."
  (interactive)
  (let ((end (point)))
    (backward-sexp)
    (dedukti-reduce (point) end "#STEP %s.")))

(add-hook 'dedukti-mode-hook
          (lambda () (local-set-key (kbd "<f8>")
                                    'dedukti-step-before)))

(defun dedukti-insert-check ()
  "Insert the error message of dkcheck at point."
  (interactive)
  (let ((s (shell-command-to-string
            (format
             "%s %s %s"
             dedukti-path
             (mapconcat 'identity dedukti-check-options " ")
             (buffer-file-name)))))
    (setq s (dedukti-remove-debrujn s))
    (setq s (replace-regexp-in-string "?" "_" s nil t))
    (setq s (replace-regexp-in-string "\n" ".\n" s nil t))
    (setq s (replace-regexp-in-string "\\.\\.\n" ".\n" s nil t))
    (setq s (replace-regexp-in-string "\\(ERROR.*context:\\)\\." "(; \\1 ;)" s))
    (setq s (replace-regexp-in-string " type:" "_type :=" s nil t))
    (insert s)))


(provide 'dedukti-mode)

;;; dedukti-mode.el ends here
