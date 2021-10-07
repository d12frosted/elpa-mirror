;;; xref-rst.el --- Lookup reStructuredText symbols -*- lexical-binding: t -*-

;; Copyright (C) 2020  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://gitlab.com/ideasman42/emacs-xref-rst
;; Package-Version: 20211006.2319
;; Package-Commit: 4ca1c15e9fe98fadfb13098dd0ee104d5ca6abf2
;; Version: 0.1
;; Package-Requires: ((emacs "26.1"))

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

;; This package provides functions to lookup symbols under the cursor using xref.
;; Supported types include "doc", "ref" and file-paths (typically used in an index).

;;; Usage:

;; ;; Enable the Xref back-end in RST mode.
;; (add-hook 'rst-mode-hook (lambda ()
;;   (add-hook 'xref-backend-functions #'xref-rst-xref-backend nil t)))

;;; Code:


(require 'subr-x) ;; For `string-trim', `string-join'.
(require 'thingatpt) ;; For `thing-at-point-looking-at'.
(require 'vc) ;; For `vc-backend' and related functions.
(require 'xref) ;; For `xref' integration.
(require 'map) ;; For `map-elt'.


;; ---------------------------------------------------------------------------
;; Custom Variables

(defgroup xref-rst nil "Cross-reference (XREF) support for reStructuredText." :group 'xref)

;; Most uses should convert into a REGEX using `xref-rst--file-match-regex'
(defcustom xref-rst-extensions '(".rst" ".txt")
  "Extensions (must include the period character before the extension)."
  :type '(repeat string))

;; We must match last or second last groups here, annoying,
;; but I'm not sure there is a good way around this.
(defconst xref-rst--regex-any-role-data
  (concat
    ":\\([a-zA-Z0-9_]+\\):`"
    ;; Start group, only for "OR".
    "\\(?:"
    ;; With brackets.
    "[^<\n]*<\\([^>\n]+\\)>"
    ;; Or...
    "\\|"
    ;; Without brackets.
    "\\([^`\n]+\\)"
    ;; End non-matching group.
    "\\)`"))


(defconst xref-rst--regex-ref-declare
  (concat
    ;; Prefix.
    "\\(^[[:blank:]]*\\.\\.[[:blank:]]+_\\)"
    ;; Reference ID.
    "\\([a-zA-Z0-9_.\\-]+\\)"
    ;; End.
    ":"))

(defconst xref-rst--regex-glossary-directive
  (concat
    ;; White space prefix.
    "\\(^[[:blank:]]*\\)"
    ;; Prefix.
    "\\.\\.[[:blank:]]+"
    ;; Reference ID.
    "glossary"
    ;; End.
    "::"))


;; ---------------------------------------------------------------------------
;; Internal Functions (Generic)

(defun xref-rst--range-of-block-at-current-indent (pos)
  "Return the beginning/end point of lines at the indentation level of POS."
  (let
    (
      (beg nil)
      (end nil))
    (save-excursion
      (goto-char pos)
      (back-to-indentation)
      (let ((col (current-column)))
        (dolist (dir (list -1 1))
          (let ((last-pos pos))
            (while
              (and
                (zerop (forward-line dir))
                (progn
                  (back-to-indentation)
                  (eq col (current-column))))
              (setq last-pos (point)))
            (goto-char last-pos)
            (cond
              ((< dir 0)
                (setq beg (line-beginning-position)))
              (t
                (setq end (line-end-position))))))))
    (cons beg end)))

(defun xref-rst--find-next-indent-level-as-string (pos pos-end)
  "Find the next indent level at POS, that does not exceed POS-END.

Return the blank text representing the indentation or nil if none is found."
  (save-excursion
    (goto-char pos)
    (back-to-indentation)
    (let
      (
        (first-indent (current-column))
        (result nil))

      ;; Scan forward lines until we hit the next indentation level.
      (while
        (and
          (null result)
          ;; Stop when we hit the end of the buffer.
          (zerop (forward-line 1))
          ;; Don't read past this point.
          (< (point) pos-end))

        (let
          (
            (beg (line-beginning-position))
            (end (line-end-position)))

          ;; Skip blank lines.
          (unless (string-match-p "^[[:blank:]]*$" (buffer-substring-no-properties beg end))
            (back-to-indentation)

            (let ((current-indent (current-column)))
              (cond
                ;; Indented, set the result.
                ((> current-indent first-indent)
                  (setq result (buffer-substring-no-properties beg (point))))

                ;; Less indentation on non-blank line, early exit.
                ((< current-indent first-indent)
                  (setq result t)))))))

      ;; Only yield result if it's a string,
      ;; allow for true value to exit the loop but not return.
      (and (stringp result) result))))

(defun xref-rst--maybe-char-regex (str)
  "Return a regex for STR where each character is optionally matched."
  (let ((regex-list (list)))
    (dotimes (i (length str))
      (push (concat "\\(?:" (regexp-quote (char-to-string (aref str i))) "\\)?") regex-list))
    (string-join (nreverse regex-list))))


;; ---------------------------------------------------------------------------
;; Internal Functions (reStructuredText)

(defun xref-rst--is-point-in-glossary-body (pos)
  "Return t if POS is within the glossary body."
  (save-match-data
    (save-excursion
      (goto-char pos)
      (when (re-search-backward xref-rst--regex-glossary-directive nil t)
        ;; Ensure we're not on the glossary line.
        (when (> pos (line-end-position))
          (forward-line 1)
          (goto-char (line-beginning-position))
          (let*
            (
              (current-indent (match-string-no-properties 1))
              (glossary-end-pos
                (save-excursion
                  (cond
                    (
                      (re-search-forward
                        (concat "^" (xref-rst--maybe-char-regex current-indent) "[^[:blank:]\n]")
                        nil
                        t)
                      (point))
                    (t
                      (point-max))))))
            (<= pos glossary-end-pos)))))))

(defun xref-rst--regex-role-data-by-type (role-id)
  "Return the regular expression to match ROLE-ID."
  (concat
    ":" role-id ":`"
    ;; Start group, only for "OR".
    "\\(?:"
    ;; With brackets.
    "[^<\n]*<\\([^>\n]+\\)>"
    ;; Or...
    "\\|"
    ;; Without brackets.
    "\\([^`\n]+\\)"
    ;; End non-matching group.
    "\\)`"))


(defun xref-rst--file-match-regex ()
  "Return `xref-rst-extensions' as a file matching REGEX."
  ;; Converts:
  ;;    '(".rst" ".txt")
  ;; Into:
  ;;    "^[^.].*\\(\\.rst\\|\\.txt\\)\\'"
  ;;
  ;; Skip files starting with a dot (typically hidden/backup files).
  (concat "\\`[^.].*" "\\(" (mapconcat #'regexp-quote xref-rst-extensions "\\|") "\\)\\'"))

(defun xref-rst--dirs-recursive (root)
  "Recursively scan ROOT for RST files."
  (let ((rst-file-match-regex (xref-rst--file-match-regex)))
    (directory-files-recursively
      root rst-file-match-regex nil
      ;; Ignore hidden directories too.
      (lambda (dir) (not (string-equal "." (substring (file-name-nondirectory dir) 0 1)))))))

(defun xref-rst--project-vars (error-prefix)
  "Access project with ERROR-PREFIX for any errors."
  (let*
    (
      (buf
        (or
          (current-buffer)
          (user-error (concat error-prefix "current buffer not found, exiting!"))))
      (current-filepath
        (or
          (buffer-file-name buf)
          (user-error (concat error-prefix "current buffer has no path, exiting!"))))
      (current-dir
        (or
          (file-name-directory current-filepath)
          (user-error (concat error-prefix "unable to get directory name"))))

      (current-project-root
        (or
          ;; Sphinx convention.
          (locate-dominating-file current-dir "conf.py")

          ;; Base-dir from VC.
          (let ((vc-backend (ignore-errors (vc-responsible-backend current-filepath))))
            (when vc-backend
              (vc-call-backend vc-backend 'root current-filepath)))
          ;;
          (user-error (concat error-prefix "unable to find project root")))))

    (list current-project-root current-dir current-filepath)))


;; ---------------------------------------------------------------------------
;; Internal Functions (Find)

(defun xref-rst--lookup-ref (current-project-root rst-role-data)
  "Lookup the location of the 'ref' RST-ROLE-DATA in the CURRENT-PROJECT-ROOT."
  (let
    (
      (matches (list))
      (all-files
        (let ((case-fold-search t)) ;; Case insensitive search.
          (xref-rst--dirs-recursive current-project-root))))
    (with-temp-buffer
      (setq buffer-undo-list t)
      (set-buffer-multibyte nil)
      (let ((coding-system-for-read 'no-conversion))
        (dolist (rst-file-iter all-files)
          (insert-file-contents rst-file-iter)
          (goto-char (point-min))
          (while (re-search-forward xref-rst--regex-ref-declare nil t)
            (when (string-equal rst-role-data (match-string-no-properties 2))
              (let
                (
                  (bol (line-beginning-position))
                  (eol (line-end-position)))

                (push
                  (xref-rst--candidate
                    ;; Symbol.
                    rst-role-data
                    ;; Filename.
                    rst-file-iter
                    ;; Line number.
                    (1+ (count-lines (point-min) (match-beginning 0)))
                    ;; Column number.
                    (- (match-beginning 2) bol)
                    ;; Display text.
                    (buffer-substring-no-properties bol eol))
                  matches))))
          (erase-buffer))))
    matches))

(defun xref-rst--lookup-term (current-project-root rst-role-data)
  "Lookup the location of the 'term' RST-ROLE-DATA in the CURRENT-PROJECT-ROOT."
  (let
    (
      (matches (list))
      (all-files
        (let ((case-fold-search t)) ;; Case insensitive search.
          (xref-rst--dirs-recursive current-project-root))))

    (with-temp-buffer
      (setq buffer-undo-list t)
      (set-buffer-multibyte nil)
      (let ((coding-system-for-read 'no-conversion))
        (dolist (rst-file-iter all-files)
          (insert-file-contents rst-file-iter)
          (goto-char (point-min))
          (while (re-search-forward xref-rst--regex-glossary-directive nil t)
            (let*
              ( ;; Indent then term.
                (current-indent (match-string-no-properties 1))

                ;; Find the end of this glossary directive.
                ;; This is done by finding the same indent level, or less indention.
                ;; `xref-rst--maybe-char-regex' is used to search for lower levels of indentation.
                (glossary-end-pos
                  (save-excursion
                    (cond
                      (
                        (re-search-forward
                          (concat "^" (xref-rst--maybe-char-regex current-indent) "[^[:blank:]\n]")
                          nil
                          t)
                        (point))
                      (t
                        (point-max)))))

                ;; Although this should never be nil, there is some small chance it could be
                ;; if - for example there is odd mixing of tabs/spaces,
                ;; so use a fallback if it can't be detected.
                (next-indent (xref-rst--find-next-indent-level-as-string (point) glossary-end-pos))

                (term-regex
                  (concat
                    "^"
                    ;; Match indentation.
                    "\\("
                    ;; The next indent level, be exact so we don't match any of the body text.
                    ;;
                    ;; Fall back to any indent greater than the current indent
                    ;; while not perfect in that it may match the body text of the glossary,
                    ;; the chance it fails is very low, so it's not a bad fallback.
                    (cond
                      (next-indent
                        (regexp-quote next-indent))
                      (t
                        (concat (regexp-quote current-indent) "[[:blank:]]+")))
                    ;; End group.
                    "\\)"
                    ;; The term.
                    "\\(" (regexp-quote rst-role-data) "\\)"
                    ;; Allow for keys (they're ignored, but support finding entries with keys).
                    "\\([[:blank:]]*\\|[[:blank:]]+:[[:blank:]]+.*\\)$")))

              (when (re-search-forward term-regex glossary-end-pos t)
                (let
                  (
                    (bol (line-beginning-position))
                    (eol (line-end-position)))
                  (push
                    (xref-rst--candidate
                      ;; Symbol.
                      rst-role-data
                      ;; Filename.
                      rst-file-iter
                      ;; Line number.
                      (1+ (count-lines (point-min) (match-beginning 1)))
                      ;; Column number.
                      (- (match-beginning 2) bol)
                      ;; Display text.
                      (buffer-substring-no-properties bol eol))
                    matches)))

              (goto-char glossary-end-pos)))
          (erase-buffer))))
    matches))

(defun xref-rst--lookup-doc (current-project-root current-dir rst-role-data)
  "Lookup the location of the 'doc' RST-ROLE-DATA.

This is done relative to CURRENT-PROJECT-ROOT or CURRENT-DIR."
  (let*
    (
      (rst-filepath-no-ext
        (cond
          ((string-equal "/" (substring rst-role-data 0 1))
            (concat (file-name-as-directory current-project-root) (substring rst-role-data 1)))
          (t
            (concat (file-name-as-directory current-dir) rst-role-data 0 1))))
      (rst-file-part (file-name-nondirectory rst-role-data))
      (rst-dir-part (file-name-directory rst-filepath-no-ext))
      (rst-files-test (directory-files rst-dir-part t (concat "^" (regexp-quote rst-file-part))))
      (rst-filepath-found
        (catch 'result
          (let
            ( ;; Case insensitive extension comparison.
              (case-fold-search t)
              (rst-file-match-regex (xref-rst--file-match-regex)))
            (save-match-data
              (dolist (rst-test rst-files-test)
                (let ((rst-file-only (file-name-nondirectory rst-test)))
                  (when (string-match rst-file-match-regex rst-file-only)
                    ;; While it's unlikely, this could match a word
                    ;; that has extra characters at the end.
                    (when (zerop (match-beginning 0))
                      (throw 'result rst-test))))))))))

    (unless rst-filepath-found
      (user-error
        "Could not find a file: %S with extensions matching %S"
        rst-filepath-no-ext
        xref-rst-extensions))

    ;; Result (list of one).
    (list (xref-rst--candidate rst-role-data rst-filepath-found 1 0 ""))))

(defun xref-rst--find-definitions-impl (symbol)
  "Lookup SYMBOL, returning a list of matching items from `xref-rst--candidate'."
  (let
    (
      (error-prefix "RST-reference: ")
      (matches (list)))
    (pcase-let
      (
        (`(,current-project-root ,current-dir ,_current-filepath)
          (xref-rst--project-vars error-prefix)))

      (save-excursion
        (save-match-data
          (cond
            ;; Handle RST role, both:
            ;; - :role:`data`
            ;; - :role:`Text <data>`
            ((string-match xref-rst--regex-any-role-data symbol)
              (let
                (
                  (rst-role-id (match-string-no-properties 1 symbol))
                  (rst-role-data
                    (or
                      (match-string-no-properties 2 symbol)
                      (match-string-no-properties 3 symbol))))

                ;; Act on roles.
                (cond
                  ((string-equal rst-role-id "ref")
                    (setq matches (xref-rst--lookup-ref current-project-root rst-role-data)))

                  ((string-equal rst-role-id "term")
                    (setq matches (xref-rst--lookup-term current-project-root rst-role-data)))

                  ((string-equal rst-role-id "doc")
                    (setq matches
                      (xref-rst--lookup-doc current-project-root current-dir rst-role-data))))))

            ;; Not an RST role,
            ;; fall-back to looking up a file path as is used within an index.
            (t
              (let
                (
                  (rst-found-file
                    (concat
                      current-dir
                      ;; Extract "file.rst" from "Some Title <file.rst>".
                      ;; if this syntax is used in index listings.
                      (cond
                        ((string-match "[[:blank:]]+<\\(.*\\)>[[:blank:]]*$" symbol)
                          (match-string-no-properties 1 symbol))
                        (t
                          symbol)))))
                (unless (file-exists-p rst-found-file)
                  (user-error
                    (concat error-prefix "not over an RST role or filename at the cursor")))

                (push (xref-rst--candidate symbol rst-found-file 1 0 "") matches)))))))
    matches))


;; ---------------------------------------------------------------------------
;; Internal Functions (Usage)

(defun xref-rst--find-references-to-ref (symbol)
  "Lookup references to SYMBOL using the :ref: role."

  (let
    (
      (error-prefix "RST-reference-usage: ")
      (xrefs (list))
      (rst-role-data nil)
      (regex-ref-role-data (xref-rst--regex-role-data-by-type "ref")))

    (pcase-let
      (
        (`(,current-project-root ,_current-dir ,_current-filepath)
          (xref-rst--project-vars error-prefix)))

      ;; The current line is a role.

      ;; Find "ref" usage.
      (setq rst-role-data
        (save-match-data
          (when (string-match xref-rst--regex-ref-declare symbol)
            (match-string-no-properties 2 symbol))))

      (when rst-role-data
        (let
          (
            (all-files
              (let ((case-fold-search t)) ;; Case insensitive search.
                (xref-rst--dirs-recursive current-project-root))))
          (with-temp-buffer
            (setq buffer-undo-list t)
            (set-buffer-multibyte nil)
            (let ((coding-system-for-read 'no-conversion))
              (dolist (rst-file-iter all-files)
                (insert-file-contents rst-file-iter)
                (goto-char (point-min))
                (while (re-search-forward regex-ref-role-data nil t)
                  (when
                    (string-equal
                      rst-role-data
                      (or (match-string-no-properties 1) (match-string-no-properties 2)))
                    (let
                      (
                        (bol (line-beginning-position))
                        (eol (line-end-position)))
                      (push
                        (xref-make
                          ;; Display text.
                          (buffer-substring-no-properties bol eol)
                          ;; Location.
                          (xref-make-file-location
                            ;; File path:
                            rst-file-iter
                            ;; Line: +1 is important or we wont account
                            ;; for the newline directly before the ':ref:'.
                            (count-lines (point-min) (1+ (match-beginning 0)))
                            ;; Column: skip the ':ref:`'.
                            (+ 6 (- (match-beginning 0) bol))))
                        xrefs))))

                (erase-buffer))))

          (unless xrefs
            (user-error
              (concat
                error-prefix
                (format
                  "could not find any references to %S under %S within %d files!"
                  rst-role-data
                  current-project-root
                  (length all-files))))))

        ;; Show collected Xref list.
        xrefs))))


(defun xref-rst--find-references-to-term (symbol)
  "Lookup references to SYMBOL using the :term: role."

  (let
    (
      (error-prefix "RST-term-usage: ")
      (xrefs (list))
      (rst-terms-data nil)
      (regex-term-role-data (xref-rst--regex-role-data-by-type "term")))

    (pcase-let
      (
        (`(,current-project-root ,_current-dir ,_current-filepath)
          (xref-rst--project-vars error-prefix)))

      ;; First check we're in the glossary,
      ;; tsk, we need to get the surrounding context from the symbol.
      (let ((symbol-context (get-text-property 0 'xref-rst-context symbol)))
        (when symbol-context
          (pcase-let ((`(,symbol-buffer . ,symbol-point) symbol-context))
            (with-current-buffer symbol-buffer
              (when (xref-rst--is-point-in-glossary-body symbol-point)
                (pcase-let
                  ((`(,beg . ,end) (xref-rst--range-of-block-at-current-indent symbol-point)))
                  (setq rst-terms-data
                    (mapcar
                      (lambda (str)
                        (string-trim
                          ;; Ignore the "key".
                          (car (split-string str ":"))))
                      (split-string (buffer-substring-no-properties beg end) "\n")))))))))

      (when rst-terms-data
        (let
          (
            (rst-terms-data-regex
              (concat "\\(" (mapconcat #'regexp-quote rst-terms-data "\\|") "\\)"))
            (all-files
              (let ((case-fold-search t)) ;; Case insensitive search.
                (xref-rst--dirs-recursive current-project-root))))

          (with-temp-buffer
            (setq buffer-undo-list t)
            (set-buffer-multibyte nil)
            (let ((coding-system-for-read 'no-conversion))
              (dolist (rst-file-iter all-files)
                (insert-file-contents rst-file-iter)
                (goto-char (point-min))
                (while (re-search-forward regex-term-role-data nil t)
                  (when
                    (string-match-p
                      rst-terms-data-regex
                      (or (match-string-no-properties 1) (match-string-no-properties 2)))
                    (let
                      (
                        (bol (line-beginning-position))
                        (eol (line-end-position)))

                      (push
                        (xref-make
                          ;; Display text.
                          (buffer-substring-no-properties bol eol)
                          ;; Location.
                          (xref-make-file-location
                            ;; File path:
                            rst-file-iter
                            ;; Line: +1 is important or we wont account
                            ;; for the newline directly before the ':ref:'.
                            (count-lines (point-min) (1+ (match-beginning 0)))
                            ;; Column: skip the ':term:`'.
                            (+ 7 (- (match-beginning 0) bol))))
                        xrefs))))

                (erase-buffer)))

            (unless xrefs
              (user-error
                (concat
                  error-prefix
                  (format
                    "could not find any references to %S under %S within %d files!"
                    rst-terms-data
                    current-project-root
                    (length all-files)))))))

        ;; Show collected Xref list.
        xrefs))))

(defun xref-rst--find-references-impl (symbol)
  "Show usages of SYMBOL."
  (let ((xrefs (list)))

    (cond
      ;; found ':ref:'
      ((setq xrefs (xref-rst--find-references-to-ref symbol)))

      ;; found ':term:'
      ((setq xrefs (xref-rst--find-references-to-term symbol)))

      (t
        (user-error
          (concat
            "RST usage: "
            (format
              "unable to determine a reference type from %S"
              (substring-no-properties symbol))))))

    xrefs))


;; ---------------------------------------------------------------------------
;; Xref Utilities

;; Use for creating targets to display.
(defun xref-rst--candidate (symbol file line col line-text)
  "Return a candidate association-list.
This is built from SYMBOL, FILE, LINE, COL and a raw LINE-TEXT result."
  (list
    (cons 'file file)
    (cons 'line line)
    (cons 'column col)
    (cons 'symbol symbol)
    (cons 'match line-text)))


;; Use for finding links to this item.
(defun xref-rst--make-xref (candidate)
  "Return a new Xref object built from CANDIDATE."
  (xref-make
    (map-elt candidate 'match)
    (xref-make-file-location
      (map-elt candidate 'file)
      (map-elt candidate 'line)
      (map-elt candidate 'column))))


;; ---------------------------------------------------------------------------
;; Xref Back-End

(cl-defmethod xref-backend-identifier-at-point ((_backend (eql xref-rst)))
  "Return either an RST directive or a file name."
  (let
    (
      (symbol
        (save-match-data
          (cond
            ((thing-at-point-looking-at xref-rst--regex-any-role-data)
              (match-string-no-properties 0))
            (t
              (string-trim (thing-at-point 'line t)))))))

    (propertize symbol 'xref-rst-context (cons (current-buffer) (point)))))

(cl-defmethod xref-backend-definitions ((_backend (eql xref-rst)) symbol)
  "Find definitions of SYMBOL."
  (mapcar #'xref-rst--make-xref (xref-rst--find-definitions-impl symbol)))

(cl-defmethod xref-backend-references ((_backend (eql xref-rst)) symbol)
  "Show references to SYMBOL."
  (xref-rst--find-references-impl symbol))

(defun xref-rst-xref-backend ()
  "Xref-RST back-end for Xref."
  'xref-rst)

;;;###autoload
(define-minor-mode xref-rst-mode
  "Enable Xref for RST files."
  :global nil
  :lighter ""

  (cond
    (xref-rst-mode
      (add-hook 'xref-backend-functions #'xref-rst-xref-backend nil t))
    (t
      (remove-hook 'xref-backend-functions #'xref-rst-xref-backend t))))

(provide 'xref-rst)

;;; xref-rst.el ends here
