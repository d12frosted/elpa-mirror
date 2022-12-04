;;; isearch-dabbrev.el --- Use dabbrev in isearch

;; Copyright (C) 2014 by Dewdrops

;; Author: Dewdrops <v_v_4474@126.com>
;; URL: https://github.com/Dewdrops/isearch-dabbrev
;; Package-Version: 20141224.622
;; Package-Commit: 1efe7abba4923015cbc2462395deaec5446a9cc8
;; Version: 0.1
;; Keywords: dabbrev isearch
;; Package-Requires: ((cl-lib "0.5"))

;; This file is NOT part of GNU Emacs.

;;; License:
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Use dabbrev-expand within isearch-mode
;;
;; Installation:
;;
;; put isearch-dabbrev.el somewhere in your load-path and add these
;; lines to your .emacs:
;; (eval-after-load "isearch"
;;   '(progn
;;      (require 'isearch-dabbrev)
;;      (define-key isearch-mode-map (kbd "<tab>") 'isearch-dabbrev-expand)))
;; Then you can use TAB to do dabbrev-expand work in isearch-mode

;;; Code:

(require 'dabbrev)
(require 'cl-lib)

(defvar isearch-dabbrev/expansions-list nil)

(defvar isearch-dabbrev/expansions-list-idx 0)


(defun isearch-dabbrev/unquote-regexp (string)
  "Replace quoted instances of regex special character with its unquoted form."
  (let ((inverted "")
        (index 0)
        current-char
        next-char)
    (cl-loop until (equal index (length string)) do
             (setq current-char (elt string index))
             (setq next-char
                   (unless (equal (1+ index) (length string))
                     (elt string (1+ index))))
             (if (and (equal current-char ?\\)
                      (member next-char
                              '(?. ?\\ ?+ ?* ?? ?^ ?$ ?\[ ?\])))
                 (progn
                   (setq inverted (concat inverted (list next-char)))
                   (cl-incf index 2))
               (setq inverted (concat inverted (list current-char)))
               (cl-incf index)))
    inverted))

;;;###autoload
(defun isearch-dabbrev-expand ()
  "Dabbrev-expand in isearch-mode"
  (interactive)
  (let ((dabbrev-string (if isearch-regexp
                            (isearch-dabbrev/unquote-regexp isearch-string)
                          isearch-string))
        istring)
    (if (eq last-command this-command)
        (progn
          (setq isearch-dabbrev/expansions-list-idx
                (if (= isearch-dabbrev/expansions-list-idx
                       (1- (length isearch-dabbrev/expansions-list)))
                    0
                  (1+ isearch-dabbrev/expansions-list-idx))))
      (let (expansion expansions-before expansions-after
                      (dabbrev-check-all-buffers nil)
                      (dabbrev-check-other-buffers nil))
        (setq isearch-dabbrev/expansions-list nil)
        (setq isearch-dabbrev/expansions-list-idx 0)
        (save-excursion
          (let ((point-start
                 (ignore-errors
                   (if isearch-forward
                       (backward-sexp)
                     (forward-sexp))
                   (point))))
            
            (dabbrev--reset-global-variables)
            (while (setq expansion
                         (dabbrev--find-expansion dabbrev-string
                                                  -1
                                                  isearch-case-fold-search))
              (setq expansions-after (cons expansion expansions-after)))
            (goto-char point-start)
            (dabbrev--reset-global-variables)
            (while (setq expansion
                         (dabbrev--find-expansion dabbrev-string
                                                  1
                                                  isearch-case-fold-search))
              (setq expansions-before (cons expansion expansions-before)))))
        (setq isearch-dabbrev/expansions-list
              (if isearch-forward
                  (append (reverse expansions-after) expansions-before)
                (append (reverse expansions-before) expansions-after)))))

    (when (not isearch-dabbrev/expansions-list)
      (error "No dynamic expansion for \"%s\" found in this-buffer"
             isearch-string))

    (setq istring (nth isearch-dabbrev/expansions-list-idx
                       isearch-dabbrev/expansions-list))
    (if (and isearch-case-fold-search
             (eq 'not-yanks search-upper-case))
        (setq istring (downcase istring)))
    (if isearch-regexp (setq istring (regexp-quote istring)))
    (setq isearch-yank-flag t)

    (setq isearch-string istring
          isearch-message (mapconcat 'isearch-text-char-description istring ""))
    (isearch-search-and-update)))


(provide 'isearch-dabbrev)
;;; isearch-dabbrev.el ends here
