;;; read-only-cfg.el --- Make files read-only based on user config -*- lexical-binding: t; -*-

;; Copyright (C) 2021 pfchen

;; Author: pfchen <pfchen31@gmail.com>
;; Version: 0.1.0
;; Package-Version: 20210717.205
;; Package-Commit: a4e50d4fbf48970e98b2464e13f46e51a4c43c37
;; Package-Requires: ((emacs "24.3"))
;; Keywords: tools, convenience
;; URL: https://github.com/pfchen/read-only-cfg

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even thea implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; `read-only-cfg' is a GNU Emacs minor mode that can automatically make
;;  files read-only based on user configuration.  User configuration is
;;  very simple and only consists of prefix directories or regex patterns.

;; Installation

;; The package is available on `MELPA'.  To use the `MELPA' repository,
;; you can add the following codes to your init.el.
;;
;;     (require 'package)
;;     (add-to-list 'package-archives
;;		    '("melpa" . "https://melpa.org/packages/") t)
;;     (package-initialize)
;;     (package-refresh-contents)
;;
;; Now you can install `read-only-cfg' with:
;;
;;     M-x package-install RET read-only-cfg RET
;;
;; And enable with:
;;
;;     (require 'read-only-cfg)
;;     (read-only-cfg-mode 1)
;;
;;
;; Alternatively, you can manually download or clone this repository
;; locally, and add this to your init.el:
;;
;;     (add-to-list 'load-path "/path/to/read-only-cfg")
;;     (autoload 'read-only-cfg "read-only-cfg" nil t)
;;     (require 'read-only-cfg)
;;     (read-only-cfg-mode 1)

;; Usage

;; Add a read-only directory:
;;
;;     M-x read-only-cfg-add-dir RET /path/to/you-directory RET
;;
;; Add a read-only regex pattern:
;;
;;     M-x read-only-cfg-add-regexp RET <regexp> RET
;;
;; Or add this into your config:
;;
;;     (require 'read-only-cfg)
;;     (read-only-cfg-add-dir "/path/to/your-directory/")
;;     (read-only-cfg-add-regexp "<regexp>")
;;
;; And remove a read-only directory:
;;
;;     M-x read-only-cfg-remove-dir RET /path/to/your-directory RET
;;
;; Remove a read-only regex pattern:
;;
;;     M-x read-only-cfg-remove-regexp RET <regexp> RET
;;

;; Customization

;; Customize variable `read-only-cfg-update-file-buffer-state' to
;; determine whether to update the read-only state of all existing
;; file-buffer when this mode is enabled or disabled.

;;; Code:
(defgroup read-only-cfg nil
  "Make files read-only based on config."
  :prefix "read-only-cfg-"
  :group 'files)

(defcustom read-only-cfg-dirs
  ()
  "List of all user defined read-only directories."
  :type '(repeat (string :tag "Read-only directory"))
  :group 'read-only-cfg)

(defcustom read-only-cfg-regexps
  ()
  "List of all user defined read-only regex patterns."
  :type '(repeat (regexp :tag "Read-only regex pattern"))
  :group 'read-only-cfg)

(defcustom read-only-cfg-update-file-buffer-state
  t
  "Whether update buffer state when this mode is enabled or disabled.
If this flag is non-nil, the read-only state of all existing
buffers associated with files will be changed when the
read-only-cfg mode is enabled or disabled.

Default is non-nil."
  :type '(boolean)
  :group 'read-only-cfg)

(defun read-only-cfg--regexp-valid-p (string)
  "Return non-nil if STRING is a valid regex pattern."
  (condition-case err
      (prog1 t (string-match-p string ""))
    (error (message (error-message-string err)) nil)))

(defun read-only-cfg--match-dirs-p (file-name)
  "Return non-nil if FILE-NAME matched user defined prefix directories."
  (catch 'done
    (dolist (dir read-only-cfg-dirs)
      (when (string-prefix-p dir (file-name-as-directory file-name))
        (throw 'done t)))
    nil))

(defun read-only-cfg--match-regexps-p (file-name)
  "Return non-nil if FILE-NAME matched user defined regex patterns."
  (catch 'done
    (dolist (regexp read-only-cfg-regexps)
      (when (string-match-p regexp file-name)
        (throw 'done t)))
    nil))

(defun read-only-cfg--match-p (file-name)
  "Return non-nil if FILE-NAME matched user defined config."
  (if (or (read-only-cfg--match-dirs-p file-name)
          (read-only-cfg--match-regexps-p file-name))
      t
    nil))

(defun read-only-cfg--find-file-handler ()
  "A read-only handler of `find-file-hook'."
  (when (read-only-cfg--match-p (buffer-file-name))
    (read-only-mode 1)))

(defun read-only-cfg--update-buffers (v)
  "Update the read-only state of existing file buffers with value V."
  (when read-only-cfg-update-file-buffer-state
    (dolist (buf (buffer-list))
      (when (and (buffer-file-name buf)
                 (read-only-cfg--match-p (buffer-file-name buf)))
        (with-current-buffer buf
          (read-only-mode v))))))

(defun read-only-cfg--delay-saving-handler ()
  "A handler is used to save config outside Customize for future session.
The main reason for using this handler to delay saving config is to avoid
conflicts with Customize which will automatically insert
`custom-set-variables' in the init file.  If we don't that, our previous
config will be overwritten by`custom-set-variables'."
  (let ((delay-saving-dirs (get 'read-only-cfg-dirs 'delay-saving-items))
        (dirs-changed nil)
        (delay-saving-regexps (get 'read-only-cfg-regexps 'delay-saving-items))
        (regexps-changed nil))

    ;; Add or remove delay-saving dirs
    (dolist (pair (reverse delay-saving-dirs))
      (if (equal (car pair) "add")
          (unless (member (cdr pair) read-only-cfg-dirs)
            (setq dirs-changed t)
            (add-to-list 'read-only-cfg-dirs (cdr pair)))
        (when (member (cdr pair) read-only-cfg-dirs)
          (setq dirs-changed t)
          (setq read-only-cfg-dirs (delete (cdr pair) read-only-cfg-dirs)))))

    ;; Add or remove delay-saving regexps
    (dolist (pair (reverse delay-saving-regexps))
      (if (equal (car pair) "add")
          (unless (member (cdr pair) read-only-cfg-regexps)
            (setq regexps-changed t)
            (add-to-list 'read-only-cfg-regexps (cdr pair)))
        (when (member (cdr pair) read-only-cfg-regexps)
          (setq regexps-changed t)
          (setq read-only-cfg-regexps (delete (cdr pair) read-only-cfg-regexps)))))

    ;; Save to custom-file
    (when dirs-changed
      (customize-save-variable 'read-only-cfg-dirs read-only-cfg-dirs))
    (when regexps-changed
      (customize-save-variable 'read-only-cfg-regexps read-only-cfg-regexps))

    ;; Reset
    (put 'read-only-cfg-dirs 'delay-saving-items nil)
    (put 'read-only-cfg-regexps 'delay-saving-items nil)))

(add-hook 'emacs-startup-hook #'read-only-cfg--delay-saving-handler)

(defun read-only-cfg--add-delay-saving-item (symbol action item)
  "Add a delay-saving ITEM with ACTION into SYMBOL properties section."
  (let ((pair (cons action item))
        (delay-saving-items (get symbol 'delay-saving-items)))
    (unless (member pair delay-saving-items)
      (put symbol 'delay-saving-items
           (push pair delay-saving-items)))))

;;;###autoload
(defun read-only-cfg-add-dir (dir)
  "Add a read-only directory DIR."
  (interactive "DRead-only directory: ")
  (let ((dir (file-name-as-directory (file-truename dir))))
    (if (called-interactively-p 'any)
        (progn
          (add-to-list 'read-only-cfg-dirs dir)
          (customize-save-variable 'read-only-cfg-dirs read-only-cfg-dirs)
          (message "Added a read-only directory: %s" dir))
      (read-only-cfg--add-delay-saving-item 'read-only-cfg-dirs "add" dir))))

;;;###autoload
(defun read-only-cfg-add-regexp (regexp)
  "Add a read-only regex pattern REGEXP."
  (interactive "sRead-only regex pattern: ")
  (when (read-only-cfg--regexp-valid-p regexp)
    (if (called-interactively-p 'any)
        (progn
          (add-to-list 'read-only-cfg-regexps regexp)
          (customize-save-variable 'read-only-cfg-regexps read-only-cfg-regexps)
          (message "Added a regex pattern: %s" regexp))
      (read-only-cfg--add-delay-saving-item 'read-only-cfg-regexps "add" regexp))))

;;;###autoload
(defun read-only-cfg-remove-dir (dir)
  "Remove a read-only directory DIR."
  (interactive "DRead-only directory: ")
  (let ((dir (file-name-as-directory (file-truename dir))))
    (when (member dir read-only-cfg-dirs)
      (if (called-interactively-p 'any)
          (progn
            (setq read-only-cfg-dirs (delete dir read-only-cfg-dirs))
            (customize-save-variable 'read-only-cfg-dirs read-only-cfg-dirs)
	    (message "Removed a read-only directory: %s" dir))
        (read-only-cfg--add-delay-saving-item 'read-only-cfg-dirs "remove" dir)))))

;;;###autoload
(defun read-only-cfg-remove-regexp (regexp)
  "Remove a read-only regex pattern REGEXP."
  (interactive "sRead-only regex pattern: ")
  (when (and (read-only-cfg--regexp-valid-p regexp)
             (member regexp read-only-cfg-regexps))
    (if (called-interactively-p 'any)
        (progn
          (setq read-only-cfg-regexps (delete regexp read-only-cfg-regexps))
          (customize-save-variable 'read-only-cfg-regexps read-only-cfg-regexps)
	  (message "Removed a read-only regex pattern: %s" regexp))
      (read-only-cfg--add-delay-saving-item 'read-only-cfg-regexps "remove" regexp))))

;;;###autoload
(define-minor-mode read-only-cfg-mode
  "Minor mode for making files read-only based on config."
  nil " RoCfg" nil
  :global t
  (if read-only-cfg-mode
      (progn
        (add-hook 'find-file-hook #'read-only-cfg--find-file-handler)
        (read-only-cfg--update-buffers 1))
    (progn
      (remove-hook 'find-file-hook #'read-only-cfg--find-file-handler)
      (read-only-cfg--update-buffers -1))))

(provide 'read-only-cfg)

;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; checkdoc-minor-mode: t
;; End:

;;; read-only-cfg.el ends here
