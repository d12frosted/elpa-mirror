;;; buffer-sets.el --- Sets of Buffers for Buffer Management

;; Copyright (C) 2016 Samuel Flint

;; Author: Samuel W. Flint <swflint@flintfam.org>
;; Version: 2.5
;; Package-Version: 20170718.340
;; Package-Commit: bc84c2f79a33609cccf3c996101125859b2e26ab
;; Package-Requires: ((cl-lib "0.5"))
;; Keywords: buffer-management
;; URL: http://github.com/swflint/buffer-sets

;;; Commentary:
;;



;;; Code:

(require 'cl-lib)

;;; Variables and Structures

(cl-defstruct buffer-set
  name
  files
  select
  on-apply
  on-apply-source
  on-remove
  on-remove-source)

(defvar *buffer-sets* nil
  "List of all defined buffer sets.")

(defvar *buffer-sets-applied* nil
  "List of applied buffer-sets.")

(defvar *buffer-set-definitions* nil
  "List of all buffer set definitions.")

(defvar *buffer-set-buffers* nil
  "List of buffers in loaded buffer sets.")

(defvar buffer-sets-mode-p nil)

(defvar buffer-sets-load-set-hook '()
  "Hook run on set load.")

(defvar buffer-sets-unload-hook '()
  "Hook run on set unload.")

(defcustom buffer-set-file "~/.emacs.d/buffer-set-definitions.el"
  "The file to store buffer set definitions in."
  :type 'file :group 'editing)

;;;###autoload
(defcustom buffer-sets-load-on-start (list)
  "A list of buffer-sets to load on Emacs start."
  :type '(repeat symbol) :group 'editing)

;;;###autoload
(defcustom buffer-sets-ignore-save (list)
  "A list of buffer-sets to ignore on saving."
  :type '(repeat symbol) :group 'editing)


;;; Utility Functions

(defun buffer-sets-applied-p (set)
  "Returns true if SET is applied."
  (member set *buffer-sets-applied*))

(defun buffer-set--get-buffer-set-definition (set-name)
  (car (cl-remove-if-not (lambda (set)
			   (eq set-name (buffer-set-name set))) *buffer-set-definitions*)))

(defun buffer-set--generate-buffers-list (set-name)
  (intern (format "*buffer-set-%s--buffers*" set-name)))


;;; Set Definition

;;;###autoload
(cl-defmacro define-buffer-set (name &key files select on-apply on-remove)
  "Define a buffer set named NAME, taking FILES, RUN-ON-APPLY, RUN-ON-REMOVE and BUFFER-TO-SELECT as keyword arguments."
  `(progn
     (cl-pushnew ',name *buffer-sets*)
     (setq *buffer-set-definitions* (cons (make-buffer-set :name ',name
                                                           :files ',files
                                                           :select ,select
                                                           :on-apply-source ',on-apply
                                                           :on-remove-source ',on-remove
                                                           :on-apply (lambda () ,@on-apply)
                                                           :on-remove (lambda () ,@on-remove))
                                          (cl-remove-if (lambda (structure)
                                                          (eq ',name (buffer-set-name structure)))
                                                        *buffer-set-definitions*)))
     (defvar ,(buffer-set--generate-buffers-list name) nil)
     ',name))


;;; Interactive Functions

;;;###autoload
(defun buffer-sets-load-set (name)
  (interactive (list (intern (completing-read "Set Name: "
                                              (cl-remove-if #'(lambda (set) (member set *buffer-sets-applied*)) *buffer-sets*)
                                              nil t))))
  (let ((set-definition (buffer-set--get-buffer-set-definition name)))
    (if (not (buffer-set-p set-definition))
    	(error "Set Undefined: %s" name)
      (let ((files (buffer-set-files set-definition))
            (select (buffer-set-select set-definition))
            (on-apply (buffer-set-on-apply set-definition))
            (buffers-list (buffer-set--generate-buffers-list name)))
        (setf (symbol-value buffers-list) (mapcar #'find-file files))
        (funcall on-apply)
        (when (stringp select)
          (switch-to-buffer select))
        (add-to-list '*buffer-sets-applied* name)
        (run-hooks 'buffer-sets-load-set-hook)
        (message "Applied buffer set %s." name)))))

(defalias 'load-buffer-set 'buffer-sets-load-set)

(defun buffer-sets-in-buffers-list (set buffer)
  (cl-pushnew buffer (symbol-value (buffer-set--generate-buffers-list set))))

;;;###autoload
(defun buffer-sets-unload-buffer-set (name)
  "Unload Buffer Set named NAME."
  (interactive (list (intern (completing-read "Set Name: " *buffer-sets-applied*))))
  (let ((set-definition (buffer-set--get-buffer-set-definition name)))
    (if (not (buffer-set-p set-definition))
        (error "Set Undefined: %s" name)
      (let ((buffers-list (buffer-set--generate-buffers-list name))
            (on-remove (buffer-set-on-remove set-definition)))
        (mapc (lambda (buffer)
                (when (buffer-live-p buffer)
                  (with-current-buffer buffer
                    (save-buffer)
                    (kill-buffer buffer))))
              (symbol-value buffers-list))
        (funcall on-remove)
        (setf (symbol-value buffers-list) nil)
        (setq *buffer-sets-applied* (delq name *buffer-sets-applied*))
        (run-hooks 'buffer-sets-unload-hook)
        (message "Removed Buffer Set: %s" name)))))

;;;###autoload
(defun buffer-sets-unload-last-loaded-set ()
  (interactive)
  (let ((set (cl-first *buffer-sets-applied*)))
    (buffer-sets-unload-buffer-set set)))

;;;###autoload
(defun buffer-sets-list ()
  "Produce a list of defined buffer sets."
  (interactive)
  (when (buffer-live-p "*Buffer Sets*")
    (kill-buffer "*Buffer Sets*"))
  (with-help-window "*Buffer Sets*"
    (with-current-buffer "*Buffer Sets*"
      (insert "Defined Buffer Sets:\n\n")
      (dolist (set *buffer-sets*)
        (if (not (buffer-sets-applied-p set))
            (insert (format " - %s\n" set))
          (insert (format " - %s (Applied)\n" set)))
        (dolist (buffer (symbol-value (buffer-set--generate-buffers-list set)))
          (if (buffer-live-p buffer)
              (if (null (get-buffer-window-list buffer nil t))
                  (progn
                    (insert "    - ")
                    (insert-text-button (buffer-name buffer) 'action (eval `(lambda (but) (switch-to-buffer ,buffer))))
                    (insert "\n"))
                (progn
                  (insert "    - ")
                  (insert-text-button (buffer-name buffer) 'action (eval `(lambda (but) (switch-to-buffer ,buffer))))
                  (insert "    - %s (visible)\n")))
            ""))))))

