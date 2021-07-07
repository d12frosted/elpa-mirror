;;; org-ac.el --- Some auto-complete sources for org-mode

;; Copyright (C) 2014  Hiroaki Otsu

;; Author: Hiroaki Otsu <ootsuhiroaki@gmail.com>
;; Keywords: org, completion
;; Package-Version: 20170401.1307
;; Package-Commit: 41e3ef8e4039619d0370c23c66730b3b2e9e32ed
;; URL: https://github.com/aki2o/org-ac
;; Version: 0.0.2
;; Package-Requires: ((auto-complete-pcmp "0.0.1") (log4e "0.2.0") (yaxception "0.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; 
;; This extension provides auto-complete sources for org-mode.

;;; Dependency:
;; 
;; - auto-complete-pcmp.el ( see <https://github.com/aki2o/auto-complete-pcmp> )
;; - yaxception.el ( see <https://github.com/aki2o/yaxception> )
;; - log4e.el ( see <https://github.com/aki2o/log4e> )

;;; Installation:
;;
;; Put this to your load-path.
;; And put the following lines in your .emacs or site-start.el file.
;; 
;; (require 'org-ac)

;;; Configuration:
;; 
;; ;; Make config suit for you. About the config item, see Customization or eval the following sexp.
;; ;; (customize-group "org-ac")
;; 
;; (org-ac/config-default)

;;; Customization:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'user-variable :prefix "org-ac/" :docstring t)
;; `org-ac/ac-trigger-command-keys'
;; Keystrokes for doing `ac-start' with self insert.
;; 
;;  *** END auto-documentation

;;; API:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'command :prefix "org-ac/" :docstring t)
;; `org-ac/setup-current-buffer'
;; Do setup for using org-ac in current buffer.
;; 
;;  *** END auto-documentation
;; [Note] Functions and variables other than listed above, Those specifications may be changed without notice.

;;; Tested On:
;; 
;; - Emacs ... GNU Emacs 24.3.1 (i686-pc-linux-gnu, GTK+ Version 3.4.2) of 2013-08-22 on chindi02, modified by Debian
;; - auto-complete-pcmp.el ... Version 0.0.1
;; - yaxception.el ... Version 0.1
;; - log4e.el ... Version 0.2.0


;; Enjoy!!!


(eval-when-compile (require 'cl))
(require 'org)
(require 'auto-complete-pcmp)
(require 'rx)
(require 'log4e)
(require 'yaxception)

(defgroup org-ac nil
  "Auto completion for org-mode."
  :group 'org
  :prefix "org-ac/")

(defcustom org-ac/ac-trigger-command-keys '("\\" "*" "SPC" ":" "[" "+")
  "Keystrokes for doing `ac-start' with self insert."
  :type '(repeat string)
  :group 'org-ac)


(log4e:deflogger "org-ac" "%t [%l] %m" "%H:%M:%S" '((fatal . "fatal")
                                                    (error . "error")
                                                    (warn  . "warn")
                                                    (info  . "info")
                                                    (debug . "debug")
                                                    (trace . "trace")))
(org-ac--log-set-level 'trace)


(defun* org-ac--show-message (msg &rest args)
  (apply 'message (concat "[ORG-AC] " msg) args)
  nil)

(defun org-ac--complete-close-option-at-current-point ()
  (let ((pt (point)))
    (yaxception:$
      (yaxception:try
        (org-ac--trace "start complete close option at current point")
        (when (save-excursion
                (re-search-backward "#\\+\\(begin\\|BEGIN\\)_\\([a-zA-Z0-9]+\\) *\\=" nil t))
          (let* ((opennm (match-string-no-properties 1))
                 (typenm (match-string-no-properties 2))
                 (closenm (cond ((string= opennm "begin") "end")
                                ((string= opennm "BEGIN") "END")))
                 (case-fold-search t))
            (if (or (not (re-search-forward "^[ \t]*#\\+" nil t))
                    (not (re-search-forward (concat "\\=" closenm "_") nil t)))
                (progn (goto-char pt)
                       (insert "\n#+" closenm "_" typenm)
                       (org-cycle))
              (let ((currtypenm (if (re-search-forward "\\=\\([a-zA-Z0-9]+\\)" nil t)
                                    (match-string-no-properties 1)
                                  "")))
                (backward-delete-char (+ (length closenm)
                                         1
                                         (length currtypenm)))
                (insert closenm "_" typenm)))
            (goto-char pt))))
      (yaxception:catch 'error e
        (org-ac--show-message "Failed complete close option : %s" (yaxception:get-text e))
        (org-ac--error "failed complete close option at current point : %s\n%s"
                       (yaxception:get-text e)
                       (yaxception:get-stack-trace-string e))
        (goto-char pt)))))

(defun org-ac--get-link-head-candidates ()
  (append (ac-pcmp/get-ac-candidates)
          (mapcar (lambda (x) (concat x ":")) org-link-types)))

(defvar ac-source-org-ac-tex
  '((candidates . ac-pcmp/get-ac-candidates)
    (prefix . "\\\\\\([a-zA-Z0-9_-]*\\)")
    (symbol . "t")
    (requires . 0)
    (cache)
    (action . ac-pcmp/do-ac-action)))

(defvar ac-source-org-ac-head
  '((candidates . ac-pcmp/get-ac-candidates)
    (prefix . "[^\r\n*]\\*\\([^\t\r\n]*\\)")
    (symbol . "h")
    (requires . 0)
    (cache)
    (action . ac-pcmp/do-ac-action)))

(defvar ac-source-org-ac-todo
  '((candidates . ac-pcmp/get-ac-candidates)
    (prefix . "^\\*+ \\([a-zA-Z0-9_-]*\\)")
    (symbol . "d")
    (requires . 0)
    (cache)
    (action . ac-pcmp/do-ac-action)))

(defvar ac-source-org-ac-tag
  '((candidates . ac-pcmp/get-ac-candidates)
    (prefix . "[ \t]:\\([a-zA-Z0-9_-]*\\)")
    (symbol . "t")
    (requires . 0)
    (cache)
    (action . ac-pcmp/do-ac-action)))

(defvar org-ac--regexp-link-head (rx-to-string `(and "["
                                                     (* (any " \t"))
                                                     "["
                                                     (group (* (not (any ":*]")))))))
(defvar ac-source-org-ac-link-head
  `((candidates . org-ac--get-link-head-candidates)
    (prefix . ,org-ac--regexp-link-head)
    (symbol . "l")
    (requires . 0)
    (cache)
    (action . (lambda ()
                (ac-pcmp/do-ac-action)
                (ac-start)))))

(defvar ac-source-org-ac-option
  '((candidates . ac-pcmp/get-ac-candidates)
    (prefix . "^[ \t]*#\\+\\([a-zA-Z0-9_:=-]*\\)")
    (symbol . "o")
    (requires . 0)
    (cache)
    (action . (lambda ()
                (ac-pcmp/do-ac-action)
                (org-ac--complete-close-option-at-current-point)
                (auto-complete '(ac-source-org-ac-option-key))))))

(defvar ac-source-org-ac-option-key
  '((candidates . ac-pcmp/get-ac-candidates)
    (prefix . "^[ \t]*#\\+[a-zA-Z0-9_:=-]+ +\\([a-zA-Z0-9_-]*\\)")
    (symbol . "k")
    (requires . 0)
    (cache)
    (action . ac-pcmp/do-ac-action)))

(defvar ac-source-org-ac-option-options
  '((candidates . ac-pcmp/get-ac-candidates)
    (prefix . "^[ \t]*#\\+\\(?:options\\|OPTIONS\\):.* +\\([a-zA-Z0-9_-]*\\)")
    (symbol . "x")
    (requires . 0)
    (cache)
    (action . ac-pcmp/do-ac-action)))

(defvar ac-source-org-ac-file
  '((init . (setq ac-filename-cache nil))
    (candidates . org-ac/file-candidate)
    (prefix . "\\[file:\\(.*\\)")
    (symbol . "f")
    (requires . 0)
    (action . ac-start)
    (limit . nil)))


;;;###autoload
(defun org-ac/setup-current-buffer ()
  "Do setup for using org-ac in current buffer."
  (interactive)
  (when (eq major-mode 'org-mode)
    (loop for stroke in org-ac/ac-trigger-command-keys
          do (local-set-key (read-kbd-macro stroke) 'ac-pcmp/self-insert-command-with-ac-start))
    (add-to-list 'ac-sources 'ac-source-org-ac-tex)
    (add-to-list 'ac-sources 'ac-source-org-ac-head)
    (add-to-list 'ac-sources 'ac-source-org-ac-todo)
    (add-to-list 'ac-sources 'ac-source-org-ac-tag)
    (add-to-list 'ac-sources 'ac-source-org-ac-link-head)
    (add-to-list 'ac-sources 'ac-source-org-ac-option)
    (add-to-list 'ac-sources 'ac-source-org-ac-option-key)
    (add-to-list 'ac-sources 'ac-source-org-ac-option-options)
    (add-to-list 'ac-sources 'ac-source-org-ac-file)
    (auto-complete-mode t)))

;;;###autoload
(defun org-ac/config-default ()
  "Do setting recommemded configuration."
  (add-to-list 'ac-modes 'org-mode)
  (add-hook 'org-mode-hook 'org-ac/setup-current-buffer t))


(defun org-ac/file-candidate ()
  "Adds [file: to the normal file completition, plus allows relative paths"
  (if (string-match "^[~./]+" ac-prefix)
      (ac-filename-candidate)
    (let ((ac-prefix (concat "./" ac-prefix)))
      (mapcar (lambda (path) (substring path 2))
              (ac-filename-candidate)))))


(provide 'org-ac)
;;; org-ac.el ends here
