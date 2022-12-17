;;; pastehub.el --- A client for the PasteHub cloud service
;;
;; Copyright (C) 2012-2014 Kiyoka Nishiyama
;;
;; Author: Kiyoka Nishiyama
;; Version: 0.9.4
;; Package-Version: 20140627.1319
;; Package-Commit: 37b045c67659c078f1517d0fbd5282dab58dca23
;; URL: https://github.com/kiyoka/pastehub
;;
;; This file is part of PasteHub.el
;;
;; PasteHub.el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; PasteHub.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with PasteHub.el; see the file COPYING.
;;

;;; Commentary:

;; PasteHub.net Cloud-based cross-platform clipboard (copy and paste)
;; service.  PasteHub.el is an emacs client for PasteHub.net.
;;
;; PasteHub.el can synchronize kill-ring with PasteHub.net cloud
;; service automatically.  You don't have to learn new key-bindings.
;; 
;; To get you started, you need to install PasteHub client for your client OS.
;;  https://github.com/kiyoka/pastehub
;; 
;; and then, add this line to your .emacs file:
;;  (require 'pastehub)
;;

;;; Code:

(defcustom pastehub-client-basepath    nil
  "Basepath of pastehubPost and pastehubGet command. (e.g. \"/usr/local/bin\")"
  :type 'string
  :group 'pastehub)

(defcustom pastehub-check-interval     2.0
  "Interval second for polling new comming data."
  :type 'integer
  :group 'pastehub)

(defcustom pastehub-sync-dir          "~/Dropbox/pastehub/."
  "Sync data directory path"
  :type 'string
  :group 'pastehub)


(defconst pastehub-client-post          "pastehubPost")
(defconst pastehub-client-get           "pastehubGet")
(defconst pastehub-default-client-post "/opt/pastehub/bin/pastehubPost")
(defconst pastehub-default-client-get  "/opt/pastehub/bin/pastehubGet")


(defvar pastehub-latest-date ""         "latest synced date.")
(defvar pastehub-timer-object nil       "interval timer object.")
(defvar pastehub-unread-count 0         "number of unread pastes")
(defvar pastehub-sync-cache   '()       "cache of key-value")

(defvar pastehub-mode nil               "pastehub toggle for mode")
(defun pastehub-modeline-string ()
  ;; display unread count
  (format " PasteHub[%d]" pastehub-unread-count))

(or (assq 'pastehub-mode minor-mode-alist)
    (setq minor-mode-alist (cons
                            '(pastehub-mode (:eval (pastehub-modeline-string)))
                            minor-mode-alist)))

(defun pastehub-concat-path (basepath filename)
  (cond (basepath
	 (cond ((string-match "[/]$" basepath)
		(concat basepath filename))
	       (t
		(concat basepath "/" filename))))
	(t
	 filename)))

(defun get-pastehub-client-post ()
  (cond ((and pastehub-client-basepath
	      (file-exists-p (pastehub-concat-path pastehub-client-basepath pastehub-client-post)))
	 (pastehub-concat-path pastehub-client-basepath pastehub-client-post))
	((file-exists-p pastehub-default-client-post)
	 pastehub-default-client-post)
	(t
	 pastehub-client-post)))

(defun get-pastehub-client-get ()
  (cond ((and pastehub-client-basepath
	      (file-exists-p (pastehub-concat-path pastehub-client-basepath pastehub-client-get)))
	 (pastehub-concat-path pastehub-client-basepath pastehub-client-get))
	((file-exists-p pastehub-default-client-get)
	 pastehub-default-client-get)
	(t
	 pastehub-client-get)))

;;
;; Version
;;
(defconst pastehub-version
  "0.9.2"
  )
(defun pastehub-version (&optional arg)
  "display version"
  (interactive "P")
  (message pastehub-version))


;;
;; Paste
;;
(defun posthub-post-internal ()
  (when (car kill-ring)
    (with-temp-buffer
      (insert (substring-no-properties (car kill-ring)))
      (call-process-region (point-min) (point-max)
                           (get-pastehub-client-post)))))

(defadvice kill-new (after pastehub-post activate)
  "Post the latest killed text to pastehub cloud service."
  (when pastehub-mode
    (posthub-post-internal)))

(ad-activate 'kill-new)

(defadvice insert-for-yank-1 (after pastehub-insert-for-yank-1 activate)
  "reset unread counter."
  (when pastehub-mode
    (setq pastehub-unread-count 0)))

(ad-activate 'insert-for-yank-1)


;;
;; Poll & Sync
;;
(defun pastehub-call-process (process-name arg1 arg2)
  "call-process and return output string of the command."
  (let ((outbuf (get-buffer-create "*pastehub output*")))
    (with-current-buffer (buffer-name outbuf)
      (delete-region (point-min) (point-max)))
    (with-temp-buffer
      (call-process process-name
                    nil ;; infile
                    outbuf
                    nil ;; display
                    arg1
                    arg2))
    (with-current-buffer (buffer-name outbuf)
      (let ((result-str (buffer-substring-no-properties (point-min) (point-max))))
        result-str))))

;; like scheme's `take'
(defun pastehub-take (lst n)
  (reverse (last (reverse lst)
                 n)))

(defun pastehub-sync-kill-ring ()
  "sync kill-ring"
  (message "syncing kill-ring...")
  (let ((value (pastehub-call-process (get-pastehub-client-get) "get" ""))
	(old   (car kill-ring)))
    (push value kill-ring)
    (setq kill-ring-yank-pointer kill-ring)
    (when (not (string-equal old (car kill-ring)))
      (setq pastehub-unread-count
	    (+ pastehub-unread-count 1))))
  (message nil))


(defun latest-date-of-file (file-name)
  "Latest modify time of file-name"
  (progn
    (let* (
	   (f-attr (file-attributes file-name))
	   (m-time (nth 5 f-attr)))
      (format-time-string "%s" m-time))))
	   
(defun pastehub-timer-handler ()
  "polling process handler for pastehub service."
  (when pastehub-mode
    (let ((latest-date
	   (if (file-exists-p pastehub-sync-dir)
	       (latest-date-of-file pastehub-sync-dir)
	     (pastehub-call-process (get-pastehub-client-get) "time" ""))))
      (if (not (string-equal pastehub-latest-date latest-date))
          (progn
            (setq pastehub-latest-date latest-date)
            (pastehub-sync-kill-ring))))))

(defun pastehub-sigusr-handler ()
  (interactive)
  ;;(message "Caught signal %S" last-input-event)
  (pastehub-timer-handler))


;; initialize
(define-key special-event-map [sigusr1] 'pastehub-sigusr-handler)
(setq pastehub-timer-object
      (run-at-time t  pastehub-check-interval  'pastehub-timer-handler))


;; mode changer
(defun pastehub-mode (&optional arg)
  "Pastehub mode changer"
  (interactive "P")
  (setq pastehub-mode (if (null arg) (not pastehub-mode)
                        (> (prefix-numeric-value arg) 0))))


;; Check the pastehubGet binary is installed.
(let ((exec-name (get-pastehub-client-get)))
  (if (executable-find exec-name)
      ;; enable pastehub-mode
      (progn
	(message (format "OK: Detected pastehubGet program [%s]" exec-name))
	(setq pastehub-mode t)
	(pastehub-timer-handler) ;; one shot for initializing.
	)
    (message (format "NG: Couldn't detect pastehubGet program [%s]... disabled pastehub.el" exec-name))))

(provide 'pastehub)

;; Local Variables:
;; coding: utf-8
;; End:

;;; pastehub.el ends here
