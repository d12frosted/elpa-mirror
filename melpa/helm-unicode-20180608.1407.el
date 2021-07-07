;;; helm-unicode.el --- Helm command for unicode characters. -*- lexical-binding: t -*-

;; Copyright © 2015 Emanuel Evans

;; Version: 0.0.4
;; Package-Version: 20180608.1407
;; Package-Commit: fbeb0c5e741a6f462520884b744d43a9acbe1d34
;; Package-Requires: ((helm "1.9.8") (emacs "24.4"))

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
;; A helm command for looking up unicode characters by name 😉.

;;; Code:

(require 'helm)
(require 'helm-utils)

(defvar helm-unicode-names nil
  "Internal cache variable for unicode characters.  Should not be changed by the user.")

(defun helm-unicode-format-char-pair (char-pair)
  "Formats a char pair for helm unicode search."
             (let ((name (car char-pair))
                   (symbol (cdr char-pair)))
                   (format "%s %c" name symbol)))

(defun helm-unicode-build-candidates ()
  "Builds the candidate list."
  (let ((unames (if (hash-table-p (ucs-names))
                    (mapcar (lambda (elem) `(,elem . ,(gethash elem (ucs-names)))) (hash-table-keys (ucs-names)))
                  (ucs-names))))
    (sort
     (mapcar 'helm-unicode-format-char-pair unames)
     #'string-lessp)))

(defun helm-unicode-source ()
  "Builds the helm Unicode source.  Initialize the lookup cache if necessary."

  (unless helm-unicode-names
    (setq helm-unicode-names (helm-unicode-build-candidates)))

  (helm-build-sync-source "unicode-characters"
    :candidates helm-unicode-names
    :filtered-candidate-transformer (lambda (candidates _source) (sort candidates #'helm-generic-sort-fn))
    :action '(("Insert Character" . helm-unicode-insert-char))))

(defun helm-unicode-insert-char (candidate)
  "Insert CANDIDATE into the main buffer."
  (insert (substring candidate -1)))

;;;###autoload
(defun helm-unicode (arg)
  "Precofigured `helm' for looking up unicode characters by name.

With prefix ARG, reinitialize the cache."
  (interactive "P")
  (when arg (setq helm-unicode-names nil))
  (helm :sources (helm-unicode-source)
        :buffer "*helm-unicode-search*"))

(provide 'helm-unicode)

;;; helm-unicode.el ends here
