;;; seml-mode.el --- major-mode for SEML, S-Expression Markup Language, file        -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Maintainer: Naoya Yamashita <conao3@gmail.com>
;; Keywords: lisp html
;; Package-Version: 20191123.1851
;; Package-Commit: 1f8bda7e5a4a36212f968b462cfc31ce53c6db85
;; Version: 1.6.0
;; URL: https://github.com/conao3/seml-mode
;; Package-Requires: ((emacs "25") (simple-httpd "1.5") (htmlize "1.5") (web-mode "16.0"))

;; This program is free software; you can redistribute it and/or modify
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
;;
;; Below 2 files represent the same structure.
;; I call the S expression representation of the markup language
;; (especially with HTML) SEML and this package provides
;; the major mode and utility for that file.
;;
;; SEML is *short* and *easy to understand* for Lisp hacker.
;;
;; #+begin_src html
;;   <!DOCTYPE html>
;;   <html lang="en">
;;     <head>
;;       <meta charset="utf-8"/>
;;       <title>sample page</title>
;;       <link rel="stylesheet" href="sample1.css"/>
;;     </head>
;;     <body>
;;       <h1>sample</h1>
;;       <p>
;;         text sample
;;       </p>
;;     </body>
;;   </html>
;; #+end_src
;;
;; #+begin_src seml
;;   (html ((lang . "en"))
;;     (head nil
;;       (meta ((charset . "utf-8")))
;;       (title nil "sample page")
;;       (link ((rel . "stylesheet") (href . "sample1.css"))))
;;     (body nil
;;       (h1 nil "sample")
;;       (p nil "text sample")))
;; #+end_src
;;
;; More information at [[https://github.com/conao3/seml-mode][github]]
;;
;; Sample configuration with [[https://github.com/conao3/leaf.el][leaf.el]]
;;
;; (leaf real-auto-save
;;   :ensure t
;;   :custom ((real-auto-save-interval . 0.3))
;;   :hook (find-file-hook . real-auto-save-mode))
;;
;; (leaf seml-mode
;;   :config (require 'seml-mode)
;;   :custom ((seml-live-refresh-interval . 0.35)))
;;

;;; Code:

(require 'elisp-mode)                  ; seml-mode is a derivative of elisp-mode
(require 'simple-httpd)                ; seml provide Emacs's httpd process
(require 'htmlize)                     ; Embed code with each fontlock
(require 'web-mode)                    ; well-indent html by web-mode
(require 'cl-lib)                      ; cl-mapcan

(defgroup seml nil
  "Major mode for editing SEML (S-Expression Markup Language) file."
  :group 'lisp
  :prefix "seml-")

(defcustom seml-mode-hook nil
  "Hook run when entering seml mode."
  :type 'hook
  :group 'seml)

(defvar seml-map (make-sparse-keymap)
  "Keymap for SEML mode.")

(defcustom seml-import-dir (locate-user-emacs-file "seml")
  "`seml-import' search directory."
  :type 'string
  :group 'seml)

(defcustom seml-live-refresh-interval 1.1
  "Live-refresh interval.
NOTE: If you have auto-save settings, set this variable loger than it."
  :type 'integer
  :group 'seml)

(defcustom seml-live-refresh-url-variable ":arg1/:arg2/:arg3"
  "Live-refresh url."
  :type 'strings
  :group 'seml)

(defcustom seml-live-refresh-url-quety "query"
  "Live-refresh url."
  :type 'string
  :group 'seml)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Const
;;

(defconst seml-mode-syntax-table lisp-mode-syntax-table
  "Syntax table of seml.")

(defconst seml-mode-keywords
  '(html
    head title base link meta style
    script noscript
    body section nav article aside hgroup header footer address
    h1 h2 h3 h4 h5 h6
    p hr pre backquote ol ul li
    dl dt dd figure figcaption div main
    a em strong small s cite q dfn addr time code var
    samp kbd sub sup i b mark ruby rt rpbdo span br wbr
    ins del
    img iframe embed object param
    video audio source canvas map area
    table caption colgroup col tbody thead tfoot tr td th
    form fieldset legend label input button select
    datalist optgroup option textarea keygen output progress meter
    details summary command menu

    ;; libxml-parse keywords
    comment top))

(defconst seml-mode-keywords-regexp
  (rx-to-string `(or ,@(mapcar 'symbol-name seml-mode-keywords))))

(defconst seml-html-single-tags
  '(base link meta img br area param hr col option input wbr))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Polifills
;;

(defsubst seml-pairp (var)
  "Return t if VAR is pair."
  (and (listp var) (atom (cdr var))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  macros
;;

(defmacro with-seml-elisp (&rest body)
  "Provide environment of eval BODY in seml.  Use ,@(with-seml-elisp (sexp))."
  (declare (indent 0) (debug t))
  `(progn ,@body nil))
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  functions
;;

(require 'lisp-mode)                   ; define seml indent function from lisp's
(defvar calculate-lisp-indent-last-sexp) ; lisp-mode: L888
(defun seml-indent-function (indent-point state)
  "Indent calculation function for seml.
at INDENT-POINT on STATE.  see original function `lisp-indent-function'."
  (let ((normal-indent (current-column)))
    (goto-char (1+ (elt state 1)))
    (parse-partial-sexp (point) calculate-lisp-indent-last-sexp 0 t)
    (if (and (elt state 2)
             (not (looking-at "\\sw\\|\\s_")))
        ;; car of form doesn't seem to be a symbol
        (progn
          (if (not (> (save-excursion (forward-line 1) (point))
                      calculate-lisp-indent-last-sexp))
	      (progn (goto-char calculate-lisp-indent-last-sexp)
		     (beginning-of-line)
		     (parse-partial-sexp (point)
					 calculate-lisp-indent-last-sexp 0 t)))
	  ;; Indent under the list or under the first sexp on the same
	  ;; line as calculate-lisp-indent-last-sexp.  Note that first
	  ;; thing on that line has to be complete sexp since we are
          ;; inside the innermost containing sexp.
          (backward-prefix-chars)
          (current-column))
      (let ((function (buffer-substring (point)
					(progn (forward-sexp 1) (point))))
	    method)
	(setq method (or (function-get (intern-soft function)
                                       'lisp-indent-function)
			 (get (intern-soft function) 'lisp-indent-hook)))
	(cond ((or (eq method 'defun)
		   (and (null method)
			(> (length function) 3)
			(string-match "\\`def" function)))
	       (lisp-indent-defform state indent-point))
              ((memq (intern-soft function) seml-mode-keywords)
               (lisp-indent-specform 1 state
				     indent-point normal-indent))
	      ((integerp method)
	       (lisp-indent-specform method state
				     indent-point normal-indent))
	      (method
	       (funcall method indent-point state)))))))

;;;###autoload
(defun seml-to-string (sexp)
  "Return formated string from seml SEXP."
  (with-temp-buffer
    (insert (prin1-to-string sexp))
    (goto-char (point-min))
    (save-excursion
      (ignore-errors
        (while t
          (if (equal (following-char) ?\")
              (forward-sexp)
            (forward-char)
            (forward-sexp) (forward-sexp))
          (skip-chars-forward ") ")
          (insert "\n"))))
    (delete-trailing-whitespace)
    (seml-mode)
    (indent-sexp)
    (buffer-substring-no-properties (point-min) (point-max))))

;;;###autoload
(defun seml-pp (sexp &optional stream return-p)
  "Output pretty-printed representation of seml SEXP.
Output to STREAM, or value of `standard-output'
When RETURN-P is non-nil, return `pp' string.

This function is seml version of `pp'."
  (let ((ppstr (seml-to-string sexp)))
    (princ ppstr (or stream standard-output))
    (if return-p ppstr nil)))

;;;###autoload
(defun seml-xpath (xpath sexp &optional without-top)
  "Get element at XPATH like specification from seml SEXP.
When WITHOUT-TOP is nonnil, return SEML sexp without top tag.
XPATH is now supported below forms
- '(top html body pre)"
  (declare (indent 1))
  (let ((fn) (result) (current))
    (setq fn (lambda (dom)
               (cond
                ((and (listp dom) (not (seml-pairp dom))
                      (eq (car xpath) (car dom)))
                 (setq current (pop xpath))
                 (if xpath
                     (mapc fn dom)
                   (push (if without-top (cddr dom) dom) result)
                   (push current xpath)))
                ((and (listp dom) (not (seml-pairp dom)))
                 (mapc fn dom))
                (t nil))))
    (mapc fn `(,sexp))
    (nreverse result)))

;;;###autoload
(defun seml-xpath-single (xpath sexp &optional without-top)
  "Get one element at XPATH like specifiction from seml SEXP.
Supported XPATH more information, see `seml-xpath'.

When WITHOUT-TOP is non-nil, remove root tag."
  (declare (indent 1))
  (car (seml-xpath xpath sexp without-top)))

;;;###autoload
(defun seml-xpath-without-top (xpath sexp)
  "Call `seml-xpath' with without-top option (and call with XPATH SEXP)."
  (declare (indent 1))
  (seml-xpath xpath sexp t))

;;;###autoload
(defun seml-xpath-single-without-top (xpath sexp)
  "Call `seml-xpath-single' with without-top option (and call with XPATH SEXP)."
  (declare (indent 1))
  (seml-xpath-single xpath sexp t))

;;;###autoload
(defun seml-htmlize (majormode codestr &optional noindentp formatfn)
  "Return seml sexp formated CODESTR by Emacs fontlock on MAJORMODE.
optional:
  - NOINDENTP is non-nil, do not indent the entire buffer.
  - FORMATFN is function, executed before indent."
  (let ((source-buf (generate-new-buffer " *seml*"))
        (htmlize-buf) (result))
    (unwind-protect
        (progn
          (with-current-buffer source-buf
            (insert codestr)
            (funcall majormode)
            (font-lock-ensure)
            (when formatfn
              (funcall formatfn))
            (unless noindentp
              (ignore-errors
                (indent-region (point-min) (point-max)))))
          (setq htmlize-buf (htmlize-buffer source-buf))
          (setq result (seml-encode-html-from-buffer htmlize-buf)))
      (kill-buffer source-buf)
      (kill-buffer htmlize-buf))
    (car (seml-xpath '(pre) result))))

;;;###autoload
(defun seml-import (path)
  "Import external seml file at `seml-import-dir'/PATH."
  (let ((path path))
  (eval
   (read
    (with-temp-buffer
      (insert-file-contents (expand-file-name path seml-import-dir))
      (buffer-substring-no-properties (point-min) (point-max)))))))

;;;###autoload
(defun seml-expand-url (path baseurl)
  "Return expanded url base at BASEURL to PATH."
  (expand-file-name path baseurl))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Encode
;;

;;;###autoload
(defun seml-encode-html-from-region (start end)
  "Return SEML sexp encoded from region from START to END."
  (interactive "r")
  (let ((fn) (prep))
    (setq fn (lambda (x)
               (cond
                (prep
                 (cond
                  ((and (consp x) (not (seml-pairp x)))
                   `(,(cl-mapcan fn x)))
                  (t
                   `(,x))))
                ((and (consp x) (eq (car x) 'pre) (not (seml-pairp x)))
                 (prog2
                     (setq prep t)
                     (cond
                      ((and (consp x) (not (seml-pairp x)))
                       `(,(cl-mapcan fn x)))
                      ((stringp x)
                       (when (string-match-p "[[:graph:]]" x) `(,x)))
                      (t
                       `(,x)))
                   (setq prep nil)))
                ((and (consp x) (not (seml-pairp x)))
                 `(,(cl-mapcan fn x)))
                ((stringp x)
                 (when (string-match-p "[[:graph:]]" x) `(,x)))
                (t
                  `(,x)))))
    (cl-mapcan fn (libxml-parse-html-region start end))))

;;;###autoload
(defun seml-encode-html-from-string (str)
  "Return SEML sexp encoded from HTML STR."
  (with-temp-buffer
    (insert str)
    (seml-encode-html-from-region (point-min) (point-max))))

;;;###autoload
(defun seml-encode-html-from-buffer (&optional buf)
  "Return SEML sexp encoded from HTML BUF.
If omit BUF, use `current-buffer'."
  (with-current-buffer (or buf (current-buffer))
    (seml-encode-html-from-region (point-min) (point-max))))

;;;###autoload
(defun seml-encode-html-from-file (filepath)
  "Return SEML sexp encoded from html file located in FILEPATH."
  (let ((buf (generate-new-buffer " *seml-encode*")))
    (with-current-buffer buf
      (insert-file-contents filepath))
    (seml-encode-html-from-buffer buf)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Decode
;;

;;;###autoload
(defun seml-decode-seml-from-region (start end &optional doctype)
  "Return HTML string from buffer region at START to END.
If gives DOCTYPE, concat DOCTYPE at head."
  (seml-decode-seml-from-string (buffer-substring-no-properties start end) doctype))

;;;###autoload
(defun seml-decode-seml-from-sexp (sexp &optional doctype)
  "Return HTML decoded from seml SEXP.
If gives DOCTYPE, concat DOCTYPE at head."
  (let ((prop--fn (lambda (x)
                    (when x (format " %s=\"%s\"" (car x) (cdr x)))))
        (jade--fn (lambda (x)
                    (if (not (stringp x))
                        `(,x)
                      (let ((elms (split-string x "\\."))
                            (ret))
                        (when (string-match (rx bos "#" (group (* any))) (car elms))
                          (push `(id . ,(match-string 1 (car elms)))
                                ret)
                          (pop elms))
                        (when (and elms (string= (car elms) ""))
                          (pop elms))
                        (when elms
                          (push `(class . ,(mapconcat 'identity elms " "))
                                ret))
                        (nreverse ret)))))
        (decode-fn) (prep))
    (setq decode-fn
          (lambda (dom)
            (if (atom dom)
                dom
              (let* ((tag  (pop dom))
                     (prop (cl-mapcan jade--fn (pop dom)))
                     (rest dom)
                     (tagname (symbol-name tag)))
                (cond
                 (prep
                  (format "%s%s%s"
                          (format "<%s%s>" tagname (mapconcat prop--fn prop ""))
                          (mapconcat decode-fn rest "")
                          (format "</%s>" tagname)))
                 ((eq tag 'pre)
                  (prog2
                      (setq prep t)
                      (format "%s%s%s"
                              (format "<%s%s>" tagname (mapconcat prop--fn prop ""))
                              (mapconcat decode-fn rest "")
                              (format "</%s>" tagname))
                    (setq prep nil)))
                 ((eq tag 'top)
                  (format "%s"
                          (mapconcat decode-fn rest "\n")))
                 ((eq tag 'comment)
                  (format "<!--%s-->"
                          (mapconcat decode-fn rest "\n")))
                 ((memq tag seml-html-single-tags)
                  (format "%s"
                          (format "<%s%s>" tagname (mapconcat prop--fn prop ""))))
                 (t
                  (format "%s%s%s%s%s"
                          (format "<%s%s>" tagname (mapconcat prop--fn prop ""))
                          (if (< 1 (length rest)) "\n" "")
                          (mapconcat decode-fn rest "\n")
                          (if (< 1 (length rest)) "\n" "")
                          (format "</%s>" tagname))))))))
    (with-temp-buffer
      (and doctype (insert (concat doctype "\n")))
      (insert (funcall decode-fn sexp))
      (web-mode)
      (let ((web-mode-markup-indent-offset 2))
        (indent-region (point-min) (point-max)))
      (buffer-substring-no-properties (point-min) (point-max)))))

;;;###autoload
(defun seml-decode-seml-from-string (str &optional doctype)
  "Return HTML string decode from seml STR.
If gives DOCTYPE, concat DOCTYPE at head."
  (seml-decode-seml-from-sexp (eval (read str)) doctype))

;;;###autoload
(defun seml-decode-seml-from-buffer (&optional buf doctype)
  "Return HTML string decode from BUF.
If gives DOCTYPE, concat DOCTYPE at head."
  (seml-decode-seml-from-string
   (with-current-buffer (or buf (current-buffer))
     (buffer-string))
   doctype))

;;;###autoload
(defun seml-decode-seml-from-file (filepath &optional doctype)
  "Return HTML string decoded from seml file located in FILEPATH.
If gives DOCTYPE, concat DOCTYPE at head."
  (let ((buf (generate-new-buffer " *seml-decode*")))
    (with-current-buffer buf
      (insert-file-contents filepath))
    (seml-decode-seml-from-buffer buf doctype)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Replace
;;

;;;###autoload
(defun seml-replace-buffer-from-html ()
  "Replace buffer string HTML to SEML."
  (interactive)
  (let ((content (buffer-substring-no-properties (point-min) (point-max))))
    (erase-buffer)
    (insert (seml-to-string (seml-encode-html-from-string content)))
    (seml-mode)
    (indent-region (point-min) (point-max))))

;;;###autoload
(defun seml-replace-buffer-from-seml ()
  "Replace buffer string SEML to HTML."
  (interactive)
  (let ((content (buffer-substring-no-properties (point-min) (point-max))))
    (erase-buffer)
    (insert
     (seml-decode-seml-from-string content "<!DOCTYPE html>"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Live refresh (Google chrome on macOS only)
;;

(defvar seml-live-refresh-timer nil)
(defvar seml-live-refresh-baffer "")
(defvar seml-live-refresh-prev-sexp-history nil)

;;;###autoload
(defun seml-live-refresh-start ()
  "Start live refresh from buffer string (without saving)."
  (interactive)

  ;; register timer function
  (if seml-live-refresh-timer
      (message "Already live refresh enabled (Taget buffer: %s)"
               seml-live-refresh-baffer)
    (setq seml-live-refresh-baffer (buffer-name))
    (setq seml-live-refresh-timer
          (run-with-idle-timer
           seml-live-refresh-interval t 'seml-live-refresh-func))
    (message "Live refresh enabled (Taget buffer: %s)"
             seml-live-refresh-baffer))

  ;; defvar simple-httpd's variable
  (when seml-live-refresh-url-variable
    (mapc (lambda (x)
            (eval `(defvar ,(intern x) "")))
          `(,@(mapcar (lambda (y)
                        (replace-regexp-in-string "^:" "" y))
                      (split-string seml-live-refresh-url-variable "/"))
            ,@(mapcar #'symbol-name seml-live-refresh-url-quety))))

  ;; register servlet
  (eval `(defservlet*
           ,(intern (format "seml-mode/live-refresh/%s"
                            seml-live-refresh-url-variable))
           "text/html"
           (,@seml-live-refresh-url-quety)
           (insert (seml-decode-seml-from-buffer
                    seml-live-refresh-baffer "<!DOCTYPE html>")))))

(defun seml-live-refresh-stop ()
  "Stop live refresh."
  (interactive)
  (when seml-live-refresh-timer
    (setq seml-live-refresh-baffer "")
    (cancel-timer seml-live-refresh-timer)
    (setq seml-live-refresh-timer nil)))

(defun seml-live-refresh-func ()
  "Send refresh message to Google Chrome timer function.

Then, with activating target SEML buffer, `seml-live-refresh-start'
to register `servelet*' buffer and set timer function.

If you stop monitor SEML buffer, `seml-live-refresh-stop'.

~seml-mode.el~ send refresh message to Google Chrome...
1. When no error read and eval register buffer string,
2. When the evaled sexp differs from last time.
3. When Open ~seml-mode.el~ live-refresh page
   (http://localhost:8080/seml-mode/live-refresh)."
  (let ((fn (lambda (x)
              (save-excursion
                (with-current-buffer (get-buffer-create "*seml-live-refresh*")
                  (goto-char (point-max))
                  (when (< 10 (line-number-at-pos))
                    (erase-buffer))
                  (insert x)))))
        (url) (sexp))
    (condition-case err
        (progn
          (setq sexp (eval
                      (read
                       (with-current-buffer seml-live-refresh-baffer
                         (buffer-substring-no-properties (point-min) (point-max))))))
          (setq url (replace-regexp-in-string
                     "\n" ""
                     (shell-command-to-string
                      (mapconcat 'identity
                                 '("osascript -e"
                                   "'tell application \"/Applications/Google Chrome.app\""
                                   "to URL of active tab of window 1'") " "))))

          (cond ((equal sexp seml-live-refresh-prev-sexp-history)
                 (funcall fn (format "%s, Nothing to change, Abort\n"
                                     seml-live-refresh-baffer)))
                ((string-match "localhost.*seml-mode/live-refresh" url)
                 (setq seml-live-refresh-prev-sexp-history
                       (eval (read
                              (with-current-buffer seml-live-refresh-baffer
                                (buffer-substring-no-properties (point-min) (point-max))))))

                 (shell-command-to-string
                  (mapconcat 'identity
                             '("osascript -e"
                               "'tell application \"/Applications/Google Chrome.app\""
                               "to reload active tab of window 1'") " "))

                 (setq seml-live-refresh-prev-sexp-history sexp)
                 (funcall fn (format "%s, Success.\n"
                                     seml-live-refresh-baffer)))
                (t (funcall fn (format "%s, URL is %s, Abort.\n"
                                       seml-live-refresh-baffer url)))))
      
      (error (funcall fn (format "%s, Cannot eval, Abort. (Err msg: %s)\n"
                                 seml-live-refresh-baffer err))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Main
;;

;;;###autoload
(define-derived-mode seml-mode emacs-lisp-mode "SEML"
  "Major mode for editing SEML (S-Expression Markup Language) file."

  (set-syntax-table seml-mode-syntax-table)
  
  (set (make-local-variable 'lisp-indent-function) 'seml-indent-function))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.seml\\'" . seml-mode))
;;;###autoload
(add-to-list 'interpreter-mode-alist '("seml" . seml-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  font-lock
;;

;; (defvar seml-font-lock-keywords
;;   `(,(eval `(rx "(" (group (regexp ,seml-mode-keywords-regexp)) (* not-wordchar)
;;                 (or
;;                  (group "nil")
;;                  ;; (group "(" (+
;;                  ;;             (group (* not-wordchar)
;;                  ;;                    "(" (group (+? any)) "." (+? any) ")"
;;                  ;;                    (* not-wordchar)))
;;                  ;;        ")")
;;                  )))
;;     (1 font-lock-keyword-face)
;;     (2 font-lock-constant-face)
;;     ;; (5 font-lock-constant-face t)
;;     ))
;;
;; (font-lock-add-keywords 'seml-mode seml-font-lock-keywords)
(font-lock-add-keywords 'seml-mode
                        `((,(eval
                             `(rx "(" (group
                                       (regexp ,seml-mode-keywords-regexp)
                                       not-wordchar)))
                           (1 font-lock-keyword-face nil nil))))

(provide 'seml-mode)
;;; seml-mode.el ends here
