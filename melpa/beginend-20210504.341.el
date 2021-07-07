;;; beginend.el --- Redefine M-< and M-> for some modes   -*- lexical-binding: t; -*-

;; Copyright (C) 2015-2021 Damien Cassou

;; Authors: Damien Cassou <damien@cassou.me>
;;          Matus Goljer <matus.goljer@gmail.com>
;; Version: 2.0.1
;; Package-Version: 20210504.341
;; Package-Commit: 4b4e4808dc3248ea61b3d8bdd7c6b73edd3b6902
;; URL: https://github.com/DamienCassou/beginend
;; Package-Requires: ((emacs "25.3"))
;; Created: 01 Jun 2015

;; This file is not part of GNU Emacs.

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

;; Redefine M-< and M-> for some modes.  For example,
;;
;; - in dired mode, M-< (respectively M->) goes to first (respectively last)
;;   file line
;;
;; - in message mode,
;;    - M-< goes to first line of message body (after headings)
;;    - M-> goes to last line before message signature
;;
;; - in prog-mode,
;;    - M-< goes to the first line after comments
;;    - M-> goes to the last line before comments
;;
;; Many more modes are supported.
;;
;;; Code:


(require 'cl-lib) ; for (setf (point) …)

;;; Helper code

(defun beginend--defkey (map command-begin command-end)
  "Bind \[beginning-of-buffer] and \[end-of-buffer] in MAP to COMMAND-BEGIN and COMMAND-END."
  (define-key map (vector 'remap 'beginning-of-buffer) command-begin)
  (define-key map (vector 'remap 'end-of-buffer) command-end))

(defun beginend--goto-nonwhitespace ()
  "Move point backward after the first non-whitespace character."
  (re-search-backward "[^[:space:]]" nil t)
  (forward-char))

(defun beginend--out-of-bounds-p (point)
  "Return non-nil if POINT is outside [`point-min', `point-max'].
This is possible if buffer was narrowed after POINT was stored."
  (not (<= (point-min) point (point-max))))

(defmacro beginend--double-tap (extremum &rest body)
  "Go to point EXTREMUM if executing BODY did not change point."
  (declare (debug (form body))
           (indent 1))
  (let ((oldpos-var (make-symbol "old-position"))
        (newpos-var (make-symbol "new-position"))
        (extremum-var (make-symbol "extremum")))
    `(let ((,oldpos-var (point))
           (,newpos-var nil)
           (,extremum-var ,extremum))
       (goto-char ,extremum-var)
       (save-restriction
         (widen)
         ,@body
         (setq ,newpos-var (point)))
       (if (or (beginend--out-of-bounds-p ,newpos-var)
               (= ,oldpos-var ,newpos-var))
           (goto-char ,extremum-var)
         (when (/= ,oldpos-var ,extremum-var)
           (push-mark ,oldpos-var))))))

(defmacro beginend--double-tap-begin (&rest body)
  "Evaluate BODY and go-to `point-min' if point did not move."
  (declare (debug (body)))
  `(beginend--double-tap (point-min)
     ,@body))

(defmacro beginend--double-tap-end (&rest body)
  "Evaluate BODY and go-to `point-max' if point did not move."
  (declare (debug (body)))
  `(beginend--double-tap (point-max)
     ,@body))

(defvar beginend-modes
  '((mu4e-view-mode-hook . beginend-message-mode)
    (mu4e-compose-mode-hook . beginend-message-mode))
  "List all beginend modes.
Each element has the form (STD-MODE-HOOK . BEGINEND-MODE).  STD-MODE-HOOK
is the standard mode hook (e.g., `dired-mode-hook') to which
BEGINEND-MODE (e.g., function `beginend-dired-mode') should be added.")

(defmacro beginend-define-mode (mode begin-body end-body)
  "Define a new beginend mode.
MODE is a name of an existing mode that should be adapted.

BEGIN-BODY and END-BODY are two `progn' expressions passed to respectively
`beginend--double-tap-begin' and `beginend--double-tap-end'."
  (declare (indent 1)
           (debug (symbolp ("progn" body) ("progn" body))))
  (let* ((mode-name (symbol-name mode))
         (hook (intern (format "%s-hook" mode-name)))
         (beginfunc-name (intern (format "beginend-%s-goto-beginning" mode-name)))
         (endfunc-name (intern (format "beginend-%s-goto-end" mode-name)))
         (map-name (intern (format "beginend-%s-map" mode-name)))
         (beginend-mode-name (intern (format "beginend-%s" mode-name))))
    `(progn
       (defun ,beginfunc-name ()
         ,(format "Go to beginning of buffer in `%s'." mode-name)
         (interactive)
         (beginend--double-tap-begin
          ,@(cdr begin-body)))
       (defun ,endfunc-name ()
         ,(format "Go to beginning of buffer in `%s'." mode-name)
         (interactive)
         (beginend--double-tap-end
          ,@(cdr end-body)))
       (defvar ,map-name
         (let ((map (make-sparse-keymap)))
           (beginend--defkey map #',beginfunc-name #',endfunc-name)
           map)
         ,(format "Keymap for beginend in `%s'." mode-name))
       (define-minor-mode ,beginend-mode-name
         ,(format "Mode for beginend in `%s'.\n\\{%s}" mode-name map-name)
         :lighter " be"
         :keymap ,map-name)
       (add-to-list 'beginend-modes
                    (cons ',hook
                          #',beginend-mode-name)))))


;;; Modes

(declare-function message-goto-body "message")

(beginend-define-mode message-mode
  (progn
    (message-goto-body))
  (progn
    (when (re-search-backward "^-- $" nil t)
      (beginend--goto-nonwhitespace))))

(declare-function dired-next-line "dired")
(declare-function dired-previous-line "dired")
(declare-function dired-get-filename "dired")
(declare-function dired-move-to-filename "dired")

(defun beginend--dired-on-file-p ()
  "Return non-nil if point is on a file.
`.' and `..' are not considered files."
  (ignore-errors (dired-get-filename 'no-dir)))

(beginend-define-mode dired-mode
  (progn
    (while (and (not (beginend--dired-on-file-p))
                (not (eobp)))
      (dired-next-line 1))
    (if (eobp)
        (goto-char (point-min))
      (dired-move-to-filename)))
  (progn
    (while (and (not (beginend--dired-on-file-p))
                (not (bobp)))
      (dired-previous-line 1))
    (if (bobp)
        (goto-char (point-max))
      (dired-move-to-filename))))

(beginend-define-mode occur-mode
  (progn
    (occur-next 1))
  (progn
    (occur-prev 1)))

(declare-function ibuffer-forward-line "ibuffer")
(declare-function ibuffer-backward-line "ibuffer")

(beginend-define-mode ibuffer-mode
  (progn
    (ibuffer-forward-line 1))
  (progn
    (ibuffer-backward-line 1)))

(declare-function vc-dir-next-line "vc-dir")
(declare-function vc-dir-previous-line "vc-dir")

(beginend-define-mode vc-dir-mode
  (progn
    (vc-dir-next-line 1))
  (progn
    (vc-dir-previous-line 1)))


(declare-function bs-up "bs")
(declare-function bs-down "bs")

(beginend-define-mode bs-mode
  (progn
    (bs-down 2))
  (progn
    (bs-up 1)
    (bs-down 1)))

(beginend-define-mode recentf-dialog-mode
  (progn
    (when (re-search-forward "^  \\[" nil t)
      (goto-char (match-beginning 0))
      (back-to-indentation)))
  (progn
    (re-search-backward "^  \\[" nil t)
    (back-to-indentation)))

(declare-function org-agenda-next-item "org-agenda")
(declare-function org-agenda-previous-item "org-agenda")

(beginend-define-mode org-agenda-mode
  (progn
    (org-agenda-next-item 1)
    (back-to-indentation))
  (progn
    (org-agenda-previous-item 1)
    (back-to-indentation)))

(declare-function compilation-next-error "compile")
(declare-function compilation-previous-error "compile")

(beginend-define-mode compilation-mode
  (progn
    (compilation-next-error 1))
  (progn
    (compilation-previous-error 1)))

(declare-function notmuch-search-first-thread "notmuch")
(declare-function notmuch-search-last-thread "notmuch")

(beginend-define-mode notmuch-search-mode
  (progn
    (notmuch-search-first-thread)
    (back-to-indentation))
  (progn
    (notmuch-search-last-thread)
    (back-to-indentation)))

(beginend-define-mode elfeed-search-mode
  (progn)
  (progn
    (forward-line -2)))

(declare-function prodigy-first "prodigy")
(declare-function prodigy-last "prodigy")

(beginend-define-mode prodigy-mode
  (progn
    (prodigy-first)
    (goto-char (line-beginning-position))
    (back-to-indentation))
  (progn
    (prodigy-last)
    (goto-char (line-beginning-position))
    (back-to-indentation)))

(declare-function magit-section-backward "magit-section")

(beginend-define-mode magit-status-mode
  (progn
    (re-search-forward "^$")
    (forward-line))
  (progn
    (magit-section-backward)
    (magit-section-backward)))

(declare-function magit-section-forward-sibling "magit-section")
(declare-function magit-section-match "magit-section")

(beginend-define-mode magit-revision-mode
  (progn
    (condition-case nil
        (while (not (or (eobp) (magit-section-match 'magit-file-section)))
          (magit-section-forward-sibling))
      (user-error (setf (point) (point-min)))))
  (progn
    (setf (point) (line-beginning-position))))

(beginend-define-mode deft-mode
  (progn
    (re-search-forward "^$")
    (forward-line))
  (progn
    (forward-line -1)))

(defun beginend--point-is-in-comment-p (&optional p)
  "Return non-nil if point is in comment.

If optional argument P is present test at that point instead of `point'."
  (setq p (or p (point)))
  (ignore-errors
    (save-excursion
      (or (nth 4 (syntax-ppss p))
          (eq (char-syntax (char-after p)) ?<)
          (let ((s (car (syntax-after p))))
            (when s
              (or (and (/= 0 (logand (lsh 1 16) s))
                       (nth 4 (syntax-ppss (+ p 2))))
                  (and (/= 0 (logand (lsh 1 17) s))
                       (nth 4 (syntax-ppss (+ p 1)))))))))))

(defun beginend--prog-mode-code-position-p ()
  "Return non-nil if point, at beginning of line, is inside code."
  (not
   (or (beginend--point-is-in-comment-p)
       (= (point) (line-end-position))
       (looking-at (char-to-string ?\f))))) ;; form-feed (^L)

(beginend-define-mode prog-mode
  (progn
    (while (not (or (eobp)
                    (beginend--prog-mode-code-position-p)))
      (forward-line)))
  (progn
    (while (not (or (bobp)
                    (beginend--prog-mode-code-position-p)))
      (forward-line -1))
    (goto-char (line-end-position))))

(declare-function outline-on-heading-p "outline")
(declare-function outline-next-visible-heading "outline")

(beginend-define-mode outline-mode
  (progn
    (unless (outline-on-heading-p)
      (outline-next-visible-heading 1)))
  (progn))

(declare-function org-on-heading-p "org")

(beginend-define-mode org-mode
  (progn
    (while (and (not (org-on-heading-p)) (not (eobp)))
      (forward-line))
    (when (eobp)
      (setf (point) (point-min))))
  (progn))

(declare-function nroam-goto "nroam")

(beginend-define-mode nroam-mode
  (progn
    (if (search-forward "#+title:" nil t)
        (forward-line)
      (setf (point) (point-min))))
  (progn
    (nroam-goto)))

(beginend-define-mode LaTeX-mode
  (progn
    (when (search-forward "\\begin{document}" nil t)
      (skip-chars-forward "\t\n\r ")))
  (progn
    (when (search-backward "\\end{document}" nil t)
      (skip-chars-backward "\t\n\r "))))

(beginend-define-mode latex-mode
  (progn
    (when (search-forward "\\begin{document}" nil t)
      (skip-chars-forward "\t\n\r ")))
  (progn
    (when (search-backward "\\end{document}" nil t)
      (skip-chars-backward "\t\n\r "))))

(declare-function rg-next-file "rg")
(declare-function rg-prev-file "rg")

(beginend-define-mode rg-mode
  (progn
    (rg-next-file 1))
  (progn
    (rg-prev-file 1)))

(beginend-define-mode epa-key-list-mode
  (progn
    (re-search-forward "^  [^ ] [^ ]" nil t)
    (backward-char))
  (progn
    (forward-line -1)
    (re-search-forward "^  [^ ] [^ ]" nil t)
    (backward-char)))



;;;###autoload
(defun beginend-setup-all ()
  "Use beginend on all compatible modes.
For example, this activates function `beginend-dired-mode' in `dired' and
function `beginend-message-mode' in `message-mode'.  All affected minor
modes are described in `beginend-modes'."
  (mapc (lambda (pair)
          (add-hook (car pair) (cdr pair)))
        beginend-modes))

;;;###autoload
(defun beginend-unsetup-all ()
  "Remove beginend from all compatible modes in `beginend-modes'."
  (mapc (lambda (pair)
          (remove-hook (car pair) (cdr pair)))
        beginend-modes))

;;;###autoload
(define-minor-mode beginend-global-mode
  "Toggle beginend mode.
Interactively with no argument, this command toggles the mode.  A positive
prefix argument enables the mode, any other prefix argument disables it.
From Lisp, argument omitted or nil enables the mode, `toggle' toggles the
state.

When beginend mode is enabled, modes such as `dired-mode', `message-mode'
and `compilation-mode' will have their \\[beginning-of-buffer] and
\\[end-of-buffer] keys adapted to go to meaningful places."
  :require 'beginend
  :lighter " be"
  :global t
  (if beginend-global-mode
      (beginend-setup-all)
    (beginend-unsetup-all)))


(provide 'beginend)

;;; beginend.el ends here

;;  LocalWords:  beginend whitespace
