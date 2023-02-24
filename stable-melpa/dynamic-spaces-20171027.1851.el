;;; dynamic-spaces.el --- When editing, don't move text separated by spaces

;; Copyright (C) 2015-2017  Anders Lindgren

;; Author: Anders Lindgren
;; Created: 2015-09-10
;; Version: 0.0.0
;; Package-Version: 20171027.1851
;; Package-Commit: 97ae8480c257ba573ca3d06dbf602f9b23c41d38
;; Keywords: convenience
;; URL: https://github.com/Lindydancer/dynamic-spaces

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

;; When editing a text, and `dynamic-spaces-mode' is enabled, text
;; separated by more than one space doesn't move, if possible.
;; Concretely, end-of-line comments stay in place when you edit the
;; code and you can edit a field in a table without affecting other
;; fields.
;;
;; For example, this is the content of a buffer before an edit (where
;; `*' represents the cursor):
;;
;;     alpha*gamma         delta
;;     one two             three
;;
;; When inserting "beta" without dynamic spaces, the result would be:
;;
;;     alphabeta*gamma         delta
;;     one two             three
;;
;; However, with `dynamic-spaces-mode' enabled the result becomes:
;;
;;     alphabeta*gamma     delta
;;     one two             three

;; Usage:
;;
;; To enable *dynamic spaces* for all supported modes, add the
;; following to a suitable init file:
;;
;;     (dynamic-spaces-global-mode 1)
;;
;; Or, activate it for a specific major mode:
;;
;;     (add-hook 'example-mode-hook 'dynamic-spaces-mode)
;;
;; Alternatively, use `M-x customize-group RET dynamic-spaces RET'.

