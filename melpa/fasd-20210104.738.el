;;; fasd.el --- Emacs integration for the command-line productivity booster `fasd'

;; Copyright (C) 2013 steckerhalter

;; Author: steckerhalter
;; URL: https://framagit.org/steckerhalter/emacs-fasd
;; Package-Version: 20210104.738
;; Package-Commit: c1d92553f33ebb018135c698db1a6d7f86731a26
;; Keywords: cli bash zsh autojump

;;; Commentary:

;; Hooks into to `find-file-hook' to add all visited files and directories to `fasd'.
;; Adds the function `fasd-find-file' to prompt and fuzzy complete available candidates

;;; Requirements:

;; `fasd' command line tool, see: https://github.com/clvv/fasd
;; `grizzl' for fuzzy completion

;;; Usage:

;; (require 'fasd)
;; (global-fasd-mode 1)

;; Optionally bind `fasd-find-file' to a key:
;; (global-set-key (kbd "C-h C-/") 'fasd-find-file)

;;; Code:

(defgroup fasd nil
  "Navigate previously-visited files and directories easily"
  :group 'tools
  :group 'convenience)

(defcustom fasd-enable-initial-prompt t
  "Specify whether to enable prompt for the initial query.

When set to nil, all fasd results are returned for completion"
  :type 'boolean)

(defcustom fasd-file-manager 'dired
  "A default set of file managers to use with `fasd-find-file'"
  :type '(radio
          (const :tag "Use `dired', default emacs file manager" dired)
          (const :tag "Use `deer', ranger's file manager" deer)
          (function :tag "Custom predicate")))

(defcustom fasd-standard-search "-a"
  "`fasd' standard search parameter.
This parameter is overridden by PREFIX given to `fasd-find-file'
Fasd has the following options:
`-a' match files and directories
`-d' match directories only
`-f' match files only
`-r' match by rank only
`-t' match by recent access only
to specify multiple flags separate them by spaces, e.g. `-a -r'"
  :type 'string)

  (defun fasd-find-file-action (file)
    (if (file-readable-p file)
        (if (file-directory-p file)
            (if (fboundp 'counsel-find-file)
                (counsel-find-file file)
              (funcall fasd-file-manager file))
          (find-file file))
      (message "Directory or file `%s' doesn't exist" file)))

(when (featurep 'ivy)
  (ivy-set-actions
   'fasd-find-file
   '(("o" fasd-find-file-action "find-file"))))

;;;###autoload
(defun fasd-find-file (prefix &optional query)
  "Use fasd to open a file, or a directory with dired.
If PREFIX is positive consider only directories.
If PREFIX is -1 consider only files.
If PREFIX is nil consider files and directories.
QUERY can be passed optionally to avoid the prompt."
  (interactive "P")
  (if (not (executable-find "fasd"))
      (error "Fasd executable cannot be found.  It is required by `fasd.el'.  Cannot use `fasd-find-file'")
    (unless query (setq query (if fasd-enable-initial-prompt
                                  (read-from-minibuffer "Fasd query: ")
                                "")))
    (let* ((prompt "Fasd query: ")
           (results
            (split-string
             (shell-command-to-string
              (concat "fasd -l -R"
                      (pcase (prefix-numeric-value prefix)
                        (`-1 " -f ")
                        ((pred (< 1)) " -d ")
                        (_ (concat " " fasd-standard-search " ")))
                      query))
             "\n" t))
           (file (when results
                   ;; set `this-command' to `fasd-find-file' is required because
                   ;; `read-from-minibuffer' modifies its value, while `ivy-completing-read'
                   ;; assumes it to be its caller
                   (setq this-command 'fasd-find-file)
                   (completing-read prompt results nil t))))
        (if (not file)
            (message "Fasd found nothing for query `%s'" query)
            (unless (featurep 'ivy)
              (fasd-find-file-action file))))))

;;;###autoload
(defun fasd-add-file-to-db ()
  "Add current file or directory to the Fasd database."
  (if (not (executable-find "fasd"))
      (message "Fasd executable cannot be found. It is required by `fasd.el'. Cannot add file/directory to the fasd db")
    (let ((file (if (string= major-mode "dired-mode")
                    dired-directory
                  (buffer-file-name))))
      (when (and file
                 (stringp file)
                 (file-readable-p file))
        (start-process "*fasd*" nil "fasd" "--add" file)))))

;;;###autoload
(define-minor-mode global-fasd-mode
  "Toggle fasd mode globally.
   With no argument, this command toggles the mode.
   Non-null prefix argument turns on the mode.
   Null prefix argument turns off the mode."
  :global t
  :group 'fasd

  (if global-fasd-mode
      (progn (add-hook 'find-file-hook 'fasd-add-file-to-db)
             (add-hook 'dired-mode-hook 'fasd-add-file-to-db))
    (remove-hook 'find-file-hook 'fasd-add-file-to-db)
    (remove-hook 'dired-mode-hook 'fasd-add-file-to-db)))

(provide 'fasd)
;;; fasd.el ends here
