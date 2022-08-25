;;; -*- lexical-binding: t -*-
;;; scratch-pop.el --- Generate, popup (& optionally backup) scratch buffer(s).

;; Copyright (C) 2012- zk_phi

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

;; Version: 2.2.0
;; Package-Version: 20200910.226
;; Package-Commit: 545badcd840dd50b39dd7dfa37459c6f71d02ea6
;; Author: zk_phi
;; URL: http://hins11.yu-yake.com/
;; Package-Requires: ()

;;; Commentary:

;; Load this script
;;
;;   (require 'scratch-pop)
;;
;; and you can popup a scratch buffer with "M-x scratch-pop". If a
;; scratch is already displayed, new buffers (like =*scratch2*=,
;; =*scratch3*= ...) are created. You may also bind some keys to
;; "scratch-pop" if you want.
;;
;;   (global-set-key "C-M-s" 'scratch-pop)
;;
;; You can backup scratches by calling `scratch-pop-backup-scratches'
;; after setting `scratch-pop-backup-directory',
;;
;;   (setq scratch-pop-backup-directory "~/.emacs.d/scratch_pop/")
;;   (add-hook 'kill-emacs-hook 'scratch-pop-backup-directory)
;;
;; and then restore backups by calling `scratch-pop-restore-scratches'.
;;
;;   (scratch-pop-restore-scratches 2) ; restores *scratch* and *scratch2*

;;; Change Log:

;; 1.0.0 first released
;; 1.0.1 better management of multiple scratches
;;       automatically yank region
;; 1.0.2 better handling of popup window
;; 1.0.3 require popwin
;; 2.0.0 change scratch buffer selection algorithm
;; 2.1.0 add backup feature
;; 2.1.1 add option to disable auto yank
;; 2.1.2 add option scratch-pop-after-restore-hook
;; 2.1.3 add option scratch-pop-initial-major-mode
;; 2.2.0 no longer requires popwin
;;       (set scratch-pop-popup-function to restore the previous behavior)

;;; Code:

(defconst scratch-pop-version "2.2.0")

;; + customs

(defgroup scratch-pop nil
  "Generate, popup (& optionally backup) scratch buffer(s)"
  :group 'emacs)

(defcustom scratch-pop-backup-directory nil
  "When non-nil, scratch buffers are backed up in the directory."
  :group 'scratch-pop
  :type 'string)

(defcustom scratch-pop-kept-old-backups 50
  "Number of old versions kept in `scratch-pop-backup-directory'."
  :group 'scratch-pop
  :type 'integer)

(defcustom scratch-pop-enable-auto-yank nil
  "When non-nil and `scratch-pop' is called with an active
region, the region is yanked to the scratch buffer."
  :group 'scratch-pop
  :type 'boolean)

(defcustom scratch-pop-after-restore-hook nil
  "Hook run immediately after a scratch buffer is restored from
backup and set major-mode."
  :group 'scratch-pop
  :type 'hook)

(defcustom scratch-pop-initial-major-mode initial-major-mode
  "Major-mode applied to scratch buffers when created."
  :group 'scratch-pop
  :type 'symbol)

(defcustom scratch-pop-popup-function 'scratch-pop-popup-buffer
  "Function used to popup the scratch buffer."
  :group 'scratch-pop
  :type 'function)

;; + backup

;; backup filename format: /BACKUP_DIR/yyyymmddHHMMSS!BUFNAME_SANS_ASTERISK!MAJOR_MODE

;; TODO: remove this code in a future version
(defun scratch-pop-migrate-older-backups ()
  "Convert backups in older format to the current format."
  (interactive)
  (when (file-exists-p scratch-pop-backup-directory)
    (let ((default-directory scratch-pop-backup-directory))
      (dolist (file (directory-files scratch-pop-backup-directory))
        (when (string-match "^\\(scratch[0-9]*\\)_\\(.*\\)$" file)
          (rename-file file (format "00000000000000!%s!%s" (match-string 1 file) (match-string 2 file))))))))

(defun scratch-pop--cleanup-older-backups ()
  "If `scratch-pop-backup-directory' contains greater number of
backups than `scratch-pop-kept-old-backups', delete oldest
backups."
  (when (file-exists-p scratch-pop-backup-directory)
    (let ((lst (delq nil (mapcar (lambda (f) (and (file-regular-p f) f))
                                 (directory-files scratch-pop-backup-directory t)))))
      (when (> (length lst) scratch-pop-kept-old-backups)
        (message "[scratch-pop] cleaning up old backups.")
        (dotimes (_ (- (length lst) scratch-pop-kept-old-backups))
          (delete-file (pop lst)))))))

(defun scratch-pop--maybe-backup-buffer (bufname)
  "Create backup file of buffer BUFNAME if it is a scratch
buffer."
  (when (and (file-exists-p scratch-pop-backup-directory)
             (string-match "^\\*\\(scratch[0-9]*\\)\\*$" bufname))
    (with-current-buffer bufname
      (let ((name (format "%s!%s!%s"
                          (format-time-string "%Y%m%d%H%M%S" (current-time))
                          (match-string 1 bufname)
                          major-mode)))
        (write-region 1 (1+ (buffer-size))
                      (expand-file-name name scratch-pop-backup-directory))))))

(defun scratch-pop--maybe-restore-buffer (bufname)
  "Restore scratch buffer BUFNAME from backup if exists. Return
non-nil when a buffer is restored, or nil otherwise."
  (when (and (file-exists-p scratch-pop-backup-directory)
             (string-match "^\\*\\(scratch[0-9]*\\)\\*$" bufname))
    (let* ((regexp (concat "!" (match-string 1 bufname) "!"))
           (lst (directory-files scratch-pop-backup-directory t regexp))
           (file (and lst (car (last lst)))))
      (when file
        (or (get-buffer bufname) (generate-new-buffer bufname))
        (with-current-buffer bufname
          (erase-buffer)
          (save-excursion
            (insert-file-contents (expand-file-name file scratch-pop-backup-directory)))
          (let ((mode (and (string-match "!\\([^!]*\\)$" file) (intern (match-string 1 file)))))
            (when (functionp mode) (funcall mode)))
          (run-hooks 'scratch-pop-after-restore-hook)
          t)))))

(defun scratch-pop-backup-scratches ()
  "Backup scratch buffers."
  (unless scratch-pop-backup-directory
    (error "scratch-pop: Backup directory is not set."))
  (unless (file-exists-p scratch-pop-backup-directory)
    (make-directory scratch-pop-backup-directory))
  (dolist (buf (buffer-list))
    (scratch-pop--maybe-backup-buffer (buffer-name buf)))
  (scratch-pop--cleanup-older-backups))

(defun scratch-pop-restore-scratches (&optional limit)
  "Restore scratch buffers. You can optionally LIMIT the number
of scratch buffers to restore."
  (unless scratch-pop-backup-directory
    (error "scratch-pop: Backup directory is not set."))
  (when (file-exists-p scratch-pop-backup-directory)
    (cond (limit
           (dotimes (n limit)
             (scratch-pop--maybe-restore-buffer
              (concat "*scratch" (if (> n 1) (int-to-string n) "") "*"))))
          ;; backward-compatibility
          (t
           (let ((n 1))
             (while (scratch-pop--maybe-restore-buffer
                     (concat "*scratch" (if (> n 1) (int-to-string n) "") "*"))
               (setq n (1+ n))))))))

;; + core

(defvar scratch-pop--next-scratch-id nil) ; Int
(defvar scratch-pop--visible-buffers nil) ; List[Buffer]

(defun scratch-pop--get-next-scratch ()
  "Return the next scratch buffer. This function creates a new
buffer if necessary. Binding `scratch-pop--next-scratch-id'
and/or `scratch-pop--visible-buffers' dynamically affects this
function."
  (let* ((name (concat "*scratch"
                       (unless (= scratch-pop--next-scratch-id 1)
                         (int-to-string scratch-pop--next-scratch-id))
                       "*"))
         (buf (get-buffer name)))
    (setq scratch-pop--next-scratch-id (1+ scratch-pop--next-scratch-id))
    (cond ((null buf)
           (with-current-buffer (generate-new-buffer name)
             (funcall scratch-pop-initial-major-mode)
             (current-buffer)))
          ((memq buf scratch-pop--visible-buffers) ; skip visible buffers
           (scratch-pop--get-next-scratch))
          (t
           buf))))

(autoload 'edmacro-format-keys "edmacro.el")

(defun scratch-pop-popup-buffer (buf)
  (if (string-match "^\\*\\(scratch[0-9]*\\)\\*$" (buffer-name))
      (switch-to-buffer buf)
    (select-window (display-buffer-below-selected buf nil))))

;;;###autoload
(defun scratch-pop ()
  "Popup a scratch buffer. If `*scratch*' is already displayed,
create new scratch buffers `*scratch2*', `*scratch3*', ... ."
  (interactive)
  (let ((str (when (and scratch-pop-enable-auto-yank (use-region-p))
               (prog1 (buffer-substring (region-beginning) (region-end))
                 (delete-region (region-beginning) (region-end))
                 (deactivate-mark))))
        (repeat-key (vector last-input-event)))
    (setq scratch-pop--next-scratch-id 1
          scratch-pop--visible-buffers (mapcar 'window-buffer (window-list)))
    (funcall scratch-pop-popup-function (scratch-pop--get-next-scratch))
    (when str
      (goto-char (point-max))
      (insert (concat "\n" str "\n")))
    (message "(Type %s to repeat)" (edmacro-format-keys repeat-key))
    (set-transient-map
     (let ((km (make-sparse-keymap))
           (cycle-fn (lambda ()
                       (interactive)
                       (switch-to-buffer (scratch-pop--get-next-scratch)))))
       (define-key km repeat-key cycle-fn)
       km) t)))

(provide 'scratch-pop)

;;; scratch-pop.el ends here
