;;; requirejs-mode.el --- Improved AMD module management

;; Copyright (C) 2013 Marc-Olivier Ricard

;; Author: Marc-Olivier Ricard <marco.ricard@gmail.com>
;; Version: 1.1
;; Package-Version: 20130215.2104
;; Package-Commit: 011849043098b6c4f27571625ae19071b53b8824
;; Keywords: Javascript, AMD, RequireJs

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
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This mode helps to manage dependencies in an AMD javascript module.
;; See https://github.com/ricardmo/requirejs-mode for full documentation.

;;; Code:

(defvar require-mode-map (make-sparse-keymap)
  "require-mode keymap")

(define-key require-mode-map
  (kbd "C-c rf") 'require-import-file)

(define-key require-mode-map
  (kbd "C-c ra") 'require-import-add)

(define-key require-mode-map
  (kbd "C-c rc") 'require-create)

(define-minor-mode requirejs-mode
  "RequireJS mode

This mode is intended to provide easier management of
dependencies in an AMD style javascript module."

  nil " requireJS" require-mode-map)

(defun require-goto-headers ()
  (search-backward-regexp "^define[\s]*(+[\s]*" nil t))

(defun require-goto-function-declaration ()
  (search-forward-regexp "[\s]) {" nil t))

(defun require-goto-headers-declaration ()
  (require-goto-headers)
  (require-goto-function-declaration)
  (backward-char 4))

(defun require-goto-dependency-insert-point ()
  (require-goto-headers)
  (search-forward-regexp "]," nil t)
  (backward-char 2)
)

(defun is-first-import ()
  (looking-back "[\[]" 2))

(defun camelize (s)
      "Convert dash-based string S to CamelCase string."
      (mapconcat 'identity (mapcar
                            '(lambda (word) (capitalize (downcase word)))
                            (split-string s "-")) ""))

(defun un-camelcase-string (s &optional sep start)
  (let ((case-fold-search nil))
    (while (string-match "[A-Z]" s (or start 1))
      (setq s (replace-match (concat (or sep "-") 
                                     (downcase (match-string 0 s))) 
                             t nil s)))
    (downcase s)))

(defun require-create ()
  "initializes an empty requireJS mnodule"
  (interactive)
  (insert "define (
    [],    
    function ( ) {
        
    }
);")
  (backward-char 9))

(defun insert-module (import)
  "Insert import into module header"
  (interactive)

  (save-excursion 
    (if (not (require-goto-headers))
        (require-create))
    (require-goto-dependency-insert-point)
    (let ((is-first (is-first-import)))

      (insert (concat (if is-first "'" ",'") (car import) "'\n    "))
      (require-goto-headers-declaration)
      (insert (concat (if is-first " " ", ") (cdr import))))))


;; Very basic default list of modules
(setq require-modules 
      '(("jquery" . "$")
        ("underscore" . "_")
        ("backbone" . "Backbone")))

(defun require-import (s)
  "add import to require header"
  (interactive)
  (message (concat "Adding " s " to dependencies."))
  (let ((import (substring s
                           (or (string-match "collections[/.]*[/]" s)
                               (string-match "models[/.]*[/]" s)
                               (string-match "views[/.]*[/]" s)
                               (string-match "templates[/.]*[/]" s)
                               (string-match "nls[/.]*[/]" s)
                               (string-match "[a-z0-9-]+[.]+[a-z]+$" s)
                               0) 
                           (string-match ".js$" s)))
        (is-template (string-match "templates" s))
        (is-view (string-match "views" s)))

    (if is-template (setq import (concat "text!" import)))

    (let ((key import)
          (value (concat
                  (camelize (substring import
                                       (string-match "[a-z0-9-]+[.]*[a-z]*$" import) 
                                       (string-match "[.]" import)))

                  (if (and is-template (not (string-match "template.[a-z]+$" import)))
                      "Template")
                  (if (and is-view (not (string-match "view$" import)))
                      "View"))))
      (insert-module (or (assoc key require-modules)
                         (assoc key (push (cons key value) require-modules)))))))

;; Try to use ido if available but don't whine if not.
(when (require 'ido nil 'noerror)
  (setq ido-present t))

(defun get-file-name (prompt)
  (if ido-present 
      (ido-read-file-name prompt)
    (read-file-name prompt)))

(defun pick-from-list (prompt alist)
  (if ido-present
      (ido-completing-read prompt alist)
    (completing-read prompt alist)))

(defun require-import-file ()
  "add import to require header from ido-file-chooser"
  (interactive)
  (require-import (get-file-name "Import RequireJS module: ")))

(defun require-import-add ()
  "add import to require header from prompted name"
  (interactive)
  (insert-module (assoc (pick-from-list "Add RequireJS module: " require-modules) require-modules)))

(provide 'requirejs-mode)

;;; requirejs-mode.el ends here
