;;; sideline-lsp.el --- Show lsp information with sideline  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Shen, Jen-Chieh

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Maintainer: Shen, Jen-Chieh <jcs090218@gmail.com>
;; URL: https://github.com/emacs-sideline/sideline-lsp
;; Package-Version: 20220629.757
;; Package-Commit: b340c1e9a6d26ad4b3afe6aa660d62e8cebd66c8
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (sideline "0.1.0") (lsp-mode "6.0") (dash "2.18.0") (ht "2.4") (s "1.12.0"))
;; Keywords: convenience lsp

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Support for lsp code actions,
;;
;; 1) Add sideline-lsp to sideline backends list,
;;
;;   (setq sideline-backends-right '(sideline-lsp))
;;
;; 2) Then enable sideline-mode in the target buffer,
;;
;;   M-x sideline-mode
;;
;; Make sure your have lsp-mode enabled, and connected to the language server.
;;

;;; Code:

(require 'cl-lib)
(require 'subr-x)

(require 'dash)
(require 'ht)
(require 'lsp-mode)
(require 's)
(require 'sideline)

(defgroup sideline-lsp nil
  "Show lsp information with sideline."
  :prefix "sideline-lsp-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/emacs-sideline/sideline-lsp"))

(defcustom sideline-lsp-update-mode 'point
  "Define the mode for updating sideline actions.

When set to `line' the actions will be updated when user changes current line
otherwise the actions will be updated when user changes current point."
  :type '(choice (const line)
                 (const point))
  :group 'sideline-lsp)

(defcustom sideline-lsp-ignore-duplicate nil
  "Ignore duplicates when there is a same symbol with the same contents."
  :type 'boolean
  :group 'sideline-lsp)

(defcustom sideline-lsp-actions-kind-regex "quickfix.*\\|refactor.*"
  "Regex for the code actions kinds to show in the sideline."
  :type 'string
  :group 'sideline-lsp)

(defface sideline-lsp-code-action
  '((((background light)) :foreground "DarkOrange")
    (t :foreground "yellow"))
  "Face used to highlight code action text."
  :group 'sideline-lsp)

(defcustom sideline-lsp-code-actions-prefix "💡 "
  "Prefix to insert before the code action title.
This can be used to insert, for example, an unicode character: 💡"
  :type 'string
  :group 'sideline-lsp)

(defvar-local sideline-lsp--ht-code-actions nil
  "Holds code actions in (string . action) to display in sideline.")

;;;###autoload
(defun sideline-lsp (command)
  "Backend for sideline.

Argument COMMAND is required in sideline backend."
  (cl-case command
    (`candidates
     (when (and (bound-and-true-p lsp-managed-mode)  ; check connection
                (or (lsp--capability "codeActionProvider")
                    (lsp--registered-capability "textDocument/codeAction")))
       (cons :async #'sideline-lsp--run)))
    (`action
     (lambda (candidate &rest _)
       (funcall (ht-get sideline-lsp--ht-code-actions candidate))))))

(defun sideline-lsp--line-diags (line)
  "Return LINE's diagnostics."
  (->> (--filter
        (let ((range (lsp-get it :range)))
          (or (-some-> range (lsp-get :start) (lsp-get :line) (= line))
              (-some-> range (lsp-get :end) (lsp-get :line) (= line))))
        (lsp--get-buffer-diagnostics))
       (apply 'vector)))

(defun sideline-lsp--run (callback &rest _)
  "Send async request.

Execute CALLBACK to display candidates in sideline."
  (let* ((buffer (current-buffer))
         (bol (line-beginning-position)) (eol (line-end-position))
         (line-widen (or (and (buffer-narrowed-p) (save-restriction (widen) (line-number-at-pos)))
                         (line-number-at-pos)))
         (doc-id (lsp--text-document-identifier)))
    (lsp-request-async
     "textDocument/codeAction"
     (-let (((start . end) (if (eq sideline-lsp-update-mode 'line)
                               (cons 0 (- eol bol))
                             (--> (- (point) bol) (cons it it)))))
       (list :textDocument doc-id
             :range (list :start (list :line (1- line-widen) :character start)
                          :end (list :line (1- line-widen) :character end))
             :context (list :diagnostics (sideline-lsp--line-diags (1- line-widen)))))
     (lambda (actions)
       (when (eq (current-buffer) buffer)
         (sideline-lsp--code-actions callback actions)))
     :mode 'tick
     :cancel-token :sideline-lsp-code-actions)))

(defun sideline-lsp--code-actions (callback actions)
  "Show code ACTIONS.

Execute CALLBACK to display candidates in sideline."
  (when sideline-lsp-actions-kind-regex
    (setq actions (seq-filter (-lambda ((&CodeAction :kind?))
                                (or (not kind?)
                                    (s-match sideline-lsp-actions-kind-regex kind?)))
                              actions)))
  (setq sideline-lsp--ht-code-actions (ht-create))
  (dolist (action actions)
    (-let*
        ((title (->> (lsp:code-action-title action)
                     (replace-regexp-in-string "[\n\t ]+" " ")
                     (replace-regexp-in-string " " " ")
                     (concat sideline-lsp-code-actions-prefix)))
         (code-action (lambda () (save-excursion (lsp-execute-code-action action))))
         (len (length title))
         (title (progn
                  (add-face-text-property 0 len 'sideline-lsp-code-action nil title)
                  title)))
      (when (or (not sideline-lsp-ignore-duplicate)
                (not (member title (ht-keys sideline-lsp--ht-code-actions))))
        (ht-set sideline-lsp--ht-code-actions title code-action))))
  (funcall callback (ht-keys sideline-lsp--ht-code-actions)))

(provide 'sideline-lsp)
;;; sideline-lsp.el ends here
