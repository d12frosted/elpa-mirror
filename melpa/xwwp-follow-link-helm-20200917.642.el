;;; xwwp-follow-link-helm.el --- Link navigation in `xwidget-webkit' sessions using `helm' -*- lexical-binding: t; -*-

;; Author: Damien Merenne
;; URL: https://github.com/canatella/xwwp
;; Package-Version: 20200917.642
;; Package-Commit: 99670ec37e2083eada9691a342441d2fa4589002
;; Created: 2020-03-11
;; Keywords: convenience
;; Version: 0.1
;; Package-Requires: ((emacs "26.1") (xwwp "0.1"))

;; Copyright (C) 2020 Q. Hong <qhong@mit.edu>, Damien Merenne <dam@cosinux.org>

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
;; `helm' completion.

;;; Code:

(require 'xwwp-follow-link)
(require 'helm)

;; tell the compiler these do exists
(declare-function helm "helm")
(declare-function helm-get-selection "helm")
(declare-function helm-make-source "helm-source")

(defclass xwwp-follow-link-completion-backend-helm (xwwp-follow-link-completion-backend) ((candidates)))

(cl-defmethod xwwp-follow-link-candidates ((backend xwwp-follow-link-completion-backend-helm))
  (let* ((candidates (oref backend candidates))
         (selection (helm-get-selection))
         (result (seq-map #'cdr candidates)))
    (cons selection result)))

(cl-defmethod xwwp-follow-link-read ((backend xwwp-follow-link-completion-backend-helm) prompt collection action update-fn)
  (add-hook 'helm-after-initialize-hook (lambda ()
                                          (with-current-buffer "*helm-xwwp*"
                                            (add-hook 'helm-move-selection-after-hook update-fn nil t)))
            nil t)
  (or (helm :sources
            (helm-make-source "Xwidget Plus" 'helm-source-sync
              :candidates collection
              :action action
              :filtered-candidate-transformer (lambda (candidates _)
                                                (oset backend candidates candidates)
                                                (funcall update-fn)
                                                candidates))
            :prompt prompt
            :buffer "*helm-xwwp*") (signal 'quit nil)))

(provide 'xwwp-follow-link-helm)
;;; xwwp-follow-link-helm.el ends here
