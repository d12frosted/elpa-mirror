;;; helm-sage.el --- A helm extension for sage-shell-mode.

;; Copyright (C) 2012-2016 Sho Takemori.
;; Author: Sho Takemori <stakemorii@gmail.com>
;; URL: https://github.com/stakemori/helm-sage
;; Keywords: Sage, math, helm
;; Version: 0.0.4
;; Package-Requires: ((cl-lib "0.5") (helm "1.5.6") (sage-shell-mode "0.1.0"))

;;; License
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
;; helm-sage provides 4 commands.
;; Bind them to some keys: e.g.
;; (eval-after-load "sage-shell-mode"
;;   '(sage-shell:define-keys sage-shell-mode-map
;;      "C-c C-i"  'helm-sage-complete
;;      "C-c C-h"  'helm-sage-describe-object-at-point
;;      "M-r"      'helm-sage-command-history
;;      "C-c o"    'helm-sage-output-history))

;;; Code:
(defgroup helm-sage
  nil "a helm source for `sage-shell-mode'."
  :group 'helm)

(require 'cl-lib)
(require 'helm)
(require 'sage-shell-mode)

(defvar helm-sage-action-alist
  '(("Insert" . helm-sage-objcts-insert-action)
    ("View Docstring" . helm-sage-show-doc)))

(defvar helm-sage-additional-action-alist
  '(("View Source File" . (lambda (can)
                            (sage-shell:find-source-in-view-mode
                             (sage-shell-cpl:to-objname-to-send can))))))

(defcustom helm-sage-candidate-regexp (rx alnum (zero-or-more (or alnum "_")))
  "Regexp used for collecting Sage attributes and functions."
  :group 'helm-sage
  :type 'regexp)

(defvar helm-source-sage-objects
  (helm-build-in-buffer-source "Sage objects"
    :data (lambda ()
            (sage-shell-cpl:candidates-sync helm-sage-candidate-regexp))
    :action (append helm-sage-action-alist
                    helm-sage-additional-action-alist)))

(defvar helm-source-sage-help
  (helm-build-in-buffer-source "Sage Documents"
    :data (lambda ()
            (sage-shell-cpl:candidates-sync helm-sage-candidate-regexp))
    :action (append (reverse helm-sage-action-alist)
                    helm-sage-additional-action-alist)))

(defun helm-sage-objcts-insert-action (can)
  (with-current-buffer helm-current-buffer
    (sage-shell:insert-action can)))

;;;###autoload
(defalias 'helm-sage-shell 'helm-sage-complete)

;;;###autoload
(defun helm-sage-complete ()
  (interactive)
  (helm
   :sources '(helm-source-sage-objects)
   :input (sage-shell:word-at-point)
   :buffer "*helm Sage*"))

;;;###autoload
(defalias 'helm-sage-shell-describe-object-at-point
  'helm-sage-describe-object-at-point)

;;;###autoload
(defun helm-sage-describe-object-at-point ()
  (interactive)
  (helm
   :sources '(helm-source-sage-help)
   :input (sage-shell:word-at-point)
   :buffer "*helm Sage*"))

(defun helm-sage-show-doc (can)
  (if (sage-shell:at-top-level-p)
      (sage-shell-help:describe-symbol
       (sage-shell-cpl:to-objname-to-send can))
    (message "Document help is not available here.")))

(defvar helm-sage-commnd-list-cached nil)

(defvar helm-source-sage-command-history
  (helm-build-sync-source "Sage Command History"
    :init 'helm-sage-make-command-list
    :action '(("Insert" . helm-sage-objcts-insert-action))
    :candidates (lambda () helm-sage-commnd-list-cached)))

(defun helm-sage-make-command-list ()
  (setq helm-sage-commnd-list-cached
        (cl-loop for i from 0 to (ring-size comint-input-ring)
         collect (ring-ref comint-input-ring i))))

;;;###autoload
(defun helm-sage-command-history ()
  (interactive)
  (helm
   :sources '(helm-source-sage-command-history)
   :buffer "*helm Sage*"))

(defcustom helm-sage-output-format "_%s"
  "Format string used for helm-sage-output-history."
  :group 'helm-sage
  :type 'string)

(defun helm-sage-make-outputs-list ()
  (let ((out (sage-shell:-inputs-outputs)))
    (cl-loop for a in out
             collect (replace-regexp-in-string
                      (rx (or (and bol "\n") (and "\n" eol)))
                      "" a t))))

(defun helm-sage-output-history-action (c)
  (when (string-match (rx bol "In " "[" (group (1+ num)) "]") c)
    (with-current-buffer helm-current-buffer
      (insert (format helm-sage-output-format (match-string 1 c))))))

(defvar helm-sage-source-output-history
  (helm-build-sync-source
   "Sage Output History"
   :candidates (lambda () (with-current-buffer helm-current-buffer
                        (helm-sage-make-outputs-list)))
   :action '(("Insert the output" . helm-sage-output-history-action))
   :multiline t))

;;;###autoload
(defun helm-sage-output-history ()
  "List output history."
  (interactive)
  (helm :sources '(helm-sage-source-output-history)
        :buffer "*helm Sage Outputs*"))


(provide 'helm-sage)
;;; helm-sage.el ends here
