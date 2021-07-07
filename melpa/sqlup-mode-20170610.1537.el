;;; sqlup-mode.el --- Upcase SQL words for you

;; Copyright (C) 2014 Aldric Giacomoni

;; Author: Aldric Giacomoni <trevoke@gmail.com>
;; URL: https://github.com/trevoke/sqlup-mode.el
;; Package-Version: 20170610.1537
;; Package-Commit: 3f9df9c88d6a7f9b1ae907e401cad8d3d7d63bbf
;; Created: Jun 25 2014
;; Version: 0.8.0
;; Keywords: sql, tools, redis, upcase

;;; License:

;; This file is not part of GNU Emacs

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

;; `M-x sqlup-mode` and just type.
;; This mode supports the various built-in SQL modes as well as redis-mode.
;; The capitalization is triggered when you press the following keys:
;; * SPC
;; * RET
;; * ,
;; * ;
;; * (
;; * '
;;
;; This package also provides a function to capitalize SQL keywords inside a
;; region as well as the whole bufer - always available, no need to activate 
;; the minor mode to use it:
;;
;; M-x sqlup-capitalize-keywords-in-region
;; M-x sqlup-capitalize-keywords-in-buffer
;;
;; It is not bound to a keybinding. Here is an example of how you could do it:
;;
;; (global-set-key (kbd "C-c u") 'sqlup-capitalize-keywords-in-region)
;;
;; Here follows an example setup to activate `sqlup-mode` automatically:
;;
;; (add-hook 'sql-mode-hook 'sqlup-mode)
;; (add-hook 'sql-interactive-mode-hook 'sqlup-mode)
;; (add-hook 'redis-mode-hook 'sqlup-mode)
;;
;; Sqlup can be configured to ignore certain keywords by adding them to the list
;; `sqlup-blacklist`. For example if you use `name` as a column name it would be
;; annoying to have it upcased so you can prevent this by adding
;;
;; (add-to-list 'sqlup-blacklist "name")
;;
;; to your config (or do the equivalent through the `M-x customize` interface).



;;; Code:

(require 'cl-lib)
(require 'sql)


(defcustom sqlup-blacklist
  '()
  "List of words which should never be upcased

The words must match the whole symbol. They are interpreted as plain
strings not regexes."
  :type '(repeat string)
  :group 'sqlup)


(defconst sqlup-trigger-characters
  (mapcar 'string-to-char '(";"
                            " "
                            "("
                            ","
                            "\n"
                            "'"))
  "When the user types one of these characters,
this mode's logic will be evaluated.")

(defconst sqlup-eval-keywords
  '((postgres "EXECUTE" "format("))
  "List of keywords introducing eval strings, organised by dialect.")

(defvar sqlup-local-keywords nil
  "Buffer-local variable holding regexps to identify keywords.")

(defvar sqlup-work-buffer nil
  "Buffer-local variable keeping track of the name of the buffer where sqlup
figures out what is and isn't a keyword.")


;;;###autoload
(define-minor-mode sqlup-mode
  "Capitalizes SQL keywords for you."
  :lighter " SUP"
  (if sqlup-mode
      (sqlup-enable-keyword-capitalization)
    (sqlup-disable-keyword-capitalization)))

(defun sqlup-enable-keyword-capitalization ()
  "Add buffer-local hook to handle this mode's logic"
  (set (make-local-variable 'sqlup-work-buffer) nil)
  (set (make-local-variable 'sqlup-local-keywords) nil)
  (add-hook 'post-self-insert-hook 'sqlup-capitalize-as-you-type nil t))

(defun sqlup-disable-keyword-capitalization ()
  "Remove buffer-local hook to handle this mode's logic"
  (if sqlup-work-buffer (kill-buffer sqlup-work-buffer))
  (remove-hook 'post-self-insert-hook 'sqlup-capitalize-as-you-type t))

(defun sqlup-capitalize-as-you-type ()
  "If the user typed a trigger key, check if we should capitalize
the previous word."
  (if (member last-command-event sqlup-trigger-characters)
      (save-excursion (sqlup-maybe-capitalize-symbol -1))))

(defun sqlup-maybe-capitalize-symbol (direction)
  "DIRECTION is either 1 for forward or -1 for backward"
  (with-syntax-table (make-syntax-table sql-mode-syntax-table)
    ;; Give \ symbol syntax so that it is included when we get a symbol. This is
    ;; needed so that \c in postgres is not treated as the keyword C.
    (modify-syntax-entry ?\\ "_")
    (forward-symbol direction)
    (sqlup-work-on-symbol (thing-at-point 'symbol)
                          (bounds-of-thing-at-point 'symbol))))

(defun sqlup-work-on-symbol (symbol symbol-boundaries)
  (if (and symbol
           (sqlup-keyword-p (downcase symbol))
           (not (sqlup-blacklisted-p (downcase symbol)))
           (sqlup-capitalizable-p (point)))
      (upcase-region (car symbol-boundaries)
                     (cdr symbol-boundaries))))

(defun sqlup-keyword-p (word)
  (cl-some (lambda (reg) (string-match-p (concat "^" reg "$") word))
           (sqlup-keywords-regexps)))

(defun sqlup-blacklisted-p (word)
  (cl-some (lambda (blacklisted) (string-match-p (concat "^" (regexp-quote blacklisted) "$") word))
           sqlup-blacklist))

(defun sqlup-capitalizable-p (point-location)
  (let ((dialect (sqlup-valid-sql-product)))
    (with-current-buffer (sqlup-work-buffer)
      (goto-char point-location)
      (and (not (sqlup-comment-p))
           (not (and (not (sqlup-in-eval-string-p dialect))
                     (sqlup-string-p)))))))

(defun sqlup-comment-p ()
  (and (nth 4 (syntax-ppss)) t))

(defun sqlup-in-eval-string-p (dialect)
  "Return t if we are in an eval string."
  (save-excursion
    (if (sqlup-string-p)
        (progn
          (goto-char (nth 8 (syntax-ppss)))
          (sqlup-match-eval-keyword-p dialect)))))

(defun sqlup-match-eval-keyword-p (dialect)
  "Return t if the code just before point ends with an eval keyword valid in
the given DIALECT of SQL."
  (cl-some (lambda (kw) (looking-back (concat kw "\\s-*") 0))
           (cdr (assoc dialect sqlup-eval-keywords))))

(defun sqlup-string-p ()
  (and (nth 3 (syntax-ppss)) t))

;;;###autoload
(defun sqlup-capitalize-keywords-in-region (start-pos end-pos)
  "Call this function on a region to capitalize the SQL keywords therein."
  (interactive "r")
  (save-excursion
    (goto-char start-pos)
    (while (< (point) end-pos)
      (sqlup-maybe-capitalize-symbol 1))))

(defun sqlup-capitalize-keywords-in-buffer ()
  "Call this function in a buffer to capitalize the SQL keywords therein."
  (interactive)
  (save-excursion
    (sqlup-capitalize-keywords-in-region (point-min) (point-max))))

(defun sqlup-keywords-regexps ()
  (or sqlup-local-keywords
      (set (make-local-variable 'sqlup-local-keywords)
           (sqlup-find-correct-keywords))))

(defun sqlup-find-correct-keywords ()
  "Depending on the major mode (redis-mode or sql-mode), find the
correct keywords. If not, create a (hopefully sane) default based on
ANSI SQL keywords."
  (cond ((derived-mode-p 'redis-mode) (mapcar 'downcase (sqlup-get-redis-keywords)))
        ((sqlup-within-sql-buffer-p) (mapcar 'car sql-mode-font-lock-keywords))
        (t (mapcar 'car (sql-add-product-keywords
                         (sqlup-valid-sql-product) '())))))

(defun sqlup-get-redis-keywords ()
  (if (boundp 'redis-keywords)
      redis-keywords
    '()))

(defun sqlup-valid-sql-product ()
  (or (and (boundp 'sql-product)
           sql-product)
      'ansi))

(defun sqlup-within-sql-buffer-p ()
  (and (boundp 'sql-mode-font-lock-keywords) sql-mode-font-lock-keywords))

(defun sqlup-work-buffer ()
  "Determines in which buffer sqlup will look to find what it needs and returns it. It can return the current buffer or create and return an indirect buffer based on current buffer and set its major mode to sql-mode."
  (cond ((sqlup-within-sql-buffer-p) (current-buffer))
        (t (sqlup-indirect-buffer))))

(defun sqlup-indirect-buffer ()
  (or sqlup-work-buffer
      (set (make-local-variable 'sqlup-work-buffer)
           (with-current-buffer (clone-indirect-buffer
                                 (generate-new-buffer-name
                                  (format "*sqlup-%s*" (buffer-name)))
                                 nil)
             (sql-mode)
             (current-buffer)))))

(defadvice font-lock-mode (around sqlup-ignore-font-lock-on-indirect-buffer activate)
  "Do not turn on jit-lock-mode on indirect buffers at all.
Because we're using indirect buffers, the font face gets shared and when we
change the major mode in the indirect buffer it messes with the font in the
base buffer (the one the user cares about). This tells emacs to not enable
font locking in an indirect buffer for which the primary buffer has
sqlup-mode enabled."
  (unless (and (buffer-base-buffer)
               (with-current-buffer (buffer-base-buffer)
                 sqlup-mode))
    ad-do-it))

(defadvice sql-set-product (after sqlup-invalidate-sqlup-keyword-cache activate)
  "Advice sql-set-product, to invalidate sqlup's keyword cache after changing
the sql product. We need to advice sql-set-product since sql-mode does not
provide any hook that runs after changing the product"
  (setq sqlup-local-keywords nil))

(defadvice comint-send-input (before sqlup-capitalize-sent-input activate)
  "Capitalize any sql keywords before point when sending input in
  interactive sql"
  (when sqlup-mode
    (save-excursion (sqlup-maybe-capitalize-symbol -1))))

(provide 'sqlup-mode)
;;; sqlup-mode.el ends here
