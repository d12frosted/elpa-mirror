;;; kconfig-ref.el --- A simple package for looking up kconfig symbol quickly
;;
;; Copyright (C) 2023 Jason Kim
;;
;; Author: Jason Kim <sukbeom.kim@gmail.com>
;; Maintainer: Jason Kim <sukbeom.kim@gmail.com>
;; Created: February 19, 2023
;; Modified: February 19, 2023
;; Version: 0.1.0
;; Package-Version: 20230220.1207
;; Package-Commit: dfb127fa5ac003a06f108d2e876c84a1931e5678
;; Keywords: tools, kconfig, linux, kernel
;; Homepage: https://github.com/seokbeomkim/kconfig-ref
;; Package-Requires: ((emacs "24.4") (ripgrep "0.4.0") (projectile "2.7.0"))

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This is a simple package for looking up kconfig symbols and values with
;; parsing the .config file in the Linux kernel directory.

;; Setup:

;; (require 'kconfig-ref)

;;; Code:

(require 'ripgrep)
(require 'projectile)

(defvar kconfig-ref-config-file ".config")
(defvar kconfig-ref-last-find-config nil)
(defvar kconfig-ref-backup-buffer nil)

;;;###autoload
(defun kconfig-ref-config-file-exist ()
  "Check .config exists in the Linux kernel source tree."
  (file-exists-p (concat (projectile-acquire-root) ".config")))

;;;###autoload
(defun kconfig-ref-parse-item (line)
  "Add dependency information through parsing .config.
Argument LINE A line of the Kconfig definition block."
  (when (string-match "depends on" line)
    ;; if .config does not exist, skip to parse .config file
    (if (not (kconfig-ref-config-file-exist))
	(message "No .config in the kernel root directory.")
      (progn
	(let ((dependencies (substring line (match-end 0))))
	  (dolist (depend (split-string dependencies "&&\\|||"))
	    (message (string-trim depend))
	    (let ((depend-on (string-trim depend))
		  (backup-buffer (current-buffer)))
	      (find-file (concat (projectile-acquire-root) kconfig-ref-config-file))
	      (goto-char (point-min))
	      (condition-case err
		  (progn
		    (if (re-search-forward (concat "CONFIG_" depend-on "=\\(.*\\)"))
			(setq line (replace-regexp-in-string depend-on
							     (concat depend-on "[=" (match-string 1) "]")
							     line))
		      (setq line (replace-regexp-in-string depend-on
							   (concat depend-on "[=N]")
							   line))))
		(search-failed
		 (progn
		   (message "No match found (%s) in .config" depend-on)
		   (setq line (replace-regexp-in-string depend-on
							(concat depend-on "[=N]")
							line)))))
	      (switch-to-buffer backup-buffer)))))))
  line)

;;;###autoload
(defun kconfig-ref-find-file-hook ()
  "Ripgrep search hook."

  (let ((output-buffer-name "*kconfig-ref*")
	(kconfig-output-string "")
	(ripgrep-search-buffer-name (concat "*ripgrep-search*<" (projectile-project-name) ">")))
    (if (not (buffer-live-p (get-buffer ripgrep-search-buffer-name)))
	(setq ripgrep-search-buffer-name "*ripgrep-search*"))
    (get-buffer-create output-buffer-name)
    (with-current-buffer ripgrep-search-buffer-name
      (message (buffer-name))
      (goto-char (point-min))
      (when (re-search-forward "\\(.*\\):\\(.*\\):\\([ \t]*config.*\\)")
	(let ((kconfig-path (match-string 1))
	      (kconfig-lnum (match-string 2))
	      (kconfig-item (match-string 3))
	      (kconfig-done nil))
	  (setq kconfig-output-string
		(concat (format "Found in [[%s::%s][%s]]\n\n"
				(concat (projectile-acquire-root) kconfig-path)
				kconfig-lnum
				kconfig-path)
			kconfig-ref-last-find-config "\n"))
	  (find-file kconfig-path)
	  (goto-char (point-min))
	  (search-forward kconfig-item)
	  (forward-line 1)
	  (beginning-of-line)
	  (while (and
		  (not (eobp))
		  (equal kconfig-done nil))
	    (let ((line (buffer-substring-no-properties
			 (line-beginning-position) (line-end-position))))
	      ;; Check block is ended
	      (if (not (string-match "^[ \t]*config [A-Z_]+" line))
		  (progn
		    (setq kconfig-output-string
			  (concat kconfig-output-string (kconfig-ref-parse-item line) "\n"))
		    ;; (setq kconfig-output-string (concat kconfig-output-string line "\n"))
		    (forward-line 1))
		(setq kconfig-done t))))
	  (kill-buffer)))
      (kill-buffer ripgrep-search-buffer-name))
    (with-current-buffer output-buffer-name
      (erase-buffer)
      (insert kconfig-output-string "\n")
      (other-window 1)
      (switch-to-buffer output-buffer-name)
      (org-mode)
      (read-only-mode t)
      (goto-char (point-min))))
  (other-window 1)
  (switch-to-buffer kconfig-ref-backup-buffer)
  (remove-hook 'ripgrep-search-finished-hook #'kconfig-ref-find-file-hook))

;;;###autoload
(defun kconfig-ref-find-file-with-name (name)
  "Set config-key as search keyword such as \"config SPI\".
Argument NAME kconfig symbol name."
  (let ((config-key (concat "config " name)))
    (setq kconfig-ref-last-find-config config-key)
    (add-hook 'ripgrep-search-finished-hook #'kconfig-ref-find-file-hook)
    (ripgrep-regexp config-key
		    (projectile-acquire-root)
		    '("-g 'Kconfig*'" ))))

;;;###autoload
(defun kconfig-ref-find-config ()
  "Find kconfig deinifition under the cursor."
  (interactive)
  (setq kconfig-ref-backup-buffer (current-buffer))
  (setq-local valid-input (replace-regexp-in-string "^CONFIG_" "" (current-word)))
  (kconfig-ref-find-file-with-name valid-input))

(provide 'kconfig-ref)
;;; kconfig-ref.el ends here
