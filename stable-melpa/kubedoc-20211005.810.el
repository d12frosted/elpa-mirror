;;; kubedoc.el --- Kubernetes API Documentation -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Dean Lindqvist Todevski
;;
;; Author: Dean Lindqvist Todevski <https://github.com/r0bobo>
;; Maintainer: Dean Lindqvist Todevski
;; Keywords: docs help k8s kubernetes tools
;; Package-Version: 20211005.810
;; Package-Commit: 20692189359ce0517726a945c8ab798bb91a8624
;; Version: 1.0
;; Homepage: https://github.com/r0bobo/kubedoc.el/
;; Package-Requires: ((emacs "27.1"))

;; This file is NOT part of GNU Emacs.

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

;; kubedoc.el provides Kubernetes API documentation in Emacs.

;;; Code:

;;;; Requirements

(require 'cl-lib)
(require 'seq)
(require 'subr-x)

;;;; Completion style

(add-to-list 'completion-category-overrides '(kubedoc (styles partial-completion)))

;;;; Declarations

(defconst kubedoc-imenu-generic-expression
  '((nil "^   \\(\\w+\\)" 1 kubedoc--imenu-goto-field)))

(defconst kubedoc-font-lock-defaults
  `(("^KIND\\|^VERSION\\|^RESOURCE\\|^DESCRIPTION\\|^FIELDS?" . font-lock-keyword-face)
    ("-required-" . font-lock-function-name-face)
    ("\\(<.+>\\)\\( -required-\\)?$" 1 font-lock-comment-face)))

(defvar kubedoc-mode-map
  (let ((map (make-sparse-keymap)))
    (suppress-keymap map)
    (set-keymap-parent map (make-composed-keymap button-buffer-map special-mode-map))
    map))

(defvar kubedoc--field-completion-table-cache nil)

(defvar kubedoc--resource-completion-table-cache nil)

(defvar-local kubedoc--buffer-path nil)

(defvar kubedoc--field-completion-source-function nil)

(defvar kubedoc-resource-filter '("\\.metrics\\.k8s\\.io")
  "Resources to ignore in completion.
For example Aggregated APIs with no docs.")

(define-button-type 'kubedoc-field
  'follow-link t
  'help-echo "mouse-2, RET: display this section"
  'action #'kubedoc--field-button-function)


;;;; Commands

(defun kubedoc--imenu-goto-field (_name position)
  "Jump to correctly indented field POSITION."
  (goto-char (+ position 3)))

(defun kubedoc--highlight-field-links ()
  "Create field link buttons in current buffer."
  (while (re-search-forward "^   \\(\\w+\\)" nil t)
    (make-button
     (match-beginning 1)
     (match-end 1)
     'type 'kubedoc-field
     'kubectl-section (match-string 1))))

(defun kubedoc--kubectl-command (&rest args)
  "Run kubectl with ARGS and return output as string."
  (with-temp-buffer
    (let* ((command (string-join (append '("kubectl") (seq-map #'shell-quote-argument args)) " "))
           (returncode (call-process-shell-command command nil t))
           (output (buffer-substring (point-min) (point-max))))
      (if (zerop returncode)
          output
        (user-error (string-trim output))))))

(defun kubedoc--field-button-function (button)
  "Follow field link in BUTTON."
  (with-current-buffer (current-buffer)
    (let ((field (button-get button 'kubectl-section)))
      (apply #'kubedoc--view-resource (append kubedoc--buffer-path (list field))))))

(defun kubedoc--resource-completion-table ()
  "Completion candidate list for all known Kubernetes resources in the cluster."
  (seq-filter
   (lambda (e)
     (seq-every-p (lambda (regex) (not (string-match-p regex e))) kubedoc-resource-filter))
   (mapcar
    (lambda (e) (concat e "/"))
    (split-string
     (kubedoc--kubectl-command "api-resources" "--output" "name") nil t))))

(defun kubedoc--resource-completion-table-cached ()
  "Cached completion candidate list for all known Kubernetes resources in the cluster."
  (when (null kubedoc--resource-completion-table-cache)
    (setq kubedoc--resource-completion-table-cache (kubedoc--resource-completion-table)))
  kubedoc--resource-completion-table-cache)

(defun kubedoc--default-field-completion-source-function (resource)
  "Field completions for RESOURCE using shell command `kubectl explain'."
  (kubedoc--kubectl-command "explain" "--recursive" resource))

(defun kubedoc--field-completion-table (resource)
  "Completion candidate list for all fields of Kubernetes RESOURCE."
  (let* ((res '())
         (path '())
         (prev-indent 0)
         (explain-output-lines
          (split-string
           (funcall (or kubedoc--field-completion-source-function
                        #'kubedoc--default-field-completion-source-function)
                    resource)
           "\\\n" t))
         (explain-output-lines-trimmed
          (seq-drop-while
           (lambda (e) (not (string-match "^FIELDS" e)))
           explain-output-lines)))

    (dolist (item explain-output-lines-trimmed)
      (unless (string-match "^FIELDS" item)
        (string-match "^\\( +\\)\\(\\w+\\) ?" item)

        (let ((indent (/ (length (match-string 1 item)) 3))
              (match (match-string 2 item)))

          (unless (> indent prev-indent)
            (push (string-join (reverse path) "/") res))

          (cond
           ((< indent prev-indent)
            (setq path (nthcdr (+ 1 (- prev-indent indent)) path)))
           ((= indent prev-indent)
            (setq path (nthcdr 1 path))))

          (push match path)

          (when (string= item (car (reverse explain-output-lines)))
            (push (string-join (reverse path) "/") res))

          (setq prev-indent indent))))
    (mapcar (lambda (e) (concat resource "/" e)) res)))

(defun kubedoc--field-completion-table-cached (resource)
  "Cached Completion candidate list for all fields of Kubernetes RESOURCE."
  (let ((cached (cdr (assoc resource kubedoc--field-completion-table-cache))))
    (cond
     ((null cached)
      (let* ((all (if-let ((result (kubedoc--field-completion-table resource))) result 'none)))
        (cl-pushnew `(,resource . ,all) kubedoc--field-completion-table-cache)
        all)
      cached)
     ((eq cached 'none) nil)
     (t cached))))

(defun kubedoc--completion-table (path)
  "Completion candidate list for given Kubernetes resource and field PATH.
PATH is a filesystem style path such as pods/spec/containers"
  (let* ((string-parts (split-string path "/+"))
         (resource (car string-parts)))
    (if (= (length string-parts) 1)
        (seq-filter
         (lambda (e)
           (string-prefix-p path e))
         (kubedoc--resource-completion-table-cached))
      (seq-uniq
       (mapcar
        (lambda (e)
          (let* ((trimmed (string-remove-prefix (file-name-directory path) e))
                 (end (or (string-match-p "/" trimmed) (- (length trimmed) 1))))
            (substring trimmed 0 (+ end 1))))
        (seq-filter
         (lambda (e)
           (string-prefix-p path e))
         (kubedoc--field-completion-table-cached resource)))
       #'string-equal))))

(defun kubedoc--completion-sort (collection)
  "Completion candidate list sorting of COLLECTION.
Sorts alphabetically with parent fields on top."
  (seq-sort
   (lambda (a b)
     (let ((a-parent-p (string= (substring a -1) "/"))
           (b-parent-p (string= (substring b -1) "/")))
       (if (equal a-parent-p b-parent-p)
           (string< a b)
         a-parent-p)))
   collection))

(defun kubedoc--completion-function (string pred action)
  "Completion for Kubernetes API resources.
See argument STRING PRED ACTION descriptions in command `try-completion'."
  (cond
   ((eq action 'metadata)
    '(metadata (category . kubedoc)
               (display-sort-function . kubedoc--completion-sort)))

   ((eq (car-safe action) 'boundaries)
    (let* ((start (length (file-name-directory string)))
           (end (string-match-p "/" (cdr action))))
      `(boundaries ,start . ,end)))

   (t
    (let ((candidate
           (if (string-equal string "")
               string
             (string-remove-prefix (or (file-name-directory string) "") string))))
      (complete-with-action action (kubedoc--completion-table string) candidate pred)))))

(defun kubedoc--view-resource (resource &rest field)
  "Display Kubernetes api documentation for RESOURCE and optionally FIELD."
  (let* ((path (append (list resource) field))
         (prev-buffer (current-buffer))
         (buffer (concat "*Kubernetes Docs <" (string-join path "/") ">*")))
    (unless (get-buffer buffer)
      (with-current-buffer (get-buffer-create buffer)
        (insert (kubedoc--kubectl-command "explain" (string-join path ".")))
        (when field
          (goto-char (point-max))
          (insert "\n")
          (insert-text-button "Navigate up" 'action (lambda (_button) (kubedoc-up)))
          (insert "  ")
          (insert-text-button "Navigate to top" 'action (lambda (_button) (kubedoc-top)))
          (goto-char (point-min)))
        (untabify (point-min) (point-max))
        (kubedoc-mode)
        (setq-local kubedoc--buffer-path path)))
    (if (with-current-buffer prev-buffer (equal major-mode 'kubedoc-mode))
        (pop-to-buffer-same-window buffer)
      (pop-to-buffer buffer))))

(defun kubedoc--resource-path-canonical (resource &rest field)
  "Return canonical path for Kubernetes RESOURCE and optionally FIELD.
Paths are suffixed with a `/' if they contain any child fields."
  (let* ((path (string-join (append (list resource) field) "/"))
         (path-trailing-slash (concat path "/")))
    (if (kubedoc--completion-table path-trailing-slash) path-trailing-slash path)))


;;;; Interactive commands

;;;###autoload
(defun kubedoc ()
  "Kubernetes API documentation."
  (interactive)
  (let* ((current-path (if-let ((current kubedoc--buffer-path))
                           (apply #'kubedoc--resource-path-canonical current)
                         ""))
         (path (completing-read
                "Kubernetes resource: " #'kubedoc--completion-function
                nil nil current-path)))
    (apply #'kubedoc--view-resource (split-string (string-trim-right path "/+") "/"))))


(defun kubedoc-up ()
  "Navigate to parent field of current Kubernetes resource."
  (interactive)
  (let ((parts (buffer-local-value 'kubedoc--buffer-path (current-buffer))))
    (when (> (length parts) 1)
      (apply #'kubedoc--view-resource (butlast kubedoc--buffer-path)))))

(defun kubedoc-top ()
  "Navigate to top of current Kubernetes resource."
  (interactive)
  (let ((parts (buffer-local-value 'kubedoc--buffer-path (current-buffer))))
    (when (> (length parts) 1)
      (apply #'kubedoc--view-resource (list (car kubedoc--buffer-path))))))

(defun kubedoc-invalidate-cache ()
  "Invalidate kubedoc completion cache."
  (interactive)
  (setq kubedoc--field-completion-table-cache nil)
  (setq kubedoc--resource-completion-table-cache nil))


;;;; Mode
(define-derived-mode kubedoc-mode special-mode "kubedoc"
  "Major mode for displaying Kubernetes api documentation."
  (setq buffer-auto-save-file-name nil
        truncate-lines t
        font-lock-defaults '((kubedoc-font-lock-defaults))
        imenu-generic-expression kubedoc-imenu-generic-expression)
  (view-mode)
  (auto-fill-mode -1)
  (kubedoc--highlight-field-links)
  (goto-char (point-min)))


(provide 'kubedoc)
;;; kubedoc.el ends here
