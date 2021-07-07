;;; ppp.el --- Extended pretty printer for Emacs Lisp  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Version: 2.2.4
;; Package-Version: 20200812.844
;; Package-Commit: 86dad69c3a7dae770f6b99285647dff2aad81930
;; Keywords: tools
;; Package-Requires: ((emacs "25.1") (leaf "4.1.1"))
;; URL: https://github.com/conao3/ppp.el

;; This program is free software: you can redistribute it and/or modify
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

;; Extended pretty printer for Emacs Lisp


;;; Code:

(require 'warnings)
(require 'seq)
(require 'cl-lib)
(require 'leaf)              ; leaf proper indentation, leaf-list

(defgroup ppp nil
  "Extended pretty printer for Emacs Lisp."
  :prefix "ppp-"
  :group 'tools
  :link '(url-link :tag "Github" "https://github.com/conao3/ppp.el"))

(defcustom ppp-indent-spec
  '((0 . (unwind-protect progn))
    (1 . (lambda if condition-case not null car cdr 1+ 1-
           goto-char goto-line))
    (2 . (closure defcustom))
    (3 . (macro))
    (ppp--add-newline-for-let . (let let*))
    (ppp--add-newline-for-setq . (setq setf))
    (ppp--add-newline-for-leaf . (leaf use-package)))
  "Special indent specification.
Element at the top of the list takes precedence.

Format:
  FORMAT  := (SPEC*)
  SPEC    := (LEVEL . SYMBOLS)
  LEVEL   := <integer> | <lambda>
  SYMBOLS := (<symbol>*)

Duplicate LEVEL is accepted."
  :group 'ppp
  :type 'sexp)

(defcustom ppp-add-newline-after-op-list
  (leaf-list
   leaf use-package
   progn prog1 prog2 defun defcustom cl-defun
   eval-when-compile eval-and-compile cl-eval-when
   eval-after-load with-eval-after-load)
  "Add newline after those op sexp list."
  :group 'ppp
  :type 'sexp)

(defcustom ppp-escape-newlines t
  "Value of `print-escape-newlines' used by ppp-* functions."
  :type 'boolean
  :group 'ppp)

(defcustom ppp-debug-buffer-template "*PPP Debug buffer - %s*"
  "Buffer name for `ppp-debug'."
  :group 'ppp
  :type 'string)

(defcustom ppp-minimum-warning-level-alist '((t . :warning))
  "Minimum level for `ppp-debug'.
The key is package symbol.
The value should be either :debug, :warning, :error, or :emergency.
The value its key is t, is default minimum-warning-level value."
  :group 'ppp
  :type 'sexp)

;; If you want to change those internal variables, please use `let'.
(defvar ppp-optional-newline t
  "Whether add newline after `ppp-add-newline-after-op-list' sexp.")
(defvar ppp-tail-newline t
  "Whether add newline after `ppp' output or not.")
(defvar ppp-indent t
  "Whether indent `ppp' output or not.")


;;; Debug

(defvar ppp-debug nil
  "If non-nil, show debug overlay.")

(defvar-local ppp-debug-ovs (make-list 5 nil)
  "Debug overlay.")

(defvar ppp-debug-palette '("SeaGreen3" "khaki3" "brown3" "aquamarine3" "plum3")
  "Debug overlay palette.")

(defun ppp--debug-ov-make ()
  "Make debug overlay at point."
  (prog1 t
    (when ppp-debug
      (ppp--debug-ov-remove)
      (dotimes (i 5)
        (let ((ov (make-overlay (point) (1+ (point)))))
          (setf (nth i ppp-debug-ovs) ov)
          (move-overlay ov (point) (1+ (point)))
          (overlay-put ov 'ppp-debug-overlay t)
          (overlay-put ov 'priority (- 10 i))))
      (ppp--debug-ov-move))))

(defun ppp--debug-ov-move (&optional inx)
  "Move INXth debug overlay at PTR."
  (prog1 t
    (when ppp-debug
      (let* ((inx* (or inx 0))
             (ov (nth inx* ppp-debug-ovs)))
        (overlay-put ov 'face `(t :foreground "black"
                                  :background ,(nth inx* ppp-debug-palette)))
        (move-overlay ov (point) (1+ (point)))))))

(defun ppp--debug-ov-remove ()
  "Remove ppp-debug-overlay in buffer."
  (prog1 t
    (when ppp-debug
      (dolist (ov (cl-remove-if-not
                   (lambda (ov)
                     (overlay-get ov 'ppp-debug-overlay))
                   (overlays-in (point-min) (point-max))))
        (delete-overlay ov)))))


;;; wrapper functions

(defun ppp--forward-sexp (&optional arg)
  "Move forward across one balanced expression (sexp).
With ARG, do it that many times.  see `forward-sexp'."
  (let ((prev (point)))
    (condition-case _
        (progn
          (apply #'forward-sexp `(,arg))
          (not (equal prev (point))))
      (scan-error nil))))

(defun ppp--backward-sexp (&optional arg)
  "Move backward across one balanced expression (sexp).
With ARG, do it that many times.  see `backward-sexp'."
  (let ((prev (point)))
    (condition-case _
        (progn
          (apply #'backward-sexp `(,arg))
          (not (equal prev (point))))
      (scan-error nil))))

(defun ppp--forward-list (&optional arg)
  "Move forward across one balanced group of parentheses.
With ARG, do it that many times.  see `forward-list'."
  (let ((prev (point)))
    (condition-case _
        (progn
          (apply #'forward-list `(,arg))
          (not (equal prev (point))))
      (scan-error nil))))

(defun ppp--backward-list (&optional arg)
  "Move backward across one balanced group of parentheses.
With ARG, do it that many times.  see `backward-list'."
  (let ((prev (point)))
    (condition-case _
        (progn
          (apply #'backward-list `(,arg))
          (not (equal prev (point))))
      (scan-error nil))))

