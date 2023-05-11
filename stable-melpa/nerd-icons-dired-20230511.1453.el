;;; nerd-icons-dired.el --- Shows icons for each file in dired mode -*- lexical-binding: t -*-

;; Copyright (C) 2023 Hongyu Ding <rainstormstudio@yahoo.com>

;; Author: Hongyu Ding <rainstormstudio@yahoo.com>
;; Keywords: lisp
;; Package-Version: 20230511.1453
;; Package-Commit: 87c493858c2b7a4cf0f9a50445adfefd41b2a02d
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.4") (nerd-icons "0.0.1"))
;; URL: https://github.com/rainstormstudio/nerd-icons-dired
;; Keywords: files, icons, dired

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

;; To use this package, simply install and add this to your init.el
;; (require 'nerd-icons-dired)
;; (add-hook 'dired-mode-hook 'nerd-icons-dired-mode)

;; or use use-package:
;; (use-package nerd-icons-dired
;;   :hook
;;   (dired-mode . nerd-icons-dired-mode))

;; This package is inspired by
;; - `all-the-icons-dired': https://github.com/jtbm37/all-the-icons-dired

;;; Code:

(require 'dired)
(require 'nerd-icons)

(defface nerd-icons-dired-dir-face
  '((t nil))
  "Face for the directory icon."
  :group 'nerd-icons-faces)

(defcustom nerd-icons-dired-v-adjust 0.01
  "The default vertical adjustment of the icon in the Dired buffer."
  :group 'nerd-icons
  :type 'number)

(defvar nerd-icons-dired-mode)

(defun nerd-icons-dired--remove-all-icons ()
  "Remove all `nerd-icons-dired' icons."
  (save-restriction
    (widen)
    (let ((inhibit-read-only t)
          (pos nil))
      (save-excursion
        (while (setq pos (text-property-any (point-min) (point-max) 'category 'dired-icon))
          (goto-char pos)
          (delete-char 1))))))

(defun nerd-icons-dired--refresh ()
  "Display the icons of files in a Dired buffer."
  (nerd-icons-dired--remove-all-icons)
  (save-excursion
    (goto-char (point-min))
    (while (not (eobp))
      (when (dired-move-to-filename nil)
        (let ((file (dired-get-filename 'relative 'noerror)))
          (when file
            (let ((icon (if (file-directory-p file)
                            (nerd-icons-icon-for-dir file
                                                     :face 'nerd-icons-dired-dir-face
                                                     :v-adjust nerd-icons-dired-v-adjust)
                          (nerd-icons-icon-for-file file :v-adjust nerd-icons-dired-v-adjust)))
                  (inhibit-read-only t))
              (if (member file '("." ".."))
                  (insert (propertize "  \t" 'category 'dired-icon))
                (insert (propertize (concat icon "\t") 'category 'dired-icon)))))))
      (forward-line 1))))

(defun nerd-icons-dired--refresh-advice (fn &rest args)
  "Advice function for FN with ARGS."
  (let ((result (apply fn args))) ;; Save the result of the advised function
    (when nerd-icons-dired-mode
      (nerd-icons-dired--refresh))
    result)) ;; Return the result

(defun nerd-icons-dired--setup ()
  "Setup `nerd-icons-dired'."
  (when (derived-mode-p 'dired-mode)
    (setq-local tab-width 1)
    (advice-add 'dired-readin :around #'nerd-icons-dired--refresh-advice)
    (advice-add 'dired-revert :around #'nerd-icons-dired--refresh-advice)
    (advice-add 'dired-internal-do-deletions :around #'nerd-icons-dired--refresh-advice)
    (advice-add 'dired-insert-subdir :around #'nerd-icons-dired--refresh-advice)
    (advice-add 'dired-do-kill-lines :around #'nerd-icons-dired--refresh-advice)
    (with-eval-after-load 'dired-narrow
      (advice-add 'dired-narrow--internal :around #'nerd-icons-dired--refresh-advice))
    (nerd-icons-dired--refresh)))

(defun nerd-icons-dired--teardown ()
  "Functions used as advice when redisplaying buffer."
  (advice-remove 'dired-readin #'nerd-icons-dired--refresh-advice)
  (advice-remove 'dired-revert #'nerd-icons-dired--refresh-advice)
  (advice-remove 'dired-internal-do-deletions #'nerd-icons-dired--refresh-advice)
  (advice-remove 'dired-narrow--internal #'nerd-icons-dired--refresh-advice)
  (advice-remove 'dired-insert-subdir #'nerd-icons-dired--refresh-advice)
  (advice-remove 'dired-do-kill-lines #'nerd-icons-dired--refresh-advice)
  (nerd-icons-dired--remove-all-icons))

;;;###autoload
(define-minor-mode nerd-icons-dired-mode
  "Display nerd-icons icon for each files in a Dired buffer."
  :lighter " nerd-icons-dired-mode"
  (when (derived-mode-p 'dired-mode)
    (if nerd-icons-dired-mode
        (nerd-icons-dired--setup)
      (nerd-icons-dired--teardown))))

(provide 'nerd-icons-dired)
;;; nerd-icons-dired.el ends here
