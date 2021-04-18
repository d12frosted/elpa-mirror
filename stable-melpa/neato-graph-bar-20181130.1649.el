;;; neato-graph-bar.el --- Neat-o graph bars CPU/memory etc. -*- lexical-binding: t -*-

;; Author: Robert Cochran <robert-git@cochranmail.com>.
;; URL: https://gitlab.com/RobertCochran/neato-graph-bar
;; Package-Version: 20181130.1649
;; Package-Commit: a7ae35afd67911e8924f36e646bce0d3e3c1bbe6
;; Version: 1.0.0
;; Package-Requires: ((emacs "24.3"))

;; Copyright (C) 2016 Robert Cochran <robert-git@cochranmail.com>
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

;; Provides htop-like graphs for CPU and memory consumption.  A good
;; companion for proced.  Run `neato-graph-bar'.

;;; Code:

(require 'cl-lib)

(defgroup neato-graph-bar nil
  "Neat-o graph bars for various things"
  :group 'applications)

(defcustom neato-graph-bar-memory-info-file
  "/proc/meminfo"
  "File to grab the memory usage info from.

Currently expecting Linux meminfo format."
  :type '(file :must-match t)
  :group 'neato-graph-bar)

(defcustom neato-graph-bar-cpu-stat-file
  "/proc/stat"
  "File to grab the CPU usage statistics from.

Currently expecting Linux /proc/stat format."
  :type '(file :must-match t)
  :group 'neato-graph-bar)

(defcustom neato-graph-bar-unified-cpu-graph
  nil
  "When nil, draw separate graphs for each CPU.
When non-nil, draw a single unified CPU graph."
  :type 'boolean)

(defcustom neato-graph-bar-label-padding
  4
  "The number of characters to pad graph labels to."
  :type 'wholenum
  :group 'neato-graph-bar)

(defcustom neato-graph-bar-refresh-time
  1
  "The number of seconds to wait before refreshing."
  :type 'number
  :group 'neato-graph-bar)

(defface neato-graph-bar-memory-used
  '((t
     :foreground "green"
     :inherit default))
  "Face for the portion of the memory graph representing userspace memory"
  :group 'neato-graph-bar)

(defface neato-graph-bar-memory-buffer
  '((t
     :foreground "blue"
     :inherit default))
  "Face for the portion of the memory graph representing buffers"
  :group 'neato-graph-bar)

(defface neato-graph-bar-memory-cache
  '((t
     :foreground "yellow"
     :inherit default))
  "Face for the portion of the memory graph representing caches"
  :group 'neato-graph-bar)

(defface neato-graph-bar-cpu-user
  '((t
     :foreground "green"
     :inherit default))
  "Face for the portion of the CPU graph representing user programs"
  :group 'neato-graph-bar)

(defface neato-graph-bar-cpu-system
  '((t
     :foreground "red"
     :inherit default))
  "Face for the portion of the CPU graph representing the kernel"
  :group 'neato-graph-bar)

(defface neato-graph-bar-cpu-interrupt
  '((t
     :foreground "gray"
     :inherit default))
  "Face for the portion of the CPU graph representing interrupts"
  :group 'neato-graph-bar)

(defface neato-graph-bar-cpu-vm
  '((t
     :foreground "purple"
     :inherit default))
  "Face for the portion of the CPU graph representing virtual machines"
  :group 'neato-graph-bar)

(defvar-local neato-graph-bar--memory-fields-to-keep
  '("MemTotal"
    "MemFree"
    "MemAvailable"
    "Buffers"
    "Cached"
    "SwapTotal"
    "SwapFree"
    "SwapCached")
  "Fields to keep when retrieving memory information, to keep
memory use low and not have a bunch of unused info in the
alist.")

(defvar-local neato-graph-bar--cpu-field-names
  '(user
    nice
    system
    idle
    iowait
    irq
    softirq
    steal
    guest
    guest-nice)
  "Field names for CPU statistics")

(defvar-local neato-graph-bar--cpu-stats-previous
  nil
  "Previous statistics of CPU usage information")

(defvar-local neato-graph-bar--update-timer
  nil
  "Update timer for graphs")

(defvar-local neato-graph-bar--current-window
  nil
  "Current window")

;;;###autoload
(defun neato-graph-bar ()
  "Displays system information graph bars."
  (interactive)
  (let ((buffer (get-buffer-create "*Neato Graph Bar*")))
    (set-buffer buffer)
    (buffer-disable-undo buffer)
    (when (zerop (buffer-size))
      (neato-graph-bar-mode)
      (neato-graph-bar-update))
    (pop-to-buffer buffer)
    (unless neato-graph-bar--update-timer
      (setq neato-graph-bar--update-timer
	    (run-at-time 0
			 neato-graph-bar-refresh-time
			 'neato-graph-bar-update)))))

;;;###autoload
(define-derived-mode neato-graph-bar-mode
  special-mode
  "Neato Graph Bar"
  (set (make-local-variable 'revert-buffer-function)
       'neato-graph-bar-update)
  (setq cursor-type nil)
  (add-hook 'kill-buffer-hook
	    (lambda ()
	      (if (timerp neato-graph-bar--update-timer)
		  (cancel-timer neato-graph-bar--update-timer)))
            nil t))

(defun neato-graph-bar-update ()
  "Update the graphs."
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (eq major-mode 'neato-graph-bar-mode)
	(setq neato-graph-bar--current-window (get-buffer-window nil t))
	(if neato-graph-bar--current-window
	    (neato-graph-bar--redraw))))))

(defun neato-graph-bar--redraw ()
  "Neato Graph Bar revert function."
  (if (zerop (window-width neato-graph-bar--current-window))
      (cl-return-from neato-graph-bar-update))
  (let ((buffer-read-only nil))
    (erase-buffer)
    (neato-graph-bar--draw-all-graphs))
  (goto-char (point-min)))

(defun neato-graph-bar--draw-graph (label portions &optional end-text)
  "Draw a bar graph.

LABEL is the label in front of the graph.  PORTIONS is an alist
of font-percent value pairs, where percent is a float between 0
and 1. Al unused space will automatically be marked as empty.  For
example, to specify that you want a graph drawn with face1 as the
first 30%, and face2 the second 20%, with the rest empty, you
would pass

\((face1 . 0.3)
 (face2 . 0.2))

for PORTIONS.  END-TEXT is placed within the graph at the
end.  Unspecified, it defaults to a percentage, but can be any
arbitrary string (good for doing things such as providing a
\"30MB/100MB\" type counter for storage graphs)."
  (let* ((padded-label (concat (make-string (max (- neato-graph-bar-label-padding
                                                    (length label))
                                                 0)
                                            ?\s)
                               label))
         (bar-width (- (window-body-width neato-graph-bar--current-window)
                       ;; Seems that Emacs will wrap the line if it extends
                       ;; all the way to the end of the window in a terminal...
                       ;; not what we want... so adjust for it.
                       (if (display-graphic-p) 0 1)
                       (length padded-label)
                       ; 3 -> Space after label + '[' + ']'
                       3))
	 (filled-percent 0.0))
    (insert padded-label " [")
    (dolist (pair portions)
      (cl-destructuring-bind (face . percent) pair
	(insert (propertize
		 (make-string (round (* percent bar-width)) ?|)
		'font-lock-face face))
	(cl-incf filled-percent percent)))
    (insert (make-string (- (+ bar-width (length padded-label) 2)
			    (current-column))
	    ?\s))
    (insert "]")
    (unless end-text
      (setq end-text (format "%.1f%%" (* filled-percent 100))))
    (save-excursion
      (backward-char (1+ (length end-text)))
      (insert end-text)
      (delete-char (length end-text)))))

(defun neato-graph-bar--create-storage-status-text (used total)
  "Create an end-text suitable for storage bars (ie \"10M/200M\").

USED and TOTAL should both be in kilobytes."
  (let ((suffix-table '(?K ?M ?G ?T))
	(log-used (if (zerop used) 0 (floor (log used 1024))))
	(log-total (if (zerop total) 0 (floor (log total 1024)))))
    (format "%.1f%c/%.1f%c"
	    (/ (float used) (expt 1024 log-used))
	    (elt suffix-table log-used)
	    (/ (float total) (expt 1024 log-total))
	    (elt suffix-table log-total))))

(defun neato-graph-bar--get-memory-info ()
  "Retrieve the system memory information.

This is obtained from `neato-graph-bar-memory-info-file', and
filtered down to entries listed in `neato-graph-bar--memory-fields-to-keep'."
  (let ((mem-info-list
	 (mapcar (lambda (x) (split-string x ":" t))
		 (with-temp-buffer
		   (insert-file-contents neato-graph-bar-memory-info-file)
		   (split-string (buffer-string) "\n" t)))))
    (cl-delete-if-not (lambda (x) (member x neato-graph-bar--memory-fields-to-keep))
		      mem-info-list
		      :key #'car)
    (mapc (lambda (x) (rplacd x (string-to-number (car (split-string (cadr x))))))
	  mem-info-list)))

(defun neato-graph-bar--queue-memory-graph (q)
  "Queue up memory graph information onto Q."
  (let ((memory-info (neato-graph-bar--get-memory-info)))
    (cl-flet ((get-attribute (x) (cdr (assoc x memory-info))))
      (let* ((memory-total (get-attribute "MemTotal"))
	     (memory-free (get-attribute "MemFree"))
	     (memory-buffers (get-attribute "Buffers"))
	     (memory-cached (get-attribute "Cached"))
	     ;; Side note - it appears that there is a difference of 20MB (when
	     ;; I tested) between `(- memory-total memory-free
	     ;; memory-buffers-cache)` and the result of `(- memory-total
	     ;; memory-available)`... no idea *why*. This 20MB is likely kernel
	     ;; memory, I bet. Anyways, my reference, the file 'proc/sysinfo.c'
	     ;; from procps-ng uses the first form, so I do here as well.
	     (memory-used (- memory-total memory-free memory-buffers memory-cached))
	     (memory-graph-alist
	      `((neato-graph-bar-memory-used . ,(/ (float memory-used)
						   memory-total))
		(neato-graph-bar-memory-buffer . ,(/ (float memory-buffers)
						     memory-total))
		(neato-graph-bar-memory-cache . ,(/ (float memory-cached)
						    memory-total))))
	     (memory-end-text (neato-graph-bar--create-storage-status-text
			       memory-used
			       memory-total)))
	(push (list "Mem" memory-graph-alist memory-end-text) (cl-first q))))))

