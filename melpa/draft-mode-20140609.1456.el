;;; draft-mode.el --- Rough drafting for Emacs.
;; Version: 0.1.1
;; Package-Version: 20140609.1456
;; Package-Commit: f059c04b044f62aec764c7698adddad301bfe89c

;; Copyright (C) 2014 Eeli Reilin

;; Author: Eeli Reilin <gaudecker@fea.st>
;; Keywords: draft, drafting
;; URL: https://github.com/gaudecker/draft-mode

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

;; When enabled, all input is inserted at (point-max), removing the
;; ability to revise the already written text.

;;; How to use:

;; Enable with `M-x draft-mode`.

;;; Code:

(defvar draft-mode-map (make-sparse-keymap)
  "Keymap for draft-mode.")

(defgroup draft nil
  "Rough drafting for Emacs."
  :prefix "draft-"
  :link '(emacs-commentary-link "draft-mode")
  :link '(url-link "https://github.com/gaudecker/draft-mode"))

(defun draft-pre-command-hook ()
  "Move point to the end of the buffer before self-insert."
  (if (and draft-mode
           (or (eq this-command 'org-self-insert-command)
               (eq this-command 'self-insert-command)))
      (goto-char (point-max))))

(add-hook 'draft-mode-hook
          (lambda ()
            (add-hook 'pre-command-hook 'draft-pre-command-hook nil 'local)))

(define-key draft-mode-map [remap delete-char] 'end-of-buffer)
(define-key draft-mode-map [remap org-delete-char] 'end-of-buffer)
(define-key draft-mode-map [remap kill-word] 'end-of-buffer)
(define-key draft-mode-map [remap kill-region] 'end-of-buffer)
(define-key draft-mode-map [remap kill-line] 'end-of-buffer)
(define-key draft-mode-map [remap kill-paragraph] 'end-of-buffer)
(define-key draft-mode-map [remap org-kill-line] 'end-of-buffer)
(define-key draft-mode-map [remap delete-backward-char] 'end-of-buffer)
(define-key draft-mode-map [remap backward-delete-char] 'end-of-buffer)
(define-key draft-mode-map [remap backward-delete-char-untabify] 'end-of-buffer)
(define-key draft-mode-map [remap org-delete-backward-char] 'end-of-buffer)
(define-key draft-mode-map [remap backward-kill-word] 'end-of-buffer)

;;;###autoload
(define-minor-mode draft-mode 
  "Toggle Draft mode.
Interactively with no argument, this command toggles the mode.
A positive prefix argument enables the mode, any other prefix
argument disables it.  From Lisp, argument omitted or nil enables
the mode, `toggle' toggles the state.

When Draft mode is enabled, all input is inserted at the end of 
the buffer and disables most editing commands."
  nil " Draft" draft-mode-map)

(provide 'draft-mode)
;;; draft-mode.el ends here
