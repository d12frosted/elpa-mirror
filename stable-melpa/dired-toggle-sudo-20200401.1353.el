;;; dired-toggle-sudo.el --- Browse directory with sudo privileges.

;; Copyright © 2011 Sebastien Gross <seb•ɑƬ•chezwam•ɖɵʈ•org>

;; Author: Sebastien Gross <seb•ɑƬ•chezwam•ɖɵʈ•org>
;; Keywords: emacs, dired
;; Package-Version: 20200401.1353
;; Package-Commit: 13bbe52c54893f5aa3e56228450ffdd0c9e1d169
;; Created: 2011-07-06
;; Last changed: 2020-04-01 15:52:40
;; Licence: WTFPL, grab your copy here: http://sam.zoy.org/wtfpl/

;; This file is NOT part of GNU Emacs.

;;; Commentary:
;;
;; Allow to switch from current user to sudo when browsind `dired' buffers.
;;
;; To activate and swit with "C-c C-s" just put in your .emacs:
;;
;; (require 'dired-toggle-sudo)
;; (define-key dired-mode-map (kbd "C-c C-s") 'dired-toggle-sudo)
;; (eval-after-load 'tramp
;;  '(progn
;;     ;; Allow to use: /sudo:user@host:/path/to/file
;;     (add-to-list 'tramp-default-proxies-alist
;;		  '(".*" "\\`.+\\'" "/ssh:%h:"))))



;;; Code:

(require 'files)
(require 'tramp)
(require 'dired)

(defun dired-toggle-sudo-internal (path &optional sudo-user)
  "Convert PATH to its sudoed version. root is used by default
unless SUDO-USER is provided."
  (let* (;; Handle the case of local files. `tramp-dissect-file-name' does
	 ;; not raise an error anymore.
	 (tramp-pseudo-method (if (> emacs-major-version 25)
				  "/-::" "/:"))
	 (path (if (tramp-tramp-file-p path)
		   path
		 (concat tramp-pseudo-method path)))
	 (file-vec (or (ignore-errors (tramp-dissect-file-name
				       path))
		       (tramp-dissect-file-name
			(concat tramp-pseudo-method path) 1)))
	 (method  (tramp-file-name-method file-vec))
	 (user (tramp-file-name-user file-vec))
	 (host  (tramp-file-name-host file-vec))
	 (localname (expand-file-name
		     (tramp-file-name-localname file-vec))))
    ;; (message "(tramp-make-tramp-file-name %s %s %s %s %s %s)"
    ;; 	     method
    ;; 	     (tramp-file-name-domain file-vec)
    ;; 	     user host
    ;; 	     (tramp-file-name-port file-vec)
    ;; 	     localname)
    (when (or (string= system-name host)
	      (string= "-" host))
      (setq host nil))
    (cond
     ;; remote directory -> sudo
     ((and host (string= method "ssh"))
      (setq method "sudo" user sudo-user))
     ;; remote directory -> normal
     ((and host (string= method "sudo"))
      (setq method "ssh" user nil))
     ;; Local directory -> normal
     ((and (not host) (string= method "ssh"))
      (setq method "sudo"))
     ;; Local directory -> sudo
     ((and (not host) (string= method "sudo"))
      (setq method nil user sudo-user))
     ;; Local directory -> normal
     (t
      (setq method "sudo" user sudo-user)))
    ;; (message "%s -> %s" path file-vec)
    ;; (message "(tramp-make-tramp-file-name %s %s %s %s %s %s)"
    ;; 	     method
    ;; 	     (tramp-file-name-domain file-vec)
    ;; 	     user host
    ;; 	     (tramp-file-name-port file-vec)
    ;; 	     localname)
    (replace-regexp-in-string
     "^/:/" "/"
     (if (> emacs-major-version 25)
	 (tramp-make-tramp-file-name method
				     user
				     (tramp-file-name-domain file-vec)
				     host
				     (tramp-file-name-port file-vec)
				     localname)
	 (tramp-make-tramp-file-name method user host localname)))))

(defun dired-toggle-sudo-find (fname)
  "Create a new buffer for file name FNAME."
  (let ((save-point (point)))
    (find-alternate-file fname)
    (goto-char save-point)))

;;;###autoload
(defun dired-toggle-sudo (&optional sudo-user)
  "Reopen current file or dired buffer with sudo.

If SUDO-USER is nil assume root.

If called with `universal-argument' (C-u), ask for username.
"
  (interactive "P")
  (let* ((fname (or buffer-file-name
		    dired-directory))
	 (sudo-user (if current-prefix-arg
			(read-string "Username: ")
		      sudo-user))
	 (orig (current-buffer))
         (file-now (if (eq major-mode 'dired-mode)
                       (dired-get-filename t))))
    (when fname
      (setq fname (dired-toggle-sudo-internal fname sudo-user))
      (if (not (eq major-mode 'dired-mode))
	  (dired-toggle-sudo-find fname)
	(kill-buffer orig)
	(dired fname)
        (when file-now
          (dired-goto-file (expand-file-name file-now fname)))))))

(provide 'dired-toggle-sudo)

;;; dired-toggle-sudo.el ends here
