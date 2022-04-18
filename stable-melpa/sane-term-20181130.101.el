;;; sane-term.el --- Multi Term is crazy. This is not.

;; Copyright (C) 2018 Adam Patterson

;; Author: Adam Patterson <adam@adamrt.com>
;; URL: http://github.com/adamrt/sane-term
;; Package-Version: 20181130.101
;; Package-Commit: 369178c2dd0348250c2ec0019567688376c637f7
;; Version: 0.6
;; Package-Requires: ((emacs "24.1"))

;;; Commentary:

;; You can set it up like this:

;;    (use-package sane-term
;;      :ensure t
;;      :bind (("C-x t" . sane-term)
;;             ("C-x T" . sane-term-create)))

;;; Code:

(defgroup sane-term nil
  "Multi Term is crazy. This is not."
  :group 'term)

(defcustom sane-term-shell-command (or (getenv "SHELL")
                                       "/bin/sh")
  "Specify which shell to use."
  :type 'string
  :group 'sane-term)

(defcustom sane-term-initial-create t
  "Creates a term if one doesn't exist."
  :type 'boolean
  :group 'sane-term)

(defcustom sane-term-kill-on-exit t
  "Kill term buffer on exit (C-d or `exit`)."
  :type 'boolean
  :group 'sane-term)

(defcustom sane-term-next-on-kill t
  "When killing a term buffer, go to the next one.
Depends on sane-term-kill-on-exit."
  :type 'boolean
  :group 'sane-term)

(defun sane-term-buffer-exists-p ()
  "Boolean if term-mode buffers exist."
  (catch 'loop
    (dolist (buf (buffer-list))
      (with-current-buffer buf
        (when (derived-mode-p 'term-mode)
          (throw 'loop t))))))

(defun sane-term-cycle (reverse)
  (unless reverse
    (when (derived-mode-p 'term-mode)
      (bury-buffer)))
  (let ((buffers (buffer-list)))
    (when reverse
      (setq buffers (nreverse buffers)))
    (catch 'loop
      (dolist (buf buffers)
        (when (with-current-buffer buf (derived-mode-p 'term-mode))
          (switch-to-buffer buf)
          (throw 'loop nil))))))

(defun sane-term-prev ()
  "Cycle through term buffers, in reverse."
  (interactive)
  (sane-term-cycle t))

(defun sane-term-next ()
  "Cycle through term buffers."
  (interactive)
  (sane-term-cycle nil))

;;;###autoload
(defun sane-term-create ()
  "Create new term buffer."
  (interactive)
  (ansi-term sane-term-shell-command))

;;;###autoload
(defun sane-term ()
  "Cycle through term buffers, creating if necessary."
  (interactive)
  (when sane-term-initial-create
    (unless (sane-term-buffer-exists-p)
      (sane-term-create)))
  (sane-term-next))

(defun sane-term-mode-toggle ()
  "Toggles term between line mode and char mode. Nice to have a
   single key so I don't have to remember separate char and line
   mode bindings"
  (interactive)
  (if (term-in-line-mode)
      (term-char-mode)
    (term-line-mode)))

(defadvice term-handle-exit
    (after term-kill-buffer-on-exit activate)
  "Kill term buffers on exiting term (C-d or `exit`).
Optionally go to next term buffer."
  (when sane-term-kill-on-exit
    (kill-buffer)
    (when sane-term-next-on-kill
      (sane-term-next))))


(provide 'sane-term)

;;; sane-term.el ends here
