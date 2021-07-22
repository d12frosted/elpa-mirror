;;; su.el --- Automatically read and write files using su or sudo -*- lexical-binding: t -*-

;; Copyright (C) 2018 PythonNut

;; Author: PythonNut <pythonnut@pythonnut.com>
;; SPDX-License-Identifier: MIT
;; Keywords: convenience, helm, fuzzy, flx
;; Package-Version: 20210721.1816
;; Package-Commit: 1ecf7a7bbf9d88708eb2215e940753f8d6bccc92
;; Version: 20200819
;; URL: https://github.com/PythonNut/su.el
;; Package-Requires: ((emacs "26.1"))

;;; Commentary:

;; This package facilitates automatic privilege escalation for file
;; permissions using TRAMP.

;; You can install the package by either cloning it yourself, or by
;; doing M-x package-install RET su RET.

;; After that, you can enable it by putting the following in your init
;; file:

;;     (su-mode +1)

;; When `su-mode' is enabled, you will be able to edit files which you
;; lack permissions to write. `su-mode' will automatically switch the
;; visited path to a TRAMP path encoding the correct privelege
;; escalation just before you save the file. See the README for more
;; info.

;;; Code:
(require 'cl-lib)

(eval-when-compile
  (with-demoted-errors "Byte-compile: %s"
    (require 'tramp)
    (require 'nadvice)))

(declare-function tramp-tramp-file-p "tramp.el" t t)
(declare-function tramp-dissect-file-name "tramp.el" t t)
(declare-function tramp-make-tramp-file-name "tramp.el" t t)

(defgroup su nil
  "Automatically read and write files as users"
  :group 'convenience
  :prefix "su-")

(defcustom su-auto-make-directory t
  "Automatically become other users to create directories."
  :type 'boolean
  :group 'su)

(defcustom su-auto-write-file t
  "Automatically become other users to write files."
  :type 'boolean
  :group 'su)

(defcustom su-auto-read-file t
  "Automatically become other users to read files."
  :type 'boolean
  :group 'su)

(defcustom su-auto-save-mode-lighter
  (list " " (propertize "root" 'face 'tty-menu-selected-face))
  "The mode line lighter for function `su-auto-save-mode'."
  :type 'list
  :group 'su)

(defcustom su-sudo-method "sudo"
  "TRAMP method to use to edit with sudo."
  :type '(choice (const :tag "sudo" "sudo")
                 (const :tag "sudoedit" "sudoedit"))
  :group 'su)

;; Required for the face to be displayed
(put 'su-auto-save-mode-lighter 'risky-local-variable t)

(defun su--get-current-user (path)
  "Get the user currently opening `PATH'."
  (if (and (featurep 'tramp)
           (tramp-tramp-file-p path))
      (with-parsed-tramp-file-name path parsed
        (if parsed-user
            (substring-no-properties parsed-user)
          user-login-name))
    user-login-name))

(defun su--root-file-name-p (path)
  "Test whether this PATH is already being opened by root."
  (string= (su--get-current-user path) "root"))

(defun su--tramp-get-method-parameter (method param)
  "Helper to get a PARAM for a METHOD in `tramp-methods'."
  (assoc param (assoc method tramp-methods)))

(defun su--tramp-corresponding-inline-method (method)
  "Calculate the inline-method which is most similar to METHOD."
  (let* ((login-program
          (su--tramp-get-method-parameter method 'tramp-login-program))
         (login-args
          (su--tramp-get-method-parameter method 'tramp-login-args))
         (copy-program
          (su--tramp-get-method-parameter method 'tramp-copy-program)))
    (or
     ;; If the method is already inline, it's already okay
     (and login-program
          (not copy-program)
          method)

     ;; If the method isn't inline, try calculating the corresponding
     ;; inline method, by matching other properties.
     (and copy-program
          (cl-some
           (lambda (test-method)
             (when (and
                    (equal login-args
                           (su--tramp-get-method-parameter
                            test-method
                            'tramp-login-args))
                    (equal login-program
                           (su--tramp-get-method-parameter
                            test-method
                            'tramp-login-program))
                    (not (su--tramp-get-method-parameter
                          test-method
                          'tramp-copy-program)))
               test-method))
           (mapcar #'car tramp-methods)))

     ;; These methods are weird and need to be handled specially
     (and (member method '("sftp" "fcp"))
          "sshx"))))

(defun su--check-passwordless-sudo (&optional user)
  "Determine if USER can use sudo without a password."
  (let (process-file-side-effects)
    (= (apply #'process-file
              "sudo"
              nil
              nil
              nil
              "-n"
              "true"
              (when user
                (list "-u" user)))
       0)))

(defun su--check-password-sudo (&optional user)
  "Determine if USER can use sudo with a password."
  (let ((prompt "emacs-su-prompt")
        process-file-side-effects)
    (string-match-p
     prompt
     (with-output-to-string
       (with-current-buffer standard-output
         (apply #'process-file
                "sudo"
                nil
                t
                nil
                "-vSp"
                prompt
                (when user
                  (list "-u" user))))))))

(defun su--check-sudo (&optional user)
  "Determine if USER can use sudo."
  (or (su--check-passwordless-sudo user)
      (su--check-password-sudo user)))

(defun su--file-name-first-matching-parent (file-path predicate &optional include-self)
  "Return the first parent of FILE-PATH for which (PREDICATE parent) is truthy.

If INCLUDE-SELF is set, then include FILE-PATH path in list of
potential matches. (i.e. the \"parent\" relationship is not
proper.)"
  (catch 'found-directory
    (let ((temp-path (if include-self
                         file-path
                       (file-name-directory file-path))))
      (while t
        (if (funcall predicate temp-path)
            (throw 'found-directory
                   temp-path)
          ;; strip one directory off the path
          (setq temp-path
                (directory-file-name
                 (file-name-directory (if (file-name-absolute-p temp-path)
                                          temp-path
                                        (expand-file-name temp-path))))))))))

(defun su--make-root-file-name (file-name &optional user)
  "Calculate the TRAMP path with escalated privileges for FILE-NAME.

Optional argument USER provides a user whose identity to assume
via TRAMP."
  (require 'tramp)
  (let* ((target-user (or user "root"))
         (abs-file-name (expand-file-name file-name))
         (sudo (with-demoted-errors "sudo check failed: %s"
                 (let ((default-directory
                         (su--file-name-first-matching-parent
                          abs-file-name
                          #'file-readable-p)))
                   (su--check-sudo user))))
         (su-method (if sudo su-sudo-method "su")))
    (if (tramp-tramp-file-p abs-file-name)
        (with-parsed-tramp-file-name abs-file-name parsed
          (if (string= parsed-user target-user)
              abs-file-name
            (tramp-make-tramp-file-name
             su-method
             target-user
             nil
             parsed-host
             nil
             parsed-localname
             (let ((tramp-postfix-host-format tramp-postfix-hop-format)
                   (tramp-prefix-format))
               (tramp-make-tramp-file-name
                (su--tramp-corresponding-inline-method parsed-method)
                parsed-user
                parsed-domain
                parsed-host
                parsed-port
                ""
                parsed-hop)))))
      (if (string= (user-login-name) user)
          abs-file-name
        (tramp-make-tramp-file-name su-method
                                    target-user
                                    nil
                                    "localhost"
                                    nil
                                    abs-file-name)))))

(defun su--nadvice-find-file-noselect-1 (old-fun buf filename &rest args)
  "Find-file-noselect with privilege escalation if necessary.
Argument OLD-FUN Should be `find-file-noselect-1'.
Argument BUF The buffer to read FILENAME into.
Argument FILENAME The filename to open.
Optional argument ARGS Any other args to `find-file-noselect-1'."
  (condition-case err
      (apply old-fun buf filename args)
    (file-error
     (if (and (not (su--root-file-name-p filename))
              (y-or-n-p "File is not readable. Open with root? "))
         (let ((filename (su--make-root-file-name (file-truename filename))))
           (apply #'find-file-noselect-1
                  (or (get-file-buffer filename)
                      (create-file-buffer filename))
                  filename
                  args))
       (signal (car err) (cdr err))))))

(defun su--nadvice-make-directory-auto-root (old-fun &rest args)
  "Make-directory with privilege escalation if necessary.
Argument OLD-FUN Should be `make-directory'.
Optional argument ARGS Any other args to `make-directory'."
  (cl-letf*
      ((old-md (symbol-function #'make-directory))
       ((symbol-function #'make-directory)
        (lambda (dir &rest args)
          (if (and (not (su--root-file-name-p dir))
                   (not (file-writable-p
                         (su--file-name-first-matching-parent dir
                                                              #'file-exists-p)))
                   (y-or-n-p "Insufficient permissions. Create with root? "))
              (apply old-md
                     (su--make-root-file-name dir)
                     args)
            (apply old-md dir args)))))
    (apply old-fun args)))

(defun su--nadvice-supress-find-file-hook (old-fun &rest args)
  "Prevent `find-file-hook' from being fired during the execution of OLD-FUN.
Optional argument ARGS Any other args to OLD-FUN."
  (cl-letf* ((old-aff (symbol-function #'after-find-file))
             ((symbol-function #'after-find-file)
              (lambda (&rest args)
                (let ((find-file-hook))
                  (apply old-aff args)))))
    (apply old-fun args)))

(defun su--before-save-hook ()
  "Switch the visiting file to a TRAMP path if needed to perform the save."
  (when (and (buffer-modified-p)
             (not (su--root-file-name-p buffer-file-name))
             (or (not (su--check-passwordless-sudo))
                 (yes-or-no-p "File is not writable. Save with root? ")))
    (let ((change-major-mode-with-file-name nil))
      (set-visited-file-name (su--make-root-file-name buffer-file-name) t t))
    (remove-hook 'before-save-hook #'su--before-save-hook t)))

(defun su--nadvice-find-file-noselect (old-fun &rest args)
  "Fool `find-file-noselect' into thinking files are writable.
Argument OLD-FUN Should be `find-file-noselect'.
Optional argument ARGS Any other args to `find-file-noselect'."
  (cl-letf* ((old-fwp (symbol-function #'file-writable-p))
             ((symbol-function #'file-writable-p)
              (lambda (&rest iargs)
                (or (member 'su-auto-save-mode first-change-hook)
                    (bound-and-true-p su-auto-save-mode)
                    (apply old-fwp iargs)))))
    (apply old-fun args)))

(defun su--notify-insufficient-permissions ()
  "Notify the user that privilege escalation will be required to save."
  (message "Modifications will require a change of permissions to save."))

(defun su--edit-file-as-root-maybe ()
  "Find file as root if necessary."
  (when (and buffer-file-name
             (not (file-writable-p buffer-file-name))
             (not (string= user-login-name
                           (nth 3 (file-attributes buffer-file-name 'string))))
             (not (su--root-file-name-p buffer-file-name)))

    (setq buffer-read-only nil)
    (add-hook 'first-change-hook #'su-auto-save-mode nil t)

    ;; This is kind of a hack, since I can't guarantee that this
    ;; message will be displayed last, so I just display it with a
    ;; delay.
    (run-with-idle-timer 0.5 nil #'su--notify-insufficient-permissions)))

;;;###autoload
(defun su ()
  "Open the current file as root."
  (interactive)
  (find-alternate-file (su--make-root-file-name buffer-file-name)))

;;;###autoload
(defun su-find-file (filename &optional wildcards)
  "Find FILENAME as root.
Optional argument WILDCARDS Wildcards to pass to `find-file'."
  (interactive
   (let ((default-directory (su--make-root-file-name default-directory)))
     (find-file-read-args "Find file: "
                          (confirm-nonexistent-file-or-buffer))))
  (find-file filename wildcards))

;;;###autoload
(define-minor-mode su-auto-save-mode
  "Automatically save buffer as root"
  :lighter su-auto-save-mode-lighter
  (if su-auto-save-mode
      ;; Ensure that su-auto-save-mode is visible by moving it to the
      ;; beginning of the minor mode list
      (progn
        (let ((su-auto-save-mode-alist-entry
               (assoc 'su-auto-save-mode minor-mode-alist)))
          (setq minor-mode-alist
                (delete su-auto-save-mode-alist-entry minor-mode-alist))
          (push su-auto-save-mode-alist-entry minor-mode-alist))
        (add-hook 'before-save-hook #'su--before-save-hook nil t))
    (remove-hook 'before-save-hook #'su--before-save-hook t)))

;;;###autoload
(define-minor-mode su-mode
  "Automatically read and write files as users"
  :init-value nil
  :group 'su
  :global t
  (if su-mode
      (progn
        (when su-auto-make-directory
          (advice-add 'basic-save-buffer :around
                      #'su--nadvice-make-directory-auto-root))

        (when su-auto-write-file
          (add-hook 'find-file-hook #'su--edit-file-as-root-maybe)
          (advice-add 'find-file-noselect :around
                      #'su--nadvice-find-file-noselect))

        (when su-auto-read-file
          (advice-add 'find-file-noselect-1 :around
                      #'su--nadvice-find-file-noselect-1)))

    (remove-hook 'find-file-hook #'su--edit-file-as-root-maybe)
    (advice-remove 'basic-save-buffer
                #'su--nadvice-make-directory-auto-root)
    (advice-remove 'find-file-noselect
                #'su--nadvice-find-file-noselect)
    (advice-remove 'find-file-noselect-1
                   #'su--nadvice-find-file-noselect-1)))

;;;###autoload
(define-minor-mode su-helm-integration-mode
  "Enable su-mode integration with helm."
  :init-value nil
  :group 'su
  :global t
  (require 'helm-files)
  (if su-helm-integration-mode
      (advice-add 'helm-find-file-or-marked :around
                  #'su--nadvice-make-directory-auto-root)
    (advice-remove 'helm-find-file-or-marked
                   #'su--nadvice-make-directory-auto-root)))

;;;###autoload
(define-minor-mode su-semantic-integration-mode
  "Enable su-mode integration with semantic."
  :init-value nil
  :group 'su
  :global t
  (require 'semantic)
  (if su-semantic-integration-mode
      (advice-add 'semantic-find-file-noselect :around
                  #'su--nadvice-supress-find-file-hook)
    (advice-remove 'semantic-find-file-noselect
                   #'su--nadvice-supress-find-file-hook)))

(provide 'su)

;;; su.el ends here