(defun ppp--down-list (&optional arg)
  "Move forward down one level of parentheses.
With ARG, do this that many times.  see `down-list'."
  (let ((prev (point)))
    (condition-case _
        (progn
          (apply #'down-list `(,arg))
          (not (equal prev (point))))
      (scan-error nil))))

(defun ppp--backward-up-list (&optional arg)
  "Move backward out of one level of parentheses.
With ARG, do this that many times.  see `backward-up-list'."
  (let ((prev (point)))
    (condition-case _
        (progn
          (apply #'backward-up-list `(,arg))
          (not (equal prev (point))))
      (scan-error nil))))

(defun ppp--up-list (&optional arg)
  "Move forward out of one level of parentheses.
With ARG, do this that many times.  see `up-list'."
  (let ((prev (point)))
    (condition-case _
        (progn
          (apply #'up-list `(,arg))
          (not (equal prev (point))))
      (scan-error nil))))

(defun ppp--insert (&rest args)
  "Insert ARGS.  see `insert'."
  (prog1 t
    (apply #'insert args)))


;;; Small utility

(defun ppp--get-indent (op)
  "Get indent for OP."
  (or (car
       (cl-find-if
        (lambda (elm) (memq op (cdr elm)))
        ppp-indent-spec))
      (when (symbolp op)
        (plist-get (symbol-plist op) 'lisp-indent-function))))

(defun ppp--skip-spaces-forward ()
  "Skip spaces forward."
  (prog1 t
    (skip-chars-forward " \t\n")))

(defun ppp--skip-spaces-backward ()
  "Skip spaces backward."
  (prog1 t
    (skip-chars-backward " \t\n")))


;;; ppp-sexp

(defun ppp--add-newline-this-sexp ()
  "Add newline this pointed sexp."
  (ppp--skip-spaces-forward) (ppp--debug-ov-move 4)
  (save-restriction
    (save-excursion
      (let ((beg (point))
            (end (progn (and (ppp--forward-sexp) (point))))
            (ppp-optional-newline nil)
            (ppp-tail-newline nil)
            (ppp-indent nil))
        (when (and beg end (< beg end))
          (narrow-to-region beg end)
          (ppp-buffer)
          t)))))

(defun ppp--add-newline-after-sexp (nsexp)
  "Add newline after NSEXP.
Return t if scan succeeded and return nil if scan failed."
  (and
   (let ((res (= 0 nsexp)))               ; make RES t when NSEXP is 0
     (dotimes (_ nsexp res)
       (ppp--add-newline-this-sexp)
       (setq res (and (ppp--forward-sexp) (ppp--debug-ov-move 4)))))
   (progn (unless (eq ?\) (char-after)) (ppp--insert "\n")) t)))

(defun ppp--add-newline-per-sexp (nsexp)
  "Add newline per NSEXP."
  (while (ppp--add-newline-after-sexp nsexp)))

(defun ppp--add-newline-for-let ()
  "Add newline for `let'."
  (and
   (ppp--down-list) (ppp--debug-ov-move 4)
   (progn (save-excursion (ppp--add-newline-per-sexp 1)) t)
   (while (and
           (ppp--down-list) (ppp--debug-ov-move 4)
           (ppp--forward-sexp) (ppp--debug-ov-move 4)
           (prog1 t
             (delete-region
              (point)
              (progn (ppp--skip-spaces-forward) (point))))
           (ppp--insert " ")
           (ppp--up-list) (ppp--debug-ov-move 4)))))

(defun ppp--add-newline-for-leaf ()
  "Add newline for `leaf', `use-package'."
  (and
   (and
    (ppp--forward-sexp) (ppp--debug-ov-move)
    (ppp--skip-spaces-forward) (ppp--debug-ov-move))
   (let (key)
     (while (let ((sexp (sexp-at-point)))
              (and
               (cond
                ((keywordp sexp)
                 (setq key sexp)
                 (and
                  (prog1 t
                    (delete-region
                     (point)
                     (progn (ppp--skip-spaces-backward) (point))))
                  (ppp--insert "\n") (ppp--debug-ov-move)
                  (ppp--forward-sexp) (ppp--debug-ov-move)
                  (prog1 t
                    (when (memq sexp '(:preface :init :config :mode-hook))
                      (ppp--insert "\n") (ppp--debug-ov-move)))))
                (t
                 (cl-case key
                   ((:preface :init :config :mode-hook)
                    (and
                     (ppp--add-newline-after-sexp 1) (ppp--debug-ov-move)))
                   (otherwise
                    (and
                     (ppp--add-newline-this-sexp) (ppp--debug-ov-move)
                     (ppp--forward-sexp) (ppp--debug-ov-move))))))
               (ppp--skip-spaces-forward) (ppp--debug-ov-move)))))))

(defun ppp--add-newline-for-setq ()
  "Add newline for `let'."
  (while (ppp--add-newline-after-sexp 2)))

(defmacro with-ppp--working-buffer (form &rest body)
  "Insert FORM, execute BODY, return `buffer-string'."
  (declare (indent 1) (debug t))
  `(with-temp-buffer
     (lisp-mode-variables nil)
     (set-syntax-table emacs-lisp-mode-syntax-table)
     (let ((print-escape-newlines ppp-escape-newlines)
           (print-length nil)
           (print-level nil)
           (print-quoted t))
       (insert (prin1-to-string ,form)))
     (goto-char (point-min))
     (ppp--debug-ov-make)
     (save-excursion
       ,@body)
     (buffer-substring-no-properties (point-min) (point-max))))

;;;###autoload
(defun ppp-buffer ()
  "Prettify the current buffer with printed representation of a Lisp object.
IF NOTAILNEWLINE is non-nil, add no last newline.
If NOINDENT is non-nil, don't perform indent sexp.
ppp version of `pp-buffer'."
  (interactive)
  (goto-char (point-min)) (ppp--debug-ov-make)
  (let ((ptr -1))
    (while (not (eobp))
      (let* ((op (sexp-at-point))
             (indent (ppp--get-indent op)))
        (cond
         ((or (and (functionp indent) (not (= ptr (point))))
              (and (symbolp indent) (not (memq indent '(nil defun))) (not (= ptr (point)))))
          (and
           (ppp--forward-sexp) (ppp--debug-ov-move)
           (funcall (if (functionp indent) indent (symbol-function indent))))
          (setq ptr (point)))
         ((and (integerp indent) (not (= ptr (point))))
          (and
           (ppp--forward-sexp) (ppp--debug-ov-move)
           (ppp--add-newline-after-sexp indent))
          (setq ptr (point)))
         ((and (ppp--down-list) (ppp--debug-ov-move))
          (save-excursion
            (backward-char 1) (ppp--debug-ov-move 1)
            (skip-chars-backward "'`#^") (ppp--debug-ov-move 1)
            (when (and (not (bobp)) (memq (char-before) '(?\s ?\t ?\n)))
              (delete-region
               (point)
               (progn (ppp--skip-spaces-backward) (point)))
              (ppp--insert "\n") (ppp--debug-ov-move 1))))
         ((and (ppp--up-list) (ppp--debug-ov-move))
          (skip-syntax-forward ")") (ppp--debug-ov-move)
          (delete-region
           (point)
           (progn (ppp--skip-spaces-forward) (point)))
          (ppp--insert "\n") (ppp--debug-ov-move))
         (t (goto-char (point-max)) (ppp--debug-ov-move))))))
  (goto-char (point-max))
  (delete-region (point) (progn (ppp--skip-spaces-backward) (point)))
  (when ppp-tail-newline (goto-char (point-max)) (ppp--insert "\n"))
  (when ppp-optional-newline (goto-char (point-min)) (ppp-add-newline-after-op))
  (when ppp-indent (goto-char (point-min)) (indent-sexp)))

(defun ppp-pp-buffer ()
  "Prettify the current buffer with printed representation of a Lisp object.
`pp-buffer' with debug marker."
  (goto-char (point-min))
  (ppp--debug-ov-make)
  (while (not (eobp))
    ;; (message "%06d" (- (point-max) (point)))
    (cond
     ((ignore-errors (down-list 1) (ppp--debug-ov-move) t)
      (save-excursion
        (backward-char 1) (ppp--debug-ov-move 1)
        (skip-chars-backward "'`#^") (ppp--debug-ov-move 1)
        (when (and (not (bobp)) (memq (char-before) '(?\s ?\t ?\n)))
          (delete-region
           (point)
           (progn (ppp--skip-spaces-backward) (point)))
          (insert "\n") (ppp--debug-ov-move 1))))
     ((ignore-errors (up-list 1) (ppp--debug-ov-move) t)
      (skip-syntax-forward ")") (ppp--debug-ov-move)
      (delete-region
       (point)
       (progn (ppp--skip-spaces-forward) (point)))
      (insert ?\n) (ppp--debug-ov-move))
     (t (goto-char (point-max)) (ppp--debug-ov-move))))
  (goto-char (point-min)) (ppp--debug-ov-move)
  (indent-sexp))

(defun ppp-add-newline-after-op ()
  "Add newline after `ppp-add-newline-after-op-list' sexp."
  (while (not (eobp))
    (cond
     ((and (ppp--down-list) (ppp--debug-ov-move))
      (when (memq (sexp-at-point) ppp-add-newline-after-op-list)
        (save-excursion
          (and (ppp--up-list)
               (not (eq ?\) (char-after)))
               (skip-chars-forward "\n")
               (not (eobp))
               (ppp--insert "\n")))))
     ((and (ppp--up-list) (ppp--debug-ov-move))
      (skip-syntax-forward ")") (ppp--debug-ov-move))
     (t (goto-char (point-max)) (ppp--debug-ov-move)))))


;;; String functions

;;;###autoload
(defun ppp-sexp-to-string (form)
  "Output the pretty-printed representation of FORM suitable for objects.
If NOTAILNEWLINE is non-nil, add no newline at tail newline.
See `ppp-sexp' to get more info."
  (with-ppp--working-buffer form
    (ppp-buffer)))

;;;###autoload
(defmacro ppp-macroexpand-to-string (form)
  "Output the pretty-printed representation of FORM suitable for macro.
If NOTAILNEWLINE is non-nil, add no newline at tail newline.
See `ppp-macroexpand' to get more info."
  `(ppp-sexp-to-string (macroexpand-1 ',form)))

;;;###autoload
(defmacro ppp-macroexpand-all-to-string (form)
  "Output the pretty-printed representation of FORM suitable for macro.
Unlike `ppp-macroexpand', use `macroexpand-all' instead of `macroexpand-1'.
If NOTAILNEWLINE is non-nil, add no newline at tail newline.
See `ppp-macroexpand-all' to get more info."
  `(ppp-sexp-to-string (macroexpand-all ',form)))

;;;###autoload
(defun ppp-list-to-string (form)
  "Output the pretty-printed representation of FORM suitable for list.
If NOTAILNEWLINE is non-nil, add no newline at tail newline.
See `ppp-list' to get more info."
  (with-ppp--working-buffer form
    (save-excursion
      (and (ppp--down-list) (ppp--add-newline-per-sexp 1)))
    (indent-sexp)
    (when ppp-tail-newline
      (goto-char (point-max)) (ppp--insert "\n"))))

;;;###autoload
(defun ppp-plist-to-string (form)
  "Output the pretty-printed representation of FORM suitable for plist.
If NOTAILNEWLINE is non-nil, add no newline at tail newline.
See `ppp-plist' to get more info."
  (if (not (listp form))
      (prin1-to-string form)
    (with-ppp--working-buffer `(ppp-dummy ,@form) ; add dummy symbol for indent
      (save-excursion
        (ppp--down-list) (ppp--forward-sexp) (ppp--insert "\n")
        (ppp--add-newline-per-sexp 2))
      (indent-sexp)
      (delete-region                    ; remove dummy symbol
       (progn (ppp--down-list) (point))
       (progn (ppp--forward-sexp) (ppp--skip-spaces-forward) (point)))
      (when ppp-tail-newline
        (goto-char (point-max)) (ppp--insert "\n")))))

;;;###autoload
(defun ppp-alist-to-string (form)
  "Output the pretty-printed representation of FORM suitable for alist.
If NOTAILNEWLINE is non-nil, add no newline at tail newline.
See `ppp-plist' to get more info."
  (ppp-plist-to-string (ppp-alist-to-plist form)))

;;;###autoload
(defun ppp-symbol-function-to-string (symbol)
  "Output the pretty-printed representation of SYMBOL `symbol-function'.
If NOTAILNEWLINE is non-nil, add no newline at tail newline.
See `ppp-symbol-funciton' to get more info."
  (ppp-sexp-to-string (symbol-function symbol)))

;;;###autoload
(defun ppp-symbol-value-to-string (symbol)
  "Output the pretty-printed representation of SYMBOL `symbol-value'.
If NOTAILNEWLINE is non-nil, add no newline at tail newline.
See `ppp-symbol-value' to get more info."
  (ppp-sexp-to-string (symbol-value symbol)))


;;; Princ functions

;;;###autoload
(defun ppp-sexp (form)
  "Output the pretty-printed representation of FORM suitable for objects.
If NOTAILNEWLINE is non-nil, add no newline at tail newline."
  (prog1 nil
    (princ (ppp-sexp-to-string form))))

;;;###autoload
(defmacro ppp-macroexpand (form)
  "Output the pretty-printed representation of FORM suitable for macro.
If NOTAILNEWLINE is non-nil, add no newline at tail newline."
  `(prog1 nil
     (princ (ppp-macroexpand-to-string ,form))))

;;;###autoload
(defmacro ppp-macroexpand-all (form)
  "Output the pretty-printed representation of FORM suitable for macro.
If NOTAILNEWLINE is non-nil, add no newline at tail newline.
Unlike `ppp-macroexpand', use `macroexpand-all' instead of `macroexpand-1'."
  `(prog1 nil
     (princ (ppp-macroexpand-all-to-string ,form))))

;;;###autoload
(defun ppp-list (form)
  "Output the pretty-printed representation of FORM suitable for list.
If NOTAILNEWLINE is non-nil, add no newline at tail newline."
  (prog1 nil
    (princ (concat (ppp-list-to-string form) "\n"))))

;;;###autoload
(defun ppp-plist (form)
  "Output the pretty-printed representation of FORM suitable for plist.
If NOTAILNEWLINE is non-nil, add no newline at tail newline."
  (prog1 nil
    (princ (concat (ppp-plist-to-string form) "\n"))))

;;;###autoload
(defun ppp-alist (form)
  "Output the pretty-printed representation of FORM suitable for alist.
If NOTAILNEWLINE is non-nil, add no newline at tail newline."
  (prog1 nil
    (princ (concat (ppp-alist-to-string form)))))

;;;###autoload
(defun ppp-symbol-function (symbol)
  "Output `symbol-function' for SYMBOL.
If NOTAILNEWLINE is non-nil, add no newline at tail newline."
  (prog1 nil
    (princ (ppp-symbol-function-to-string symbol))))

;;;###autoload
(defun ppp-symbol-value (symbol)
  "Output `symbol-value' for SYMBOL.
If NOTAILNEWLINE is non-nil, add no newline at tail newline."
  (prog1 nil
    (princ (ppp-symbol-value-to-string symbol))))

;;;###autoload
(defun ppp-alist-to-plist (alist &optional _notailnewline)
  "Convert ALIST to plist.
If NOTAILNEWLINE is non-nil, add no newline at tail newline."
  (mapcan
   (lambda (elm)
     (let ((keyname (prin1-to-string (car elm))))
       (list (intern
              (concat (unless (string-prefix-p ":" keyname) ":") keyname))
             (cdr elm))))
   alist))

(defun ppp--get-caller (&optional level)
  "Get caller function and arguments from backtrace.
If NOTAILNEWLINE is non-nil, add no newline at tail newline.
Optional arguments LEVEL is pop level for backtrace."
  (let ((trace-str (format "(%s)" (with-output-to-string (backtrace))))
        trace)
    (condition-case _err
        (progn
          (setq trace (cdr (read trace-str)))   ; drop `backtrace' symbol
          (let (tmp)
            (dotimes (_i (or level 1))
              (while (listp (setq tmp (pop trace)))))
            `(,tmp ,(car-safe trace))))
      (invalid-read-syntax
       '(:error invalid-read-syntax)))))

;;;###autoload
(defmacro ppp-debug (&rest args)
  "Output debug message to `flylint-debug-buffer'.

ARGS accepts (KEYWORD-ARGUMENTS... PKG FORMAT &rest FORMAT-ARGS).

Auto arguments:
  PKG is symbol.
  FORMAT and FORMAT-ARGS passed `format'.

Keyword arguments:
  If LEVEL is specified, output higher than
  `ppp-minimum-warning-level--{{PKG}}' initialized `ppp-minimum-warning-level'.
  LEVEL should be one of :debug, :warning, :error, or :emergency.
  If LEVEL is omitted, assume :debug.
  If BUFFER is specified, output that buffer.
  If POPUP is non-nil, `display-buffer' debug buffer.
  If BREAK is non-nil, output page break before output string.

Note:
  If use keyword arguments, must specified these before auto arguments.

\(fn &key buffer level break PKG FORMAT &rest FORMAT-ARGS)"
  (declare (indent defun))
  (let (prop)
    (cl-loop for (key val) on args by #'cddr
             for rest on args by #'cddr
             for key* = (eval key)
             while (keywordp key*)
             do (if (memq key* '(:level :buffer :popup :break))
                    (setf (alist-get key* prop) (eval val))
                  (error "Unknown keyword: %s" key*))
             finally (progn
                       (setf (alist-get :pkg prop) (eval (pop rest)))
                       (setf (alist-get :format-raw prop) (pop rest))
                       (setf (alist-get :format-args-raw prop) rest)))
    (let* ((pkg             (alist-get :pkg prop))
           (format-raw      (alist-get :format-raw prop))
           (format-args-raw (alist-get :format-args-raw prop))
           (level           (or (alist-get :level prop) :debug))
           (buffer          (or (alist-get :buffer prop)
                                (format ppp-debug-buffer-template pkg)))
           (popup           (alist-get :popup prop))
           (break           (alist-get :break prop)))
      `(with-current-buffer (get-buffer-create ,buffer)
         (special-mode)
         (emacs-lisp-mode)
         (when (<= (warning-numeric-level
                    ,(alist-get pkg ppp-minimum-warning-level-alist
                                (alist-get t ppp-minimum-warning-level-alist)))
                   (warning-numeric-level ,level))
           (prog1 t
             (let ((inhibit-read-only t)
                   (msg (format ,format-raw ,@format-args-raw))
                   (scroll (equal (point) (point-max))))
               (save-excursion
                 (goto-char (point-max))
                 (insert
                  (concat
                   ,(and break "\n")
                   ,(format (cadr (assq level warning-levels))
                            (format warning-type-format pkg))
                   ;; (seq-let (caller caller-args) (ppp--get-caller 2)
                   ;;   (prin1-to-string caller)
                   ;;   " "
                   ;;   (prin1-to-string caller-args))
                   "\n"
                   msg))
                 (unless (and (bolp) (eolp))
                   (newline)))
               (when scroll
                 (goto-char (point-max))
                 (set-window-point
                  (get-buffer-window (current-buffer)) (point-max)))
               ,(when popup
                  '(display-buffer (current-buffer))))))))))

(provide 'ppp)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; ppp.el ends here
