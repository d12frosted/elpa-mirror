;;; helm-prosjekt.el --- Helm integration for prosjekt.

;; Copyright (C) 2012 Sohail Somani
;; Author: Sohail Somani <sohail@taggedtype.net>
;; Version: 0.1
;; Package-Version: 20140129.717
;; Package-Commit: f94f970c2d375e0973b66ba99b29c7aa42fd550f
;; URL: https://github.com/abingham/prosjekt
;; Package-Requires: ((prosjekt "0.3") (helm "1.5.9"))

;; Originally based on anything-prosjekt by Austin Bingham

;; This file is NOT part of GNU Emacs.

;;; Commentary:
;;
;; Allows opening and closing prosjekt projects through prosjekt, as
;; well as selection of files within a project.
;;
;; To activate, add helm-prosjekt.el to your load path and
;;
;;   (require 'helm-prosjekt)
;;
;; to your .emacs. You can then use the interactive function
;; `helm-prosjekt`
;;
;; Helm: https://github.com/emacs-helm/helm
;;
;; License:
;;
;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Code: (copied from anything-prosjekt.el)

(require 'prosjekt)
(require 'helm-files)

;; TODO: Share this
(defun prosjekt-temp-file-name ()
  (mapcar
   (lambda (item)
     (expand-file-name (concat prosjekt-proj-dir item)))
   (prosjekt-proj-files)))

(defvar helm-c-source-prosjekt-files
  '((name . "Files in prosjekt")
    (init . helm-c-source-prosjekt-files-init)
    ;(candidates-in-buffer)
    ; Grab candidates from all project files.
    (candidates . prosjekt-temp-file-name)
    (type . file)
    ; TODO: Understand this next one better.
    (real-to-display . (lambda (real)
                         (file-relative-name real prosjekt-proj-dir)))
    )
  "Search for files in the current prosjekt.")

(defun helm-c-source-prosjekt-files-init ()
  "Build `helm-candidate-buffer' of prosjekt files."
  (with-current-buffer (helm-candidate-buffer 'local)
    (mapcar
     (lambda (item)
       (insert (format "%s\n" item)))
     (prosjekt-proj-files))))

(defvar helm-c-source-prosjekt-projects
  '((name . "Prosjekt projects")
    (candidates . (lambda ()
                    (prosjekt-cfg-project-list (prosjekt-cfg-load))))
    (action ("Open Recent Project" . (lambda (cand)
                                (prosjekt-open cand)))
            ("Close project" . (lambda (cand)
                                 (prosjekt-close)))))
  "Open or close prosjekt projects.")

(defun helm-prosjekt ()
  (interactive)
  (helm-other-buffer '(helm-c-source-prosjekt-projects
                       helm-c-source-prosjekt-files)
                     "*helm-prosjekt buffer*"))

(provide 'helm-prosjekt)

;;; helm-prosjekt.el ends here
