;;; wfnames.el --- Edit filenames -*- lexical-binding:t -*-

;; Author: Thierry Volpiatto <thievol@posteo.net>
;; Copyright (C) 2022 Thierry Volpiatto, all rights reserved.
;; URL: https://github.com/thierryvolpiatto/wfnames
;; Package-Version: 20230519.437
;; Package-Commit: 7202294447e3f6e894fe8a1ae88c96ca010ccccd

;; Compatibility: GNU Emacs 24.3+"
;; Package-Requires: ((emacs "24.3"))
;; Version: 1.0

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

;; A mode to edit filenames, similar to wdired.

;; This package have no user interface, but you can easily use it with
;; Helm package by customizing `helm-ff-edit-marked-files-fn'
;; variable.  If you are not using Helm you will have to define
;; yourself a function that call `wfnames-setup-buffer' with a list of
;; files as argument.

;; Usage:
;; Once in the Wfnames buffer, edit your filenames and hit C-c C-c to
;; save your changes. You have completion on filenames and directories
;; with TAB but if you are using Iedit package and it is in action use =M-TAB=.

;;; Code:

(require 'cl-lib)

;; Internal.
(defvar wfnames-buffer "*Wfnames*")
(defvar wfnames--modified nil)

(defgroup wfnames nil
  "A mode to edit filenames."
  :group 'wfnames)

(defcustom wfnames-create-parent-directories t
  "Create parent directories when non nil."
  :type 'boolean)

(defcustom wfnames-interactive-rename t
  "Ask confirmation when overwriting."
  :type 'boolean)

(defvar wfnames-after-commit-hook nil)

(defcustom wfnames-after-commit-function #'kill-buffer
  "A function to call on `wfnames-buffer' when done."
  :type 'function)

(defcustom wfnames-make-backup nil
  "Backup files before overwriting when non nil."
  :type 'boolean)

(defface wfnames-modified
    '((t :background "LightBlue" :foreground "black"))
  "Face used when filename is modified.")

(defface wfnames-modified-exists
    '((t :background "DarkOrange" :foreground "black"))
  "Face used when modified fname point to an existing file.")

(defface wfnames-files '((t :foreground "DeepSkyBlue"))
  "Face used to display filenames in wfnames buffer.")

(defface wfnames-dir '((t :background "White" :foreground "red"))
  "Face used to display directories in wfnames buffer.")

(defface wfnames-symlink '((t :foreground "Orange"))
  "Face used to display symlinks in wfnames buffer.")

(defface wfnames-prefix '((t :foreground "Gold"))
  "Face used to prefix filenames in wfnames buffer.")

(defvar wfnames-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") #'wfnames-commit-buffer)
    (define-key map (kbd "C-x C-s") #'wfnames-commit-buffer)
    (define-key map (kbd "C-c C-r") #'wfnames-revert-changes)
    (define-key map (kbd "C-c C-k") #'wfnames-abort)
    (define-key map (kbd "TAB")     #'completion-at-point)
    ;; This override ispell completion in iedit map which is useless
    ;; here.
    (define-key map (kbd "C-M-i")   #'completion-at-point)
    map))

(defun wfnames-capf ()
  "Provide filename completion in wfnames buffer."
  (let ((beg (point-at-bol))
        (end (point)))
    (list beg end #'completion-file-name-table
          :exit-function (lambda (str _status)
                             (when (and (stringp str)
                                        (eq (char-after) ?/))
                               (delete-char -1))))))

(define-derived-mode wfnames-mode
    text-mode "wfnames"
    "Major mode to edit filenames.

Special commands:
\\{wfnames-mode-map}"
  (add-hook 'after-change-functions #'wfnames-after-change-hook nil t)
  (make-local-variable 'wfnames--modified)
  (set (make-local-variable 'completion-at-point-functions) #'wfnames-capf))

(defun wfnames-abort ()
  "Quit and kill wfnames buffer."
  (interactive)
  (quit-window t))

(defun wfnames-after-change-hook (beg end _len)
  "Put overlay on current line when modified.
Args BEG and END delimit changes on line."
  (with-current-buffer wfnames-buffer
    (save-excursion
      (save-match-data
        (goto-char beg)
        (let* ((bol (point-at-bol))
               (eol (point-at-eol))
               (old (get-text-property bol 'old-name))
               (new (buffer-substring-no-properties bol eol))
               ov face)
          (setq face (if (file-exists-p new)
                         'wfnames-modified-exists 'wfnames-modified))
          (setq-local wfnames--modified
                      (cons old (delete old wfnames--modified)))
          (cl-loop for o in (overlays-in bol eol)
                   when (overlay-get o 'hff-changed)
                   return (setq ov o))
          (cond ((string= old new)
                 (cl-loop for o in (overlays-in bol eol)
                          when (overlay-get o 'hff-changed)
                          do (delete-overlay o)))
                (ov
                 (move-overlay ov bol eol)
                 (overlay-put ov 'face face))
                (t (setq ov (make-overlay bol eol))
                   (overlay-put ov 'face face)
                   (overlay-put ov 'hff-changed t)
                   (overlay-put ov 'priority -1)
                   (overlay-put ov 'evaporate t)))
          ;; When text is modified with something else than
          ;; self-insert-command e.g. yank or iedit-rect, it loose its
          ;; properties, so restore props here.
          (put-text-property beg end 'face 'wfnames-files)
          (put-text-property beg end 'old-name old))))))

;;;###autoload
(cl-defun wfnames-setup-buffer (files
                                &optional (display-fn #'switch-to-buffer) append)
  "Initialize wfnames buffer with FILES and display it with DISPLAY-FN.

Arg DISPLAY-FN default to `switch-to-buffer' if unspecified.
When APPEND is specified, append FILES to existing `wfnames-buffer'."
  (with-current-buffer (get-buffer-create wfnames-buffer)
    (unless append (erase-buffer))
    (save-excursion
      (when append (goto-char (point-max)))
      (cl-loop for file in files
               for face = (cond ((file-directory-p file) 'wfnames-dir)
                                ((file-symlink-p file) 'wfnames-symlink)
                                (t 'wfnames-files))
               do (insert (propertize
                           file 'old-name file 'face face
                           'line-prefix (propertize
                                         "* "
                                         'face 'wfnames-prefix))
                          "\n"))
      (when append (delete-duplicate-lines (point-min) (point-max))))
    (unless append
      ;; Go to beginning of basename on first line.
      (while (re-search-forward "/" (point-at-eol) t))
      (wfnames-mode)
      (funcall display-fn wfnames-buffer))))

(defun wfnames-ask-for-overwrite (file)
  "Ask before overwriting FILE."
  (or (null wfnames-interactive-rename)
      (y-or-n-p
       (format "File `%s' exists, overwrite? "
               file))))

(defun wfnames-maybe-backup (file)
  "Backup FILE."
  (when wfnames-make-backup
    (with-current-buffer (find-file-noselect file)
      (let ((backup-by-copying t))
        (backup-buffer))
      (kill-buffer))))

(defun wfnames-commit-buffer ()
  "Commit wfnames buffer when changes are done."
  (interactive)
  (let ((renamed 0) (skipped 0) delayed overwrites)
    (cl-labels ((commit ()
                  (with-current-buffer wfnames-buffer
                    (goto-char (point-min))
                    (while (not (eobp))
                      (let* ((beg (point-at-bol))
                             (end (point-at-eol))
                             (old (get-text-property (point) 'old-name))
                             (new (buffer-substring-no-properties beg end))
                             ow)
                        (unless (string= old new) ; not modified, skip.
                          (cond (;; New file exists, rename it to a
                                 ;; temp file to put it out of the way
                                 ;; and delay real rename to next
                                 ;; turn. Make it accessible in
                                 ;; overwrites alist for next usage as
                                 ;; old [1].
                                 (and (file-exists-p new)
                                      ;; new is one of the old
                                      ;; files about to be modified.
                                      (member new wfnames--modified)
                                      (not (member new delayed)))
                                 ;; Maybe ask.
                                 (if (wfnames-ask-for-overwrite new)
                                     (let ((tmpfile (make-temp-name new)))
                                       (push (cons new tmpfile) overwrites)
                                       (push new delayed)
                                       (wfnames-maybe-backup new)
                                       (rename-file new tmpfile))
                                   ;; Answer is no, skip.
                                   (add-text-properties
                                    beg end `(old-name ,new))
                                   (cl-incf skipped)))
                                ;; Now really rename files.
                                (t
                                 (when (and (file-exists-p new)
                                            (not (member new delayed)))
                                   (setq ow t))
                                 (when wfnames-create-parent-directories
                                   ;; Check if base directory of new exists.
                                   (let ((basedir (file-name-directory
                                                   (directory-file-name new))))
                                     (unless (file-directory-p basedir)
                                       (mkdir basedir 'parents))))
                                 (if (and ow (wfnames-ask-for-overwrite new))
                                     ;; Direct overwrite i.e. first loop.
                                     (progn
                                       (wfnames-maybe-backup new)
                                       (rename-file old new 'overwrite))
                                   ;; 'No' answered.
                                   (and ow (cl-incf skipped))
                                   ;; It is an overwrite when OLD is
                                   ;; found in overwrites alist (2nd
                                   ;; loop), otherwise do normal renaming.
                                   (and (null ow)
                                        (rename-file
                                         (or (assoc-default old overwrites) old)
                                         new)))
                                 (add-text-properties beg end `(old-name ,new))
                                 (setq delayed (delete new delayed))
                                 (cl-incf renamed))))
                        (forward-line 1)))
                    (when delayed (commit)))))
      (commit)
      (run-hooks 'wfnames-after-commit-hook)
      (message "Renamed %s file(s), Skipped %s file(s)" renamed skipped)
      (funcall wfnames-after-commit-function wfnames-buffer))))

(defun wfnames-revert-changes ()
  "Revert wfnames buffer to its initial state."
  (interactive)
  (with-current-buffer wfnames-buffer
    (cl-loop for o in (overlays-in (point-min) (point-max))
             when (overlay-get o 'hff-changed)
             do (delete-overlay o))
    (goto-char (point-min))
    (save-excursion
      (while (not (eobp))
        (let ((old (get-text-property (point) 'old-name))
              (new (buffer-substring-no-properties
                    (point-at-bol) (point-at-eol))))
          (unless (string= old new)
            (delete-region (point-at-bol) (point-at-eol))
            (insert (propertize
                     old 'old-name old 'face 'wfnames-file
                     'line-prefix (propertize
                                   "* "
                                   'face 'wfnames-prefix))))
          (forward-line 1))))
    (while (re-search-forward "/" (point-at-eol) t))))

(provide 'wfnames)

;;; wfnames.el ends here
