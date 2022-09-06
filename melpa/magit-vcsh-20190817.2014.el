;;; magit-vcsh.el --- Magit vcsh integration -*- lexical-binding: t -*-

;; Author: Štěpán Němec <stepnem@gmail.com>
;; Created: 2019-08-17 09:37:50 Saturday +0200
;; URL: https://gitlab.com/stepnem/magit-vcsh-el
;; Package-Version: 20190817.2014
;; Package-Commit: fcff128cdbe3ef547dc64f2496cb6405b8ee21ca
;; Keywords: vc, files, magit
;; License: public domain
;; Version: 0.4.1
;; Tested-with: GNU Emacs 27
;; Package-Requires: ((magit "2.90.1") (vcsh "0.4") (emacs "24.4"))

;;; Commentary:

;; This library provides a global minor mode `magit-vcsh-hack-mode'
;; that advises Magit functions so that `magit-list-repositories' and
;; `magit-status' work with vcsh repos.  `magit-vcsh-status' works
;; even without enabling the minor mode.

;; `magit-vcsh-status' is also added to `vcsh-after-new-functions' to
;; open Magit status buffer on the new repo upon creation.

;; See also the commentary in vcsh.el for more information.

;; Corrections and constructive feedback appreciated.

;;; Code:

(require 'magit)
(require 'vcsh)

;; (defgroup magit-vcsh () "Magit vcsh integration."
;;   :group 'magit)

;;;###autoload
(defun magit-vcsh-status (repo)
  "Make vcsh REPO current (cf. `vcsh-link') and run `magit-status' in it."
  (interactive (list (vcsh-read-repo)))
  (vcsh-link repo)
  (magit-status-setup-buffer (vcsh-repo-path repo)))

(add-hook 'vcsh-after-new-functions #'magit-vcsh-status)

;;; Hack some Magit functions to work with vcsh repos
(defun magit-vcsh--list-repos-1 (orig &rest args)
  "Make `magit-list-repos-1' consider vcsh git directories.
Checkdoc: can you guess what ORIG and ARGS mean?"
  (let ((dir (car args)))
    (if (vcsh-repo-p dir)
        (list (file-name-as-directory dir))
      (apply orig args))))

(defun magit-vcsh--status-setup-buffer (&optional dir)
  "Make `magit-status-setup-buffer' handle vcsh repositories.
Checkdoc: can you guess what DIR means?"
  (unless dir (setq dir default-directory))
  (when (vcsh-repo-p dir) (vcsh-link
                           ;;-D
                           (file-name-base
                            (directory-file-name
                             (file-name-as-directory dir))))))

;;;###autoload
(define-minor-mode magit-vcsh-hack-mode
  "Advise Magit functions to work with vcsh repositories.
In particular, when this mode is enabled, `magit-status' and
`magit-list-repositories' should work as expected."
  :global t
  (if magit-vcsh-hack-mode
      (progn
        (advice-add 'magit-list-repos-1 :around #'magit-vcsh--list-repos-1)
        (advice-add 'magit-status-setup-buffer :before
                    #'magit-vcsh--status-setup-buffer))
    (advice-remove 'magit-list-repos-1 #'magit-vcsh--list-repos-1)
    (advice-remove 'magit-status-setup-buffer
                   #'magit-vcsh--status-setup-buffer)))

(defun magit-vcsh-unload-function ()
  "Clean up after the magit-vcsh library."
  (magit-vcsh-hack-mode -1)
  nil)

(defun magit-vcsh-reload ()
  "Reload the magit-vcsh library."
  (interactive)
  (unload-feature 'magit-vcsh t)
  (require 'magit-vcsh))

(provide 'magit-vcsh)
;;; magit-vcsh.el ends here