;;;###autoload
(defun buffer-sets-unload-all-buffer-sets ()
  "Unload all loaded buffer sets."
  (interactive)
  (dolist (buffer-set *buffer-sets-applied*)
    (buffer-sets-unload-buffer-set buffer-set)))

;;;###autoload
(defun buffer-sets-create-set (name)
  "Create a new set."
  (interactive "SNew Set Name: ")
  (when (not (member name *buffer-sets*))
    (cl-pushnew name *buffer-sets*)
    (setf (symbol-value (buffer-set--generate-buffers-list name)) nil)
    (cl-pushnew (make-buffer-set :name name
                                 :on-apply (lambda () nil)
                                 :on-remove (lambda () nil)) *buffer-set-definitions*)))

;;;###autoload
(defun buffer-sets-add-file-to-set (name file)
  "Add a file to the set."
  (interactive (list
                (intern (completing-read "Set Name: " *buffer-sets* nil t))
                (read-file-name "File Name: ")))
  (let ((set (buffer-set--get-buffer-set-definition name)))
    (setf (buffer-set-files set) (append (buffer-set-files set) (list file)))))

;;;###autoload
(defun buffer-sets-add-directory-to-set (name directory)
  (interactive (list
                (intern (completing-read "Set Name: " *buffer-sets* nil t))
                (read-directory-name "Directory: ")))
  (let ((set (buffer-set--get-buffer-set-definition name)))
    (setf (buffer-set-files set) (append (buffer-set-files set) (list directory)))))

;;;###autoload
(defun buffer-sets-add-buffer-to-set (name buffer)
  "Add a buffer to the given set."
  (interactive (list
                (intern (completing-read "Set Name: " *buffer-sets* nil t))
                (get-buffer (read-buffer "Buffer: " (current-buffer)))))
  (let ((set (buffer-set--get-buffer-set-definition name))
        (file (buffer-file-name buffer)))
    (setf (buffer-set-files set) (append (buffer-set-files set) (list file)))))

;; (defun buffer-sets-edit-load-actions (set)
;;   "Edit the actions to be preformed on buffer set load."
;;   (interactive (list (completing-read "Set: " *buffer-sets* nil t))))

;; (defun buffer-sets-edit-remove-actions (set)
;;   "Edit the actions to be preformed on buffer set removal."
;;   (interactive (list (completing-read "Set: " *buffer-sets* nil t))))

