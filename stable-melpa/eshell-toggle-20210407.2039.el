;;; eshell-toggle.el --- Show/hide eshell under active window. -*- lexical-binding: t -*-

;; Copyright (C) 2015, 2016  Dmitry Cherkasov

;; Author: Dmitry Cherkassov <dcherkassov@gmail.com>
;; Maintainer: Dmitry Cherkassov <dcherkassov@gmail.com>
;; URL: https://github.com/4da/eshell-toggle
;; Package-Version: 20210407.2039
;; Package-Commit: 7160518ca56444fead841b8acff59aeffc7cebb3
;; Version: 0.10.0
;; Package-Requires: ((emacs "25.1")(dash "2.11.0"))
;; Keywords: processes

;; This file is part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Call `eshell-toggle' to toggle eshell for current buffer.
;; Show eshell at the bottom of current window cd to current buffer's path.
;; If eshell-toggle'd buffer is already visible in frame for current buffer or current window is (toggled) eshell itself then hide it.

(require 'dash)
(require 'eshell)
(require 'esh-mode)
(require 'term)
(require 'subr-x)

;;; Customization

;;; Code:

(defgroup eshell-toggle nil
  "Customize group for eshell-toggle.el"
  :group 'emacs)

(define-obsolete-variable-alias 'eshell-toggle-height-fraction 'eshell-toggle-size-fraction "0.10.0")

(defcustom eshell-toggle-size-fraction
  3
  "Proportion of parent window size and eshell window."
  :type 'integer
  :group 'eshell-toggle)

(defcustom eshell-toggle-window-side
  'below
  "Eshell-toggle buffer position.  See `split-window'."
  :type '(choice (const 'above)
                 (const 'below)
                 (const 'left)
                 (const 'right))
  :group 'eshell-toggle)

(defcustom eshell-toggle-default-directory
  nil
  "Default directory to open eshell at if buffer has no associated file."
  :type 'directory
  :group 'eshell-toggle)

(defcustom eshell-toggle-use-projectile-root
  nil
  "Open eshell at projectile's project root if not nil."
  :type '(choice (const :tag "Disabled" nil)
                 (const :tag "Enabled" t))
  :group 'eshell-toggle)

(defcustom eshell-toggle-name-separator
  ":"
  "String to separate directory paths when giving a name to buffer."
  :type 'string
  :group 'eshell-toggle)

(defcustom eshell-toggle-init-term-char-mode
  nil
  "Switch `ansi-term' buffer to ‘term-char-mode’ after init.  Bind `eshell-toggle' in `term-raw-map'."
  :type 'boolean
  :group 'eshell-toggle)

(defcustom eshell-toggle-run-command
  "ls"
  "Command to run in a new shell if any."
  :type '(choice (const :tag "None" nil)
                 (string :tag "Command"))
  :group 'eshell-toggle)

(defcustom eshell-toggle-init-function
  'eshell-toggle-init-eshell
  "Function to init toggle buffer."
  :type 'function
  :group 'eshell-toggle)

(defcustom eshell-toggle-use-git-root
  nil
  "Open eshell at git root directory, if exists."
  :type '(choice (const :tag "Disabled" nil)
                 (const :tag "Enabled" t))
  :group 'eshell-toggle)

(defvar eshell-toggle--toggle-buffer-p nil)
(make-variable-buffer-local 'eshell-toggle--toggle-buffer-p)

(declare-function vc-find-root "vc-hooks")

(defun eshell-toggle-get-git-directory (dir)
  "Returns directory path of git project root directory, otherwise return nil."
  (require 'vc)
  (funcall (lambda ()
	     (vc-find-root dir ".git"))))

(declare-function projectile-project-root "ext:projectile")
(declare-function projectile-project-name "ext:projectile")

(defun eshell-toggle--get-directory ()
  "Return default directory for current buffer."
  (or
   (if eshell-toggle-use-projectile-root
       (condition-case nil
           (projectile-project-root)
         (error nil)))
   (if eshell-toggle-use-git-root
       (condition-case nil
	   (eshell-toggle-get-git-directory default-directory)
         (error nil)))
   eshell-toggle-default-directory
   default-directory))

(defun eshell-toggle--make-buffer-name ()
  "Generate toggle buffer name."
  (if eshell-toggle-use-projectile-root
      (concat "*et" eshell-toggle-name-separator (projectile-project-name) "*")
    (let* ((dir (eshell-toggle--get-directory))
           (name (string-join (split-string dir "/") eshell-toggle-name-separator))
           (buf-name (concat "*et" name "*")))
      buf-name)))

(defun eshell-toggle-init-eshell (dir)
  "Init `eshell' buffer with DIR."
  (let ((default-directory dir))
    (eshell "new")
    (when eshell-toggle-run-command
      (insert eshell-toggle-run-command)
      (eshell-send-input))))


(defun eshell-toggle--init-term (&optional input)
  "Init `ansi-term' and send INPUT string to it."
  (ansi-term (getenv "SHELL"))
  (term-line-mode)
  (when input
    (insert input)
    (term-send-input))
  (when eshell-toggle-init-term-char-mode
    (term-char-mode)))

(defun eshell-toggle-init-ansi-term (dir)
  "Init `ansi-term' buffer with DIR."
  (let ((default-directory dir))
    (eshell-toggle--init-term eshell-toggle-run-command)))

(defun eshell-toggle-init-tmux (dir)
  "Init tmux `ansi-term' buffer with DIR."
  (eshell-toggle--init-term (format "tmux new -A -c '%s' -s '%s'" dir dir)))


(defun eshell-toggle--window-size ()
  "Width or height of the selected window, depends on `eshell-toggle-window-side'."
  (if (memq eshell-toggle-window-side '(left right))
      (window-text-width)
    (window-total-height)))

(defun eshell-toggle--split-window ()
  "Split window according to customization."
  (let* ((size (/ (eshell-toggle--window-size) eshell-toggle-size-fraction))
         (count (if (memq eshell-toggle-window-side '(above left)) -1 1)))
    (split-window nil (- size) eshell-toggle-window-side)
    (other-window count)))

(defun eshell-toggle--new-buffer (buf-name)
  "Init BUF-NAME."
  (funcall eshell-toggle-init-function (eshell-toggle--get-directory))
  (rename-buffer buf-name)
  (setq eshell-toggle--toggle-buffer-p t))

;;;###autoload
(defun eshell-toggle (&optional keep-visible)
  "Show eshell at the bottom of current window and cd to current buffer's path.
(1) If eshell-toggle'd buffer is already visible in frame for
current buffer then select (toggled) eshell window.
(2) If current window is (toggled) eshell itself then hide it.
(3) If KEEP-VISIBLE is non-nil, (toggled) eshell window will stay
visible and will not be hidden."
  (interactive)
  (if (eq eshell-toggle--toggle-buffer-p t)
      (unless keep-visible
        ;; if selected window is eshell-toggle buffer itself just delete its window
        (delete-window))    
    (let ((buf-name (eshell-toggle--make-buffer-name)))
      (if (get-buffer buf-name)
	  ;; buffer is already created
          (or (-some-> buf-name get-buffer-window delete-window)
	      (eshell-toggle--split-window)
              (switch-to-buffer buf-name))
        ;; buffer is not created, create it
        (eshell-toggle--split-window)
        (eshell-toggle--new-buffer buf-name)
        (switch-to-buffer buf-name)))))

(when eshell-toggle-init-term-char-mode
  (dolist (kb (where-is-internal 'eshell-toggle))
    (define-key term-raw-map kb 'eshell-toggle)))

(provide 'eshell-toggle)

;;; eshell-toggle.el ends here
