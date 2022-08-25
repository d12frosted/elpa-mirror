;;; highlight-unique-symbol.el --- highlight symbols which not appear in the repository

;; Copyright (C) 2013 hitode909

;; Author: hitode909 <hitode909@gmail.com>
;; Version: 0.1
;; Package-Version: 20130612.542
;; Package-Commit: d760015b4a5ce31d6da5a30890b599a8e1312be5
;; URL: https://github.com/hitode909/emacs-highlight-unique-symbol
;; Package-Requires: ((deferred "0.3.2"))

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
;; (require 'highlight-unique-symbol)  ;; Not necessary if using ELPA package
;; (highlight-unique-symbol t)
;;
;; You can configure these settings with `M-x customize-group RET highlight-unique-symbol RET`.
;;
;; `highlight-unique-symbol:interval`
;; Interval to check symbol at cursor.
;;
;; `highlight-unique-symbol:face`
;; Face of unique symbols.

;;; Code:

(require 'cl)
(require 'deferred)
(require 'vc)
(require 'vc-git)

(defgroup highlight-unique-symbol nil
  "Typo Finder"
  :group 'tools
  )



(defcustom highlight-unique-symbol:interval 0.1
  "Interval to check symbol's appearance count"
  :group 'highlight-unique-symbol
  :type 'float)

(defface highlight-unique-symbol:face
    '((t (:foreground "red")))
  "*Face used for unique symbol."
  :group 'highlight-unique-symbol)

(defvar highlight-unique-symbol:timer
  nil
  "*Timer"
  )

(defun highlight-unique-symbol:chomp (str)
  (replace-regexp-in-string "[\n\r]+$" "" str))

(defun highlight-unique-symbol:git-project-p ()
  (not (string= (highlight-unique-symbol:git-root-directory) "")))

(defun highlight-unique-symbol:git-root-directory ()
  (or (vc-file-getprop default-directory 'highlight-unique-symbol-git-root-directory)
      (vc-file-setprop default-directory 'highlight-unique-symbol-git-root-directory
                       (or (vc-git-root default-directory) ""))))

(defun highlight-unique-symbol:check ()
  (interactive)
  (lexical-let*
      (
       (current-symbol (thing-at-point 'symbol))
       (current-overlay (and current-symbol (highlight-unique-symbol:overlay)))
       )
    (when (and
           current-symbol
           current-overlay
           (highlight-unique-symbol:git-project-p)
           (highlight-unique-symbol:is-overlay-changed  current-overlay current-symbol)
           (not (eq (face-at-point) 'font-lock-comment-face))
           (not (eq (face-at-point) 'font-lock-doc-face))
           )
      (overlay-put current-overlay 'highlight-unique-symbol:symbol current-symbol)
      (deferred:$
        (deferred:process-shell (format
                                 ;; -I Don't match the pattern in binary files
                                 "git --no-pager grep --cached --word-regexp -I --fixed-strings --quiet -e %s -- %s"
                                 (shell-quote-argument current-symbol)
                                 (highlight-unique-symbol:git-root-directory)
                                 ))
        ;; success when found
        (deferred:nextc it
          (lambda (res)
            (highlight-unique-symbol:ok current-overlay)))
        ;; error when not found
        (deferred:error it
          (lambda (res)
            (highlight-unique-symbol:warn current-overlay)))
        ))))

(defun highlight-unique-symbol:is-overlay-changed (overlay symbol-at-point)
  (not (string= (overlay-get overlay 'highlight-unique-symbol:symbol) symbol-at-point)))

(defun highlight-unique-symbol:warn (overlay)
  (overlay-put overlay 'face 'highlight-unique-symbol:face))

(defun highlight-unique-symbol:ok (overlay)
  (overlay-put overlay 'face nil))

(defun highlight-unique-symbol:overlay ()
  (save-excursion
    (let*
        (
         (begin (beginning-of-thing 'symbol))
         (end (end-of-thing 'symbol))
         (overlays (overlays-in begin end))
         (overlay (find-if
                   '(lambda (ovl) (overlay-get ovl 'highlight-unique-symbol:is-highlight-overlay))
                   overlays))
         )
      (if overlay
          overlay
        (highlight-unique-symbol:create-overlay)))))

(defun highlight-unique-symbol:create-overlay ()
  (save-excursion
    (let*
        (
         (begin (beginning-of-thing 'symbol))
         (end (end-of-thing 'symbol))
         (overlay (make-overlay begin end))
         (on-modify '((lambda (overlay after-p begin end &optional length)
                      (delete-overlay overlay))))
         )
      (overlay-put overlay 'highlight-unique-symbol:is-highlight-overlay 1)
      (overlay-put overlay 'modification-hooks on-modify)
      (overlay-put overlay 'insert-in-front-hooks on-modify)
      (overlay-put overlay 'insert-behind-hooks on-modify)
      overlay)))

;;;###autoload
(defun highlight-unique-symbol (start)
  "Start highlighting unique symbols"
  (when (and start highlight-unique-symbol:timer) (highlight-unique-symbol nil))
  (if start
      (setq highlight-unique-symbol:timer (run-with-idle-timer
                                           highlight-unique-symbol:interval
                                           t
                                           'highlight-unique-symbol:check))
  (when highlight-unique-symbol:timer
    (cancel-timer highlight-unique-symbol:timer)
    (setq highlight-unique-symbol:timer nil)))
  )

(provide 'highlight-unique-symbol)

;; Local Variables:
;; byte-compile-warnings: (not cl-functions)
;; End:

;;; highlight-unique-symbol.el ends here
