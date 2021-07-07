;;; org-elp.el --- Preview latex equations in org mode while editing -*- lexical-binding: t; -*-

;; Author: Yilun Guan
;; URL: https://github.com/guanyilun/org-elp
;; Package-Version: 20210329.1535
;; Package-Commit: 36b5ab2ed3fa3b5917f058e3acf8dff2df69efae
;; Keywords: lisp, tex, org
;; Version: 0.1
;; Package-Requires: ((emacs "27.1"))

;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;

;;; Commentary:
;;
;; Preview latex equations in org mode in a separate buffer while
;; editing.  Possible configurations:
;;
;; To set the fraction of the window taken up by the previewing buffer
;; (setq org-elp-split-fraction 0.2)
;;
;; To adjust buffer name
;; (setq org-elp-buffer-name "*Equation Live*")
;;
;; To adjust idle time to run latex preview
;; (setq org-elp-idle-time 0.5)
;;
;; Launch or deactivate the previewing with
;; M-x org-elp-mode
;;
;;; Code:

(require 'org-element)

(defgroup org-elp nil
  "org-elp customizable variables."
  :group 'org)

(defcustom org-elp-buffer-name "*Equation Live Preview*"
  "Buffer name used to show the previewed equation."
  :type  'string
  :group 'org-elp)

(defcustom org-elp-split-fraction 0.2
  "Fraction of the window taken up by the previewing buffer."
  :type  'float
  :group 'org-elp)

(defcustom org-elp-idle-time 0.5
  "Idle time after editing to wait before creating the fragment."
  :type  'float
  :group 'org-elp)

(defvar org-elp--timer nil
  "A variable that keeps track of the idle timer.")

(defvar org-elp--preview-buffer nil
  "Buffer used for previewing equations.")

(defun org-elp--preview ()
  "Preview the equation at point in buffer defined in `org-elp-buffer-name'."
  (let ((datum (org-element-context)))
    (and (memq (org-element-type datum) '(latex-environment latex-fragment))
         (let* ((beg (org-element-property :begin datum))
                (end (org-element-property :end datum))
                (text (buffer-substring-no-properties beg end)))
           (with-current-buffer org-elp--preview-buffer
             (let ((inhibit-read-only t))
               (erase-buffer) (insert (replace-regexp-in-string "\n$" "" text))
               (org-latex-preview)))))))

(defun org-elp--open-buffer ()
  "Open the preview buffer."
  (split-window-vertically (floor (* (- 1 org-elp-split-fraction)
                                     (window-height))))
  (other-window 1)
  (switch-to-buffer org-elp-buffer-name)
  (special-mode)
  (other-window -1))

;;;###autoload
(defun org-elp-activate ()
  "Activate previewing buffer and idle timer."
  (interactive)
  (message "Activating org-elp")
  (setq org-elp--preview-buffer (get-buffer-create org-elp-buffer-name))
  (org-elp--open-buffer)
  (setq org-elp--timer (run-with-idle-timer
                        org-elp-idle-time t #'org-elp--preview)))

;;;###autoload
(defun org-elp-deactivate ()
  "Deactivate previewing and remove the idle timer."
  (interactive)
  (with-current-buffer org-elp--preview-buffer
      (kill-buffer-and-window))
  (message "Deactivating org-elp")
  (cancel-function-timers #'org-elp--preview))

;;;###autoload
(define-minor-mode org-elp-mode
  "org-elp mode: display latex fragment while typing."
  :lighter " org-elp"
  :group   'org-elp
  :require 'org-elp
  (if org-elp-mode
      (org-elp-activate)
    (org-elp-deactivate)))


(provide 'org-elp)
;;; org-elp.el ends here
