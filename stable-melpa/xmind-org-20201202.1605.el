;;; xmind-org.el --- Import XMind mindmaps into Org -*- lexical-binding: t -*-

;; Copyright (C) 2020 Akira Komamura

;; Author: Akira Komamura <akira.komamura@gmail.com>
;; Version: 0.1
;; Package-Version: 20201202.1605
;; Package-Commit: ee09e382b3fefb67ccf3cd4db96a8dd2acc34045
;; Package-Requires: ((emacs "27.1") (org-ml "5.3") (dash "2.12"))
;; Keywords: outlines wp files
;; URL: https://github.com/akirak/xmind-org-el

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides `xmind-org-insert-file' command, which is a
;; function to import an XMind mindmap file into an Org buffer.

;;; Code:

(require 'org-ml)
(require 'seq)
(require 'dash)

(defgroup xmind-org nil
  "Convert XMind mindmaps to Org."
  :group 'outlines
  :group 'org)

(cl-defstruct xmind-org-node title id summary
              attached-children detached-children)

(defcustom xmind-org-unzip-command "unzip"
  "Executable of unzip command used to process mindmap files."
  :type 'file)

(defun xmind-org-parse-content (file)
  "Parse the content of a mindmap FILE."
  (let ((stdout (generate-new-buffer "*xmind content*")))
    (unwind-protect
        (when (zerop (call-process xmind-org-unzip-command nil
                                   (cons stdout nil)
                                   nil
                                   "-p" file "content.json"))
          (with-current-buffer stdout
            (goto-char (point-min))
            (json-parse-buffer :array-type 'list
                               :object-type 'hash-table
                               :null-object nil)))
      (kill-buffer stdout))))

(cl-defun xmind-org-root-node (doc &optional (tab 0))
  "Given a JSON content document, return its root node as `xmind-org-node'.

DOC is a list of mindmaps, which is usually a result of
`xmind-org-parse-content'.

Optional you can specify TAB, which is the index of a tab in the
document."
  (cl-labels
      ((build-node
        (obj)
        (let* ((children (gethash "children" obj))
               (attached (and children (gethash "attached" children)))
               (detached (and children (gethash "detached" children))))
          (make-xmind-org-node
           :title (gethash "title" obj)
           :id (gethash "id" obj)
           :summary (gethash "summary" obj)
           :attached-children
           (and attached (seq-map #'build-node attached))
           :detached-children
           (and detached (seq-map #'build-node detached))))))
    (build-node (gethash "rootTopic" (seq-elt doc tab)))))

(defsubst xmind-org--trim-space (str)
  "Trim consecutive whitespaces in STR."
  (replace-regexp-in-string (rx (+ (any space))) " " str))

(cl-defun xmind-org--build-org-ml-node (node level &key comment)
  "Build an org-ml node from the parsed node.

NODE must be of `xmind-org-node' type.

LEVEL is the heading level of the created Org node.

If COMMENT is non-nil, the node will have a comment heading."
  (let ((next-level (org-get-valid-level (1+ level)))
        (summary (xmind-org-node-summary node)))
    (apply #'org-ml-build-headline
           :title (list (xmind-org--trim-space (xmind-org-node-title node)))
           :level level
           :commentedp comment
           (append (when summary
                     (list (org-ml-build-paragraph summary)))
                   (mapcar `(lambda (child)
                              (xmind-org--build-org-ml-node child ,next-level
                                                            :comment t))
                           (xmind-org-node-detached-children node))
                   (mapcar `(lambda (child)
                              (xmind-org--build-org-ml-node child ,next-level))
                           (xmind-org-node-attached-children node))))))

(defun xmind-org-insert-node (node)
  "Convert NODE to Org and insert it at the current position."
  ;; Allow only at the beginning of a line
  (cl-assert (looking-at (rx bol)))
  (let ((start-level (if (org-before-first-heading-p)
                         1
                       (1+ (org-outline-level)))))
    (org-ml-insert (point)
                   (xmind-org--build-org-ml-node node start-level))))

;;;###autoload
(defun xmind-org-insert-file (file)
  "Insert an XMind FILE into the current Org buffer."
  (interactive "f")
  (cl-assert (derived-mode-p 'org-mode))
  (-> (xmind-org-parse-content file)
      (xmind-org-root-node)
      (xmind-org-insert-node)))

(provide 'xmind-org)
;;; xmind-org.el ends here
