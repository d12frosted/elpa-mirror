;;; hl-prog-extra.el --- Customizable highlighting for source-code -*- lexical-binding: t -*-

;; Copyright (C) 2021  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://gitlab.com/ideasman42/emacs-hl-prog-extra
;; Package-Version: 20211006.1402
;; Package-Commit: e8be12a44ee659d73cf934530adc58ab9a48e9dd
;; Keywords: convenience
;; Version: 0.1
;; Package-Requires: ((emacs "26.2"))

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

;; This package provides an easy way to highlight words in programming modes,
;; where terms can be highlighted on code, comments or strings.
;;

;;; Usage

;;
;; Write the following code to your .emacs file:
;;
;;   (require 'hl-prog-extra)
;;   (global-hl-prog-extra-mode)
;;
;; Or with `use-package':
;;
;;   (use-package hl-prog-extra)
;;   (global-hl-prog-extra-mode)
;;
;; If you prefer to enable this per-mode, you may do so using
;; mode hooks instead of calling `global-hl-prog-extra-mode'.
;; The following example enables this for org-mode:
;;
;;   (add-hook 'python-mode-hook
;;     (lambda ()
;;       (hl-prog-extra-mode)))
;;

;;; Code:

;; ---------------------------------------------------------------------------
;; Custom VarIables

(defgroup hl-prog-extra nil
  "Custom additional user-defined faces for comments/strings or code."
  :group 'faces)

;; Default to URL's and email addresses, avoid adding too many here
;; as users may want to extend to this list for their own purposes.
(defcustom hl-prog-extra-list
  (list
    ;; Match `http://xyz' (URL)
    '("\\bhttps?://[^[:blank:]]*" 0 comment font-lock-constant-face)
    ;; Match `<email@address.com>' email address.
    '("<\\([[:alnum:]\\._-]+@[[:alnum:]\\._-]+\\)>" 1 comment font-lock-constant-face)

    ;; Highlight `TODO` or `TODO(text): and similar.
    '
    ("\\<\\(TODO\\|NOTE\\)\\(([^)+]+)\\)?"
      0
      comment
      '(:background "#006000" :foreground "#FFFFFF"))
    '
    ("\\<\\(FIXME\\|XXX\\|WARNING\\|BUG\\)\\(([^)+]+)\\)?"
      0
      comment
      '(:background "#800000" :foreground "#FFFFFF")))
  "Lists that match faces (context face regex regex-group)

`regex':
  The regular expression to match.
`regex-subexpr':
  Group to use when highlighting the expression (zero for the whole match).
`context':
  A symbol in: 'comment, 'string or nil
  This limits the highlighting to only these parts of the text,
  where nil is used for anything that doesn't match a comment or string.
`face':
  The face to apply.

Modifying this while variable `hl-prog-extra-mode' is enabled requires calling
`hl-prog-extra-refresh'to update the internal state."
  :type
  '
  (repeat
    (list
      regexp integer
      (choice
        (const :tag "Comment" :value comment)
        (const :tag "String" :value string)
        (const :tag "Other" :value nil))
      face)))

(defcustom hl-prog-extra-global-ignore-modes nil
  "List of major-modes to exclude when `hl-prog-extra' has been enabled globally."
  :type '(repeat symbol))

(defvar-local hl-prog-extra-global-ignore-buffer nil
  "When non-nil, Global `hl-prog-extra' will not be enabled for this buffer.
This variable can also be a predicate function, in which case
it'll be called with one parameter (the buffer in question), and
it should return non-nil to make Global `hl-prog-extra' Mode not
check this buffer.")


;; ---------------------------------------------------------------------------
;; Internal Variables

(defvar-local hl-prog-extra--data nil
  "Internal data used for `hl-prog-extra--match' to do font locking.")


;; ---------------------------------------------------------------------------
;; Generic Utilities

(defun hl-prog-extra--match-first (match)
  "Return a the first valid group from MATCH and it's zero based index."
  (setq match (cddr match))
  (let ((i 0))
    (while (and match (null (car match)))
      (setq match (cddr match))
      (setq i (1+ i)))
    (cons match i)))

(defun hl-prog-extra--match-index-set (beg end index)
  "Set the match data from BEG to END at INDEX."
  (let ((gen-match (list beg end)))
    (dotimes (_ index)
      (setq gen-match (cons nil (cons nil gen-match))))
    (setq gen-match (cons beg (cons end gen-match)))
    (set-match-data gen-match)))

(defun hl-prog-extra--regexp-valid-or-error (re)
  "Return nil if RE is not a valid regexp."
  (condition-case err
    (prog1 nil
      (string-match-p re ""))
    (error (error-message-string err))))


;; ---------------------------------------------------------------------------
;; Pre-Compute Font Locking

(defun hl-prog-extra--precompute-keywords (face-vector)
  "Create data to pass to `font-lock-add-keywords' from FACE-VECTOR."
  ;; The generated result will look something like this.
  ;; (list
  ;;   (list
  ;;     'hl-prog-extra--match
  ;;     (cons 2 (list 'font-lock-string-face t t))
  ;;     (cons 1 (list 'font-lock-warning-face t t))
  ;;     (cons 0 (list 'font-lock-constant-face t t))
  ;;
  ;; Counting down is important so the first matching group that is met is used.
  (let ((keywords (list)))
    (dotimes (i (length face-vector))
      (let ((face (aref face-vector i)))

        ;; Without this, a face that is not yet loaded will raise an error in font lock.
        (when (and (symbolp face) (not (boundp face)))
          (setq face (list 'quote face)))

        ;; The first number is the regex-group to match (starting at 1).
        ;;
        ;; The two booleans after `face' are:
        ;; - Ignore error, this is important as the groups start with the highest number first.
        ;; - Counting down. If a match isn't met, keep looking and don't error.
        (push (cons (1+ i) (list face t t)) keywords)))

    (setq keywords (nreverse keywords))
    ;; Put the matching function at the head of the list.
    (push 'hl-prog-extra--match keywords)

    ;; There is only one highlighter at the moment.
    (list keywords)))

(defun hl-prog-extra--precompute-regex (syn-regex-list)
  "Pre-compute data from the SYN-REGEX-LIST.

Return (re-string face-table) where:

regex-string:
  A list of 3 strings containing grouped regex statements from SYN-REGEX-LIST.

`face-list':
  Unique faces.
`uniq-list':
  Unique data for each regex group.
`face-table':
  Map the regex group index to the `face-list'.

Tables are aligned with SYN-REGEX-LIST."
  (let ((len (length syn-regex-list)))
    (let
      ( ;; Group regex by the context they search in.
        (re-comment (list))
        (re-string (list))
        (re-rest (list))

        ;; Unique faces, use to build the arguments for font locking.
        (face-list (list))
        (face-list-contents (make-hash-table :test 'eq :size len))
        ;; Unique values aligned with the regex groups.
        ;; Each element be a list if other kinds of data needs to be referenced.
        (uniq-list (list))
        (uniq-list-contents (make-hash-table :test 'eql :size len))
        ;; Map the regex-group index to the face-list index.
        (face-table (list))

        ;; Error checking.
        (item-error-prefix "hl-prog-extra, error parsing `hl-prog-extra-list'")
        (item-index 0)
        (item-context-valid-items (list 'comment 'string nil)))

      (dolist (item syn-regex-list)
        (pcase-let ((`(,re ,re-subexpr ,context ,face) item))
          (let
            ( ;; Validate inputs.
              ;;
              ;; Be strict here since any errors on font-locking are difficult for users to debug.
              (has-error
                (cond
                  ;; Check `re'.
                  ((not (stringp re))
                    (message
                      "%s: 1st (regex) expected a string! (at %d)"
                      item-error-prefix
                      item-index)
                    t)
                  (
                    (let ((item-error (hl-prog-extra--regexp-valid-or-error re)))
                      (when item-error
                        (message
                          "%s: 1st (regex) invalid regex \"%s\" (at %d)"
                          item-error-prefix
                          item-error
                          item-index)
                        t))
                    t)

                  ;; Check `re-subexpr'.
                  ((not (integerp re-subexpr))
                    (message
                      "%s: 2nd (regex sub-expression) expected an integer! (at %d)"
                      item-error-prefix
                      item-index)
                    t)
                  ((< re-subexpr 0)
                    (message
                      "%s: 2nd (regex sub-expression) cannot be negative! (at %d)"
                      item-error-prefix
                      item-index)
                    t)

                  ;; Check `context'.
                  ((not (or (null context) (symbolp context)))
                    (message
                      "%s: 3rd expected a symbol or nil! (at %d)"
                      item-error-prefix
                      item-index)
                    t)
                  ((not (or (memq context item-context-valid-items)))
                    (message
                      "%s: 4th (context), unexpected symbol %S, expected %S or nil! (at %d)"
                      item-error-prefix
                      context
                      item-context-valid-items
                      item-index)
                    t)

                  ;; Check `face'
                  ((not (or (facep face) (listp face)))
                    (message
                      (concat
                        "%s: 4th (face) expected a symbol, string, face or "
                        "list of face properties. "
                        "%S is not known! (at %d)")
                      item-error-prefix face item-index)
                    t)

                  ;; No error.
                  (t
                    nil)))
              ;; End error checking.

              (uniq-index nil)
              (face-index nil))

            (unless has-error
              (when (and re-subexpr (zerop re-subexpr))
                (setq re-subexpr nil))

              (let ((key face))
                (setq face-index (gethash key face-list-contents))

                (unless face-index
                  (setq face-index (hash-table-count face-list-contents))
                  (push face face-list)
                  (puthash key face-index face-list-contents)))

              (let ((key (cons face re-subexpr)))
                (setq uniq-index (gethash key uniq-list-contents))
                (unless uniq-index
                  (setq uniq-index (hash-table-count uniq-list-contents))
                  (push re-subexpr uniq-list)
                  (puthash key uniq-index uniq-list-contents)
                  ;; Unrelated to maintaining `uniq-list-contents'.
                  (push face-index face-table)))

              (let ((regex-fmt (format "\\(?%d:%s\\)" (1+ uniq-index) re)))
                (cond
                  ((eq context 'comment)
                    (push regex-fmt re-comment))
                  ((eq context 'string)
                    (push regex-fmt re-string))
                  ((null nil)
                    (push regex-fmt re-rest))
                  (t ;; Checked for above.
                    (error "Invalid context %S" context)))))))
        (setq item-index (1+ item-index)))

      (list
        ;; Join all regex groups into single strings.
        (mapcar
          (lambda (re)
            (when re
              (mapconcat #'identity (nreverse re) "\\|")))
          (list re-comment re-string re-rest))

        (vconcat (nreverse face-list))
        (vconcat (nreverse uniq-list))
        (vconcat (nreverse face-table))))))


;; ---------------------------------------------------------------------------
;; Internal Font Lock Match

(defun hl-prog-extra--match (bound)
  "MATCHER for the font lock keyword in `hl-prog-extra--data', until BOUND."
  (let
    (
      (found nil)
      (state-at-pt (syntax-ppss))
      (state-at-pt-next nil)
      (info (car hl-prog-extra--data)))

    (pcase-let ((`(,`(,re-comment ,re-string ,re-rest) ,_ ,uniq-array ,face-table) info))
      (while (and (null found) (< (point) bound))
        (let
          (
            (re-context
              (cond
                ((nth 3 state-at-pt)
                  re-string)
                ((nth 4 state-at-pt)
                  re-comment)
                (t
                  re-rest))))

          ;; Only search in the current context.
          (cond
            (re-context
              (let
                (
                  (bound-context
                    (save-excursion
                      (setq state-at-pt-next
                        (parse-partial-sexp (point) bound nil nil state-at-pt 'syntax-table))
                      (point)))

                  (bound-context-clamp nil))

                ;; Without this, the beginning of a comment is seen as code,
                ;; in practice this means C-style comments such as `/*XXX*/',
                ;; end up considering the first two characters as code.
                ;; This causes problems if we want to highlight operators,
                ;; eg: `*' or `/' characters.
                ;; Avoid this by further clamping the context not to step
                ;; into the beginning of a comment or string.
                ;; Note that this introduces 'gaps', where the beginnings of
                ;; comments can't be matched.
                ;; Properly adjusting all beginnings and ends ends up being quite
                ;; complex since state isn't maintained between calls to this function.
                ;; So unless there is an important use-case for this, accept the limitation since
                ;; not being able to properly match symbols in code is a much larger limitation.
                (when (or (nth 3 state-at-pt-next) (nth 4 state-at-pt-next))
                  (let ((comment-or-string-start (nth 8 state-at-pt-next)))
                    (when (<= (point) comment-or-string-start)
                      (setq bound-context-clamp comment-or-string-start))))

                (cond
                  ((re-search-forward re-context (or bound-context-clamp bound-context) t)
                    (setq found t)
                    (pcase-let*
                      ( ;; The `uniq-index' is always needed so the original font can be found
                        ;; and so it's possible to check for a sub-expression.
                        (`(,match-tail . ,uniq-index) (hl-prog-extra--match-first (match-data)))
                        (`(,beg-final ,end-final) match-tail))

                      ;; When sub-expressions are used, they need to be extracted.
                      (let ((sub-expr (aref uniq-array uniq-index)))
                        (when sub-expr
                          (pcase-let ((`(,beg ,end) (nthcdr (* 2 sub-expr) match-tail)))
                            ;; The configuration may have an out of range `sub-expr'
                            ;; just ignore this and use the whole expression since raising
                            ;; an error during font-locking in this case isn't practical.
                            (when (and beg end)
                              (setq beg-final beg)
                              (setq end-final end)))))

                      ;; Remap the absolute table to the unique face.
                      (hl-prog-extra--match-index-set
                        (marker-position beg-final)
                        (marker-position end-final)
                        (aref face-table uniq-index)))

                    (when bound-context-clamp
                      ;; If the clamped bounds is met, step to the un-clamped bounds.
                      (when (>= (point) bound-context-clamp)
                        (goto-char bound-context))))

                  ;; Not found, skip to the next context.
                  (t
                    (goto-char bound-context)
                    (setq state-at-pt state-at-pt-next)))))

            ;; Nothing to search for, simply skip over this context.
            (t
              (setq state-at-pt
                (parse-partial-sexp (point) bound nil nil state-at-pt 'syntax-table)))))))
    found))


;; ---------------------------------------------------------------------------
;; Define Minor Mode

(defun hl-prog-extra-mode-enable ()
  "Turn on option `hl-prog-extra-mode' for the current buffer."
  ;; Paranoid.
  (when hl-prog-extra--data
    (font-lock-remove-keywords nil (cdr hl-prog-extra--data)))

  (let ((info (hl-prog-extra--precompute-regex hl-prog-extra-list)))
    (let ((keywords (hl-prog-extra--precompute-keywords (nth 1 info))))
      (font-lock-add-keywords nil keywords 'append)
      (font-lock-flush)
      (setq hl-prog-extra--data (cons info keywords)))))

(defun hl-prog-extra-mode-disable ()
  "Turn off option `hl-prog-extra-mode' for the current buffer."
  (when hl-prog-extra--data
    (font-lock-remove-keywords nil (cdr hl-prog-extra--data))
    (font-lock-flush))
  (kill-local-variable 'hl-prog-extra--data))

;;;###autoload
(defun hl-prog-extra-refresh ()
  "Update internal data after changing `hl-prog-extra-list'."
  (when hl-prog-extra--data
    (hl-prog-extra-mode-disable)
    (hl-prog-extra-mode-enable)))

;;;###autoload
(define-minor-mode hl-prog-extra-mode
  "Highlight matches for `hl-prog-extra-list' in comments, strings and code."
  :lighter ""
  :keymap nil

  (cond
    (hl-prog-extra-mode
      (hl-prog-extra-mode-enable))
    (t
      (hl-prog-extra-mode-disable))))

(defun hl-prog-extra--mode-turn-on ()
  "Enable the option `hl-prog-extra-mode' where possible."
  (when
    (and
      ;; Not already enabled.
      (not hl-prog-extra-mode)
      ;; Not in the mini-buffer.
      (not (minibufferp))
      ;; Not a special mode (package list, tabulated data ... etc)
      ;; Instead the buffer is likely derived from `text-mode' or `prog-mode'.
      (not (derived-mode-p 'special-mode))
      ;; Not explicitly ignored.
      (not (memq major-mode hl-prog-extra-global-ignore-modes))
      ;; Optionally check if a function is used.
      (or
        (null hl-prog-extra-global-ignore-buffer)
        (cond
          ((functionp hl-prog-extra-global-ignore-buffer)
            (not (funcall hl-prog-extra-global-ignore-buffer (current-buffer))))
          (t
            nil))))
    (hl-prog-extra-mode 1)))

;;;###autoload
(define-globalized-minor-mode
  global-hl-prog-extra-mode
  hl-prog-extra-mode
  hl-prog-extra--mode-turn-on)

(provide 'hl-prog-extra)
;;; hl-prog-extra.el ends here