;; Space groups:
;;
;; Two pieces of text are considered different (and
;; `dynamic-spaces-mode' tries to keep then in place) if they are
;; separated by a "space group".  The following is, by default,
;; considered space groups:
;;
;; * A TAB character.
;;
;; * Two or more whitespace characters.
;;
;; However, the following are *not* considered space groups:
;;
;; * whitespace in a quoted string.
;;
;; * Two spaces, when preceded by a punctuation character and
;;   `sentence-end-double-space' is non-nil.
;;
;; * Two spaces, when preceded by a colon and `colon-double-space' is
;;   non-nil.

;; Configuration:
;;
;; You can use the following variables to modify the behavior or
;; `dynamic-spaces-mode':
;;
;; * `dynamic-spaces-mode-list' - List of major modes where
;;   dynamic spaces mode should be enabled by the global mode.
;;
;; * `dynamic-spaces-avoid-mode-list' - List of major modes where
;;   dynamic spaces mode should not be enabled.
;;
;; * `dynamic-spaces-global-mode-ignore-buffer' - When non-nil in a
;;   buffer, `dynamic-spaces-mode' will not be enabled in that buffer
;;   when `dynamic-spaces-global-mode' is enabled.
;;
;; * `dynamic-spaces-commands' - Commands that dynamic spaces mode
;;   should adjust spaces for.
;;
;; * `dynamic-spaces-keys' - Keys, in `kbd' format, that dynamic
;;   spaces mode should adjust spaces for.  (This is needed as many
;;   major modes define electric command and bind them to typical edit
;;   keys.)
;;
;; * `dynamic-spaces-find-next-space-group-function' - A function that
;;   would find the next dynamic space group.

;; Notes:
;;
;; By default, this is disabled for org-mode since it interferes with
;; the org mode table edit system.

;;; Code:

;; -------------------------------------------------------------------
;; Configuration variables.
;;

(defgroup dynamic-spaces nil
  "Adapt spaces when editing automatically."
  :group 'convenience)


(defcustom dynamic-spaces-mode-list
  '(prog-mode
    text-mode)
  "List of major modes where Dynamic-Spaces mode should be enabled.

When Dynamic-Spaces Global mode is enabled, Dynamic-Spaces mode is
enabled for buffers whose major mode is a member of this list, or
is derived from a member in the list.

See also `dynamic-spaces-avoid-mode-list'."
  :group 'dynamic-spaces
  :type '(repeat (symbol :tag "Major mode")))


(defcustom dynamic-spaces-avoid-mode-list
  '(org-mode)
  "List of major modes in which Dynamic-Spaces mode should not be enabled.

When Dynamic-Spaces Global mode is enabled, Dynamic-Spaces mode
is not enabled for buffers whose major mode is a member of this
list, or is derived from a member in the list.

This variable take precedence over `dynamic-spaces-mode-list'."
  :group 'dynamic-spaces
  :type '(repeat (symbol :tag "Major mode")))


(defvar dynamic-spaces-global-mode-ignore-buffer nil
  "When non-nil, stop global Dynamic-Spaces mode from enabling the mode.
This variable becomes buffer local when set in any fashion.")
(make-variable-buffer-local 'dynamic-spaces-global-mode-ignore-buffer)


(defcustom dynamic-spaces-commands '(delete-backward-char
                                     delete-char
                                     self-insert-command
                                     dabbrev-expand
                                     yank)
  "Commands that Dynamic-Spaces mode should adjusts spaces for."
  :group 'dynamic-spaces
  :type '(repeat function))


(defun dynamic-spaces-normalize-key-vector (v)
  "Normalize the key vector V to the form used by `this-single-command-keys'.

Currently, this replaces `escape' with the ASCII code 27."
  (let ((i 0))
    (while (< i (length v))
      (when (eq (elt v i) 'escape)
        (aset v i 27))
      (setq i (+ i 1)))))


(defun dynamic-spaces-convert-keys-to-vector (strs)
  "Return a list of vectors corresponding to the keys in STRS."
  (mapcar (lambda (s)
            (let ((key (read-kbd-macro s t)))
              (dynamic-spaces-normalize-key-vector key)
              key))
          strs))


(defcustom dynamic-spaces-keys '("C-d"
                                 "<deletechar>"
                                 "M-d"
                                 "<escape> d"
                                 "M-DEL"
                                 "<escape> <DEL>")
  "Keys that, in Dynamic-Spaces mode, adjust spaces.

This must be set before Dynamic-Spaces mode is enabled.

The main reason to allow keys, rather than commands, is to handle
the myriad of electric commands various major modes provide."
  :group 'dynamic-spaces
  :type '(repeat string))


(defvar dynamic-spaces-key--vectors '()
  "Keys that, in Dynamic-Spaces mode, adjust spaces, in vector format.

The format should be the same as returned by `this-single-command-keys'.

Do not set this variable manually, it is initialized from
`dynamic-spaces-key' when Dynamic-Spaces mode is enabled.")


(defcustom dynamic-spaces-pre-filter-functions
  '(dynamic-spaces-reject-in-string
    dynamic-spaces-reject-double-spaces)
  "List of functions that can reject a space group.

The functions are called without arguments with the point at the
end of the potential space group.  They should return non-nil
if the group should be rejected.  The functions should not move
the point."
  :group 'dynamic-spaces
  :type '(repeat function))


(defcustom dynamic-spaces-post-filter-once-functions
  '(dynamic-spaces-reject-in-string)
  "List of functions that can reject a space group after an edit.

The functions in the list are called once, before the space group
is adjusted.

The functions are called without arguments with the point at the
end of the space group.  They should return non-nil if the
group should be rejected.  The functions should not move the
point.

Use `add-hook' to add functions to this variable."
  :group 'dynamic-spaces
  :type '(repeat function))


(defcustom dynamic-spaces-post-filter-functions
  '(dynamic-spaces-reject-double-spaces)
  "List of functions that can reject a space group when shrinking spaces.

The functions in the list can be called multiple times, while the
space group is being adjusted.

The functions are called without arguments with the point at the
end of the space group.  They should return non-nil if the
group should be rejected.  The functions should not move the
point.

Use `add-hook' to add functions to this variable."
  :group 'dynamic-spaces
  :type '(repeat function))


(defcustom dynamic-spaces-find-next-space-group-function
  #'dynamic-spaces-find-next-space-group
  "A function used to find the next space group on the line.

The function is called without arguments and should place point
at the end of the space group and return non-nil when a group is
found."
  :group 'dynamic-spaces
  :type 'function)


(defcustom dynamic-spaces-find-next-space-group-alist '()
  "Alist from MODE to function to find next space group on line.

The first entry where `major-mode' is MODE, or derived from MODE,
is selected.  If no such mode exists use the value of
`dynamic-spaces-find-next-space-group-function'."
  :group 'dynamic-spaces
  :type '(repeat (cons (symbol :tag "Major mode")
                       function)))


;; -------------------------------------------------------------------
;; The modes
;;

;;;###autoload
(define-minor-mode dynamic-spaces-mode
  "Minor mode that adapts surrounding spaces when editing."
  :group 'dynamic-spaces
  (if dynamic-spaces-mode
      (progn
        (add-hook 'pre-command-hook  'dynamic-spaces-pre-command-hook  t t)
        (add-hook 'post-command-hook 'dynamic-spaces-post-command-hook nil t)
        (set (make-local-variable 'dynamic-spaces-key--vectors)
             (dynamic-spaces-convert-keys-to-vector dynamic-spaces-keys))
        (let ((tail dynamic-spaces-find-next-space-group-alist))
          (while tail
            (let ((pair (pop tail)))
              (when (derived-mode-p (car pair))
                (set (make-local-variable
                      'dynamic-spaces-find-next-space-group-function)
                     (cdr pair))
                ;; Break the loop.
                (setq tail '()))))))
    (remove-hook 'pre-command-hook  'dynamic-spaces-pre-command-hook  t)
    (remove-hook 'post-command-hook 'dynamic-spaces-post-command-hook t)))


(defun dynamic-spaces-activate-if-applicable ()
  "Turn on Dynamic-Spaces mode, if applicable.

Don't turn it on if `dynamic-spaces-global-mode-ignore-buffer' is non-nil."
  (when (and (not dynamic-spaces-global-mode-ignore-buffer)
             (apply #'derived-mode-p dynamic-spaces-mode-list)
             (not (apply #'derived-mode-p dynamic-spaces-avoid-mode-list)))
    (dynamic-spaces-mode 1)))


;;;###autoload
(define-global-minor-mode dynamic-spaces-global-mode dynamic-spaces-mode
  dynamic-spaces-activate-if-applicable
  :group 'dynamic-spaces)


;; -------------------------------------------------------------------
;; Pre- and post-command hooks.
;;


(defvar dynamic-spaces--space-groups nil
  "List of (MARKER . COLUMN) of space groups after point on current line.

MARKER and COLUMN refers to the first character after a group of spaces.

Information passed from Dynamic Spaces pre- to post command hook.")


(defvar dynamic-spaces--bol nil
  "Position of the beginning of a line before the command.

Information passed from Dynamic Spaces pre- to post command hook.")


(defvar dynamic-spaces--inside-space-group nil
  "Original point if point was inside a space group, or nil.

Information passed from Dynamic Spaces pre- to post command hook.")


(defvar dynamic-spaces--middle-of-two-space-group nil
  "Non-nil if point was in the middle of a space group of two spaces.")


;; (defvar dynamic-spaces--log nil)


(defun dynamic-spaces-line-end-position ()
  "Like `line-end-position' but aware of selective display."
  (if selective-display
      (save-excursion
        (if (search-forward "\r" (line-end-position) t)
            (- (point) 1)
          (line-end-position)))
    (line-end-position)))


(defun dynamic-spaces-middle-of-two-spaces ()
  "Non-nil if point is in the middle of space group consisting of two spaces."
  (and (eq (char-after) ?\s)
       (not (memq (char-after (+ (point) 1)) '(?\s ?\t)))
       (eq (char-before) ?\s)
       (not (memq (char-before (- (point) 1)) '(?\s ?\t)))))


(defun dynamic-spaces-pre-command-hook ()
  "Record the start of each space group.

This is typically attached to a local `pre-command-hook' and is
executed before each command."
  ;; Clear out old information, and recycle markers. (This isn't done
  ;; in `dynamic-spaces-post-command-hook' for the benefit if
  ;; `dynamic-spaces-view-space-group-print-source'.)
  (dynamic-spaces-recycle-marker-list dynamic-spaces--space-groups)
  (setq dynamic-spaces--space-groups '())
  (when (or (memq this-command dynamic-spaces-commands)
            (let ((keys (this-single-command-keys)))
              ;; (push keys dynamic-spaces--log)
              (or (member keys dynamic-spaces-key--vectors)
                  (and (eq (length keys) 1)
                       (let ((key (aref keys 0)))
                         ;; Printable characters and backspace.
                         (and (numberp key)
                              (>= key 32)
                              (<= key 127)))))))
    (setq dynamic-spaces--bol (line-beginning-position))
    (setq dynamic-spaces--space-groups (dynamic-spaces-find-space-groups))
    (setq dynamic-spaces--inside-space-group
          (and dynamic-spaces--space-groups
               (= (save-excursion
                    (skip-chars-forward " \t")
                    (point))
                  (car (car dynamic-spaces--space-groups)))
               (point)))
    (setq dynamic-spaces--middle-of-two-space-group
          (and dynamic-spaces--inside-space-group
               (dynamic-spaces-middle-of-two-spaces)))))


(defun dynamic-spaces-post-command-hook ()
  "Update space groups after a command."
  (when dynamic-spaces--space-groups
    (unless buffer-read-only
      (when (eq (line-beginning-position) dynamic-spaces--bol)
        (when (or
               ;; When deleting chars after the point inside a space
               ;; group it should shrink.
               (eq dynamic-spaces--inside-space-group
                   (point))
               ;; Special case: Point was in the middle of two spaces,
               ;; and text to the left has been deleted. Don't adjust
               ;; the space group, as this situation often occurs in
               ;; normal editing.
               (and dynamic-spaces--middle-of-two-space-group
                    (< (point) dynamic-spaces--inside-space-group)))
          (dynamic-spaces-recycle-marker (pop dynamic-spaces--space-groups)))
        (dynamic-spaces-adjust-space-groups-to
         dynamic-spaces--space-groups)))))


;; -------------------------------------------------------------------
;; The engine
;;

(defun dynamic-spaces-find-next-space-group ()
  "Go to end of next space group.

Return non-nil if one is found.

A space group starts either two whitespace characters or with a tab.

Ignore space groups rejected by `dynamic-spaces-pre-filter-functions'.

The point may move even if no group was found."
  (let (res)
    (when (memq (following-char) '(?\s ?\t))
      (skip-chars-backward " \t"))
    (while (and
            (setq res (re-search-forward "\\(  \\|\t\\)[ \t]*"
                                         (dynamic-spaces-line-end-position) t))
            ;; Reject cases like when two spaces are preceded by a
            ;; punctuation character and `sentence-end-double-space'
            ;; is non-nil.
            (run-hook-with-args-until-success
             'dynamic-spaces-pre-filter-functions)))
    res))


(defun dynamic-spaces-reject-in-string ()
  "Reject space group at point when in strings."
  (nth 3 (syntax-ppss)))


(defun dynamic-spaces-reject-double-spaces ()
  "Maybe reject double-space space groups when preceded by special characters.

If `sentence-end-double-space' is non-nil, reject space groups
preceded by `.', `!', or `?'.

If `colon-double-space' is non-nil, reject space groups preceded
by `:'."
  (and (eq (char-before (point))  ?\s)
       (eq (char-before (- (point) 1)) ?\s)
       (let ((ch (char-before (- (point) 2))))
         (and (or (and sentence-end-double-space
                       (memq ch '(?. ?! ??)))
                  (and colon-double-space
                       (eq ch ?:)))))))


(defvar dynamic-spaces--unused-markers '()
  "List or unused markers, used to avoid reallocation of markers.")


(defun dynamic-spaces-find-space-groups ()
  "List of (MARKER . COLUMN):s with space groups after the point."
  (save-excursion
    (let ((res '()))
      (while (funcall dynamic-spaces-find-next-space-group-function)
        (let ((marker (if dynamic-spaces--unused-markers
                          (pop dynamic-spaces--unused-markers)
                        (make-marker))))
          (set-marker marker (point))
          (push (cons marker (current-column)) res)))
      (nreverse res))))


(defun dynamic-spaces-space-group-before-p (pos)
  "True if POS is preceded by a space group."
  (and (or (eq (char-before pos) ?\t)
           (and (eq (char-before pos) ?\s)
                (memq (char-before (- pos 1)) '(?\s ?\t))))
       (save-excursion
         (goto-char pos)
         (not (run-hook-with-args-until-success
               'dynamic-spaces-post-filter-functions)))))


(defun dynamic-spaces-adjust-space-groups-to (space-groups)
  "Adjust space groups to the right of the point to match SPACE-GROUPS."
  (save-excursion
    (dolist (pair space-groups)
      (goto-char (car pair))
      (unless (run-hook-with-args-until-success
               'dynamic-spaces-post-filter-once-functions)
        ;; Note: There following does not check if the code has moved
        ;; to the right, but must be padded to retain a space group.
        ;; This ensures that inserting "x" in "alpha * beta" result in
        ;; "alpha x* beta" and not "alpha x*  beta".
        (while (let ((diff (- (cdr pair) (current-column))))
                 (cond ((< diff 0)
                        ;; The text has moved to the right, delete
                        ;; whitespace to compensate, and redo.
                        (cond ((eq (char-before) ?\t)
                               ;; Delete the \t and, possibly, insert
                               ;; two spaces to ensure that a space
                               ;; group is preserved.
                               ;;
                               ;; Ensure that markers before the tab
                               ;; (e.g. from the `save-excursion'
                               ;; above) and after (e.g. from
                               ;; `dynamic-spaces--space-groups') are
                               ;; preserved.
                               (backward-char)
                               (unless (dynamic-spaces-space-group-before-p
                                        (point))
                                 (insert "  "))
                               (delete-char 1)
                               t)
                              ((and (eq (char-before) ?\s)
                                    (dynamic-spaces-space-group-before-p
                                     (- (point) 1)))
                               (backward-delete-char 1)
                               t)
                              (t
                               nil)))
                       ((> diff 0)
                        ;; The text has moved to the left. Insert more
                        ;; space to compensate.
                        (insert (make-string diff ?\s))
                        nil)
                       (t
                        nil))))))))


(defun dynamic-spaces-recycle-marker-list (space-group-list)
  "Save markers in SPACE-GROUP-LIST to avoid excessive allocation."
  (dolist (space-group space-group-list)
    (dynamic-spaces-recycle-marker space-group)))


(defun dynamic-spaces-recycle-marker (space-group)
  "Save markers in SPACE-GROUP to avoid excessive allocation."
  (push (set-marker (car space-group) nil) dynamic-spaces--unused-markers))


;; -------------------------------------------------------------------
;; Debug support.
;;

(defun dynamic-spaces-view-space-group-print-source ()
  "Print information about current line and existing space groups."
  (save-excursion
    (princ dynamic-spaces--space-groups)
    (terpri)
    ;; `princ' doesn't preserve syntax highlighting.
    (let ((src (buffer-substring
                (line-beginning-position) (dynamic-spaces-line-end-position))))
      (with-current-buffer standard-output
        (insert src)))
    (terpri)
    ;; --------------------
    ;; Visualize point as "*"
    (princ (make-string (current-column) ?\s))
    (princ "*\n")
    ;; --------------------
    ;; Visualize space group. ("-" is a space, "T" a tab, and ">"
    ;; the extra space inserted by the tab.)
    (let ((col 0))
      (dolist (group dynamic-spaces--space-groups)
        (goto-char (car group))
        (skip-chars-backward " \t")
        (princ (make-string (- (current-column) col) ?\s))
        (setq col (current-column))
        (while (< (point) (car group))
          (if (eq (char-after) ?\s)
              (princ "-")
            (princ "T")
            (setq col (+ col 1))
            (princ (make-string (- (save-excursion
                                     (forward-char)
                                     (current-column))
                                   col)
                                ?>)))
          (forward-char)
          (setq col (current-column)))))
    (terpri)))


(defun dynamic-spaces-view-space-groups (key-sequence)
  "Display dynamic-space information about the current line.

Execute the command bound to KEY-SEQUENCE and displays the
current line (with meta information) before the command, after
the command but before adjustments, and after adjustments.

When executed interactively, the user is prompted for a key
sequence."
  (interactive
   (list (read-key-sequence "Press keys to run command")))
  (let ((dynamic-spaces-commands
         (cons 'dynamic-spaces-view-space-groups
               dynamic-spaces-commands)))
    (dynamic-spaces-pre-command-hook)
    (with-output-to-temp-buffer "*DynamicSpaces*"
      (princ (format "Beginning of line: %d\n" dynamic-spaces--bol))
      (princ (format "Is point inside space group: %s\n"
                     (if dynamic-spaces--inside-space-group
                         "yes"
                       "no")))
      (princ "\nSource before:\n")
      (dynamic-spaces-view-space-group-print-source)
      ;; --------------------
      ;; Run command.
      (let ((post-command-hook nil))
        (execute-kbd-macro key-sequence))
      (princ "\nSource after command, before adjustment:\n")
      (dynamic-spaces-view-space-group-print-source)
      ;; --------------------
      ;; After adjustment.
      (dynamic-spaces-post-command-hook)
      (princ "\nSource after adjustment:\n")
      (dynamic-spaces-view-space-group-print-source)
      ;; --------------------
      (display-buffer standard-output))))


;; -------------------------------------------------------------------
;; The end
;;

(provide 'dynamic-spaces)

;;; dynamic-spaces.el ends here
