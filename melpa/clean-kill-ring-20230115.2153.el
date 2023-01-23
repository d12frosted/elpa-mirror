;;; clean-kill-ring.el --- Keep the kill ring clean  -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Nicholas Hubbard <nicholashubbard@posteo.net>
;;
;; Licensed under the same terms as Emacs and under the MIT license.

;; SPDX-License-Identifier: MIT

;; Author: Nicholas Hubbard <nicholashubbard@posteo.net>
;; URL: http://github.com/NicholasBHubbard/clean-kill-ring.el
;; Package-Version: 20230115.2153
;; Package-Commit: d05fa7ee97e760d21d533261c7b63eecf223f612
;; Package-Requires: ((emacs "24.4"))
;; Version: 1.1
;; Created: 2022-02-23
;; By: Nicholas Hubbard <nicholashubbard@posteo.net>
;; Keywords: kill-ring, convenience

;;; Commentary:

;; This package provides functionality for automatic customized filtering of the
;; kill ring.

;;; Code:

(defcustom clean-kill-ring-filters '(string-blank-p)
  "List of functions for cleaning the `kill-ring'."
  :type '(repeat function)
  :group 'clean-kill-ring-mode)

(defcustom clean-kill-ring-prevent-duplicates nil
  "Non-nil means prevent duplicate items from entering the `kill-ring'."
  :type 'boolean
  :group 'clean-kill-ring-mode)

(defun clean-kill-ring-filter-catch-p (string)
  "T if STRING satisfies at least one of `clean-kill-ring-filters'."
  (let ((caught nil)
        (s (substring-no-properties string)))
    (catch 'loop
      (dolist (filter clean-kill-ring-filters)
        (when (funcall filter s)
          (setq caught t)
          (throw 'loop t))))
    caught))

(defun clean-kill-ring-clean (&optional remove-dups)
  "Remove `kill-ring' members that satisfy one of`clean-kill-ring-filters'.

If REMOVE-DUPS or `clean-kill-ring-prevent-duplicates' is non-nil, or if called
interactively then remove duplicate items from the `kill-ring'."
  (interactive (list t))
  (let ((new-kill-ring nil)
        (this-kill-ring-member nil)
        (i (1- (length kill-ring))))
    (while (>= i 0)
      (setq this-kill-ring-member (nth i kill-ring))
      (unless (clean-kill-ring-filter-catch-p this-kill-ring-member)
        (push this-kill-ring-member new-kill-ring))
      (setq i (1- i)))
    (if (or remove-dups clean-kill-ring-prevent-duplicates)
        (setq kill-ring (delete-dups new-kill-ring))
      (setq kill-ring new-kill-ring))))

(defun clean-kill-ring-clean-most-recent-entry ()
  "Remove head of `kill-ring' if it satisfies one of `clean-kill-ring-filters'.

If `clean-kill-ring-prevent-duplicates' is non-nil then remove all items from
the `kill-ring' that are `string=' to the most recent entry."
  (let ((most-recent (car kill-ring)))
    (if (clean-kill-ring-filter-catch-p most-recent)
        (pop kill-ring)
      (when clean-kill-ring-prevent-duplicates
        (let ((new-kill-ring nil)
              (this-kill-ring-member nil)
              (i (1- (length kill-ring))))
          (while (>= i 0)
            (setq this-kill-ring-member (nth i kill-ring))
            (when (or (= i 0) (not (string= most-recent this-kill-ring-member)))
              (push this-kill-ring-member new-kill-ring))
            (setq i (1- i)))
          (setq kill-ring new-kill-ring))))
    (setq kill-ring-yank-pointer kill-ring)))

(defvar clean-kill-ring-mode-map (make-sparse-keymap)
  "Keymap for `clean-kill-ring-mode'.")

(define-minor-mode clean-kill-ring-mode
  "Toggle `clean-kill-ring-mode'.

When active prevent strings that satisfy at least one predicate in
`clean-kill-ring-filters' from entering the `kill-ring'."
  :global t
  :group 'clean-kill-ring-mode
  :require 'clean-kill-ring
  :keymap clean-kill-ring-mode-map
  (if clean-kill-ring-mode
      (progn
        (clean-kill-ring-clean)
        (advice-add 'kill-new :after #'(lambda (&rest _args)
                                         (clean-kill-ring-clean-most-recent-entry))))
    
    (advice-remove 'kill-new #'(lambda (&rest _args)
                                 (clean-kill-ring-clean-most-recent-entry)))))

(provide 'clean-kill-ring)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; clean-kill-ring.el ends here
