;;; origami-predef.el --- Apply folding when finding (opening) files  -*- lexical-binding: t; -*-

;; Author: Álvaro González Sotillo <alvarogonzalezsotillo@gmail.com>
;; URL: https://github.com/alvarogonzalezsotillo/origami-predef
;; Package-Version: 20200615.1044
;; Package-Commit: cc363f4b2fd20021ab330fc989369e2658457f93
;; Package-Requires: ((emacs "24.3") (origami "1.0"))
;; Version: 1.0
;; Keywords: convenience folding

;; This file is not part of GNU Emacs.

;;; License:

;; GNU General Public License v3.0. See COPYING for details.


;;; Commentary:

;; Apply predefined folding to a buffer, based on customizable string occurrences.
;; The origami package is used to perform the actual folding.
;;
;; Quick start:
;; Enable the mode origami-predef-global-mode.  This will add a find-file-hook that will fold every tagged line.
;; Tag the lines you need to be initialy folded with *autofold*.
;; 
;;   public void boringMethod(){ // *autofold*
;;      foo();
;;      bar();
;;   }
;;  
;; Sometimes, the tag can not be placed in the same line you need to be folded.  In these cases, *autofold:*
;; will fold the next line.
;;
;;   # A very long shell variable with newlines
;;    # *autofold:*
;;   LOREM="
;;     Pellentesque dapibus suscipit ligula.
;;     Donec posuere augue in quam.
;;     Etiam vel tortor sodales tellus ultricies commodo.
;;     Suspendisse potenti.
;;     Aenean in sem ac leo mollis blandit.
;;     ...
;;   "
;;
;; The tags can be changed with customize.
;;
;; You can invoke =origami-predef-apply= to reset folding to its initial state, according to tagged lines.
;;
;; It is possible to define initial folding for each major mode using the mode hook and origami-predef-apply-patterns.
;;
;; More information at https://github.com/alvarogonzalezsotillo/origami-predef



;;; Code:
(require 'origami)

(defgroup origami-predef-group nil
  "Apply predefined folding when finding (opening) files."
  :group 'convenience)

(defcustom origami-predef-strings-fold-this '("\\*autofold\\*")  ; *autofold*
  "When found, `origami-close-node' will be invoked on the same line."
  :type '(repeat string))

;;; *autofold:*
(defcustom origami-predef-strings-fold-next '("\\*autofold:\\*")
  "When found, `origami-close-node' will be invoked on the next line."
  :type '(repeat string))

;;; See origami-hide-overlay
(defun origami-predef--point-in-folded-overlay ()
  "Check if point is on an already folded overlay."
  (let* ((overlays (overlays-at (point)))
         (predicate (lambda (overlay) (overlay-get overlay 'invisible)))
         (folded-overlay (cl-find-if predicate overlays)))
    folded-overlay))
  

(defun origami-predef--match-and-apply (pattern-or-patterns function)
  "Search buffer and apply the FUNCTION on each line.
PATTERN-OR-PATTERNS is a string or a list of strings to search"
  (let ((patterns (if (listp pattern-or-patterns) pattern-or-patterns (list pattern-or-patterns) )))
    (save-excursion
      (dolist (pattern patterns)
        (goto-char (point-min))
        (while (re-search-forward pattern nil t 1)
          (unless (origami-predef--point-in-folded-overlay)
            (funcall function)))))))


(defun origami-predef--hide-element-next-line ()
  "Apply origami-hide-element to the next line of current point."
  (forward-line)
  (origami-predef--hide-element-this-line))

(defun origami-predef--hide-element-this-line ()
  "Apply origami-hide-element to the line of current point."
  (move-end-of-line nil)
  (origami-close-node (current-buffer) (point)))

(defun origami-predef-apply()
  "Apply folding based on origami-predef-strings-fold-* variables."
  (interactive)
  (origami-predef-apply-patterns origami-predef-strings-fold-this origami-predef-strings-fold-next))


(defun origami-predef-apply-patterns (this-line &optional next-line)
  "Apply folding to patterns in THIS-LINE and NEXT-LINE.
The folding is performed by `origami-predef--hide-element-this-line'
and `origami-predef--hide-element-next-line'"
  (origami-predef--match-and-apply this-line #'origami-predef--hide-element-this-line)
  (origami-predef--match-and-apply next-line #'origami-predef--hide-element-next-line))


;;;###autoload
(define-minor-mode origami-predef-global-mode
  "Apply initial folding when finding (opening) a file buffer"
  :group 'origami-predef-group
  :global t
  
  (remove-hook 'find-file-hook #'origami-predef-apply t)
  (when origami-predef-global-mode
    (add-hook 'find-file-hook #'origami-predef-apply t)))

(provide 'origami-predef)
;;; origami-predef.el ends here
