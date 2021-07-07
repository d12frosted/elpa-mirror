;;; org-tree-slide-pauses.el --- Bring the \pause Beamer to org-tree-slide!

;; Copyright 2020 cnngimenez
;;
;; Author: cnngimenez
;; Maintainer: cnngimenez
;; Version: 0.1.0
;; Package-Version: 20201202.217
;; Package-Commit: 80d6e9279fad10bcff15fbce75726bb002da73c0
;; Keywords: convenience, org-mode, presentation
;; URL: https://github.com/cnngimenez/org-tree-slide-pauses
;; Package-Requires: ((emacs "24.4") (org-tree-slide "2.8.4"))

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

;; Bring animation like in Beamer into your org-tree-slide presentations!
;;
;; Maunal installation:
;; Download the org-tree-slide-pauses.el.  Add the path to the `load-path'
;; variable and load it.  This can be added to the .emacs initialization file:
;;
;;     (add-to-list 'load-path "path-to-where-the-el-file-is")
;;     (require 'org-tree-slide-pauses)
;;
;; Usage:
;; - List items and enumerations works automatically.
;; - Add one of the following to create a pause:
;;   # pause
;;   #+pause:
;;   #+beamer: \pause
;;
;; When you start to presenting with `org-tree-slide-mode' the text between
;; pauses will appear with the "shadow" face.  Use the C->
;; (M-x `org-tree-slide-move-next-tree') to show one by one.  If there is no
;; more text to reveal, the same command will show the next slide/title like
;; usual.

;;; Code:

(provide 'org-tree-slide-pauses)
(require 'org-element)
(require 'org-tree-slide)

;;;;##########################################################################
;;;;  User Options, Variables
;;;;##########################################################################


(defconst org-tree-slide-pauses-pause-regexp "^[[:space:]]*# pause[[:space:]]*$"
  "Regexp to find the pause declaration.") ;; defconst

(defvar org-tree-slide-pauses-pause-text-list '()
  "List of overlays to hide the \"pause\" text position." )

(defvar org-tree-slide-pauses-overlay-lists '()
  "List of pauses overlays.
This list is created with the `org-tree-slide-pauses-search-pauses'.")

(defvar org-tree-slide-pauses-current-pause 0)

(defun org-tree-slide-pauses-clear-overlay-list ()
  "Clear the `org-tree-slide-pauses-overlay-lists'."
  (dolist (the-overlay org-tree-slide-pauses-overlay-lists)
    (delete-overlay the-overlay))
  (setq org-tree-slide-pauses-overlay-lists '())

  (dolist (the-overlay org-tree-slide-pauses-pause-text-list)
    (delete-overlay the-overlay))
  (setq org-tree-slide-pauses-pause-text-list '())

  (setq org-tree-slide-pauses-current-pause 0) ) ;; defun


(defun org-tree-slide-pauses--search-elements ()
  "Search all items that needs pauses and return the org-element list."

  (delq
   nil
   (org-element-map (org-element-parse-buffer nil t)
       '(comment item keyword headline)
     (lambda (element)
       "If it is one of the pauses, return their positions"
       (cond

	((eq (org-element-type element) 'keyword)
	 (if (or (string-equal (org-element-property :key element) "PAUSE")
		 (and (string-equal (org-element-property :key element)
				    "BEAMER")
		      (string-equal (org-element-property :value element)
				    "\\pause")))
	     element
	   nil))
	
	((eq (org-element-type element) 'comment)
	 (if (string-equal (org-element-property :value element) "pause")
	     element
	   nil))
	
	(t element))))) ) ;; defun

(defun org-tree-slide-pauses--new-overlay-for-text ()
  "Return new overlays for all elements that needs to be hidden."

  (delq nil
	(mapcar (lambda (element)
		  (unless (member (org-element-type element)
				  '(item headline))
		    (make-overlay
		     (org-element-property :begin element)
		     (org-element-property :end element))))
		(org-tree-slide-pauses--search-elements))) ) ;; defun

(defun org-tree-slide-pauses--new-overlay-for-pair (element next-element)
  "Create overlays for a consecutive pair of (ELEMENT NEXT-ELEMENT).
Returns nil when:
- There are blanks texts between pauses (no text to show).
- The first one is a headline (no pauses between headline and first item)"
  (cond
   ((and (eq (org-element-type element) 'headline))
    ;; the first is a headline, ignore it.
    nil)

   ((and (numberp next-element)
	 (eq (org-element-type element) 'item))
    ;; It's the last and the previous is an item
    (list
     (make-overlay (org-element-property :begin element)
		   (org-element-property :end element))
     (unless (string-blank-p (buffer-substring-no-properties
			      (org-element-property :end element)
			      next-element))
       (make-overlay (org-element-property :end element) next-element))))

    ((and (numberp next-element))
     ;; It's the last and the previous is a pause
     (unless (string-blank-p (buffer-substring-no-properties
			      (org-element-property :end element)
			      next-element))
       (list (make-overlay (org-element-property :end element) next-element))))

   ((and (eq (org-element-type element) 'item)
	 (eq (org-element-type next-element) 'item))
    ;; both are items
    (list
     (make-overlay (org-element-property :begin element)
		   (org-element-property :end element))))

   ((eq (org-element-type element) 'item)
    ;; the first one is an item, the second one is a pause/headline
    (list
     (make-overlay (org-element-property :begin element)
		   (org-element-property :end element))
     (unless (string-blank-p (buffer-substring-no-properties
			      (org-element-property :end element)
			      (org-element-property :begin next-element)))
       (make-overlay (org-element-property :end element)
		     (org-element-property :begin next-element)))))

   ((eq (org-element-type next-element) 'item)
    ;; the first one is a pause/headline, the second one is an item
    (list
     (unless (string-blank-p (buffer-substring-no-properties
			      (org-element-property :end element)
			      (org-element-property :begin next-element)))
       (make-overlay (org-element-property :end element)
		     (org-element-property :begin next-element)))
     (make-overlay (org-element-property :begin next-element)
		   (org-element-property :end next-element))))

   (t
    ;; both of them are pauses
    (if (string-blank-p (buffer-substring-no-properties
			 (org-element-property :end element)
			 (org-element-property :begin next-element)))
	nil
      (list
       (make-overlay (org-element-property :end element)
		     (org-element-property :begin next-element))))) ) ;; cond
  ) ;; defun

(defun org-tree-slide-pauses--partition (lst-elements)
  "Partition of the LST-ELEMENTS into list of two elements."

  (let ((prev nil)
	(result '()))
    
    (dolist (element lst-elements)
      (add-to-list 'result (cons prev element) t)
      (setq prev element))

    (when prev
      (add-to-list 'result (cons prev (point-max)) t))
    
    (cdr result)) ) ;; defun


(defun org-tree-slide-pauses--new-overlay-for-pauses ()
  "Return new overlays for all elements that needs to be paused."
  (delq
   nil
   (apply #'append
	  (mapcar (lambda (element)
		    (org-tree-slide-pauses--new-overlay-for-pair (car element)
						     (cdr element)))
		  (org-tree-slide-pauses--partition
		   (org-tree-slide-pauses--search-elements))))) ) ;; defun


(defun org-tree-slide-pauses-search-pauses ()
  "Hide all pauses."
  (org-tree-slide-pauses-clear-overlay-list)

  (setq org-tree-slide-pauses-pause-text-list
	(org-tree-slide-pauses--new-overlay-for-text))
  (setq org-tree-slide-pauses-overlay-lists
	(org-tree-slide-pauses--new-overlay-for-pauses)))

(defun org-tree-slide-pauses-hide-pauses ()
  "Hide all pauses."
  (interactive)
  (dolist (the-overlay org-tree-slide-pauses-pause-text-list)
    (overlay-put the-overlay 'invisible t))
  
  (dolist (the-overlay org-tree-slide-pauses-overlay-lists)
    (overlay-put the-overlay 'face 'shadow)) ) ;; defun

(defun org-tree-slide-pauses-show-pauses ()
  "Show everything to edit the buffer easily.
This do not deletes the overlays that hides the pauses commands, it only make
them visibles."
  (interactive)
  (dolist (the-overlay org-tree-slide-pauses-pause-text-list)
    (overlay-put the-overlay 'invisible nil)) ) ;; defun


(defun org-tree-slide-pauses-init ()
  "Search for pauses texts, create overlays and setup to start presentation.
This function is added to the `org-tree-slide-after-narrow-hook' to start the
pauses parsing."
  (org-tree-slide-pauses-search-pauses)
  (org-tree-slide-pauses-hide-pauses) ) ;; defun

(defun org-tree-slide-pauses-end ()
  "Restore the buffer and delete overlays."
  (org-tree-slide-pauses-clear-overlay-list) ) ;; defun


(defun org-tree-slide-pauses-next-pause ()
  "Show next pause.

Basically, all text are stored as overlays in
`org-tree-slide-pauses-overlay-lists'.  Just take one more and set its face.

`org-tree-slide-pauses-current-pause' keep track of the number of overlays
displayed."
  
  (when (nth org-tree-slide-pauses-current-pause
	     org-tree-slide-pauses-overlay-lists)
    (overlay-put (nth org-tree-slide-pauses-current-pause
		      org-tree-slide-pauses-overlay-lists)
		 'face nil)
    (setq org-tree-slide-pauses-current-pause
	  (1+ org-tree-slide-pauses-current-pause))) ) ;; defun


(defun org-tree-slide-pauses-next-advice (ots-move-next-tree &rest args)
  "Advice for 'org-tree-slide-move-next-tree'.

When the user ask for the next slide, instead show the next hidden text.
If no hidden text is found, then show the next slide (call
OTS-MOVE-NEXT-TREE, the original function with ARGS arguments)."
  (interactive)
  (if (>= org-tree-slide-pauses-current-pause
	 (length org-tree-slide-pauses-overlay-lists))
      (progn
	(apply ots-move-next-tree args)
	;; Parse the current slide, or just in case the user edited the buffer
	
	;; (org-tree-slide-pauses-init)
	)
    (progn
      (org-tree-slide-pauses-next-pause)
      (message (format "Pauses: %d/%d"
		       org-tree-slide-pauses-current-pause
		       (length org-tree-slide-pauses-overlay-lists))))) ) ;; defun

(advice-add #'org-tree-slide-move-next-tree
	    :around #'org-tree-slide-pauses-next-advice)

(add-hook 'org-tree-slide-after-narrow-hook #'org-tree-slide-pauses-init)

;;; org-tree-slide-pauses.el ends here
