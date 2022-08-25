;;; virtual-auto-fill.el --- Readably display text without adding line breaks -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Free Software Foundation, Inc.

;; Author: Luis Gerhorst <virtual-auto-fill@luisgerhorst.de>
;; Maintainer: Luis Gerhorst <virtual-auto-fill@luisgerhorst.de>
;; URL: https://github.com/luisgerhorst/virtual-auto-fill
;; Package-Version: 20200906.2038
;; Package-Commit: a3991ce02d9a6a1624a3f04da80f4ac966a44092
;; Keywords: convenience, mail, outlines, files, wp
;; Created: Sun 26. Jan 2020
;; Version: 0.1
;; Package-Requires: ((emacs "25.2") (adaptive-wrap "0.7") (visual-fill-column "1.9"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Virtual Auto Fill mode displays unfilled text in a readable way.  It wraps
;; the text as if you had inserted line breaks (e.g. using `fill-paragraph' or
;; `auto-fill-mode') without actually modifying the underlying buffer.  It also
;; indents paragraphs in bullet lists properly.
;;
;; Specifically, `adaptive-wrap-prefix-mode', Visual Fill Column mode and
;; `visual-line-mode' are used to wrap paragraphs and bullet lists between the
;; wrap prefix and the fill column.

;;; Code:

(require 'adaptive-wrap)
(require 'visual-fill-column)

;; To support Emacs versions < 26.1, which added `read-multiple-choice', we
;; include a copy of the function from rmc.el here.
(defun virtual-auto-fill--read-multiple-choice (prompt choices)
  "Ask user a multiple choice question.
PROMPT should be a string that will be displayed as the prompt.

CHOICES is an alist where the first element in each entry is a
character to be entered, the second element is a short name for
the entry to be displayed while prompting (if there's room, it
might be shortened), and the third, optional entry is a longer
explanation that will be displayed in a help buffer if the user
requests more help.

This function translates user input into responses by consulting
the bindings in `query-replace-map'; see the documentation of
that variable for more information.  In this case, the useful
bindings are `recenter', `scroll-up', and `scroll-down'.  If the
user enters `recenter', `scroll-up', or `scroll-down' responses,
perform the requested window recentering or scrolling and ask
again.

When `use-dialog-box' is t (the default), this function can pop
up a dialog window to collect the user input.  That functionality
requires `display-popup-menus-p' to return t. Otherwise, a text
dialog will be used.

The return value is the matching entry from the CHOICES list.

Usage example:

\(virtual-auto-fill--read-multiple-choice \"Continue connecting?\"
                      \\='((?a \"always\")
                        (?s \"session only\")
                        (?n \"no\")))"
  (let* ((altered-names nil)
         (full-prompt
          (format
           "%s (%s): "
           prompt
           (mapconcat
            (lambda (elem)
              (let* ((name (cadr elem))
                     (pos (seq-position name (car elem)))
                     (altered-name
                      (cond
                       ;; Not in the name string.
                       ((not pos)
                        (format "[%c] %s" (car elem) name))
                       ;; The prompt character is in the name, so highlight
                       ;; it on graphical terminals...
                       ((display-supports-face-attributes-p
                         '(:underline t) (window-frame))
                        (setq name (copy-sequence name))
                        (put-text-property pos (1+ pos)
                                           'face 'read-multiple-choice-face
                                           name)
                        name)
                       ;; And put it in [bracket] on non-graphical terminals.
                       (t
                        (concat
                         (substring name 0 pos)
                         "["
                         (upcase (substring name pos (1+ pos)))
                         "]"
                         (substring name (1+ pos)))))))
                (push (cons (car elem) altered-name)
                      altered-names)
                altered-name))
            (append choices '((?? "?")))
            ", ")))
         tchar buf wrong-char answer)
    (save-window-excursion
      (save-excursion
        (while (not tchar)
          (message "%s%s"
                   (if wrong-char
                       "Invalid choice.  "
                     "")
                   full-prompt)
          (setq tchar
                (if (and (display-popup-menus-p)
                         last-input-event ; not during startup
                         (listp last-nonmenu-event)
                         use-dialog-box)
                    (x-popup-dialog
                     t
                     (cons prompt
                           (mapcar
                            (lambda (elem)
                              (cons (capitalize (cadr elem))
                                    (car elem)))
                            choices)))
                  (condition-case nil
                      (let ((cursor-in-echo-area t))
                        (read-char))
                    (error nil))))
          (setq answer (lookup-key query-replace-map (vector tchar) t))
          (setq tchar
                (cond
                 ((eq answer 'recenter)
                  (recenter) t)
                 ((eq answer 'scroll-up)
                  (ignore-errors (scroll-up-command)) t)
                 ((eq answer 'scroll-down)
                  (ignore-errors (scroll-down-command)) t)
                 ((eq answer 'scroll-other-window)
                  (ignore-errors (scroll-other-window)) t)
                 ((eq answer 'scroll-other-window-down)
                  (ignore-errors (scroll-other-window-down)) t)
                 (t tchar)))
          (when (eq tchar t)
            (setq wrong-char nil
                  tchar nil))
          ;; The user has entered an invalid choice, so display the
          ;; help messages.
          (when (and (not (eq tchar nil))
                     (not (assq tchar choices)))
            (setq wrong-char (not (memq tchar '(?? ?\C-h)))
                  tchar nil)
            (when wrong-char
              (ding))
            (with-help-window (setq buf (get-buffer-create
                                         "*Multiple Choice Help*"))
              (with-current-buffer buf
                (erase-buffer)
                (pop-to-buffer buf)
                (insert prompt "\n\n")
                (let* ((columns (/ (window-width) 25))
                       (fill-column 21)
                       (times 0)
                       (start (point)))
                  (dolist (elem choices)
                    (goto-char start)
                    (unless (zerop times)
                      (if (zerop (mod times columns))
                          ;; Go to the next "line".
                          (goto-char (setq start (point-max)))
                        ;; Add padding.
                        (while (not (eobp))
                          (end-of-line)
                          (insert (make-string (max (- (* (mod times columns)
                                                          (+ fill-column 4))
                                                       (current-column))
                                                    0)
                                               ?\s))
                          (forward-line 1))))
                    (setq times (1+ times))
                    (let ((text
                           (with-temp-buffer
                             (insert (format
                                      "%c: %s\n"
                                      (car elem)
                                      (cdr (assq (car elem) altered-names))))
                             (fill-region (point-min) (point-max))
                             (when (nth 2 elem)
                               (let ((start (point)))
                                 (insert (nth 2 elem))
                                 (unless (bolp)
                                   (insert "\n"))
                                 (fill-region start (point-max))))
                             (buffer-string))))
                      (goto-char start)
                      (dolist (line (split-string text "\n"))
                        (end-of-line)
                        (if (bolp)
                            (insert line "\n")
                          (insert line))
                        (forward-line 1)))))))))))
    (when (buffer-live-p buf)
      (kill-buffer buf))
    (assq tchar choices)))

;; When available however, use the default `read-multiple-choice'.
(require 'rmc nil t)
(when (fboundp 'read-multiple-choice)
  (defalias 'virtual-auto-fill--read-multiple-choice #'read-multiple-choice))

(defvar virtual-auto-fill--saved-mode-enabled-states nil
  "Saves enabled states of local minor modes.
The mode function and variable must behave according to
define-minor-mode's default.")

(defun virtual-auto-fill--save-state ()
  "Save enabled modes."
  (set (make-local-variable 'virtual-auto-fill--saved-mode-enabled-states) nil)
  (dolist (var '(visual-line-mode
                 adaptive-wrap-prefix-mode
                 visual-fill-column-mode))
    (push (cons var (symbol-value var))
          virtual-auto-fill--saved-mode-enabled-states)))

(defun virtual-auto-fill--restore-state ()
  "Restore enabled modes."
  (dolist (saved virtual-auto-fill--saved-mode-enabled-states)
    (if (cdr saved)
        (funcall (car saved) 1)
      (funcall (car saved) -1)))
  ;; Clean up.
  (kill-local-variable 'virtual-auto-fill--saved-mode-enabled-states))

(defvar virtual-auto-fill-fill-paragraph-require-confirmation t
  "Ask for confirmation before `fill-paragraph'.")

(defun virtual-auto-fill-fill-paragraph-after-confirmation ()
  "Ask the first time a paragraph is filled in a buffer.
Confirmation is always skipped if
`virtual-auto-fill-fill-paragraph-require-confirmation' is nil."
  (interactive)
  (unless (when virtual-auto-fill-fill-paragraph-require-confirmation
            (pcase (car (virtual-auto-fill--read-multiple-choice
                         "Really fill paragraphs in visually wrapped buffer?"
                         '((?y "yes" "Fill the paragraph, do not ask again")
                           (?n "no" "Don't fill the paragraph and ask again next time")
                           (?d "disable visual wrapping" "Disable virtual-auto-fill-mode"))))
              (?y (progn (setq-local virtual-auto-fill-fill-paragraph-require-confirmation nil)
                         nil))
              (?n t)
              (?d (progn (virtual-auto-fill-mode -1) nil))))
    ;; Either no confirmation was required or the user decided to fill the
    ;; paragraph.
    (call-interactively #'fill-paragraph)))

(defvar virtual-auto-fill-visual-fill-column-in-emacs-pre-26-1 nil
  "Enable Visual Fill Column mode even if Emacs is too old.
Emacs versions before 26.1 have a bug that can crash Emacs when
Visual Fill Column mode is enabled (a mode employed by
Virtual Auto Fill mode).  For further information, see:

  https://github.com/joostkremers/visual-fill-column/issues/1

By setting this to non-nil, you risk a crash when your Emacs
version is too old.  To only disable the warning about the bug,
unset
`virtual-auto-fill-visual-fill-column-warning-in-emacs-pre-26-1'.")

(put 'virtual-auto-fill-visual-fill-column-in-emacs-pre-26-1
     'risky-local-variable t)

(defvar virtual-auto-fill-visual-fill-column-warning-in-emacs-pre-26-1 nil
  "Don't warn about the Emacs bug triggered by Visual Fill Column mode.
Emacs versions before 26.1 have a bug that can crash Emacs when
Visual Fill Column mode is enabled (a mode employed by Virtual
Auto Fill mode).  For further information and workarounds, see:

  https://github.com/joostkremers/visual-fill-column/issues/1

Setting this to non-nil silences the warning issued when you are
running an Emacs version smaller than 26.1, but still leaves
Visual Fill Column mode disabled.  To enable Visual Fill Column
mode even when your Emacs is deemed buggy, set
`virtual-auto-fill-visual-fill-column-in-emacs-pre-26-1'.")

(put 'virtual-auto-fill-visual-fill-column-warning-in-emacs-pre-26-1
     'risky-local-variable t)

;;;###autoload
(define-minor-mode virtual-auto-fill-mode
  "Visually wrap lines between wrap prefix and `fill-column'."
  :lighter " VirtualFill"
  (if virtual-auto-fill-mode
      (progn
        (virtual-auto-fill--save-state)
        (visual-line-mode 1)
        (adaptive-wrap-prefix-mode 1)
        (if (and (version< emacs-version "26.1")
                 (not virtual-auto-fill-visual-fill-column-in-emacs-pre-26-1))
            (when virtual-auto-fill-visual-fill-column-warning-in-emacs-pre-26-1
              (message "You are running an Emacs version < 26.1 which has a bug that can crash Emacs when Visual Fill Column mode is enabled (that's a mode employed by Virtual Auto Fill mode). This bug has been fixed starting with Emacs version 26.1. Visual Fill Column mode is left disabled for now. To enable it anyway, set `virtual-auto-fill-visual-fill-column-in-emacs-pre-26-1' to non-nil and retry. To disable this warning (but leave Virtual Auto Fill mode disabled), unset `virtual-auto-fill-visual-fill-column-warning-in-emacs-pre-26-1'. For further information, see https://github.com/joostkremers/visual-fill-column/issues/1"))
          (visual-fill-column-mode 1))
        (local-set-key [remap fill-paragraph]
                       #'virtual-auto-fill-fill-paragraph-after-confirmation)
        (local-set-key [remap mu4e-fill-paragraph]
                       #'virtual-auto-fill-fill-paragraph-after-confirmation))
    (virtual-auto-fill--restore-state)
    ;; TODO: Not sure whether we ideally would also have to save/restore these
    ;; keybindings.
    (local-set-key [remap fill-paragraph] nil)
    (local-set-key [remap mu4e-fill-paragraph] nil)
    (kill-local-variable 'virtual-auto-fill-fill-paragraph-require-confirmation)))

(provide 'virtual-auto-fill)

;;; virtual-auto-fill.el ends here
