;;; org-generate.el --- Generate template files/folders from org document  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Version: 1.0.5
;; Package-Version: 20200815.736
;; Package-Commit: 98825efb73c4537f05f653ce40e639a220d2ee5d
;; Keywords: convenience
;; Package-Requires: ((emacs "26.1") (org "9.3") (mustache "0.23"))
;; URL: https://github.com/conao3/org-generate.el

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

;; Generate template files/folders from org document.


;;; Code:

(require 'subr-x)
(require 'org)
(require 'org-element)
(require 'mustache)

(defgroup org-generate nil
  "Generate template files/folders from org document."
  :group 'convenience
  :link '(url-link :tag "Github" "https://github.com/conao3/org-generate.el"))

(defcustom org-generate-file (locate-user-emacs-file "org-generate.org")
  "File template definition path."
  :group 'org-generate
  :type 'string)

(defcustom org-generate-edit-recursive-edit nil
  "If non-nil, use `recursive-edit' for `org-generate-edit'."
  :group 'org-generate
  :type 'boolean)

(defcustom org-generate-with-export-as-org t
  "If non-nil, the target's definition is exported as org beforehand.
By exporting as org before generating it is possible to use some additional org
features like including files, macros replacements and the noweb reference
syntax."
  :group 'org-generate
  :type 'boolean)

(defcustom org-generate-show-save-message t
  "If non-nil, show message after save files."
  :group 'org-generate
  :type 'boolean)

(defvar org-generate-root nil)
(defvar org-generate-mustache-info nil)
(defvar org-generate--file-buffer nil)
(defun org-generate-file-buffer ()
  "Return org-generate file buffer."
  (or (and (buffer-live-p org-generate--file-buffer)
           org-generate--file-buffer)
      (setq org-generate--file-buffer
            (find-file-noselect org-generate-file))))

(defun org-generate--hash-table-from-alist (alist)
  "Create hash table from ALIST."
  (let ((h (make-hash-table :test 'equal)))
    ;; the first key-value pair in an alist gets precedence, so we
    ;; start from the end of the list:
    (dolist (pair (reverse alist) h)
      (let ((key (car pair))
            (value (cdr pair)))
        (puthash key value h)))))

(defun org-generate-get-heading ()
  "Get `org' heading."
  (with-current-buffer (org-generate-file-buffer)
    (letrec ((fn (lambda (elm)
                   (mapcar
                    (lambda (elm)
                      (when (eq (car elm) 'headline)
                        (cons
                         (nth 1 elm)
                         (funcall fn (cddr elm)))))
                    elm))))
      (funcall
       fn
       (org-element-contents
        (org-element-parse-buffer 'headline))))))

(defun org-generate-candidate ()
  "Get `org' candidate heading for `current-buffer'."
  (let (res)
    (dolist (h1 (org-generate-get-heading))
      (dolist (h2 (cdr h1))
        (push (format "%s/%s"
                      (plist-get (car h1) :raw-value)
                      (plist-get (car h2) :raw-value))
              res)))
    (nreverse res)))

(defun org-generate-search-heading (queue)
  "Search QUEUE from `org-generate-get-heading'."
  (let* ((fn (lambda (h seq)
               (cl-find-if
                (lambda (elm)
                  (cl-find-if
                   (lambda (e)
                     (string= h (plist-get e :raw-value)))
                   elm))
                seq)))
         (lst (split-string queue "/"))
         (h1 (nth 0 lst))
         (h2 (nth 1 lst)))
    (when-let* ((tmp (funcall fn h1 (org-generate-get-heading)))
                (tmp (funcall fn h2 tmp)))
      tmp)))

(defun org-generate--create-string-for-export (heading)
  "Return the string to use for export to org for HEADING in the current buffer.
The string returned consists of the target's heading and its subtree, its parent
heading including the content before the first child , and the content before
the first heading.  This is needed to avoid macro replacments in parts that are
not relevant."
  (let* ((start (plist-get (car heading) :begin))
         regions)
    (save-excursion
      (save-match-data
        ;; Target heading and its subtree.
        (push (cons start (plist-get (car heading) :end)) regions)
        ;; Parent's heading and content.
        (goto-char start)
        (org-up-heading-safe)
        (push (cons (point) (outline-next-heading)) regions)
        ;; Content before first heading.
        (goto-char (point-min))
        (unless (org-at-heading-p)
          (push (cons (point-min) (outline-next-heading)) regions))))
    ;; Create the string for export.
    (apply #'concat
           (mapcar
            (lambda (e) (buffer-substring-no-properties (car e) (cdr e)))
            regions))))

(defvar org-export-with-properties)
(defun org-generate--export-string-as-org (string)
  "Export the STRING as org and return the exported string.
Properties are exported as well."
  (require 'ox-org)
  (let ((org-export-with-properties t))
    (org-export-string-as string 'org t)))

(defun org-generate--with-export (heading)
  "Return a new buffer with the definition for HEADING exported as org."
  (let* ((string-to-export (org-generate--create-string-for-export heading))
         (exported-string (org-generate--export-string-as-org string-to-export))
         (export-buffer (generate-new-buffer "*org-generate-temp*")))
    (with-current-buffer export-buffer
      (insert exported-string)
      (let ((org-inhibit-startup t))
        (org-mode)))
    export-buffer))

;;;###autoload
(defun org-generate-edit ()
  "Open `org-generate-file'."
  (interactive)
  (if org-generate-edit-recursive-edit
      (save-window-excursion
        (save-excursion
          (pop-to-buffer-same-window (org-generate-file-buffer))
          (recursive-edit)))
    (pop-to-buffer-same-window (org-generate-file-buffer))))

(defun org-generate-1 (root heading)
  "Generate file from HEADING.
If ROOT is non-nil, omit some conditions."
  (if root
      (dolist (elm heading)
        (org-generate-1 nil elm))
    (when-let* ((heading* (car-safe heading))
                (title (plist-get heading* :title))
                (title* (mustache-render title org-generate-mustache-info)))
      (when (and (not (string-suffix-p "/" title*)) (cdr heading))
        (error "Heading %s is not suffixed \"/\", but it have childlen" title*))
      (when (string-empty-p title*)
        (error "Heading %s will be empty string.  We could not create file with empty name" title))
      (if (string-suffix-p "/" title*)
          (mkdir (expand-file-name title* default-directory) 'parent)
        (let ((src
               (save-excursion
                 (save-restriction
                   (narrow-to-region
                    (plist-get heading* :begin) (plist-get heading* :end))
                   (goto-char (point-min))
                   (let ((case-fold-search t))
                     (when (search-forward "#+begin_src" nil 'noerror)
                       (goto-char (match-beginning 0))))
                   (org-element-src-block-parser (point-max) nil)))))
          (unless src
            (error "Node %s has no src block" title*))
          (let* ((file (expand-file-name title* default-directory))
                 (srcbody (org-remove-indentation (plist-get (cadr src) :value)))
                 (srcbody* (mustache-render srcbody org-generate-mustache-info)))
            (with-temp-file file
              (insert srcbody*))
            (when org-generate-show-save-message
              (message "[org-generate] Saved: %s" file)))))
      (dolist (elm (cdr heading))
        (let ((default-directory
                (expand-file-name title* default-directory)))
          (org-generate-1 nil elm))))))

;;;###autoload
(defun org-generate (target)
  "Generate files from org document using TARGET definition."
  (interactive (list
                (completing-read
                 "Generate: "
                 (org-generate-candidate) nil 'match)))
  (let ((dir default-directory)
        export-buffer)
    (with-current-buffer (org-generate-file-buffer)
      (let ((heading (org-generate-search-heading target)))
        (unless heading
          (error "%s is not defined at %s" target org-generate-file))
        ;; Export as org to new buffer before if needed.
        (when org-generate-with-export-as-org
          (setq export-buffer (org-generate--with-export heading))
          (set-buffer export-buffer)
          ;; Update heading positions.
          (let ((org-generate--file-buffer export-buffer))
            (setq heading (org-generate-search-heading target))))
        (unwind-protect
            (let* ((fn (lambda (elm)
                         (org-entry-get-multivalued-property
                          (plist-get (car heading) :begin)
                          (symbol-name elm))))
                   (root (funcall fn 'org-generate-root))
                   (vars (funcall fn 'org-generate-variable))
                   (beforehooks (funcall fn 'org-generate-before-hook))
                   (afterhooks  (funcall fn 'org-generate-after-hook)))
              (setq root (expand-file-name
                          (or org-generate-root
                              (car root)
                              (read-file-name "Generate root: " dir))))
              (unless (file-directory-p root)
                (error "%s is not directory" root))
              (let ((default-directory root)
                    (org-generate-mustache-info
                     (or org-generate-mustache-info
                         (org-generate--hash-table-from-alist
                          (mapcar (lambda (elm)
                                    (cons elm (read-string (format "%s: " elm))))
                                  vars)))))
                (when beforehooks
                  (dolist (elm beforehooks)
                    (funcall (intern elm))))

                (org-generate-1 t heading)

                (when afterhooks
                  (dolist (elm afterhooks)
                    (funcall (intern elm))))
                (when (called-interactively-p 'interactive)
                  (dired root))))
          (when export-buffer
            (kill-buffer export-buffer)))))))

(provide 'org-generate)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; org-generate.el ends here
