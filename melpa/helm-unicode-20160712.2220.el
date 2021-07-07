;;; helm-unicode.el --- Helm command for unicode characters. -*- lexical-binding: t -*-

;; Copyright © 2015 Emanuel Evans

;; Version: 0.0.1
;; Package-Version: 20160712.2220
;; Package-Commit: 3b2a61dd9d4c9e85946567e07d8e70e276c5136b
;; Package-Requires: ((helm "1.6") (emacs "24.4"))

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
  "Internal variable for unicode characters.")

(defun helm-source-unicode ()
  "Builds the helm Unicode source"
  (unless helm-unicode-names
    (setq helm-unicode-names
          (sort (mapcar (lambda (char-pair)
                          (format "%s %c"
                                  (car char-pair)
                                  (cdr char-pair)))
                        (ucs-names))
                #'string-lessp)))
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
  (helm :sources (helm-source-unicode)
        :buffer "*helm-unicode-search*"))

(provide 'helm-unicode)

;;; helm-unicode.el ends here
