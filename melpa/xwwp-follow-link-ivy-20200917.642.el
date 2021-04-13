;;; xwwp-follow-link-ivy.el --- Link navigation in `xwidget-webkit' sessions using `ivy' -*- lexical-binding: t; -*-

;; Author: Damien Merenne
;; URL: https://github.com/canatella/xwwp
;; Created: 2020-03-11
;; Keywords: convenience
;; Version: 0.1
;; Package-Requires: ((emacs "26.1") (xwwp "0.1"))

;; Copyright (C) 2020 Damien Merenne <dam@cosinux.org>

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Add support for navigating web pages in `xwidget-webkit' sessions using the
;; `ivy' completion.

;;; Code:

(require 'xwwp-follow-link)
(require 'ivy)

(defvar xwwp-follow-link-ivy-history
  nil
  "Stores history for links selected with command `xwwp-follow-link-completion-backend-ivy'.")

(defclass xwwp-follow-link-completion-backend-ivy (xwwp-follow-link-completion-backend) ())

(cl-defmethod xwwp-follow-link-candidates ((_ xwwp-follow-link-completion-backend-ivy))
  "Follow a link selected with ivy."
  (with-current-buffer (ivy-state-buffer ivy-last)
    (let* ((collection (ivy-state-collection ivy-last))
           (current (ivy-state-current ivy-last))
           (candidates (ivy--filter ivy-text ivy--all-candidates))
           (result (cons current candidates)))
      (seq-map (lambda (c) (cdr (nth (get-text-property 0 'idx c) collection))) result))))

(cl-defmethod xwwp-follow-link-read ((_ xwwp-follow-link-completion-backend-ivy) prompt collection action update-fn)
  "Select a link from COLLECTION a with ivy showing PROMPT using UPDATE-FN to highlight the link in the xwidget session and execute ACTION once a link has been select."
  (ivy-read prompt collection
            :require-match t
            :action (lambda (v) (funcall action (cdr v)))
            :update-fn update-fn
            :caller 'xwwp-follow-link-read
            :history 'xwwp-follow-link-ivy-history))

(defmacro xwwp-follow-link-ivy-ivify-action (v &rest body)
  "Wraps BODY as an action for the `xwwp-follow-link-read' `ivy' version.
The url of the link is made available as variable `linkurl' extracted from the
selection candidate V.  Before the action is executed, the link highlights are
removed from the HTML document shown in xwidgets."
  `(let ((xwidget (xwidget-webkit-current-session))
         (linkurl (caddr ,v)))
    (xwwp-follow-link-cleanup xwidget)
    ,@body))

(defmacro xwwp-follow-link-ivy-ivify-action-with-text (v &rest body)
  "Wraps BODY as an action for the `xwwp-follow-link-read' `ivy' version.
The text and url of the link is made available as variables `linktext' and
`linkurl' extracted from the selection candidate V.  Before the action is
executed, the link highlights are removed from the HTML document shown in
xwidgets."
  `(let ((xwidget (xwidget-webkit-current-session))
         (linktext (car ,v))
         (linkurl (caddr ,v)))
    (xwwp-follow-link-cleanup xwidget)
    ,@body))

(defun xwwp-follow-link-ivy-copy-url-action (v)
  "Copy the selected url from candidate V to the `kill-ring'."
  (xwwp-follow-link-ivy-ivify-action v
   (kill-new linkurl)))

(defun xwwp-follow-link-ivy-browse-external-action (v)
  "Open the selected url from candidate V in the default browser."
  (xwwp-follow-link-ivy-ivify-action v
   (browse-url linkurl)))

(defun xwwp-follow-link-ivy-get-full-candidate (c)
  "Return the full candidate for a text candidate C from xwwp-follow-link-ivy."
  (with-current-buffer (ivy-state-buffer ivy-last)
    (let* ((collection (ivy-state-collection ivy-last)))
      (nth (get-text-property 0 'idx c) collection))))

(defun xwwp-follow-link-ivy-get-candidate-text (v)
  "Return the link text for completion candiate V for displaying candidates in `ivy-rich'."
  (substring-no-properties (car (xwwp-follow-link-ivy-get-full-candidate v))))

(defun xwwp-follow-link-ivy-get-candidate-url (v)
  "Return the url for for a complettion candidate V for displaying candidates in `ivy-rich'."
  (caddr (xwwp-follow-link-ivy-get-full-candidate v)))

;; add ivy actions
(ivy-add-actions
 'xwwp-follow-link-read
 '(("w" xwwp-follow-link-ivy-copy-url-action "Copy URL")
   ("e" xwwp-follow-link-ivy-browse-external-action "Open in default browser")))

(provide 'xwwp-follow-link-ivy)
;;; xwwp-follow-link-ivy.el ends here
