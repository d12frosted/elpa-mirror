;;; sotlisp.el --- Write lisp at the speed of thought.  -*- lexical-binding: t; -*-

;; Copyright (C) 2014, 2015 Free Software Foundation, Inc.

;; Author: Artur Malabarba <emacs@endlessparentheses.com>
;; URL: https://github.com/Malabarba/speed-of-thought-lisp
;; Package-Version: 20190211.2026
;; Package-Commit: ed2356a325c7a4a88ec1bd31381c8666e8997e97
;; Keywords: convenience, lisp
;; Package-Requires: ((emacs "24.1"))
;; Version: 1.6.2

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
;;
;; This defines a new global minor-mode `speed-of-thought-mode', which
;; activates locally on any supported buffer.  Currently, only
;; `emacs-lisp-mode' buffers are supported.
;;
;; The mode is quite simple, and is composed of two parts:
;;
;;; Abbrevs
;;
;; A large number of abbrevs which expand function
;; initials to their name.  A few examples:
;;
;; - wcb -> with-current-buffer
;; - i -> insert
;; - r -> require '
;; - a -> and
;;
;; However, these are defined in a way such that they ONLY expand in a
;; place where you would use a function, so hitting SPC after "(r"
;; expands to "(require '", but hitting SPC after "(delete-region r"
;; will NOT expand the `r', because that's obviously not a function.
;; Furthermore, "#'r" will expand to "#'require" (note how it omits
;; that extra quote, since it would be useless here).
;;
;;; Commands
;;
;; It also defines 4 commands, which really fit into this "follow the
;; thought-flow" way of writing.  The bindings are as follows, I
;; understand these don't fully adhere to conventions, and I'd
;; appreciate suggestions on better bindings.
;;
;; - M-RET :: Break line, and insert "()" with point in the middle.
;; - C-RET :: Do `forward-up-list', then do M-RET.
;;
;; Hitting RET followed by a `(' was one of the most common key sequences
;; for me while writing elisp, so giving it a quick-to-hit key was a
;; significant improvement.
;;
;; - C-c f :: Find function under point.  If it is not defined, create a
;; definition for it below the current function and leave point inside.
;; - C-c v :: Same, but for variable.
;;
;; With these commands, you just write your code as you think of it.  Once
;; you hit a "stop-point" of sorts in your thought flow, you hit `C-c f/v`
;; on any undefined functions/variables, write their definitions, and hit
;; `C-u C-SPC` to go back to the main function.
;;
;;; Small Example
;;
;; With the above (assuming you use something like paredit or
;; electric-pair-mode), if you write:
;;
;;   ( w t b M-RET i SPC text
;;
;; You get
;;
;;   (with-temp-buffer (insert text))

;;; Code:
(require 'skeleton)

;;; Predicates
(defun sotlisp--auto-paired-p ()
  "Non-nil if this buffer auto-inserts parentheses."
  (or (bound-and-true-p electric-pair-mode)
      (bound-and-true-p paredit-mode)
      (bound-and-true-p smartparens-mode)
      (bound-and-true-p lispy-mode)))

(defun sotlisp--looking-back (regexp)
  (string-match
   (concat regexp "\\'")
   (buffer-substring (line-beginning-position) (point))))

(defun sotlisp--function-form-p ()
  "Non-nil if point is at the start of a sexp.
Specially, avoids matching inside argument lists."
  (and (eq (char-before) ?\()
       (not (sotlisp--looking-back
             (rx (or (seq (? "cl-") (or "defun" "defmacro" "defsubst") (? "*")
                          symbol-end (* any))
                     (seq (or "lambda" "dolist" "dotimes")
                          symbol-end (+ (syntax whitespace))))
                 "(")))
       (save-excursion
         (forward-char -1)
         (condition-case nil
             (progn
               (backward-up-list)
               (forward-sexp -1)
               (not
                (looking-at-p (rx (* (or (syntax word) (syntax symbol) "-"))
                                  "let" (? "*") symbol-end))))
           (error t)))
       (not (string-match (rx (syntax symbol)) (string last-command-event)))))

(defun sotlisp--function-quote-p ()
  "Non-nil if point is at a sharp-quote."
  (ignore-errors
    (save-excursion
      (forward-char -2)
      (looking-at-p "#'"))))

(defun sotlisp--code-p ()
  (save-excursion
    (let ((r (point)))
      (beginning-of-defun)
      (let ((pps (parse-partial-sexp (point) r)))
        (not (or (elt pps 3)
                 (elt pps 4)))))))

(defun sotlisp--function-p ()
  "Non-nil if point is at reasonable place for a function name.
Returns non-nil if, after moving backwards by a sexp, either
`sotlisp--function-form-p' or `sotlisp--function-quote-p' return
non-nil."
  (save-excursion
    (ignore-errors
      (and (not (string-match (rx (syntax symbol)) (string last-command-event)))
           (sotlisp--code-p)
           (progn
             (skip-chars-backward (rx alnum))
             (or (sotlisp--function-form-p)
                 (sotlisp--function-quote-p)))))))

