;;; ppp.el --- Extended pretty printer for Emacs Lisp  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Version: 1.0.0
;; Package-Version: 20191225.1254
;; Package-Commit: 6aabd694bcc66775c6a4328fa653a83e39791252
;; Keywords: tools
;; Package-Requires: ((emacs "26"))
;; License: AGPL-3.0
;; URL: https://github.com/conao3/ppp.el

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
;; See the GNU Affero General Public License for more details.

;; You should have received a copy of the GNU Affero General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Extended pretty printer for Emacs Lisp


;;; Code:

(require 'warnings)

(defgroup ppp nil
  "Extended pretty printer for Emacs Lisp"
  :prefix "ppp-"
  :group 'tools
  :link '(url-link :tag "Github" "https://github.com/conao3/ppp.el"))

(defcustom ppp-escape-newlines t
  "Value of `print-escape-newlines' used by ppp-* functions."
  :type 'boolean
  :group 'ppp)

(defcustom ppp-debug-buffer-template "*P Debug buffer - %s*"
  "Buffer name for debugging."
  :group 'ppp
  :type 'string)

(defcustom ppp-minimum-warning-level-base :warning
  "Minimum level for debugging.
It should be either :debug, :warning, :error, or :emergency.
Every minimul-earning-level variable initialized by this variable.
You can customize each variable like ppp-minimum-warning-level--{{pkg}}."
  :group 'ppp
  :type 'symbol)


;;; Helpers

(defmacro with-ppp--working-buffer (form &rest body)
  "Insert FORM, execute BODY, return `buffer-string'."
  (declare (indent 1) (debug t))
  `(with-temp-buffer
     (lisp-mode-variables nil)
     (set-syntax-table emacs-lisp-mode-syntax-table)
     (let ((print-escape-newlines ppp-escape-newlines)
           (print-quoted t))
       (prin1 ,form (current-buffer))
       (goto-char (point-min)))
     (progn ,@body)
     (delete-trailing-whitespace)
     (buffer-substring-no-properties (point-min) (point-max))))


;;; Macros

;;;###autoload
(defmacro ppp-sexp-to-string (form)
  "Output the pretty-printed representation of FORM suitable for objects.
See `ppp-sexp' to get more info."
  `(with-output-to-string
     (ppp-sexp ,form)))

;;;###autoload
(defmacro ppp-macroexpand-to-string (form)
  "Output the pretty-printed representation of FORM suitable for macro.
See `ppp-macroexpand' to get more info."
  `(with-output-to-string
     (ppp-macroexpand ,form)))

;;;###autoload
(defmacro ppp-macroexpand-all-to-string (form)
  "Output the pretty-printed representation of FORM suitable for macro.
Unlike `ppp-macroexpand', use `macroexpand-all' instead of `macroexpand-1'.
See `ppp-macroexpand-all' to get more info."
  `(with-output-to-string
     (ppp-macroexpand-all ,form)))

;;;###autoload
(defmacro ppp-list-to-string (form)
  "Output the pretty-printed representation of FORM suitable for list.
See `ppp-list' to get more info."
  `(with-output-to-string
     (ppp-list ,form)))

;;;###autoload
(defmacro ppp-plist-to-string (form)
  "Output the pretty-printed representation of FORM suitable for plist.
See `ppp-plist' to get more info."
  `(with-output-to-string
     (ppp-plist ,form)))


;;; Functions

;;;###autoload
(defun ppp-sexp (form)
  "Output the pretty-printed representation of FORM suitable for objects."
  (let ((str (with-ppp--working-buffer form
               ;; `pp-buffer'
               (while (not (eobp))
                 ;; (message "%06d" (- (point-max) (point)))
                 (cond
                  ((ignore-errors (down-list 1) t)
                   (save-excursion
                     (backward-char 1)
                     (skip-chars-backward "'`#^")
                     (when (not (bobp))
                       (newline))))
                  ((ignore-errors (up-list 1) t)
                   (skip-syntax-forward ")")
                   (newline))
                  (t (goto-char (point-max)))))
               (goto-char (point-min))
               (indent-sexp))))
    (princ str))
  nil)

;;;###autoload
(defmacro ppp-macroexpand (form)
  "Output the pretty-printed representation of FORM suitable for macro."
  `(progn
     (ppp-sexp (macroexpand-1 ',form))
     nil))

;;;###autoload
(defmacro ppp-macroexpand-all (form)
  "Output the pretty-printed representation of FORM suitable for macro.
Unlike `ppp-macroexpand', use `macroexpand-all' instead of `macroexpand-1'."
  `(progn
     (ppp-sexp (macroexpand-all ',form))
     nil))

;;;###autoload
(defun ppp-list (form)
  "Output the pretty-printed representation of FORM suitable for list."
  (let ((str (with-ppp--working-buffer form
               (when (and form (listp form))
                 (forward-char)
                 (ignore-errors
                   (while t (forward-sexp) (newline)))
                 (delete-char -1)))))
    (princ (concat str "\n")))
  nil)

;;;###autoload
(defun ppp-plist (form)
  "Output the pretty-printed representation of FORM suitable for plist."
  (let ((str (with-ppp--working-buffer form
               (when (and form (listp form))
                 (forward-char)
                 (ignore-errors
                   (while t (forward-sexp 2) (newline)))
                 (delete-char -1)))))
    (princ (concat str "\n")))
  nil)

;;;###autoload
(defun ppp-debug (&rest args)
  "Output debug message to `flylint-debug-buffer'.

FORMAT and FORMAT-ARGS passed `format'.
PKG is accept symbol.
If BUFFER is specified, output that buffer.
If LEVEL is specified, output higher than `flylint-minimum-warning-level'.
If POPUP is non-nil, `display-buffer' debug buffer.
If BREAK is non-nil, output page break before output string.

ARGS accept (PKG &key buffer level break &rest FORMAT-ARGS).

\(fn &key buffer level break PKG FORMAT &rest FORMAT-ARGS)"
  (declare (indent defun))
  (let ((buffer nil)
        (level :debug)
        (popup nil)
        (break nil)
        (pkg 'unknown)
        format format-args elm)
    (while (keywordp (setq elm (pop args)))
      (cond ((eq :buffer elm)
             (setq buffer (pop args)))
            ((eq :popup elm)
             (setq popup (pop args)))
            ((eq :level elm)
             (setq level (pop args)))
            ((eq :break elm)
             (setq break (pop args)))
            (t
             (error "Unknown keyword: %s" elm))))
    (setq pkg elm)
    (setq format (pop args))
    (setq format-args args)
    (let ((arg-name (format "ppp-minimum-warning-level--%s" elm)))
      (unless (boundp (intern arg-name))
        (eval
         `(defcustom ,(intern arg-name) ppp-minimum-warning-level-base
            ,(format "Minimum level for debugging %s.
It should be either :debug, :warning, :error, or :emergency." pkg)
            :group 'ppp
            :type 'pkg)))
      (with-current-buffer (get-buffer-create
                            (or buffer (format (format ppp-debug-buffer-template pkg))))
        (emacs-lisp-mode)
        (when popup
          (display-buffer (current-buffer)))
        (when (<= (warning-numeric-level (symbol-value (intern arg-name)))
                  (warning-numeric-level level))
          (let ((msg (apply #'format `(,format ,@format-args)))
                (scroll (equal (point) (point-max)))
                (trace (read (format "(%s)" (with-output-to-string (backtrace)))))
                caller caller-args)
            (setq trace (cdr trace))   ; drop `backtrace' symbol
            (let ((tmp nil))
              (dotimes (_i 2)
                (while (listp (setq tmp (pop trace)))))
              (setq caller tmp)
              (setq caller-args (car-safe trace)))
            (prog1 msg
              (save-excursion
                (goto-char (point-max))
                (insert
                 (concat
                  (and break "\n")
                  (format "%s%s %s\n%s"
                          (format (cadr (assq level warning-levels))
                                  (format warning-type-format pkg))
                          caller caller-args
                          msg)))
                (unless (and (bolp) (eolp)) (newline)))
              (when scroll
                (goto-char (point-max))
                (set-window-point
                 (get-buffer-window (current-buffer)) (point-max))))))))))

(provide 'ppp)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; ppp.el ends here
