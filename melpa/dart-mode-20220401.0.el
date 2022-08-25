;;; dart-mode.el --- Major mode for editing Dart files -*- lexical-binding: t; -*-

;; Author: https://github.com/bradyt/dart-mode/issues
;; URL: https://github.com/bradyt/dart-mode
;; Package-Version: 20220401.0
;; Package-Commit: ae032b9b30ebadfe1b8a48a4cf278417e506d100
;; Version: 1.0.7
;; Package-Requires: ((emacs "24.3"))
;; Keywords: languages

;; The author is Brady Trainor, but removed from keywords in attempt
;; to avoid some class of robots.

;; Honorable mention to previous author, maintainer and
;; contributors. Please see git history for significant
;; contributions. They are mostly gone from the current repo, replaced
;; or split out to dart-server repo. Most of the Github stars are from
;; previous management. The mistakes and regressions in the rewrite
;; below are my own. The previous implementation was done with cc-mode
;; framework. Let me know if you think it should be added back as an
;; option.

;;; Commentary:

;; Major mode for editing Dart files.

;; Provides basic syntax highlighting and indentation.

;;; Code:

;;; Configuration

(defvar dart-mode-map (make-sparse-keymap)
  "Keymap used in dart-mode buffers.")
(define-key dart-mode-map (kbd "<backtab>") 'dart-dedent-simple)
(define-key dart-mode-map (kbd "C-c C-i") 'indent-according-to-mode)


;;; Indentation

(defcustom dart-indent-trigger-commands
  '(indent-for-tab-command yas-expand yas/expand dart-dedent-simple)
  "Commands that might trigger a `dart-indent-line' call."
  :type '(repeat symbol)
  :group 'dart)

(defun dart-indent-line-function ()
  "`indent-line-function' for Dart mode.
When the variable `last-command' is equal to one of the symbols
inside `dart-indent-trigger-commands' it cycles possible
indentation levels from right to left."
  (if (and (memq this-command dart-indent-trigger-commands)
           (eq last-command this-command))
      (dart-indent-simple)
    (dart-indent-line-relative)))

(defun dart-indent-simple (&optional backwards)
  (interactive)
  (save-excursion
    (indent-line-to
     (max 0 (indent-next-tab-stop (current-indentation) backwards))))
  (when (< (current-column) (current-indentation))
    (back-to-indentation)))

(defun dart-dedent-simple ()
  (interactive)
  (dart-indent-simple 'backwards))

(defun dart-depth-of-line ()
  (save-excursion
    (back-to-indentation)
    (let ((depth (car (syntax-ppss))))
      (when (and (char-after)
                 (= (char-syntax (char-after)) ?\)))
        (while (and (char-after)
                    (/= (char-syntax (char-after)) ?\()
                    (/= (char-after) ?\C-j))
          (when (= (char-syntax (char-after)) ?\))
            (setq depth (1- depth)))
          (forward-char)))
      depth)))

(defun dart-indent-line-relative ()
  (let ((curr-depth (dart-depth-of-line))
        prev-line
        prev-depth
        prev-indent)
    (save-excursion
      (beginning-of-line)
      (catch 'done
        (while t
          (when (= (point) 1)
            (throw 'done t))
          (forward-line -1)
          (unless (looking-at (rx (and bol (zero-or-more space) eol)))
            (setq prev-line t)
            (setq prev-indent (current-indentation))
            (setq prev-depth (dart-depth-of-line))
            (throw 'done t)))))
    (save-excursion
      (if prev-line
          (indent-line-to (max 0 (+ prev-indent
                                    (* (- curr-depth prev-depth)
                                       tab-width))))
        (indent-line-to 0)))
    (when (< (current-column) (current-indentation))
      (back-to-indentation))))


;;; Fontification

(defvar dart--file-directives
  '("as"
    "deferred"
    "export"
    "hide"
    "import"
    "library"
    "of"
    "part"
    "show"))

(defvar dart--builtins
  ;; ECMA 408; Section: Identifier Reference
  ;; "Built-in identifiers"
  '("abstract"
    "as"
    "covariant"
    "deferred"
    "dynamic"
    "export"
    "extension"
    "external"
    "factory"
    "Function"
    "get"
    "implements"
    "import"
    "interface"
    "late"
    "library"
    "mixin"
    "operator"
    "part"
    "required"
    "set"
    "static"
    "typedef"))

(defvar dart--keywords
  ;; ECMA 408; Section: Reserved Words
  '("assert"
    "break"
    "case"
    "catch"
    "class"
    "const"
    "continue"
    "default"
    "do"
    "else"
    "enum"
    "extends"
    "final"
    "finally"
    "for"
    "if"
    "in"
    "is"
    "new"
    "rethrow"
    "return"
    "super"
    "switch"
    "this"
    "throw"
    "try"
    "var"
    "while"
    "with"))

(defvar dart--types
  '("bool"
    "double"
    "int"
    "num"
    "void"))

(defvar dart--constants
  '("false"
    "null"
    "true"))

(defvar dart--async-keywords-re (rx word-start
                                    (or "async" "await" "sync" "yield")
                                    word-end
                                    (zero-or-one ?*)))

;; https://dart.dev/guides/language/specifications/DartLangSpec-v2.10.pdf
;; 17.5 Numbers
(defvar dart--numeric-literal-re (rx-let
                                     ((numeric-literal (| number hex-number))
                                      (number (: (| (: (1+ digit) (? (: ?. (1+ digit))))
                                                    (: ?. (1+ digit)))
                                                 (? exponent)))
                                      (exponent (: (| ?e ?E)
                                                   (? (| ?+ ?-))
                                                   (1+ digit)))
                                      (hex-number (: ?0 (| ?x ?X) (1+ hex-digit))))
                                   (rx bow numeric-literal eow)))

(defvar dart--operator-declaration-re (rx "operator"
                                          (one-or-more space)
                                          (group
                                           (one-or-more (not (any ?\())))))

(eval-and-compile (defun dart--identifier (&optional case)
   `(and (or word-start symbol-start)
         (zero-or-more (any ?$ ?_))
         ,(if case
              case
            'alpha)
         (zero-or-more (or ?$ ?_ alnum)))))

(defvar dart--metadata-re (rx ?@ (eval (dart--identifier))))

(defvar dart--types-re (rx (eval (dart--identifier 'upper))))

(defvar dart--constants-re (rx (and word-start
                                    upper
                                    (>= 2 (or upper ?_))
                                    word-end)))

(defun dart--string-interpolation-id-func (limit)
  "Font-lock matcher for string interpolation identifiers.

These have the form $variableName.

Can fontify entire match with group 0, or using group 1 for sigil,
group 2 for variableName."
  (catch 'result
    (let (data end syntax)
      (while (re-search-forward (rx (group ?$)
                                    (group (zero-or-more ?_)
                                           lower
                                           (zero-or-more (or ?_ alnum))))
                                limit t)
        (setq data (match-data))
        (setq end (match-end 2))
        (setq syntax (syntax-ppss))
        ;; Check that we are in a string and not in a raw string
        (when (and (nth 3 syntax)
                   (or (= (nth 8 syntax) 1)
                       (not (eq (char-before (nth 8 syntax)) ?r))))
          (set-match-data data)
          (goto-char end)
          (throw 'result t))
        (when end
          (goto-char end)))
      (throw 'result nil))))

(defun dart--string-interpolation-exp-func (limit)
  "Font-lock matcher for string interpolation expressions.

These have the form ${expression}.

Can fontify entire match with group 0, or using group 1 for sigil,
groups 2 and 4 for curly brackets, and 3 for contents."
  (catch 'result
    (let (sigil beg open close end depth)
      ;; Loop and put point after ${
      (while (and (search-forward "${" limit t)
                  ;; Check that we are in a string and not in a raw string
                  (save-excursion
                    (and (nth 3 (syntax-ppss))
                         (not (eq (char-before (nth 8 (syntax-ppss))) ?r)))))
        ;; "a string with ${someInterpolation + aValue} inside of it."
        ;;                ^^^                         ^^
        ;;                |||                         ||
        ;;         sigil -+|+- open            close -++- end
        ;;                 +- beg
        (setq open (point))
        (setq beg (- open 1))
        (setq sigil (- open 2))
        (setq depth 1)
        ;; Move forward until limit, while depth is positive and we
        ;; are inside string.
        (while (and (> depth 0)
                    (< (point) limit)
                    (nth 3 (syntax-ppss)))
          (setq depth (+ depth (pcase (char-after)
                                 (?\{ 1)
                                 (?\} -1)
                                 (_ 0))))
          (forward-char))
        (setq end (point))
        ;; If depth is zero, we have found a closing } within string
        ;; and before limit. Set `match-data', `point', and return `t'.
        (when (= depth 0)
          (setq close (1- end))
          (set-match-data (list sigil end
                                sigil beg
                                beg open
                                open close
                                close end))
          (goto-char end)
          (throw 'result t))
        ;; If the candidate did not meet criteria, put point at end
        ;; and search again.
        (goto-char end))
      ;; When there are no more candidate "${", return nil.
      (throw 'result nil))))

(defun dart--function-declaration-func (limit)
  "Font-lock matcher function for function declarations.

Matches function declarations before LIMIT that look like,

  \"lowercaseIdentifier([...]) [[a]sync[*], {, =>]\"

For example, \"main\" in \"void main() async\" would be matched."
  (catch 'result
    (let (beg end)
      (while (re-search-forward
              (rx (group (eval (dart--identifier 'lower))) ?\() limit t)
        (setq beg (match-beginning 1))
        (setq end (match-end 1))
        (condition-case nil
            (progn
              (up-list)
              (when (looking-at (rx (one-or-more space)
                                    (or "async" "async*" "sync*" "{" "=>")))
                (set-match-data (list beg end))
                (goto-char end)
                (throw 'result t)))
          (scan-error nil))
        (goto-char end))
      (throw 'result nil))))

(defun dart--abstract-method-func (limit)
  "Font-lock matcher function for abstract methods.

Matches function declarations before LIMIT that look like,

  \"  [^ ][^=]* lowercaseIdentifier([...]);\"

For example, \"compareTo\" in \"  int compareTo(num other);\" would be
matched."
  (catch 'result
    (let (beg end)
        (while (re-search-forward
                (rx (and (not (any ?\.)) (group (eval (dart--identifier 'lower)))) ?\() limit t)
          (setq beg (match-beginning 1))
          (setq end (match-end 1))
          (condition-case nil
              (progn
                (up-list)
                (when (and (< (point) (point-max))
                           (= (char-after (point)) ?\;))
                  (goto-char beg)
                  (back-to-indentation)
                  (when (and (= (current-column) 2)
                             (not (looking-at "return"))
                             (string-match-p
                              " " (buffer-substring-no-properties
                                   (point) beg))
                             (not (string-match-p
                                   "=" (buffer-substring-no-properties
                                        (point) beg))))
                    (goto-char end)
                    (set-match-data (list beg end))
                    (throw 'result t))))
            (scan-error nil))
          (goto-char end)))
    (throw 'result nil)))

(defun dart--declared-identifier-func (limit)
  "Font-lock matcher function for declared identifiers.

Matches declared identifiers before LIMIT that look like,

  \"finalConstVarOrType lowercaseIdentifier\"

For example, \"height\" in \"const int height\" would be matched."
  (catch 'result
    (let (beg end)
      (while (re-search-forward
              (rx
               (and (group (or (or "const" "final"
                                   "bool" "double" "dynamic" "int" "num" "void"
                                   "var"
                                   "get" "set")
                               (eval (dart--identifier 'upper)))
                           (zero-or-more ?>))
                    (one-or-more (or space ?\C-j))
                    (group (eval (dart--identifier 'lower)))
                    (not (any ?\( alnum ?$ ?_))))
              limit t)
        (setq beg (match-beginning 2))
        (setq end (match-end 2))
        ;; Check for false positives
        (when (not (member (match-string 2)
                           '("bool" "double" "dynamic" "int" "num" "void"
                             "var"
                             "get" "set")))
          (goto-char end)
          (unless (nth 3 (syntax-ppss))
            (set-match-data (list beg end))
            (throw 'result t)))
        (goto-char (match-end 1)))
      (throw 'result nil))))

(defun dart--in-parenthesized-expression-or-formal-parameter-list-p ()
  "Returns `t' if `point' is in parentheses, otherwise `nil'.

In particular, parenthesized expressions or formal parameter lists."
  (save-excursion
    (catch 'result
      ;; Attempt to jump out of parentheses.
      (condition-case nil
          (backward-up-list)
        (scan-error (throw 'result nil)))
      ;; If we've only jumped out of optional or named section of
      ;; formal parameters, try to jump again.
      (when (member (char-after (point)) '(?\[ ?\{))
        (condition-case nil
            (backward-up-list)
          (scan-error (throw 'result nil))))
      (throw 'result (= (char-after (point)) ?\()))))

(defun dart--declared-identifier-anchor-func (limit)
  "Font-lock matcher for declared identifier.

Uses `dart--declared-identifier-func' to find candidates before
LIMIT, and checks that they are not in parentheses.

This matcher is an anchor to match multiple identifiers in a
single variable declaration. From ECMA-408,

  variableDeclaration:
    declaredIdentifier (', ' identifier)*
  ;

After this function sets anchor, font-lock will use the function
`dart--declared-identifier-next-func' to find subsequent
identifiers."
  (catch 'result
    (let (data)
      (while (dart--declared-identifier-func limit)
        (setq data (match-data))
        (unless (dart--in-parenthesized-expression-or-formal-parameter-list-p)
          (set-match-data data)
          (goto-char (match-end 0))
          (throw 'result t))
        (goto-char (match-end 0)))
      (throw 'result nil))))

(defun dart--declared-identifier-next-func (limit)
  "Font-lock matcher for subsequent identifiers.

For use after `dart--declared-identifier-anchor-func' sets
anchor, this function will look for subsequent identifers to
fontify as declared variables. From ECMA-408,

  variableDeclaration:
    declaredIdentifier (', ' identifier)*
  ;"
  (catch 'result
    (let ((depth (car (syntax-ppss))))
      (while t
        (cond
         ;; If point is followed by semi-colon, we are done.
         ((or (> (point) limit)
              (null (char-after (point)))
              (= (char-after (point)) ?\;)
              (< (car (syntax-ppss)) depth))
          (throw 'result nil))
         ;; If point is followed by comma, and we are still at same
         ;; depth, then attempt to match another identifier, otherwise
         ;; return nil.
         ((and (= (char-after (point)) ?\x2c) ; ?,
               (= (car (syntax-ppss)) depth))
          (if (looking-at (rx ?\x2c
                              (one-or-more space)
                              (group (eval (dart--identifier 'lower)))))
              (progn (set-match-data (list (match-beginning 1)
                                           (match-end 1)))
                     (goto-char (match-end 0))
                     (throw 'result t))
            (throw 'result nil)))
         ;; Otherwise, if we are still before `point-max' (shouldn't
         ;; this be `limit'? May be a bad attempt to deal with
         ;; multiline searches. Should research how this is done with
         ;; font-lock.), move forward.
         ((< (point) (point-max))
          (forward-char))
         ;; Otherwise, return nil.
         (t (throw 'result nil)))))))

(defun dart--anonymous-function-matcher (limit)
  "Font-lock matcher for start of anonymous functions.

Looks for opening parenthesis, tries to jump to opening
parenthesis, ensure it is not preceded by for, while, etc. Then
tries to jump to closing parenthesis and check if followed by \"
{\" or \" =>\".

Used with `dart--untyped-parameter-anchored-matcher' to fontify
untyped parameters. For example, in

  (untypedParameter) => untypedParameter.length"
  (catch 'result
    (let (beg end)
      (while (search-forward "(" limit t)
        (setq beg (match-beginning 0))
        (setq end (match-end 0))
        (unless (looking-back (rx (or (and (or "do" "for" "if" "switch" "while")
                                           space)
                                      "super")
                                  ?\()
                              (point-at-bol))
          (condition-case nil
              (up-list)
            (scan-error (throw 'result nil)))
          (when (looking-at (rx space (or ?\{ "=>")))
            (set-match-data (list beg end))
            (goto-char end)
            (throw 'result t))
          (goto-char end)))
      (throw 'result nil))))

(defun dart--untyped-parameter-anchored-matcher (limit)
  "Font-lock anchored-matcher for untyped parameters.

Searches forward for for lowercase idenitifer and ensures depth
is still same.

Used with `dart--anonymous-function-matcher' to fontify
untyped parameters. For example, in

  (untypedParameter) => untypedParameter.length"
  (let (beg end)
    (catch 'result
      (if (equal (char-after) ?\))
          (throw 'result nil))
      (let ((depth (car (syntax-ppss))))
        (while (re-search-forward
                (rx (and (group (or (one-or-more (char ?_))
                                    (eval (dart--identifier 'lower))))
                         (or ?, ?\)))))
          (setq beg (match-beginning 1))
          (setq end (match-end 1))
          (goto-char end)
          (if (or (> (point) limit)
                  (< (car (syntax-ppss)) depth))
              (throw 'result nil)
            (set-match-data (list beg end))
            (throw 'result t))))
      (throw 'result nil))))

(defun dart--get-point-at-end-of-list ()
  (let (pt)
    (save-excursion
      (up-list)
      (setq pt (point)))
    pt))

(defvar dart-font-lock-defaults
  '((dart-font-lock-keywords-1 dart-font-lock-keywords-1
                               dart-font-lock-keywords-2
                               dart-font-lock-keywords-3)))

(defvar dart-font-lock-keywords-1
  `((,(regexp-opt dart--file-directives 'words) . font-lock-builtin-face)
    (dart--function-declaration-func            . font-lock-function-name-face)
    (,dart--operator-declaration-re             . (1 font-lock-function-name-face))
    (dart--abstract-method-func                 . font-lock-function-name-face)))

(defvar dart-font-lock-keywords-2
  `(,dart--async-keywords-re
    ,(regexp-opt dart--keywords 'words)
    (,(regexp-opt dart--builtins 'words)  . font-lock-builtin-face)
    (,(regexp-opt dart--constants 'words) . font-lock-constant-face)
    (,dart--numeric-literal-re            . font-lock-constant-face)
    (,dart--metadata-re                   . font-lock-constant-face)
    (,dart--constants-re                  . font-lock-constant-face)
    (,(regexp-opt dart--types 'words)     . font-lock-type-face)
    (,dart--types-re                      . font-lock-type-face)
    (dart--function-declaration-func      . font-lock-function-name-face)
    (,dart--operator-declaration-re       . (1 font-lock-function-name-face))
    (dart--abstract-method-func           . font-lock-function-name-face)))

(defvar dart-font-lock-keywords-3
  (append
   dart-font-lock-keywords-2
   `((dart--declared-identifier-func      . font-lock-variable-name-face)
     (dart--declared-identifier-anchor-func
      . (dart--declared-identifier-next-func
         nil
         nil
         (0 font-lock-variable-name-face)))
     (dart--anonymous-function-matcher
      . (dart--untyped-parameter-anchored-matcher
         (dart--get-point-at-end-of-list)
         nil
         (0 font-lock-variable-name-face)))
     (dart--string-interpolation-id-func  (0 font-lock-variable-name-face t))
     (dart--string-interpolation-exp-func (0 font-lock-variable-name-face t)))))

(defun dart-syntax-propertize-function (beg end)
  "Sets syntax-table text properties for raw and/or multiline strings.

We use fences uniformly for consistency.

In raw strings, we modify backslash characters to have punctuation
syntax rather than escape syntax.

String interpolation is not handled correctly yet, but the fixes to
quote characters in multiline strings, and escape characters in raw
strings, ensures that code outside of strings is not highlighted as
strings."
  (goto-char beg)
  ;; We rely on syntax-propertize-extend-region-functions that `beg`
  ;; will be at beginning of line, but we ensure here that we are not
  ;; in a string
  (while (nth 3 (syntax-ppss))
    (goto-char (nth 8 (syntax-ppss)))
    (beginning-of-line))
  ;; Search for string opening
  (while (re-search-forward (rx (group (optional ?r))
                                (group (or (repeat 3 ?\")
                                           (repeat 3 ?\')
                                           ?\"
                                           ?\')))
                            end t)
    (let ((bos (match-beginning 2))
          (rawp (equal (match-string-no-properties 1) "r"))
          (string-delimiter (match-string-no-properties 2)))
      ;; Set string fence syntax at beginning of string
      (put-text-property bos (1+ bos) 'syntax-table (string-to-syntax "|") nil)
      ;; Look for the end of string delimiter, depending on rawp and
      ;; string-delimiter
      ;; Unless rawp, ensure an even number of backslashes
      (when (or (looking-at (concat (unless rawp (rx (zero-or-more ?\\ ?\\)))
                                    string-delimiter))
                (re-search-forward (concat (unless rawp (rx (not (any ?\\)) (zero-or-more ?\\ ?\\)))
                                           string-delimiter)
                                   end t))
        (let ((eos (match-end 0)))
          ;; Set end of string fence delimiter
          (put-text-property (1- eos) eos 'syntax-table (string-to-syntax "|") nil)
          ;; For all strings, remove fence property between fences
          ;; For raw strings, set all backslashes to punctuation syntax
          (dolist (pt (number-sequence (1+ bos) (- eos 2)))
            (when (equal (get-text-property pt 'syntax-table) (string-to-syntax "|"))
              (remove-text-properties pt (1+ pt) 'syntax-table))
            (when (and rawp (equal (char-after pt) ?\\))
              (put-text-property pt (1+ pt) 'syntax-table (string-to-syntax ".") nil)))
          (goto-char eos))))))


;;; Initialization

;;;###autoload (add-to-list 'auto-mode-alist '("\\.dart\\'" . dart-mode))

;;;###autoload
(define-derived-mode dart-mode prog-mode "Dart"
  "Major mode for editing Dart files.

The hook `dart-mode-hook' is run with no args at mode
initialization.

Key bindings:
\\{dart-mode-map}"
  (modify-syntax-entry ?/  "_ 124b")
  (modify-syntax-entry ?*  ". 23")
  (modify-syntax-entry ?\n "> b")
  (modify-syntax-entry ?\' "\"")
  (modify-syntax-entry ?\> ".")
  (modify-syntax-entry ?\< ".")
  (setq-local electric-indent-chars '(?\n ?\) ?\] ?\}))
  (setq electric-indent-inhibit t)
  (setq-local comment-start "//")
  (setq-local comment-end "")
  (setq fill-column 80)
  (setq font-lock-defaults dart-font-lock-defaults)
  (setq-local indent-line-function 'dart-indent-line-function)
  (setq indent-tabs-mode nil)
  (setq tab-width 2)
  (setq-local syntax-propertize-function 'dart-syntax-propertize-function))

(provide 'dart-mode)

;;; dart-mode.el ends here
