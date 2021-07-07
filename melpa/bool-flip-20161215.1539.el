;;; bool-flip.el --- flip the boolean under the point

;; Copyright (C) 2016 Michael Brandt
;;
;; Author: Michael Brandt <michaelbrandt5@gmail.com>
;; URL: http://github.com/michaeljb/bool-flip/
;; Package-Version: 20161215.1539
;; Package-Commit: f58a9a7b9ab875bcfbd57c8262697ae404eb4485
;; Package-Requires: ((emacs "24.3"))
;; Version: 1.0.1
;; Keywords: boolean, convenience, usability

;; This file is not part of GNU Emacs.

;;; License:

;; Licensed under the same terms as Emacs.

;;; Commentary:

;; Bind the following commands:
;; bool-flip-do-flip
;;
;; For a detailed introduction see:
;; http://github.com/michaeljb/bool-flip/blob/master/README.md

;;; Code:

(require 'cl-lib)

(defcustom bool-flip-alist
  '(("T"    . "F")
    ("t"    . "f")
    ("TRUE" . "FALSE")
    ("True" . "False")
    ("true" . "false")
    ("Y"    . "N")
    ("y"    . "n")
    ("YES"  . "NO")
    ("Yes"  . "No")
    ("yes"  . "no")
    ("1"    . "0"))
  "List of values flipped by `bool-flip-do-flip'."
  :group 'bool-flip
  :safe 'listp)

;;;###autoload
(defun bool-flip-do-flip ()
  "Replace the boolean at point with its opposite."
  (interactive)
  (let* ((old (thing-at-point 'symbol))
         (new (or (cdr (assoc  old bool-flip-alist))
                  (car (rassoc old bool-flip-alist)))))
    (if new
        (cl-destructuring-bind (beg . end)
            (bounds-of-thing-at-point 'symbol)
          (let ((insert-after (= (point) beg)))
            (delete-region beg end)
            (insert new)
            (when insert-after
              (goto-char beg))))
      (user-error "Nothing to flip here"))))

(provide 'bool-flip)
;;; bool-flip.el ends here
