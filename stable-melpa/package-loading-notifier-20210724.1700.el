;;; package-loading-notifier.el --- Notify a package is being loaded -*- lexical-binding: t; -*-

;; Author: SeungKi Kim <tttuuu888@gmail.com>
;; URL: https://github.com/tttuuu888/package-loading-notifier
;; Package-Version: 20210724.1700
;; Package-Commit: 895ab23f970f954349ccb6c89d397ad7d86087f8
;; Version: 0.1.0
;; Keywords: convenience faces config startup
;; Package-Requires: ((emacs "25"))

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; To enable `package-loading-notifier' globally, add the following lines to
;; your .emacs:
;;
;;  (require 'package-loading-notifier)
;;  (package-loading-notifier-mode 1)
;;

;;; Code:

(require 'subr-x)

(defgroup package-loading-notifier nil
  "Notify a package is being loaded."
  :prefix "package-loading-notifier-"
  :group 'startup)

(defcustom package-loading-notifier-packages '(org)
  "List of packages to notify when the package is being loaded."
  :type '(repeat symbol)
  :group 'package-loading-notifier)

(defcustom package-loading-notifier-format "%s loading ..."
  "String format to notify a package is being loaded.
`%s' is replaced by the package name."
  :type 'string
  :group 'package-loading-notifier)

(defface package-loading-notifier-face
  '((t :inverse-video t :weight bold))
  "Face used to notify a package is being loaded."
  :group 'package-loading-notifier)

(defun package-loading-notifier--notify (pkg old &rest r)
  "Notify a PKG is being loaded and execute OLD with rest arguments R."
  (let ((msg (capitalize (format package-loading-notifier-format pkg)))
        (ovr (make-overlay (point) (point)))
        (ret nil))
    (when (fboundp 'company-cancel) (company-cancel))
    (setq package-loading-notifier-packages
          (delq pkg package-loading-notifier-packages))
    (unless package-loading-notifier-packages
      (package-loading-notifier-mode -1))
    (message msg)
    (overlay-put ovr 'after-string
                 (propertize msg 'face 'package-loading-notifier-face))
    (redisplay)
    (unwind-protect
        (setq ret (apply old r))
      (delete-overlay ovr))
    ret))

(defun package-loading-notifier--require (old &rest r)
  "Notifier for `require' function.
If the package is not a member of
`package-loading-notifier-packages', just execute OLD with rest
arguments R."
  (let ((pkg (car r)))
    (if (not (member pkg package-loading-notifier-packages))
        (apply old r)
      (apply #'package-loading-notifier--notify pkg old r))))

(defun package-loading-notifier--find-file (old &rest r)
  "Notifier for all kind of `find-file' functions.
If the package is not a member of
`package-loading-notifier-packages', just execute OLD with rest
arguments R."
  (let* ((file-name (car r))
         (mode
          (when (stringp file-name)
            (let ((ret (assoc-default file-name auto-mode-alist 'string-match)))
              (and (symbolp ret) (symbol-name ret)))))
         (pkg-with-mode
          (when mode (intern mode)))
         (pkg-without-mode
          (when mode
            (intern (string-remove-suffix "-mode" mode))))
         (pkg
          (if (member pkg-with-mode package-loading-notifier-packages)
              pkg-with-mode
            pkg-without-mode)))
    (if (not (member pkg package-loading-notifier-packages))
        (apply old r)
      (apply #'package-loading-notifier--notify pkg old r))))

;;;###autoload
(define-minor-mode package-loading-notifier-mode
  "Notify a package is being loaded."
  :init-value nil
  :global t
  (if package-loading-notifier-mode
      (progn
        (advice-add 'require :around #'package-loading-notifier--require)
        (advice-add 'find-file-noselect :around #'package-loading-notifier--find-file))
    (advice-remove 'require #'package-loading-notifier--require)
    (advice-remove 'find-file-noselect #'package-loading-notifier--find-file)))

(provide 'package-loading-notifier)
;;; package-loading-notifier.el ends here