(defun neato-graph-bar--queue-swap-graph (q)
  "Queue up swap graph information onto Q."
  (let ((memory-info (neato-graph-bar--get-memory-info)))
    (cl-flet ((get-attribute (x) (cdr (assoc x memory-info))))
      (let* ((swap-total (get-attribute "SwapTotal"))
	     (swap-free (get-attribute "SwapFree"))
	     (swap-cached (get-attribute "SwapCached"))
	     (swap-used (- swap-total swap-free swap-cached))
	     (swap-graph-alist
	      `((neato-graph-bar-memory-used . ,(/ (float swap-used) swap-total))
		(neato-graph-bar-memory-cache . ,(/ (float swap-cached)
						    swap-total))))
	     (swap-end-text (neato-graph-bar--create-storage-status-text
			     swap-used
			     swap-total)))
	(push (list "Swap" swap-graph-alist swap-end-text) (cl-first q))))))

(defun neato-graph-bar--get-cpu-stats ()
  "Get the difference in the system CPU statistics since last update.

The old information snapshot is moved to `neato-graph-bar--cpu-stats-previous'.

This is obtained from `neato-graph-bar-cpu-stat-file', and made
into key-value pairs as defined by `neato-graph-bar--cpu-field-names'."
  (let* ((cpu-stat-list-strings
	  (mapcar (lambda (x) (split-string x " " t))
		  (with-temp-buffer
		    (insert-file-contents neato-graph-bar-cpu-stat-file)
		    (cl-delete-if-not
		     (lambda (x) (string= (substring x 0 3) "cpu"))
		     (split-string (buffer-string) "\n" t)))))
	 (cpu-stat-list
	  (mapcar (lambda (x)
		    (cons (car x)
			  (cl-pairlis neato-graph-bar--cpu-field-names
				      (mapcar #'string-to-number (cdr x)))))
		  cpu-stat-list-strings))
	 (cpu-diff (copy-tree cpu-stat-list)))
    ;; Account for empty first run
    (unless neato-graph-bar--cpu-stats-previous
      (setq neato-graph-bar--cpu-stats-previous cpu-stat-list))
    (cl-loop for new-cpu in cpu-diff
             for old-cpu in neato-graph-bar--cpu-stats-previous
             do (cl-loop for new-stat in (cdr new-cpu)
                         for old-stat in (cdr old-cpu)
                         do (cl-decf (cdr new-stat) (cdr old-stat))))
    (setq neato-graph-bar--cpu-stats-previous cpu-stat-list)
    cpu-diff))

(defun neato-graph-bar--queue-cpu-graph-helper (cpu q)
  "Push CPU graph information onto Q."
  (cl-flet ((stat-total () (cl-reduce #'+ (cdr cpu) :key #'cdr))
	    (get-attribute (x) (cdr (assoc x (cdr cpu)))))
    (let* ((cpu-name (upcase (car cpu)))
	   (cpu-total (stat-total))
	   (cpu-user (+ (get-attribute 'user)
			(get-attribute 'nice)))
	   (cpu-system (get-attribute 'system))
	   (cpu-irq (+ (get-attribute 'irq)
		       (get-attribute 'softirq)))
	   (cpu-vm (+ (get-attribute 'steal)
		      (get-attribute 'guest)
		      (get-attribute 'guest-nice)))
	   (cpu-graph-alist
	    `((neato-graph-bar-cpu-user . ,(/ (float cpu-user) cpu-total))
	      (neato-graph-bar-cpu-system . ,(/ (float cpu-system) cpu-total))
	      (neato-graph-bar-cpu-interrupt . ,(/ (float cpu-irq) cpu-total))
	      (neato-graph-bar-cpu-vm . ,(/ (float cpu-vm) cpu-total)))))
      ;; First run has cpu-total at 0, which will cause a div-by-0.
      ;; If we find any NaNs, skip drawing
      (unless (cl-find -0.0e+NaN cpu-graph-alist :key #'cdr)
	(push (list cpu-name cpu-graph-alist nil) (cl-first q))))))

(defun neato-graph-bar--queue-cpu-graph (q)
  "Push CPU graph(s) information onto Q."
  (cl-destructuring-bind (unified-cpu . separate-cpus) (neato-graph-bar--get-cpu-stats)
    (if neato-graph-bar-unified-cpu-graph
	(neato-graph-bar--queue-cpu-graph-helper unified-cpu q)
      (dolist (cpu separate-cpus)
	(neato-graph-bar--queue-cpu-graph-helper cpu q)))))

(defun neato-graph-bar--draw-all-graphs ()
  "Draw all available graphs."
  ; Wrap the real graph-queue in another list, so we can 'pass by reference'
  (let ((graph-queue (list nil))
	max-label)
    (neato-graph-bar--queue-cpu-graph graph-queue)
    (neato-graph-bar--queue-memory-graph graph-queue)
    (neato-graph-bar--queue-swap-graph graph-queue)
    (setf max-label (cl-reduce #'max (cl-first graph-queue)
                               :key (lambda (x) (length (cl-first x)))))
    (let ((neato-graph-bar-label-padding max-label))
      (cl-loop for (label graph-info end-text) in (nreverse (cl-first graph-queue)) do
	       (neato-graph-bar--draw-graph label graph-info end-text)
	       (insert "\n")))))

(provide 'neato-graph-bar)

;;; neato-graph-bar.el ends here
