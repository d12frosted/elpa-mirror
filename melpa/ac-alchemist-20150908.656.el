;;; ac-alchemist.el --- auto-complete source for alchemist -*- lexical-binding: t; -*-

;; Copyright (C) 2015 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-ac-alchemist
;; Package-Version: 20150908.656
;; Package-Commit: b1891c3d41aed83f61d78a609ea97be5cc2758d9
;; Version: 0.01
;; Package-Requires: ((auto-complete "1.5.0") (alchemist "1.5.0") (cl-lib "0.5"))

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

;;; Code:

(require 'auto-complete)
(require 'alchemist)
(require 'cl-lib)

(defgroup ac-alchemist nil
  "auto complete source of alchemist"
  :group 'auto-complete)

(defvar ac-alchemist--output-cache nil)
(defvar ac-alchemist--candidate-cache nil)
(defvar ac-alchemist--prefix nil)
(defvar ac-alchemist--document nil)

(defun ac-alchemist--candidates ()
  (cl-loop for cand in ac-alchemist--candidate-cache
           if (string-match "\\(\\S-+\\)\\(/[0-9]+\\)" cand)
           collect
           (popup-make-item (match-string-no-properties 1 cand)
                            :symbol (match-string-no-properties 2 cand))
           else
           collect (popup-make-item cand :symbol "  ")))

(defun ac-alchemist--merge-candidates (candidates-list)
  (with-temp-buffer
    (cl-loop for candidates in candidates-list
             do
             (insert candidates))
    (goto-char (point-min))
    (let ((results nil))
      (while (not (looking-at-p "^END-OF"))
        (push (buffer-substring-no-properties
               (line-beginning-position) (line-end-position)) results)
        (forward-line +1))
      results)))

(defun ac-alchemist--complete-filter (_process output)
  (setq ac-alchemist--output-cache (cons output ac-alchemist--output-cache))
  (when (alchemist-server-contains-end-marker-p output)
    (let ((candidates (ac-alchemist--merge-candidates ac-alchemist--output-cache)))
      (setq ac-alchemist--output-cache nil)
      (setq ac-alchemist--candidate-cache candidates))))

(defun ac-alchemist--do-complete (process output)
  (ac-alchemist--complete-filter process output)
  (ac-start))

(defun ac-alchemist--get-prefixed-string (end)
  (save-excursion
    (goto-char end)
    (skip-chars-backward "[a-zA-Z._:]")
    (buffer-substring-no-properties (point) end)))

(defun ac-alchemist--complete-request ()
  (let ((prefix (ac-alchemist--get-prefixed-string (point))))
    (setq ac-alchemist--prefix prefix)
    (alchemist-server-complete-candidates
     (format "{ \"%s\", [ context: [], imports: [], aliases: [] ] }" prefix)
     'ac-alchemist--complete-filter)))

(defun alchemist-company-doc-buffer-filter (_process output)
  (when (alchemist-server-contains-end-marker-p output)
    (let ((docstr (ansi-color-filter-apply
                   (alchemist-server-prepare-filter-output (list output)))))
      (setq ac-alchemist--document docstr))))

(defun ac-alchemist--document-query (candidate)
  (if (not (string-match-p "\\." ac-alchemist--prefix))
      candidate
    (let ((arity (or (get-text-property 0 'symbol candidate) "")))
      (let ((prefix (ac-alchemist--get-prefixed-string ac-point)))
        (concat prefix candidate arity)))))

(defun ac-alchemist--show-document (candidate)
  (setq ac-alchemist--document nil)
  (let ((query (alchemist-help--prepare-search-expr
                (ac-alchemist--document-query candidate))))
    (setq alchemist-company-doc-lookup-done nil)
    (alchemist-server-help
     (alchemist-help--server-arguments query)
     'alchemist-company-doc-buffer-filter)
    (sit-for 0.1) ;; XXX
    ac-alchemist--document))

(defun ac-alchemist--prefix ()
  (when (looking-back "[a-zA-Z_.:]+" (line-beginning-position))
    (save-excursion
      (skip-chars-backward "^ \t\n\r.")
      (point))))

(ac-define-source alchemist
  '((init . ac-alchemist--complete-request)
    (prefix . ac-alchemist--prefix)
    (candidates . ac-alchemist--candidates)
    (document . ac-alchemist--show-document)
    (requires . -1)))

;;;###autoload
(defun ac-alchemist-setup ()
  (interactive)
  (auto-complete-mode +1)
  (add-to-list 'ac-sources 'ac-source-alchemist))

(provide 'ac-alchemist)

;;; ac-alchemist.el ends here
