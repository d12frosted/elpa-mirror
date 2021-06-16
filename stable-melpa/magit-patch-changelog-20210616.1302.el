;;; magit-patch-changelog.el --- Generate a patch according to emacs-mirror/CONTRIBUTE -*- lexical-binding: t; coding: utf-8 -*-

;; Copyright (C) 2019 The Authors of magit-patch-changelog.el

;; Authors: dickmao <github id: dickmao>
;; Version: 0.1.0
;; Package-Version: 20210616.1302
;; Package-Commit: 623d1a6a3bfa0f01bcaaffa13ad5ce5ae29cdb0a
;; Keywords: git tools vc
;; URL: https://github.com/dickmao/magit-patch-changelog
;; Package-Requires: ((emacs "25.1") (magit "2.91.0"))

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with magit-patch-changelog.el.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Generate a patch according to emacs-mirror/CONTRIBUTE.

;;; Code:

(require 'magit)
(require 'magit-patch)

(defcustom magit-patch-changelog-fancy-xref nil
  "Jump to diff referenced by ChangeLog entry after idling one second."
  :group 'magit-patch-changelog
  :type 'boolean)

(defvar magit-patch-changelog-local-timer nil
  "Assigned as a buffer-local variable of COMMIT_EDITMSG.")

(defsubst magit-patch-changelog--forward-to-hunk ()
  "Move point to hunk, or stay if already in hunk.  Return t if successful."
  (cl-loop until (or (magit-section-match 'hunk)
                     (condition-case nil
                         (magit-section-forward)
                       (user-error t)))
           finally return (magit-section-match 'hunk)))

(defsubst magit-patch-changelog--within-diff ()
  "Return t if point is in a hunked diff block."
  (and (magit-section-match 'hunk)
       (let ((face (get-text-property (point) 'font-lock-face)))
         (or (eq 'magit-diff-removed-highlight face)
             (eq 'magit-diff-removed face)
             (eq 'magit-diff-added-highlight face)
             (eq 'magit-diff-added face)))))

(defsubst magit-patch-changelog--single-property-change (prop x direction limit)
  "`previous-single-property-change' is off-by-one coming and going.

Return position preceding character differing in PROP of X in
direction DIRECTION up to LIMIT.  By 'preceding' we mean positionally
after in the case direction is -1 and before if direction is +1."
  (let ((result
         (funcall (if (< direction 0)
                      #'previous-single-property-change
                    #'next-single-property-change)
                  (if (< direction 0) (min (1+ x) (point-max)) x)
                  prop nil limit)))
    (if (and result (< direction 0))
        (max (1- result) (point-min) limit)
      result)))

(defsubst magit-patch-changelog--next-face ()
  "Return first character with differening font-lock-face.

Or (point-max), whichever comes first."
  (magit-patch-changelog--single-property-change
   'font-lock-face (point) 1 (point-max)))

(defsubst magit-patch-changelog--move-next-face ()
  "Move point to first character with differing font-lock-face.

Or (point-max), whichever comes first."
  (goto-char (magit-patch-changelog--next-face)))

(defsubst magit-patch-changelog--forward-to-diff ()
  "Move point to diff, or stay if already in diff.

Return possibly updated point, nil if no more diffs."
  (when (magit-patch-changelog--forward-to-hunk)
    (cl-loop until (or (magit-patch-changelog--within-diff) (eobp))
             do (magit-patch-changelog--move-next-face)
             finally return (and (magit-patch-changelog--within-diff) (point)))))

(defun magit-patch-changelog-next-diff ()
  "Move point to next diff.  Return updated point if successful, nil otherwise."
  (let ((was-on-diff (magit-patch-changelog--within-diff)))
    (when (magit-patch-changelog--forward-to-diff)
      (when was-on-diff
        (magit-patch-changelog--move-next-face))
      (magit-patch-changelog--forward-to-diff))))

(defun magit-patch-changelog-next-defun (&optional previous)
  "Move point to next diffed defun after string PREVIOUS denoting a function.

Return next defun string if successful, nil otherwise."
  (cl-loop
   initially do (magit-patch-changelog--forward-to-diff)
   for next-defun =
   (cl-loop with next-defun-in-block
            with skip-lines = -1
            for line-start = (line-number-at-pos (point))
            for line-end = (line-number-at-pos (magit-patch-changelog--next-face))
            until (zerop skip-lines)
            do (pcase-let* ((`(,buf ,pos) (magit-diff-visit-file--noselect)))
                 (magit--with-temp-position buf pos
                   (setq next-defun-in-block (add-log-current-defun))
                   (if (string= next-defun-in-block previous)
                       (progn
                         (end-of-defun)
                         (end-of-defun)
                         (beginning-of-defun)
                         (setq skip-lines
                               (- (line-number-at-pos (point))
                                  (line-number-at-pos pos))))
                     (setq skip-lines 0)))
                 (kill-buffer buf))
            do (if (and (> skip-lines 0)
                        (< skip-lines (- line-end line-start)))
                   (forward-line skip-lines)
                 (setq skip-lines 0))
            finally return (and (not (string= previous next-defun-in-block))
                                next-defun-in-block))
   if next-defun
     return next-defun
   else
     unless (magit-patch-changelog-next-diff)
       return nil
     end
   end))

(defun magit-patch-changelog-add-log-insert (buffer file defun)
  "As `magit-commit-add-log-insert', and set text properties to xref diffs.

Write to BUFFER the ChangeLog entry \"* FILE (DEFUN):\"."
  (with-current-buffer (magit-get-mode-buffer 'magit-diff-mode)
    (when (stringp defun)
      (put-text-property 0 (length defun)
                         'magit-patch-changelog-loc (cons (current-buffer) (point))
                         defun)))
  (with-current-buffer buffer
    (undo-boundary)
    (goto-char (point-max))
    (while (re-search-backward (concat "^" comment-start) nil t))
    (save-restriction
      (narrow-to-region (point-min) (point))
      (cond ((re-search-backward (format "* %s\\(?: (\\([^)]+\\))\\)?: " file)
                                 nil t)
             (when (equal (match-string 1) defun)
               (setq defun nil))
             (re-search-forward ": "))
            (t
             (when (re-search-backward "^[\\*(].+\n" nil t)
               (goto-char (match-end 0)))
             (while (re-search-forward "^[^\\*\n].*\n" nil t))
             (let ((changelog-header (format "* %s " file)))
               (put-text-property 0 (length changelog-header)
                                  'magit-patch-changelog-header t
                                  changelog-header)
               (if defun
                   (progn (insert (format "%s(%s): \n" changelog-header defun))
                          (setq defun nil))
                 (insert (format "%s: \n" changelog-header))))
             (backward-char)
             (unless (looking-at "\n[\n\\']")
               (insert ?\n)
               (backward-char))))
      (when defun
        (forward-line)
        (let ((limit (save-excursion
                       (and (re-search-forward "^\\*" nil t)
                            (point)))))
          (unless (or (looking-back (format "(%s): " defun)
                                    (line-beginning-position))
                      (re-search-forward (format "^(%s): " defun) limit t))
            (while (re-search-forward "^[^\\*\n].*\n" limit t))
            (insert (format "(%s): \n" defun))
            (backward-char)))))))

(easy-mmode-defmap magit-patch-changelog-mode-map
                   '(("\M-." . magit-patch-changelog-xref)
                     ([M-down] . magit-patch-changelog-agg-down)
                     ([M-up] . magit-patch-changelog-agg-up))
                   "Keymap for the `magit-patch-changelog-mode'."
                   :group 'magit-patch)

(defun magit-patch-changelog--goto-ref (direction &optional limit)
  "Move point to next ChangeLog ref in DIRECTION up to LIMIT."
  (unless limit
    (setq limit (or (funcall (if (< direction 0)
                                 #'previous-single-property-change
                               #'next-single-property-change)
                             (point) 'magit-patch-changelog-header)
                    (if (< direction 0) (point-min) (point-max)))))
  (cl-block nil
    (let* ((orig (point))
           (on-ref-func (lambda (x) (get-text-property
                                     x 'magit-patch-changelog-loc)))
           (on-ref (funcall on-ref-func (point)))
           (change-p (lambda (x)
                       (and x (not (eq x limit)))))
           (next-change-func (lambda (x)
                               (magit-patch-changelog--single-property-change
                                'magit-patch-changelog-loc x direction limit))))
      (when on-ref
        (let ((nspc (funcall next-change-func (point))))
          (when (funcall change-p nspc)
            (goto-char nspc)
            (when (funcall on-ref-func nspc)
              (cl-return nspc)))))

      (let ((nspc (funcall next-change-func (point))))
        (if (funcall change-p nspc)
            (goto-char nspc)
          (goto-char orig)
          nil)))))

(defsubst magit-patch-changelog-string-trim-left (string &optional regexp)
  "Trim STRING of leading string matching REGEXP.

REGEXP defaults to \"[ \\t\\n\\r]+\"."
  (if (string-match (concat "\\`\\(?:" (or  regexp "[ \t\n\r]+")"\\)") string)
      (replace-match "" t t string)
    string))

(defun magit-patch-changelog--fixline (&optional triggering)
  "Patch up ChangeLog entry on current line.  Move point to TRIGGERING ref.

Returns nil if deleted line, t otherwise."
  (cl-block nil
    (save-excursion
      (beginning-of-line)
      (let* ((header-start (text-property-any
                            (point) (line-end-position)
                            'magit-patch-changelog-header t))
             (header-end (and header-start
                              (text-property-any
                               header-start (line-end-position)
                               'magit-patch-changelog-header nil)))
             (changelog-header (and header-start header-end
                                    (buffer-substring header-start header-end)))
             (line-end (line-end-position))
             (line-beg (line-beginning-position))
             changelog-refs
             next
             commentary)
        (save-excursion
          (unless (bobp) (backward-char))
          (while (setq next (magit-patch-changelog--goto-ref 1 line-end))
            (push (buffer-substring
                   next
                   (or (next-single-property-change
                        next 'magit-patch-changelog-loc)
                       (point-max)))
                  changelog-refs)))
        (save-excursion
          (end-of-line)
          (unless (eobp) (forward-char))
          (let ((begin-loc (previous-single-property-change
                            (point) 'magit-patch-changelog-loc
                            nil line-beg))
                (begin-header (previous-single-property-change
                               (point) 'magit-patch-changelog-header
                               nil line-beg)))
            (setq commentary (magit-patch-changelog-string-trim-left
                              (buffer-substring
                               (max begin-loc begin-header)
                               line-end) "[(,): ]+"))))
        (setq changelog-refs (nreverse changelog-refs))
        (kill-region line-beg (min (1+ line-end) (point-max)))
        (when changelog-header
          (insert changelog-header))
        (when changelog-refs
          (insert (format "(%s): " (mapconcat #'identity changelog-refs ", "))))
        (unless (zerop (length commentary))
          (insert commentary))
        (if (bolp)
            (cl-return nil)
          (insert "\n"))))
    (when triggering
      (when-let ((goto (text-property-any (line-beginning-position)
                                          (line-end-position)
                                          'magit-patch-changelog-loc
                                          (get-text-property
                                           0 'magit-patch-changelog-loc
                                           triggering))))
        (goto-char goto)))
    t))

(defsubst magit-patch-changelog-agg-up ()
  "Slurp ref upwards.

Move (foo, >b< ar) to (bar, foo).
Move (>f< oo, bar) to (foo)\n(bar)."
  (interactive)
  (magit-patch-changelog--agg -1))

(defsubst magit-patch-changelog-agg-down ()
  "Barf ref downwards.

Move (>f< oo, bar) to (bar, foo).
Move (foo, >b< ar) to (foo)\n(bar)."
  (interactive)
  (magit-patch-changelog--agg 1))

(defun magit-patch-changelog--agg (direction)
  "DIRECTION is -1 for up, and +1 for down."
  (if (get-text-property (point) 'magit-patch-changelog-loc)
      (let* ((header-tail
              (magit-patch-changelog--single-property-change
               'magit-patch-changelog-header (point) -1 (point-min)))
             (changelog-ref (thing-at-point 'symbol))
             (bounds (bounds-of-thing-at-point 'symbol))
             (next-line-p (if (< direction 0)
                              (lambda (x) (< x (line-beginning-position)))
                            (lambda (x) (> x (line-end-position)))))
             (insert-func (lambda (x) (if (< direction 0)
                                          (progn (forward-char)
                                                 (insert (format " %s " x)))
                                        (insert (format " %s " x))))))
        (let* ((next (save-excursion
                       (magit-patch-changelog--goto-ref direction)))
               (nextm (and next (copy-marker next)))
               (nextp (and nextm (funcall next-line-p (marker-position nextm))))
               (limit-func (lambda () (if (< direction 0)
                                          (line-beginning-position)
                                        (line-end-position))))
               (singleton-p (lambda ()
                              (and (not (save-excursion
                                          (magit-patch-changelog--goto-ref
                                           -1 (line-beginning-position))))
                                   (not (save-excursion
                                          (magit-patch-changelog--goto-ref
                                           1 (line-end-position)))))))
               (barf-p (lambda ()
                         (or (and (< direction 0)
                                  (not (save-excursion
                                         (magit-patch-changelog--goto-ref
                                          -1 (line-beginning-position)))))
                             (and (> direction 0)
                                  (not (save-excursion
                                         (magit-patch-changelog--goto-ref
                                          1 (line-end-position)))))))))
          (cl-macrolet ((jimmy
                         (goback)
                         `(progn
                            (setq ,goback (prog1 (copy-marker (point))
                                            (goto-char (marker-position ,goback))))
                            (magit-patch-changelog--fixline)
                            (goto-char (marker-position ,goback)))))
            ;; "Novice Emacs Lisp programmers often try to use the mark for
            ;; the wrong purposes. To remember a location for internal use,
            ;; store it in a Lisp variable."
            (let ((goback (copy-marker (point))))
              (cond ((and (not next) (funcall singleton-p)))
                    ((and (not next) (< direction 0)) ;; special case header fixup
                     (when header-tail
                       (apply #'kill-region (list (car bounds) (cdr bounds)))
                       (goto-char header-tail)
                       (funcall insert-func changelog-ref)
                       (magit-patch-changelog--fixline changelog-ref)
                       (jimmy goback)))
                    ((and (funcall barf-p) (not (funcall singleton-p)))
                     (apply #'kill-region (list (car bounds) (cdr bounds)))
                     (if (< direction 0)
                         (progn (beginning-of-line)
                                (insert "\n")
                                (forward-line -1)
                                (backward-char))
                       (end-of-line)
                       (insert "\n"))
                     (funcall insert-func changelog-ref)
                     (magit-patch-changelog--fixline changelog-ref)
                     (jimmy goback))
                    (t
                     (apply #'kill-region (list (car bounds) (cdr bounds)))
                     (goto-char (marker-position nextm))
                     (unless nextp
                       (goto-char (or (magit-patch-changelog--single-property-change
                                       'magit-patch-changelog-loc
                                       (marker-position nextm) direction
                                       (funcall limit-func))
                                      (funcall limit-func))))
                     (funcall insert-func changelog-ref)
                     (magit-patch-changelog--fixline changelog-ref)
                     (when nextp (jimmy goback))))))))
    (message "No ChangeLog data at point")))

(defsubst magit-patch-changelog--contains (prop)
  "Return first position with non-nil PROP on current line."
  (let ((line-end (line-end-position)))
    (save-excursion
      (beginning-of-line)
      (unless (bobp) (backward-char))
      (/= line-end
          (next-single-property-change
           (point) prop nil line-end)))))

(defun magit-patch-changelog-xref (&optional explicit-p)
  "Jump to diff referenced by text property `magit-patch-changelog-loc'.

EXPLICIT-P exploits the 'interactive p' trick to determine if called via [M-.].
Under EXPLICIT-P, jump to definition at point.  Otherwise, jump to definition of
first function reference on the line."
  (interactive "p")
  (let ((ref-point (if explicit-p
                       (point)
                     (let ((line-end (line-end-position)))
                       (save-excursion
                         (beginning-of-line)
                         (unless (bobp) (backward-char))
                         (magit-patch-changelog--goto-ref 1 line-end))))))
    (if-let ((loc (and ref-point
                       (get-text-property ref-point 'magit-patch-changelog-loc))))
        (cl-destructuring-bind (buf . pos) loc
          (let ((goback (selected-window))
                (magit-display-buffer-noselect nil))
            (magit-display-buffer buf)
            (with-current-buffer buf
              (goto-char pos)
              (set-window-start (get-buffer-window) (point)))
            (select-window goback)))
      (when explicit-p
        (message "No ChangeLog data at point")))))

(define-derived-mode magit-patch-changelog-mode text-mode "ChangeLog Edit"
  "Major mode manipulating parenthesized ChangeLog function references.

\\{magit-patch-changelog-mode-map}")

(defun magit-patch-changelog--commit-status ()
  "Return plist of (:face font-lock-face :content commit-output).

font-lock-face will be one of magit-process-ok, magit-process-ng, or nil."
  (with-current-buffer (magit-get-mode-buffer 'magit-status-mode)
    (with-current-buffer (magit-process-buffer t)
      (goto-char (point-max))
      (let (side-effect)
        (magit-section--backward-find
         (lambda ()
           (let ((section (magit-current-section)))
             (and (eq (oref section type) 'process)
                  (let* ((what (buffer-substring
                                (oref section start)
                                (or (oref section content)
                                    (oref section end))))
                         (commit (cl-second
                                  (split-string
                                   what
                                   (format "\\s-*%s\\s-*" magit-ellipsis)))))
                    (let (deactivate-mark)
                      (when (string-match-p "^commit" commit)
                        (setq side-effect
                              `(:content ,(buffer-substring-no-properties
                                           (or (oref section content)
                                               (oref section end))
                                           (oref section end))
                                         :face    ,(get-text-property
                                                    (oref section start)
                                                    'font-lock-face))))))))))
        side-effect))))

;;;###autoload
(defun magit-patch-changelog-create (args files)
  "Compress commits from current branch to master.

ARGS are `transient-args' from `magit-patch-create'.
Limit patch to FILES, if non-nil."
  (interactive
   (let ((args (transient-args 'magit-patch-create)))
     (list (-filter #'stringp args)
           (cdr (assoc "--" args)))))
  (let* ((feature-branch (magit-get-current-branch))
         (ephemeral-branch (make-temp-name (concat feature-branch "-")))
         (git-commit-major-mode 'magit-patch-changelog-mode)
         (cleanup
          (apply-partially
           (lambda (toplevel)
             (let ((default-directory toplevel))
               (when (timerp magit-patch-changelog-local-timer)
                 (cancel-timer magit-patch-changelog-local-timer)
                 (setq-local magit-patch-changelog-local-timer nil))
               (unless (string= feature-branch (magit-get-current-branch))
                 (magit-run-git "checkout" "-f" feature-branch))
               (when (magit-commit-p ephemeral-branch)
                 (magit-run-git "branch" "-D" ephemeral-branch))))
           (magit-toplevel)))
         (format-patch
          (lambda ()
            (unwind-protect
                (magit-with-toplevel
                  (cl-loop repeat 50
                           for status = (magit-patch-changelog--commit-status)
                           until (and status (plist-get status :face))
                           do (sit-for 0.1)
                           finally
                           (let ((avoid-incense
                                  (format "COMMIT_EDITMSG saved in %s"
                                          (directory-file-name (magit-git-dir))))
                                 (warning-buffer "*Magit ChangeLog*"))
                             (if status
                                 (if (eq (plist-get status :face)
                                         'magit-process-ng)
                                     (display-warning
                                      'magit-patch-changelog
                                      (format "\n%s\n%s"
                                              (plist-get status :content)
                                              avoid-incense)
                                      :error
                                      warning-buffer)
                                   (when (buffer-live-p (get-buffer warning-buffer))
                                     (kill-buffer warning-buffer))
                                   (magit-run-git
                                    "format-patch" "HEAD^" args "--" files)
                                   (when (member "--cover-letter" args)
                                     (message "Ignoring --cover-letter")))
                               (display-warning
                                'magit-patch-changelog
                                (format "Unknown commit status\n%s"
                                        avoid-incense)
                                :error
                                warning-buffer)))))
              (funcall cleanup))))

         ;; Dynamic-let of `git-commit-setup-hook' is closure-tidy.
         ;; But because `magit-commit-create' is async, closure needs to be
         ;; active until emacsclient returns.
         ;;
         ;; Considered: modifying `find-file-hook' to `add-hook' my goodies to
         ;; a LOCAL version of `git-commit-setup-hook'.

         (git-commit-setup-hook
          (append
           (default-value 'git-commit-setup-hook)
           `(,(lambda ()
                (when magit-patch-changelog-fancy-xref
                  (setq-local magit-patch-changelog-local-timer
                              (run-with-idle-timer 1 t #'magit-patch-changelog-xref)))
                (add-hook 'with-editor-post-finish-hook format-patch nil t)
                (add-hook 'with-editor-post-cancel-hook cleanup t t)
                (add-hook 'kill-emacs-hook cleanup)
                (dolist (hook '(with-editor-post-cancel-hook
                                with-editor-post-finish-hook))
                  (add-hook hook
                            (apply-partially #'remove-hook 'kill-emacs-hook cleanup)
                            nil t)))))))
    (condition-case err
        (progn
          (magit-branch-checkout ephemeral-branch "master")
          (magit-merge-assert)
          (magit-run-git "merge" "--squash" feature-branch)
          (cl-assert (memq 'magit-commit-diff server-switch-hook))
          (magit-commit-create)
          (cl-loop repeat 50
                   until (magit-commit-message-buffer)
                   do (accept-process-output nil 0.1)
                   finally
                   (unless (magit-commit-message-buffer)
                     (user-error "`magit-commit-create' failed")))
          (cl-loop with commit-buffer = (magit-commit-message-buffer)
                   repeat 50
                   for diff-buffer = (with-current-buffer commit-buffer
                                       (magit-get-mode-buffer 'magit-diff-mode))
                   until diff-buffer
                   do (accept-process-output nil 0.1)
                   finally
                   (if diff-buffer
                       (with-current-buffer diff-buffer
                         (goto-char (point-min))
                         (let* (my-current-defun
                                (magit-commit-add-log-insert-function
                                 'magit-patch-changelog-add-log-insert)
                                (add-log-current-defun-function
                                 (lambda () my-current-defun))
                                (magit--refresh-cache (list (cons 0 0))))
                           (while (setq my-current-defun
                                        (magit-patch-changelog-next-defun my-current-defun))
                             (cl-destructuring-bind (seconds num-gc seconds-gc)
                                 (benchmark-run (magit-commit-add-log))
                               (message (concat "%s: took %s seconds,"
                                                " with %s gc runs taking %s seconds")
                                        my-current-defun seconds num-gc seconds-gc)))))
                     (user-error "`magit-commit-diff' failed"))
                   (with-current-buffer commit-buffer
                     (let ((inhibit-message t))
                       (message (buffer-string))) ;; without this, point appears mid-buffer
                     (message "")              ;; without this, minibuffer explodes
                     (when with-editor-show-usage
                       (with-editor-usage-message))

                     ;; The variable `auto-fill-function' should be buffer local
                     ;; so this advise shouldn't pollute.
                     (when auto-fill-function
                       (add-function
                        :before-until (symbol-function auto-fill-function)
                        (lambda (&rest _args)
                          (and (eq major-mode 'magit-patch-changelog-mode)
                               (or (magit-patch-changelog--contains
                                    'magit-patch-changelog-header)
                                   (magit-patch-changelog--contains
                                    'magit-patch-changelog-loc))))))
                     (goto-char (point-min)))))
      (error (funcall cleanup)
             (user-error "%s" (error-message-string err))))))

(transient-append-suffix 'magit-patch-create "c"
  '("e" "Create patches for Emacs" magit-patch-changelog-create))

;;; _
(provide 'magit-patch-changelog)
;;; magit-patch-changelog.el ends here
