;;; dired-lsi.el --- Add memo to directory and show it in dired  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Version: 1.0.1
;; Package-Version: 20200812.929
;; Package-Commit: 0f4038c8b47f6cfc70f82062800700c14c9912c2
;; Keywords: convenience
;; Package-Requires: ((emacs "26.1"))
;; URL: https://github.com/conao3/dired-lsi.el

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

;; Add memo to directory and show it in dired.

;; To use this package, simply add this to your init.el:
;;   (add-hook 'dired-mode-hook 'dired-lsi-mode)

;; If you use `dired-git', I suggest below customize.
;;   (setq dired-lsi--create-spacer-fn
;;         (lambda () (when all-the-icons-dired-mode "  \t")))


;;; Code:

(require 'cl-lib)
(require 'dired)
(require 'subr-x)

(defgroup dired-lsi nil
  "Add memo to directory and show it in dired."
  :group 'convenience
  :link '(url-link :tag "Github" "https://github.com/conao3/dired-lsi.el"))

(defcustom dired-lsi-separator " / "
  "Separator between item and description."
  :group 'dired-lsi
  :type 'string)

(defcustom dired-lsi--create-spacer-fn #'ignore
  "Create additional spacer function.
This variable should be function symbol or lambda function.
That function called with empty argument and should return string or nil."
  :group 'dired-lsi
  :type 'function)

(defface dired-lsi-default-face
  '((t (:inherit font-lock-warning-face)))
  "Default face."
  :group 'dired-lsi)


;;; Functions

(defvar dired-lsi-mode)

(defun dired-lsi--add-overlay (pos string)
  "Add overlay to display STRING at POS."
  (let ((ov (make-overlay (1- pos) pos)))
    (overlay-put ov 'dired-lsi-overlay t)
    (overlay-put ov 'after-string string)))

(defun dired-lsi--overlays-in (beg end)
  "Get all dired-lsi overlays between BEG to END."
  (cl-remove-if-not
   (lambda (ov)
     (overlay-get ov 'dired-lsi-overlay))
   (overlays-in beg end)))

(defun dired-lsi--remove-all-overlays ()
  "Remove all `dired-lsi' overlays."
  (save-restriction
    (widen)
    (mapc #'delete-overlay
          (dired-lsi--overlays-in (point-min) (point-max)))))

(defmacro dired-lsi--thread-last-check-empty (&rest forms)
  "Thread FORMS elements as the last argument of their successor.
Do `thread-last' and check if it isn't empty at each steps."
  (declare (indent 1) (debug thread-first))
  `(catch 'empty
     (cl-flet ((throw-if-empty
                (elm)
                (if (and elm (not (string-empty-p elm)))
                    elm
                  (throw 'empty nil))))
       (thread-last ,(pop forms)
         ,@(mapcan (lambda (elm) `((throw-if-empty) ,elm)) forms)))))

(defun dired-lsi--modify-description (desc)
  "Modify DESC to suit dired buffer.
If return nil, dired-lsi doesn't show description."
  (dired-lsi--thread-last-check-empty desc
    (string-trim-right)
    (funcall (lambda (elm)
               (propertize elm 'face 'dired-lsi-default-face)))
    (concat dired-lsi-separator)
    (funcall (lambda (elm)
               (if (not (string-match-p "\n" elm))
                   elm
                 (let ((col (save-excursion
                              (end-of-line)
                              (current-column)))
                       (sep (length dired-lsi-separator)))
                   (replace-regexp-in-string
                    "\n"
                    (format "\n%s"
                            (concat
                             (funcall dired-lsi--create-spacer-fn)
                             (make-string (+ sep col) ?\s)))
                    elm)))))
    (identity)))                        ; empty check

(defun dired-lsi--refresh ()
  "Display the icons of files in a dired buffer."
  (dired-lsi--remove-all-overlays)
  (save-excursion
    (goto-char (point-min))
    (while (not (eobp))
      (when (dired-move-to-filename nil)
        (when-let* ((item (dired-get-filename 'relative 'noerror))
                    (file (expand-file-name ".description.lsi" item))
                    (desc (when (file-readable-p file)
                            (with-temp-buffer
                              (insert-file-contents file)
                              (buffer-string))))
                    (desc* (dired-lsi--modify-description desc)))
          (end-of-line)
          (dired-lsi--add-overlay (point) desc*)))
      (forward-line 1))))


;;; Main

(defvar dired-lsi-description-history nil)

;;;###autoload
(defun dired-lsi-add-description (dir desc)
  "In dired, add DESC for DIR on this line."
  (interactive
   (let (dir*)
     (list (setq dir* (dired-get-filename nil 'allow-dir))
           (let ((file (expand-file-name ".description.lsi" dir*)))
             (read-string "Description: "
                          (when (file-readable-p file)
                            (with-temp-buffer
                              (insert-file-contents file)
                              (buffer-string)))
                          'dired-lsi-description-history)))))
  (let ((file (expand-file-name ".description.lsi" dir)))
    (if (string-empty-p desc)
        (delete-file file)
      (with-temp-file file
        (insert desc))))
  (dired-lsi--refresh))

;;;###autoload
(defun dired-lsi-mkdir-with-description (name desc)
  "Make directory named NAME with dired-lsi DESC."
  (interactive
   (list (read-string "Directory name: ")
         (read-string "Description: " nil 'dired-lsi-description-history)))
  (let ((dir (expand-file-name name)))
    (when (file-exists-p dir)
      (error "%s is already exists" dir))
    (mkdir dir)
    (dired-lsi-add-description (expand-file-name name) desc)
    (when (derived-mode-p 'dired-mode)
      (dired-revert))))


;;; Minor-mode

(defun dired-lsi--refresh-advice (fn &rest args)
  "Advice function for FN with ARGS."
  (apply fn args)
  (when dired-lsi-mode
    (dired-lsi--refresh)))

(defvar dired-lsi-advice-alist
  '((dired-readin                . dired-lsi--refresh-advice)
    (dired-revert                . dired-lsi--refresh-advice)
    (dired-do-create-files       . dired-lsi--refresh-advice)
    (dired-do-kill-lines         . dired-lsi--refresh-advice)
    (dired-insert-subdir         . dired-lsi--refresh-advice)
    (dired-create-directory      . dired-lsi--refresh-advice)
    (dired-internal-do-deletions . dired-lsi--refresh-advice)
    (dired-narrow--internal      . dired-lsi--refresh-advice)
    (dired-hide-details-mode     . dired-lsi--refresh-advice))
  "Alist of advice and advice functions.")

(defun dired-lsi--setup ()
  "Setup `dired-lsi'."
  (when (derived-mode-p 'dired-mode)
    (setq-local tab-width 1)
    (pcase-dolist (`(,sym . ,fn) dired-lsi-advice-alist)
      (advice-add sym :around fn))
    (dired-lsi--refresh)))

(defun dired-lsi--teardown ()
  "Functions used as advice when redisplaying buffer."
  (pcase-dolist (`(,sym . ,fn) dired-lsi-advice-alist)
    (advice-remove sym fn))
  (dired-lsi--remove-all-overlays))

;;;###autoload
(define-minor-mode dired-lsi-mode
  "Display all-the-icons icon for each files in a dired buffer."
  :lighter " dired-lsi"
  (when (and (derived-mode-p 'dired-mode) (display-graphic-p))
    (if dired-lsi-mode
        (dired-lsi--setup)
      (dired-lsi--teardown))))

(provide 'dired-lsi)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; dired-lsi.el ends here
