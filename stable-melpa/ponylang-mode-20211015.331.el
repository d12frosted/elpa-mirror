;;; ponylang-mode.el --- A major mode for the Pony programming language
;;
;; Authors: Sean T Allen <sean@monkeysnatchbanana.com>
;; Version: 0.6.0
;; Package-Version: 20211015.331
;; Package-Commit: 1abf04bc8f4f09a6add4b587c7cf5ca23735e7c0
;; URL: https://github.com/ponylang/ponylang-mode
;; Keywords: languages programming
;; Package-Requires: ((emacs "25.1") (dash "2.17.0") (hydra "0.15.0") (hl-todo "3.1.2") (yafolding "0.4.1") (yasnippet "0.14.0") (company-ctags "0.0.4") (rainbow-delimiters "2.1.4") (fill-column-indicator "1.90"))
;;
;; This file is not part of GNU Emacs.
;;
;; Copyright (c) 2015 Austin Bingham
;; Copyright (c) 2016 Sean T. Allen
;; Copyright (c) 2020 Damon Kwok
;; Copyright (c) 2021 The Pony Developers
;;
;;; Commentary:
;;
;; Description:
;;
;; This is a major mode for the Pony programming language
;;
;; For more details, see the project page at
;; https://github.com/ponylang/ponylang-mode
;;
;; Installation:
;;
;; The simple way is to use package.el:
;;
;;   M-x package-install ponylang-mode
;;
;; Or, copy ponylang-mode.el to some location in your Emacs load
;; path.  Then add "(require 'ponylang-mode)" to your Emacs initialization
;; (.emacs, init.el, or something).
;;
;; Example config:
;;
;;   (require 'ponylang-mode)
;;
;;; License:
;;
;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Code:

(require 'cl-lib)
(require 'dash)
(require 'xref)
(require 'hydra)
(require 'imenu)
(require 'hl-todo)
(require 'easymenu)
(require 'yafolding)
(require 'yasnippet)
(require 'whitespace)
(require 'rainbow-delimiters)
(require 'fill-column-indicator)

(defvar ponylang-mode-hook nil)

;; TODO: I don't like having to mention yas-* here, but that's how
;; e.g. python does it. It seems like there should be more general way
;; to detect "repeated tab presses".
(defcustom ponylang-indent-trigger-commands
                                        ;
  '(indent-for-tab-command yas-expand yas/expand)
  "Commands that might trigger a `ponylang-indent-line' call."
  :type '(repeat symbol)
  :group 'ponylang)

(defcustom ponylang-share-url-format "https://playground.ponylang.io/?code=%s"
  "Format string to use when submitting code to the share."
  :type 'string
  :group 'ponylang)

(defcustom ponylang-skip-ctags nil
  "Switch to disable TAGS file generation on file save."
  :type 'boolean
  :group 'ponylang)

(defcustom ponylang-shortener-url-format
  "https://is.gd/create.php?format=simple&url=%s"
  "Format string to use for creating the shortened link of a share submission."
  :type 'string
  :group 'ponylang)

(defconst ponylang-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; fontify " using ponylang-keywords

    ;; / is punctuation, but // is a comment starter
    (modify-syntax-entry ?/ ". 124" table)

    ;; /* */ comments, which can be nested
    (modify-syntax-entry ?* ". 23bn" table)

    ;; \n is a comment ender
    (modify-syntax-entry ?\n ">" table)

    ;; string
    (modify-syntax-entry ?\" "\"" table)

    ;; Don't treat underscores as whitespace
    (modify-syntax-entry ?_ "w" table) table))

(defun ponylang-mode-syntactic-face-function (STATE)
  "Function to determine which face to use when fontifying syntactically.
The function is called with a single parameter (the STATE as returned by
`parse-partial-sexp' at the beginning of the region to highlight) and
should return a face.  This is normally set via `font-lock-defaults'."
  (if (nth 3 STATE)                     ;
    (save-excursion                     ;
      (goto-char (nth 8 STATE))
      (beginning-of-line)
      (while (and (not (bobp))
               (looking-at "^$?[ \t]*?$?\"?*$"))
        (forward-line -1))
      (beginning-of-line)
      (if (or (and (bobp)
                (looking-at "^$?[ \t]*?\"*$"))
            (looking-at ".*=>$?[ \t]*?$")
            (looking-at
              "^[ \t]*\\(use\\|class\\|actor\\|primitive\\|struct\\|trait\\|interface\\|type\\|fun\\|be\\|new\\)")) ;
        'font-lock-doc-face             ;
        'font-lock-string-face))        ;
    'font-lock-comment-face))

(defun ponylang-comment-or-uncomment-region-or-line ()
  "Comments or uncomments the region or the current line if there's no active region."
  (interactive)
  (let (beg end)
    (if (region-active-p)
      (setq beg (region-beginning) end (region-end))
      (setq beg (line-beginning-position) end (line-end-position)))
    (comment-or-uncomment-region beg end)
    (next-line)))

(defvar ponylang-mode-map
  (let ((map (make-keymap)))
    (define-key map "\C-j" #'newline-and-indent)
    (define-key map (kbd "<C-return>") #'yafolding-toggle-element)
    (define-key map "\M-;" #'ponylang-comment-or-uncomment-region-or-line)
    (define-key map (kbd "C-c C-f") #'ponylang-format-buffer) ;
    map)
  "Keymap for Pony major mode.")

(defvar ponylang--indent-cycle-direction 'left)

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.pony\\'" . ponylang-mode))

(defconst ponylang-capabilities '("box" "iso" "ref" "tag" "trn" "val")
  "Pony capability markers.")

(defconst ponylang-keywords
  '("__loc" "actor" "addressof" "and" "as"         ;
     "be" "break"                                  ;
     "class" "compile_error" "compile_intrinsic"   ;
     "consume" "continue"                          ;
     "digestof" "do"                               ;
     "else" "elseif" "embed" "end" "error"         ;
     "for" "fun" "if"                              ;
     "ifdef" "iftype" "in" "interface" "is" "isnt" ;
     "let"                                         ;
     "match"                                       ;
     "new" "not"                                   ;
     "object" "or"                                 ;
     "primitive"                                   ;
     "recover" "repeat" "return"                   ;
     "struct"                                      ;
     "then" "this" "trait" "try" "type"            ;
     "until"                                       ;
     "use"                                         ;
     "var"                                         ;
     "where" "while" "with"                        ;
     "xor")
  "Pony language keywords.")

(defconst ponylang-indent-start-keywords
  '("actor"                             ;
     "be"                               ;
     "class"                            ;
     "else" "elseif"                    ;
     "for" "fun"                        ;
     "if" "ifdef" "interface"           ;
     "new"                              ;
     "primitive"                        ;
     "recover" "ref" "repeat"           ;
     "struct"                           ;
     "tag" "then" "trait" "try"         ;
     "until"                            ;
     "while" "with")
  "Pony keywords which indicate a new indentation level.")

(defconst ponylang-declaration-keywords
  '("type" "class" "actor" "primitive" "struct" "trait" "interface" ;
     "fun" "be"                                                     ;
     "let" "var" "embed")
  "Pony declaration keywords.")

(defconst ponylang-careful-keywords
  '("use"                                     ;
     "addressof"                              ;
     "continue" "break" "return"              ;
     "new" "object" "consume" "recover" "try" ;
     "_init" "_final"                         ;
     "is" "isnt" "as"                         ;
     "error" "compile_error" "compile_intrinsic")
  "Pony language careful keywords.")

(defconst ponylang-common-functions '("apply" "update" "string" "size" "hash")
  "Pony language common functions.")

(defconst ponylang-operator-functions
  '("and" "op_and" "or" "op_or" "xor" "op_xor"       ;
     ;;
     "add" "sub""mul" "div""rem" "mod"               ;
     "shl" "shr"                                     ;
     "eq" "ne" "lt" "le" "ge" "gt"                   ;
     ;;
     "gt_unsafe" "lt_unsafe" "le_unsafe" "ge_unsafe" ;
     "add_unsafe" "sub_unsafe"                       ;
     "mul_unsafe" "div_unsafe"                       ;
     "rem_unsafe" "mod_unsafe"                       ;
     "shl_unsafe" "shr_unsafe"                       ;
     "eq_unsafe" "ne_unsafe"                         ;
     ;;
     "add_partial" "sub_partial"        ;
     "mul_partial" "div_partial"        ;
     "rem_partial" "mod_partial")
  "Pony language operators functions.")

(defconst ponylang-constants '("false" "true" "this" "None")
  "Common constants.")

;; create the regex string for each class of keywords
(defconst ponylang-keywords-regexp
  (regexp-opt (append ponylang-keywords ponylang-capabilities) 'words)
  "Regular expression for matching keywords.")

(defconst ponylang-constant-regexp ;;
  (regexp-opt ponylang-constants 'words)
  "Regular expression for matching common constants.")

(defconst ponylang-capabilities-regexp ;;
  (regexp-opt ponylang-capabilities 'words)
  "Regular expression for matching capabilities.")

(defconst ponylang-careful-keywords-regexp
  (regexp-opt ponylang-careful-keywords 'words)
  "Regular expression for matching careful keywords.")

(defconst ponylang-declaration-keywords-regexp
  (regexp-opt ponylang-declaration-keywords 'words)
  "Regular expression for matching declaration keywords.")

(defconst ponylang-operator-functions-regexp
  (regexp-opt ponylang-operator-functions 'words)
  "Regular expression for matching operator functions.")

(defconst ponylang-common-functions-regexp
  (regexp-opt ponylang-common-functions 'words)
  "Regular expression for matching common functions.")

;; (setq ponylang-event-regexp (regexp-opt ponylang-events 'words))
;; (setq ponylang-functions-regexp (regexp-opt ponylang-functions 'words))

(defconst ponylang-font-lock-keywords
  `(
     ;; careful
     (,ponylang-careful-keywords-regexp . font-lock-warning-face)

     ;; declaration
     (,ponylang-declaration-keywords-regexp . font-lock-preprocessor-face)

     ;; delimiter: modifier
     ("\\(->\\|=>\\|\\.>\\|:>\\||\\|&\\)" 1 'font-lock-keyword-face)

     ;; delimiter: . , ; separate
     ("\\($?[.,;]+\\)" 1 'font-lock-comment-delimiter-face)

     ;; delimiter: operator symbols
     ;; ("\\($?[+-/*//%~^!=<>]+\\)$?,?" 1 'font-lock-negation-char-face)
     ("\\($?[+-/*//%~=<>]+\\)$?,?" 1 'font-lock-negation-char-face)
     ("\\($?[?^!]+\\)" 1 'font-lock-warning-face)

     ;; delimiter: = : separate
     ("[^+-/*//%~^!=<>]\\([=:]\\)[^+-/*//%~^!=<>]" 1
       'font-lock-comment-delimiter-face)

     ;; delimiter: brackets
     ("\\(\\[\\|\\]\\|[()]\\)" 1 'font-lock-comment-delimiter-face)

     ;; delimiter: lambda
     ("\\($?[{}]+\\)" 1 'font-lock-function-name-face)

     ;; common methods
     (,ponylang-common-functions-regexp . font-lock-builtin-face)

     ;; operator methods
     (,ponylang-operator-functions-regexp . font-lock-builtin-face)

     ;; capabilities
     (,ponylang-capabilities-regexp . font-lock-builtin-face)

     ;; capability constraints
     ("#\\(?:read\\|send\\|share\\|any\\|alias\\)" . 'font-lock-builtin-face)

     ;; variable definitions
     ("\\(?:object\\|let\\|var\\|embed\\|for\\)\\s +\\([^ \t\r\n,:;=)]+\\)" 1
       'font-lock-variable-name-face)

     ;; method definitions
     ("\\(?:new\\|fun\\|be\\)\s+\\(?:\\(?:box\\|iso\\|ref\\|tag\\|trn\\|val\\)\s+\\)?\\($?[a-z_][A-Za-z0-9_]*\\)"
       1 'font-lock-function-name-face)

     ;; type definitions
     ("\\(?:class\\|actor\\|primitive\\|struct\\|trait\\|interface\\|type\\)\s+\\($?_?[A-Z][A-Za-z0-9_]*\\)"
       1 'font-lock-type-face)

     ;; type references: first filter
     ("[:,|&[]$?[ \t]*\\($?_?[A-Z][A-Za-z0-9_]*\\)" 1 'font-lock-type-face)

     ;; constants references
     (,ponylang-constant-regexp . font-lock-constant-face)

     ;; type references: second filter
     ("\\(\s\\|\\.\\|->\\|[\[]\\|[\(]\\|=\\)\\($?_?[A-Z][A-Za-z0-9_]*\\)" 2
       'font-lock-type-face)

     ;; ffi
     ("@[A-Za-z_]*[A-Z-a-z0-9_]*" . 'font-lock-builtin-face)

     ;; method references
     ("\\([a-z_]$?[a-z0-9_]?+\\)$?[ \t]?(+" 1 'font-lock-function-name-face)

     ;; parameter
     ("\\(?:(\\|,\\)\\([a-z_][a-z0-9_']*\\)\\([^ \t\r\n,:)]*\\)" 1
       'font-lock-variable-name-face)
     ("\\(?:(\\|,\\)[ \t]+\\([a-z_][a-z0-9_']*\\)\\([^ \t\r\n,:)]*\\)" 1
       'font-lock-variable-name-face)

     ;; tuple references
     ("[.]$?[ \t]?\\($?_[1-9]$?[0-9]?*\\)" 1 'font-lock-variable-name-face)

     ;;(,ponylang-event-regexp . font-lock-builtin-face)
     ;;(,ponylang-functions-regexp . font-lock-function-name-face)

     ;; keywords
     (,ponylang-keywords-regexp . font-lock-keyword-face)

     ;; character literals
     ("\\('[\\].'\\)" 1 'font-lock-constant-face)

     ;; numeric literals
     ("[ \t/+-/*//=><([,;]\\([0-9]+[0-9a-zA-Z_]*\\)+" 1
       'font-lock-constant-face)

     ;; variable references
     ("\\([a-z_]+[a-z0-9_']*\\)+" 1 'font-lock-variable-name-face)

     ;; note: order above matters. “ponylang-keywords-regexp” goes last because
     ;; otherwise the keyword “state” in the function “state_entry”
     ;; would be highlighted.
     )
  "An alist mapping regexes to font-lock faces.")

;; Indentation
(defun ponylang--looking-at-indent-start ()
  "Determines if the current position is 'looking at' a keyword that start new indentation."
  (-any? (lambda (k)
           (looking-at (concat  "^[ \t]*" k "\\($\\|[ \t]\\)")))
    ponylang-indent-start-keywords))

(defun ponylang--looking-at-indent-declare ()
  "Determines if the current position is 'looking at' a keyword that declaration new indentation."
  (-any? (lambda (k)
           (looking-at (concat  ".*" k ".*[:,|&][ \t]*$")))
    ponylang-declaration-keywords))

(defun ponylang-syntactic-indent-line ()
  "Indent current line as pony code based on language syntax and the current context."
  (beginning-of-line)
  (let ((cur-indent (current-indentation)))
    (cond ((bobp)
            (setq cur-indent 0))
      ((looking-at "^[ \t]*\\(//\\|/\\*\\)")
        (setq cur-indent (current-indentation)))
      ((looking-at
         "^[ \t]*\\(use\\|class\\|actor\\|primitive\\|struct\\|trait\\|interface\\|type\\)[
\t]*.*$")
        (setq cur-indent 0))
      ((looking-at "^[ \t]*\\(fun\\|be\\|new\\|=>\\)[ \t]*.*$")
        (setq cur-indent tab-width))
      ((looking-at "^.*\\(\"\\)[ \t]*$")
        (setq cur-indent (current-indentation)))
      ((looking-at
         "^[ \t]*\\(|\\|end\\|else\\|elseif\\|do\\|then\\|until\\)[ \t]*.*$")
        (progn (save-excursion ;;
                 (forward-line -1)
                 (if (looking-at ".*[ \t]*\\(|\\|match\\).*$")
                   (setq cur-indent (current-indentation))
                   (setq cur-indent (max 0 (- (current-indentation)
                                             tab-width)))))))
      (t                                ;
        (save-excursion                 ;
          (let ((keep-looking t))
            (while keep-looking
              (setq keep-looking nil)
              (forward-line -1)
              (cond
                ;; if the previous line ends in `end', keep indent
                ((looking-at ".*\\(end\\)[ \t]*$")
                  (setq cur-indent (current-indentation)))

                ;; if the previous line ends in = or =>, indent one level
                ((looking-at ".*\\(=>\\|=\\|recover\\)[ \t]*$")
                  (setq cur-indent (+ (current-indentation) tab-width)))
                ((ponylang--looking-at-indent-declare)
                  (setq cur-indent (+ (current-indentation) tab-width)))
                ((ponylang--looking-at-indent-start)
                  (setq cur-indent (+ (current-indentation) tab-width)))

                ;; if the previous line is all empty space, keep the current indentation
                ((not (looking-at "^[ \t]*$"))
                  (setq cur-indent (current-indentation)))

                ;; if it's the beginning of the buffer, indent to zero
                ((bobp)
                  (setq cur-indent 0))
                (t
                  (setq keep-looking t))))))))
    (indent-line-to cur-indent)))

(defun ponylang-cycle-indentation ()
  "Ponylang cycle indentation."
  (if (eq (current-indentation) 0)
    (setq ponylang--indent-cycle-direction 'right))
  (if (eq ponylang--indent-cycle-direction 'left)
    (indent-line-to (max 0 (- (current-indentation) tab-width)))
    (indent-line-to (+ (current-indentation) tab-width))))

(defun ponylang-indent-line ()
  "Indent the current line based either on syntax or repeated use of the TAB key."
  (interactive)
  (let ((repeated-indent (memq last-command ponylang-indent-trigger-commands)))
    (if repeated-indent (ponylang-cycle-indentation)
      (progn
        (setq ponylang--indent-cycle-direction 'left)
        (ponylang-syntactic-indent-line)))))

(defalias 'ponylang-parent-mode
                                        ;
  (if (fboundp 'prog-mode) 'prog-mode 'fundamental-mode))

(defun ponylang-stringify-triple-quote ()
  "Put `syntax-table' property on triple-quoted strings."
  (let* ((string-end-pos (point))
          (string-start-pos (- string-end-pos 3))
          (ppss (prog2 (backward-char 3)
                  (syntax-ppss)
                  (forward-char 3))))
    (unless (nth 4 (syntax-ppss)) ;; not inside comment
      (if (nth 8 (syntax-ppss))
        ;; We're in a string, so this must be the closing triple-quote.
        ;; Put | on the last " character.
        (put-text-property (1- string-end-pos) string-end-pos ;
          'syntax-table (string-to-syntax "|"))
        ;; We're not in a string, so this is the opening triple-quote.
        ;; Put | on the first " character.
        (put-text-property string-start-pos (1+ string-start-pos) ;
          'syntax-table (string-to-syntax "|"))))))

(defconst ponylang-syntax-propertize-function
  (syntax-propertize-rules ("\"\"\""    ; A triple quoted string
                             (0 (ignore (ponylang-stringify-triple-quote))))))

(defun ponylang-project-root-p (PATH)
  "Return t if directory `PATH' is the root of the Pony project."
  (let* ((files '("corral.json" "lock.json" "Makefile" ;
                   "Dockerfile" ".editorconfig" ".gitignore"))
          (foundp nil))
    (while (and files
             (not foundp))
      (let* ((filename (car files))
              (filepath (concat (file-name-as-directory PATH) filename)))
        (setq files (cdr files))
        (setq foundp (file-exists-p filepath)))) ;
    foundp))

(defun ponylang-project-root
  (&optional
    PATH)
  "Return the root of the pony project.
Optional argument PATH ."
  (let* ((bufdir (if buffer-file-name   ;
                   (file-name-directory buffer-file-name) default-directory))
          (curdir (if PATH (file-name-as-directory PATH) bufdir))
          (parent (file-name-directory (directory-file-name curdir))))
    (if (or (not parent)
          (string= parent curdir)
          (string= parent "/")
          (ponylang-project-root-p curdir)) ;
      curdir                                ;
      (ponylang-project-root parent))))

(defun ponylang-project-name ()
  "Return pony project name."
  (file-name-base (directory-file-name (ponylang-project-root))))

(defun ponylang-project-file-exists-p (FILENAME)
  "Return t if file `FILENAME' exists."
  (file-exists-p (concat (ponylang-project-root) FILENAME)))

(defun ponylang-run-command (COMMAND &optional PATH)
  "Return `COMMAND' in the root of the pony project.
Optional argument PATH ."
  (setq default-directory (if PATH PATH (ponylang-project-root PATH)))
  (compile COMMAND))

(defun ponylang-buffer-dirname ()
  "Return current buffer directory file name."
  (directory-file-name (if buffer-file-name (file-name-directory
                                              buffer-file-name)
                         default-directory)))

(defun ponylang-project-build ()
  "Build project with ponyc."
  (interactive)
  (if (ponylang-project-file-exists-p "Makefile")
    (ponylang-run-command "make")
    (if (ponylang-project-file-exists-p "corral.json")
      (ponylang-run-command "corral run -- ponyc --debug")
      (ponylang-run-command "ponyc"))))

(defun ponylang-project-run ()
  "Run project."
  (interactive)
  (if (ponylang-project-file-exists-p "Makefile")
    (ponylang-run-command "make run")
    (let* ((bin1 (concat (ponylang-project-root) "bin/"
                   (ponylang-project-name)))
            (bin2 (concat (ponylang-project-root) "/" (ponylang-project-name)))
            (bin3 (concat (ponylang-buffer-dirname) "/"
                    (ponylang-project-name))))
      (if (file-exists-p bin1)
        (ponylang-run-command bin1)
        (if (file-exists-p bin2)
          (ponylang-run-command bin2)
          (if (file-exists-p bin3)
            (ponylang-run-command bin3)))))))

(defun ponylang-project-clean ()
  "Clean project."
  (interactive)
  (if (ponylang-project-file-exists-p "Makefile")
    (ponylang-run-command "make clean")
    (let* ((bin1 (concat (ponylang-project-root) "bin/"
                   (ponylang-project-name)))
            (bin2 (concat (ponylang-project-root) "/" (ponylang-project-name)))
            (bin3 (concat (ponylang-buffer-dirname) "/"
                    (ponylang-project-name))))
      (if (file-exists-p bin1)
        (delete-file bin1))
      (if (file-exists-p bin2)
        (delete-file bin2))
      (if (file-exists-p bin3)
        (delete-file bin3)))))

(defun ponylang-corral-init ()
  "Run corral `init' command."
  (interactive)
  (unless (ponylang-project-file-exists-p "corral.json")
    (ponylang-run-command "corral init")))

(defun ponylang-corral-fetch ()
  "Run corral `fetch' command."
  (interactive)
  (if (ponylang-project-file-exists-p "corral.json")
    (ponylang-run-command "corral fetch")))

(defun ponylang-corral-update ()
  "Run corral `update' command."
  (interactive)
  (if (ponylang-project-file-exists-p "corral.json")
    (ponylang-run-command "corral update")))

(defun ponylang-corral-open ()
  "Open `corral.json' file."
  (interactive)
  (if (ponylang-project-file-exists-p "corral.json")
    (find-file (concat (ponylang-project-root) "corral.json"))))

(defun ponylang-share-region (begin end)
  "Create a shareable URL for the region from BEGIN to END on the Pony `playground'."
  (interactive "r")
  (let* ((data
           (buffer-substring
             begin
             end))
          (escaped-data (url-hexify-string data))
          (escaped-share-url (url-hexify-string (format
                                                  ponylang-share-url-format
                                                  escaped-data))))
    (if (> (length escaped-share-url) 50000)
      (error
        "Encoded share data exceeds 50000 character limit (length %s)"
        (length escaped-share-url))
      (let ((shortener-url (format ponylang-shortener-url-format
                             escaped-share-url))
             (url-request-method "POST"))
        (url-retrieve shortener-url ;;
          (lambda (state)
            ;; filter out the headers etc. included at the
            ;; start of the buffer: the relevant text
            ;; (shortened url or error message) is exactly
            ;; the last line.
            (goto-char (point-max))
            (let ((last-line (thing-at-point 'line t))
                   (err (plist-get state
                          :error)))
              (kill-buffer)
              (if err
                (error
                  "Failed to shorten share url: %s"
                  last-line)
                (progn (kill-new last-line)
                  (message "%s is append to system clipboard."
                    last-line))))))))))

(defun ponylang-region-length ()
  "Return selection region length."
  (if (use-region-p)
    (let ((selection
            (buffer-substring-no-properties
              (region-beginning)
              (region-end))))
      (length selection)) 0))

(defun ponylang-share-region-auto ()
  "Create a shareable URL for the region on the Pony `playground'."
  (if (> (ponylang-region-length) 0)
    (ponylang-share-region (region-beginning)
      (region-end))))

(defun ponylang-share-buffer ()
  "Create a shareable URL for the contents of the buffer on the Pony `playground'."
  (interactive)
  (ponylang-share-region (point-min)
    (point-max)))

(easy-menu-define ponylang-mode-menu ponylang-mode-map ;
  "Menu for Ponylang mode."                            ;
  '("Ponylang"                                         ;
     ["Build" ponylang-project-build t]
     ["Run" ponylang-project-run t]     ;
     ["Clean" ponylang-project-clean t]
     ("Corral"                          ;
       ["Init" ponylang-corral-init t]
       ["Open" ponylang-corral-open t]
       ["Fetch" ponylang-corral-fetch t]
       ["Update" ponylang-corral-update t])
     ("Playground"                      ;
       ["Share Buffer"          ponylang-share-buffer t]
       ["Share Region"          ponylang-share-region-auto (use-region-p)])
     "---"                              ;
     ("Community"                       ;
       ["News"                          ;
         (ponylang-run-command "xdg-open https://www.ponylang.io/blog") t]
       ["Beginner Help"                 ;
         (ponylang-run-command
           "xdg-open https://ponylang.zulipchat.com/#narrow/stream/189985-beginner-help") t]
       ["Open an issue"                 ;
         (ponylang-run-command
           "xdg-open https://github.com/ponylang/ponyc/issues") t]
       ["Zulip chat"                    ;
         (ponylang-run-command "xdg-open https://ponylang.zulipchat.com") t]
       ["Planet-pony"                   ;
         (ponylang-run-command "xdg-open
https://www.ponylang.io/community/planet-pony") t]
       ["Papers"                        ;
         (ponylang-run-command
           "xdg-open https://www.ponylang.io/community/#papers")]
       ["Tutorial"                      ;
         (ponylang-run-command "xdg-open https://tutorial.ponylang.io/") t]
       ["Videos"                        ;
         (ponylang-run-command
           "xdg-open https://vimeo.com/search/sort:latest?q=pony-vug") t]
       ["Contribute"                    ;
         (ponylang-run-command
           "xdg-open https://github.com/ponylang/contributors") t]
       ["Sponsors"                      ;
         (ponylang-run-command "xdg-open https://www.ponylang.io/sponsors")
         t])))

(defconst ponylang-banner-default
  "
 _ __   ___  _ __  _   _
| '_ \\ / _ \\| '_ \\| | | |
| |_) | (_) | | | | |_| |
| .__/ \\___/|_| |_|\\__, |
| |                 __/ |
|_|                |___/
"
  "Ponylang word logo.")

(defconst ponylang-banner-horse
  "
                               ,(\\_/)
                            ((((^`\\
                          ((((  (6 \\
                         ((((( ,    \\
     ,,,_              (((((  /\"._  ,`,
    ((((\\\\ ,...       ((((   /    `-.-'
    )))  ;'    `\"'\"'\"((((    (
   (((  /           (((       \\
    )) |                      |
   ((  |        .       '     |
   ))  \\     _ '      `\\   ,.'Y
   (   |   y;---,-\"\"'\"-.\\   \\/
   )   / ./  ) /         `\\  \\
      |./   ( (           / /'
      ||     \\\\          //'|
      ||      \\\\       _// ||
      ||       ))     |_/  ||
      \\_\\     |_/          ||
      `'\"                  \\_\\
                           `'\""
  "Ponylang horse logo.")

(defconst ponylang-banner-knight
  "
                                 .
                                 |\\
                                 ||
                                 ||
                                 ||
                     ,__,,       ||
                     =/= /       ||
         ,   ,       \\j /     o-</>>o
        _)\\_/)      __//___,____/_\\
       (/ (6\\>   __// /_ /__\\_/_/
      /`  _ /\\><'_\\/\\/__/
     / ,_//\\  \\>    _)_/
     \\_('  |  )>   x)_::\\       ______,
           /  \\>__//  o |----.,/(  )\\\\))
           \\'  \\|  )___/ \\     \\/  \\\\\\\\\\
           /    +-/o/----+      |
          / '     \\_\\,  ___     /
         /  \\_|  _/\\_|-\" /,    /
        / _/ / _/   )\\|  |   _/
       ( (  / /    /_/ \\_ \\_(__
        \\`./ /           / /  /
         \\/ /           / / _/
        _/,/          _/_/,/
  _____/ (______,____/_/ (______
       ^-'             ^-'"
  "Ponylang knight logo.")

(defcustom ponylang-banner 1
  "Specify the startup banner.
Default value is `1', it displaysthe `Word' logo.`2' displays Emacs `Horse'
logo.  `3' displays Emacs `Knight' logo.A string to customize the banner.If the
value is 0 then no banner is displayed."
  :type  '(choice (integer :tag "banner index")
            (string :tag "custom banner"))
  :group 'ponylang)

(defun ponylang-choose-banner ()
  "Return the banner content."
  (cond ((not ponylang-banner) "")
    ((stringp ponylang-banner) ponylang-banner)
    ((= 0 ponylang-banner) "")
    ((= 1 ponylang-banner) ponylang-banner-default)
    ((= 2 ponylang-banner) ponylang-banner-horse)
    ((= 3 ponylang-banner) ponylang-banner-knight)
    (t ponylang-banner-default)))

(defhydra ponylang-hydra-menu
  (:color blue
    :hint none)
  "
%s(ponylang-choose-banner)
  Corral      |  _i_: Init     _f_: Fetch   _u_: Update  _o_: corral.json
  Pony        |  _b_: Build    _r_: Run     _c_: Clean
  Playground  |  _s_: Buffer   _S_: Region
  Community   |  _1_: News     _2_: BeginerHelp  _3_: Open Issue
              |  _4_: Chat     _5_: PlanetPony   _6_: Papers
              |  _7_: Tutorial _8_: Videos       _9_: Sponsors _0_: Contribute
  _q_: Quit"                            ;
  ("b" ponylang-project-build "Build")
  ("r" ponylang-project-run "Run")
  ("c" ponylang-project-clean "Clean")
  ("o" ponylang-corral-open "Open corral.json")
  ("i" ponylang-corral-init "corral init")
  ("f" ponylang-corral-fetch "corral fetch")
  ("u" ponylang-corral-update "corral udate")
  ("s" ponylang-share-buffer "share buffer")
  ("S" (ponylang-share-region (region-beginning)
         (region-end)) "share region")
  ("1" (ponylang-run-command "xdg-open https://www.ponylang.io/blog") "News")
  ("2" (ponylang-run-command
         "xdg-open https://ponylang.zulipchat.com/#narrow/stream/189985-beginner-help") "Beginner Help")
  ("3" (ponylang-run-command "xdg-open
https://github.com/ponylang/ponyc/issues") "Open an issue")
  ("4" (ponylang-run-command "xdg-open https://ponylang.zulipchat.com")
    "Zulip chat")
  ("5" (ponylang-run-command
         "xdg-open https://www.ponylang.io/community/planet-pony")
    "Planet-pony")
  ("6" (ponylang-run-command
         "xdg-open https://www.ponylang.io/community/#papers") "Papers")
  ("7" (ponylang-run-command "xdg-open https://tutorial.ponylang.io/")
    "Tutorial")
  ("8" (ponylang-run-command
         "xdg-open https://vimeo.com/search/sort:latest?q=pony-vug") "Videos")
  ("9" (ponylang-run-command "xdg-open https://www.ponylang.io/sponsors")
    "Sponsors")
  ("0" (ponylang-run-command "xdg-open
https://github.com/ponylang/contributors") "Contribute")
  ("q" nil "Quit"))

(defun ponylang-menu ()
  "Open ponylang hydra menu."
  (interactive)
  (ponylang-hydra-menu/body))

(defun ponylang-folding-hide-element
  (&optional
    RETRY)
  "Hide current element.
Optional argument RETRY ."
  (interactive)
  (let* ((region (yafolding-get-element-region))
          (beg (car region))
          (end (cadr region)))
    (if (and (eq RETRY nil)
          (= beg end))
      (progn (yafolding-go-parent-element)
        (ponylang-folding-hide-element t))
      (yafolding-hide-region beg end))))

(defun ponylang-build-tags ()
  "Build TAGS file for current project."
  (interactive)
  (let ((tags-buffer (get-buffer "TAGS"))
         (tags-buffer2 (get-buffer (format "TAGS<%s>"
                                     (ponylang-project-name)))))
    (if tags-buffer (kill-buffer tags-buffer))
    (if tags-buffer2 (kill-buffer tags-buffer2)))
  (let* ((ponyc-path (executable-find "ponyc"))
         (ponyc-executable (file-chase-links (expand-file-name ponyc-path)))
         (packages-path1 (concat (file-name-directory ponyc-executable)
                                 "../packages") )
         (packages-path2 (concat (file-name-directory ponyc-executable)
                                 "../../packages") )
         (packages-path (if (file-exists-p packages-path1) ;
                            packages-path1                   ;
                          packages-path2))
          (ctags-params                 ;
            (concat
              "ctags --langdef=pony --langmap=pony:.pony "
              "--regex-pony='/^[ \\t]*actor[ \\t]+([a-zA-Z0-9_]+)/\\1/a,actor/' "
              "--regex-pony='/^[ \\t]*class([ \\t]+(iso|trn|ref|val|box|tag))?[ \\t]+([a-zA-Z0-9_]+)/\\3/c,class/' "
              "--regex-pony='/[ \\t]*fun([ \\t]+(iso|trn|ref|val|box|tag))?[ \\t]+([a-zA-Z0-9_]+)/\\3/f,function/' "
              "--regex-pony='/[ \\t]*be[ \\t]+([a-zA-Z0-9_]+)/\\1/b,behavior/' "
              "--regex-pony='/[ \\t]*new([ \\t]+(iso|trn|ref|val|box|tag))?[ \\t]+([a-zA-Z0-9_]+)/\\3/n,new/' "
              "--regex-pony='/^[ \\t]*interface([ \\t]+(iso|trn|ref|val|box|tag))?[ \\t]+([a-zA-Z0-9_]+)/\\3/i,interface/' "
              "--regex-pony='/^[ \\t]*primitive[ \\t]+([a-zA-Z0-9_]+)/\\1/p,primitive/' "
              "--regex-pony='/^[ \\t]*struct[ \\t]+([a-zA-Z0-9_]+)/\\1/s,struct/' "
              "--regex-pony='/^[ \\t]*trait([ \\t]+(iso|trn|ref|val|box|tag))?[ \\t]+([a-zA-Z0-9_]+)/\\3/t,trait/' "
              "--regex-pony='/^[ \\t]*type[ \\t]+([a-zA-Z0-9_]+)/\\1/y,type/' "
              "--languages=pony "
              "-e -R . " packages-path)))
    (if (file-exists-p packages-path)
      (let ((oldir default-directory))
        (setq default-directory (ponylang-project-root))
        (shell-command ctags-params)
        (ponylang-load-tags)
        (setq default-directory oldir)))))

(defun ponylang-load-tags
  (&optional
    BUILD)
  "Visit tags table.
Optional argument BUILD ."
  (interactive)
  (let* ((tags-file (concat (ponylang-project-root) "TAGS")))
    (if (file-exists-p tags-file)
      (progn (visit-tags-table (concat (ponylang-project-root) "TAGS")))
      (if BUILD (ponylang-build-tags)))))

(defun ponylang-before-save-hook ()
  "Before save hook."
  (when (eq major-mode 'ponylang-mode)
    (ponylang-format-buffer)))

(defun ponylang-format-buffer ()
  "Format the current buffer."
  (indent-region (point-min)
    (point-max)))

(defun ponylang-after-save-hook ()
  "After save hook."
  (when (and (eq major-mode 'ponylang-mode)
             (not ponylang-skip-ctags))
    (if (not (= 0 (call-process-shell-command "ctags --version")))
      (message "Could not locate suitable executable '%s'" "ctags")
      (ponylang-build-tags))))

;;;###autoload
(define-derived-mode ponylang-mode ponylang-parent-mode
  "Pony"
  "Major mode for editing Pony files."
  :syntax-table ponylang-mode-syntax-table
  (setq-local imenu-generic-expression ;;
    '(("TODO" ".*TODO:[ \t]*\\(.*\\)$" 1)
       ("fun"
         "[ \t]*fun[ \t]+$?\\(iso\\|trn\\|ref\\|val\\|box\\|tag\\)?[ \t]*\\([a-zA-Z0-9_]+\\)[ \t]*"
         2)
       ("be" "[ \t]*be[ \t]+\\([a-zA-Z0-9_]+\\)[ \t]*(" 1)
       ("new"
         "[ \t]*new[ \t]+\\(iso\\|trn\\|ref\\|val\\|box\\|tag\\)*[ \t]*\\([a-zA-Z0-9_]+\\)[ \t]*("
         2)
       ("type" "^[ \t]*type[ \t]+\\([a-zA-Z0-9_]+\\)" 1)
       ("interface"
         "^[ \t]*interface[ \t]+\\(iso\\|trn\\|ref\\|val\\|box\\|tag\\)?[ \t]*\\([a-zA-Z0-9_]+\\)"
         2)
       ("trait"
         "^[ \t]*trait[ \t]+\\(iso\\|trn\\|ref\\|val\\|box\\|tag\\)?[ \t]*\\([a-zA-Z0-9_]+\\)"
         2)
       ("struct" "^[ \t]*struct[ \t]+\\([a-zA-Z0-9_]+\\)" 1)
       ("primitive" "^[ \t]*primitive[ \t]+\\([a-zA-Z0-9_]+\\)" 1)
       ("actor" "^[ \t]*actor[ \t]+\\([a-zA-Z0-9_]+\\)" 1)
       ("class"
         "^[ \t]*class[ \t]+\\(iso\\|trn\\|ref\\|val\\|box\\|tag\\)?[ \t]*\\([a-zA-Z0-9_]+\\)"
         2)
       ("use" "^[ \t]*use[ \t]+\\([a-zA-Z0-9_]+\\)" 1)))
  (imenu-add-to-menubar "Index")
  (setq-local comment-start "// ")
  (setq-local comment-start-skip "//+")
  (setq-local font-lock-defaults        ;
    '(ponylang-font-lock-keywords       ;
       nil nil nil nil                  ;
       (font-lock-syntactic-face-function .
         ponylang-mode-syntactic-face-function)))
  (setq-local indent-line-function 'ponylang-indent-line)
  (setq-local syntax-propertize-function ponylang-syntax-propertize-function)
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width 2)
  (setq-local buffer-file-coding-system 'utf-8-unix)
  (hl-todo-mode)
  (setq-local hl-todo-keyword-faces '(("TODO" . "green")
                                       ("FIXME" . "yellow")
                                       ("DEBUG" . "DarkCyan")
                                       ("GOTCHA" . "red")
                                       ("STUB" . "DarkGreen")))
  (whitespace-mode)
  (setq-local whitespace-style '(face spaces tabs newline space-mark tab-mark
                                  newline-mark trailing))
  ;; Make whitespace-mode and whitespace-newline-mode use “¶” for end of line char and “▷” for tab.
  (setq-local whitespace-display-mappings
    ;; all numbers are unicode codepoint in decimal. e.g. (insert-char 182 1)
    '((space-mark 32 [183]
        [46]) ;; SPACE 32 「 」, 183 MIDDLE DOT 「·」, 46 FULL STOP 「.」
       (newline-mark 10 [182 10]) ;; LINE FEED
       (tab-mark 9 [9655 9]
         [92 9])))

  ;; (setq-local whitespace-style '(face trailing))
  (setq-local fci-rule-column 80)
  (setq-local fci-handle-truncate-lines nil)
  (setq-local fci-rule-width 1)
  (setq-local fci-rule-color "grey30")
  ;;
  (rainbow-delimiters-mode t)
  (defalias 'yafolding-hide-element 'ponylang-folding-hide-element)
  ;;
  (yafolding-mode t)
  ;;
  ;; (add-hook 'before-save-hook 'ponylang-before-save-hook nil t)
  (add-hook 'after-save-hook #'ponylang-after-save-hook nil t)
  (ponylang-load-tags))

(provide 'ponylang-mode)

;;; ponylang-mode.el ends here
