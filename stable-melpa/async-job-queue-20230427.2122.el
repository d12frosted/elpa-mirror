;;; async-job-queue.el --- Dispatch queue of async jobs to a fixed number of slots    -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Onnie Winebarger

;; Author: Onnie Winebarger
;; Copyright (C) 2023 by Onnie Lynn Winebarger <owinebar@gmail.com>
;; Keywords: extensions, lisp
;; Package-Version: 20230427.2122
;; Package-Commit: eeafcce7f960305666b2a51aec55cc6333f6af1b
;; Version: 0.1
;; Package-Requires: ((async "1.4") (emacs "25.1") (queue "0.2"))
;; URL: https://github.com/owinebar/emacs-async-job-queue

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Provide a queue for dispatching jobs asynchronously
;; while maintaining a fixed maximum number of active jobs
;;
;; Lisp code can use this to create an arbitrary number of jobs
;; to be run asynchronously without immediately starting those
;; jobs.  The default number of jobs allowed to run simultaneously
;; is set to the number of processors reported by (num-processors)
;; when available, or 1 otherwise

;;; Code:

(require 'cl-lib)
(require 'async)
(require 'queue)

(define-error 'async-job-queue-slot-already-free
  "Slot in job queue is already free")
(define-error 'async-job-queue--table-no-free-slot
  "No free slots in job queue")

(defgroup async-job-queue nil
  "Customization group for async-job-queue package."
  :group 'lisp)
  
(defcustom async-job-queue-default-size
  (if (and (>= emacs-major-version 28)
	   (fboundp 'num-processors))
      (num-processors)
    1)
  "Default number of slots in a job queue."
  :type 'natnum
  :group 'async-job-queue)

(defmacro async-job-queue--call-with-warn (&rest app-form)
  "Perform funcall of user callback APP-FORM and display errors as warnings."
  (let ((err-sym (gensym "err")))
    `(condition-case ,err-sym
	 (funcall ,@app-form)
       (error
	(display-warning
	 :error
	 (format "%s: %S" (car ,err-sym) (cdr ,err-sym)))))))
    
(cl-defstruct (async-job-queue--table
	       (:constructor async-job-queue--table-create)
	       (:copier async-job-queue--table-copy))
  "Structure describing the table of active jobs and associated lists.
  Slots:
   `id' Symbol for identification in reporting
   `slots' vector of active descriptors
   `active' when non-nil, jobs will be started as soon as a slot is open
            when nil, jobs will simply be pushed onto the queue
   `in-use' number of slots in use
   `free' number of slots free
   `queue' FIFO collection of jobs to be started when a slot is available
   `on-empty' continuation to run when no slots are in use and
              the queue is empty
   `on-activate' hook for functions to call when table is activated
   `on-deactivate' hook for functions to call when table is deactivated
   `first-used' index of the first entry in the list of slots in use
   `last-used' index of the last entry in the list of slots in use
   `first-free' index of first entry in the list of slots not in use
   `last-free'  index of last entry in list of slots free
   `freq'  time between polling in use entries for completed jobs
   `timer' non-nil when jobs are being monitored"
  id
  slots
  (active t)
  in-use
  free
  queue
  on-empty
  on-activate
  on-deactivate
  first-used
  last-used
  first-free
  last-free
  freq
  timer)


(cl-defstruct (async-job-queue--queue
	       (:constructor async-job-queue--queue-create)
	       (:copier async-job-queue--queue-copy))
  head
  last)

(cl-defstruct (async-job-queue--slot
	       (:constructor async-job-queue--slot-create)
	       (:copier async-job-queue--slot-copy))
  "Structure for tracking running jobs.
  Slots:
   `table' job table this slot is contained by
   `index' index of slot in table
   `next' Integer of next entry in list this entry is part of (free or in-use)
   `prev' Integer of previous entry in list this entry is part of
   `job' An async-job-queue--job struct or nil if free"
  table
  index
  next
  prev
  job)


(cl-defstruct (async-job-queue--job
	       (:constructor async-job-queue--job-create)
	       (:copier async-job-queue--job-copy))
  "Structure for jobs unboxed has started.  Callbacks take job struct as first argument.
  Slots:
   `id' Identifier
   `table' job-queue structure managing this job
   `run-slot' when running, index of slot in active table, else nil
   `program' Elisp program run in the job
   `started' start time
   `max-time' maximum wall clock time to allow run, nil for no limit
   `future' object representing the async process
   `ended' time result was ready or job terminated
   `returned' t if result is set by the return value of program, nil otherwise
   `result' the value returned by program, if it completed
   `dispatched' callback function to run immediately after starting the job
   `succeed' callback function to use when results are available
   `timeout' callback function to use when process times out
   `quit' callback function to use when job is canceled"
  id
  table
  run-slot
  program
  started
  max-time
  future
  ended
  returned
  result
  dispatched
  succeed
  timeout
  quit)

(defun async-job-queue--job-slot (job)
  "Return the slot for JOB if it is running, nil otherwise."
  (let ((idx (async-job-queue--job-run-slot job)))
    (when idx
      (aref (async-job-queue--table-slots (async-job-queue--job-table job))
	    idx))))

(defun async-job-queue-displayable-table (tbl)
  "Minimal description of job queue TBL."
  (if tbl
      `(async-job-queue--table
	(id ,(async-job-queue--table-id tbl))
	(slots ,(length (async-job-queue--table-slots tbl)))
	(active ,(async-job-queue--table-active tbl))
	(in-use ,(async-job-queue--table-in-use tbl)
		,(async-job-queue--table-first-used tbl)
		,(async-job-queue--table-last-used tbl)
		,(async-job-queue--slots-in-use-list tbl))
	(free ,(async-job-queue--table-free tbl)
	      ,(async-job-queue--table-first-free tbl)
	      ,(async-job-queue--table-last-free tbl)
	      ,(async-job-queue--slots-free-list tbl))
	(queue ,(queue-length (async-job-queue--table-queue tbl)))
	(on-empty ,(and (async-job-queue--table-on-empty tbl) t))
	(freq ,(async-job-queue--table-freq tbl))
	(timer ,(and (async-job-queue--table-timer tbl) (async-job-queue--timer-info (async-job-queue--table-timer tbl)))))
    '(async-job-queue--table nil)))
  

(defun async-job-queue-displayable-slot (slot)
  "Minimal description of queue slot SLOT."
  (if slot
      `(async-job-queue--slot
	(table ,(and (async-job-queue--slot-table slot) (async-job-queue--table-id (async-job-queue--slot-table slot))))
	(index ,(async-job-queue--slot-index slot))
	(next ,(async-job-queue--slot-next slot))
	(prev ,(async-job-queue--slot-prev slot))
	(job ,(and (async-job-queue--slot-job slot) (async-job-queue--job-id (async-job-queue--slot-job slot)))))
    '(async-job-queue--slot nil)))

(defun async-job-queue-displayable-job (job)
  "Minimal description of JOB."
  (if job
      `(async-job-queue--job
	(id ,(async-job-queue--job-id job))
	(table ,(and (async-job-queue--job-table job) (async-job-queue--table-id (async-job-queue--job-table job))))
	(run-slot ,(async-job-queue--job-run-slot job))
	(started ,(async-job-queue--job-started job))
	(ended ,(async-job-queue--job-ended job))
	(max-time ,(async-job-queue--job-max-time job))
	(future ,(async-job-queue--job-future job))
	(returned ,(async-job-queue--job-returned job))
	(result ,(async-job-queue--job-result job))
	(dispatched ,(and (async-job-queue--job-dispatched job) t))
	(succeed ,(and (async-job-queue--job-succeed job) t))
	(timeout ,(and (async-job-queue--job-timeout job) t))
	(quit ,(and (async-job-queue--job-quit job) t)))
    `(async-job-queue--job nil)))

(defun async-job-queue--expr-to-async (e)
  "Convert expression E to thunk as necessary for `async-start'."
  (unless (or (and (consp e)
		   (or (eq (car e) 'lambda)
		       (eq (car e) 'function)))
	      (and (not (symbolp e))
		   (functionp e)))
    (setq e `(lambda () ,e)))
  e)

(defun async-job-queue--slots-in-use-list (tbl)
  "Indexes of slots in in-use list of TBL."
  (let ((slots (async-job-queue--table-slots tbl))
	(idx (async-job-queue--table-first-used tbl))
	used next)
    (while idx
      (push idx used)
      (setq next (async-job-queue--slot-next (aref slots idx)))
      (if (member next used)
	  (progn
	    (push next used)
	    (setq idx nil))
	(setq idx next)))
    (nreverse used)))

(defun async-job-queue--slots-free-list (tbl)
  "Indexes of slots in free list of TBL."
  (let ((slots (async-job-queue--table-slots tbl))
	(idx (async-job-queue--table-first-free tbl))
	free next)
    (while idx
      (push idx free)
      (setq next (async-job-queue--slot-next (aref slots idx)))
      (if (member next free)
	  (progn
	    (push next free)
	    (setq idx nil))
	(setq idx next)))
    (nreverse free)))

(defvar async-job-queue--num-tables-created 0
  "Number of job queues created.")

(defun async-job-queue-make-job-queue (freq &optional N on-empty inactive on-activate on-deactivate id)
  "Create an async job queue.
Arguments:
   FREQ - frequency of polling for job completion
   N - number of slots in job queue
   ON-EMPTY - continuation to call when queue is activated and empty
   INACTIVE - if non-nil, create the queue in a deactivated state
   ON-ACTIVATE - hook for functions to call when table is activated
   ON-DEACTIVATE - hook for functions to call when table is deactivated
   ID - A symbol used to identify the queue in `displayable' summaries of
        data structures"
  (unless N
    (setq N async-job-queue-default-size))
  (cl-incf async-job-queue--num-tables-created)
  (unless id
    (setq id (intern (format "async-job-queue-table-%S"
			     async-job-queue--num-tables-created))))
  (let ((tbl (async-job-queue--table-create
	      :id id
	      :slots (make-vector N nil)
	      :active (not inactive)
	      :in-use 0
	      :free N
	      :queue (make-queue)
	      :on-empty on-empty
	      :on-activate on-activate
	      :on-deactivate on-deactivate
	      :first-used nil
	      :last-used nil
	      :first-free 0
	      :last-free (1- N)
	      :freq freq))
	(i 0)
	(prev nil)
	(next 1)
	slots a)
    (setq slots (async-job-queue--table-slots tbl))
    (while (< i N)
      ;; note the nil job indicates the entry is on the free list
      ;; a non-nil job indicates the entry is on the in-use list
      (setq a (async-job-queue--slot-create
	       :table tbl
	       :index i
	       :next next
	       :prev prev
	       :job nil)
	    prev i
	    i next)
      (cl-incf next)
      (aset slots prev a))
    (setf (async-job-queue--slot-next a) nil)
    tbl))

;; The slots associated with a table are fixed at table creation
;; This simply moves the first one from the free list to the last
;; entry on the in-use list
(defun async-job-queue--alloc-slot (tbl)
  "Move first free slot of TBL to the end of the in-use list.
Return the allocated slot."
  (when (= (async-job-queue--table-free tbl) 0)
    (signal 'async-job-queue--table-no-free-slot tbl))
  ;; (message "Allocating slot in %S"
  ;; 	   (async-job-queue-displayable-table tbl))
  (let ((first-free (async-job-queue--table-first-free tbl))
	(last-used  (async-job-queue--table-last-used tbl))
	(slots (async-job-queue--table-slots tbl))
	(n-in-use (async-job-queue--table-in-use tbl))
	(n-free (async-job-queue--table-free tbl))
	next-free a b)
    (setq a (aref slots first-free)
	  next-free (async-job-queue--slot-next a))
    (setf (async-job-queue--table-first-free tbl) next-free)
    (when next-free
      (setq b (aref slots next-free))
      ;; this is first free now
      (setf (async-job-queue--slot-prev b) nil))
    ;; a will be last used
    (setf (async-job-queue--slot-next a) nil)
    ;; prev field of a is nil by definition of first free
    (setf (async-job-queue--slot-prev a) last-used)
    (unless next-free
      (setf (async-job-queue--table-last-free  tbl) nil))
    (setf (async-job-queue--table-free tbl) (1- n-free))
    (setf (async-job-queue--table-in-use tbl) (1+ n-in-use))
    (unless last-used
      (setf (async-job-queue--table-first-used tbl) first-free))
    (when last-used
      (setq b (aref slots last-used))
      ;; next field of b is nil by definition of last used
      (setf (async-job-queue--slot-next b) first-free))
    (setf (async-job-queue--table-last-used tbl) first-free)
    ;; maintain invariant that nil job is free list
    (setf (async-job-queue--slot-job a) t)
    ;; (message "Allocated slot in %S"
    ;; 	     (async-job-queue-displayable-table tbl))
    a))

;; Frees an allocated slot
;; returns job from freed slot
(defun async-job-queue--reclaim-slot (s)
  "Move slot S from the in-use list to the free list.
Remove slot S from the in-use list and append
to the free list.  Return the job previously
associated with S"
  ;; (message "Reclaiming slot %S" (async-job-queue--slot-index s))
  (when (null (async-job-queue--slot-job s))
    (signal 'async-job-queue-slot-already-free s))
  ;; (message "Reclaiming slot %S"
  ;; 	   (async-job-queue-displayable-slot s))
  (let ((tbl (async-job-queue--slot-table s))
	(prev-used (async-job-queue--slot-prev s))
	(next-used (async-job-queue--slot-next s))
	(job (async-job-queue--slot-job s))
	(idx (async-job-queue--slot-index s))
	first-free last-free slots
	n-in-use n-free
	a b)
    ;; (message "Reclaiming slot %S job %S"
    ;; 	     (async-job-queue--slot-index s)
    ;; 	     (async-job-queue-displayable-job job))
    ;; (message "Reclaiming slot %S table %S"
    ;; 	     (async-job-queue--slot-index s)
    ;; 	     (async-job-queue-displayable-table tbl))
    (setf (async-job-queue--slot-job s) nil)
    (setq first-free (async-job-queue--table-first-free tbl)
	  last-free (async-job-queue--table-last-free tbl)
	  slots (async-job-queue--table-slots tbl)
	  n-in-use (async-job-queue--table-in-use tbl)
	  n-free (async-job-queue--table-free tbl))
    ;; remove s from the in-use list
    (unless prev-used
      (setf (async-job-queue--table-first-used tbl) next-used))
    (unless next-used
      (setf (async-job-queue--table-last-used tbl) prev-used))
    (when prev-used
      (setq a (aref slots prev-used)))
    (when next-used
      (setq b (aref slots next-used)))
    (when a
      (setf (async-job-queue--slot-next a) next-used))
    (when b
      (setf (async-job-queue--slot-prev b) prev-used))
    (setf (async-job-queue--table-in-use tbl) (1- n-in-use))
    (setf (async-job-queue--table-free tbl) (1+ n-free))
    (unless first-free
      (setf (async-job-queue--table-first-free tbl) idx))
    (when last-free
      (setq a (aref slots last-free))
      (setf (async-job-queue--slot-next a) idx))
    (setf (async-job-queue--table-last-free tbl) idx)
    (setf (async-job-queue--slot-next s) nil)
    ;; (message "Reclaimed slot %S in table %S"
    ;; 	     (async-job-queue-displayable-slot s)
    ;; 	     (async-job-queue-displayable-table tbl))
    job))

(defun async-job-queue--dispatch (tbl &optional job)
  "Dispatch job JOB into first free slot of TBL.
If JOB is nil, dispatch first job from queue of pending jobs."
  (unless job
    (let ((q (async-job-queue--table-queue tbl)))
      (setq job (and (not (queue-empty q))
		     (queue-dequeue q)))))
  (when job
    (let ((s (async-job-queue--alloc-slot tbl))
	  (on-dispatch (async-job-queue--job-dispatched job))
	  (on-finish (async-job-queue--job-succeed job)))
      ;;(message "Allocated slot %S" (async-job-queue--slot-index s))
      (setf (async-job-queue--slot-job s) job)
      ;; (message "Set job for slot %S %S"
      ;; 	       (async-job-queue--slot-index s)
      ;; 	       (async-job-queue--job-id job))
      (setf (async-job-queue--job-run-slot job)
	    (async-job-queue--slot-index s))
      (setf (async-job-queue--job-started job) (current-time))
      (let ((f (async-start
		(async-job-queue--expr-to-async
		 (async-job-queue--job-program job))
		(lambda (v)
		  ;; (message "Async for job %S returned %S" (async-job-queue--job-id job) v)
		  (async-job-queue--cleanup-job job s)
		  ;; (message "Cleaned up job %S" (async-job-queue--job-id job))
		  (setf (async-job-queue--job-returned job) t)
		  (setf (async-job-queue--job-result job) v)
		  ;; do this before ensuring queue in case this
		  ;; emptied the table
		  (when on-finish
		    (async-job-queue--call-with-warn on-finish job v))
		  (async-job-queue--ensure-queue-running tbl)))))
	(setf (async-job-queue--job-future job) f)
	(when on-dispatch
	  (async-job-queue--call-with-warn on-dispatch job)))))
  job)

(defun async-job-queue-schedule-job (tbl prog &optional id on-dispatch on-finish max-time on-timeout on-quit)
  "Add a job to TBL to run PROG asynchronously.
ID - symbol used in displayable structure summaries
ON-DISPATCH - callback called when job is started
ON-FINISH - continuation to call after job completes normally
MAX-TIME - seconds (wall-clock) to allow job to run before terminating
           as a time-out
ON-TIMEOUT - continuation to call if job is terminated due to timeout
ON-QUIT - continuation to call if job is cancelled"
  (let ((job (async-job-queue--job-create
	      :id id
	      :table tbl
	      :program prog
	      :max-time max-time
	      :dispatched on-dispatch
	      :succeed on-finish
	      :timeout on-timeout
	      :quit on-quit))
	(q (async-job-queue--table-queue tbl))
	(active (async-job-queue--table-active tbl))
	(n-in-use (async-job-queue--table-in-use tbl)))
    (if (or (not active)
	    (not (queue-empty q))
	    (= (async-job-queue--table-free tbl) 0))
	(queue-enqueue q job)
      ;; optimization
      (async-job-queue--dispatch tbl job))
    ;; timer might not be running if the table was empty
    ;; before this
    (when (and active (= n-in-use 0))
      ;; (message "Ensuring job queue running for job id %S" id)
      (async-job-queue--ensure-queue-running tbl))
    job))

(defun async-job-queue--dispatch-queued (tbl)
  "Dispatch jobs until TBL is full or queue of pending jobs is empty."
  (when (async-job-queue--table-active tbl)
    (let ((q (async-job-queue--table-queue tbl)))
      (while (and (not (queue-empty q))
		  (> (async-job-queue--table-free tbl) 0))
	(async-job-queue--dispatch tbl)))))

(defun async-job-queue--terminate-job-process (job fut)
  "Kill the process associated with JOB running in FUT."
  (condition-case nil
      (delete-process fut)
    (error
     (display-warning
      :warning
      (format "Could not kill process %S for timed-out job %S" fut job)))))
  
(defun async-job-queue--cleanup-job (job slot)
  "Set post-run values for fields of JOB in SLOT."
  (setf (async-job-queue--job-future job) nil)
  (setf (async-job-queue--job-table job) nil)
  (setf (async-job-queue--job-run-slot job) nil)
  (setf (async-job-queue--job-ended job) (current-time))
  (when slot (async-job-queue--reclaim-slot slot)))
  
(defun async-job-queue--handle-finished-job (slot job v)
  "Clean up SLOT in TBL that ran JOB and returned value V."
  (async-job-queue--cleanup-job job slot)
  (setf (async-job-queue--job-returned job) t)
  (setf (async-job-queue--job-result job) v)
  (async-job-queue--call-with-warn (async-job-queue--job-succeed job) job v))

(defun async-job-queue--handle-terminated-job (slot job fut)
  "Clean up SLOT in TBL that ran JOB as FUT and timed out."
  (async-job-queue--terminate-job-process job fut)
  (async-job-queue--cleanup-job job slot)
  (setf (async-job-queue--job-result job) nil)
  (async-job-queue--call-with-warn (async-job-queue--job-timeout job) job))

(defun async-job-queue-cancel-job (job)
  "Cancel JOB which may or may not have started running."
  (when (async-job-queue--job-future job)
    (async-job-queue--terminate-job-process job (async-job-queue--job-future job)))
  (async-job-queue--cleanup-job job (async-job-queue--job-slot job))
  (async-job-queue--call-with-warn (async-job-queue--job-quit job) job))

(defun async-job-queue-cancel-job-queue (tbl)
  "Cancel all jobs associated with job queue TBL."
  ;; first the queued jobs, if any
  (let ((q (async-job-queue--table-queue tbl)))
    (while (not (queue-empty q))
      (async-job-queue-cancel-job (queue-dequeue q))))
  (let ((idx (async-job-queue--table-first-used tbl))
	(slots (async-job-queue--table-slots tbl))
	a)
    (while idx
      (setq a (aref slots idx)
	    idx (async-job-queue--slot-next a))
      (async-job-queue-cancel-job (async-job-queue--slot-job a))))
  (let ((timer (async-job-queue--table-timer tbl)))
    (when timer
      (cancel-timer timer)
      (setf (async-job-queue--table-timer tbl) nil))))

(defun async-job-queue--timer-info (tmr)
  "Produce non-recursive display of timer TMR."
  (when tmr
    `[timer (triggered ,(timer--triggered tmr))
	    (high-seconds ,(timer--high-seconds tmr))
	    (low-seconds ,(timer--low-seconds tmr))
	    (micro-seconds ,(timer--usecs tmr))
	    (pico-seconds ,(timer--psecs tmr))
	    (repeat-delay ,(timer--repeat-delay tmr))
	    (function ,(timer--function tmr))
	    (idle-delay ,(timer--idle-delay tmr))
	    (integral-multiple
	     ,(if (and (>= emacs-major-version 28)
		       (fboundp 'timer--integral-multiple))
		  (timer--integral-multiple tmr)
		nil))]))

(defun async-job-queue--make-timer (freq rpt fxn &rest args)
  "Make a timer.
FREQ - Initial delay and frequency in seconds or time stamp
RPT - Non-nil to repeat every FREQ
FXN - timer function to call
ARGS - arguments to supply to FXN"
  (if (numberp freq)
      (apply #'run-with-timer freq
	     (and rpt freq) fxn args)
    (apply #'run-at-time freq (and rpt freq) fxn args)))

(defun async-job-queue--ensure-queue-running (tbl)
  "Manage administratvia for TBL.
Ensures queued jobs are run as slots become available, if queue is active.
Sets up a timer if one is needed, cancels an existing one if it is not."
  ;; (message "ajq--ensure-queue-running %S" (async-job-queue-displayable-table tbl))
  (let ((on-empty (async-job-queue--table-on-empty tbl))
	(freq (async-job-queue--table-freq tbl))
	(timer (async-job-queue--table-timer tbl))
	(active (async-job-queue--table-active tbl)))
    (when active
      ;; (message "ajq--ensure-queue-running active")
      (async-job-queue--dispatch-queued tbl)
      ;; (message "ajq--ensure-queue-running dispatched queued")
      ;; (message "ajq--ensure-queue-running timer %S" (and timer t))
      (when (and timer
		 on-empty
		 (= (async-job-queue--table-in-use tbl) 0))
	;; (message "ajq--ensure-queue-running calling on-empty")
	(async-job-queue--call-with-warn on-empty tbl)))
    (if (= (async-job-queue--table-in-use tbl) 0)
	;; this is correct whether or not the job queue is active
	(when timer
	  ;; (message "ajq--ensure-queue-running cancelling timer")
	  (cancel-timer timer)
	  (setq timer nil)
	  (setf (async-job-queue--table-timer tbl) nil))
      (unless (or (not active) timer)
	;; (message "ajq--ensure-queue-running setting up timer")
	(setq timer (async-job-queue--make-timer freq freq #'async-job-queue--process-queue tbl))
	;; (message "ajq--ensure-queue-running timer %S" (async-job-queue--timer-info timer))
	(setf (async-job-queue--table-timer tbl) timer)))
    timer))

  
(defun async-job-queue--process-queue (tbl)
  "Check slots of TBL for completed jobs.
Poll running jobs in queue TBL for completion or timeout.
Dispatch pending jobs as slots become available when TBL is active."
  ;; (message "ajq--process-queue %S" (async-job-queue-displayable-table tbl))
  (let ((idx (async-job-queue--table-first-used tbl))
	(slots (async-job-queue--table-slots tbl))
	slot job fut t0 t1 maxt dt)
    (while idx
      ;; (message "Processing slot index %S" idx)
      (setq slot (aref slots idx))
      (setq job (async-job-queue--slot-job slot))
      (setq fut (async-job-queue--job-future job))
      (setq maxt (async-job-queue--job-max-time job))
      (when (async-ready fut)
	;; (message "Future ready %S" fut)
	(async-job-queue--handle-finished-job slot job (async-get fut))
	(setq fut nil))
      (when (and maxt fut)
	;; (message "Future not ready %S checking maxt %S" fut maxt)
	(setq t0 (async-job-queue--job-started job))
	(setq t1 (current-time))
	(setq dt (time-subtract t1 t0))
	(when (<= maxt (float-time dt))
	  (async-job-queue--handle-terminated-job slot job fut)))
      (setq idx (async-job-queue--slot-next slot)))
    (async-job-queue--ensure-queue-running tbl)))

(defun async-job-queue-add-deactivation (tbl callback)
  "Add CALLBACK to on-deactivate hook of job queue TBL."
  (push callback (async-job-queue--table-on-deactivate tbl)))

(defun async-job-queue-add-activation (tbl callback)
  "Add CALLBACK to on-activate hook of job queue TBL."
  (push callback (async-job-queue--table-on-activate tbl)))

(defun async-job-queue-deactivate-queue (tbl &optional key)
  "Deactivate job queue TBL with KEY.
Running jobs will finish.  Queued jobs will remain pending until the
queue is reactivated.  Functions on the deactivation hook will be
called with TBL and KEY as arguments."
  (setf (async-job-queue--table-active tbl) nil)
  (let ((ls (async-job-queue--table-on-deactivate tbl)))
    (while ls
      (funcall (pop ls) tbl key))))

(defun async-job-queue-activate-queue (tbl &optional key)
  "Activate job queue TBL with KEY.
Start dispatching jobs and monitoring for job completion."
  (setf (async-job-queue--table-active tbl) t)
  (let ((ls (async-job-queue--table-on-activate tbl)))
    (while ls
      (funcall (pop ls) tbl key)))
  (async-job-queue--ensure-queue-running tbl))


(provide 'async-job-queue)

;;; async-job-queue.el ends here
;; Local Variables:
;; read-symbol-shorthands: (("ajq-" . "async-job-queue-")("ajqt-" . "async-job-queue-test-"))
;; End:

;; Local Variables:
;; read-symbol-shorthands: (("ajq-" . "async-job-queue-")("q-" . "queue-"))
;; End:

;; Local Variables:
;; read-symbol-shorthands: (("ajq-" . "async-job-queue-"))
;; End:
