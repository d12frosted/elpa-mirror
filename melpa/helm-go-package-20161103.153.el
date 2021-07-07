;;; helm-go-package.el --- helm sources for Go programming language's package

;; Copyright (C) 2013-2016 Yasuyuki Oka

;; Author: Yasuyuki Oka <yasuyk@gmail.com>
;; Version: 0.3.0-snapshot
;; Package-Version: 20161103.153
;; Package-Commit: e42c563936c205ceedb930a687c11b4bb56447bc
;; URL: https://github.com/yasuyk/helm-go-package
;; Package-Requires: ((emacs "24.4") (helm-core "2.2.1") (go-mode "1.4.0") (deferred "0.4.0"))

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

;; Add the following to your Emacs init file:
;;
;; (autoload 'helm-go-package "helm-go-package") ;; Not necessary if using ELPA package
;; (eval-after-load 'go-mode
;;   '(substitute-key-definition 'go-import-add 'helm-go-package go-mode-map))

;; That's all.

;;; Code:

(require 'helm)
(require 'go-mode)
(require 'deferred)


(defgroup helm-go-package nil
  "Go package related Applications and libraries for Helm."
  :prefix "helm-go-package-"
  :group 'helm)

(defcustom helm-go-package-godoc-browse-url-function 'browse-url
  "Function to display package documentation on godoc.org.
It is `browse-url' by default."
  :group 'helm-go-package
  :type 'symbol)

(defcustom helm-go-package-actions
  (helm-make-actions
   "Add a new import"  (lambda (candidate) (go-import-add nil candidate))
   "Add a new import as"  (lambda (candidate) (go-import-add t candidate))
   "Show documentation" 'godoc
   "Display GoDoc" 'helm-go-package--godoc-browse-url
   "Visit package's directory" 'helm-go-package--visit-package-directory)
  "Actions for helm go package."
  :group 'helm-go-package
  :type '(alist :key-type string :value-type function))

(defcustom helm-go-package-search-on-godoc-actions
  (helm-make-actions
   "Download and install" 'helm-go-package--download-and-install
   "Display GoDoc" 'helm-go-package--godoc-browse-url)
  "Actions for helm go package search on godoc."
  :group 'helm-go-package
  :type '(alist :key-type string :value-type function))


;;; Faces
(defface helm-source-go-package-godoc-description
  (let ((str (face-foreground 'font-lock-string-face)))
    `((t (:foreground ,str))))
  "Face used for Godoc description."
  :group 'helm-go-package)



(defun helm-go-package--package-paths ()
  "Get paths of each packages."
  (let ((goroot (car (split-string (shell-command-to-string "go env GOROOT") "\n"))))
    (list
     (format "%s/src" goroot) ;; Go >= 1.4
     (format "%s/src"
             (car (split-string (shell-command-to-string "go env GOPATH") "\n")))
     (format "%s/src/pkg" goroot)))) ;; Go <= 1.3.3

(defun helm-go-package--locate-directory (name path)
  "Locate all occurrences of the sub-directory NAME in PATH.
Return a list of absolute directory names in reverse order, or nil if
not found."
  (let (found)
    (condition-case err
        (dolist (elt path)
          (setq elt (eval elt))
          (cond
           ((stringp elt)
            (and (file-accessible-directory-p
                  (setq elt (expand-file-name name elt)))
                 (push elt found)))
           (elt
            (setq found (helm-go-package--locate-directory
                         name (if (atom elt) (list elt) elt))))))
      (error
       (message "In helm-go-package--locate-directory: %s"
                (error-message-string err))))
    found))

(defconst helm-go-package-godoc-format
  "https://godoc.org/%s"
  "Format of godoc.org for browse URL.")

(defun helm-go-package--godoc-browse-url (candidate)
  "Ask a WWW browser to load CANDIDATE package of URL on `https://godoc.org'."
  (funcall helm-go-package-godoc-browse-url-function
           (format helm-go-package-godoc-format candidate)))

(defun helm-go-package--visit-package-directory (candidate)
  "Visit CANDIDATE package directory."
  (find-file (car (helm-go-package--locate-directory
                   candidate (helm-go-package--package-paths)))))

(defun helm-go-package--persistent-action (candidate)
  "Show godoc of CANDIDATE as persistent action."
  (with-selected-window (select-window (next-window))
    (godoc candidate)))

(defvar helm-go-package-source
  (helm-build-sync-source "Go local packages"
    :candidates 'go-packages
    :persistent-action 'helm-go-package--persistent-action
    :persistent-help  "Show documentation"
    :action 'helm-go-package-actions))

(defvar helm-go-package--search-on-godoc-command-alist
  (cond ((executable-find "curl")
         '(start-process  "curl" "-H" "Accept: text/plain"))
        ((executable-find "wget")
         '(start-process-shell-command "wget" "-O" "-" "--quiet" "--header='Accept: text/plain'"))
        (t '())))

(defun helm-go-package--godoc-url-with-query ()
  "Get url of godoc.org with query."
  (url-encode-url
   (format "https://godoc.org/\?\q=%s" helm-pattern)))

(defun helm-go-package--search-on-godoc-process ()
  "Run candidate-porcess."
  (apply (car helm-go-package--search-on-godoc-command-alist)
         "*helm-go-pacakge-search-on-godoc*" nil
         (append (cdr helm-go-package--search-on-godoc-command-alist)
                 (list (helm-go-package--godoc-url-with-query)))))

(defun helm-go-package--filtered-candidate-transformer (candidates source)
  "Filter CANDIDATES.  SOURCE is unused."
  (mapcar (lambda (e)
            (let* ((substrings (split-string e " " t))
                   (package (car substrings))
                   (description (mapconcat 'identity (cdr substrings) " "))
                   (display (format "%s %s" package
                                    (propertize description 'face
                                                'helm-source-go-package-godoc-description))))
              `(,display . ,package)))
            candidates))

(defun helm-go-package--download-and-install (candidate)
  "Download CANDIDATE and install it."
  (cl-block nil
    (unless (y-or-n-p "Download and install packages and dependencies? ")
      (cl-return)))
  (lexical-let ((package candidate))
    (deferred:$
      (deferred:process-shell (format "go get %s" package))
      (deferred:error it 'message)
      (deferred:next
        (lambda () (message (format "%s have been installed." package)))))))

(defclass helm-go-package-source-class-search-on-godoc (helm-source-async)
  ((candidates-process :initform 'helm-go-package--search-on-godoc-process)
   (requires-pattern :initform 3)
   (volatile :initform t)
   (filtered-candidate-transformer
    :initform 'helm-go-package--filtered-candidate-transformer)
   (action :initform 'helm-go-package-search-on-godoc-actions)
   (persistent-action :initform 'helm-go-package--godoc-browse-url)
   (persistent-help :initform "Browse GoDoc")))

(defvar helm-go-package-source-search-on-godoc
  (helm-make-source "search Go packages on Godoc"
      'helm-go-package-source-class-search-on-godoc))

;;;###autoload
(defun helm-go-package ()
  "Helm for Go programming language's package.

\"Go local packages\"
These actions are available.
* Add a new import
* Add a new import as
* Show documentation
* Display GoDoc
* Visit package's directory

This persistent action is available.
* Show documentation

\"search Go packages on Godoc\"
These actions are available.
* Download and install
* Display GoDoc"
  (interactive)
  (helm-other-buffer '(helm-go-package-source
                       helm-go-package-source-search-on-godoc)
                     "*helm go package*"))


(define-obsolete-variable-alias 'helm-source-go-package
  'helm-go-package-source "0.2.0")
(define-obsolete-variable-alias 'helm-source-go-package-search-on-godoc
  'helm-go-package-source-search-on-godoc "0.2.0")

(define-obsolete-function-alias
  'helm-source-go-package-search-on-godoc--filtered-candidate-transformer
  'helm-go-package--filtered-candidate-transformer "0.2.0")


(provide 'helm-go-package)

;; Local Variables:
;; coding: utf-8
;; End:

;;; helm-go-package.el ends here
