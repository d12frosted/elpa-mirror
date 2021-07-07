;;; leaf-tree.el --- Interactive side-bar feature for init.el using leaf  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Version: 1.0.0
;; Package-Version: 20210503.531
;; Package-Commit: 8126baf45c881fd4a692c2d74f9cc2eb15170401
;; Keywords: convenience leaf
;; Package-Requires: ((emacs "25.1") (imenu-list "0.8"))
;; URL: https://github.com/conao3/leaf-tree.el

;; This program is free software: you can redistribute it and/or modify
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

;; Interactive side-bar feature for init.el using leaf.el.

;; To use this package, just invoke `M-x leaf-tree-mode'.


;;; Code:

(require 'seq)
(require 'cl-lib)
(require 'subr-x)
(require 'imenu-list)

(defgroup leaf-tree nil
  "Interactive folding Elisp code using :tag leaf keyword."
  :prefix "leaf-tree-"
  :group 'tools
  :link '(url-link :tag "Github" "https://github.com/conao3/leaf-tree.el"))

(defcustom leaf-tree-flat nil
  "Non-nil means make leaf-tree flat."
  :group 'leaf-tree
  :type 'boolean)

(defcustom leaf-tree-click-group-to-hide nil
  "Non-nil means hide child leaf-tree when click group line."
  :group 'leaf-tree
  :type 'boolean)

(defcustom leaf-tree-regexp (eval-when-compile
                              (require 'regexp-opt)
                              (concat "^\\s-*("
                                      (regexp-opt '("leaf") 'symbols)
                                      "\\s-+\\("
                                      (or (bound-and-true-p lisp-mode-symbol-regexp)
                                          "\\(?:\\sw\\|\\s_\\|\\\\.\\)+")
                                      "\\)"))
  "Regexp search `leaf'.
Regexp must have 2 group, for OP and LEAF--NAME.
See `leaf-enable-imenu-support' to reference regexp."
  :group 'leaf-tree
  :type 'string)


;;; Function

(defvar leaf-tree-mode)
(defvar leaf-tree--imenu--index-alist nil
  "Internal variable using `leaf-tree'.
The value is the same format as `imenu--index-alist'.

`imenu--index-alist' is alist like below format.
  imenu--index-alist := TREE
    TREE    := nil | (<GROUP | NODE>*)
    GROUP   := (<GROUP | (G_TITLE NODE+)>*)
    NODE    := (N_TITLE . MARKER)
    G_TITLE := <string>      ; Group title
    N_TITLE := <string>      ; Node title
    MARKER  := <marker>      ; Marker at definition beginning")

(defun leaf-tree--forward-sexp (&optional arg)
  "Move forward across one balanced expression (sexp).
With ARG, do it that many times.  see `forward-sexp'."
  (let ((prev (point)))
    (condition-case _
        (progn
          (apply #'forward-sexp `(,arg))
          (not (equal prev (point))))
      (scan-error nil))))

(defun leaf-tree--imenu--list-rescan-imenu ()
  "Create `leaf' index alist for the current buffer.
This function modify `leaf-tree--imenu--index-alist'."
  (let (acc)
    (setq acc (lambda (&optional contents)
                (while (and (re-search-forward leaf-tree-regexp nil t))
                  (let* ((beg (match-beginning 0))
                         ;; (op (match-string 1))
                         (leaf--name (match-string-no-properties 2))
                         (leaf--end (save-excursion
                                      (goto-char beg) (and (leaf-tree--forward-sexp) (point)))))
                    (if-let (child (save-restriction
                                     ;; Narrow this leaf and skip to next leaf
                                     (narrow-to-region beg leaf--end)
                                     (funcall acc)))
                        (push `(,leaf--name ,@child . ,(set-marker (make-marker) beg)) contents)
                      (push `(,leaf--name . ,(set-marker (make-marker) beg)) contents))
                    (goto-char leaf--end)))
                (nreverse contents)))
    (save-excursion
      (goto-char (point-min))
      (setq leaf-tree--imenu--index-alist `(("leaf-tree" ,@(funcall acc)))))))

