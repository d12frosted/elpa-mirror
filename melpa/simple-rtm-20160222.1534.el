;;; simple-rtm.el --- Interactive Emacs mode for Remember The Milk

;; Copyright (C) 2011, 2012 Moritz Bunkus

;; Author: Moritz Bunkus <morit@bunkus.org>
;; Created: April 3, 2011
;; Version: 0.3
;; Package-Version: 20160222.1534
;; Package-Commit: 37c5feffea7c9b571279b6f549d06cf9c0720273
;; Package-Requires: ((rtm "0.1")(dash "2.0.0"))
;; Keywords: remember the milk productivity todo

;; This product uses the Remember The Milk API but is not endorsed or
;; certified by Remember The Milk

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the MIT license (see COPYING).

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

(require 'rtm)
(require 'dash)
;; (require 'pp)
(require 'cl)

(defgroup simple-rtm nil
  "A simple interface to Remember The Milk."
  :prefix "simple-rtm-"
  :group 'tools)

(defcustom simple-rtm-completing-read-function 'ido-completing-read
  "Function to be called when requesting input from the user."
  :group 'simple-rtm
  :type '(radio (function-item ido-completing-read)
		(function-item iswitchb-completing-read)
		(function :tag "Other")))

(defcustom simple-rtm-sort-order 'date-priority-name
  "Attributes that tasks are sorted by."
  :group 'simple-rtm
  :type '(radio (function-item date-priority-name)
		(function-item priority-date-name)))

(defcustom simple-rtm-use-default-list-for-new-tasks t
  "Add the list at point to the task spec if no list is given when adding tasks."
  :group 'simple-rtm
  :type 'boolean)

(defcustom simple-rtm-mode-line-format
  "[due:%da]"
  "Control string formatting the string to display in the mode line.
Ordinary characters in the control string are printed as-is, while
conversion specifications introduced by a `%' character in the control
string are substituted as follows:
%t Total number of tasks
%p1 Number of tasks with priority 1
%p2 Number of tasks with priority 2
%p3 Number of tasks with priority 3
%pn Number of tasks without a priority
%d1 Number of due tasks with priority 1
%d2 Number of due tasks with priority 2
%d3 Number of due tasks with priority 3
%dn Number of due tasks without a priority
%da Number of due tasks regardless of their priority"
  :group 'simple-rtm
  :type '(choice string (const nil)))

(defgroup simple-rtm-faces nil
  "Customize the appearance of SimpleRTM"
  :prefix "simple-rtm-"
  :group 'faces
  :group 'simple-rtm)

(defface simple-rtm-list
  '((((class color) (background light))
     :foreground "#696969")
    (((class color) (background dark))
     :foreground "#ffffff"))
  "Face for lists."
  :group 'simple-rtm-faces)

(defface simple-rtm-smart-list
  '((((class color) (background light))
     :foreground "#00bbff")
    (((class color) (background dark))
     :foreground "#00bbff"))
  "Face for smart lists."
  :group 'simple-rtm-faces)

(defface simple-rtm-task
  '((((class color) (background light))
     :foreground "#e5e5e5")
    (((class color) (background dark))
     :foreground "#e5e5e5"))
  "Face for task names. Other task faces inherit from it."
  :group 'simple-rtm-faces)

(defface simple-rtm-task-priority-1
  '((((class color) (background light))
     :foreground "#ffd700" :inherit simple-rtm-task)
    (((class color) (background dark))
     :foreground "#ffd700" :inherit simple-rtm-task))
  "Face for priority 1 tasks."
  :group 'simple-rtm-faces)

(defface simple-rtm-task-priority-2
  '((((class color) (background light))
     :foreground "#00ffff" :inherit simple-rtm-task)
    (((class color) (background dark))
     :foreground "#00ffff" :inherit simple-rtm-task))
  "Face for priority 2 tasks."
  :group 'simple-rtm-faces)

(defface simple-rtm-task-priority-3
  '((((class color) (background light))
     :foreground "#0033ff" :inherit simple-rtm-task)
    (((class color) (background dark))
     :foreground "#0033ff" :inherit simple-rtm-task))
  "Face for priority 3 tasks."
  :group 'simple-rtm-faces)

(defface simple-rtm-task-duedate
  '((((class color) (background light))
     :foreground "#00ff00" :inherit simple-rtm-task)
    (((class color) (background dark))
     :foreground "#00ff00" :inherit simple-rtm-task))
  "Face for the task's due date."
  :group 'simple-rtm-faces)

(defface simple-rtm-task-duedate-due
  '((((class color) (background light))
     :foreground "#ffffff" :background "red" :inherit simple-rtm-task)
    (((class color) (background dark))
     :foreground "#ffffff" :background "red" :inherit simple-rtm-task))
  "Face for the task's due date if the task is due."
  :group 'simple-rtm-faces)

(defface simple-rtm-task-url
  '((((class color) (background light))
     :underline t
     :inherit simple-rtm-task)
    (((class color) (background dark))
     :underline t
     :inherit simple-rtm-task))
  "Face for a task's URL."
  :group 'simple-rtm-faces)

(defface simple-rtm-task-tag
  '((((class color) (background light))
     :foreground "#00aeff"
     :inherit simple-rtm-task)
    (((class color) (background dark))
     :foreground "#00aeff"
     :inherit simple-rtm-task))
  "Face for a task's tag."
  :group 'simple-rtm-faces)

(defface simple-rtm-task-location
  '((((class color) (background light))
     :foreground "#000000"
     :inherit simple-rtm-task)
    (((class color) (background dark))
     :foreground "#ffffff"
     :inherit simple-rtm-task))
  "Face for a task's URL."
  :group 'simple-rtm-faces)

(defface simple-rtm-task-time-estimate
  '((((class color) (background light))
     :foreground "#ff00ff" :inherit simple-rtm-task)
    (((class color) (background dark))
     :foreground "#ff00ff" :inherit simple-rtm-task))
  "Face for the task's time estimate."
  :group 'simple-rtm-faces)

(defface simple-rtm-note-title
  '((((class color) (background light))
     :foreground "#000000" :inherit simple-rtm-task)
    (((class color) (background dark))
     :foreground "#ffffff" :inherit simple-rtm-task))
  "Face for note titles."
  :group 'simple-rtm-faces)

(defvar simple-rtm-mode-line-string nil
  "String to display in the mode line.")
;;;###autoload (put 'simple-rtm-mode-line-string 'risky-local-variable t)

(defvar simple-rtm-lists)
(defvar simple-rtm-locations)
(defvar simple-rtm-tasks)
(defvar simple-rtm-data)
(defvar simple-rtm-transaction-ids)

(dolist (var '(simple-rtm-lists simple-rtm-locations simple-rtm-tasks simple-rtm-data simple-rtm-transaction-ids))
  (make-variable-buffer-local var)
  (put var 'permanent-local t))

(defvar simple-rtm-mode-map nil
  "The mode map for the simple Remember The Milk interface.")
(setf simple-rtm-mode-map
      (let ((map (make-keymap)))
        (suppress-keymap map t)
        (define-key map (kbd "$") 'simple-rtm-reload)
        (define-key map (kbd "%") 'simple-rtm-reload-all)
        (define-key map (kbd "* *") 'simple-rtm-task-select-current)
        (define-key map (kbd "* a") 'simple-rtm-task-select-all)
        (define-key map (kbd "* n") 'simple-rtm-task-select-none)
        (define-key map (kbd "* r") 'simple-rtm-task-select-regex)
        (define-key map (kbd ",") 'simple-rtm-task-select-toggle-current)
        (define-key map (kbd ".") 'simple-rtm-redraw)
        (define-key map (kbd "1") 'simple-rtm-task-set-priority-1)
        (define-key map (kbd "2") 'simple-rtm-task-set-priority-2)
        (define-key map (kbd "3") 'simple-rtm-task-set-priority-3)
        (define-key map (kbd "4") 'simple-rtm-task-set-priority-none)
        (define-key map (kbd "<SPC>") 'simple-rtm-task-select-toggle-current)
        (define-key map (kbd "<deletechar>") 'simple-rtm-task-delete)
        (define-key map (kbd "C-d") 'simple-rtm-task-delete)
        (define-key map (kbd "DEL") 'simple-rtm-task-delete)
        (define-key map (kbd "E a") 'simple-rtm-list-expand-all)
        (define-key map (kbd "E n") 'simple-rtm-list-collapse-all)
        (define-key map (kbd "RET") 'simple-rtm-task-show-details)
        (define-key map (kbd "TAB") 'simple-rtm-list-toggle-expansion)
        (define-key map (kbd "C-/") 'simple-rtm-undo)
        (define-key map (kbd "C-<down>") 'simple-rtm-list-goto-next)
        (define-key map (kbd "C-<up>") 'simple-rtm-list-goto-previous)
        (define-key map (kbd "a") 'simple-rtm-task-select-all-in-list)
        (define-key map (kbd "c") 'simple-rtm-task-complete)
        (define-key map (kbd "d") 'simple-rtm-task-set-duedate)
        (define-key map (kbd "g") 'simple-rtm-task-set-time-estimate)
        (define-key map (kbd "j") 'next-line)
        (define-key map (kbd "k") 'previous-line)
        (define-key map (kbd "l") 'simple-rtm-task-set-location)
        (define-key map (kbd "m") 'simple-rtm-task-move)
        (define-key map (kbd "n") 'simple-rtm-task-select-none-in-list)
        (define-key map (kbd "p") 'simple-rtm-task-postpone)
        (define-key map (kbd "q") 'simple-rtm-quit)
        (define-key map (kbd "r") 'simple-rtm-task-rename)
        (define-key map (kbd "s") 'simple-rtm-task-set-tags)
        (define-key map (kbd "t") 'simple-rtm-task-smart-add)
        (define-key map (kbd "u") 'simple-rtm-task-set-url)
        (define-key map (kbd "x") 'simple-rtm-task-select-toggle-current)
        (define-key map (kbd "y") 'simple-rtm-task-add-note)
        (define-key map (kbd "z") 'simple-rtm-undo)
        map))

(defvar simple-rtm-details-mode-map nil
  "The mode map for the task details.")
(setf simple-rtm-details-mode-map
      (let ((map (make-keymap)))
        (suppress-keymap map t)
        (define-key map (kbd "$") 'simple-rtm-reload)
        (define-key map (kbd "%") 'simple-rtm-reload-all)
        (define-key map (kbd ".") 'simple-rtm-redraw)
        (define-key map (kbd "<deletechar>") 'simple-rtm-task-delete-note)
        (define-key map (kbd "C-d") 'simple-rtm-task-delete-note)
        (define-key map (kbd "DEL") 'simple-rtm-task-delete-note)
        (define-key map (kbd "RET") 'simple-rtm-task-set-thing-at-point)
        (define-key map (kbd "1") 'simple-rtm-task-set-priority-1)
        (define-key map (kbd "2") 'simple-rtm-task-set-priority-2)
        (define-key map (kbd "3") 'simple-rtm-task-set-priority-3)
        (define-key map (kbd "4") 'simple-rtm-task-set-priority-none)
        (define-key map (kbd "c") 'simple-rtm-task-complete)
        (define-key map (kbd "d") 'simple-rtm-task-set-duedate)
        (define-key map (kbd "e") 'simple-rtm-task-edit-note)
        (define-key map (kbd "g") 'simple-rtm-task-set-time-estimate)
        (define-key map (kbd "l") 'simple-rtm-task-set-location)
        (define-key map (kbd "m") 'simple-rtm-task-move)
        (define-key map (kbd "p") 'simple-rtm-task-postpone)
        (define-key map (kbd "q") 'simple-rtm-quit-details)
        (define-key map (kbd "r") 'simple-rtm-task-rename)
        (define-key map (kbd "s") 'simple-rtm-task-set-tags)
        (define-key map (kbd "t") 'simple-rtm-task-smart-add)
        (define-key map (kbd "u") 'simple-rtm-task-set-url)
        (define-key map (kbd "y") 'simple-rtm-task-add-note)
        (define-key map (kbd "z") 'simple-rtm-undo)
        map))

(defun simple-rtm--buffer (&optional dont-create)
  (if dont-create
      (get-buffer "*SimpleRTM*")
    (get-buffer-create "*SimpleRTM*")))

(defconst simple-rtm--details-buffer-name
  "*SimpleRTM task details*")

(defun simple-rtm--details-buffer ()
  (get-buffer-create simple-rtm--details-buffer-name))

(defun simple-rtm--details-buffer-visible-p ()
  (get-buffer simple-rtm--details-buffer-name))

;;;###autoload
(defun simple-rtm-mode ()
  "An interactive \"do everything right now\" mode for Remember The Milk

Display all of your lists and tasks in a new buffer or switch to
that buffer if it already exists.

Each action will be sent to the Remember The Milk web interface
immediately.

\\{simple-rtm-mode-map}"
  (interactive)
  (let* ((default-directory "~/")
         (buffer (simple-rtm--buffer))
         (window (get-buffer-window buffer)))
    (if window
        (select-window window)
      (switch-to-buffer buffer)))
  (setq major-mode 'simple-rtm-mode
        mode-name "SimpleRTM"
        mode-line-process ""
        truncate-lines t
        buffer-read-only t)
  (use-local-map simple-rtm-mode-map)
  (unless simple-rtm-lists
    (simple-rtm-reload))
  )

(defun simple-rtm--completing-read-multiple-regex--complete ()
  "Complete the minibuffer contents as far as possible."
  (interactive)
  (let* ((input (minibuffer-completion-contents))
         (reify (lambda (re)
                  (setq re (getf re :regex))
                  (concat "\\(?:\\s-\\|^\\)"
                          (if (string-match-p "\\$$" re)
                              re
                            (concat re "$")))))
         (match (cadar (sort (remove-if (lambda (entry) (not (car entry)))
                                        (mapcar (lambda (entry)
                                                  (list (string-match-p (funcall reify entry) input)
                                                        entry))
                                                table))
                             (lambda (e1 e2)
                               (> (car e1) (car e2)))))))
    ;; (message "trying very hard: %s match %s" input (pp-to-string match))
    (when match
      (let ((minibuffer-completion-table (mapcar (lambda (string)
                                                   (concat (or (getf match :prefix) "") string))
                                                 (getf match :collection)))
            (completion-all-sorted-completions nil)
            (inhibit-read-only t)
            (to-complete (save-match-data
                           (string-match (funcall reify match) input)
                           (match-string (if (listp (car match)) (cadr match) 1) input))))
        (put-text-property (- (point) (length input)) (point-max)
                           'field nil)
        (put-text-property (- (point) (length to-complete) (length (getf match :prefix)))
                           (point)
                           'field t)
        ;; (message "YEAH! for RE %s dump %s to-complete %s field %s" (funcall reify match) (pp-to-string (cadr match)) to-complete (field-string))
        (call-interactively 'minibuffer-complete)))))

(defun simple-rtm--completing-read-multiple-regex (prompt table &rest options)
  (let ((map (copy-keymap minibuffer-local-map)))
    (define-key map (kbd "TAB") 'simple-rtm--completing-read-multiple-regex--complete)
    (read-from-minibuffer prompt
                          (getf options :initial-input)
                          map
                          nil
                          (getf options :history))))

(defun simple-rtm--read (prompt &rest options)
  (let ((result (cond ((getf options :collection)
                       (funcall simple-rtm-completing-read-function
                                prompt
                                (getf options :collection)
                                nil
                                (getf options :require-match)
                                (getf options :initial-input)))
                      ((getf options :multi-collection)
                       (simple-rtm--completing-read-multiple-regex prompt (getf options :multi-collection) options))
                      (t (read-input prompt (getf options :initial-input))))))
    (if (and (getf options :error-msg-if-empty)
             (string= (or result "") ""))
        (error (getf options :error-msg-if-empty)))
    result))

(defun simple-rtm--store-transaction-id (result)
  (with-current-buffer (simple-rtm--buffer)
    (when (and (eq (caar result) 'transaction)
               (string= (or (cdr (assoc 'undoable (cadar result) )) "") "1"))
      (push (or (cdr (assoc 'id (cadar result) )) "") (car simple-rtm-transaction-ids)))))

(defun simple-rtm--start-mass-transaction ()
  (if (or (not simple-rtm-transaction-ids)
          (car simple-rtm-transaction-ids))
      (push nil simple-rtm-transaction-ids)))

(defun simple-rtm--last-mass-transaction ()
  (car (delq nil simple-rtm-transaction-ids)))

(defmacro simple-rtm--with-buffer-and-window (buffer-or-name &rest body)
  (declare (indent 1) (debug t))
  (let ((buffer (make-symbol "*buffer*"))
        (window (make-symbol "*window*")))
    `(let* ((,buffer (get-buffer ,buffer-or-name))
            (,window (get-buffer-window ,buffer)))
       (with-current-buffer ,buffer
         (if ,window
             (with-selected-window ,window
               ,@body)
           ,@body)))))

(defmacro simple-rtm--save-pos (&rest body)
  (declare (indent 0))
  (let ((list-id (make-symbol "*list-id*"))
        (task-id (make-symbol "*task-id*"))
        (found (make-symbol "*found*")))
    `(simple-rtm--with-buffer-and-window (simple-rtm--buffer)
       (let ((,list-id (get-text-property (point) :list-id))
             (,task-id (get-text-property (point) :task-id)))
         ,@body
         (unless (simple-rtm--list-visible-p ,list-id)
           (setf ,task-id nil))
         (if (not (simple-rtm--goto ,list-id ,task-id))
             (goto-char (point-min)))))))

(defun simple-rtm--goto (list-id &optional task-id)
  (let (found list-at)
    (goto-char (point-min))
    (while (and (not (string= (or (get-text-property (point) :list-id) "") list-id))
                (< (point) (point-max)))
      (forward-line))
    (setf found (string= (or (get-text-property (point) :list-id) "") list-id)
          list-at (point))

    (when (and found task-id)
      (setf found nil)
      (forward-line)
      (while (and (not (string= (or (get-text-property (point) :task-id) "") task-id))
                  (< (point) (point-max)))
        (forward-line))
      (setf found (string= (or (get-text-property (point) :task-id) "") task-id))

      (unless found
        (goto-char list-at)
        (setq found t)))
    found))

(defun simple-rtm--overlay-name (list-or-id)
  (intern (concat "simple-rtm-list-" (if (listp list-or-id) (getf list-or-id :id) list-or-id))))

(defun simple-rtm--list-visible-p (list-or-id)
  (not (member (simple-rtm--overlay-name list-or-id) buffer-invisibility-spec)))

(defun simple-rtm--list-smart-p (list)
  (string= (xml-get-attribute (getf list :xml) 'smart) "1"))

(defun simple-rtm--render-list-header (list)
  (let ((name (getf list :name))
        (is-smart (simple-rtm--list-smart-p list)))
    (insert (propertize (concat "["
                                (cond ((not (getf list :tasks)) " ")
                                      ((getf list :expanded) "-")
                                      (t "+"))
                                "] "
                                name
                                "\n")
                        :list-id (getf list :id)
                        'face (if is-smart 'simple-rtm-smart-list 'simple-rtm-list)))))

(defun simple-rtm--render-list (list)
  (let ((name (getf list :name))
        list-beg
        (overlay-name (simple-rtm--overlay-name list)))
    (simple-rtm--render-list-header list)
    (setq list-beg (point))
    (dolist (task (getf list :tasks))
      (simple-rtm--render-task task))
    (overlay-put (make-overlay list-beg (point))
                 'invisible overlay-name)
    (unless (getf list :expanded)
      (add-to-invisibility-spec overlay-name))))

(defun simple-rtm--sort-lists (lists)
  (sort lists
        (lambda (l1 l2)
          (let ((l1-smart (xml-get-attribute (getf l1 :xml) 'smart))
                (l2-smart (xml-get-attribute (getf l2 :xml) 'smart)))
            (if (string= l1-smart l2-smart)
                (string< (downcase (getf l1 :name))
                         (downcase (getf l2 :name)))
              (string< l1-smart l2-smart))))))

(defun simple-rtm--cmp (v1 v2)
  (cond ((string< v1 v2) -1)
        ((string= v1 v2) nil)
        (t 1)))

(defun simple-rtm--xml-set-attribute (node attribute value)
  (let ((attributes (cdadr node)))
    (while (and attributes (not (eq (caar attributes) attribute)))
      (setf attributes (cdr attributes)))
    (if attributes
        (setcdr (car attributes) (or value ""))))
  node)

(defun simple-rtm--task-duedate (task &optional default)
  (let ((duedate (xml-get-attribute task 'due)))
    (if (string= duedate "")
        default
      (format-time-string "%Y-%m-%d" (date-to-time duedate)))))

(defun simple-rtm--format-duedate (duedate)
  (let* ((today-sec (float-time (date-to-time (format-time-string "%Y-%m-%d 00:00:00"))))
         (duedate-time (date-to-time (concat duedate " 00:00:00")))
         (duedate-sec (float-time duedate-time))
         (diff (- duedate-sec today-sec)))
    (cond ((< diff 0) duedate)
          ((< diff (* 60 60 24)) "Today")
          ((< diff (* 60 60 24 2)) "Tomorrow")
          ((< diff (* 60 60 24 7)) (format-time-string "%A" duedate-time))
          ((< diff (* 60 60 24 90)) (format-time-string "%B %d" duedate-time))
          (t duedate))))

(defun simple-rtm--task< (t1 t2)
  (let* ((t1-task (car (xml-get-children (getf t1 :xml) 'task)))
         (t2-task (car (xml-get-children (getf t2 :xml) 'task)))
         (dueify (lambda (task) (simple-rtm--task-duedate task "9999-99-99")))
         (t1-due (funcall dueify t1-task))
         (t2-due (funcall dueify t2-task))
         (t1-prio (xml-get-attribute t1-task 'priority))
         (t2-prio (xml-get-attribute t2-task 'priority))
         (t1-name (downcase (getf t1 :name)))
         (t2-name (downcase (getf t2 :name))))
    (= -1 (or (if (eq simple-rtm-sort-order 'priority-date-name) (simple-rtm--cmp t1-prio t2-prio) (simple-rtm--cmp t1-due  t2-due))
              (if (eq simple-rtm-sort-order 'priority-date-name) (simple-rtm--cmp t1-due  t2-due)  (simple-rtm--cmp t1-prio t2-prio))
              (simple-rtm--cmp t1-name t2-name)
              0))))

(defun simple-rtm--render-task (task)
  (let* ((taskseries-node (getf task :xml))
         (task-node (car (xml-get-children taskseries-node 'task)))
         (priority (xml-get-attribute task-node 'priority))
         (priority-str (if (string= priority "N")
                           "  "
                         (propertize (concat "P" priority)
                                     'face (intern (concat "simple-rtm-task-priority-" priority)))))
         (name (getf task :name))
         (url (xml-get-attribute taskseries-node 'url))
         (location (simple-rtm--find-location-by 'id (xml-get-attribute taskseries-node 'location_id)))
         (duedate (simple-rtm--task-duedate task-node))
         (time-estimate (xml-get-attribute task-node 'estimate))
         (num-notes (length (xml-get-children (car (xml-get-children taskseries-node 'notes))
                                              'note)))
         (tags (getf task :tags))
         (tags-str (if tags
                       (mapconcat (lambda (tag)
                                    (propertize tag 'face 'simple-rtm-task-tag))
                                  tags " ")))
         (today (format-time-string "%Y-%m-%d")))
    (insert (propertize (concat (mapconcat 'identity
                                           (delq nil
                                                 (list ""
                                                       (if (getf task :marked) "*" " ")
                                                       priority-str
                                                       (if duedate
                                                           (propertize (simple-rtm--format-duedate duedate)
                                                                       'face (if (string< today duedate)
                                                                                 'simple-rtm-task-duedate
                                                                               'simple-rtm-task-duedate-due)))
                                                       tags-str
                                                       (propertize name 'face 'simple-rtm-task)
                                                       (if (not (string= time-estimate ""))
                                                           (propertize time-estimate 'face 'simple-rtm-task-time-estimate))
                                                       (if (not (string= url ""))
                                                           (propertize url 'face 'simple-rtm-task-url))
                                                       (if location
                                                           (propertize (concat "@" (xml-get-attribute location 'name))
                                                                       'face 'simple-rtm-task-location))
                                                       (if (> num-notes 0)
                                                           (propertize (format "[%d]" num-notes)
                                                                       'face 'simple-rtm-note-title))
                                                       ))
                                           " ")
                                "\n")
                        :list-id (getf task :list-id)
                        :task-id (getf task :id)))))

(defun simple-rtm--find-list (id)
  (if id
      (find-if (lambda (list)
                 (string= (getf list :id) id))
               (getf simple-rtm-data :lists))))

(defun simple-rtm--find-list-by-name (name)
  (if name
      (find-if (lambda (list)
                 (string= (getf list :name) name))
               (getf simple-rtm-data :lists))))

(defun simple-rtm--find-list-at-point ()
  (simple-rtm--find-list (get-text-property (point) :list-id)))

(defun simple-rtm--find-task-at-point ()
  (let ((list (simple-rtm--find-list (get-text-property (point) :list-id)))
        (task-id (get-text-property (point) :task-id)))
    (if (and list task-id)
        (find-if (lambda (task)
                   (string= (getf task :id) task-id))
                 (getf list :tasks)))))

(defun simple-rtm--list-names ()
  (delq nil (mapcar (lambda (list)
                      (unless (string= (xml-get-attribute (getf list :xml) 'smart) "1")
                        (getf list :name)))
                    (getf simple-rtm-data :lists))))

(defun simple-rtm--tag-names ()
  (sort (remove-duplicates (apply 'append
                                  (mapcar (lambda (list)
                                            (apply 'append
                                                   (mapcar (lambda (task) (getf task :tags))
                                                           (getf list :tasks))))
                                          (getf simple-rtm-data :lists)))
                           :test 'equal)
        'string<))

(defun simple-rtm--find-location-by (attribute value)
  (if (and value (not (string= value "")))
      (find-if (lambda (location)
                 (string= (xml-get-attribute location attribute) value))
               simple-rtm-locations)))

(defun simple-rtm--find-list-and-task (list-id task-id)
  (with-current-buffer (simple-rtm--buffer)
    (let ((list (simple-rtm--find-list list-id))
          task)
      (when list (setq task
                       (find-if (lambda (task)
                                  (string= (getf task :id) task-id))
                                (getf list :tasks))))
      (if (and list task)
          (cons list task)))))

(defun simple-rtm--find-note (taskseries-node note-id)
  (if (and taskseries-node note-id)
      (find-if (lambda (note)
                 (string= (xml-get-attribute note 'id) note-id))
               (xml-get-children (car (xml-get-children taskseries-node 'notes))
                                 'note))))

(defun simple-rtm--location-names (&optional no-error)
  (or (mapcar (lambda (location)
                (xml-get-attribute location 'name))
              simple-rtm-locations)
      (unless no-error
        (error "No locations have been set yet."))))

(defun simple-rtm--multi-collection-for-smart-add ()
  `((:regex "!\\(.*\\)"   :prefix "!" :collection ("1" "2" "3" "4"))
    (:regex "#\\(.*\\)"   :prefix "#" :collection ,(simple-rtm--list-names))
    (:regex "%\\(.*\\)"   :prefix "%" :collection ,(simple-rtm--tag-names))
    (:regex "@\\(.*\\)"   :prefix "@" :collection ,(simple-rtm--location-names t))
    (:regex "\\^\\(.*\\)" :prefix "^" :collection ("today" "tomorrow" "monday" "tuesday" "wednesday" "thursday" "friday" "saturday" "sunday"))))

(defun simple-rtm--modify-task (id modifier)
  (dolist (list (getf simple-rtm-data :lists))
    (dolist (task (getf list :tasks))
      (if (string= id (getf task :id))
          (funcall modifier task)))))

(defun simple-rtm--selected-tasks ()
  (or (when (and (simple-rtm--details-buffer-visible-p)
                 (eq (current-buffer) (simple-rtm--details-buffer)))
        (delq nil (list (cdr (simple-rtm--find-list-and-task (getf simple-rtm-data :list-id)
                                                             (getf simple-rtm-data :task-id))))))
      (apply 'append
             (mapcar (lambda (list)
                       (if (simple-rtm--list-visible-p list)
                           (remove-if (lambda (task) (not (getf task :marked)))
                                      (getf list :tasks))))
                     (with-current-buffer (simple-rtm--buffer)
                       (getf simple-rtm-data :lists))))
      (delq nil (list (with-current-buffer (simple-rtm--buffer)
                        (simple-rtm--find-task-at-point))))
      (error "No task selected and point not on a task")))

(defun simple-rtm--list-set-expansion (list action)
  (setf (getf list :expanded)
        (cond ((eq action 'toggle) (not (getf list :expanded)))
              ((eq action 'expand) t)
              (t nil))))

(defun simple-rtm-list-toggle-expansion ()
  "Expand or collapse the list point is in."
  (interactive)
  (let* ((list-id (get-text-property (point) :list-id))
         (list (or (simple-rtm--find-list list-id)
                   (error "No list found"))))
    (when (> (length (getf list :tasks)) 0)
      (simple-rtm--list-set-expansion list 'toggle)
      (simple-rtm-redraw))))

(defun simple-rtm-list-expand-all ()
  "Expand all lists."
  (interactive)
  (dolist (list (getf simple-rtm-data :lists))
    (simple-rtm--list-set-expansion list 'expand))
  (simple-rtm-redraw))

(defun simple-rtm-list-collapse-all ()
  "Collapse all lists."
  (interactive)
  (dolist (list (getf simple-rtm-data :lists))
    (simple-rtm--list-set-expansion list 'collapse))
  (simple-rtm-redraw))

(defun simple-rtm--task-set-marked (task action)
  (simple-rtm--modify-task (getf task :id)
                           (lambda (task)
                             (setf (getf task :marked)
                                   (cond ((eq action 'toggle) (not (getf task :marked)))
                                         ((eq action 'mark) t)
                                         (t nil))))))

(defun simple-rtm--task-set-priority (task priority)
  (simple-rtm--modify-task (getf task :id)
                           (lambda (task)
                             (let* ((taskseries-node (getf task :xml))
                                    (task-node (car (xml-get-children taskseries-node 'task))))
                               (unless (string= priority (xml-get-attribute task-node 'priority))
                                 (simple-rtm--store-transaction-id
                                  (rtm-tasks-set-priority (getf task :list-id)
                                                          (getf task :id)
                                                          (xml-get-attribute task-node 'id)
                                                          priority)))))))

(defmacro simple-rtm--defun-action (name doc &rest body)
  (declare (indent defun))
  `(defun ,(intern (concat "simple-rtm-" (symbol-name name))) ()
     ,doc
     (interactive)
     (with-current-buffer (simple-rtm--buffer)
       ,@body)
     (simple-rtm-reload)
     (message "Done.")))

(defmacro simple-rtm--defun-task-action (name doc body &rest options)
  (declare (indent defun))
  (let* ((args (getf options :args))
         (act (cdr args))
         vars)
    (while act
      (setq vars (append vars (list (car act)))
            act (cddr act)))
    `(defun ,(intern (concat "simple-rtm-task-" (symbol-name name))) ()
       ,doc
       (interactive)
       (let* ((selected-tasks ,(if (getf options :no-tasks) nil `(simple-rtm--selected-tasks)))
              (first-task (car selected-tasks))
              (note ,(if (getf options :with-note)
                         '(or (simple-rtm--find-note (getf first-task :xml)
                                                     (get-text-property (point) :note-id))
                              (error "No note found at point."))))
              previous-num-transactions transaction-has-ids
              ,@vars)
         (with-current-buffer (simple-rtm--buffer)
           (setq previous-num-transactions (length (delq nil simple-rtm-transaction-ids)))
           (simple-rtm--start-mass-transaction)
           (progn
             ,args)
           ,(if (getf options :no-tasks)
                (progn body)
              `(dolist (current-task selected-tasks)
                 (simple-rtm--modify-task (getf current-task :id)
                                          (lambda (task)
                                            (let* ((taskseries-node (getf task :xml))
                                                   (task-node (car (xml-get-children taskseries-node 'task)))
                                                   (taskseries-id (getf task :id))
                                                   (list-id (getf task :list-id))
                                                   (task-id (xml-get-attribute task-node 'id)))
                                              (simple-rtm--store-transaction-id ,body))))))
           (setq transaction-has-ids (car simple-rtm-transaction-ids))
           (unless transaction-has-ids
             (pop simple-rtm-transaction-ids))
           ,(if (getf options :force-reload)
                `(simple-rtm-reload)
              `(if (not (= previous-num-transactions (length (delq nil simple-rtm-transaction-ids))))
                   (simple-rtm-reload)))
           (message (concat "Done." (if transaction-has-ids " Actions can be undone."))))))))

(defmacro simple-rtm--defun-set-priority (priority)
  (declare (indent defun))
  (setq priority (if (symbolp priority) (symbol-name priority) (format "%d" priority)))
  `(simple-rtm--defun-task-action
     ,(intern (concat "set-priority-" priority))
     ,(concat "Set the priority of selected tasks to " priority ".")
     (simple-rtm--task-set-priority task ,(if (string= priority "none") "N" priority))))

(simple-rtm--defun-set-priority 1)
(simple-rtm--defun-set-priority 2)
(simple-rtm--defun-set-priority 3)
(simple-rtm--defun-set-priority none)

(simple-rtm--defun-task-action postpone
  "Postpone the marked tasks."
  (rtm-tasks-postpone list-id taskseries-id task-id))

(simple-rtm--defun-task-action complete
  "Complete the marked tasks."
  (rtm-tasks-complete list-id taskseries-id task-id))

(simple-rtm--defun-task-action delete
  "Delete the marked tasks."
  (rtm-tasks-delete list-id taskseries-id task-id))

(simple-rtm--defun-task-action set-priority
  "Set the priority of the marked tasks."
  (unless (string= priority (xml-get-attribute task-node 'priority))
    (rtm-tasks-set-priority list-id taskseries-id task-id priority))
  :args (setq priority (simple-rtm--read "New priority: "
                                         :initial-input (xml-get-attribute (car (xml-get-children (getf first-task :xml) 'task))
                                                                           'priority))))

(simple-rtm--defun-task-action set-duedate
  "Set the due date of the marked tasks."
  (unless (string= duedate (simple-rtm--task-duedate task-node))
    (rtm-tasks-set-due-date list-id taskseries-id task-id duedate "0" "1"))
  :args (setq duedate (simple-rtm--read "New due date: "
                                        :initial-input (simple-rtm--task-duedate (car (xml-get-children (getf first-task :xml) 'task))))))

(simple-rtm--defun-task-action set-time-estimate
  "Set the time estimate of the marked tasks."
  (unless (string= time-estimate (xml-get-attribute task-node 'estimate))
    (rtm-tasks-set-estimate list-id taskseries-id task-id time-estimate))
  :args (setq time-estimate (simple-rtm--read "New time estimate: "
                                              :initial-input (xml-get-attribute (car (xml-get-children (getf first-task :xml) 'task))
                                                                                'estimate))))

(simple-rtm--defun-task-action set-url
  "Set the URL of the marked tasks."
  (unless (string= url (xml-get-attribute taskseries-node 'url))
    (rtm-tasks-set-url list-id taskseries-id task-id url))
  :args (setq url (simple-rtm--read "New URL: "
                                    :initial-input (xml-get-attribute (getf first-task :xml) 'url))))

(simple-rtm--defun-task-action set-tags
  "Set the tags of the marked tasks."
  (unless (string= tags (mapconcat 'identity (getf task :tags) " "))
    (rtm-tasks-set-tags list-id taskseries-id task-id (split-string tags " ")))
  :args (setq tags (simple-rtm--read "New tags: "
                                     :initial-input (mapconcat 'identity (getf first-task :tags) " "))))

(simple-rtm--defun-task-action set-location
  "Set the location for the marked tasks."
  (rtm-tasks-set-location list-id taskseries-id task-id (and location (xml-get-attribute location 'id)))
  :args (setq location-name (simple-rtm--read "New location: "
                                              :collection (simple-rtm--location-names))
              location (simple-rtm--find-location-by 'name location-name)))

(simple-rtm--defun-task-action rename
  "Rename the marked tasks."
  (unless (string= name (getf task :name))
    (rtm-tasks-set-name list-id taskseries-id task-id name))
  :args (setq name (simple-rtm--read "Rename to: "
                                     :initial-input (getf first-task :name)
                                     :error-msg-if-empty "Name must not be empty.")))

(simple-rtm--defun-task-action move
  "Move marked tasks to another list."
  (rtm-tasks-move-to list-id (getf new-list :id) taskseries-id task-id)
  :args (setq list-name (simple-rtm--read "New list: "
                                          :collection (simple-rtm--list-names)
                                          :error-msg-if-empty "List must not be empty."
                                          :require-match t)
              new-list (or (simple-rtm--find-list-by-name list-name)
                           (error "List not found."))))

(simple-rtm--defun-task-action add-note
  "Add a note to the marked tasks."
  (rtm-tasks-notes-add list-id taskseries-id task-id note-title note-text)
  :args (setq note-title (simple-rtm--read "Note title: "
                                           :error-msg-if-empty "Note title must not be empty.")
              note-text (simple-rtm--read "Note text: "
                                          :error-msg-if-empty "Note text must not be empty.")))

(simple-rtm--defun-task-action delete-note
  "Delete the note point is at."
  (rtm-tasks-notes-delete (xml-get-attribute note 'id))
  :with-note t)

(simple-rtm--defun-task-action edit-note
  "Edit the note point is at."
  (rtm-tasks-notes-edit (xml-get-attribute note 'id) note-title note-text)
  :with-note t
  :force-reload t
  :args (setq note-title (simple-rtm--read "Note title: "
                                           :error-msg-if-empty "Note title must not be empty."
                                           :initial-input (decode-coding-string (xml-get-attribute note 'title) 'utf-8))
              note-text (simple-rtm--read "Note text: "
                                          :error-msg-if-empty "Note text must not be empty."
                                          :initial-input (decode-coding-string (caddr note) 'utf-8))))

(simple-rtm--defun-task-action smart-add
  "Add a new task with smart add functionality.

See http://www.rememberthemilk.com/services/smartadd/ for a full
explanation of the syntax supported. Summary:

Task name and due date: Enter an arbitrary name along with the
due date spec, e.g. \"Do laundy next Saturday\"

Due date: \"^spec-or-date\", e.g. \"^tomorrow\" or
\"^2011-09-01\"

Priority: \"!prio\", e.g. \"!1\"

Lists: \"#list-name\", e.g. \"#Private\". If no list is given
then the list at point will be used.

Tags: \"%tag\", e.g. \"%birthday\". Completion allows for new
tags to be created. This prefix is intentionally different from
RTM's web interface where the \"#\" is used for both lists and
tags.

Locations: \"@location\", e.g. \"@work\"

Time estimate: \"=estimate\", e.g. \"=10 min\"

URLs: Simply add the URL. Doesn't need a special prefix.

Tab completion is supported for locations, lists, priorities and
due dates with their prefix (see above, e.g. \"some task
#In<TAB>\" could be expanded to \"some task #Inbox\")."
  (rtm-tasks-add spec "1")
  :args (setq spec-raw (simple-rtm--read "Task spec: "
                                         :multi-collection (simple-rtm--multi-collection-for-smart-add)
                                         :error-msg-if-empty "Task spec must not be empty.")
              spec (replace-regexp-in-string " +%" " #"
                                             (or (if (and simple-rtm-use-default-list-for-new-tasks
                                                          (not (string-match-p "\\s-#." spec-raw)))
                                                     (let* ((list (simple-rtm--find-list-at-point))
                                                            (name (or (getf list :name) "")))
                                                       (if (not (or (string= name "")
                                                                    (simple-rtm--list-smart-p list)))
                                                           (concat spec-raw " #" name))))
                                                 spec-raw)))
  :no-tasks t
  :force-reload t)

(simple-rtm--defun-action undo
  "Undo previous action."
  (let ((transaction-ids (simple-rtm--last-mass-transaction)))
    (unless transaction-ids
      (error "No transaction to undo"))
    (dolist (id transaction-ids)
      (rtm-transactions-undo id))
    (setf simple-rtm-transaction-ids (cdr (delq nil simple-rtm-transaction-ids)))))

(defun simple-rtm-task-show-details ()
  (interactive)
  "Show all details of the task at point in another window."
  (let* ((task (or (simple-rtm--find-task-at-point)
                   (error "No task at point.")))
         (buffer (simple-rtm--details-buffer))
         (window (get-buffer-window buffer)))
    (if window
        (select-window window)
      (switch-to-buffer-other-window buffer))
    (simple-rtm-details-mode task)))

(defun simple-rtm-details-mode (task)
  (setq major-mode 'simple-rtm-details-mode
        mode-name "SimpleRTM-details"
        mode-line-process ""
        buffer-read-only t
        simple-rtm-data (list :task-id (getf task :id)
                              :list-id (getf task :list-id)))
  (use-local-map simple-rtm-details-mode-map)
  (simple-rtm--redraw-task-details))

(defun simple-rtm--redraw-task-details ()
  (let ((buffer (simple-rtm--details-buffer)))
    (simple-rtm--with-buffer-and-window buffer
      (let ((list-and-task (simple-rtm--find-list-and-task (getf simple-rtm-data :list-id)
                                                           (getf simple-rtm-data :task-id))))
        (if (not list-and-task)
            (let ((window (get-buffer-window buffer)))
              (kill-buffer buffer)
              (if window
                  (delete-window window)))
          (let* ((list (car list-and-task))
                 (task (cdr list-and-task))
                 (taskseries-node (getf task :xml))
                 (task-node (car (xml-get-children taskseries-node 'task)))
                 (priority (xml-get-attribute task-node 'priority))
                 (priority-str (if (string= priority "N")
                                   "none"
                                 (propertize (concat "P" priority)
                                             'face (intern (concat "simple-rtm-task-priority-" priority)))))
                 (name (getf task :name))
                 (url (xml-get-attribute taskseries-node 'url))
                 (url-str (if (not (string= url ""))
                              (propertize url 'face 'simple-rtm-task-url)
                            "none"))
                 (location (simple-rtm--find-location-by 'id (xml-get-attribute taskseries-node 'location_id)))
                 (location-str (if location
                                   (propertize (xml-get-attribute location 'name) 'face 'simple-rtm-task-location)
                                 "none"))
                 (tags (getf task :tags))
                 (tags-str (if tags
                               (mapconcat (lambda (tag)
                                            (propertize tag 'face 'simple-rtm-task-tag))
                                          tags " ")
                             "none"))
                 (today (format-time-string "%Y-%m-%d"))
                 (duedate (simple-rtm--task-duedate task-node))
                 (duedate-str (if duedate
                                  (propertize (simple-rtm--format-duedate duedate)
                                              'face (if (string< today duedate)
                                                        'simple-rtm-task-duedate
                                                      'simple-rtm-task-duedate-due))
                                "never"))
                 (time-estimate (xml-get-attribute task-node 'estimate))
                 (time-estimate-str (if (not (string= time-estimate ""))
                                        (propertize time-estimate 'face 'simple-rtm-task-time-estimate)
                                      "none"))
                 (notes (xml-get-children (car (xml-get-children taskseries-node 'notes))
                                          'note))
                 (note-num 0)
                 (inhibit-read-only t)
                 (content (lambda (func &rest text)
                            (propertize (concat (apply 'concat text) "\n")
                                        :change-func (intern (concat "simple-rtm-task-" (symbol-name func))))))
                 pos)

            (setq pos (cons (line-number-at-pos) (current-column)))
            (erase-buffer)

            (insert (funcall content 'rename (propertize name 'face 'simple-rtm-task))
                    "\n"
                    (funcall content 'set-priority      "Priority:      " priority-str)
                    (funcall content 'set-duedate       "Due:           " duedate-str)
                    (funcall content 'set-tags          "Tags:          " tags-str)
                    (funcall content 'set-time-estimate "Time estimate: " time-estimate-str)
                    (funcall content 'set-location      "Location:      " location-str)
                    (funcall content 'set-url           "URL:           " url-str)
                    "\n")

            (dolist (note notes)
              (setq note-num (1+ note-num))
              (let ((beg (point)))
                (insert "Note " (format "%d" note-num) ": "
                        (propertize (decode-coding-string (xml-get-attribute note 'title) 'utf-8)
                                    'face 'simple-rtm-note-title)
                        "\n"
                        (decode-coding-string (caddr note) 'utf-8)
                        "\n\n")
                (put-text-property beg (point) :note-id (xml-get-attribute note 'id))
                (put-text-property beg (point) :change-func 'simple-rtm-task-edit-note)))

            (put-text-property (point-min) (point-max) :task-id (getf simple-rtm-data :task-id))
            (put-text-property (point-min) (point-max) :list-id (getf simple-rtm-data :list-id))

            (goto-char (point-min))
            (ignore-errors
              (forward-line (1- (car pos)))
              (move-to-column (cdr pos)))))))))

(defun simple-rtm-task-set-thing-at-point ()
  "Edit the task's property at point.

Allows the user to edit e.g. the due date, the time estimate or
the task's name depending on where point is."
  (interactive)
  (call-interactively (or (get-text-property (point) :change-func)
                          (error "There's nothing to change here."))))

(defun simple-rtm-quit-details ()
  "Quit the task details window."
  (interactive)
  (quit-window t)
  (ignore-errors
    (delete-window)))

(defun simple-rtm-task-select-toggle-current ()
  "Toggle the mark of the task at point."
  (interactive)
  (let* ((task (simple-rtm--find-task-at-point)))
    (when task
      (simple-rtm--task-set-marked task 'toggle)
      (simple-rtm-redraw)))
  (beginning-of-line)
  (forward-line))

(defun simple-rtm-task-select-current ()
  "Mark the task at point."
  (interactive)
  (let* ((task (simple-rtm--find-task-at-point)))
    (when task
      (simple-rtm--task-set-marked task 'mark)
      (simple-rtm-redraw)))
  (beginning-of-line)
  (forward-line))

(defun simple-rtm-task-select-all ()
  "Mark all visible tasks."
  (interactive)
  (dolist (list (getf simple-rtm-data :lists))
    (if (simple-rtm--list-visible-p list)
        (dolist (task (getf list :tasks))
          (simple-rtm--task-set-marked task 'mark))))
  (simple-rtm-redraw))

(defun simple-rtm-task-select-none ()
  "Unmark all visible tasks."
  (interactive)
  (dolist (list (getf simple-rtm-data :lists))
    (if (simple-rtm--list-visible-p list)
        (dolist (task (getf list :tasks))
          (simple-rtm--task-set-marked task 'unmark))))
  (simple-rtm-redraw))

(defun simple-rtm-task-select-all-in-list ()
  (interactive)
  "Mark all tasks in the list point is in.

Will only mark the tasks if the list is expanded."
  (let ((list (or (simple-rtm--find-list-at-point)
                  (error "Not on a list"))))
    (if (simple-rtm--list-visible-p list)
        (dolist (task (getf list :tasks))
          (simple-rtm--task-set-marked task 'mark))))
  (simple-rtm-redraw))

(defun simple-rtm-task-select-none-in-list ()
  (interactive)
  "Unmark all tasks in the list point is in.

Will only unmark the tasks if the list is expanded."
  (let ((list (or (simple-rtm--find-list-at-point)
                  (error "Not on a list"))))
    (if (simple-rtm--list-visible-p list)
        (dolist (task (getf list :tasks))
          (simple-rtm--task-set-marked task 'unmark))))
  (simple-rtm-redraw))

(defun simple-rtm-task-select-regex (&optional regex)
  "Mark visible tasks matching REGEX."
  (interactive)
  (unless regex
    (setf regex (simple-rtm--read "Mark tasks matching: ")))
  (when (not (string= (or regex "") ""))
    (dolist (list (getf simple-rtm-data :lists))
      (if (simple-rtm--list-visible-p list)
          (dolist (task (getf list :tasks))
            (if (string-match-p regex (getf task :name))
                (simple-rtm--task-set-marked task 'mark)))))
    (simple-rtm-redraw)))

(defun simple-rtm--build-data ()
  (let* ((expanded (make-hash-table :test 'equal))
         (marked (make-hash-table :test 'equal))
         (task-node-handler
          (lambda (task-node)
            (let ((task-id (xml-get-attribute task-node 'id)))
              (list :name (decode-coding-string (xml-get-attribute task-node 'name) 'utf-8)
                    :id task-id
                    :list-id list-id
                    :marked (gethash task-id marked)
                    :tags (mapcar (lambda (node) (decode-coding-string (caddr node) 'utf-8))
                                  (xml-get-children (car (xml-get-children task-node 'tags)) 'tag))
                    :xml task-node))))
         (list-node-handler
          (lambda (list-node)
            (let ((list-id (xml-get-attribute list-node 'id)))
              (list :name (decode-coding-string (xml-get-attribute list-node 'name) 'utf-8)
                    :id list-id
                    :expanded (gethash list-id expanded)
                    :xml list-node
                    :tasks (sort (mapcar task-node-handler
                                         (xml-get-children (car (remove-if (lambda (task-list-node)
                                                                             (not (string= list-id (xml-get-attribute task-list-node 'id))))
                                                                           simple-rtm-tasks))
                                                           'taskseries))
                                 'simple-rtm--task<))))))

    (dolist (list (getf simple-rtm-data :lists))
      (puthash (getf list :id) (getf list :expanded) expanded)
      (dolist (task (getf list :tasks))
        (puthash (getf task :id) (getf task :marked) marked)))

    (setq simple-rtm-data (list :lists (simple-rtm--sort-lists (mapcar list-node-handler simple-rtm-lists))))))

(defun simple-rtm-reload-all ()
  "Reload everything from Remember The Milk.

This will lists and locations. Afterwards tasks are reloaded by
calling `simple-rtm-reload'."
  (interactive)
  (with-current-buffer (simple-rtm--buffer)
    (setq simple-rtm-lists nil
          simple-rtm-locations nil
          simple-rtm-tasks nil)
    (simple-rtm-reload)))

(defun simple-rtm--load-locations ()
  (setq simple-rtm-locations
        (sort (mapcar (lambda (location)
                        (simple-rtm--xml-set-attribute location 'name
                                                       (decode-coding-string (xml-get-attribute location 'name)
                                                                             'utf-8)))
                      (rtm-locations-get-list))
              (lambda (l1 l2)
                (string< (downcase (xml-get-attribute l1 'name))
                         (downcase (xml-get-attribute l2 'name)))))))

(defun simple-rtm-reload ()
  "Reload tasks from Remember The Milk."
  (interactive)
  (with-current-buffer (simple-rtm--buffer)
    (unless simple-rtm-lists
      (setq simple-rtm-lists (--remove (or (string= "1" (xml-get-attribute it 'archived))
                                           (string= "1" (xml-get-attribute it 'deleted))
                                           (string= "1" (xml-get-attribute it 'smart)))
                                       (rtm-lists-get-list))))
    (unless simple-rtm-locations
      (simple-rtm--load-locations))
    (setq simple-rtm-tasks (rtm-tasks-get-list nil "status:incomplete"))
    (simple-rtm--build-data)
    (simple-rtm-redraw)
    (simple-rtm--update-mode-line-string)))

(defun simple-rtm-redraw ()
  "Redraw the SimpleRTM buffer."
  (interactive)
  (with-current-buffer (simple-rtm--buffer)
    (simple-rtm--save-pos
      (let ((inhibit-read-only t))
        (erase-buffer)
        (setq buffer-invisibility-spec nil)
        (dolist (list (getf simple-rtm-data :lists))
          (simple-rtm--render-list list)))))
  (if (simple-rtm--details-buffer-visible-p)
      (simple-rtm--redraw-task-details)))

(defun simple-rtm-list-goto-next ()
  "Go to the next list"
  (interactive)
  (if (and (= (point) (point-at-bol))
           (< (point) (point-max)))
      (forward-char))
  (save-match-data
    (if (search-forward-regexp "^\\[" nil t)
        (beginning-of-line)
      (goto-char (point-max)))))

(defun simple-rtm-list-goto-previous ()
  "Go to the previous list"
  (interactive)
  (save-match-data
    (if (search-backward-regexp "^\\[" nil t)
        (beginning-of-line)
      (goto-char (point-min)))))

(defun simple-rtm--build-mode-line-text ()
  "Build the text for the mode line according to `simple-rtm-mode-line-format'"
  (let* ((buffer (simple-rtm--buffer t))
         (keys (list :p1 :p2 :p3 :pn :d1 :d2 :d3 :dn :da :t))
         (data (apply 'append (mapcar (lambda (key) (list key 0)) keys)))
         (do-inc (lambda (key)
                   (setf (getf data key)
                         (1+ (getf data key)))))
         (result simple-rtm-mode-line-format)
         (today-sec (float-time (date-to-time (format-time-string "%Y-%m-%d 00:00:00"))))
         priority taskseries-node task-node
         duedate duedate-sec)
    ;; Only do work if a SimpleRTM exists.
    (when buffer
      (with-current-buffer buffer
        ;; Iterate over all lists and in all tasks and increase the
        ;; appropriate counters.
        (dolist (list (getf simple-rtm-data :lists))
          (dolist (task (getf list :tasks))
            (funcall do-inc :t)

            ;; Deconstruct data structure into smaller ones
            (setq taskseries-node (getf task :xml)
                  task-node (car (xml-get-children taskseries-node 'task))
                  priority (xml-get-attribute task-node 'priority)
                  duedate (simple-rtm--task-duedate (car (xml-get-children taskseries-node 'task))))

            ;; Check whether or not the current task is due, i.e. if
            ;; it has a due date and if said date is either today or
            ;; in the past.
            (if (not duedate)
                (funcall do-inc :dn)
              (setq duedate-sec (float-time (date-to-time (concat duedate " 00:00:00"))))
              (if (not (< (- duedate-sec today-sec) (* 60 60 24)))
                  (funcall do-inc :dn)
                ;; Task is due today or prior to today
                (funcall do-inc :da)
                (funcall do-inc (cond ((string= priority "1") :d1)
                                      ((string= priority "2") :d2)
                                      ((string= priority "3") :d3)
                                      (t                      :dn)))))

            ;; Count according to priority regardless of due date.
            (funcall do-inc (cond ((string= priority "1") :p1)
                                  ((string= priority "2") :p2)
                                  ((string= priority "3") :p3)
                                  (t                      :pn))))))

      ;; Format the actual mode line and return it.
      (dolist (key keys result)
        (setq result (replace-regexp-in-string (concat "%" (substring (symbol-name key) 1))
                                               (format "%d" (getf data key))
                                               result))))))

(defun simple-rtm--update-mode-line-string ()
  "Update task information in the mode line"
  (setq simple-rtm-mode-line-string
	(propertize (or (simple-rtm--build-mode-line-text) "")
		    'help-echo "SimpleRTM task information"))
  (force-mode-line-update))

(defun simple-rtm--kill-buffer-hook ()
  "Unset the mode line string if the SimpleRTM buffer is killed"
  (let ((srtm-buffer (simple-rtm--buffer t)))
    (when (and srtm-buffer (eq srtm-buffer (current-buffer)))
      (setq simple-rtm-mode-line-string "")
      (force-mode-line-update))))

(defun simple-rtm-quit ()
  "Quit SimpleRTM and kill its buffer"
  (interactive)
  (kill-buffer (simple-rtm--buffer)))

;;;###autoload
(define-minor-mode display-simple-rtm-tasks-mode
  "Display SimpleRTM task statistics in the mode line.
The text being displayed in the mode line is controlled by the variables
`simple-rtm-mode-line-format'.
The mode line will be updated automatically when a task is modified."
  :global t :group 'simple-rtm
  (setq simple-rtm-mode-line-string "")
  (unless global-mode-string
    (setq global-mode-string '("")))
  (if (not display-simple-rtm-tasks-mode)
      (setq global-mode-string
	    (delq 'simple-rtm-mode-line-string global-mode-string))
    (add-to-list 'global-mode-string 'simple-rtm-mode-line-string t)
    (add-hook 'kill-buffer-hook 'simple-rtm--kill-buffer-hook)
    (simple-rtm--update-mode-line-string)))

(provide 'simple-rtm)

;;; simple-rtm.el ends here
