;;; replace-pairs.el --- Query-replace pairs of things -*- lexical-binding: t; -*-

;; Copyright (C) 2015 Free Software Foundation, Inc.

;; Author: David Shepherd <davidshepherd7@gmail.com>
;; Version: 0.1
;; Package-Version: 20160207.1251
;; Package-Commit: ef6f2719aab7714f6cb209fd3dd6d2e720681b3c
;; Package-Requires: ((emacs "24.4"))
;; Keywords:
;; URL: https://github.com/davidshepherd7/replace-pairs

;;; Commentary:

;; Query replace pairs of things with a single command.

;;; Code:

(require 'rx)


;; Data structures

(defvar replace-pairs--closings-table (make-hash-table :test #'equal)
  "Private hash table, only modify via `replace-pairs-add-pair'")

(defvar replace-pairs--openings-table (make-hash-table :test #'equal)
  "Private hash table, only modify via `replace-pairs-add-pair'")

(defun replace-pairs-add-pair (open close)
  "Add a new pair to be recognised by replace-pairs"
  (dolist (x (list open close (concat open close)))
    (puthash x close replace-pairs--closings-table)
    (puthash x open replace-pairs--openings-table)))

;; Add default pairs
(dolist (x '(("(" . ")")
             ("[" . "]")
             ("{" . "}")
             ("<" . ">")
             ))
  (replace-pairs-add-pair (car x) (cdr x)))


(defun replace-pairs--closing (item)
  (or (gethash item replace-pairs--closings-table)
      (error "Closing of %s not found" item)))


(defun replace-pairs--opening (opening)
  (or (gethash opening replace-pairs--openings-table)
      (error "Opening of %s not found" opening)))


(defun replace-pairs--choose-replacement (from-item _)
  (cond ((match-string 1) (replace-pairs--opening from-item))
        ((match-string 2) (replace-pairs--closing from-item))
        (t (error "No regex match data found, this should never happen"))))


;; Main functions

(defun replace-pairs--do-replace (from-item to-item query-flag delimited start end backward)
  (let ((regexp (rx-to-string `(or (group ,(replace-pairs--opening from-item))
                                   (group ,(replace-pairs--closing from-item)))))
        (replacement (cons #'replace-pairs--choose-replacement to-item)))
    (perform-replace regexp replacement query-flag t delimited nil nil start end backward)))


;;;###autoload
(defun query-replace-pairs (from-item to-item delimited start end backward)
  "Query-replace pairs of things

For example replace `(' and `)' with `[' and `]' respectively.

Interface is identical to `query-replace'."
  ;; Interactive form stolen directly from query-replace-regexp in emacs 24.4.
  (interactive
   (let ((common
          (query-replace-read-args
           (concat "Query replace pairs"
                   (if current-prefix-arg
                       (if (eq current-prefix-arg '-) " backward" " word")
                     "")
                   (if (and transient-mark-mode mark-active) " in region" ""))
           t)))
     (list (nth 0 common) (nth 1 common) (nth 2 common)
           ;; These are done separately here
           ;; so that command-history will record these expressions
           ;; rather than the values they had this time.
           (if (and transient-mark-mode mark-active)
               (region-beginning))
           (if (and transient-mark-mode mark-active)
               (region-end))
           (nth 3 common))))

  ;; Do it
  (replace-pairs--do-replace from-item to-item t delimited start end backward))

;;;###autoload
(defun replace-pairs (from-item to-item &optional delimited start end backward)
  "Replace pairs of things

For example replace `(' and `)' with `[' and `]' respectively.

Interface is identical to `replace-string'."
  (interactive
   (let ((common
          (query-replace-read-args
           (concat "Replace pairs"
                   (if current-prefix-arg
                       (if (eq current-prefix-arg '-) " backward" " word")
                     "")
                   (if (and transient-mark-mode mark-active) " in region" ""))
           nil)))
     (list (nth 0 common) (nth 1 common) (nth 2 common)
           (if (and transient-mark-mode mark-active)
               (region-beginning))
           (if (and transient-mark-mode mark-active)
               (region-end))
           (nth 3 common))))

  ;; Do it
  (replace-pairs--do-replace from-item to-item nil delimited start end backward))



(provide 'replace-pairs)

;;; replace-pairs.el ends here