(defun sotlisp--whitespace-p ()
  "Non-nil if current `self-insert'ed char is whitespace."
  (sotlisp--whitespace-char-p last-command-event))
(make-obsolete 'sotlisp--whitespace-p 'sotlisp--whitespace-char-p "1.2")

(defun sotlisp--whitespace-char-p (char)
  "Non-nil if CHAR is has whitespace syntax."
  (ignore-errors
    (string-match (rx space) (string char))))


;;; Expansion logic
(defvar sotlisp--needs-moving nil
  "Will `sotlisp--move-to-$' move point after insertion?")

(defun sotlisp--move-to-$ ()
  "Move backwards until `$' and delete it.
Point is left where the `$' char was.  Does nothing if variable
`sotlisp-mode' is nil."
  (when (bound-and-true-p speed-of-thought-mode)
    (when sotlisp--needs-moving
      (setq sotlisp--needs-moving nil)
      (skip-chars-backward "^\\$")
      (delete-char -1))))

(add-hook 'post-command-hook #'sotlisp--move-to-$ 'append)

(defun sotlisp--maybe-skip-closing-paren ()
  "Move past `)' if variable `electric-pair-mode' is enabled."
  (when (and (char-after ?\))
             (sotlisp--auto-paired-p))
    (forward-char 1)))

(defun sotlisp--post-expansion-cleanup ()
  "Do some processing conditioned on the expansion done.
If the command that triggered the expansion was a whitespace
char, perform the steps below and return t.

If the expansion ended in a $, delete it and call
`sotlisp--maybe-skip-closing-paren'.
If it ended in a space and there's a space ahead, delete the
space ahead."
  ;; Inform `expand-abbrev' that `self-insert-command' should not
  ;; trigger, by returning non-nil on SPC.
  (when (sotlisp--whitespace-char-p last-command-event)
    ;; And maybe move out of closing paren if expansion ends with $.
    (if (eq (char-before) ?$)
        (progn (delete-char -1)
               (setq sotlisp--needs-moving nil)
               (sotlisp--maybe-skip-closing-paren))
      (when (and (sotlisp--whitespace-char-p (char-after))
                 (sotlisp--whitespace-char-p (char-before)))
        (delete-char 1)))
    t))