;;;###autoload
(defun buffer-sets-set-buffer-to-select (name)
  "Set the buffer to automatically select."
  (interactive (list (intern (completing-read "Set Name: " *buffer-sets* nil t))))
  (let* ((set (buffer-set--get-buffer-set-definition name))
         (files (buffer-set-files set)))
    (setf (buffer-set-select set)
          (completing-read "Buffer: " (mapcar #'buffer-name (symbol-value (buffer-set--generate-buffers-list name))) nil t))))

;;;###autoload
(defun buffer-sets-remove-file (set)
  (interactive (list (intern (completing-read "Set Name: " *buffer-sets* nil t))))
  (let ((set (buffer-set--get-buffer-set-definition set)))
    (setf (buffer-set-files set)
          (delq (completing-read "File: " (buffer-set-files set) nil t)
                (buffer-set-files set)))))


;;; File Functions

(defun buffer-sets-save (the-set)
  "Save defined buffer sets."
  (if (not (member the-set buffer-sets-ignore-save))
      (insert (format "%S\n\n" (let ((name (buffer-set-name the-set))
                                     (files (buffer-set-files the-set))
                                     (select (buffer-set-select the-set))
                                     (on-apply (buffer-set-on-apply-source the-set))
                                     (on-remove (buffer-set-on-remove-source the-set)))
                                 `(define-buffer-set ,name
                                    :files ,files
                                    :select ,select
                                    :on-apply ,on-apply
                                    :on-remove ,on-remove))))))

;;;###autoload
(defun buffer-sets-load-definitions-file ()
  "Load buffer set definitions file."
  (interactive)
  (load buffer-set-file t t)
  (message "Loaded Buffer Set Definitions."))

;;;###autoload
(defun buffer-sets-save-definitions ()
  (interactive)
  (with-current-buffer (find-file buffer-set-file)
    (kill-region (buffer-end -1) (buffer-end 1))
    (mapc #'buffer-sets-save (reverse *buffer-set-definitions*))
    (save-buffer)
    (kill-buffer))
  (message "Saved Buffer Set Definitions."))


;;; Mode Definition

(defvar buffer-sets-mode-map
  (let ((keymap (make-keymap)))
    (define-key keymap (kbd "C-x L l") #'buffer-sets-load-set)
    (define-key keymap (kbd "C-x L L") #'buffer-sets-list)
    (define-key keymap (kbd "C-x L u") #'buffer-sets-unload-buffer-set)
    (define-key keymap (kbd "C-x L U") #'buffer-sets-unload-all-buffer-sets)
    (define-key keymap (kbd "C-x L c") #'buffer-sets-create-set)
    (define-key keymap (kbd "C-x L f") #'buffer-sets-add-file-to-set)
    (define-key keymap (kbd "C-x L b") #'buffer-sets-add-buffer-to-set)
    (define-key keymap (kbd "C-x L d") #'buffer-sets-add-directory-to-set)
    (define-key keymap (kbd "C-x L R") #'buffer-sets-remove-file)
    (define-key keymap (kbd "C-x L s") #'buffer-sets-set-buffer-to-select)
    (define-key keymap (kbd "C-x L p") #'buffer-sets-unload-last-loaded-set)
    (define-key keymap (kbd "C-x L C-f") #'buffer-sets-load-definitions-file)
    (define-key keymap (kbd "C-x L C-s") #'buffer-sets-save-definitions)
    keymap)
  "Keymap for buffer-set commands.")

;;;###autoload
(define-minor-mode buffer-sets-mode
  "A mode for managing sets of buffers."
  :lighter " BSM" :global t :variable buffer-sets-mode-p :keymap buffer-sets-mode-map
  (if buffer-sets-mode-p
      (progn
        (buffer-sets-load-definitions-file)
        (add-hook 'kill-emacs-hook #'buffer-sets-unload-all-buffer-sets)
        (add-hook 'kill-emacs-hook #'buffer-sets-save-definitions))
    (progn
      (buffer-sets-save-definitions)
      (remove-hook 'kill-emacs-hook #'buffer-sets-unload-all-buffer-sets)
      (remove-hook 'kill-emacs-hook #'buffer-sets-save-definitions))))

;;;###autoload
(define-ibuffer-filter in-buffer-set
    "Check to see if a buffer is in a given buffer-set."
  (:reader (intern (completing-read "Set Name: " *buffer-sets-applied*)))
  (let ((buffers-list (symbol-value (buffer-set--generate-buffers-list qualifier))))
    (member buf buffers-list)))

;;;###autoload
(defun buffer-sets-install-emacs-start-hook ()
  "Install the hook to load buffer-sets on Emacs start."
  (add-hook 'after-init-hook #'buffer-sets-after-init))

(defun buffer-sets-after-init ()
  "Load buffer-sets on Emacs start."
  (mapcar #'load-buffer-set buffer-sets-load-on-start))

(provide 'buffer-sets)

;;; buffer-sets.el ends here
