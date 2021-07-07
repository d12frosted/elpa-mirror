;;; org-random-todo.el --- show a random TODO (with alert) every so often

;; Copyright (C) 2013-2019 Kevin Brubeck Unhammer

;; Author: Kevin Brubeck Unhammer <unhammer@fsfe.org>
;; Version: 0.5.3
;; Package-Version: 20190214.2057
;; Package-Commit: a019c7186ec60c8c7c3657914cdce029811cf4e0
;; Homepage: https://github.com/unhammer/org-random-todo
;; Package-Requires: ((emacs "24.3") (alert "1.3"))
;; Keywords: org todo notification calendar

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3 of the License, or
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

;; Show a random TODO from your org-agenda-files every so often.
;; Requires org-element, which was added fairly recently to org-mode
;; (tested with org-mode version 7.9.3f and later).

;;; Code:

(require 'org-element)
(require 'alert)
(require 'cl-lib)
(unless (fboundp 'cl-mapcan) (defalias 'cl-mapcan 'mapcan))

(defgroup org-random-todo nil
  "Options for showing random org-mode TODO's."
  :tag "Org Random Todo"
  :group 'org)

(defcustom org-random-todo-files nil
  "Files to grab TODO items from.
If nil, use `org-agenda-files'.  See that variable for documentation."
  :group 'org-random-todo
  :type '(choice
	  (repeat :tag "List of files and directories" file)
	  (file :tag "Store list in a file\n" :value "~/.agenda_files")))

(defcustom org-random-todo-include-scheduled nil
  "If non-nil, also include SCHEDULED elements.
These are typically less interesting to show randomly, since
they're in your agenda already."
  :group 'org-random-todo
  :type 'bool)

(defcustom org-random-todo-include-deadline nil
  "If non-nil, also include DEADLINE elements.
These are typically less interesting to show randomly, since
they're in your agenda already."
  :group 'org-random-todo
  :type 'bool)

(defcustom org-random-todo-skip-keywords nil
  "List of TODO keywords to skip."
  :group 'org-random-todo
  :type '(list string))

(defcustom org-random-todo-notification-hook nil
  "Hook run after successfully showing a random TODO notification."
  :group 'org-random-todo
  :type 'hook)

(defvar org-random-todo--cache nil)

(defun org-random-todo--planning-has-prop (hl prop)
  "Return nil unless HL has a PROP property in the 'planning part of 'section."
  (cl-mapcan (lambda (l) (plist-get l prop))
             (cdr (assoc 'planning
                         (cdr (assoc 'section
                                     hl))))))

(defun org-random-todo--deadlinep (hl)
  "Return nil unless HL has a \"DEADLINE\" property."
  (org-random-todo--planning-has-prop hl :deadline))

(defun org-random-todo--scheduledp (hl)
  "Return nil unless HL has a \"SCHEDULED\" property."
  (org-random-todo--planning-has-prop hl :scheduled))

(defun org-random-todo--update-cache ()
  "Update the cache of TODO's."
  (let* ((org-agenda-files (or org-random-todo-files org-agenda-files))
         (files (org-agenda-files)))
    (setq org-random-todo--cache
          (cl-mapcan
           (lambda (file)
             (when (file-exists-p file)
               (with-current-buffer (org-get-agenda-file-buffer file)
                 (org-element-map (org-element-parse-buffer)
                     'headline
                   (lambda (hl)
                     (when (and (org-element-property :todo-type hl)
                                (or org-random-todo-include-deadline
                                    (not (org-random-todo--deadlinep hl)))
                                (or org-random-todo-include-scheduled
                                    (not (org-random-todo--scheduledp hl)))
                                (not (member (org-element-property :todo-keyword hl)
                                             org-random-todo-skip-keywords))
                                (not (equal 'done (org-element-property :todo-type hl))))
                       (cons file hl)))))))
           files))))

(defun org-random-todo--headline-to-msg (elt)
  "Create a readable alert-message of this TODO headline.
The `ELT' argument is an org element, see `org-element'."
  (format "%s: %s"
          (org-element-property :todo-keyword elt)
          (org-element-property :raw-value elt)))

(defvar org-random-todo--current nil)

;;;###autoload
(defun org-random-todo-goto-current ()
  "Go to the file/position of last shown TODO.
Find one if none have been shown yet."
  (interactive)
  (unless org-random-todo--current
    (org-random-todo))
  (find-file (car org-random-todo--current))
  (goto-char (cdr org-random-todo--current))
  (org-reveal))

;;;###autoload
(defun org-random-todo-goto-new ()
  "Go to the file/position of new random TODO."
  (interactive)
  (pcase (org-random-todo--get)
    (`(,path . ,elt)
     (find-file path)
     (goto-char (org-element-property :begin elt))
     (org-reveal))))

(defun org-random-todo--get ()
  "Return a random TODO path and org element from your agenda files.
See `org-random-todo-files' to change what files are crawled.
Runs `org-random-todo--update-cache' if TODO's are out of date."
  (unless org-random-todo--cache
    (org-random-todo--update-cache))
  (with-temp-buffer
    (nth (random (length org-random-todo--cache))
         org-random-todo--cache)))

;;;###autoload
(defun org-random-todo ()
  "Show a random TODO notification from your agenda files.
See `org-random-todo-files' to change what files are crawled.
Runs `org-random-todo--update-cache' if TODO's are out of date."
  (interactive)
  (unless (minibufferp)	 ; don't run if minibuffer is asking something
    (pcase (org-random-todo--get)
      (`(,path . ,elt)
       (setq org-random-todo--current
             (cons path (org-element-property :begin elt)))
       (alert (org-random-todo--headline-to-msg elt)
              :title (file-name-base path)
              :severity 'trivial
              :mode 'org-mode
              :category 'random-todo
              :id 'org-random-todo     ; replace old messages
              :buffer (find-buffer-visiting path))
       (run-hooks 'org-random-todo-notification-hook)))))

(defvar org-random-todo-how-often 600
  "Show a message every this many seconds.
This happens simply by requiring `org-random-todo', as long as
this variable is set to a number.")


(defvar org-random-todo-cache-idletime 600
  "Update cache after being idle this many seconds.
See `org-random-todo--update-cache'; only happens if this variable is
a number.")

(defvar org-random-todo--timers nil
  "List of timers that need to be cancelled on exiting org-random-todo-mode.")

(defun org-random-todo-unless-idle ()
  "Only run `org-random-todo' if we're not idle.
This is to avoid getting a bunch of notification build-up after
e.g. a sleep/resume."
  (when (or (not (current-idle-time))
            (< (time-to-seconds (current-idle-time))
               org-random-todo-how-often))
    (org-random-todo)))

(defun org-random-todo--setup ()
  "Set up idle timers."
  (org-random-todo--teardown)
  (when (numberp org-random-todo-how-often)
    (add-to-list 'org-random-todo--timers
                 (run-with-timer org-random-todo-how-often
                                 org-random-todo-how-often
                                 'org-random-todo-unless-idle)))
  (when (numberp org-random-todo-cache-idletime)
    (add-to-list 'org-random-todo--timers
                 (run-with-idle-timer org-random-todo-cache-idletime
                                      'on-each-idle
                                      'org-random-todo--update-cache))))

(defun org-random-todo--teardown ()
  "Remove idle timers."
  (mapc #'cancel-timer (cl-remove-if nil org-random-todo--timers))
  (setq org-random-todo--timers nil))

;;;###autoload
(define-minor-mode org-random-todo-mode
  "Show a random TODO every so often"
  :global t
  (if org-random-todo-mode
      (org-random-todo--setup)
    (org-random-todo--teardown)))


(provide 'org-random-todo)
;;; org-random-todo.el ends here