(defvar sotlisp--function-table (make-hash-table :test #'equal)
  "Table where function abbrev expansions are stored.")

(defun sotlisp--expand-function ()
  "Expand the function abbrev before point.
See `sotlisp-define-function-abbrev'."
  (let ((r (point)))
    (skip-chars-backward (rx alnum))
    (let* ((name (buffer-substring (point) r))
           (expansion (gethash name sotlisp--function-table)))
      (cond
       ((not expansion) (progn (goto-char r) nil))
       ((consp expansion)
        (delete-region (point) r)
        (let ((skeleton-end-newline nil))
          (skeleton-insert (cons "" expansion)))
        t)
       ((stringp expansion)
        (delete-region (point) r)
        (if (sotlisp--function-quote-p)
            ;; After #' use the simple expansion.
            (insert (sotlisp--simplify-function-expansion expansion))
          ;; Inside a form, use the full expansion.
          (insert expansion)
          (when (string-match "\\$" expansion)
            (setq sotlisp--needs-moving t)))
        ;; Must be last.
        (sotlisp--post-expansion-cleanup))))))

(put 'sotlisp--expand-function 'no-self-insert t)

(defun sotlisp--simplify-function-expansion (expansion)
  "Take a substring of EXPANSION up to first space.
The space char is not included.  Any \"$\" are also removed."
  (replace-regexp-in-string
   "\\$" ""
   (substring expansion 0 (string-match " " expansion))))


;;; Abbrev definitions
(defconst sotlisp--default-function-abbrevs
  '(
    ("a" . "and ")
    ("ah" . "add-hook '")
    ("atl" . "add-to-list '")
    ("bb" . "bury-buffer")
    ("bc" . "forward-char -1")
    ("bfn" . "buffer-file-name")
    ("bl" . "buffer-list$")
    ("blp" . "buffer-live-p ")
    ("bn" . "buffer-name")
    ("bod" . "beginning-of-defun")
    ("bol" . "forward-line 0$")
    ("bp" . "boundp '")
    ("bs" . "buffer-string$")
    ("bsn" . "buffer-substring-no-properties")
    ("bss" . "buffer-substring ")
    ("bw" . "forward-word -1")
    ("c" . "concat ")
    ("ca" . "char-after$")
    ("cb" . "current-buffer$")
    ("cc" . "condition-case er\n$\n(error nil)")
    ("ci" . "call-interactively ")
    ("cip" . "called-interactively-p 'any")
    ("csv" . "customize-save-variable '")
    ("d" . "delete-char 1")
    ("dc" . "delete-char 1")
    ("dcu" . "defcustom $ t\n  \"\"\n  :type 'boolean")
    ("df" . "defun $ ()\n  \"\"\n  ")
    ("dfa" . "defface $ \n  '((t))\n  \"\"\n  ")
    ("dfc" . "defcustom $ t\n  \"\"\n  :type 'boolean")
    ("dff" . "defface $ \n  '((t))\n  \"\"\n  ")
    ("dfv" . "defvar $ t\n  \"\"")
    ("dk" . "define-key ")
    ("dl" . "dolist (it $)")
    ("dt" . "dotimes (it $)")
    ("dmp" . "derived-mode-p '")
    ("dm" . "defmacro $ ()\n  \"\"\n  ")
    ("dr" . "delete-region ")
    ("dv" . "defvar $ t\n  \"\"")
    ("e" . "error \"$\"")
    ("ef" . "executable-find ")
    ("efn" . "expand-file-name ")
    ("eol" . "end-of-line")
    ("f" . "format \"$\"")
    ("fb" . "fboundp '")
    ("fbp" . "fboundp '")
    ("fc" . "forward-char 1")
    ("ff" . "find-file ")
    ("fl" . "forward-line 1")
    ("fp" . "functionp ")
    ("frp" . "file-readable-p ")
    ("fs" . "forward-sexp 1")
    ("fu" . "funcall ")
    ("fw" . "forward-word 1")
    ("g" . "goto-char ")
    ("gc" . "goto-char ")
    ("gsk" . "global-set-key ")
    ("i" . "insert ")
    ("ie" . "ignore-errors ")
    ("ii" . "interactive")
    ("il" . "if-let (($))")
    ("ir" . "indent-region ")
    ("jcl" . "justify-current-line ")
    ("jl" . "delete-indentation")
    ("jos" . "just-one-space")
    ("jr" . "json-read$")
    ("jtr" . "jump-to-register ")
    ("k" . ("kbd " (format "%S" (key-description (read-key-sequence-vector "Key: ")))))
    ("kb" . "kill-buffer")
    ("kn" . "kill-new ")
    ("kp" . "keywordp ")
    ("l" . "lambda ($)")
    ("la" . ("looking-at \"" - "\""))
    ("lap" . "looking-at-p \"$\"")
    ("lb" . "looking-back \"$\"")
    ("lbp" . "line-beginning-position")
    ("lep" . "line-end-position")
    ("let" . "let (($))")
    ("lp" . "listp ")
    ("m" . "message \"$%s\"")
    ("mb" . "match-beginning 0")
    ("mc" . "mapcar ")
    ("mct" . "mapconcat ")
    ("me" . "match-end 0")
    ("ms" . "match-string 0")
    ("msn" . "match-string-no-properties 0")
    ("msnp" . "match-string-no-properties 0")
    ("msp" . "match-string-no-properties 0")
    ("mt" . "mapconcat ")
    ("n" . "not ")
    ("nai" . "newline-and-indent$")
    ("nl" . "forward-line 1")
    ("np" . "numberp ")
    ("ntr" . "narrow-to-region ")
    ("ow" . "other-window 1")
    ("p" . "point$")
    ("pm" . "point-marker$")
    ("pa" . "point-max$")
    ("pg" . "plist-get ")
    ("pi" . "point-min$")
    ("pz" . "propertize ")
    ("r" . "require '")
    ("ra" . "use-region-p$")
    ("rap" . "use-region-p$")
    ("rb" . "region-beginning")
    ("re" . "region-end")
    ("rh" . "remove-hook '")
    ("rm" . "replace-match \"$\"")
    ("ro" . "regexp-opt ")
    ("rq" . "regexp-quote ")
    ("rris" . "replace-regexp-in-string ")
    ("rrs" . "replace-regexp-in-string ")
    ("rs" . "while (search-forward $ nil t)\n(replace-match \"\") nil t)")
    ("rsb" . "re-search-backward \"$\" nil 'noerror")
    ("rsf" . "re-search-forward \"$\" nil 'noerror")
    ("s" . "setq ")
    ("sb" . "search-backward $ nil 'noerror")
    ("sbr" . "search-backward-regexp $ nil 'noerror")
    ("scb" . "skip-chars-backward \"$\\r\\n[:blank:]\"")
    ("scf" . "skip-chars-forward \"$\\r\\n[:blank:]\"")
    ("se" . "save-excursion")
    ("sf" . "search-forward $ nil 'noerror")
    ("sfr" . "search-forward-regexp $ nil 'noerror")
    ("sic" . "self-insert-command")
    ("sl" . "setq-local ")
    ("sm" . "string-match \"$\"")
    ("smd" . "save-match-data")
    ("sn" . "symbol-name ")
    ("sp" . "stringp ")
    ("sq" . "string= ")
    ("sr" . "save-restriction")
    ("ss" . "substring ")
    ("ssn" . "substring-no-properties ")
    ("ssnp" . "substring-no-properties ")
    ("stb" . "switch-to-buffer ")
    ("sw" . "selected-window$")
    ("syp" . "symbolp ")
    ("tap" . "thing-at-point 'symbol")
    ("tf" . "thread-first ")
    ("tl" . "thread-last ")
    ("u" . "unless ")
    ("ul" . "up-list")
    ("up" . "unwind-protect\n(progn $)")
    ("urp" . "use-region-p$")
    ("w" . "when ")
    ("wcb" . "with-current-buffer ")
    ("wf" . "write-file ")
    ("wh" . "while ")
    ("wl" . "when-let (($))")
    ("we" . "window-end")
    ("ws" . "window-start")
    ("wsw" . "with-selected-window ")
    ("wtb" . "with-temp-buffer")
    ("wtf" . "with-temp-file ")
    )
  "Alist of (ABBREV . EXPANSION) used by `sotlisp'.")

(defun sotlisp-define-function-abbrev (name expansion)
  "Define a function abbrev expanding NAME to EXPANSION.
This abbrev will only be expanded in places where a function name is
sensible.  Roughly, this is right after a `(' or a `#''.

If EXPANSION is any string, it doesn't have to be the just the
name of a function.  In particular:
  - if it contains a `$', this char will not be inserted and
    point will be moved to its position after expansion.
  - if it contains a space, only a substring of it up to the
first space is inserted when expanding after a `#'' (this is done
by defining two different abbrevs).

For instance, if one defines
   (sotlisp-define-function-abbrev \"d\" \"delete-char 1\")

then triggering `expand-abbrev' after \"d\" expands in the
following way:
   (d    => (delete-char 1
   #'d   => #'delete-char"
  (define-abbrev emacs-lisp-mode-abbrev-table
    name t #'sotlisp--expand-function
    ;; Don't override user abbrevs
    :system t
    ;; Only expand in function places.
    :enable-function #'sotlisp--function-p)
  (puthash name expansion sotlisp--function-table))

(defun sotlisp-erase-all-abbrevs ()
  "Undefine all abbrevs defined by `sotlisp'."
  (interactive)
  (maphash (lambda (x _) (define-abbrev emacs-lisp-mode-abbrev-table x nil))
           sotlisp--function-table))

(defun sotlisp-define-all-abbrevs ()
  "Define all abbrevs in `sotlisp--default-function-abbrevs'."
  (interactive)
  (mapc (lambda (x) (sotlisp-define-function-abbrev (car x) (cdr x)))
    sotlisp--default-function-abbrevs))


;;; The global minor-mode
(defvar speed-of-thought-turn-on-hook '()
  "Hook run once when `speed-of-thought-mode' is enabled.
Note that `speed-of-thought-mode' is global, so this is not run
on every buffer.

See `sotlisp-turn-on-everywhere' for an example of what a
function in this hook should do.")

(defvar speed-of-thought-turn-off-hook '()
  "Hook run once when `speed-of-thought-mode' is disabled.
Note that `speed-of-thought-mode' is global, so this is not run
on every buffer.

See `sotlisp-turn-on-everywhere' for an example of what a
function in this hook should do.")

;;;###autoload
(define-minor-mode speed-of-thought-mode
  nil nil nil nil
  :global t
  (run-hooks (if speed-of-thought-mode
                 'speed-of-thought-turn-on-hook
               'speed-of-thought-turn-off-hook)))

;;;###autoload
(defun speed-of-thought-hook-in (on off)
  "Add functions ON and OFF to `speed-of-thought-mode' hooks.
If `speed-of-thought-mode' is already on, call ON."
  (add-hook 'speed-of-thought-turn-on-hook on)
  (add-hook 'speed-of-thought-turn-off-hook off)
  (when speed-of-thought-mode (funcall on)))


;;; The local minor-mode
(define-minor-mode sotlisp-mode
  nil nil " SoT"
  `(([M-return] . sotlisp-newline-and-parentheses)
    ([C-return] . sotlisp-downlist-newline-and-parentheses)
    (,(kbd "C-M-;") . ,(if (fboundp 'comment-or-uncomment-sexp)
                           #'comment-or-uncomment-sexp
                         #'sotlisp-comment-or-uncomment-sexp))
    ("\C-cf"    . sotlisp-find-or-define-function)
    ("\C-cv"    . sotlisp-find-or-define-variable))
  (if sotlisp-mode
      (abbrev-mode 1)
    (kill-local-variable 'abbrev-mode)))

(defun sotlisp-turn-on-everywhere ()
  "Call-once function to turn on sotlisp everywhere.
Calls `sotlisp-mode' on all `emacs-lisp-mode' buffers, and sets
up a hook and abbrevs."
  (add-hook 'emacs-lisp-mode-hook #'sotlisp-mode)
  (sotlisp-define-all-abbrevs)
  (mapc (lambda (b)
          (with-current-buffer b
            (when (derived-mode-p 'emacs-lisp-mode)
              (sotlisp-mode 1))))
        (buffer-list)))

(defun sotlisp-turn-off-everywhere ()
  "Call-once function to turn off sotlisp everywhere.
Removes `sotlisp-mode' from all `emacs-lisp-mode' buffers, and
removes hooks and abbrevs."
  (remove-hook 'emacs-lisp-mode-hook #'sotlisp-mode)
  (sotlisp-erase-all-abbrevs)
  (mapc (lambda (b)
          (with-current-buffer b
            (when (derived-mode-p 'emacs-lisp-mode)
              (sotlisp-mode -1))))
        (buffer-list)))

(speed-of-thought-hook-in #'sotlisp-turn-on-everywhere #'sotlisp-turn-off-everywhere)


;;; Commands
(defun sotlisp-newline-and-parentheses ()
  "`newline-and-indent' then insert a pair of parentheses."
  (interactive)
  (point)
  (ignore-errors (expand-abbrev))
  (newline-and-indent)
  (insert "()")
  (forward-char -1))

(defun sotlisp-downlist-newline-and-parentheses ()
  "`up-list', `newline-and-indent', then insert a parentheses pair."
  (interactive)
  (ignore-errors (expand-abbrev))
  (up-list)
  (newline-and-indent)
  (insert "()")
  (forward-char -1))

(defun sotlisp--find-in-buffer (r s)
  "Find the string (concat R (regexp-quote S)) somewhere in this buffer."
  (let ((l (save-excursion
             (goto-char (point-min))
             (save-match-data
               (when (search-forward-regexp (concat r (regexp-quote s) "\\_>")
                                            nil :noerror)
                 (match-beginning 0))))))
    (when l
      (push-mark)
      (goto-char l)
      l)))

(defun sotlisp--beginning-of-defun ()
  "`push-mark' and move above this defun."
  (push-mark)
  (beginning-of-defun)
  (forward-line -1)
  (unless (looking-at "^;;;###autoload\\s-*\n")
    (forward-line 1)))

(defun sotlisp--function-at-point ()
  "Return name of `function-called-at-point'."
  (if (save-excursion
        (ignore-errors (forward-sexp -1)
                       (looking-at-p "#'")))
      (thing-at-point 'symbol)
    (let ((fcap (function-called-at-point)))
      (if fcap
          (symbol-name fcap)
        (thing-at-point 'symbol)))))

(defun sotlisp-find-or-define-function (&optional prefix)
  "If symbol under point is a defined function, go to it, otherwise define it.
Essentially `find-function' on steroids.

If you write in your code the name of a function you haven't
defined yet, just place point on its name and hit \\[sotlisp-find-or-define-function]
and a defun will be inserted with point inside it.  After that,
you can just hit `pop-mark' to go back to where you were.
With a PREFIX argument, creates a `defmacro' instead.

If the function under point is already defined this just calls
`find-function', with one exception:
    if there's a defun (or equivalent) for this function in the
    current buffer, we go to that even if it's not where the
    global definition comes from (this is useful if you're
    writing an Emacs package that also happens to be installed
    through package.el).

With a prefix argument, defines a `defmacro' instead of a `defun'."
  (interactive "P")
  (let ((name (sotlisp--function-at-point)))
    (unless (and name (sotlisp--find-in-buffer "(def\\(un\\|macro\\|alias\\) " name))
      (let ((name-s (intern-soft name)))
        (if (fboundp name-s)
            (find-function name-s)
          (sotlisp--beginning-of-defun)
          (insert "(def" (if prefix "macro" "un")
                  " " name " (")
          (save-excursion (insert ")\n  \"\"\n  )\n\n")))))))

(defun sotlisp-find-or-define-variable (&optional prefix)
  "If symbol under point is a defined variable, go to it, otherwise define it.
Essentially `find-variable' on steroids.

If you write in your code the name of a variable you haven't
defined yet, place point on its name and hit \\[sotlisp-find-or-define-variable]
and a `defcustom' will be created with point inside.  After that,
you can just `pop-mark' to go back to where you were.  With a
PREFIX argument, creates a `defvar' instead.

If the variable under point is already defined this just calls
`find-variable', with one exception:
    if there's a defvar (or equivalent) for this variable in the
    current buffer, we go to that even if it's not where the
    global definition comes from (this is useful if you're
    writing an Emacs package that also happens to be installed
    through package.el).

With a prefix argument, defines a `defvar' instead of a `defcustom'."
  (interactive "P")
  (let ((name (symbol-name (variable-at-point t))))
    (unless (sotlisp--find-in-buffer "(def\\(custom\\|const\\|var\\) " name)
      (unless (and (symbolp (variable-at-point))
                   (ignore-errors (find-variable (variable-at-point)) t))
        (let ((name (thing-at-point 'symbol)))
          (sotlisp--beginning-of-defun)
          (insert "(def" (if prefix "var" "custom")
                  " " name " t")
          (save-excursion
            (insert "\n  \"\""
                    (if prefix "" "\n  :type 'boolean")
                    ")\n\n")))))))


;;; Comment sexp
(defun sotlisp-uncomment-sexp (&optional n)
  "Uncomment a sexp around point."
  (interactive "P")
  (let* ((initial-point (point-marker))
         (inhibit-field-text-motion t)
         (p)
         (end (save-excursion
                (when (elt (syntax-ppss) 4)
                  (re-search-backward comment-start-skip
                                      (line-beginning-position)
                                      t))
                (setq p (point-marker))
                (comment-forward (point-max))
                (point-marker)))
         (beg (save-excursion
                (forward-line 0)
                (while (and (not (bobp))
                            (= end (save-excursion
                                     (comment-forward (point-max))
                                     (point))))
                  (forward-line -1))
                (goto-char (line-end-position))
                (re-search-backward comment-start-skip
                                    (line-beginning-position)
                                    t)
                (ignore-errors
                  (while (looking-at comment-start-skip)
                    (forward-char -1))
                  (unless (looking-at "[\n\r[:blank]]")
                    (forward-char 1)))
                (point-marker))))
    (unless (= beg end)
      (uncomment-region beg end)
      (goto-char p)
      ;; Indentify the "top-level" sexp inside the comment.
      (ignore-errors
        (while (>= (point) beg)
          (backward-prefix-chars)
          (skip-chars-backward "\r\n[:blank:]")
          (setq p (point-marker))
          (backward-up-list)))
      ;; Re-comment everything before it.
      (ignore-errors
        (comment-region beg p))
      ;; And everything after it.
      (goto-char p)
      (forward-sexp (or n 1))
      (skip-chars-forward "\r\n[:blank:]")
      (if (< (point) end)
          (ignore-errors
            (comment-region (point) end))
        ;; If this is a closing delimiter, pull it up.
        (goto-char end)
        (skip-chars-forward "\r\n[:blank:]")
        (when (eq 5 (car (syntax-after (point))))
          (delete-indentation))))
    ;; Without a prefix, it's more useful to leave point where
    ;; it was.
    (unless n
      (goto-char initial-point))))

(defun sotlisp--comment-sexp-raw ()
  "Comment the sexp at point or ahead of point."
  (pcase (or (bounds-of-thing-at-point 'sexp)
             (save-excursion
               (skip-chars-forward "\r\n[:blank:]")
               (bounds-of-thing-at-point 'sexp)))
    (`(,l . ,r)
     (goto-char r)
     (skip-chars-forward "\r\n[:blank:]")
     (save-excursion
       (comment-region l r))
     (skip-chars-forward "\r\n[:blank:]"))))

(defun sotlisp-comment-or-uncomment-sexp (&optional n)
  "Comment the sexp at point and move past it.
If already inside (or before) a comment, uncomment instead.
With a prefix argument N, (un)comment that many sexps."
  (interactive "P")
  (if (or (elt (syntax-ppss) 4)
          (< (save-excursion
               (skip-chars-forward "\r\n[:blank:]")
               (point))
             (save-excursion
               (comment-forward 1)
               (point))))
      (sotlisp-uncomment-sexp n)
    (dotimes (_ (or n 1))
      (sotlisp--comment-sexp-raw))))

(provide 'sotlisp)
;;; sotlisp.el ends here
