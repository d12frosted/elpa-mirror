;;; loc-changes.el --- keep track of positions even after buffer changes

;; Copyright (C) 2015, 2016, 2020 Free Software Foundation, Inc

;; Author: Rocky Bernstein <rocky@gnu.org>
;; Version: 1.2
;; Package-Version: 20200722.1111
;; Package-Commit: 0a55bcba684f78417e831eef2cc32da24a207f29
;; URL: https://github.com/rocky/emacs-loc-changes
;; Compatibility: GNU Emacs 24.x

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

;; This package lets users or programs set marks in a buffer prior to
;; changes so that we can track the original positions after the
;; change.

;; One common use is say when debugging a program.  The debugger has its static
;; notion of the file and positions inside that.  However it may be convenient
;; for a programmer to edit the program but not restart execution of the program.

;; Another use might be in a compilation buffer for errors and
;; warnings which refer to file and line positions.

;;; Code:

(eval-when-compile (require 'cl))

(make-variable-buffer-local 'loc-changes-alist)
(defvar loc-changes-alist '()
  "A buffer-local association-list (alist) of line numbers and
their corresponding markers in the buffer. The key is the line
number; the a list of value the marker and the initial 10
characters after that mark" )

(defun loc-changes:follow-mark(event)
  (interactive "e")
  (let* ((pos (posn-point (event-end event)))
	 (mark (car (get-text-property pos 'mark))))
    (switch-to-buffer-other-window  (marker-buffer mark))
    (goto-char (marker-position mark))
    ))


(defun loc-changes:alist-describe (&optional opt-buffer)
  "Display buffer-local variable loc-changes-alist. If BUFFER is
not given, the current buffer is used. Information is put in an
internal buffer called *Describe*."
  (interactive "")
  (let ((buffer (or opt-buffer (current-buffer)))
	(alist))
    (with-current-buffer buffer
	  (setq alist loc-changes-alist)
	  (unless (listp alist) (error "expecting loc-changes-alist to be a list"))
	  )
    (switch-to-buffer (get-buffer-create "*Describe*"))
    (setq buffer-read-only 'nil)
    (delete-region (point-min) (point-max))
    (dolist (assoc alist)
	  (put-text-property
	   (insert-text-button
	    (format "line %d: %s" (car assoc) (cadr assoc))
	    'action 'loc-changes:follow-mark
	    'help-echo "mouse-2: go to this location")
	   (point)
	   'mark (cdr assoc)
	    )
	  (insert (format ":\t%s\n" (cl-caddr assoc)))
	  )
    (setq buffer-read-only 't)
    ))

(defun loc-changes-goto-line (line-number &optional column-number)
  "Position `point' at LINE-NUMBER of the current buffer. If
COLUMN-NUMBER is given, position `point' at that column just
before that column number within the line. Note that the beginning of
the line starts at column 0, so the column number display will be one less
than COLUMN-NUMBER. For example COLUMN-NUMBER 1 will set before the first
column on the line and show 0.

The Emacs `goto-line' docstring says it is wrong to use that
function in a Lisp program. So here is something that I proclaim
is okay to use in a Lisp program."
  (interactive
   (if (and current-prefix-arg (not (consp current-prefix-arg)))
       (list (prefix-numeric-value current-prefix-arg))
     ;; Look for a default, a number in the buffer at point.
     (let* ((default
	      (save-excursion
		(skip-chars-backward "0-9")
		(if (looking-at "[0-9]")
		    (string-to-number
		     (buffer-substring-no-properties
		      (point)
		      (progn (skip-chars-forward "0-9")
			     (point)))))))
	    ;; Decide if we're switching buffers.
	    (buffer
	     (if (consp current-prefix-arg)
		 (other-buffer (current-buffer) t)))
	    (buffer-prompt
	     (if buffer
		 (concat " in " (buffer-name buffer))
	       "")))
       ;; Read the argument, offering that number (if any) as default.
       (list (read-number (format "Goto line%s: " buffer-prompt)
                          (list default (line-number-at-pos)))
	     buffer))))
  (unless (wholenump line-number)
    (error "Expecting line-number parameter `%s' to be a whole number"
	   line-number))
  (unless (> line-number 0)
    (error "Expecting line-number parameter `%d' to be greater than 0"
	   line-number))
  (let ((last-line (line-number-at-pos (point-max))))
    (unless (<= line-number last-line)
      (error
       "Line number %d should not exceed %d, the number of lines in the buffer"
       line-number last-line))
    (goto-char (point-min))
    (forward-line (1- line-number))
    (if column-number
	(let ((last-column
	       (save-excursion
		 (move-end-of-line 1)
		 (current-column))))
	  (cond ((not (wholenump column-number))
		 (message
		  "Column ignored. Expecting column-number parameter `%s' to be a whole number"
			  column-number))
		((<= column-number 0)
		 (message
		  "Column ignored. Expecting column-number parameter `%d' to be a greater than 1"
			  column-number))
		((>= column-number last-column)
		 (message
		  "Column ignored. Expecting column-number parameter `%d' to be a less than %d"
		   column-number last-column))
		(t (forward-char (1- column-number)))))
      )
    (redisplay)
    )
  )

(defun loc-changes-add-elt (pos)
  "Add an element `loc-changes-alist'. The car will be POS and a
marker for it will be created at the point."
  (setq loc-changes-alist
	(cons (cons pos (list (point-marker) (buffer-substring (point) (point-at-eol))))
		    loc-changes-alist)))

(defun loc-changes-add-and-goto (line-number &optional opt-buffer)
  "Add a marker at LINE-NUMBER and record LINE-NUMBER and its
marker association in `loc-changes-alist'."
  (interactive
   (if (and current-prefix-arg (not (consp current-prefix-arg)))
       (list (prefix-numeric-value current-prefix-arg))
     ;; Look for a default, a number in the buffer at point.
     (let* ((default
	      (save-excursion
		(skip-chars-backward "0-9")
		(if (looking-at "[0-9]")
		    (string-to-number
		     (buffer-substring-no-properties
		      (point)
		      (progn (skip-chars-forward "0-9")
			     (point)))))))
	    ;; Decide if we're switching buffers.
	    (buffer
	     (if (consp current-prefix-arg)
		 (other-buffer (current-buffer) t)))
	    (buffer-prompt
	     (if buffer
		 (concat " in " (buffer-name buffer))
	       "")))
       ;; Read the argument, offering that number (if any) as default.
       (list (read-number (format "Goto line%s: " buffer-prompt)
                          (list default (line-number-at-pos)))
	     buffer))))

  (let ((buffer (or opt-buffer (current-buffer))))
    (with-current-buffer buffer
      (loc-changes-goto-line line-number)
      (loc-changes-add-elt line-number)
      ))
  )

(defun loc-changes-clear-buffer (&optional opt-buffer)
  "Remove all location-tracking associations in BUFFER."
  (interactive "bbuffer: ")
  (let ((buffer (or opt-buffer (current-buffer)))
	)
    (with-current-buffer buffer
      (setq loc-changes-alist '())
      ))
  )

(defun loc-changes-reset-position (&optional opt-buffer no-insert)
  "Update `loc-changes-alist' so that the line number of point is
used to when aline number is requested.

Updates any existing line numbers referred to in marks at this
position.

This may be useful for example in debugging if you save the
buffer and then cause the debugger to reread/reevaluate the file
so that its positions are will be reflected."
  (interactive "")
  (let* ((line-number (line-number-at-pos (point)))
	 (elt (assq line-number loc-changes-alist)))
    (let ((buffer (or opt-buffer (current-buffer)))
	  )
      (with-current-buffer buffer
	(if elt
	    (setcdr elt
		    (list (point-marker) (buffer-substring (point) (point-at-eol))))
	  (unless no-insert
	    (loc-changes-add-elt line-number)
	    )
	  ))
      )
    ))


(defun loc-changes-goto (line-number &optional opt-buffer no-update)
  "Go to the LINE-NUMBER inside OPT-BUFFER taking into account the
previous line-number marks. Normally if the line-number hasn't been
seen before, we will add a new mark for this line-number. However if
NO-UPDATE is set, no mark is added."
  ;;; FIXME: opt-buffer is not used
  (unless (wholenump line-number)
    (error "Expecting line-number parameter `%s' to be a whole number"
	   line-number))
  (let ((elt (assq line-number loc-changes-alist)))
    (if elt
	(let ((marker (cadr elt)))
	  (unless (markerp marker)
	    (error "Internal error: loc-changes-alist is not a marker"))
	  (goto-char (marker-position marker)))
      (if no-update
	  (loc-changes-goto-line line-number)
	(loc-changes-add-and-goto line-number))
      )
    )
  )

(provide 'loc-changes)
;;; loc-changes.el ends here
