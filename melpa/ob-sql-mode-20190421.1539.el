;;; ob-sql-mode.el --- SQL code blocks evaluated by sql-mode -*- lexical-binding: t -*-

;; Copyright (C) 2016 Free Software Foundation, Inc.

;; Author: Nik Clayton nik@google.com
;; URL: http://github.com/nikclayton/ob-sql-mode
;; Package-Version: 20190421.1539
;; Package-Commit: b31a016585324ad91f1742ff6205bcb76f3ece6e
;; Version: 1.1
;; Package-Requires: ((emacs "24.4"))
;; Keywords: languages, org, org-babel, sql

;; This file is part of GNU Emacs.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Org-Babel support for evaluating SQL using sql-mode.
;;
;; Usage:
;;
;; Enter an Org SRC block that specifies sql-mode.
;;
;;   #+BEGIN_SRC sql-mode
;;   <enter query here>
;;   #+END_SRC
;;
;; You can also type "<Q[TAB]" to expand a template that does this
;; (change `org-babel-sql-mode-template-selector' to use a key other
;; than "Q" to select the template).
;;
;; Although all the statements in the block will be executed, only the
;; results from executing the final statement will be returned.
;;
;; Supported params.
;;
;; ":product productname" -- name of the product to use when evaluating
;;     the SQL.  Must be a value in `sql-product-alist'.  The default is
;;     given by the entry for ":product" in
;;     `org-babel-default-header-args:sql-mode'.
;;
;; ":session sessionname" -- name of the session to use when
;;     evaluating the SQL.  All SQL blocks that share the same product
;;     and session settings will be executed in the same comint
;;     buffer.  If blank then the session name is "none".
;;
;; Using Org property syntax you can set these on a per-file level with
;; a line like:
;;
;;     #+PROPERTY: header-args:sql-mode :product sqlite
;;     #+PROPERTY: header-args:sql-mode+ :session mysession
;;
;; Or in a per-heading property drawer
;;
;;     :PROPERTIES:
;;     :header-args:sql-mode :product sqlite
;;     :header-args:sql-mode+ :session mysession
;;     :END:
;;
;; (note the "+" on the second lines to append to the value -- you could
;; also place those on one line).
;;
;; Supported hooks.
;;
;; org-babel-sql-mode-pre-execute-hook
;;
;;     Hook functions take STATEMENTS, a list of SQL statements to
;;     execute, and PROCESSED-PARAMS.  A hook function should return
;;     nil, or a new list that replaces STATEMENTS.  Hooks run until
;;     the first one returns success.
;;
;;     Typical use: Modifying STATEMENTS depending on values in
;;     PROCESSED-PARAMS.
;;
;; org-babel-sql-mode-post-execute-hook
;;
;;     Hook functions take no arguments, and execute with the current
;;     buffer set to the buffer that contains the output from the
;;     query (so variables like `sql-product' are in scope).  Each
;;     hook function can make any changes it wants to the contents of
;;     the buffer.
;;
;;     Typical use: Cleaning up unwanted output from the buffer.
;;
;; Recommended user configuration:
;;
;; ;; Disable evaluation confirmation checks for sql-mode.
;; (setq org-confirm-babel-evaluate
;;       (lambda (lang body)
;;         (not (string= lang "sql-mode"))))
;;
;; Known problems / future work.
;;
;; [note: these problems might be due to my cursory familiarity with
;;  sql-mode]
;;
;; * Calls `sql-product-interactive' from `sql-mode' to start a
;;   session.  This then calls `pop-to-buffer' which displays the
;;   buffer.  This is unwanted, so the code currently temporarily
;;   redfines `pop-to-buffer'.  It would be better if `sql-mode'
;;   had a function that silently created the comint buffer.
;;
;; * The strategy for sending data to the comint process is
;;   suboptimal.
;;
;;   Broadly, there seem to be two ways to do it.
;;
;;   1. Keep the entered query as a multi-line string, and try and
;;      use `sql-send-region'.  But `sql-send-region' can't redirect
;;      into another buffer.
;;
;;   2. (current code) Calls `sql-redirect' to send the query and
;;      redirect the results to the session buffer.  But
;;      `sql-redirect' appears to want each statement to be a single
;;      line.  So the current code naively assumes it can split the
;;      string on ';', remove "--.*$", and then replace newlines with
;;      spaces to construct an acceptable statement.  This works, but
;;      is fragile.
;;
;; * Does nothing with Org :vars blocks.  I don't have a solid use for
;;   them yet.
;;
;; * Would be nice if there was a configuration option to include all
;;   the results, not just the result from the last statement.
;;   Requires changes to `sql-mode'.
;;
;; * Some mechanism to translate between the SQL results tables and
;;   Org table format would be interesting.
;;
;; * Doesn't support header params to specify things like the database
;;   user, password, connection params, and so on.  That's probably best
;;   left delegated to `sql-mode' and the various product feature options.

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'ob)
(require 'org)
(require 'sql)

(defcustom org-babel-sql-mode-start-interpreter-prompt
  (lambda (bufname buf product)
    (y-or-n-p (format "Interpreter not running in %s.  Start it? " bufname)))
  "Function to call if the buffer BUF called BUFNAME is not running PRODUCT.

If the function returns t then a buffer will be created, otherwise the
session will not be started."
  :group 'org-babel
  :safe t
  :type 'function)

(defcustom org-babel-sql-mode-template-selector
  "Q"
  "Character to enter after '<' to trigger template insertion."
  :group 'org-babel
  :safe t
  :type 'string)

(defcustom org-babel-default-header-args:sql-mode
  '((:product . "ansi"))
  "Default header args."
  :group 'org-babel
  :safe t)

(defvar org-babel-header-args:sql-mode
  '((:product . :any)
    (:session . :any)))

(defvar org-babel-sql-mode-pre-execute-hook nil
  "Hook for functions to be called before the query is executed.

Each function is called with two parameters, BODY is the text of
the SQL statements to be run.  PROCESSED-PARAMS is the parameters
to the code block.

The hook should return a new BODY modified in some way.")

(add-to-list 'org-babel-tangle-lang-exts '("sql-mode" . "sql"))

(with-eval-after-load "org"
  (add-to-list 'org-src-lang-modes '("sql-mode" . sql))
  (let* ((split-version (split-string org-version "\\."))
	 (org-major (string-to-number (nth 0 split-version)))
	 (org-minor (string-to-number (nth 1 split-version))))
    (if (or (and (= org-major 9)
		 (< org-minor 2))
	    (< org-major 9))
	(add-to-list 'org-structure-template-alist
		     `(,org-babel-sql-mode-template-selector
                       "#+BEGIN_SRC sql-mode ?\n\n#+END_SRC"
                       "#+BEGIN_SRC sql-mode ?\n\n#+END_SRC"))
      (add-to-list 'org-structure-template-alist
		   `(,org-babel-sql-mode-template-selector
		     . "src sql-mode")))))


;; On Windows systems the "-interactive" option is required, otherwise
;; output is buffered and Emacs never sees the prompt. See
;; https://write.as/nikclayton/missing-prompt-issues-with-sql-mode-and-sqlite-on-windows
(with-eval-after-load "sql"
  (if (eq system-type 'windows-nt)
      (add-to-list 'sql-sqlite-options "-interactive")))

(defun org-babel-execute:sql-mode (body params)
  "Execute the SQL statements in BODY using PARAMS."
  (let* ((processed-params (org-babel-process-params params))
         (session (cdr (assoc :session processed-params)))
         (session-proc (org-babel-sql-mode-initiate-session session processed-params))
         (sql-product (intern (cdr (assoc :product params))))
         (sql-prompt-regexp (sql-get-product-feature sql-product :prompt-regexp))
         (sql-prompt-cont-regexp (sql-get-product-feature sql-product :prompt-cont-regexp)))
    (with-temp-buffer
      (let ((adjusted-body (run-hook-with-args-until-success
                            'org-babel-sql-mode-pre-execute-hook
                            body processed-params)))
        (when adjusted-body
          (setq body adjusted-body)))
      (sql-redirect session-proc body (buffer-name) nil)
      (run-hooks 'org-babel-sql-mode-post-execute-hook)
      ;; The output may contain the prompt or (more likely) the continuation
      ;; prompt. Search for both and remove them.
      (save-match-data
	(goto-char (point-min))
	(while (re-search-forward sql-prompt-regexp nil t)
	  (replace-match "")))
	(goto-char (point-min))
	(while (re-search-forward sql-prompt-cont-regexp nil t)
	  (replace-match ""))
	(buffer-string))))

(defun org-babel-sql-mode-initiate-session (&optional session _params)
  "Return the comint buffer for this `SESSION'.

Determines the buffer from values in `PARAMS'."
  (let* ((bufname (org-babel-sql-mode--buffer-name _params))
         (sql-bufname (format "*SQL: %s*" bufname))
         (buf (get-buffer sql-bufname))
         (product (intern (cdr (assoc :product _params)))))
    (unless (assoc product sql-product-alist)
      (user-error "Product `%s' is not in `sql-product-alist'" product))
    (save-current-buffer
      (unless (sql-buffer-live-p buf product)
        (if (funcall org-babel-sql-mode-start-interpreter-prompt
		     sql-bufname buf product )
            ;; Temporarily redefine pop-to-buffer to do nothing, so
            ;; that when sql-product-interactive calls it nothing
            ;; happens.  Otherwise the frame is split to show the
            ;; interactive buffer, which is not wanted.
            (let ((old-pop-to-buffer (symbol-function 'pop-to-buffer)))
              (fset 'pop-to-buffer #'(lambda (&rest _r)))
              (sql-product-interactive product bufname)
              (fset 'pop-to-buffer old-pop-to-buffer))
          (user-error "Can't do anything without an SQL interactive buffer")))
      (get-buffer sql-bufname))))

(defun org-babel-sql-mode--buffer-name (params)
  "Return a buffer name to use for the `SESSION'.

The buffer name is (currently) derived from the :product and :session
keys in `PARAMS', but do not depend on this."
  (format "%s:%s" (cdr (assoc :product params))
          (cdr (assoc :session params))))

(provide 'ob-sql-mode)
;;; ob-sql-mode.el ends here
