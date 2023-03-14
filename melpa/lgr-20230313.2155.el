;;; lgr.el --- A fully featured logging framework -*- lexical-binding: t -*-

;; Copyright (C) 2023 Matúš Goljer

;; Author: Matúš Goljer <matus.goljer@gmail.com>
;; Maintainer: Matúš Goljer <matus.goljer@gmail.com>
;; Version: 0.1.0
;; Package-Version: 20230313.2155
;; Package-Commit: a46f7e6c58e0c343c81e464f4233acfaa0434b4f
;; Package-Requires: ((emacs "26.1"))
;; Created: 10th March 2023
;; Keywords: tools
;; URL: https://github.com/Fuco1/emacs-lgr

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; lgr is a logging package for Emacs built on the back of EIEIO
;; classes.  It is designed to be flexible, performant, and
;; extensible.

;;; Code:

(require 'seq)
(require 'eieio)
(require 'format-spec)

;; (lgr-log :: (function ((class lgr-logger) int string &rest mixed) mixed))
(cl-defgeneric lgr-log (this level message &rest meta)
  "Log a MESSAGE at a specific LEVEL.

THIS is a logger instance.

META is the additional custom data stored as metadata on the
event.  The exact interpretation of this argument depends on the
logger class.

Rather than using this function directly it is preferable to use
the logging macros which implement lazy evaluation for the
arguments.  In case the logger level is less than the granularity
of the event to be produced, the arguments will not be
evaluated.

The logging macros are:

- `lgr-fatal'
- `lgr-error'
- `lgr-warn'
- `lgr-info'
- `lgr-debug'
- `lgr-trace'.")

(eval-and-compile
  (defconst lgr-log-levels '((fatal . 100)
                             (error . 200)
                             (warn . 300)
                             (info . 400)
                             (debug . 500)
                             (trace . 600))
    "Log levels used in `lgr-log'.")

  (defmacro lgr--def-level (level)
    "Generate the `lgr-level-LEVEL' constant and `lgr-LEVEL' macro for LEVEL."
    (let ((lgr-level (intern (concat "lgr-level-" (symbol-name level))))
          (lgr-name (intern (concat "lgr-" (symbol-name level)))))
      `(progn
         (defconst ,lgr-level
           ,(cdr (assq level lgr-log-levels)))

         (defmacro ,lgr-name (this message &rest meta)
           ,(format "Log MESSAGE using THIS logger at %s level." level)
           (declare (indent 1))
           (macroexp-let2 symbolp logger this
             ,(list
               'backquote
               `(when (>= (lgr-get-threshold ,',logger) ,lgr-level)
                  (lgr-log ,',logger ,lgr-level ,',message ,',@meta))))))))

  (lgr--def-level fatal)
  (lgr--def-level error)
  (lgr--def-level warn)
  (lgr--def-level info)
  (lgr--def-level debug)
  (lgr--def-level trace))

;; (lgr--json-serialize :: (function (mixed) string))
(defmacro lgr--json-serialize (data)
  "Serialize DATA using either `json-serialize' or `json-encode'."
  (if (fboundp 'json-serialize)
      `(json-serialize ,data)
    `(json-encode ,data)))

;; (lgr-level-to-name :: (function (int) symbol))
(defun lgr-level-to-name (level)
  "Convert logging LEVEL to symbol."
  (cdr (assq
        level
        (mapcar
         (lambda (x) (cons (cdr x) (car x)))
         lgr-log-levels))))

;; (lgr-to-string :: (function (mixed) string))
(cl-defgeneric lgr-to-string (obj)
  "Format OBJ as string."
  (format "%s" obj))

(defclass lgr-event ()
  ((msg
    :type string
    :initarg :msg
    :documentation "String message to be appended.")
   (level
    :type integer
    :initarg :level
    :documentation "Log level.  See `lgr-log-levels'")
   (timestamp
    :type (list-of integer)
    :initarg :timestamp
    :documentation "Timestamp created by `current-time'.")
   (timezone
    :type (or string boolean symbol)
    :initarg :timezone
    :initform t
    :documentation "Timezone of the event.")
   (logger-name
    :type string
    :initarg :logger-name
    :documentation "Name of the logger which emited this event.")
   (meta
    :type list
    :initarg :meta
    :initform nil
    :documentation "Plist of arbitrary additional metadata."))
  "Log event produced by `lgr-logger'.

To provide different way of formatting, rather than extending the
event and providing different `lgr-to-string', it is advisable to
extend `lgr-layout' and implement new `lgr-format-event' method.

The event can be extended along with a logger if we want to track
additional properties.")

(cl-defmethod lgr-to-string ((this lgr-event))
  "Format THIS event as string."
  (format "[%s] (%s) %s - %s%s"
          (format-time-string "%FT%T%z" (oref this timestamp) (oref this timezone))
          (oref this level)
          (oref this logger-name)
          (oref this msg)
          (if (oref this meta)
              (format " %s" (oref this meta))
            "")))

(defclass lgr-layout () ()
  "Layouts format `lgr-event' as strings for appending via `lgr-appender'.

A layout needs to implement the method `lgr-format-event'.")

;; (lgr-format-event :: (function ((class lgr-layout) (class lgr-event)) string))
(cl-defgeneric lgr-format-event (this event)
  "Format `lgr-event' EVENT to string using THIS layout.")

(cl-defmethod lgr-format-event ((_this lgr-layout) (event lgr-event))
  "Use `lgr-to-string' to format EVENT."
  (lgr-to-string event))

(defclass lgr-layout-format (lgr-layout)
  ((format
    :type string
    :initarg :format
    :documentation "Format spec.")
   (timestamp-format
    :type string
    :initarg :timestamp-format
    :initform "%FT%T%z"
    :documentation "Time format string used by `format-time-string'."))
  "Format the event using a format spec.

%t The timestamp of the message, formatted according to
   timestamp-format.
%l The log level, lowercase character representation.
%L The log level, uppercase character representation.
%k The log level, first letter of lowercase character
   representation.
%K The log level, first letter of uppercase character
   representation.
%n The log level, integer representation.
%g The name of the logger.
%m The log message.
%f All custom fields of x as a plist.
%j All custom fields of x in proper JSON.")

(cl-defmethod lgr-format-event ((this lgr-layout-format) (event lgr-event))
  "Format EVENT using format spec from `lgr-layout-format'.

THIS is the layout."
  (format-spec
   (oref this format)
   (format-spec-make
    ?t (format-time-string
        (oref this timestamp-format)
        (oref event timestamp)
        (oref event timezone))
    ?l (downcase (symbol-name (lgr-level-to-name (oref event level))))
    ?L (upcase (symbol-name (lgr-level-to-name (oref event level))))
    ?k (substring (downcase (symbol-name (lgr-level-to-name (oref event level)))) 0 1)
    ?K (substring (upcase (symbol-name (lgr-level-to-name (oref event level)))) 0 1)
    ?n (oref event level)
    ?g (oref event logger-name)
    ?m (oref event msg)
    ?f (or (oref event meta) "nil")
    ?j (lgr--json-serialize (oref event meta)))))

(defclass lgr-layout-json (lgr-layout) ()
  "Format the event as JSON.")

(cl-defmethod lgr-to-string ((_this lgr-layout-json))
  "Format THIS layout to string."
  "json layout")

(cl-defmethod lgr-format-event ((_this lgr-layout-json) (event lgr-event))
  "Format EVENT as JSON."
  (lgr--json-serialize
   (list
    :timestamp (format-time-string "%FT%T%z"
                                   (oref event timestamp)
                                   (oref event timezone))
    :level (oref event level)
    :logger-name (oref event logger-name)
    :msg (oref event msg)
    :meta (oref event meta))))

;; (lgr-set-threshold :: (function (mixed int) mixed))
(cl-defgeneric lgr-set-threshold (this level)
  "Set threshold for THIS to LEVEL.

The implementations should always return THIS.")

;; (lgr-get-threshold :: (function (mixed) int))
(cl-defgeneric lgr-get-threshold (this)
  "Get threshold for THIS.")

(defclass lgr-appender ()
  ((threshold
    :type integer
    :initarg :threshold
    :initform (progn lgr-level-trace)
    :accessor lgr-get-threshold)
   (layout
    :type lgr-layout
    :initarg :layout
    :initform (progn (lgr-layout-format :format "[%t] (%L) %g - %m %f"))
    :accessor lgr-get-layout))
  "Appender manages the output of events to proper destinations.

Destination can be the terminal, a file, an external service, en
Elisp function or anything else in general.

Appenders only handle the *destination* where the event is
output.

Appenders can have thresholds configured independently of
loggers.  For example, one logger can have one file appenders
logging everything and one email appender for errors only.  This
way, all events can be logged to the file but only error and
above will be emailed to a SRE personnel.

To change the way events are formatted, change the layout for
this appender with `lgr-set-layout'.  See `lgr-layout'.")

;; (lgr-set-layout :: (function ((class lgr-appender) (class lgr-layout)) (class lgr-appender)))
(cl-defgeneric lgr-set-layout (this layout)
  "Set the LAYOUT for THIS appender.")

;; (lgr-append :: (function ((class lgr-appender) (class lgr-event)) (class lgr-appender)))
(cl-defgeneric lgr-append (this event)
  "Append EVENT to THIS appender's output.")

(cl-defmethod lgr-to-string ((_this lgr-appender))
  "Format THIS appender as string."
  "Message")

(cl-defmethod lgr-set-threshold ((this lgr-appender) level)
  "Set threshold for THIS appender to LEVEL."
  (oset this threshold level)
  this)

(cl-defmethod lgr-set-layout ((this lgr-appender) (layout lgr-layout))
  "Set layout for THIS appender to LAYOUT."
  (oset this layout layout)
  this)

(cl-defmethod lgr-append ((this lgr-appender) (event lgr-event))
  "Print the EVENT to minibuffer using `message'.

THIS is an appender."
  (message "%s" (lgr-format-event (oref this layout) event))
  this)

(defclass lgr-appender-princ (lgr-appender) ()
  "Print events to standard output using `princ'.")

(cl-defmethod lgr-to-string ((_this lgr-appender-princ))
  "Format THIS appender as string."
  "Princ")

(cl-defmethod lgr-append ((this lgr-appender-princ) (event lgr-event))
  "Print the EVENT to standard output using `princ'.

THIS is an appender."
  (princ (lgr-format-event (oref this layout) event))
  (princ "\n")
  this)

(defclass lgr-appender-file (lgr-appender)
  ((file
    :type string
    :initarg :file
    :documentation "Destination file."))
  "Log events to a file.")

(cl-defmethod lgr-to-string ((this lgr-appender-file))
  "Format THIS appender as string."
  (format "File %s" (oref this file)))

(cl-defmethod lgr-append ((this lgr-appender-file) (event lgr-event))
  "Print the EVENT to a file.

THIS is an appender."
  (let ((msg (lgr-format-event (oref this layout) event)))
    (with-temp-buffer
      (insert msg "\n")
      (append-to-file (point-min) (point-max) (oref this file))))
  this)

(defclass lgr-appender-buffer (lgr-appender)
  ((buffer
    :type (or string buffer)
    :initarg :buffer
    :documentation "Destination buffer."))
  "Log events to a buffer.")

(cl-defmethod lgr-to-string ((this lgr-appender-buffer))
  "Format THIS appender as string."
  (format "%S" (get-buffer-create (oref this buffer))))

(cl-defmethod lgr-append ((this lgr-appender-buffer) (event lgr-event))
  "Print the EVENT to a buffer.

THIS is an appender."
  (let ((msg (lgr-format-event (oref this layout) event)))
    (with-current-buffer (get-buffer-create (oref this buffer))
      (read-only-mode -1)
      (goto-char (point-max))
      (insert msg "\n")
      (read-only-mode 1)))
  this)

(defclass lgr-appender-journald (lgr-appender)
  ((proc
    :type (or process null)
    :initform nil))
  "Log events to systemd journal.

This appender maps the lgr log levels to journald levels in the
following way:

- fatal -> 2 - Critical
- error -> 3 - Error
- warn  -> 4 - Warning
- info  -> 6 - Informational
- debug -> 7 - Debug
- trace -> 7 - Debug")

(cl-defmethod lgr-to-string ((_this lgr-appender-journald))
  "Format THIS appender as string."
  "Journald")

(cl-defmethod lgr-append ((this lgr-appender-journald) (event lgr-event))
  "Log EVENT to journald.

If EVENT's meta contains any of the following, they will be added
to the datagram.

- :SYSLOG_IDENTIFIER (defaults to \"emacs-lgr\")
- :CODE_FILE
- :CODE_LINE
- :CODE_FUNC

Documentation for user journal fields are available at
https://www.freedesktop.org/software/systemd/man/systemd.journal-fields.html"
  (unless (oref this proc)
    (let ((name (generate-new-buffer-name "*lgr-appender-journald*")))
      (oset this proc
            (make-network-process :name name
                                  :buffer (get-buffer-create name)
                                  :type 'datagram
                                  :family 'local
                                  :remote "/run/systemd/journal/socket"))))
  (let* ((level (oref event level))
         (priority (cond
                    ((<= level lgr-level-fatal) 2)
                    ((<= level lgr-level-error) 3)
                    ((<= level lgr-level-warn) 4)
                    ((<= level lgr-level-info) 6)
                    (t 7))))
    (process-send-string
     (oref this proc)
     (format "PRIORITY=%d
SYSLOG_IDENTIFIER=%s%s%s%s
MESSAGE=%s
"
             priority
             (or (plist-get (oref event meta) :SYSLOG_IDENTIFIER)
                 "emacs-lgr")
             (if-let ((cf (plist-get (oref event meta) :CODE_FILE)))
                 (format "CODE_FILE=%s\n" cf)
               "")
             (if-let ((cl (plist-get (oref event meta) :CODE_LINE)))
                 (format "CODE_LINE=%s\n" cl)
               "")
             (if-let ((cf (plist-get (oref event meta) :CODE_FUNC)))
                 (format "CODE_FUNC=%s\n" cf)
               "")
             (lgr-format-event (oref this layout) event)))))

(defclass lgr-appender-warnings (lgr-appender) ()
  "Append messages using `display-warning'.

This appender maps the lgr log levels to warning log levels in
the following way:

- fatal -> :emergency
- error -> :error
- warn  -> :warning
- info  -> :debug
- debug -> :debug
- trace -> :debug")

(cl-defmethod lgr-to-string ((_this lgr-appender-warnings))
  "Format THIS appender as string."
  "Warnings")

(cl-defmethod lgr-append ((this lgr-appender-warnings) (event lgr-event))
  "Display the EVENT using `display-warning'.

THIS is an appender."
  (display-warning
   (mapcar #'intern (split-string (oref event logger-name) "\\."))
   (lgr-format-event (oref this layout) event)
   (let ((level (oref event level)))
     (cond
      ((<= level lgr-level-fatal) :emergency)
      ((<= level lgr-level-error) :error)
      ((<= level lgr-level-warn) :warning)
      (t :debug)))))

(defclass lgr-logger ()
  ((name
    :type string
    :initarg :name
    :documentation "Name of the logger.")
   (threshold
    :type integer
    :initarg :threshold
    :documentation "Threshold for this logger.")
   (propagate
    :type boolean
    :initarg :propagate
    :initform t
    :documentation "If non-nil, propagate events to parent loggers.")
   (parent
    :type (or lgr-logger null)
    :initarg :parent
    :initform nil
    :documentation "Parent logger.")
   (appenders
    :type (list-of lgr-appender)
    :initform nil
    :documentation "List of appenders for this logger."))
  "Logger produces `lgr-event' objects and passes them to appenders.")

(cl-defmethod lgr-set-threshold ((this lgr-logger) level)
  "Set threshold for THIS logger to LEVEL."
  (oset this threshold level)
  this)

(cl-defmethod lgr-get-threshold ((this lgr-logger))
  "Get the threshold of THIS logger or first configured parent.

If this logger has no configured threshold, recursively check the
parents and pick the first one with configured level.

The root logger which is always present has default level info."
  (if (slot-boundp this 'threshold)
      (oref this threshold)
    (when-let ((parent (oref this parent)))
      (lgr-get-threshold parent))))

;; (lgr-set-propagate :: (function ((class lgr-logger) bool) (class lgr-logger)))
(cl-defgeneric lgr-set-propagate (this propagate)
  "Set PROPAGATE for THIS."
  (oset this propagate propagate)
  this)

;; (lgr-add-appender :: (function ((class lgr-logger) (class lgr-appender)) (class lgr-logger)))
(cl-defgeneric lgr-add-appender (this appender)
  "Add APPENDER to THIS logger."
  (oset this appenders
        (append (oref this appenders) (list appender)))
  this)

;; (lgr-remove-appender :: (function ((class lgr-logger) int) (class lgr-logger)))
(cl-defgeneric lgr-remove-appender (this pos)
  "Remove appender at POS from THIS logger."
  (oset this appenders
        (append (seq-take (oref this appenders) (1- pos))
                (seq-drop (oref this appenders) pos)))
  this)

;; (lgr-reset-appenders :: (function ((class lgr-logger)) (class lgr-logger)))
(cl-defgeneric lgr-reset-appenders (this)
  "Remove all appenders from THIS logger."
  (oset this appenders nil)
  this)

;; (lgr-get-appenders :: (function ((class lgr-logger)) (list (class lgr-appender))))
(cl-defgeneric lgr-get-appenders (this)
  "Get all appenders for THIS logger and its parents."
  (append (oref this appenders)
          (when-let ((parent (oref this parent)))
            (when (oref this propagate)
              (lgr-get-appenders parent)))))

(cl-defmethod lgr-log ((this lgr-logger) level message &rest meta)
  "Log MESSAGE as-is at LEVEL.

META arguments are stored as event metadata.

THIS is a logger."
  (when (>= (lgr-get-threshold this) level)
    (let ((event (lgr-event :msg message
                            :level level
                            :timestamp (current-time)
                            :logger-name (oref this name)
                            :meta meta)))
      (dolist (app (lgr-get-appenders this))
        (when (>= (lgr-get-threshold app) (oref event level))
          (lgr-append app event))))))

(defvar lgr--loggers (let ((ht (make-hash-table :test #'equal)))
                       (puthash "lgr--root" (lgr-logger :name "lgr--root" :threshold 400) ht)
                       ht)
  "Hash table of configured loggers.")

;; (lgr-get-all-loggers :: (function () (list (class lgr-logger))))
(defun lgr-get-all-loggers ()
  "Return a list of all configured loggers."
  (hash-table-values lgr--loggers))

(defun lgr--flat-to-tree (lst &optional depth)
  "Convert a flat list LST into a tree.

LST is a list of items (depth logger) which are converted to a
tree structure."
  (setq depth (or depth 0))
  (let ((layer nil)
        (block nil))
    (while lst
      (push (pop lst) block)
      (while (and lst (> (caar lst) depth))
        (push (pop lst) block))
      (push (reverse block) layer)
      (setq block nil))
    (mapcar (lambda (l)
              (append
               (car l)
               (reverse (lgr--flat-to-tree (cdr l) (1+ depth)))))
            layer)))

(defun lgr--graphify (tree &optional prefix)
  "Convert TREE to a graphical tree.

PREFIX is the current string prefix for the processed row.

Return a multi-line string with rendered graph."
  (setq prefix (or prefix ""))
  (cond
   ((consp (car tree))
    (mapcar (lambda (item) (cons prefix (lgr--graphify item prefix))) tree))
   ((null tree)
    (cdr tree))
   (t (let ((head (seq-take tree 2))
            (children (nthcdr 2 tree))
            (index 0))
        (append
         head
         (mapcar
          (lambda (node)
            (prog1 (cond
                    ((= index (1- (length children)))
                     (cons (concat prefix "└─ ")
                           (lgr--graphify node (concat prefix "   "))))
                    (t (cons (concat prefix "├─ ")
                             (lgr--graphify node (concat prefix "│  ")))))
              (cl-incf index)))
          children))))))

(defun lgr--flatten-tree (tree)
  "Flatten a TREE by appending all leaf nodes to a list."
  (if (atom tree)
      (list tree)
    (apply #'append (mapcar #'lgr--flatten-tree tree))))

(defun lgr--level-to-face (level)
  (cond
   ((<= level lgr-level-error) 'error)
   ((<= level lgr-level-warn) 'warning)
   (t 'default)))

(defun lgr-loggers-format-to-tree ()
  "Format all loggers as a tree."
  (interactive)
  (let* ((keys (sort (hash-table-keys lgr--loggers) #'string<))
         (loggers (mapcar
                   (lambda (key)
                     (list (if (equal key "lgr--root") 0
                             (length (split-string key "\\.")))
                           key))
                   keys))
         ;; put the root logger to front
         (loggers (sort loggers (lambda (a _b) (= (car a) 0)))))

    (with-current-buffer (get-buffer-create "*lgr loggers*")
      (read-only-mode -1)
      (erase-buffer)
      (insert "lgr logger hierarchy\n")
      (insert "====================\n\n")
      (insert (propertize "🔇 Loggers without appenders" 'face 'shadow))
      (insert "\n\n")
      (insert (mapconcat
               (lambda (x)
                 (concat
                  (car x)
                  (let* ((logger (gethash (nth 2 x) lgr--loggers))
                         (name (car (last (split-string (oref logger name) "\\."))))
                         (level (and (slot-boundp logger 'threshold)
                                     (oref logger threshold)))
                         (appenders (oref logger appenders))
                         (has-appender (lgr-get-appenders logger)))
                    (format "%s%s%s%s"
                            (if has-appender "" "🔇 ")
                            (propertize name
                                        'font-lock-face (if has-appender 'default 'shadow))
                            (if level
                                (propertize (format " [%s]" (lgr-level-to-name level))
                                            'font-lock-face (lgr--level-to-face level))
                              "")
                            (if appenders
                                (format " > %s" (mapconcat #'lgr-to-string appenders ", "))
                              ""
                              )))))
               (seq-partition
                (lgr--flatten-tree
                 (lgr--graphify
                  (lgr--flat-to-tree loggers)))
                3)
               "\n"))
      (read-only-mode 1)
      (font-lock-mode 1)
      (pop-to-buffer (current-buffer)))))

(defun lgr-get-logger (name &optional logger-class)
  "Return a logger with NAME.

If no logger with NAME exists, create a new one and return it.

The NAME is dot-separated hierarchy of loggers.  For example, the
name \"foo.bar\" will create a logger named \"bar\" with parent
\"foo\".

Each logger has automatically a root logger as parent.  The root
logger is named \"lgr--root\" and has a threshold of 400.  This
logger should not be used directly.

You should always configure at least one top-level logger for
your package named after your package.  This way consumers can
selectively enable or disable logging for your package.

If LOGGER-CLASS is non-nil, use it to create the logger of that
class."
  (setq logger-class (or logger-class 'lgr-logger-format))
  (if-let ((logger (gethash name lgr--loggers)))
      logger
    (let* ((path (split-string name "\\."))
           (parent (if (= (length path) 1)
                       (gethash "lgr--root" lgr--loggers)
                     (lgr-get-logger (string-join (seq-take path (1- (length path))) ".") logger-class)))
           (logger (funcall logger-class :name name :parent parent)))
      (puthash name logger lgr--loggers)
      logger)))

(defclass lgr-logger-format (lgr-logger) ()
  "Logger which uses `format' to format messages.")

;; (lgr--count-format-sequences :: (function (string) int))
(defun lgr--count-format-sequences (string)
  "Count the number of format sequences in STRING."
  (with-temp-buffer
    (insert string)
    (goto-char (point-min))
    (let ((count 0))
      (while (re-search-forward "%" nil t)
        (if (looking-at-p "%")
            (forward-char 1)
          (cl-incf count)))
      count)))

(cl-defmethod lgr-log ((this lgr-logger-format) level fmt &rest meta)
  "Format FMT using `format' drawing values from META.

LEVEL is the log level, see `lgr-log-levels'.

FMT is a `format' compatible format string.

The placeholders in FMT are replaced by arguments from META.  Any
leftover arguments are stored on the event as metadata.

THIS is a logger."
  (when (>= (lgr-get-threshold this) level)
    (let* ((num-of-format-controls (lgr--count-format-sequences fmt))
           (event (lgr-event :msg (apply #'format fmt (seq-take meta num-of-format-controls))
                             :level level
                             :timestamp (current-time)
                             :logger-name (oref this name)
                             :meta (seq-drop meta num-of-format-controls))))
      (dolist (app (lgr-get-appenders this))
        (when (>= (lgr-get-threshold app) (oref event level))
          (lgr-append app event))))))

(provide 'lgr)
;;; lgr.el ends here
