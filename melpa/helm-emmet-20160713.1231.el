;;; helm-emmet.el --- helm sources for emmet-mode's snippets

;; Copyright (C) 2013 Yasuyuki Oka <yasuyk@gmail.com>

;; Author: Yasuyuki Oka <yasuyk@gmail.com>
;; Version: DEV
;; Package-Version: 20160713.1231
;; Package-Commit: f0364e736b10cf44232053a78de04133a88185ae
;; URL: https://github.com/yasuyk/helm-emmet
;; Package-Requires: ((helm "1.0") (emmet-mode "1.0.2"))
;; Keywords: convenience, helm, emmet

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Provides helm sources for emmet-mode

;;; Usage:

;;     (require 'helm-emmet) ;; Not necessary if using ELPA package

;;; Code:

(require 'helm)
(require 'emmet-mode)

;;; Faces
(defface helm-emmet-snippet-first-line
    '((t (:foreground "yellow")))
  "Face used for a first line of snippet in helm buffer."
  :group 'helm-emmet)

(defun helm-emmet-snippets-init (hash)
  (let* ((lgst-len 0) keys)
    (maphash (lambda (k v)
               (when (> (length k) lgst-len)
                 (setq lgst-len (length k)))
               (setq k (propertize k 'helm-emmet-snippet v))
               (setq keys (cons k keys))) hash)
    (helm-attrset 'lgst-len lgst-len)
    keys))

(defvar helm-emmet-html-snippets-hash
  (gethash "snippets" (gethash "html" emmet-snippets)))

(defvar helm-emmet-html-aliases-hash
  (gethash "aliases" (gethash "html" emmet-snippets)))

(defvar helm-emmet-css-snippets-hash
  (gethash "snippets" (gethash "css" emmet-snippets)))

(defvar helm-emmet-html-snippets-keys nil)
(defvar helm-emmet-html-aliases-keys nil)
(defvar helm-emmet-css-snippets-keys nil)

(defun helm-emmet-padding-space (lgst-len str)
  (let ((length (- lgst-len (length str))))
        (when (< 0 length) (make-string length ? ))))

(defun helm-emmet-real-to-display (candidate)
  (let ((snippet (get-text-property 0 'helm-emmet-snippet candidate))
        (lgst-len (helm-attr 'lgst-len))
        firstline)
    (when (functionp snippet)
      (setq snippet (funcall snippet "")))
    (if (stringp snippet)
        (progn
          (setq firstline (car (split-string snippet "\n")))
          (setq firstline (propertize firstline 'face 'helm-emmet-snippet-first-line))
          (concat candidate " " (helm-emmet-padding-space lgst-len candidate) firstline))
      candidate)))

(defun helm-emmet-persistent-action (candidate)
  (let ((hbuf (get-buffer (help-buffer))))
    (with-help-window hbuf
      (let ((snippet (get-text-property 0 'helm-emmet-snippet candidate)))
        (when (functionp snippet)
          (setq snippet (funcall snippet "")))
        (prin1 snippet)))))

(defclass helm-source-emmet (helm-source-sync)
  ((action :initform '(("Preview" . (lambda (c)
                                      (insert c)
                                      (call-interactively 'emmet-expand-line)))
                       ("Expand" . (lambda (c)
                                     (insert c)
                                     (emmet-expand-line c)))))
   (real-to-display :initform #'helm-emmet-real-to-display)
   (persistent-action :initform #'helm-emmet-persistent-action)
   (persistent-help :initform "Describe this snippet")))

(defvar helm-source-emmet-html-snippets
  (helm-make-source "emmet html snippets" 'helm-source-emmet
    :init (lambda ()
            (setq helm-emmet-html-snippets-keys
                  (helm-emmet-snippets-init helm-emmet-html-snippets-hash)))
    :candidates 'helm-emmet-html-snippets-keys)
  "Show emmet-mode's html snippets.")

(defvar helm-source-emmet-html-aliases
  (helm-make-source "emmet html aliases" 'helm-source-emmet
    :init (lambda ()
              (setq helm-emmet-html-aliases-keys
                    (helm-emmet-snippets-init helm-emmet-html-aliases-hash)))
    :candidates 'helm-emmet-html-aliases-keys)
  "Show emmet-mode's html aliases.")

(defvar helm-source-emmet-css-snippets
  (helm-make-source "emmet css snippets" 'helm-source-emmet
    :init (lambda ()
              (setq helm-emmet-css-snippets-keys
                    (helm-emmet-snippets-init helm-emmet-css-snippets-hash)))
    :candidates 'helm-emmet-css-snippets-keys)
  "Show emmet-mode's css snippets.")

;;;###autoload
(defun helm-emmet ()
  "Helm to preview or expand emmet-mode's snippets."
  (interactive)
  (helm-other-buffer '(helm-source-emmet-html-snippets
                       helm-source-emmet-html-aliases
                       helm-source-emmet-css-snippets)
                     "*helm emmet*"))

(provide 'helm-emmet)

;; Local Variables:
;; coding: utf-8
;; End:

;;; helm-emmet.el ends here
