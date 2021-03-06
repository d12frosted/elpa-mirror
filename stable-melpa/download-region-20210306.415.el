;;; -*- lexical-binding: t -*-
;;; download-region.el --- Simple in-buffer download manager

;; Copyright (C) 2013-2015 zk_phi

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

;; Author: zk_phi
;; URL: http://zk-phi.github.io/
;; Package-Version: 20210306.415
;; Package-Commit: e0a721858a22896fa1d7f1d5689dd0878dbc58fa
;; Version: 1.0.0
;; Package-Requires: ((cl-lib "0.3"))

;;; Commentary:

;; Require (or autoload) this script in your init file :
;;
;;   (require 'download-region)
;;
;; then two commands below are available.
;;
;; - download-region-as-url
;;
;;   Download selected URL, to a specific directory.
;;
;; - download-region-cancel
;;
;;   Cancel all downloads in the region.
;;
;; For more details, see "Readme".

;;; Change Log:

;; 1.0.0 first released

;;; Code:

(require 'mm-decode)
(require 'cl-lib)
(require 'url)
(require 'thingatpt)

(defconst download-region-version "1.0.0")

;; + customs

(defgroup download-region nil
  "simple in-buffer download manager for Emacs."
  :group 'emacs)

(defcustom download-region-max-downloads 5
  "maximum number of downloads."
  :type 'integer
  :group 'download-region)

(defface download-region-downloading '((t (:background "#194854")))
  "Face used to show download objects."
  :group 'download-region)

;; + utilities

(defun dlrgn/filter (pred lst)
  (delq nil (mapcar (lambda (x) (and (funcall pred x) x)) lst)))

(defun dlrgn/remove-from-list (lstvar elem)
  (cl-labels ((dlrgn/remove (lst elem)
                            (cond ((null lst) nil)
                                  ((equal elem (car lst)) (cdr lst))
                                  (t (cons (car lst) (dlrgn/remove (cdr lst) elem))))))
    (set lstvar (dlrgn/remove (symbol-value lstvar) elem))))

;; + internal fns/vars

;; a "download" is actually an overlay that may have following properties :
;;
;; - dlrgn/buf ... the buffer download process is running in (for active downloads)
;; - dlrgn/url ... the target URL of the download (for pending downloads)
;;
;; - dlrgn/newname ... the filename contents will be saved into
;; - dlrgn/canceled ... when non-nil dlrgn/callback must count it a canceled download

(defvar dlrgn/active-downloads nil)
(defvar dlrgn/pending-downloads nil)

(defvar dlrgn/update-timer nil)
(defvar dlrgn/last-dir nil)

(defun dlrgn/make-download (beg end newname)
  (let ((ov (make-overlay beg end nil t)))
    (overlay-put ov 'dlrgn/newname newname)
    (overlay-put ov 'face 'download-region-downloading)
    (overlay-put ov 'intangible t)
    ;; cancel download on delete
    (overlay-put ov 'modification-hooks
                 '((lambda (ov afterp &rest _)
                     (if (and (not afterp)
                              (y-or-n-p "Cancel downloading ?"))
                         (dlrgn/cancel-download ov) (error "")))))
    ov))

(defun dlrgn/start-download (url ov)
  (let (buf)
    (cond ((and download-region-max-downloads ; add to the queue
                (>= (length dlrgn/active-downloads)
                    download-region-max-downloads))
           (overlay-put ov 'display "[waiting ...]")
           (overlay-put ov 'dlrgn/url url)
           (add-to-list 'dlrgn/pending-downloads ov t))
          ((progn                       ; connection succeeded
             (overlay-put ov 'display "[connecting ...]")
             (setq buf (ignore-errors
                         (url-retrieve url 'dlrgn/callback (list ov)))))
           (overlay-put ov 'dlrgn/buf buf)
           ;; if this is the first active download, start the timer
           (when (null dlrgn/active-downloads)
             (setq dlrgn/update-timer (run-with-timer 2 2 'dlrgn/update)))
           (push ov dlrgn/active-downloads))
          ((y-or-n-p "Connection failed. Retry ?") ; retry
           (dlrgn/start-download url ov))
          (t                            ; cancel
           (delete-overlay ov)))))

(defun dlrgn/cancel-download (ov)
  (let ((buf (overlay-get ov 'dlrgn/buf))
        (url (overlay-get ov 'dlrgn/url)))
    (cond (buf                          ; active download
           (overlay-put ov 'dlrgn/canceled t)
           (delete-process (get-buffer-process buf)) ; => cb is called
           )
          (url                          ; pending download
           (overlay-put ov 'dlrgn/canceled t)
           (dlrgn/callback nil ov))
          (t                            ; normal overlays
           nil))))

(defun dlrgn/callback (status ov)
  (let* ((newurl (plist-get status :redirect))
         (err (plist-get status :error))
         (canceled (overlay-get ov 'dlrgn/canceled))
         (buf (overlay-get ov 'dlrgn/buf)))
    (dlrgn/remove-from-list 'dlrgn/active-downloads ov)
    (cond ((or err canceled)            ; error or canceled
           (when buf (kill-buffer buf))
           (delete-overlay ov)
           (message "download aborted."))
          (newurl                       ; redirect
           (kill-buffer buf)
           (when (y-or-n-p (concat "redirect to " newurl))
             (dlrgn/start-download newurl ov)))
          (t                            ; success
           (overlay-put ov 'display "[saving ...]")
           ;; copied from "url-copy-file"
           (with-current-buffer buf
             (let ((handle (mm-dissect-buffer t)))
               (mm-save-part-to-file handle (overlay-get ov 'dlrgn/newname))
               (kill-buffer buf)
               (mm-destroy-parts handle)))
           (delete-overlay ov)
           (message "download completed.")))
    ;; if any download is pending, start it
    (when dlrgn/pending-downloads
      (let ((ov (car dlrgn/pending-downloads)))
        (dlrgn/start-download (overlay-get ov 'dlrgn/url) ov))
      (setq dlrgn/pending-downloads (cdr dlrgn/pending-downloads)))
    ;; if no download is active, stop the timer
    (when (null dlrgn/active-downloads)
      (cancel-timer dlrgn/update-timer))))

(defun dlrgn/update ()
  (mapc (lambda (ov)
          (overlay-put ov 'display
                       (format "[downloading ... (%.2fMB)]"
                               (/ (buffer-size (overlay-get ov 'dlrgn/buf))
                                  1048576.0))))
        dlrgn/active-downloads))

;; + interactive commands

;;;###autoload
(defun download-region-as-url (&optional use-last-dir)
  "download region as url. when a prefix-argument is given,
download it to the same directory as the last download."
  (interactive "P")
  (let* ((bounds (cond
                  ((use-region-p)
                   (cons (region-beginning) (region-end)))
                  ((thing-at-point-bounds-of-url-at-point))
                  (t (error "There is no region."))))
         (beg (car bounds))
         (end (cdr bounds))
         (url (buffer-substring-no-properties beg end))
         (dir (setq dlrgn/last-dir
                    (or (and use-last-dir dlrgn/last-dir)
                        (read-directory-name
                         "download to :"
                         (or dlrgn/last-dir default-directory)))))
         (_ (when (not (file-exists-p dir)) (make-directory dir t)))
         (file (convert-standard-filename
                (url-unhex-string (car (last (split-string url "/" t))))))
         (newname (concat dir file))
         (newname (or (and (file-exists-p newname)
                           (not (y-or-n-p "file already exists. overwrite?"))
                           (read-file-name "new filename : " dir file))
                      newname))
         (ov (dlrgn/make-download beg end newname)))
    (dlrgn/start-download url ov)))

(defun download-region-cancel (beg end)
  "cancel all downloads in the region."
  (interactive "r")
  (let (dls)
    (while (setq dls
                 (dlrgn/filter (lambda (ov) (overlay-get ov 'dlrgn/newname))
                               (overlays-in beg end)))
      (mapc 'dlrgn/cancel-download dls))))

;; + kill-buffer query

(push (lambda ()
        (let ((dls (dlrgn/filter (lambda (ov) (overlay-get ov 'dlrgn/newname))
                                 (overlays-in 1 (1+ (buffer-size))))))
          (or (null dls)
              (and (y-or-n-p "Cancel all downloads in this buffer ?")
                   (progn (mapc 'dlrgn/cancel-download dls) t)))))
      kill-buffer-query-functions)

;; + provide

(provide 'download-region)

;;; download-region.el ends here