(defun leaf-tree--imenu--list-rescan-imenu--flat ()
  "Create `leaf' index alist for the current buffer.
This function modify `leaf-tree--imenu--index-alist' in flat list."
  (let (ret)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward leaf-tree-regexp nil t)
        (let ((beg (match-beginning 0))
              ;; (op (match-string 1))
              (leaf--name (match-string-no-properties 2)))
          (push `(,leaf--name . ,(set-marker (make-marker) beg)) ret))))
    (setq leaf-tree--imenu--index-alist `(("leaf-tree (flat)" ,@(nreverse ret))))))


;;; Advice

(defvar leaf-tree-advice-alist
  '((imenu-list-collect-entries . leaf-tree--advice-imenu-list-collect-entries)
    (imenu-list--find-entry     . leaf-tree--advice-imenu-list--find-entry)
    (imenu-list--insert-entry   . leaf-tree--advice-imenu-list--insert-entry)
    (imenu-list--insert-entries-internal . leaf-tree--advice-imenu-list--insert-entries-internal))
  "Alist for leaf-tree advice.
See `leaf-tree--setup' and `leaf-tree--teardown'.")

(defun leaf-tree--advice-imenu-list-collect-entries (fn &rest args)
  "Around advice for FN with ARGS.
This code based on `imenu-list' (2019/03/15 hash:4600873)
See `imenu-list-collect-entries'."
  (if (not leaf-tree-mode)
      (apply fn args)
    (if leaf-tree-flat         ; renew `leaf-tree--imenu--index-alist'
        (leaf-tree--imenu--list-rescan-imenu--flat)
      (leaf-tree--imenu--list-rescan-imenu))
    (setq imenu-list--imenu-entries leaf-tree--imenu--index-alist)
    (setq imenu-list--displayed-buffer (current-buffer))))

(defun leaf-tree--advice-imenu-list--find-entry (fn &rest args)
  "Around advice for FN with ARGS.
This code based on `imenu-list' (2019/03/15 hash:4600873)
See `imenu-list--find-entry'."
  (let ((buf (or imenu-list--displayed-buffer (current-buffer))))
    (if (not (buffer-local-value 'leaf-tree-mode buf))
        (apply fn args)
      (let ((entry (nth (1- (line-number-at-pos)) imenu-list--line-entries)))
        (if (not (listp (cdr entry)))
            entry
          `(,(car entry) . ,(cdr (last entry))))))))

(defun leaf-tree--advice-imenu-list--insert-entry (fn &rest args)
  "Around advice for FN with ARGS.
This code based on `imenu-list' (2019/03/15 hash:4600873)
See `imenu-list--insert-entry'."
  (let ((buf (or imenu-list--displayed-buffer (current-buffer))))
    (if (not (buffer-local-value 'leaf-tree-mode buf))
        (apply fn args)
      (seq-let (entry depth) args
        (if (imenu--subalist-p entry)
            (progn
              (insert (imenu-list--depth-string depth))
              (insert-button (format "+ %s" (car entry))
                             'face (imenu-list--get-face depth t)
                             'help-echo (format (if leaf-tree-click-group-to-hide
                                                    "Toggle: %s"
                                                  "Go to: %s")
                                                (car entry))
                             'follow-link t
                             'action
                             (if leaf-tree-click-group-to-hide
                                 #'imenu-list--action-toggle-hs
                               #'imenu-list--action-goto-entry))
              (insert "\n"))
          (insert (imenu-list--depth-string depth))
          (insert-button (format "%s" (car entry))
                         'face (imenu-list--get-face depth nil)
                         'help-echo (format "Go to: %s"
                                            (car entry))
                         'follow-link t
                         'action #'imenu-list--action-goto-entry)
          (insert "\n"))))))

(defun leaf-tree--safe-mapcar (fn seq)
  "Apply FN to each element of SEQ, and make a list of the results.
The result is a list just as long as SEQUENCE.
SEQ may be a list, a vector, a 'bool-vector, or a string.
Unlike `mapcar', it works well with dotlist (last cdr is non-nil list)."
  (when (cdr (last seq))
    (setq seq (cl-copy-list seq))
    (setcdr (last seq) nil))
  (mapcar fn seq))

(defun leaf-tree--advice-imenu-list--insert-entries-internal (fn &rest args)
  "Around advice for FN with ARGS.
This code based on `imenu-list' (2019/03/15 hash:4600873)
See `insert-entries-internal'."
  (let ((buf (or imenu-list--displayed-buffer (current-buffer))))
    (if (not (buffer-local-value 'leaf-tree-mode buf))
        (apply fn args)
      (seq-let (index-alist depth) args
        (leaf-tree--safe-mapcar
         (lambda (entry)
           (setq imenu-list--line-entries (append imenu-list--line-entries (list entry)))
           (imenu-list--insert-entry entry depth)
           (when (imenu--subalist-p entry)
             (imenu-list--insert-entries-internal (cdr entry) (1+ depth))))
         index-alist)))))


;;; Main

(defvar leaf-tree--imenu-list-minor-mode-value nil
  "Stored `imenu-list-minor-mode' value before minor-mode enable.")

(defun leaf-tree--setup ()
  "Setup leaf-tree."
  (setq leaf-tree--imenu-list-minor-mode-value (if imenu-list-minor-mode 1 -1))
  (pcase-dolist (`(,sym . ,fn) leaf-tree-advice-alist)
    (advice-add sym :around fn))
  (imenu-list-minor-mode)
  (imenu-list-update 'force))

(defun leaf-tree--teardown ()
  "Teardown leaf-tree."
  (imenu-list-minor-mode leaf-tree--imenu-list-minor-mode-value)
  (pcase-dolist (`(,sym . ,fn) leaf-tree-advice-alist)
    (advice-remove sym fn)))

;;;###autoload
(define-minor-mode leaf-tree-mode
  "Toggle `leaf' specific customizations for `imenu-list'."
  :require 'leaf-tree
  :group 'leaf-tree
  :lighter " leaf-tree"
  (if leaf-tree-mode
      (leaf-tree--setup)
    (leaf-tree--teardown)))

(provide 'leaf-tree)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; leaf-tree.el ends here
