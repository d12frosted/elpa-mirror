;;; taskpaper-mode.el --- Major mode for working with TaskPaper files

;; Copyright 2016-2021 Dmitry Safronov

;; Author: Dmitry Safronov <saf.dmitry@gmail.com>
;; Maintainer: Dmitry Safronov <saf.dmitry@gmail.com>
;; URL: <https://github.com/saf-dmitry/taskpaper-mode>
;; Package-Version: 20210415.1322
;; Package-Commit: 5eacb6c1c879038c4448c10b3df9a73d95a48fc3
;; Keywords: outlines, notetaking, task management, productivity, taskpaper

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; TaskPaper mode is a major mode for working with files in TaskPaper
;; format. The format was invented by Jesse Grosjean and named after his
;; TaskPaper macOS app <https://www.taskpaper.com>, which is a system
;; for organizing your outlines and tasks in a text file.
;;
;; TaskPaper mode is implemented on top of Outline mode. Visibility
;; cycling and structure editing help to work with the outline
;; structure. Special commands also provided for outline-aware filtering,
;; tags manipulation, sorting, refiling, and archiving of items.

;;; Code:

;;;; Features

(require 'outline)
(require 'font-lock)
(require 'easymenu)
(require 'calendar)
(require 'parse-time)
(require 'cal-iso)
(require 'overlay)
(require 'cl-lib)

;;;; Variables

(defconst taskpaper-mode-version "1.0"
  "TaskPaper mode version number.")

(defconst taskpaper-mode-manual-uri
  "https://github.com/saf-dmitry/taskpaper-mode/blob/master/README.md"
  "URI for TaskPaper mode manual.")

(defvar taskpaper-mode-map (make-keymap)
  "Keymap for TaskPaper mode.")

(defvar taskpaper-mode-syntax-table
  (make-syntax-table text-mode-syntax-table)
  "Syntax table for TaskPaper mode.")

(defvar taskpaper-read-date-history nil
  "History list for date prompt.")

(defvar taskpaper-query-history nil
  "History list for query prompt.")

;;;; Custom variables

(defgroup taskpaper nil
  "Major mode for editing and querying files in TaskPaper format."
  :prefix "taskpaper-"
  :group 'wp
  :group 'text
  :group 'applications)

(defcustom taskpaper-faces-easy-properties :foreground
  "The property changes by easy faces.
The value can be :foreground or :background. A color string for
specific tags will then be interpreted as either foreground or
background color. For more details see custom variable
`taskpaper-tag-faces'."
  :group 'taskpaper
  :type '(choice (const :foreground)
                 (const :background)))

(defcustom taskpaper-tag-faces nil
  "Faces for specific tags.
This is a list of cons cells, with tag names in the car and faces
in the cdr. The tag name can basically contain uppercase and
lowercase letters, digits, hyphens, underscores, and dots. The
face can be a symbol corresponding to a name of an existing face,
a color (in which case it will be interpreted as either
foreground or background color according to the variable
`taskpaper-faces-easy-properties' and the rest is inherited from
the face `taskpaper-tag') or a property list of attributes,
like (:foreground \"blue\" :weight bold)."
  :group 'taskpaper
  :type '(repeat
          (cons (string :tag "Tag name")
                (choice :tag "Face"
                        (string :tag "Color")
                        (sexp :tag "Face")))))

(defcustom taskpaper-tag-alist nil
  "List of tags for fast selection.
The value of this variable is an alist, the car of each entry
must be a tag as a string, the cdr may be a character that is
used to select that tag through the fast-selection interface."
  :group 'taskpaper
  :type '(repeat
          (cons (string :tag "Tag name")
                (character :tag "Access char"))))

(defcustom taskpaper-tags-exclude-from-inheritance nil
  "List of tags that should never be inherited."
  :group 'taskpaper
  :type '(repeat (string :tag "Tag name")))

(defcustom taskpaper-tags-to-remove-when-done nil
  "List of tags to remove when completing item."
  :group 'taskpaper
  :type '(repeat (string :tag "Tag name")))

(defcustom taskpaper-complete-save-date 'date
  "Non-nil means, include date when completing item.
Possible values for this option are:

 nil   No date
 date  Include date
 time  Include date and time"
  :group 'taskpaper
  :type '(choice
          (const :tag "No date" nil)
          (const :tag "Date" date)
          (const :tag "Date and time" time)))

(defcustom taskpaper-blocker-hook nil
  "Hook for functions that are allowed to block completion of item.
The value of this hook may be nil, a function, or a list of
functions. Functions in this hook should not modify the buffer.
Each function gets as its single argument a buffer position at
the beginning of item. If any of the functions in this hook
returns nil, the completion is blocked."
  :group 'taskpaper
  :type 'hook)

(defcustom taskpaper-after-completion-hook nil
  "Hook run when completing item."
  :group 'taskpaper
  :type 'hook)

(defcustom taskpaper-read-date-popup-calendar t
  "Non-nil means, pop up a calendar when prompting for a date."
  :group 'taskpaper
  :type 'boolean)

(defcustom taskpaper-read-date-display-live t
  "Non-nil means, display the date prompt interpretation live."
  :group 'taskpaper
  :type 'boolean)

(defcustom taskpaper-startup-folded nil
  "Non-nil means, switch to Overview when entering TaskPaper mode."
  :group 'taskpaper
  :type 'boolean)

(defcustom taskpaper-startup-with-inline-images nil
  "Non-nil means, show inline images when entering TaskPaper mode."
  :group 'taskpaper
  :type 'boolean)

(defcustom taskpaper-max-image-size nil
  "Maximum width and height for displayed inline images.
This variable may be nil or a cons cell with maximum width in the
car and maximum height in the cdr, in pixels. When nil, use the
actual size. Otherwise, use ImageMagick to resize larger images.
This requires Emacs to be built with ImageMagick support."
  :group 'taskpaper
  :type '(choice
          (const :tag "Actual size" nil)
          (cons (choice (sexp :tag "Maximum width")
                        (const :tag "No maximum width" nil))
                (choice (sexp :tag "Maximum height")
                        (const :tag "No maximum height" nil)))))

(defcustom taskpaper-after-sorting-items-hook nil
  "Hook run after sorting of items.
When children are sorted, the cursor is in the parent line when
this hook gets called."
  :group 'taskpaper
  :type 'hook)

(defcustom taskpaper-archive-location "%s_archive.taskpaper::"
  "The location where subtrees should be archived.

The value of this variable is a string, consisting of two parts,
separated by a double-colon. The first part is a filename and the
second part is a heading.

When the filename is omitted, archiving happens in the same file.
A %s formatter in the filename will be replaced by the current
file name without the directory part and file extension.

The archived items will be filed as subtrees of the specified
item. When the heading is omitted, the subtrees are simply filed
away at the end of the file, as top-level items. Also in the
heading you can use %s to represent the file name, this can be
useful when using the same archive for a number of different
files."
  :group 'taskpaper
  :type 'string)

(defcustom taskpaper-archive-save-context nil
  "Non-nil means, add context information when archiving."
  :group 'taskpaper
  :type 'boolean)

(defcustom taskpaper-archive-hook nil
  "Hook run after successfully archiving a subtree.
Hook functions are called with point on the subtree in the
original location. At this stage, the subtree has been added to
the archive location, but not yet deleted from the original
location."
  :group 'taskpaper
  :type 'hook)

(defcustom taskpaper-reverse-note-order nil
  "Non-nil means, store new notes at the beginning of item."
  :group 'taskpaper
  :type 'boolean)

(defcustom taskpaper-file-apps
  '((directory . emacs)
    (remote    . emacs)
    (auto-mode . emacs))
  "External applications for opening file links in a document.
The entries in this list are cons cells where the car identifies
files and the cdr the corresponding command.

Possible values for the file identifier are:
 \"string\"   Matches files with this extension
 directory  Matches directories
 remote     Matches remote files
 auto-mode  Matches files that are matched by any entry in `auto-mode-alist'
 system     The system command to open files
 t          Default for files not matched by any of the other options

Possible values for the command are:
 \"string\"   A command to be executed by a shell;
            a %s formatter will be replaced by the file name
 emacs      The file will be visited by the current Emacs process
 default    Use the default application for this file type
 system     Use the system command for opening files
 mailcap    Use command specified in the mailcaps
 function   A Lisp function, which will be called with one argument:
            the file path

See also variable `taskpaper-open-non-existing-files'."
  :group 'taskpaper
  :type '(repeat
          (cons
           (choice :value ""
                   (string :tag "Extension")
                   (const :tag "System command to open files" system)
                   (const :tag "Default for unrecognized files" t)
                   (const :tag "Remote file" remote)
                   (const :tag "Links to a directory" directory)
                   (const :tag "Any files that have Emacs modes" auto-mode))
           (choice :value ""
                   (const :tag "Visit with Emacs" emacs)
                   (const :tag "Use default" default)
                   (const :tag "Use the system command" system)
                   (string :tag "Command")
                   (sexp :tag "Lisp form")))))

(defcustom taskpaper-open-non-existing-files nil
  "Non-nil means, open non-existing files in file links.
When nil, an error will be generated. This variable applies only
to external applications because they might choke on non-existing
files. If the link is to a file that will be opened in Emacs, the
variable is ignored."
  :group 'taskpaper
  :type 'boolean)

(defcustom taskpaper-mark-ring-length 4
  "Number of different positions to be recorded in the ring.
Changing this option requires a restart of Emacs."
  :group 'taskpaper
  :type 'integer)

(defcustom taskpaper-custom-queries nil
  "List of custom queries for fast selection.
The value of this variable is a list, the first element is a
character that is used to select that query through the
fast-selection interface, the second element is a short
description string, and the last is a query string. If the first
element is a string, it will be used as block separator."
  :group 'taskpaper
  :type '(repeat
          (choice (list (character :tag "Access char")
                        (string :tag "Description")
                        (string :tag "Query string"))
                  (string :tag "Block separator"))))

(defcustom taskpaper-iquery-default nil
  "Non-nil means, querying commands will use `taskpaper-iquery'
instead of default `taskpaper-query'."
  :group 'taskpaper
  :type 'boolean)

(defcustom taskpaper-iquery-delay 0.1
  "The number of seconds to wait before evaluating incremental
query."
  :group 'taskpaper
  :type 'number)

(defcustom taskpaper-pretty-task-marks t
  "Non-nil means, enable the composition display of task marks.
This does not change the underlying buffer content, but it
overlays the UTF-8 character for display purposes only."
  :group 'taskpaper
  :type 'boolean)

(defcustom taskpaper-bullet ?\u2013
  "Display character for task mark."
  :group 'taskpaper
  :type 'character)

(defcustom taskpaper-bullet-done ?\u2013
  "Display character for done task mark."
  :group 'taskpaper
  :type 'character)

(defcustom taskpaper-fontify-done-items t
  "Non-nil means, fontify completed items."
  :group 'taskpaper
  :type 'boolean)

(defcustom taskpaper-hide-markup nil
  "Non-nil means, hide inline markup characters."
  :group 'taskpaper
  :type 'boolean)
(make-variable-buffer-local 'taskpaper-hide-markup)

(defcustom taskpaper-use-inline-emphasis t
  "Non-nil means, interpret emphasis delimiters for display.
This will interpret \"*\" and \"_\" characters as inline emphasis
delimiters for strong and emphasis markup similar to Markdown."
  :group 'taskpaper
  :type 'boolean)

(defcustom taskpaper-mode-hook nil
  "Hook run when entering `taskpaper-mode'."
  :group 'taskpaper
  :type 'hook)

;;;; Compatibility code for older Emacsen

(unless (fboundp 'string-remove-prefix)
  (defun string-remove-prefix (prefix string)
    "Remove PREFIX from STRING if present."
    (if (string-prefix-p prefix string)
        (substring string (length prefix))
      string)))

(unless (fboundp 'string-remove-suffix)
  (defun string-remove-suffix (suffix string)
    "Remove SUFFIX from STRING if present."
    (if (string-suffix-p suffix string)
        (substring string 0 (- (length string) (length suffix)))
      string)))

;;;; Generally useful functions

(defun taskpaper-mode-version ()
  "Show TaskPaper mode version."
  (interactive)
  (message "TaskPaper mode version %s" taskpaper-mode-version))

(defun taskpaper-mode-browse-manual ()
  "Browse TaskPaper mode manual."
  (interactive)
  (browse-url taskpaper-mode-manual-uri))

(defun taskpaper-overlay-display (overlay text &optional face evap)
  "Make OVERLAY display TEXT with face FACE.
When EVAP is non-nil, set the 'evaporate' property to t."
  (overlay-put overlay 'display text)
  (when face (overlay-put overlay 'face face))
  (when evap (overlay-put overlay 'evaporate t)))

(defun taskpaper-new-marker (&optional pos)
  "Return a new marker at POS.
If POS is omitted or nil, the value of point is used by default."
  (let ((marker (copy-marker (or pos (point)) t))) marker))

(defsubst taskpaper-get-at-bol (prop)
  "Get text property PROP at the beginning of line."
  (get-text-property (point-at-bol) prop))

(defun taskpaper-release-buffers (blist)
  "Release all buffers in list BLIST.
When a buffer is modified, it is saved after user confirmation."
  (let (file)
    (dolist (buf blist)
      (setq file (buffer-file-name buf))
      (when (and (buffer-modified-p buf) file
                 (y-or-n-p (format "Save file %s? " file)))
        (with-current-buffer buf (save-buffer)))
      (kill-buffer buf))))

(defun taskpaper-find-base-buffer-visiting (file)
  "Return the base buffer visiting FILE.
Like `find-buffer-visiting' but always return the base buffer."
  (let ((buf (or (get-file-buffer file)
                 (find-buffer-visiting file))))
    (if buf (or (buffer-base-buffer buf) buf) nil)))

(defun taskpaper-in-regexp (regexp &optional pos)
  "Return non-nil if POS is in a match for REGEXP.
Set the match data. If POS is omitted or nil, the value of point
is used by default. Only the current line is checked."
  (catch 'exit
    (let ((pos (or pos (point)))
          (eol (line-end-position 1)))
      (save-excursion
        (goto-char pos) (beginning-of-line 1)
        (while (re-search-forward regexp eol t)
          (when (and (>= pos (match-beginning 0))
                     (<= pos (match-end 0)))
            (throw 'exit (cons (match-beginning 0)
                               (match-end 0)))))))))

(defsubst taskpaper-set-local (var value)
  "Make VAR local in the current buffer and set it to VALUE."
  (set (make-local-variable var) value))

(defsubst taskpaper-uniquify (list)
  "Non-destructively remove duplicate elements from LIST."
  (let ((res (copy-sequence list))) (delete-dups res)))

(defsubst taskpaper-sort (list)
  "Non-destructively sort elements of LIST as strings."
  (let ((res (copy-sequence list))) (sort res 'string-lessp)))

(defun taskpaper-trim-string (str)
  "Trim leading and trailing whitespaces from STR."
  (when (stringp str)
    (save-match-data
      (while (string-match "\\`[ \t\n\r]+\\|[ \t\n\r]+\\'" str)
        (setq str (replace-match "" t t str)))))
  str)

(defun taskpaper-unlogged-message (&rest args)
  "Display a message without logging."
  (let ((message-log-max nil)) (apply 'message args)))

(defun taskpaper-escape-double-quotes (str)
  "Escape double quotation marks in STR."
  (when (stringp str)
    (setq str (replace-regexp-in-string "\"" "\\\\\"" str)))
  str)

(defun taskpaper-unescape-double-quotes (str)
  "Unescape double quotation marks in STR."
  (when (stringp str)
    (setq str (replace-regexp-in-string "\\\\\"" "\"" str)))
  str)

(defun taskpaper-file-path-escape (path)
  "Escape special characters in PATH."
  (when (stringp path)
    (setq path (replace-regexp-in-string " " "\\\\ " path)))
  path)

(defun taskpaper-file-path-unescape (path)
  "Unescape special characters in PATH."
  (when (stringp path)
    (setq path (replace-regexp-in-string "\\\\ " " " path)))
  path)

(defun taskpaper-file-missing-p (file)
  "Test if local FILE exists.
Return non-nil if local FILE does not exist, otherwise return
nil. For performance reasons remote files are not checked."
  (if (and (not (file-remote-p file)) (not (file-exists-p file)))
      t
    nil))

(defun taskpaper-file-image-p (file)
  "Return non-nil if FILE is an image file."
  (string-match-p (image-file-name-regexp) file))

(defsubst taskpaper-rear-nonsticky-at (pos)
  "Add nonsticky text properties at POS."
  (add-text-properties
   (1- pos) pos
   (list 'rear-nonsticky
         '(face mouse-face keymap help-echo display invisible intangible))))

(defconst taskpaper-markup-properties
  '(face taskpaper-markup taskpaper-syntax markup invisible taskpaper-markup)
  "Properties to apply to inline markup.")

(defun taskpaper-range-property-any (begin end prop vals)
  "Check property PROP from BEGIN to END.
Return non-nil if at least one character between BEGIN and END
has a property PROP whose value is one of the given values VALS."
  (cl-some (lambda (val) (text-property-any begin end prop val)) vals))

(defun taskpaper-remove-markup-chars (s)
  "Remove markup characters from propertized string S."
  (let (b)
    (while (setq b (text-property-any
                    0 (length s)
                    'invisible 'taskpaper-markup s))
      (setq s (concat
               (substring s 0 b)
               (substring s (or (next-single-property-change
                                 b 'invisible s)
                                (length s)))))))
  s)

(defun taskpaper-remove-flyspell-overlays-in (begin end)
  "Remove Flyspell overlays in region between BEGIN and END."
  (and (bound-and-true-p flyspell-mode)
       (fboundp 'flyspell-delete-region-overlays)
       (flyspell-delete-region-overlays begin end)))

(defun taskpaper-remap (map &rest commands)
  "In keymap MAP, remap the functions given in COMMANDS.
COMMANDS is a list of alternating OLDDEF NEWDEF command names."
  (let (olddef newdef)
    (while commands
      (setq olddef (pop commands) newdef (pop commands))
      (if (fboundp 'command-remapping)
          (define-key map (vector 'remap olddef) newdef)
        (substitute-key-definition olddef newdef map global-map)))))

(defun taskpaper-add-tag-prefix (name)
  "Add tag prefix to NAME.
NAME should be a string or a list of strings."
  (cond
   ((stringp name)
    (if (string-prefix-p "@" name) name (concat "@" name)))
   ((and (listp name) (cl-every 'stringp name))
    (mapcar #'(lambda (x) (if (string-prefix-p "@" x) x (concat "@" x))) name))
   (t (error "Argument should be a string or a list of strings."))))

(defun taskpaper-remove-tag-prefix (name)
  "Remove tag prefix from NAME.
NAME should be a string or a list of strings."
  (cond
   ((stringp name)
    (string-remove-prefix "@" name))
   ((and (listp name) (cl-every 'stringp name))
    (mapcar #'(lambda (x) (string-remove-prefix "@" x)) name))
   (t (error "Argument should be a string or a list of strings."))))

(defun taskpaper-kill-is-subtree-p (&optional text)
  "Check if the current kill is a valid subtree.
Return nil if the first item level is not the largest item level
in the tree. So this will actually accept a set of subtrees as
well. If optional TEXT string is given, check it instead of the
current kill."
  (save-match-data
    (let* ((kill (or text (and kill-ring (current-kill 0)) ""))
           (start-level (and (string-match "\\`\\([\t]*[^\t\f\n]\\)" kill)
                             (- (match-end 1) (match-beginning 1))))
           (start (1+ (or (match-beginning 1) -1))))
      (if (not start-level) nil
        (catch 'exit
          (while (setq start (string-match
                              "^\\([\t]*[^\t\f\n]\\)" kill (1+ start)))
            (when (< (- (match-end 1) (match-beginning 1)) start-level)
              (throw 'exit nil)))
          t)))))

;;;; Re-usable regexps

(defconst taskpaper-tag-name-char-regexp
  (concat
   "[-a-zA-Z0-9._\u00b7\u0300-\u036f\u203f-\u2040"
   "\u00c0-\u00d6\u00d8-\u00f6\u00f8-\u02ff\u0370-\u037d"
   "\u037f-\u1fff\u200c-\u200d\u2070-\u218f\u2c00-\u2fef"
   "\u3001-\ud7ff\uf900-\ufdcf\ufdf0-\ufffd]")
  "Regular expression matching valid tag name character.")

(defconst taskpaper-tag-name-regexp
  (format "%s+" taskpaper-tag-name-char-regexp)
  "Regular expression matching tag name.")

(defconst taskpaper-tag-value-regexp
  "\\(?:\\\\(\\|\\\\)\\|[^()\n]\\)*"
  "Regular expression matching tag value.")

(defconst taskpaper-tag-regexp
  (format "\\(?:^\\|\\s-+\\)\\(@\\(%s\\)\\(?:(\\(%s\\))\\)?\\)"
          taskpaper-tag-name-regexp
          taskpaper-tag-value-regexp)
  "Regular expression matching tag.
Group 1 matches the whole tag expression.
Group 2 matches the tag name without tag indicator.
Group 3 matches the optional tag value without enclosing parentheses.")

(defconst taskpaper-consec-tags-regexp
  (format "\\(?:%s\\)+" taskpaper-tag-regexp)
  "Regular expression matching multiple consecutive tags.")

(defconst taskpaper-email-regexp
  (concat
   "\\("
   "\\(?:\\<mailto:\\)?"
   "[[:alnum:]!#$%&'*+./=?^_`{|}~-]+@"
   "[[:alnum:]]\\(?:[[:alnum:]-]\\{0,61\\}[[:alnum:]]\\)?"
   "\\(?:[.][[:alnum:]]\\(?:[[:alnum:]-]\\{0,61\\}[[:alnum:]]\\)?\\)*"
   "\\)")
  "Regular expression matching plain email link.")

(defconst taskpaper-file-path-regexp
  (concat
   "\\("
   "\\(?:~\\|[.][.]?\\|[a-zA-Z][:]\\)?[/]\\(?:\\\\ \\|[^ \0\n]\\)+"
   "\\)")
  "Regular expression matching file path.")

(defconst taskpaper-file-link-regexp
  (concat "\\(?:^\\|\\s-\\)" taskpaper-file-path-regexp)
  "Regular expression matching plain file link.")

(defconst taskpaper-uri-regexp
  (concat
   "\\<\\("
   "\\(?:"
   "[a-zA-Z][-a-zA-Z0-9.+]\\{1,31\\}[:]"
   "\\(?:[/]\\{1,3\\}\\|[[:alnum:]%]\\)"
   "\\|"
   "www[[:digit:]]\\{0,3\\}[.]"
   "\\)"
   "\\(?:"
   "[^[:space:]()<>]"
   "\\|"
   "(\\(?:[^[:space:]()<>]+\\|([^[:space:]()<>]+)\\)*)"
   "\\)+"
   "\\(?:"
   "(\\(?:[^[:space:]()<>]+\\|([^[:space:]()<>]+)\\)*)"
   "\\|"
   "[^[:space:][:punct:]]"
   "\\|"
   "[/]"
   "\\)"
   "\\)")
  "Regular expression matching generic URI.")

(defconst taskpaper-markdown-link-regexp
  (concat
   "\\("
   "\\(\\[\\)"
   "\\([^][\n]+\\)"
   "\\(\\]\\)"
   "\\((\\)"
   "\\("
   "\\(?:"
   "\\\\ "
   "\\|"
   "[^[:space:]()]"
   "\\|"
   "(\\(?:[^[:space:]()]+\\|([^[:space:]()]+)\\)*)"
   "\\)+"
   "\\)"
   "\\()\\)"
   "\\)")
  "Regular expression matching Markdown link.
Group 1 matches the entire link expression.
Group 2 matches the opening square bracket.
Group 3 matches the link description.
Group 4 matches the closing square bracket.
Group 5 matches the opening parenthesis.
Group 6 matches the link destination.
Group 7 matches the closing parenthesis.")

(defconst taskpaper-any-link-regexp
  (format "\\(%s\\)\\|\\(%s\\)\\|\\(%s\\)\\|\\(%s\\)"
          taskpaper-uri-regexp
          taskpaper-email-regexp
          taskpaper-file-link-regexp
          taskpaper-markdown-link-regexp)
  "Regular expression matching any link.")

;;;; Font Lock regexps

(defconst taskpaper-task-regexp
  "^[ \t]*\\(\\([-+*]\\) +\\([^\n]*\\)\\)$"
  "Regular expression matching task.
Group 1 matches the whole task expression.
Group 2 matches the task mark.
Group 3 matches the task name.")

(defconst taskpaper-project-regexp
  (format
   "^[ \t]*\\(\\([^\n]*\\)\\(:\\)\\(%s\\)?\\)$"
   taskpaper-consec-tags-regexp)
  "Regular expression matching project.
Group 1 matches the whole project expression.
Group 2 matches the project name.
Group 3 matches the project mark.
Group 4 matches optional trailing tags.")

(defconst taskpaper-note-regexp
  "^[ \t]*\\(.*\\S-.*\\)$"
  "Regular expression matching note.
Group 1 matches the whole note expression.")

(defconst taskpaper-emphasis-prefix-regexp
  "\\(?:^\\|[^\n*_\\]\\)"
  "Regular expression matching emphasis prefix.")

(defconst taskpaper-emphasis-suffix-regexp
  "\\(?:[^\n*_]\\|$\\)"
  "Regular expression matching emphasis suffix.")

(defconst taskpaper-emphasis-text-regexp
  (concat
   "\\(?:"
   "\\(?:\\\\.\\|[^[:space:]*_\\]\\)"
   "\\|"
   "[^[:space:]*_][^\n]*?\\(?:\\\\.\\|[^[:space:]*_\\]\\)"
   "\\)")
  "Regular expression matching emphasis text.")

(defconst taskpaper-strong-regexp
  (format "%s\\(\\(\\*\\*\\|__\\)\\(%s\\)\\(\\2\\)\\)%s"
          taskpaper-emphasis-prefix-regexp
          taskpaper-emphasis-text-regexp
          taskpaper-emphasis-suffix-regexp)
  "Regular expression matching strong inline emphasis.
Group 1 matches the entire expression.
Group 2 matches the opening delimiters.
Group 3 matches the text inside the delimiters.
Group 4 matches the closing delimiters.")

(defconst taskpaper-emphasis-regexp
  (format "%s\\(\\(\\*\\|_\\)\\(%s\\)\\(\\2\\)\\)%s"
          taskpaper-emphasis-prefix-regexp
          taskpaper-emphasis-text-regexp
          taskpaper-emphasis-suffix-regexp)
  "Regular expression matching inline emphasis.
Group 1 matches the entire expression.
Group 2 matches the opening delimiters.
Group 3 matches the text inside the delimiters.
Group 4 matches the closing delimiters.")

;;;; Faces

(defgroup taskpaper-faces nil
  "Faces used in TaskPaper mode."
  :group 'taskpaper
  :group 'faces)

(defface taskpaper-project-name
  '((t :inherit font-lock-function-name-face))
  "Face for project names."
  :group 'taskpaper-faces)

(defface taskpaper-project-mark
  '((t :inherit taskpaper-project-name))
  "Face for project marks."
  :group 'taskpaper-faces)

(defface taskpaper-task
  '((t :inherit default))
  "Face for tasks."
  :group 'taskpaper-faces)

(defface taskpaper-task-undone-mark
  '((t :inherit taskpaper-task))
  "Face for undone task marks."
  :group 'taskpaper-faces)

(defface taskpaper-task-done-mark
  '((t :inherit taskpaper-task))
  "Face for done task marks."
  :group 'taskpaper-faces)

(defface taskpaper-done-item
  `((t :strike-through ,(face-attribute 'shadow :foreground)))
  "Face for items marked as complete."
  :group 'taskpaper-faces)

(defface taskpaper-note
  '((t :inherit font-lock-comment-face))
  "Face for notes."
  :group 'taskpaper-faces)

(defface taskpaper-tag
  '((t :inherit shadow))
  "Face for tags."
  :group 'taskpaper-faces)

(defface taskpaper-link
  '((t :inherit link))
  "Face for links."
  :group 'taskpaper-faces)

(defface taskpaper-missing-link
  '((t :foreground "red" :inherit link))
  "Face for file links to non-existing files."
  :group 'taskpaper-faces)

(defface taskpaper-emphasis
  '((t (:inherit italic)))
  "Face for inline emphasis."
  :group 'taskpaper-faces)

(defface taskpaper-strong
  '((t (:inherit bold)))
  "Face for strong inline emphasis."
  :group 'taskpaper-faces)

(defface taskpaper-markup
  '((t (:slant normal :weight normal :inherit shadow)))
  "Face for markup elements."
  :group 'taskpaper-faces)

(defface taskpaper-query-error
  '((t :foreground "red" :inherit default))
  "Face for malformed query string."
  :group 'taskpaper-faces)

(defface taskpaper-query-secondary-text
  '((t :inherit shadow))
  "Face for secondary text in query string."
  :group 'taskpaper-faces)

(defface taskpaper-fast-select-key
  '((t :weight bold :inherit default))
  "Face for selection keys in fast selection dialogs."
  :group 'taskpaper-faces)

;;;; Font Lock

(defun taskpaper-face-from-face-or-color (inherit face-or-color)
  "Create a face list that set the color and inherits INHERIT.
When FACE-OR-COLOR is not a string, just return it."
  (if (stringp face-or-color)
      (list :inherit inherit
            taskpaper-faces-easy-properties face-or-color)
    face-or-color))

(defun taskpaper-get-tag-face (tag)
  "Get the right face for TAG.
If TAG is a number, get the corresponding match group."
  (let ((tag (if (wholenump tag) (match-string tag) tag)))
    (or (taskpaper-face-from-face-or-color
         'taskpaper-tag (cdr (assoc tag taskpaper-tag-faces)))
        'taskpaper-tag)))

(defvar taskpaper-mouse-map-tag
  (let ((map (make-sparse-keymap)))
    (define-key map [mouse-1] 'taskpaper-query-tag-at-point)
    map)
  "Mouse events for tags.")

(defun taskpaper-font-lock-tags (limit)
  "Fontify tags from point to LIMIT."
  (when (re-search-forward taskpaper-tag-regexp limit t)
    (if (not (taskpaper-in-tag-p))
        ;; Move forward and recursively search again
        (progn
          (goto-char (min (1+ (match-beginning 1)) limit))
          (when (< (point) limit)
            (taskpaper-font-lock-tags limit)))
      ;; Fontify
      (taskpaper-remove-flyspell-overlays-in
       (match-beginning 1) (match-end 1))
      (add-text-properties
       (match-beginning 1) (match-end 1)
       (list 'taskpaper-syntax 'tag
             'face (taskpaper-get-tag-face 2)
             'mouse-face 'highlight
             'keymap taskpaper-mouse-map-tag))
      (taskpaper-rear-nonsticky-at (match-end 1)))
    t))

(defun taskpaper-get-link-type (link)
  "Return link type as symbol.
LINK should be an unescaped raw link. Recognized types are 'uri,
'email, 'file, or nil."
  (let* ((fmt "\\`%s\\'")
         (re-file  (format fmt taskpaper-file-path-regexp))
         (re-email (format fmt taskpaper-email-regexp))
         (re-uri   (format fmt taskpaper-uri-regexp)))
    (cond ((string-match-p re-file  link) 'file)
          ((string-match-p re-email link) 'email)
          ((string-match-p re-uri   link) 'uri)
          (t nil))))

(defun taskpaper-get-link-face (link)
  "Get the right face for LINK."
  (if (and (eq (taskpaper-get-link-type link) 'file)
           (taskpaper-file-missing-p
            (expand-file-name (taskpaper-file-path-unescape link))))
      'taskpaper-missing-link
    'taskpaper-link))

(defvar taskpaper-mouse-map-link
  (let ((map (make-sparse-keymap)))
    (define-key map [mouse-1] 'taskpaper-open-link-at-point)
    map)
  "Mouse events for links.")

(defun taskpaper-font-lock-markdown-links (limit)
  "Fontify Markdown links from point to LIMIT."
  (when (re-search-forward taskpaper-markdown-link-regexp limit t)
    (taskpaper-remove-flyspell-overlays-in
     (match-beginning 1) (match-end 1))
    (let ((link (match-string-no-properties 6)))
      (add-text-properties
       (match-beginning 3) (match-end 3)
       (list 'taskpaper-syntax 'markdown-link
             'face (taskpaper-get-link-face link)
             'mouse-face 'highlight
             'keymap taskpaper-mouse-map-link
             'help-echo link)))
    (add-text-properties
     (match-beginning 2) (match-end 2) taskpaper-markup-properties)
    (add-text-properties
     (match-beginning 4) (match-end 7) taskpaper-markup-properties)
    (taskpaper-rear-nonsticky-at (match-end 1))
    t))

(defun taskpaper-font-lock-email-links (limit)
  "Fontify plain email links from point to LIMIT."
  (when (re-search-forward taskpaper-email-regexp limit t)
    (if (taskpaper-range-property-any
         (match-beginning 1) (match-end 1)
         'taskpaper-syntax '(markup))
        ;; Move forward and recursively search again
        (progn
          (goto-char (min (1+ (match-beginning 1)) limit))
          (when (< (point) limit)
            (taskpaper-font-lock-email-links limit)))
      ;; Fontify
      (taskpaper-remove-flyspell-overlays-in
       (match-beginning 1) (match-end 1))
      (let ((link (match-string-no-properties 1)))
        (add-text-properties
         (match-beginning 1) (match-end 1)
         (list 'taskpaper-syntax 'plain-link
               'face (taskpaper-get-link-face link)
               'mouse-face 'highlight
               'keymap taskpaper-mouse-map-link
               'help-echo link)))
      (taskpaper-rear-nonsticky-at (match-end 1))
      t)))

(defun taskpaper-font-lock-uri-links (limit)
  "Fontify plain URI links from point to LIMIT."
  (when (re-search-forward taskpaper-uri-regexp limit t)
    (if (taskpaper-range-property-any
         (match-beginning 1) (match-end 1)
         'taskpaper-syntax '(markup))
        ;; Move forward and recursively search again
        (progn
          (goto-char (min (1+ (match-beginning 1)) limit))
          (when (< (point) limit)
            (taskpaper-font-lock-uri-links limit)))
      ;; Fontify
      (taskpaper-remove-flyspell-overlays-in
       (match-beginning 1) (match-end 1))
      (let ((link (match-string-no-properties 1)))
        (add-text-properties
         (match-beginning 1) (match-end 1)
         (list 'taskpaper-syntax 'plain-link
               'face (taskpaper-get-link-face link)
               'mouse-face 'highlight
               'keymap taskpaper-mouse-map-link
               'help-echo link)))
      (taskpaper-rear-nonsticky-at (match-end 1))
      t)))

(defun taskpaper-font-lock-file-links (limit)
  "Fontify plain file links from point to LIMIT."
  (when (re-search-forward taskpaper-file-link-regexp limit t)
    (if (taskpaper-range-property-any
         (match-beginning 1) (match-end 1)
         'taskpaper-syntax '(markup))
        ;; Move forward and recursively search again
        (progn
          (goto-char (min (1+ (match-beginning 1)) limit))
          (when (< (point) limit)
            (taskpaper-font-lock-file-links limit)))
      ;; Fontify
      (taskpaper-remove-flyspell-overlays-in
       (match-beginning 1) (match-end 1))
      (let ((link (match-string-no-properties 1)))
        (add-text-properties
         (match-beginning 1) (match-end 1)
         (list 'taskpaper-syntax 'plain-link
               'face (taskpaper-get-link-face link)
               'mouse-face 'highlight
               'keymap taskpaper-mouse-map-link
               'help-echo link)))
      (taskpaper-rear-nonsticky-at (match-end 1))
      t)))

(defun taskpaper-font-lock-done-tasks (limit)
  "Fontify completed tasks from point to LIMIT."
  (when (re-search-forward taskpaper-task-regexp limit t)
    (when (save-excursion
            (save-match-data
              (taskpaper-item-has-attribute "done")))
      (font-lock-prepend-text-property
       (match-beginning 2) (match-end 2)
       'face 'taskpaper-task-done-mark)
      (font-lock-prepend-text-property
       (match-beginning 3) (match-end 3)
       'face 'taskpaper-done-item))
    t))

(defun taskpaper-font-lock-done-projects (limit)
  "Fontify completed projects from point to LIMIT."
  (when (re-search-forward taskpaper-project-regexp limit t)
    (when (save-excursion
            (save-match-data
              (taskpaper-item-has-attribute "done")))
      (font-lock-prepend-text-property
       (match-beginning 1) (match-end 1)
       'face 'taskpaper-done-item))
    t))

(defun taskpaper-font-lock-strong (limit)
  "Fontify strong inline emphasis from point to LIMIT."
  (when (re-search-forward taskpaper-strong-regexp limit t)
    (if (or (taskpaper-range-property-any
             (match-beginning 2) (match-end 2)
             'taskpaper-syntax '(markup plain-link tag))
            (taskpaper-range-property-any
             (match-beginning 4) (match-end 4)
             'taskpaper-syntax '(markup plain-link tag)))
        ;; Move forward and recursively search again
        (progn
          (goto-char (min (1+ (match-beginning 1)) limit))
          (when (< (point) limit)
            (taskpaper-font-lock-strong limit)))
      ;; Fontify
      (put-text-property
       (match-beginning 1) (match-end 1) 'taskpaper-syntax 'strong)
      (font-lock-prepend-text-property
       (match-beginning 3) (match-end 3) 'face 'taskpaper-strong)
      (add-text-properties
       (match-beginning 2) (match-end 2) taskpaper-markup-properties)
      (add-text-properties
       (match-beginning 4) (match-end 4) taskpaper-markup-properties)
      (backward-char 1)
      t)))

(defun taskpaper-font-lock-emphasis (limit)
  "Fontify inline emphasis from point to LIMIT."
  (when (re-search-forward taskpaper-emphasis-regexp limit t)
    (if (or (taskpaper-range-property-any
             (match-beginning 2) (match-end 2)
             'taskpaper-syntax '(markup plain-link tag))
            (taskpaper-range-property-any
             (match-beginning 4) (match-end 4)
             'taskpaper-syntax '(markup plain-link tag)))
        ;; Move forward and recursively search again
        (progn
          (goto-char (min (1+ (match-beginning 1)) limit))
          (when (< (point) limit)
            (taskpaper-font-lock-emphasis limit)))
      ;; Fontify
      (put-text-property
       (match-beginning 1) (match-end 1) 'taskpaper-syntax 'emphasis)
      (font-lock-prepend-text-property
       (match-beginning 3) (match-end 3) 'face 'taskpaper-emphasis)
      (add-text-properties
       (match-beginning 2) (match-end 2) taskpaper-markup-properties)
      (add-text-properties
       (match-beginning 4) (match-end 4) taskpaper-markup-properties)
      (backward-char 1)
      t)))

(defvar taskpaper-mouse-map-mark
  (let ((map (make-sparse-keymap)))
    (define-key map [mouse-1] 'taskpaper-item-toggle-done)
    map)
  "Mouse events for task marks.")

(defun taskpaper-activate-task-marks (limit)
  "Activate task marks from point to LIMIT."
  (when (re-search-forward taskpaper-task-regexp limit t)
    (if (save-excursion
          (save-match-data
            (taskpaper-item-has-attribute "done")))
        (when (and (characterp taskpaper-bullet-done)
                   (char-displayable-p taskpaper-bullet-done))
          (put-text-property
           (match-beginning 2) (match-end 2)
           'display (char-to-string taskpaper-bullet-done)))
      (when (and (characterp taskpaper-bullet)
                 (char-displayable-p taskpaper-bullet))
        (put-text-property
         (match-beginning 2) (match-end 2)
         'display (char-to-string taskpaper-bullet))))
    (add-text-properties
     (match-beginning 2) (match-end 2)
     (list 'mouse-face 'highlight
           'keymap taskpaper-mouse-map-mark))
    (taskpaper-rear-nonsticky-at (match-end 2))
    t))

(defvar taskpaper-font-lock-keywords nil)
(defun taskpaper-set-font-lock-defaults ()
  "Set Font Lock defaults for the current buffer.
The order in which other fontification functions are called here,
is essential."
  (let ((font-lock-keywords
         (list
          (cons taskpaper-task-regexp
                '((2 'taskpaper-task-undone-mark)
                  (3 'taskpaper-task)))
          (cons taskpaper-project-regexp
                '((2 'taskpaper-project-name)
                  (3 'taskpaper-project-mark)))
          (cons taskpaper-note-regexp
                '((1 'taskpaper-note)))
          '(taskpaper-font-lock-markdown-links)
          '(taskpaper-font-lock-email-links)
          '(taskpaper-font-lock-file-links)
          '(taskpaper-font-lock-uri-links)
          '(taskpaper-font-lock-tags)
          (when taskpaper-fontify-done-items
            '(taskpaper-font-lock-done-tasks))
          (when taskpaper-fontify-done-items
            '(taskpaper-font-lock-done-projects))
          (when taskpaper-use-inline-emphasis
            '(taskpaper-font-lock-strong))
          (when taskpaper-use-inline-emphasis
            '(taskpaper-font-lock-emphasis))
          (when taskpaper-pretty-task-marks
            '(taskpaper-activate-task-marks)))))
    (setq taskpaper-font-lock-keywords (delq nil font-lock-keywords))
    (taskpaper-set-local
     'font-lock-defaults
     '(taskpaper-font-lock-keywords t nil nil backward-paragraph))
    (kill-local-variable 'font-lock-keywords)
    nil))

(defun taskpaper-unfontify-region (begin end)
  "Remove fontification in region between BEGIN and END."
  (font-lock-default-unfontify-region begin end)
  (let* ((buffer-undo-list t)
         (inhibit-read-only t) (inhibit-point-motion-hooks t)
         (inhibit-modification-hooks t)
         deactivate-mark buffer-file-name buffer-file-truename)
    (remove-text-properties
     begin end
     '(display t mouse-face t keymap t
               help-echo t invisible t taskpaper-syntax t))))

(defun taskpaper-toggle-markup-hiding ()
  "Toggle the display or hiding of inline markup."
  (interactive)
  (setq taskpaper-hide-markup (if taskpaper-hide-markup nil t))
  (if taskpaper-hide-markup
      (progn
        (add-to-invisibility-spec 'taskpaper-markup)
        (when (called-interactively-p 'interactive)
          (message "Markup hiding enabled")))
    (remove-from-invisibility-spec 'taskpaper-markup)
    (when (called-interactively-p 'interactive)
      (message "Markup hiding disabled")))
  (when font-lock-mode (font-lock-flush)))

;;;; Files and URIs

(defconst taskpaper-file-apps-defaults-gnu
  '((remote . emacs)
    (system . mailcap)
    (t      . mailcap))
  "Default file applications on a GNU/Linux system.")

(defconst taskpaper-file-apps-defaults-macos
  '((remote . emacs)
    (system . "open %s")
    (t      . "open %s"))
  "Default file applications on a macOS system.")

(defconst taskpaper-file-apps-defaults-windowsnt
  (list (cons 'remote 'emacs)
        (cons 'system (lambda (file)
                        (with-no-warnings (w32-shell-execute "open" file))))
        (cons t (lambda (file)
                  (with-no-warnings (w32-shell-execute "open" file)))))
  "Default file applications on a Windows NT system.")

(defun taskpaper-default-apps ()
  "Return the default applications for this operating system."
  (cond
   ((eq system-type 'darwin) taskpaper-file-apps-defaults-macos)
   ((eq system-type 'windows-nt) taskpaper-file-apps-defaults-windowsnt)
   (t taskpaper-file-apps-defaults-gnu)))

(defun taskpaper-apps-regexp-alist (list &optional add-auto-mode)
  "Convert file extensions to regular expressions in the cars of LIST.
When ADD-AUTO-MODE is non-nil, make all matches in
`auto-mode-alist' point to the symbol 'emacs, indicating that the
file should be visited in Emacs."
  (append
   (delq nil
         (mapcar (lambda (x)
                   (cond ((not (stringp (car x))) nil)
                         ((string-match "\\W" (car x)) x)
                         (t (cons (concat "\\." (car x) "\\'") (cdr x)))))
                 list))
   (when add-auto-mode
     (mapcar (lambda (x) (cons (car x) 'emacs)) auto-mode-alist))))

(defun taskpaper-open-file-with-cmd (file cmd)
  "Open FILE using CMD.
If CMD is a string, the command will be executed by a shell. A %s
formatter will be replaced by the file path. If CMD is the symbol
'emacs, the file will be visited by the current Emacs process. If
CMD is a Lisp function, the function will be called with the file
path as a single argument."
  (setq file (substitute-in-file-name (expand-file-name file)))
  (when (and (not (eq cmd 'emacs))
             (not (file-exists-p file))
             (not taskpaper-open-non-existing-files))
    (user-error "No such file: %s" file))
  (cond
   ((and (stringp cmd) (not (string-match-p "^\\s-*$" cmd)))
    (while (string-match "\"%s\"\\|'%s'" cmd)
      (setq cmd (replace-match "%s" t t cmd)))
    (while (string-match "%s" cmd)
      (setq cmd (replace-match
                 (save-match-data
                   (shell-quote-argument (convert-standard-filename file)))
                 t t cmd)))
    (save-window-excursion (start-process-shell-command cmd nil cmd))
    (message "Running %s" cmd))
   ((eq cmd 'emacs)
    (find-file-other-window file))
   ((functionp cmd)
    (save-match-data (funcall cmd (convert-standard-filename file))))
   (t (error "Cannot interpret command: %s" cmd))))

(declare-function mailcap-parse-mailcaps "mailcap" (&optional path force))
(declare-function mailcap-extension-to-mime "mailcap" (extn))
(declare-function mailcap-mime-info "mailcap" (string &optional request no-decode))
(defun taskpaper-open-file (path &optional in-emacs)
  "Open the file at PATH.
With optional argument IN-EMACS, visit the file in Emacs."
  (let* ((file (if (equal path "")
                   buffer-file-name
                 (substitute-in-file-name (expand-file-name path))))
         (apps (append taskpaper-file-apps (taskpaper-default-apps)))
         (remp (and (assq 'remote apps) (file-remote-p file)))
         (dirp (file-directory-p file))
         (amap (assq 'auto-mode apps))
         (dfile (downcase file))
         (ext (and (string-match
                    "\\.\\([[:alnum:]]+\\(\\.gz\\|\\.bz2\\)?\\)\\'" dfile)
                   (match-string 1 dfile)))
         cmd)
    ;; Set open command
    (cond
     (in-emacs (setq cmd 'emacs))
     (t (setq cmd (or (and remp (cdr (assoc 'remote apps)))
                      (and dirp (cdr (assoc 'directory apps)))
                      (assoc-default dfile
                                     (taskpaper-apps-regexp-alist apps amap)
                                     'string-match)
                      (cdr (assoc ext apps))
                      (cdr (assoc t apps))))))
    (cond
     ((eq cmd 'system) (setq cmd (cdr (assoc 'system apps))))
     ((eq cmd 'default) (setq cmd (cdr (assoc t apps))))
     ((eq cmd 'mailcap)
      (require 'mailcap)
      (mailcap-parse-mailcaps)
      (let* ((mime-type (mailcap-extension-to-mime (or ext "")))
             (command (mailcap-mime-info mime-type)))
        (if (stringp command) (setq cmd command) (setq cmd 'emacs)))))
    ;; Open the file
    (taskpaper-open-file-with-cmd file cmd)))

(defun taskpaper-default-open-cmd ()
  "Return the default system command to open URIs.
Command can be a string containing a %s formatter, which will be
replaced by the URI, or a Lisp function, which will be called with
the URI as a single argument."
  (cond ((eq system-type 'darwin) "open %s")
        ((eq system-type 'windows-nt)
         (lambda (uri) (with-no-warnings (w32-shell-execute "open" uri))))
        (t "xdg-open %s")))

(defun taskpaper-open-uri (uri)
  "Open the URI using the default system command."
  (let ((cmd (taskpaper-default-open-cmd)))
    (cond
     ((stringp cmd)
      (while (string-match "%s" cmd)
        (setq cmd (replace-match
                   (save-match-data (shell-quote-argument uri)) t t cmd)))
      (save-window-excursion (start-process-shell-command cmd nil cmd))
      (message "Running %s" cmd))
     ((functionp cmd)
      (save-match-data (funcall cmd uri))))))

;;;; Links

(defun taskpaper-file-path-complete (&optional arg)
  "Read file path using completion.
Return absolute or relative path to the file as string. If ARG is
non-nil, force absolute path."
  (let ((file (read-file-name "File: "))
        (pwd  (file-name-as-directory (expand-file-name ".")))
        (pwd1 (file-name-as-directory
               (abbreviate-file-name (expand-file-name ".")))))
    (when (equal file "") (user-error "File name must not be empty"))
    (cond
     (arg (abbreviate-file-name (expand-file-name file)))
     ((string-match (concat "\\`" (regexp-quote pwd1) "\\(.+\\)") file)
      (concat "./" (match-string 1 file)))
     ((string-match (concat "\\`" (regexp-quote pwd) "\\(.+\\)")
                    (expand-file-name file))
      (concat "./" (match-string 1 (expand-file-name file))))
     (t file))))

(defun taskpaper-insert-file-link-at-point (&optional arg)
  "Insert a file link at point using completion.
The path to the file is inserted relative to the directory of the
current TaskPaper file, if the linked file is in the current
directory or in a subdirectory of it, or if the path is written
relative to the current directory using \"../\". Otherwise an
absolute path is used. An absolute path can be forced with a
\\[universal-argument] prefix argument."
  (interactive "P")
  (unless (or (bolp) (eq (char-syntax (char-before)) 32)) (insert " "))
  (insert (taskpaper-file-path-escape (taskpaper-file-path-complete arg)))
  (unless (or (eolp) (eq (char-syntax (char-after)) 32)) (insert " ")))

(defun taskpaper-open-link (link)
  "Open LINK."
  (let ((type (taskpaper-get-link-type link)))
    (cond
     ((eq type 'email)
      (setq link (string-remove-prefix "mailto:" link))
      (compose-mail-other-window link))
     ((eq type 'file)
      (setq link (taskpaper-file-path-unescape link))
      (taskpaper-open-file link))
     ((eq type 'uri)
      (when (string-match-p "\\`www[[:digit:]]\\{0,3\\}[.]" link)
        (setq link (concat "http://" link)))
      (taskpaper-open-uri link))
     (t (find-file-other-window link)))))

(defun taskpaper-open-link-at-point ()
  "Open link at point."
  (interactive)
  (let ((link))
    (cond ((taskpaper-in-regexp taskpaper-markdown-link-regexp)
           (setq link (match-string-no-properties 6)))
          ((taskpaper-in-regexp taskpaper-file-link-regexp)
           (setq link (match-string-no-properties 1)))
          ((taskpaper-in-regexp taskpaper-uri-regexp)
           (setq link (match-string-no-properties 1)))
          ((taskpaper-in-regexp taskpaper-email-regexp)
           (setq link (match-string-no-properties 1)))
          (t (user-error "No link at point")))
    (taskpaper-open-link link)))

(defvar taskpaper-link-search-failed nil)
(make-variable-buffer-local 'taskpaper-link-search-failed)

(defun taskpaper-next-link (&optional back)
  "Move forward to the next link.
If BACK is non-nil, move backward to the previous link."
  (interactive)
  (when (and taskpaper-link-search-failed (eq this-command last-command))
    (goto-char (if back (point-max) (point-min)))
    (message "Wrapping link search"))
  (setq taskpaper-link-search-failed nil)
  (let ((pos (point))
        (func (if back 're-search-backward 're-search-forward))
        (re taskpaper-any-link-regexp))
    (when (taskpaper-in-regexp re)
      ;; Don't stay stuck at link under cursor
      (goto-char (if back (match-beginning 0) (match-end 0))))
    (if (and (funcall func re nil t) (taskpaper-in-regexp re))
        (progn
          (goto-char (match-beginning 0)) (skip-syntax-forward "\s")
          (when (outline-invisible-p) (taskpaper-outline-show-context)))
      (goto-char pos) (setq taskpaper-link-search-failed t)
      (message "No further link found"))))

(defun taskpaper-previous-link ()
  "Move backward to the previous link."
  (interactive)
  (funcall 'taskpaper-next-link t))

;;;; Inline images

(defvar taskpaper-inline-image-overlays nil
  "List of inline image overlays.")
(make-variable-buffer-local 'taskpaper-inline-image-overlays)

(defun taskpaper-remove-inline-images ()
  "Remove inline images in the buffer."
  (interactive)
  (mapc #'delete-overlay taskpaper-inline-image-overlays)
  (setq taskpaper-inline-image-overlays nil))

(defun taskpaper-display-inline-images ()
  "Display inline images in the buffer.
Add inline image overlays to local image links in the buffer. An
image link is a plain link to file matching return value from
`image-file-name-regexp'."
  (interactive)
  (unless (display-images-p) (error "Images cannot be displayed"))
  (taskpaper-remove-inline-images)
  (when (fboundp 'clear-image-cache) (clear-image-cache))
  (save-excursion
    (save-restriction
      (widen) (goto-char (point-min))
      (while (re-search-forward taskpaper-file-link-regexp nil t)
        (let* ((begin (match-beginning 1)) (end (match-end 1))
               (path (match-string-no-properties 1))
               (path (expand-file-name (taskpaper-file-path-unescape path)))
               (type (if (image-type-available-p 'imagemagick) 'imagemagick nil))
               image)
          ;; Check file path
          (when (and (file-exists-p path)
                     (not (file-remote-p path))
                     (taskpaper-file-image-p path)
                     (not (taskpaper-in-regexp
                           taskpaper-markdown-link-regexp begin)))
            ;; Create image
            (setq image
                  (if taskpaper-max-image-size
                      (create-image path type nil
                                    :max-width  (car taskpaper-max-image-size)
                                    :max-height (cdr taskpaper-max-image-size))
                    (create-image path)))
            ;; Display image
            (when image
              (let ((overlay (make-overlay begin end)))
                (overlay-put overlay 'display image)
                (overlay-put overlay 'face 'default)
                (push overlay taskpaper-inline-image-overlays)))))))))

(defun taskpaper-toggle-inline-images ()
  "Toggle displaying of inline images in the buffer."
  (interactive)
  (if taskpaper-inline-image-overlays
      (progn
        (taskpaper-remove-inline-images)
        (when (called-interactively-p 'interactive)
          (message "Displaying of inline images disabled")))
    (taskpaper-display-inline-images)
    (when (called-interactively-p 'interactive)
      (message "Displaying of inline images enabled"))))

;;;; Outline API and navigation

(defalias 'taskpaper-outline-end-of-item 'outline-end-of-heading
  "Move to the end of the current item.")

(defalias 'taskpaper-outline-end-of-subtree 'outline-end-of-subtree
  "Move to the end of the current subtree.")

(defalias 'taskpaper-outline-up-level 'outline-up-heading
  "Move to the visible parent item.
With argument, move up ARG levels. If INVISIBLE-OK is non-nil,
also consider invisible items.")

(defalias 'taskpaper-outline-next-item 'outline-next-heading
  "Move to the next (possibly invisible) item.")

(defalias 'taskpaper-outline-previous-item 'outline-previous-heading
  "Move to the previous (possibly invisible) item.")

(defun taskpaper-outline-forward-same-level (arg)
  "Move forward to the ARG'th item at same level.
Call `outline-forward-same-level', but provide a better error
message."
  (interactive "p")
  (condition-case nil
      (outline-forward-same-level arg)
    (error (user-error "No following same-level item"))))

(defun taskpaper-outline-backward-same-level (arg)
  "Move backward to the ARG'th item at same level.
Call `outline-backward-same-level', but provide a better error
message."
  (interactive "p")
  (condition-case nil
      (outline-backward-same-level arg)
    (error (user-error "No previous same-level item"))))

(defsubst taskpaper-outline-up-level-safe ()
  "Move to the (possibly invisible) ancestor item.
This version will not throw an error. Also, this version is much
faster than `outline-up-heading', relying directly on leading
tabs."
  (when (ignore-errors (outline-back-to-heading t))
    (let ((level-up (1- (funcall outline-level))))
      (and (> level-up 0)
           (re-search-backward
            (format "^[\t]\\{0,%d\\}[^\t\f\n]" (1- level-up)) nil t)))))

(defun taskpaper-outline-forward-same-level-safe ()
  "Move to the next (possibly invisible) sibling.
This version will not throw an error."
  (condition-case nil
      (progn (outline-forward-same-level 1) t)
    (error nil)))

(defun taskpaper-outline-backward-same-level-safe ()
  "Move to the preceeding (possibly invisible) sibling.
This version will not throw an error."
  (condition-case nil
      (progn (outline-backward-same-level 1) t)
    (error nil)))

(defun taskpaper-outline-next-item-safe ()
  "Move to the next (possibly invisible) item.
This version will not throw an error."
  (condition-case nil
      (progn (outline-next-heading) t)
    (error nil)))

(defun taskpaper-outline-previous-item-safe ()
  "Move to the previous (possibly invisible) item.
This version will not throw an error."
  (condition-case nil
      (progn (outline-previous-heading) t)
    (error nil)))

(defun taskpaper-outline-map-descendants (func &optional self)
  "Call FUNC for every descendant of the current item.
When SELF is non-nil, also map the current item."
  (outline-back-to-heading t)
  (let ((level (save-match-data (funcall outline-level))))
    (save-excursion
      (when self (funcall func))
      (while (and (progn
                    (taskpaper-outline-next-item-safe)
                    (> (save-match-data (funcall outline-level)) level))
                  (not (eobp)))
        (funcall func)))))

(defun taskpaper-outline-map-tree (func)
  "Call FUNC for every item of the current subtree."
  (taskpaper-outline-map-descendants func t))

(defun taskpaper-outline-map-region (func begin end)
  "Call FUNC for every item between BEGIN and END."
  (save-excursion
    (setq end (copy-marker end)) (goto-char begin)
    (when (outline-on-heading-p t) (funcall func))
    (while (and (progn
                  (taskpaper-outline-next-item-safe)
                  (< (point) end))
                (not (eobp)))
      (funcall func))))

(defun taskpaper-item-has-children-p ()
  "Return non-nil if current item has children."
  (let (eoi eos)
    (save-excursion
      (outline-back-to-heading t)
      (taskpaper-outline-end-of-item) (setq eoi (point))
      (taskpaper-outline-end-of-subtree) (setq eos (point)))
    (not (= eos eoi))))

(defun taskpaper-outline-normalize-indentation ()
  "Normalize outline indentation.
The variable `tab-width' controls the amount of spaces per
indentation level."
  (interactive)
  (save-restriction
    (widen) (goto-char (point-min))
    (while (re-search-forward "^[ \t]+" nil t)
      (let ((indent (floor (string-width (match-string 0)) tab-width)))
        (replace-match (make-string indent ?\t))))))

;;;; Folding

(eval-and-compile
  (defalias 'taskpaper-outline-show-all
    (if (fboundp 'outline-show-all) 'outline-show-all 'show-all)
    "Show all items in the buffer.")
  (defalias 'taskpaper-outline-show-item
    (if (fboundp 'outline-show-entry) 'outline-show-entry 'show-entry)
    "Show the current item.")
  (defalias 'taskpaper-outline-show-children
    (if (fboundp 'outline-show-children) 'outline-show-children 'show-children)
    "Show all direct subitems of the current item.")
  (defalias 'taskpaper-outline-show-subtree
    (if (fboundp 'outline-show-subtree) 'outline-show-subtree 'show-subtree)
    "Show all subitems of the current item.")
  (defalias 'taskpaper-outline-hide-subtree
    (if (fboundp 'outline-hide-subtree) 'outline-hide-subtree 'hide-subtree)
    "Hide all subitems of the current item.")
  (defalias 'taskpaper-outline-hide-sublevels
    (if (fboundp 'outline-hide-sublevels) 'outline-hide-sublevels 'hide-sublevels))
  "Hide everything but the top-level items in the buffer.")

(defun taskpaper-outline-show-context ()
  "Show the current item and all its ancestors."
  (let (outline-view-change-hook)
    (save-excursion
      (outline-back-to-heading t) (taskpaper-outline-show-item)
      (while (taskpaper-outline-up-level-safe)
        (outline-flag-region
         (max (point-min) (1- (point)))
         (save-excursion (taskpaper-outline-end-of-item) (point))
         nil)))))

(defun taskpaper-outline-hide-other ()
  "Hide everything except the current item and its context.
Shows only current item, its ancestors and top-level items.
Essentially a slightly modified version of `outline-hide-other'."
  (interactive)
  (taskpaper-outline-hide-sublevels 1)
  (save-excursion (taskpaper-outline-show-context))
  (save-excursion (taskpaper-outline-show-children))
  (recenter-top-bottom))

(defun taskpaper-outline-overview ()
  "Show only top-level items."
  (interactive)
  (goto-char (point-min))
  (taskpaper-outline-hide-sublevels 1))

(defun taskpaper-next-line ()
  "Forward line, but move over invisible line ends.
Essentially a much simplified version of `next-line'."
  (interactive)
  (beginning-of-line 2)
  (while (and (not (eobp))
              (get-char-property (1- (point)) 'invisible))
    (beginning-of-line 2)))

(defvar taskpaper-cycle-global-status 1)
(make-variable-buffer-local 'taskpaper-cycle-global-status)

(defun taskpaper-cycle (&optional arg)
  "Perform visibility cycling.
When point is at the beginning of the buffer, or when called with
a \\[universal-argument] prefix argument, rotate the entire
buffer. When point is on an item, rotate the current subtree."
  (interactive "P")
  (cond
   (arg
    (progn (goto-char (point-min)) (taskpaper-cycle)))
   (t
    (cond
     ((bobp)
      ;; Perform global cycling
      (cond ((and (eq last-command this-command)
                  (eq taskpaper-cycle-global-status 2))
             ;; Show everything
             (taskpaper-outline-show-all)
             (taskpaper-unlogged-message "SHOW ALL")
             (setq taskpaper-cycle-global-status 1))
            (t
             ;; Show overview (default)
             (taskpaper-outline-hide-sublevels 1)
             (taskpaper-unlogged-message "OVERVIEW")
             (setq taskpaper-cycle-global-status 2))))
     ((save-excursion
        (beginning-of-line 1) (looking-at outline-regexp))
      ;; Cycle current subtree
      (outline-back-to-heading)
      (let ((goal-column 0) eoi eol eos)
        ;; Determine boundaries
        (save-excursion
          (outline-back-to-heading)
          (save-excursion
            (taskpaper-next-line) (setq eol (point)))
          (taskpaper-outline-end-of-item) (setq eoi (point))
          (taskpaper-outline-end-of-subtree) (setq eos (point)))
        (cond ((= eoi eos)
               ;; Leaf item
               (taskpaper-unlogged-message "LEAF ITEM"))
              ((>= eol eos)
               ;; Show direct children
               (taskpaper-outline-show-children)
               (taskpaper-unlogged-message "CHILDREN")
               (setq this-command 'taskpaper-cycle-children))
              ((eq last-command 'taskpaper-cycle-children)
               ;; Show the entire subtree
               (taskpaper-outline-show-subtree)
               (taskpaper-unlogged-message "SUBTREE"))
              (t
               ;; Hide the subtree (default)
               (taskpaper-outline-hide-subtree)
               (taskpaper-unlogged-message "FOLDED")))))
     (t
      ;; Not at an item
      (outline-back-to-heading))))))

(defun taskpaper-set-startup-visibility ()
  "Set startup visibility."
  (if taskpaper-startup-folded
      (taskpaper-outline-overview)
    (taskpaper-outline-show-all)))

;;;; Miscellaneous outline functions

(defun taskpaper-narrow-to-subtree ()
  "Narrow buffer to the current subtree."
  (interactive)
  (let (begin end)
    (save-excursion
      (save-match-data
        (outline-back-to-heading) (setq begin (point))
        (taskpaper-outline-end-of-subtree) (setq end (point))
        (narrow-to-region begin end)))))

(defalias 'taskpaper-mark-subtree 'outline-mark-subtree
  "Mark the current subtree.
Put point at the start of the current subtree, and mark at the
end.")

(defun taskpaper-outline-copy-visible (begin end)
  "Save all visible items between BEGIN and END to the kill ring."
  (interactive "r")
  (save-excursion
    (save-restriction
      (narrow-to-region begin end) (goto-char (point-min))
      (let ((buffer (current-buffer)) start end)
        (with-temp-buffer
          (let ((tmp-buffer (current-buffer)))
            (with-current-buffer buffer
              ;; Starting on an item
              (when (outline-on-heading-p)
                (outline-back-to-heading)
                (setq start (point)
                      end (progn
                            (taskpaper-outline-end-of-item) (point)))
                (with-current-buffer tmp-buffer
                  (insert-buffer-substring buffer start end)
                  (insert "\n")))
              (while (outline-next-heading)
                (unless (outline-invisible-p)
                  (setq start (point)
                        end (progn
                              (taskpaper-outline-end-of-item) (point)))
                  (with-current-buffer tmp-buffer
                    (insert-buffer-substring buffer start end)
                    (insert "\n"))))))
          (kill-new (buffer-string)))))))

;;;; Promotion and demotion

(defun taskpaper-fix-position-after-promote ()
  "Fix cursor position after promoting or demoting."
  (back-to-indentation))

(defun taskpaper-outline-promote ()
  "Promote the current (possibly invisible) item."
  (interactive)
  (outline-back-to-heading t)
  (let ((level (save-match-data (funcall outline-level))))
    (if (= level 1)
        (user-error "Already at top level"))
    (let ((indent (make-string (- level 2) ?\t)))
      (replace-match indent nil t nil 1))))

(defun taskpaper-outline-demote ()
  "Demote the current (possibly invisible) item."
  (interactive)
  (outline-back-to-heading t)
  (let* ((level (save-match-data (funcall outline-level)))
         (indent (make-string level ?\t)))
    (replace-match indent nil t nil 1)))

(defun taskpaper-outline-promote-subtree ()
  "Promote the current (possibly invisible) subtree."
  (interactive)
  (taskpaper-outline-map-tree 'taskpaper-outline-promote)
  (taskpaper-fix-position-after-promote))

(defun taskpaper-outline-demote-subtree ()
  "Demote the current (possibly invisible) subtree."
  (interactive)
  (taskpaper-outline-map-tree 'taskpaper-outline-demote)
  (taskpaper-fix-position-after-promote))

;;;; Vertical tree movement

(defalias 'taskpaper-outline-move-subtree-up 'outline-move-subtree-up
  "Move the current subtree up past ARG items of the same level.")

(defalias 'taskpaper-outline-move-subtree-down 'outline-move-subtree-down
  "Move the current subtree down past ARG items of the same level.")

;;; Mark ring navigation interface

(defvar taskpaper-mark-ring nil
  "Mark ring for positions before jumps.")
(defvar taskpaper-mark-ring-last-goto nil
  "Last position in the mark ring used to go back.")

;; In case file is reloaded
(setq taskpaper-mark-ring nil taskpaper-mark-ring-last-goto nil)

;; Fill and close the mark ring
(dotimes (_ taskpaper-mark-ring-length)
  (push (make-marker) taskpaper-mark-ring))
(setcdr (nthcdr (1- taskpaper-mark-ring-length) taskpaper-mark-ring)
        taskpaper-mark-ring)

(defun taskpaper-mark-ring-push (&optional pos)
  "Push the current position or POS onto the mark ring."
  (interactive)
  (setq taskpaper-mark-ring
        (nthcdr (1- taskpaper-mark-ring-length) taskpaper-mark-ring))
  (move-marker (car taskpaper-mark-ring) (or pos (point)) (current-buffer))
  (when (called-interactively-p 'any)
    (message "Position saved to mark ring.")))

(defun taskpaper-mark-ring-goto (&optional n)
  "Jump to the previous position in the mark ring.
With prefix argument N, jump back that many stored positions. When
called several times in succession, walk through the entire ring.
TaskPaper mode commands jumping to a different position in the
current file automatically push the old position onto the ring."
  (interactive "p")
  (let (p m)
    (if (eq last-command this-command)
        (setq p (nthcdr n (or taskpaper-mark-ring-last-goto
                              taskpaper-mark-ring)))
      (setq p taskpaper-mark-ring))
    (setq taskpaper-mark-ring-last-goto p) (setq m (car p))
    (unless (marker-position m) (user-error "No saved position"))
    (pop-to-buffer-same-window (marker-buffer m)) (goto-char m)
    (when (outline-invisible-p) (taskpaper-outline-show-context))))

;;;; Item auto-formatting

(defun taskpaper-new-item-same-level ()
  "Insert new item at same level."
  (interactive)
  (cond
   ((bolp) (newline))
   ((outline-on-heading-p)
    (let ((level (save-excursion (save-match-data (funcall outline-level)))))
      (newline) (insert (make-string (1- level) ?\t))))
   (t (beginning-of-line) (delete-horizontal-space))))

(defun taskpaper-new-task-same-level ()
  "Insert new task at same level."
  (interactive)
  (taskpaper-new-item-same-level) (insert "- "))

;;;; Item parsing and type formatting

(defun taskpaper-remove-indentation (item)
  "Remove indentation from ITEM."
  (save-match-data
    (when (string-match "^[ \t]+" item)
      (setq item (replace-match "" t nil item)))
    item))

(defun taskpaper-remove-trailing-tags (item)
  "Remove trailing tags from ITEM."
  (save-match-data
    (when (string-match (format "%s$" taskpaper-consec-tags-regexp) item)
      (setq item (replace-match "" t nil item))))
  item)

(defun taskpaper-remove-inline-markup (item)
  "Remove inline markup from ITEM."
  (with-temp-buffer
    (erase-buffer) (insert item)
    (delay-mode-hooks (taskpaper-mode))
    (font-lock-default-function 'taskpaper-mode)
    (font-lock-default-fontify-region (point-min) (point-max) nil)
    (setq item (taskpaper-remove-markup-chars (buffer-string))))
  (set-text-properties 0 (length item) nil item)
  item)

(defun taskpaper-item-type ()
  "Return type of item at point."
  (let ((item (buffer-substring-no-properties
               (line-beginning-position) (line-end-position))))
    (setq item (taskpaper-remove-indentation item))
    (setq item (taskpaper-remove-trailing-tags item))
    (cond ((string-match-p "^\\s-*$" item) nil)
          ((string-match-p "^[-+*] " item) "task")
          ((string-match-p ":$" item) "project")
          (t "note"))))

(defun taskpaper-item-text ()
  "Return text of item at point."
  (let ((item (buffer-substring-no-properties
               (line-beginning-position) (line-end-position))))
    (taskpaper-remove-indentation item)))

(defun taskpaper-remove-type-formatting (item)
  "Remove type formatting from ITEM."
  (let ((re-ind "^\\([ \t]+\\)")
        (re-tag (format "\\(%s\\)\\s-*$" taskpaper-consec-tags-regexp))
        (indent "") (tags ""))
    (save-match-data
      ;; Strip indent and trailing tags and save them
      (when (string-match re-ind item)
        (setq indent (match-string-no-properties 1 item)
              item (replace-match "" t nil item)))
      (when (string-match re-tag item)
        (setq tags (match-string-no-properties 1 item)
              item (replace-match "" t nil item)))
      ;; Remove type formatting
      (cond ((string-match "^[-+*] " item)
             (setq item (replace-match "" t nil item)))
            ((string-match ":$" item)
             (setq item (replace-match "" t nil item)))
            (t item)))
    ;; Sanitize
    (setq item (taskpaper-trim-string item)
          tags (taskpaper-trim-string tags))
    ;; Add separator space, if nessessary
    (when (and (not (equal item "")) (not (equal tags "")))
      (setq tags (concat " " tags)))
    ;; Add indent and trailing tags
    (concat indent item tags)))

(defun taskpaper-item-format (type)
  "Format item at point as TYPE.
Item type can be 'project, 'task, or 'note."
  (let* ((begin (line-beginning-position))
         (end (line-end-position))
         (item (buffer-substring-no-properties begin end))
         (re-ind "^\\([ \t]+\\)")
         (re-tag (format "\\(%s\\)\\s-*$" taskpaper-consec-tags-regexp))
         (indent "") (tags ""))
    ;; Remove existing type formatting
    (setq item (taskpaper-remove-type-formatting item))
    (save-match-data
      ;; Strip indent and trailing tags and save them
      (when (string-match re-ind item)
        (setq indent (match-string-no-properties 1 item)
              item (replace-match "" t nil item)))
      (when (string-match re-tag item)
        (setq tags (match-string-no-properties 1 item)
              item (replace-match "" t nil item))))
    ;; Sanitize
    (setq item (taskpaper-trim-string item)
          tags (taskpaper-trim-string tags))
    ;; Add type formatting as required
    (cond ((eq type 'task) (setq item (concat "- " item)))
          ((eq type 'project) (setq item (concat item ":")))
          ((eq type 'note) item)
          (t (error "Invalid item type: %s" type)))
    ;; Add separator space, if nessessary
    (when (and (not (equal item "")) (not (equal tags "")))
      (setq tags (concat " " tags)))
    ;; Add indent and trailing tags and replace the item
    (delete-region begin end) (insert indent item tags)))

(defun taskpaper-item-format-as-project ()
  "Format item at point as project."
  (interactive)
  (taskpaper-item-format 'project))

(defun taskpaper-item-format-as-task ()
  "Format item at point as task."
  (interactive)
  (taskpaper-item-format 'task))

(defun taskpaper-item-format-as-note ()
  "Format item at point as note."
  (interactive)
  (taskpaper-item-format 'note))

;;;: Tag and attribute utilities

(defun taskpaper-in-tag-p (&optional pos)
  "Return non-nil if POS is in a tag.
If POS is omitted or nil, the value of point is used by default.
This function does not set or modify the match data."
  (let ((pos (or pos (point))))
    (save-excursion
      (save-match-data
        (and (taskpaper-in-regexp taskpaper-tag-regexp pos)
             (not (taskpaper-in-regexp
                   taskpaper-markdown-link-regexp pos))
             (not (taskpaper-in-regexp
                   taskpaper-file-link-regexp pos)))))))

(defun taskpaper-tag-name-p (name)
  "Return non-nil when NAME is a valid tag name."
  (let ((re (format "\\`%s\\'" taskpaper-tag-name-regexp)))
    (when (stringp name) (string-match-p re name))))

(defun taskpaper-tag-value-escape (value)
  "Escape special characters in tag VALUE."
  (when (stringp value)
    (setq value (replace-regexp-in-string "\n+" " " value)
          value (replace-regexp-in-string "(" "\\\\(" value)
          value (replace-regexp-in-string ")" "\\\\)" value)))
  value)

(defun taskpaper-tag-value-unescape (value)
  "Unescape special characters in tag VALUE."
  (when (stringp value)
    (setq value (replace-regexp-in-string "\\\\(" "(" value)
          value (replace-regexp-in-string "\\\\)" ")" value)))
  value)

(defconst taskpaper-special-attributes '("type" "text")
  "The special item attributes.
These are implicit attributes not associated with tags.")

(defun taskpaper-item-get-special-attributes ()
  "Get special attrbutes for the item at point.
Return a list of cons cells (NAME . VALUE), where NAME is the
attribute name and VALUE is the attribute value, as strings."
  (let (attrs name value)
    (setq name "type" value (taskpaper-item-type))
    (push (cons name value) attrs)
    (setq name "text" value (taskpaper-item-text))
    (push (cons name value) attrs)
    attrs))

(defun taskpaper-item-get-explicit-attributes ()
  "Get explicit attrbutes for the item at point.
Return a list of cons cells (NAME . VALUE), where NAME is the
attribute name and VALUE is the attribute value, as strings."
  (let (attrs name value)
    (save-excursion
      (beginning-of-line 1)
      (save-match-data
        (while (re-search-forward
                taskpaper-tag-regexp (line-end-position) t)
          (when (taskpaper-in-tag-p (match-beginning 1))
            (setq name  (match-string-no-properties 2)
                  value (match-string-no-properties 3)
                  value (taskpaper-tag-value-unescape value))
            (unless (member name taskpaper-special-attributes)
              (push (cons name value) attrs))))))
    (nreverse attrs)))

(defun taskpaper-remove-uninherited-attributes (attrs)
  "Remove attributes excluded from inheritance from ATTRS."
  (when taskpaper-tags-exclude-from-inheritance
    (let (excluded)
      (dolist (attr attrs)
        (when (not (member (car attr) taskpaper-tags-exclude-from-inheritance))
          (push attr excluded)))
      (setq attrs (nreverse excluded))))
  attrs)

;;;; Attribute caching

;; IMPORTANT: Due to the attribute inheritance mechanism
;; attribute cache should be build and clear atomically

(defvar taskpaper-attribute-cache (make-hash-table :size 10000)
  "Attribute cache.")
(make-variable-buffer-local 'taskpaper-attribute-cache)

(defun taskpaper-attribute-cache-clear ()
  "Clear attribute cache."
  (clrhash taskpaper-attribute-cache))

(defun taskpaper-attribute-cache-put (key attrs)
  "Push attribute list ATTRS into attribute cache, under KEY."
  (puthash key attrs taskpaper-attribute-cache))

(defun taskpaper-attribute-cache-get (key)
  "Retrieve attribute list for KEY from attribute cache."
  (gethash key taskpaper-attribute-cache))

(defun taskpaper-attribute-cache-build ()
  "Build attribute cache."
  (taskpaper-attribute-cache-clear)
  (message "Caching...")
  (save-excursion
    (goto-char (point-min))
    (let ((re (concat "^" outline-regexp)))
      (while (let (case-fold-search)
               (re-search-forward re nil t))
        (let ((key (point-at-bol))
              (attrs (taskpaper-item-get-attributes t)))
          (taskpaper-attribute-cache-put key attrs)))))
  (message "Caching...done"))

;;;; Attribute API

(defun taskpaper-item-get-attributes (&optional inherit)
  "Get attrbutes for item at point.
Return read-only list of cons cells (NAME . VALUE), where NAME is
the attribute name and VALUE is the attribute value, as strings.
If INHERIT is non-nil also check higher levels of the hierarchy."
  (let* ((key (point-at-bol))
         (attrs (taskpaper-attribute-cache-get key)))
    (unless attrs
      (setq attrs (append (taskpaper-item-get-special-attributes)
                          (taskpaper-item-get-explicit-attributes)))
      (when (and inherit (outline-on-heading-p t))
        (save-excursion
          (while (taskpaper-outline-up-level-safe)
            (setq attrs
                  (append attrs
                          (taskpaper-remove-uninherited-attributes
                           (taskpaper-item-get-explicit-attributes))))))))
    (taskpaper-uniquify attrs)))

(defun taskpaper-item-get-attribute (name &optional inherit)
  "Get value of attribute NAME for item at point.
Return the value as a string or nil if the attribute does not
exist or has no value. If INHERIT is non-nil also check higher
levels of the hierarchy."
  (unless (taskpaper-tag-name-p name)
    (user-error "Invalid attribute name: %s" name))
  (cdr (assoc name (taskpaper-item-get-attributes inherit))))

(defun taskpaper-item-has-attribute (name &optional inherit)
  "Return non-nil if item at point has attribute NAME.
If INHERIT is non-nil also check higher levels of the
hierarchy."
  (unless (taskpaper-tag-name-p name)
    (user-error "Invalid attribute name: %s" name))
  (assoc name (taskpaper-item-get-attributes inherit)))

(defun taskpaper-item-remove-attribute (name)
  "Remove non-special attribute NAME from item at point."
  (unless (taskpaper-tag-name-p name)
    (user-error "Invalid attribute name: %s" name))
  (when (member name taskpaper-special-attributes)
    (user-error "Special attribute cannot be removed: %s" name))
  (beginning-of-line 1)
  (save-match-data
    (while (re-search-forward
            taskpaper-tag-regexp (line-end-position) t)
      (when (and (taskpaper-in-tag-p (match-beginning 1))
                 (equal (match-string 2) name))
        (delete-region (match-beginning 0) (match-end 0))))))

(defun taskpaper-item-set-attribute (name &optional value)
  "Set non-special attribute NAME for item at point.
With optional argument VALUE, set attribute to that value."
  (unless (taskpaper-tag-name-p name)
    (user-error "Invalid attribute name: %s" name))
  (when (member name taskpaper-special-attributes)
    (user-error "Special attribute cannot be set: %s" name))
  (taskpaper-item-remove-attribute name)
  (when value (setq value (taskpaper-tag-value-escape value)))
  (taskpaper-outline-end-of-item)
  (delete-horizontal-space) (unless (bolp) (insert " "))
  (if value
      (insert (format "@%s(%s)" name value))
    (insert (format "@%s" name))))

(defun taskpaper-string-get-attributes (str)
  "Get attrbutes for item string STR.
Like `taskpaper-item-get-attributes' but uses argument string
instead of item at point."
  (with-temp-buffer
    (erase-buffer) (insert str) (goto-char (point-min))
    (taskpaper-item-get-attributes)))

(defun taskpaper-string-get-attribute (str name)
  "Get value of attribute NAME for item string STR.
Like `taskpaper-item-get-attribute' but uses argument string
instead of item at point."
  (with-temp-buffer
    (erase-buffer) (insert str) (goto-char (point-min))
    (taskpaper-item-get-attribute name)))

(defun taskpaper-string-has-attribute (str name)
  "Return non-nil if item string STR has attribute NAME.
Like `taskpaper-item-has-attribute' but uses argument string
instead of item at point."
  (with-temp-buffer
    (erase-buffer) (insert str) (goto-char (point-min))
    (taskpaper-item-has-attribute name)))

(defun taskpaper-string-remove-attribute (str name)
  "Remove non-special attribute NAME from item string STR.
Like `taskpaper-item-remove-attribute' but uses argument string
instead of item at point. Return new string."
  (with-temp-buffer
    (erase-buffer) (insert str) (goto-char (point-min))
    (taskpaper-item-remove-attribute name)
    (buffer-string)))

(defun taskpaper-string-set-attribute (str name &optional value)
  "Set non-special attribute NAME for item string STR.
With optional argument VALUE, set attribute to that value. Like
`taskpaper-item-set-attribute' but uses argument string instead
of item at point. Return new string."
  (with-temp-buffer
    (erase-buffer) (insert str) (goto-char (point-min))
    (taskpaper-item-set-attribute name value)
    (buffer-string)))

(defun taskpaper-attribute-value-to-list (value)
  "Convert attribute value VALUE to a list.
Treat the value string as a comma-separated list of values and
return the values as a list of strings."
  (when (stringp value)
    (save-match-data (split-string value ",\\s-*" nil))))

;;;; Date and time

(defvar taskpaper-time-was-given nil)
(make-variable-buffer-local 'taskpaper-time-was-given)

(defconst taskpaper-time-whitespace-regexp
  "\\`[ \t\n\r]*"
  "Regular expression matching whitespace characters.")

(defconst taskpaper-time-non-whitespace-regexp
  "\\`[^ \t\n\r]*"
  "Regular expression matching non-whitespace characters.")

(defconst taskpaper-time-relative-word-regexp
  "\\`\\(today\\|tomorrow\\|yesterday\\|now\\)\\>"
  "Regular expression matching relative date and time.")

(defconst taskpaper-time-relative-period-regexp
  (concat
   "\\`\\(this\\|next\\|last\\) +"
   "\\(year\\|quarter\\|month\\|week\\|day\\)\\>")
  "Regular expression matching relative time period.")

(defconst taskpaper-time-relative-month-regexp
  (concat
   "\\`\\(this\\|next\\|last\\) +"
   "\\(" (mapconcat 'car parse-time-months "\\|") "\\)"
   "\\(?: +\\([0-9]?[0-9]\\)\\)?\\(?: \\|\\'\\)")
  "Regular expression matching relative month name.")

(defconst taskpaper-time-relative-weekday-regexp
  (concat
   "\\`\\(this\\|next\\|last\\) +"
   "\\(" (mapconcat 'car parse-time-weekdays "\\|") "\\)\\>")
  "Regular expression matching relative weekday.")

(defconst taskpaper-time-month-regexp
  (concat
   "\\`\\(" (mapconcat 'car parse-time-months "\\|") "\\)"
   "\\(?: +\\([0-9]?[0-9]\\)\\)?\\(?: \\|\\'\\)")
  "Regular expression matching month name.")

(defconst taskpaper-time-weekday-regexp
  (concat
   "\\`\\(" (mapconcat 'car parse-time-weekdays "\\|") "\\)\\>")
  "Regular expression matching weekday.")

(defconst taskpaper-time-iso-date-regexp
  (concat
   "\\`\\([0-9]?[0-9]?[0-9][0-9]\\)"
   "\\(?:-\\([0-9]?[0-9]\\)\\(?:-\\([0-9]?[0-9]\\)\\)?\\)?"
   "\\( \\|\\'\\)")
  "Regular expression matching ISO 8601 date.")

(defconst taskpaper-time-iso-week-date-regexp
  (concat
   "\\`\\([0-9]?[0-9]?[0-9][0-9]\\)-w\\([0-9]?[0-9]\\)"
   "\\(?:-\\([0-9]\\)\\)?\\( \\|\\'\\)")
  "Regular expression matching ISO 8601 week date.")

(defconst taskpaper-time-iso-date-short-regexp
  "\\`--\\([0-9]?[0-9]\\)-\\([0-9]?[0-9]\\)\\( \\|\\'\\)"
  "Regular expression matching ISO 8601 date without year.")

(defconst taskpaper-time-ampm-time-regexp
  "\\`\\([0-9]?[0-9]\\)\\(?::\\([0-9][0-9]\\)\\)?\\([ap]m?\\)\\>"
  "Regular expression matching time in 12-hour clock notation.")

(defconst taskpaper-time-time-regexp
  "\\`\\([0-9]?[0-9]\\):\\([0-9][0-9]\\)\\(?: \\|\\'\\)"
  "Regular expression matching time in 24-hour clock notation.")

(defconst taskpaper-time-duration-offset-regexp
  (concat
   "\\`\\([-+]\\) *\\([0-9]+\\) *"
   "\\([hdwmqy]\\|mins?\\|minutes?\\|hours?\\|"
   "days?\\|weeks?\\|months?\\|quarters?\\|years?\\|"
   (mapconcat 'car parse-time-weekdays "\\|") "\\)\\>")
  "Regular expression matching duration offset.")

(defun taskpaper-time-expand-year (year)
  "Expand 2-digit YEAR.
Expand year into one of the next 30 years, if possible, or into a
past one. Return unchanged any year larger than 99."
  (if (>= year 100) year
    (let* ((current (nth 5 (decode-time (current-time))))
           (century (/ current 100))
           (offset (- year (% current 100))))
      (cond ((> offset  30) (+ (* (1- century) 100) year))
            ((> offset -70) (+ (* century 100) year))
            (t (+ (* (1+ century) 100) year))))))

(defun taskpaper-time-relative-spec-to-inc (spec)
  "Convert relative date specifier to increment."
  (cond ((equal spec "this")  0)
        ((equal spec "next")  1)
        ((equal spec "last") -1)
        (t (error "Invalid relative date specifier: %s" spec))))

(defun taskpaper-time-parse-iso-date (nowdecode time-str)
  "Parse ISO 8601 date representation."
  (let ((year   (nth 5 nowdecode))
        (month  (nth 4 nowdecode))
        (day    (nth 3 nowdecode))
        (hour   (nth 2 nowdecode))
        (minute (nth 1 nowdecode))
        (second (nth 0 nowdecode)))
    (when (string-match taskpaper-time-iso-date-regexp time-str)
      (setq year (taskpaper-time-expand-year
                  (string-to-number (match-string 1 time-str)))
            month (if (match-end 2) (string-to-number (match-string 2 time-str)) 1)
            day (if (match-end 3) (string-to-number (match-string 3 time-str)) 1)
            hour 0 minute 0 second 0
            time-str (replace-match "" t t time-str)))
    ;; Return decoded time and remaining time string
    (cons (list second minute hour day month year) time-str)))

(defun taskpaper-time-parse-iso-week-date (nowdecode time-str)
  "Parse ISO 8601 week date representation."
  (let ((year   (nth 5 nowdecode))
        (month  (nth 4 nowdecode))
        (day    (nth 3 nowdecode))
        (hour   (nth 2 nowdecode))
        (minute (nth 1 nowdecode))
        (second (nth 0 nowdecode))
        iso-year iso-week iso-wday iso-date)
    (when (string-match taskpaper-time-iso-week-date-regexp time-str)
      (setq iso-year (taskpaper-time-expand-year
                      (string-to-number (match-string 1 time-str)))
            iso-week (string-to-number (match-string 2 time-str))
            iso-wday (if (match-end 3) (string-to-number (match-string 3 time-str)) 1)
            iso-wday (if (= iso-wday 7) 0 iso-wday)
            iso-date (calendar-gregorian-from-absolute
                      (calendar-iso-to-absolute (list iso-week iso-wday iso-year)))
            month (nth 0 iso-date) day (nth 1 iso-date) year (nth 2 iso-date)
            hour 0 minute 0 second 0
            time-str (replace-match "" t t time-str)))
    ;; Return decoded time and remaining time string
    (cons (list second minute hour day month year) time-str)))

(defun taskpaper-time-parse-iso-date-short (nowdecode time-str)
  "Parse ISO 8601 date representation with year omitted."
  (let ((year   (nth 5 nowdecode))
        (month  (nth 4 nowdecode))
        (day    (nth 3 nowdecode))
        (hour   (nth 2 nowdecode))
        (minute (nth 1 nowdecode))
        (second (nth 0 nowdecode)))
    (when (string-match taskpaper-time-iso-date-short-regexp time-str)
      (setq month (string-to-number (match-string 1 time-str))
            day (string-to-number (match-string 2 time-str))
            hour 0 minute 0 second 0
            time-str (replace-match "" t t time-str)))
    ;; Return decoded time and remaining time string
    (cons (list second minute hour day month year) time-str)))

(defun taskpaper-time-parse-relative-word (nowdecode time-str)
  "Parse relative date word."
  (let ((year   (nth 5 nowdecode))
        (month  (nth 4 nowdecode))
        (day    (nth 3 nowdecode))
        (hour   (nth 2 nowdecode))
        (minute (nth 1 nowdecode))
        (second (nth 0 nowdecode)) word)
    (when (string-match taskpaper-time-relative-word-regexp time-str)
      (setq word (match-string 1 time-str)
            time-str (replace-match "" t t time-str)))
    (cond ((equal word "today")
           (setq hour 0 minute 0 second 0))
          ((equal word "tomorrow")
           (setq day (1+ day) hour 0 minute 0 second 0))
          ((equal word "yesterday")
           (setq day (1- day) hour 0 minute 0 second 0))
          ((equal word "now")
           (setq taskpaper-time-was-given t)))
    ;; Return decoded time and remaining time string
    (cons (list second minute hour day month year) time-str)))

(defun taskpaper-time-parse-relative-period (nowdecode time-str)
  "Parse relative time period."
  (let ((wday   (nth 6 nowdecode))
        (year   (nth 5 nowdecode))
        (month  (nth 4 nowdecode))
        (day    (nth 3 nowdecode))
        (hour   (nth 2 nowdecode))
        (minute (nth 1 nowdecode))
        (second (nth 0 nowdecode)) inc period wday1)
    (when (string-match taskpaper-time-relative-period-regexp time-str)
      (setq inc (taskpaper-time-relative-spec-to-inc (match-string 1 time-str))
            period (match-string 2 time-str)
            time-str (replace-match "" t t time-str)))
    (cond
     ((equal period "year")
      (setq year (+ year inc)
            month 1 day 1 hour 0 minute 0 second 0))
     ((equal period "quarter")
      (setq month (+ (1+ (* (floor (/ (1- month) 3)) 3)) (* inc 3))
            day 1 hour 0 minute 0 second 0))
     ((equal period "month")
      (setq month (+ month inc)
            day 1 hour 0 minute 0 second 0))
     ((equal period "week")
      (and (= wday 0) (setq wday 7))
      (setq wday1 1
            day (+ day (- wday1 wday) (* inc 7))
            hour 0 minute 0 second 0))
     ((equal period "day")
      (setq day (+ day inc)
            hour 0 minute 0 second 0)))
    ;; Return decoded time and remaining time string
    (cons (list second minute hour day month year) time-str)))

(defun taskpaper-time-parse-relative-month (nowdecode time-str)
  "Parse relative month name with optional day."
  (let ((year   (nth 5 nowdecode))
        (month  (nth 4 nowdecode))
        (day    (nth 3 nowdecode))
        (hour   (nth 2 nowdecode))
        (minute (nth 1 nowdecode))
        (second (nth 0 nowdecode)) inc)
    (when (string-match taskpaper-time-relative-month-regexp time-str)
      (setq inc (taskpaper-time-relative-spec-to-inc (match-string 1 time-str))
            month (cdr (assoc (match-string 2 time-str) parse-time-months))
            day (if (match-end 3) (string-to-number (match-string 3 time-str)) 1)
            year (+ year inc)
            hour 0 minute 0 second 0
            time-str (replace-match "" t t time-str)))
    ;; Return decoded time and remaining time string
    (cons (list second minute hour day month year) time-str)))

(defun taskpaper-time-parse-relative-weekday (nowdecode time-str)
  "Parse relative weekday."
  (let ((wday   (nth 6 nowdecode))
        (year   (nth 5 nowdecode))
        (month  (nth 4 nowdecode))
        (day    (nth 3 nowdecode))
        (hour   (nth 2 nowdecode))
        (minute (nth 1 nowdecode))
        (second (nth 0 nowdecode)) inc wday1)
    (when (string-match taskpaper-time-relative-weekday-regexp time-str)
      (setq inc (taskpaper-time-relative-spec-to-inc (match-string 1 time-str))
            wday1 (cdr (assoc (match-string 2 time-str) parse-time-weekdays))
            time-str (replace-match "" t t time-str)))
    (and (= wday 0) (setq wday 7)) (and (= wday1 0) (setq wday1 7))
    (setq day (+ day (- wday1 wday) (* inc 7))
          hour 0 minute 0 second 0)
    ;; Return decoded time and remaining time string
    (cons (list second minute hour day month year) time-str)))

(defun taskpaper-time-parse-month (timedecode time-str)
  "Parse month name with optional day."
  (let ((year   (nth 5 timedecode))
        (month  (nth 4 timedecode))
        (day    (nth 3 timedecode))
        (hour   (nth 2 timedecode))
        (minute (nth 1 timedecode))
        (second (nth 0 timedecode)))
    (when (string-match taskpaper-time-month-regexp time-str)
      (setq month (cdr (assoc (match-string 1 time-str) parse-time-months))
            day (if (match-end 2) (string-to-number (match-string 2 time-str)) 1)
            hour 0 minute 0 second 0
            time-str (replace-match "" t t time-str)))
    ;; Return decoded time and remaining time string
    (cons (list second minute hour day month year) time-str)))

(defun taskpaper-time-parse-weekday (timedecode time-str)
  "Parse weekday."
  (let ((year   (nth 5 timedecode))
        (month  (nth 4 timedecode))
        (day    (nth 3 timedecode))
        (hour   (nth 2 timedecode))
        (minute (nth 1 timedecode))
        (second (nth 0 timedecode)) wday wday1)
    (when (string-match taskpaper-time-weekday-regexp time-str)
      (setq wday1 (cdr (assoc (match-string 1 time-str) parse-time-weekdays))
            wday (nth 6 (decode-time (encode-time 0 0 0 day month year)))
            time-str (replace-match "" t t time-str)))
    (and (= wday 0) (setq wday 7)) (and (= wday1 0) (setq wday1 7))
    (setq day (+ day (- wday1 wday)) hour 0 minute 0 second 0)
    ;; Return decoded time and remaining time string
    (cons (list second minute hour day month year) time-str)))

(defun taskpaper-time-parse-time (timedecode time-str)
  "Parse time."
  (let ((year   (nth 5 timedecode))
        (month  (nth 4 timedecode))
        (day    (nth 3 timedecode))
        (hour   (nth 2 timedecode))
        (minute (nth 1 timedecode))
        (second (nth 0 timedecode)) ampm)
    (cond
     ((string-match taskpaper-time-ampm-time-regexp time-str)
      (setq hour (string-to-number (match-string 1 time-str))
            minute (if (match-end 2) (string-to-number (match-string 2 time-str)) 0)
            second 0
            ampm (string-to-char (match-string 3 time-str))
            time-str (replace-match "" t t time-str)))
     ((string-match taskpaper-time-time-regexp time-str)
      (setq hour (string-to-number (match-string 1 time-str))
            minute (string-to-number (match-string 2 time-str))
            second 0
            time-str (replace-match "" t t time-str))))
    (and (equal ?a ampm) (= hour 12) (setq hour 0))
    (and (equal ?p ampm) (< hour 12) (setq hour (+ hour 12)))
    (setq taskpaper-time-was-given t)
    ;; Return decoded time and remaining time string
    (cons (list second minute hour day month year) time-str)))

(defun taskpaper-time-parse-duration-offset (timedecode time-str)
  "Parse duration offset."
  (let ((year   (nth 5 timedecode))
        (month  (nth 4 timedecode))
        (day    (nth 3 timedecode))
        (hour   (nth 2 timedecode))
        (minute (nth 1 timedecode))
        (second (nth 0 timedecode)) dir inc unit wday wday1)
    (when (string-match taskpaper-time-duration-offset-regexp time-str)
      (setq dir (string-to-char (match-string 1 time-str))
            inc (string-to-number (match-string 2 time-str))
            inc (* inc (if (= dir ?-) -1 1))
            unit (match-string 3 time-str)
            time-str (replace-match "" t t time-str)))
    (cond
     ((assoc unit parse-time-weekdays)
      (setq wday1 (cdr (assoc unit parse-time-weekdays))
            wday (nth 6 (decode-time (encode-time 0 0 0 day month year))))
      (and (= wday 0) (setq wday 7)) (and (= wday1 0) (setq wday1 7))
      (and (>= wday1 wday) (> inc 0) (setq inc (1- inc)))
      (setq day (+ day (- wday1 wday) (* inc 7))))
     ((member unit '("min" "mins" "minute" "minutes"))
      (setq minute (+ minute inc) taskpaper-time-was-given t))
     ((member unit '("h" "hour" "hours"))
      (setq hour (+ hour inc) taskpaper-time-was-given t))
     ((member unit '("d" "day" "days"))
      (setq day (+ day inc)))
     ((member unit '("w" "week" "weeks"))
      (setq day (+ day (* inc 7))))
     ((member unit '("m" "month" "months"))
      (setq month (+ month inc)))
     ((member unit '("q" "quarter" "quarters"))
      (setq month (+ month (* inc 3))))
     ((member unit '("y" "year" "years"))
      (setq year (+ year inc))))
    ;; Return decoded time and remaining time string
    (cons (list second minute hour day month year) time-str)))

(defun taskpaper-parse-time-string (time-str &optional timedecode)
  "Parse the time string TIME-STR.
Return list (SEC MIN HOUR DAY MON YEAR DOW DST TZ). When
TIMEDECODE time value is given, calculate date and time based on
this time, otherwise use current time."
  (let ((nowdecode (decode-time (current-time))) tmp)
    (setq taskpaper-time-was-given nil
          time-str (downcase time-str)
          timedecode (or timedecode nowdecode))
    (while (> (length time-str) 0)
      ;; Trim leading whitespaces
      (when (string-match taskpaper-time-whitespace-regexp time-str)
        (setq time-str (replace-match "" nil nil time-str)))
      (unless (= (length time-str) 0)
        (cond
         ;; ISO 8601 date
         ((string-match-p taskpaper-time-iso-date-regexp time-str)
          (setq tmp (taskpaper-time-parse-iso-date nowdecode time-str)
                timedecode (car tmp) time-str (cdr tmp)))
         ;; ISO 8601 week date
         ((string-match taskpaper-time-iso-week-date-regexp time-str)
          (setq tmp (taskpaper-time-parse-iso-week-date nowdecode time-str)
                timedecode (car tmp) time-str (cdr tmp)))
         ;; ISO 8601 date with year omitted
         ((string-match-p taskpaper-time-iso-date-short-regexp time-str)
          (setq tmp (taskpaper-time-parse-iso-date-short nowdecode time-str)
                timedecode (car tmp) time-str (cdr tmp)))
         ;; Relative date
         ((string-match-p taskpaper-time-relative-word-regexp time-str)
          (setq tmp (taskpaper-time-parse-relative-word nowdecode time-str)
                timedecode (car tmp) time-str (cdr tmp)))
         ;; Relative time period
         ((string-match-p taskpaper-time-relative-period-regexp time-str)
          (setq tmp (taskpaper-time-parse-relative-period nowdecode time-str)
                timedecode (car tmp) time-str (cdr tmp)))
         ;; Relative month name with optional date
         ((string-match-p taskpaper-time-relative-month-regexp time-str)
          (setq tmp (taskpaper-time-parse-relative-month nowdecode time-str)
                timedecode (car tmp) time-str (cdr tmp)))
         ;; Relative weekday
         ((string-match-p taskpaper-time-relative-weekday-regexp time-str)
          (setq tmp (taskpaper-time-parse-relative-weekday nowdecode time-str)
                timedecode (car tmp) time-str (cdr tmp)))
         ;; Month name with optional day
         ((string-match-p taskpaper-time-month-regexp time-str)
          (setq tmp (taskpaper-time-parse-month timedecode time-str)
                timedecode (car tmp) time-str (cdr tmp)))
         ;; Weekday
         ((string-match-p taskpaper-time-weekday-regexp time-str)
          (setq tmp (taskpaper-time-parse-weekday timedecode time-str)
                timedecode (car tmp) time-str (cdr tmp)))
         ;; Time
         ((or (string-match-p taskpaper-time-time-regexp time-str)
              (string-match-p taskpaper-time-ampm-time-regexp time-str))
          (setq tmp (taskpaper-time-parse-time timedecode time-str)
                timedecode (car tmp) time-str (cdr tmp)))
         ;; Duration offset
         ((string-match-p taskpaper-time-duration-offset-regexp time-str)
          (setq tmp (taskpaper-time-parse-duration-offset timedecode time-str)
                timedecode (car tmp) time-str (cdr tmp)))
         ;; Unparseable run of non-whitespace characters
         ((string-match taskpaper-time-non-whitespace-regexp time-str)
          (setq time-str (replace-match "" t t time-str))))))
    ;; Get rid of out-of-range values
    ;; TODO: Account for daylight saving?
    (decode-time (apply 'encode-time timedecode))))

(defun taskpaper-expand-time-string (time-str &optional timedecode with-time)
  "Parse and format time string TIME-STR.
Return the formatted time string. When TIMEDECODE time value is
given, calculate time based on this time, otherwise use current
time. If the original time string specifies a time or if the
optional argument WITH-TIME is non-nil, the formatted output
contains the date and the time. Otherwise, only the date is
included."
  (let ((time (taskpaper-parse-time-string time-str timedecode))
        (fmt (if (or with-time taskpaper-time-was-given)
                 "%Y-%m-%d %H:%M" "%Y-%m-%d")))
    (format-time-string fmt (apply 'encode-time time))))

(defun taskpaper-time-string-to-seconds (time-str &optional timedecode)
  "Convert time string TIME-STR to a float number of seconds.
Return the float number of seconds since the beginning of the
epoch. When TIMEDECODE time value is given, calculate time based
on this time, otherwise use current time."
  (float-time (apply 'encode-time
                     (taskpaper-parse-time-string time-str timedecode))))

(defun taskpaper-2ft (s)
  "Convert S to a float number of seconds.
If S is already a number of seconds, just return it. If S is a
string, parse it as a time string and convert to float time. If S
is nil, return 0."
  (cond ((numberp s) s)
        ((stringp s)
         (condition-case nil
             (taskpaper-time-string-to-seconds s) (error 0.)))
        (t 0.)))

;;;; Interaction with calendar

(defun taskpaper-goto-calendar (&optional arg)
  "Go to the calendar at the current date.
If point is on a tag with value, interpret the value as time
string and go to the corresponding date instead. A
\\[universal-argument] prefix argument can be used to force the
current date."
  (interactive "P")
  (let ((calendar-move-hook nil)
        (calendar-view-diary-initially-flag nil)
        (calendar-view-holidays-initially-flag nil)
        value time date)
    (cond
     ((and (taskpaper-in-tag-p)
           (taskpaper-in-regexp taskpaper-tag-regexp))
      (setq value (match-string-no-properties 3))
      (when value
        (setq value (taskpaper-tag-value-unescape value)
              time (taskpaper-parse-time-string value)
              date (list (nth 4 time) (nth 3 time) (nth 5 time)))))
     (t (setq date nil)))
    (calendar)
    (if (and date (not arg)) (calendar-goto-date date) (calendar-goto-today))))

(defun taskpaper-show-in-calendar ()
  "Show date at point in a calendar window.
If point is on a tag with value, interpret the value as time
string and show the corresponding date."
  (interactive)
  (let ((swin (selected-window)) (sframe (selected-frame)))
    (taskpaper-goto-calendar)
    (select-window swin) (select-frame-set-input-focus sframe)))

(defun taskpaper-get-date-from-calendar ()
  "Return a list (MONTH DAY YEAR) of date at point in calendar."
  (with-current-buffer "*Calendar*"
    (save-match-data (calendar-cursor-to-date))))

(defun taskpaper-date-from-calendar ()
  "Insert time stamp corresponding to cursor date in the calendar buffer."
  (interactive)
  (let* ((date (taskpaper-get-date-from-calendar))
         (time (encode-time 0 0 0 (nth 1 date) (nth 0 date) (nth 2 date))))
    (insert-before-markers (format-time-string "%Y-%m-%d" time))))

;;;; Date and time prompt

(defvar taskpaper-calendar-selected-date nil
  "Temporary storage for date selected from calendar.
Date is stored as internal time representation.")

(defun taskpaper-eval-in-calendar (form)
  "Eval FORM in the calendar window."
  (let ((cwin (get-buffer-window "*Calendar*" t)))
    (when cwin
      (let ((inhibit-message t))
        (with-selected-window cwin (eval form))))))

(defvar taskpaper-read-date-minibuffer-local-map
  (let* ((map (make-sparse-keymap)))
    (set-keymap-parent map minibuffer-local-map)
    (define-key map "!"
      (lambda () (interactive)
        (taskpaper-eval-in-calendar '(diary-mark-entries))
        (message nil)))
    (define-key map (kbd "C-.")
      (lambda () (interactive)
        (taskpaper-eval-in-calendar '(calendar-goto-today))))
    (define-key map ">"
      (lambda () (interactive)
        (taskpaper-eval-in-calendar '(calendar-scroll-left 1))))
    (define-key map "<"
      (lambda () (interactive)
        (taskpaper-eval-in-calendar '(calendar-scroll-right 1))))
    map)
  "Keymap for minibuffer commands when using `taskpaper-read-date'.")

(defun taskpaper-calendar-select ()
  "Return to `taskpaper-read-date' with the date currently selected."
  (interactive)
  (when (calendar-cursor-to-date)
    (let* ((date (calendar-cursor-to-date))
           (time (encode-time 0 0 0 (nth 1 date) (nth 0 date) (nth 2 date))))
      (setq taskpaper-calendar-selected-date time))
    (when (active-minibuffer-window) (exit-minibuffer))))

(defun taskpaper-read-date-recenter-calendar (&optional _begin _end _length)
  "Display the date prompt interpretation live in the calendar window.
The function should be called from the minibuffer as part of
`after-change-functions' hook."
  (when (minibufferp (current-buffer))
    (let* ((str (buffer-substring (point-at-bol) (point-max)))
           (time (taskpaper-parse-time-string str))
           (date (list (nth 4 time) (nth 3 time) (nth 5 time)))
           (cwin (get-buffer-window "*Calendar*" t)))
      (when cwin
        (let ((inhibit-message t) (calendar-move-hook nil))
          (with-selected-window cwin (calendar-goto-date date)))))))

(defvar taskpaper-read-date-overlay nil)
(defun taskpaper-read-date-display ()
  "Display the date prompt interpretation live in the minibuffer."
  (when taskpaper-read-date-display-live
    (when taskpaper-read-date-overlay
      (delete-overlay taskpaper-read-date-overlay))
    (when (minibufferp (current-buffer))
      (save-excursion
        (end-of-line 1)
        (and (< (- (point-max) (point)) 3)
             (not (equal
                   (buffer-substring (max (point-min) (- (point) 3)) (point))
                   "   "))
             (insert "   ")))
      (let* ((str (buffer-substring (point-at-bol) (point-max)))
             (txt (taskpaper-expand-time-string str)))
        (setq taskpaper-read-date-overlay
              (make-overlay (1- (point-at-eol)) (point-at-eol)))
        (taskpaper-overlay-display
         taskpaper-read-date-overlay txt 'secondary-selection)))))

(defun taskpaper-read-date (&optional prompt with-time to-time)
  "Prompt the user for a date using PROMPT.
Return formatted date as string. If the user specifies a time or
if the optional argument WITH-TIME is non-nil, the formatted
output contains the date and the time. Otherwise, only the date
is included. If optional argument TO-TIME is non-nil, return the
time converted to an internal time."
  (let ((mouse-autoselect-window nil)
        (calendar-setup nil)
        (calendar-move-hook nil)
        (calendar-view-diary-initially-flag nil)
        (calendar-view-holidays-initially-flag nil)
        (prompt (or prompt "Date & time: ")) text)
    (save-excursion
      (save-window-excursion
        (when taskpaper-read-date-popup-calendar
          ;; Open calendar
          (calendar) (calendar-goto-today))
        (let (;; Save calendar keymap
              (old-map (copy-keymap calendar-mode-map))
              ;; Set keymap to control calendar from minibuffer
              (minibuffer-local-map
               (copy-keymap taskpaper-read-date-minibuffer-local-map)))
          (unwind-protect
              (progn
                ;; Set temporary calendar keymap
                (define-key calendar-mode-map (kbd "RET")
                  'taskpaper-calendar-select)
                (define-key calendar-mode-map [mouse-1]
                  'taskpaper-calendar-select)
                ;; Reset `taskpaper-calendar-selected-date'
                (setq taskpaper-calendar-selected-date nil)
                ;; Activate live preview
                (add-hook 'post-command-hook
                          'taskpaper-read-date-display)
                (add-hook 'after-change-functions
                          'taskpaper-read-date-recenter-calendar)
                ;; Read date
                (setq text (read-string prompt nil
                                        taskpaper-read-date-history)))
            ;; Deactivate live preview
            (remove-hook 'post-command-hook
                         'taskpaper-read-date-display)
            (remove-hook 'after-change-functions
                         'taskpaper-read-date-recenter-calendar)
            ;; Restore calendar keymap
            (setq calendar-mode-map old-map)
            ;; Remove live preview overlay
            (when taskpaper-read-date-overlay
              (delete-overlay taskpaper-read-date-overlay)
              (setq taskpaper-read-date-overlay nil))))))
    ;; Convert and format date
    (let* ((date (taskpaper-parse-time-string text))
           (time (or taskpaper-calendar-selected-date
                     (apply 'encode-time date)))
           (fmt (if (or with-time
                        (and taskpaper-time-was-given
                             (not taskpaper-calendar-selected-date)))
                    "%Y-%m-%d %H:%M" "%Y-%m-%d")))
      ;; Return the selected date
      (if to-time time (format-time-string fmt time)))))

(defun taskpaper-read-date-insert-timestamp ()
  "Prompt the user for a date and insert a timestamp at point."
  (interactive)
  (insert-before-markers (format "%s" (taskpaper-read-date))))

;;;; Tags

(defun taskpaper-get-buffer-tags (&optional pos)
  "Return a list of buffer tag names for completion.
If optional POS is inside a tag, ignore the tag."
  (let (tag tags)
    (save-excursion
      (save-restriction
        (widen) (goto-char (point-min))
        (save-match-data
          (while (re-search-forward taskpaper-tag-regexp nil t)
            (when (taskpaper-in-tag-p (match-beginning 1))
              (setq tag (match-string-no-properties 2))
              (unless (and pos
                           (<= (match-beginning 0) pos)
                           (>= (match-end 0) pos))
                (push tag tags)))))))
    (taskpaper-sort (taskpaper-uniquify tags))))

(defun taskpaper-complete-tag-at-point (&optional attrs)
  "Complete tag name or query attribute at point.
Complete tag name or query attribute using completions from
ATTRS. If ATTRS is not given, use tag names from the current
buffer instead."
  (interactive "*")
  (setq attrs (or attrs (taskpaper-add-tag-prefix
                         (taskpaper-get-buffer-tags (point)))))
  (let* ((completion-ignore-case nil)
         (re (format "@%s*" taskpaper-tag-name-char-regexp))
         (pattern (if (taskpaper-in-regexp re)
                      (match-string-no-properties 0) ""))
         (completion-buffer-name "*Completions*")
         (end (point)) completion)
    ;; Close completion window, if any
    (let ((window (get-buffer-window completion-buffer-name)))
      (when window (delete-window window)))
    ;; Check if there is something to complete
    (unless (taskpaper-in-regexp re)
      (user-error "Nothing to complete"))
    ;; Try completion
    (setq completion (try-completion pattern attrs))
    (cond
     ((eq completion t)
      ;; Sole completion
      (message "Sole completion"))
     ((null completion)
      ;; No completion found
      (user-error "No match for %s" pattern))
     ((not (string-equal pattern completion))
      ;; Expand the current word to max match
      (delete-region (- end (length pattern)) end) (insert completion))
     (t
      ;; List possible completions
      (when completion-auto-help
        (with-output-to-temp-buffer completion-buffer-name
          (display-completion-list (all-completions pattern attrs))))
      (set-window-dedicated-p
       (get-buffer-window completion-buffer-name) 'soft)))))

(defun taskpaper-fast-tag-selection ()
  "Provide fast selection interface for tags.
Return selected tag specifier."
  (unless taskpaper-tag-alist (error "No predefined tags"))
  (save-excursion
    (save-window-excursion
      (switch-to-buffer-other-window
       (get-buffer-create "*TaskPaper custom tags*"))
      (erase-buffer)
      (setq show-trailing-whitespace nil)
      (let* ((maxlen
              (apply
               'max (mapcar
                     (lambda (x)
                       (if (stringp (car x)) (string-width (car x)) 0))
                     taskpaper-tag-alist)))
             (fwidth (+ maxlen 5))
             (ncol (floor (/ (window-width) fwidth)))
             cnt tbl e c tg)
        ;; Insert selection dialog
        (insert "\n")
        (setq tbl taskpaper-tag-alist cnt 0)
        (while (setq e (pop tbl))
          (setq tg (car e) c (cdr e))
          (when (and c tg)
            (insert
             (propertize (char-to-string c)
                         'face 'taskpaper-fast-select-key)
             " " (taskpaper-add-tag-prefix tg)
             (make-string (- fwidth 2 (length tg)) ?\ )))
          (when (= (setq cnt (1+ cnt)) ncol) (insert "\n") (setq cnt 0)))
        (insert "\n\n") (goto-char (point-min)) (fit-window-to-buffer)
        ;; Select tag specifier
        (setq c (read-char-exclusive "Press key for tag:"))
        (if (setq e (rassoc c taskpaper-tag-alist) tg (car e))
            (prog1 tg (kill-buffer))
          (kill-buffer) (setq quit-flag t))))))

(defun taskpaper-item-set-tag-fast-select ()
  "Set a tag for the item at point using fast tag selection."
  (interactive)
  (let ((re (format "\\`@?\\(%s\\)\\(?:(\\(%s\\))\\)?\\'"
                    taskpaper-tag-name-regexp
                    taskpaper-tag-value-regexp))
        (tag (taskpaper-fast-tag-selection))
        name value)
    (unless (string-match re tag) (error "Invalid tag specifier: %s" tag))
    (setq name  (match-string-no-properties 1 tag)
          value (match-string-no-properties 2 tag)
          name  (taskpaper-remove-tag-prefix name)
          value (taskpaper-tag-value-unescape value))
    ;; Expand tag value
    (when (and value (string-prefix-p "%%" value))
      (setq value (string-remove-prefix "%%" value))
      (if (equal value "")
          (setq value (taskpaper-read-date))
        (setq value (taskpaper-expand-time-string value))))
    (taskpaper-item-set-attribute name value)))

(defun taskpaper-remove-tag-at-point ()
  "Remove tag at point."
  (interactive)
  (if (and (taskpaper-in-tag-p)
           (taskpaper-in-regexp taskpaper-tag-regexp))
      (delete-region (match-beginning 0) (match-end 0))
    (user-error "No tag at point.")))

(defun taskpaper-item-toggle-done ()
  "Toggle done state of the current item."
  (interactive)
  (let ((type (taskpaper-item-get-attribute "type")) fmt)
    (when (member type '("task" "project"))
      (if (taskpaper-item-has-attribute "done")
          (taskpaper-item-remove-attribute "done")
        ;; Run blocker hook
        (when taskpaper-blocker-hook
          (unless (save-excursion
                    (save-restriction
                      (run-hook-with-args-until-failure
                       'taskpaper-blocker-hook (point-at-bol))))
            (user-error "Completing is blocked")))
        ;; Remove extra tags
        (mapc (lambda (tag) (taskpaper-item-remove-attribute tag))
              taskpaper-tags-to-remove-when-done)
        ;; Complete the item
        (cond ((or (eq taskpaper-complete-save-date t)
                   (eq taskpaper-complete-save-date 'date))
               (setq fmt "%Y-%m-%d"))
              ((eq taskpaper-complete-save-date 'time)
               (setq fmt "%Y-%m-%d %H:%M")))
        (taskpaper-item-set-attribute
         "done" (when fmt (format-time-string fmt (current-time))))
        ;; Run hook
        (run-hooks 'taskpaper-after-completion-hook)))))

;;;; Relational functions

(defun taskpaper-num= (a b)
  "Return t if two arg numbers are equal.
Strings are converted to numbers before comparing."
  (cond ((and a b)
         (setq a (string-to-number a) b (string-to-number b))
         (= a b))
        (t nil)))

(defun taskpaper-num< (a b)
  "Return t if first arg number is less than second.
Strings are converted to numbers before comparing."
  (cond ((and a b)
         (setq a (string-to-number a) b (string-to-number b))
         (< a b))
        (t nil)))

(defun taskpaper-num<= (a b)
  "Return t if first arg number is less than or equal to second.
Strings are converted to numbers before comparing."
  (cond ((and a b)
         (setq a (string-to-number a) b (string-to-number b))
         (<= a b))
        (t nil)))

(defun taskpaper-num> (a b)
  "Return t if first arg number is greater than second.
Strings are converted to numbers before comparing."
  (cond ((and a b)
         (setq a (string-to-number a) b (string-to-number b))
         (> a b))
        (t nil)))

(defun taskpaper-num>= (a b)
  "Return t if first arg number is greater than or equal to second.
Strings are converted to numbers before comparing."
  (cond ((and a b)
         (setq a (string-to-number a) b (string-to-number b))
         (>= a b))
        (t nil)))

(defun taskpaper-num<> (a b)
  "Return t if two arg numbers are not equal.
Strings are converted to numbers before comparing."
  (cond ((and a b)
         (setq a (string-to-number a) b (string-to-number b))
         (not (= a b)))
        (t nil)))

(defun taskpaper-string= (a b)
  "Return t if two arg strings are equal.
Case is significant."
  (cond ((and a b) (string= a b)) (t nil)))

(defun taskpaper-string< (a b)
  "Return t if first arg string is less than second.
Case is significant."
  (cond ((and a b) (string< a b)) (t nil)))

(defun taskpaper-string<= (a b)
  "Return t if first arg string is less than or equal to second.
Case is significant."
  (cond ((and a b) (or (string< a b) (string= a b)))
        (t nil)))

(defun taskpaper-string> (a b)
  "Return t if first arg string is greater than second.
Case is significant."
  (cond ((and a b) (and (not (string< a b)) (not (string= a b))))
        (t nil)))

(defun taskpaper-string>= (a b)
  "Return t if first arg string is greater than or equal to second.
Case is significant."
  (cond ((and a b) (not (string< a b))) (t nil)))

(defun taskpaper-string<> (a b)
  "Return t if two arg string are not equal.
Case is significant."
  (cond ((and a b) (not (string= a b))) (t nil)))

(defun taskpaper-string-match-p (a b)
  "Return t if first arg string matches second arg regexp.
Case is significant."
  (cond ((and a b)
         (let ((case-fold-search nil)) (string-match-p b a)))
        (t nil)))

(defun taskpaper-string-contain-p (a b)
  "Return t if first arg string contains second.
Case is significant."
  (cond ((and a b)
         (let ((case-fold-search nil))
           (setq b (regexp-quote b)) (string-match-p b a)))
        (t nil)))

(defun taskpaper-string-prefix-p (a b)
  "Return t if second arg string is a prefix of first.
Case is significant."
  (cond ((and a b) (string-prefix-p b a)) (t nil)))

(defun taskpaper-string-suffix-p (a b)
  "Return t if second arg string is a suffix of first.
Case is significant."
  (cond ((and a b) (string-suffix-p b a)) (t nil)))

(defun taskpaper-istring= (a b)
  "Return t if two strings are equal.
Case is ignored."
  (cond ((and a b)
         (setq a (downcase a) b (downcase b)) (string= a b))
        (t nil)))

(defun taskpaper-istring< (a b)
  "Return t if first arg string is less than second.
Case is ignored."
  (cond ((and a b)
         (setq a (downcase a) b (downcase b)) (string< a b))
        (t nil)))

(defun taskpaper-istring<= (a b)
  "Return t if first arg string is less than or equal to second.
Case is ignored."
  (cond ((and a b)
         (setq a (downcase a) b (downcase b))
         (or (string< a b) (string= a b)))
        (t nil)))

(defun taskpaper-istring> (a b)
  "Return t if first arg string is greater than second.
Case is ignored."
  (cond ((and a b)
         (setq a (downcase a) b (downcase b))
         (and (not (string< a b)) (not (string= a b))))
        (t nil)))

(defun taskpaper-istring>= (a b)
  "Return t if first arg string is greater than or equal to second.
Case is ignored."
  (cond ((and a b)
         (setq a (downcase a) b (downcase b)) (not (string< a b)))
        (t nil)))

(defun taskpaper-istring<> (a b)
  "Return t if two arg string are not equal.
Case is ignored."
  (cond ((and a b)
         (setq a (downcase a) b (downcase b)) (not (string= a b)))
        (t nil)))

(defun taskpaper-istring-match-p (a b)
  "Return t if first arg string matches second arg regexp.
Case is ignored."
  (cond ((and a b)
         (let ((case-fold-search nil))
           (setq a (downcase a) b (downcase b)) (string-match-p b a)))
        (t nil)))

(defun taskpaper-istring-contain-p (a b)
  "Return t if first arg string contains second.
Case is ignored."
  (cond ((and a b)
         (let ((case-fold-search nil))
           (setq a (downcase a) b (downcase b))
           (setq b (regexp-quote b)) (string-match-p b a)))
        (t nil)))

(defun taskpaper-istring-prefix-p (a b)
  "Return t if second arg string is a prefix of first.
Case is ignored."
  (cond ((and a b)
         (setq a (downcase a) b (downcase b)) (string-prefix-p b a))
        (t nil)))

(defun taskpaper-istring-suffix-p (a b)
  "Return t if second arg string is a suffix of first.
Case is ignored."
  (cond ((and a b)
         (setq a (downcase a) b (downcase b)) (string-suffix-p b a))
        (t nil)))

(defun taskpaper-time= (a b)
  "Return t if two arg time strings are equal.
Time string are converted to a float number of seconds before
numeric comparing. If any argument is a float number, it will be
treated as the float number of seconds since the beginning of the
epoch."
  (cond ((and a b)
         (setq a (taskpaper-2ft a) b (taskpaper-2ft b))
         (and (> a 0) (> b 0) (= a b)))
        (t nil)))

(defun taskpaper-time< (a b)
  "Return t if first arg time string is less than second.
Time string are converted to a float number of seconds before
numeric comparing. If any argument is a float number, it will be
treated as the float number of seconds since the beginning of the
epoch."
  (cond ((and a b)
         (setq a (taskpaper-2ft a) b (taskpaper-2ft b))
         (and (> a 0) (> b 0) (< a b)))
        (t nil)))

(defun taskpaper-time<= (a b)
  "Return t if first arg time string is less than or equal to second.
Time string are converted to a float number of seconds before
numeric comparing. If any argument is a float number, it will be
treated as the float number of seconds since the beginning of the
epoch."
  (cond ((and a b)
         (setq a (taskpaper-2ft a) b (taskpaper-2ft b))
         (and (> a 0) (> b 0) (<= a b)))
        (t nil)))

(defun taskpaper-time> (a b)
  "Return t if first arg time string is greater than second.
Time string are converted to a float number of seconds before
numeric comparing. If any argument is a float number, it will be
treated as the float number of seconds since the beginning of the
epoch."
  (cond ((and a b)
         (setq a (taskpaper-2ft a) b (taskpaper-2ft b))
         (and (> a 0) (> b 0) (> a b)))
        (t nil)))

(defun taskpaper-time>= (a b)
  "Return t if first arg time string is greater than or equal to second.
Time string are converted to a float number of seconds before
numeric comparing. If any argument is a float number, it will be
treated as the float number of seconds since the beginning of the
epoch."
  (cond ((and a b)
         (setq a (taskpaper-2ft a) b (taskpaper-2ft b))
         (and (> a 0) (> b 0) (>= a b)))
        (t nil)))

(defun taskpaper-time<> (a b)
  "Return t if two arg time strings are not equal.
Time string are converted to a float number of seconds before
numeric comparing. If any argument is a float number, it will be
treated as the float number of seconds since the beginning of the
epoch."
  (cond ((and a b)
         (setq a (taskpaper-2ft a) b (taskpaper-2ft b))
         (and (> a 0) (> b 0) (not (= a b))))
        (t nil)))

(defun taskpaper-cslist-num= (a b)
  "Return t if two arg cslists are equal.
Each list element is converted to number before numeric
comparing."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (and (= (length a) (length b))
         (cl-every 'taskpaper-num= a b)))
   (t nil)))

(defun taskpaper-cslist-num< (a b)
  "Return t if first arg cslist is less than second.
Each list element is converted to number before numeric
comparing."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (cl-every 'taskpaper-num< a b))
   (t nil)))

(defun taskpaper-cslist-num<= (a b)
  "Return t if first arg cslist is less than of equal to second.
Each list element is converted to number before numeric
comparing."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (cl-every 'taskpaper-num<= a b))
   (t nil)))

(defun taskpaper-cslist-num> (a b)
  "Return t if first arg cslist is greater than second.
Each list element is converted to number before numeric
comparing."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (cl-every 'taskpaper-num> a b))
   (t nil)))

(defun taskpaper-cslist-num>= (a b)
  "Return t if first arg cslist is greater than or equal to second.
Each list element is converted to number before numeric
comparing."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (cl-every 'taskpaper-num>= a b))
   (t nil)))

(defun taskpaper-cslist-num<> (a b)
  "Return t if two arg cslists are not equal.
Each list element is converted to number before numeric
comparing."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (or (not (= (length a) (length b)))
        (not (cl-every 'taskpaper-num= a b))))
   (t nil)))

(defun taskpaper-cslist-num-match-p (a b)
  "Return t if first arg cslist is subset of second.
Each list element is converted to number before numeric
comparing."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (setq a (mapcar #'string-to-number a)
          b (mapcar #'string-to-number b))
    (cl-subsetp a b :test 'equal))
   (t nil)))

(defun taskpaper-cslist-num-contain-p (a b)
  "Return t if second arg cslist is subset of first.
Each list element is converted to number before numeric
comparing."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (setq a (mapcar #'string-to-number a)
          b (mapcar #'string-to-number b))
    (cl-subsetp b a :test 'equal))
   (t nil)))

(defun taskpaper-cslist-num-head-p (a b)
  "Return t if second arg cslist is head of first.
Each list element is converted to number before numeric
comparing."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (setq a (mapcar #'string-to-number a)
          b (mapcar #'string-to-number b))
    (let (tmp1 tmp2)
      (while (and a b) (push (pop a) tmp1) (push (pop b) tmp2))
      (and tmp1 tmp2 (equal tmp1 tmp2))))
   (t nil)))

(defun taskpaper-cslist-num-tail-p (a b)
  "Return t if second arg cslist is tail of first.
Each list element is converted to number before numeric
comparing."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (setq a (mapcar #'string-to-number a)
          b (mapcar #'string-to-number b))
    (while (and (consp a) (not (equal a b))) (setq a (cdr a)))
    (equal a b))
   (t nil)))

(defun taskpaper-cslist-string= (a b)
  "Return t if two arg cslists are equal.
Case is significant."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (and (= (length a) (length b))
         (cl-every 'taskpaper-string= a b)))
   (t nil)))

(defun taskpaper-cslist-string< (a b)
  "Return t if first arg cslist is less than second.
 Case is significant."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (cl-every 'taskpaper-string< a b))
   (t nil)))

(defun taskpaper-cslist-string<= (a b)
  "Return t if first arg cslist is less than or equal to second.
Case is significant."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (cl-every 'taskpaper-string<= a b))
   (t nil)))

(defun taskpaper-cslist-string> (a b)
  "Return t if first arg cslist is greater than second.
 Case is significant."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (cl-every 'taskpaper-string> a b))
   (t nil)))

(defun taskpaper-cslist-string>= (a b)
  "Return t if first arg cslist is greater than or equal to second.
Case is significant."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (cl-every 'taskpaper-string>= a b))
   (t nil)))

(defun taskpaper-cslist-string<> (a b)
  "Return t if two arg cslists are not equal.
Case is significant."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (or (not (= (length a) (length b)))
        (not (cl-every 'taskpaper-string= a b))))
   (t nil)))

(defun taskpaper-cslist-string-match-p (a b)
  "Return t if first arg cslist is subset of second.
Case is significant."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (cl-subsetp a b :test 'equal))
   (t nil)))

(defun taskpaper-cslist-string-contain-p (a b)
  "Return t if second arg cslist is subset of first.
Case is significant."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (cl-subsetp b a :test 'equal))
   (t nil)))

(defun taskpaper-cslist-string-head-p (a b)
  "Return t if second arg cslist is head of first.
Case is significant."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (let (tmp1 tmp2)
      (while (and a b) (push (pop a) tmp1) (push (pop b) tmp2))
      (and tmp1 tmp2 (equal tmp1 tmp2))))
   (t nil)))

(defun taskpaper-cslist-string-tail-p (a b)
  "Return t if second arg cslist is tail of first.
Case is significant."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (while (and (consp a) (not (equal a b))) (setq a (cdr a)))
    (equal a b))
   (t nil)))

(defun taskpaper-cslist-istring= (a b)
  "Return t if two arg cslists are equal.
Case is ignored."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (and (= (length a) (length b))
         (cl-every 'taskpaper-istring= a b)))
   (t nil)))

(defun taskpaper-cslist-istring< (a b)
  "Return t if first arg cslist is less than second.
Case is ignored."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (cl-every 'taskpaper-istring< a b))
   (t nil)))

(defun taskpaper-cslist-istring<= (a b)
  "Return t if first arg cslist is less than or equal to second.
Case is ignored."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (cl-every 'taskpaper-istring<= a b))
   (t nil)))

(defun taskpaper-cslist-istring> (a b)
  "Return t if first arg cslist is greater than second.
Case is ignored."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (cl-every 'taskpaper-istring> a b))
   (t nil)))

(defun taskpaper-cslist-istring>= (a b)
  "Return t if first arg cslist is greater than or equal to second.
Case is ignored."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (cl-every 'taskpaper-istring>= a b))
   (t nil)))

(defun taskpaper-cslist-istring<> (a b)
  "Return t if two arg cslists are not equal.
Case is ignored."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (or (not (= (length a) (length b)))
        (not (cl-every 'taskpaper-istring= a b))))
   (t nil)))

(defun taskpaper-cslist-istring-match-p (a b)
  "Return t if first arg cslist is subset of second.
Case is ignored."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (setq a (mapcar #'downcase a) b (mapcar #'downcase b))
    (cl-subsetp a b :test 'equal))
   (t nil)))

(defun taskpaper-cslist-istring-contain-p (a b)
  "Return t if second arg cslist is subset of first.
Case is ignored."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (setq a (mapcar #'downcase a) b (mapcar #'downcase b))
    (cl-subsetp b a :test 'equal))
   (t nil)))

(defun taskpaper-cslist-istring-head-p (a b)
  "Return t if second arg cslist is head of first.
Case is ignored."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (setq a (mapcar #'downcase a) b (mapcar #'downcase b))
    (let (tmp1 tmp2)
      (while (and a b) (push (pop a) tmp1) (push (pop b) tmp2))
      (and tmp1 tmp2 (equal tmp1 tmp2))))
   (t nil)))

(defun taskpaper-cslist-istring-tail-p (a b)
  "Return t if second arg cslist is tail of first.
Case is ignored."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (setq a (mapcar #'downcase a) b (mapcar #'downcase b))
    (while (and (consp a) (not (equal a b))) (setq a (cdr a)))
    (equal a b))
   (t nil)))

(defun taskpaper-cslist-time= (a b)
  "Return t if two arg cslists are equal.
Each list element is converted to time value before time
comparing."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (and (= (length a) (length b))
         (cl-every 'taskpaper-time= a b)))
   (t nil)))

(defun taskpaper-cslist-time< (a b)
  "Return t if first arg cslist is less than second.
Each list element is converted to time value before time
comparing."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (cl-every 'taskpaper-time< a b))
   (t nil)))

(defun taskpaper-cslist-time<= (a b)
  "Return t if first arg cslist is less than or equal to second.
Each list element is converted to time value before time
comparing."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (cl-every 'taskpaper-time<= a b))
   (t nil)))

(defun taskpaper-cslist-time> (a b)
  "Return t if first arg cslist is greater than second.
Each list element is converted to time value before time
comparing."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (cl-every 'taskpaper-time> a b))
   (t nil)))

(defun taskpaper-cslist-time>= (a b)
  "Return t if first arg cslist is greater than or equal to second.
Each list element is converted to time value before time
comparing."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (cl-every 'taskpaper-time>= a b))
   (t nil)))

(defun taskpaper-cslist-time<> (a b)
  "Return t if two arg cslists are not equal.
Each list element is converted to time value before time
comparing."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (or (not (= (length a) (length b)))
        (not (cl-every 'taskpaper-time= a b))))
   (t nil)))

(defun taskpaper-cslist-time-match-p (a b)
  "Return t if first arg cslist is subset of second.
Each list element is converted to time value before time
comparing."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (setq a (mapcar #'taskpaper-2ft a) b (mapcar #'taskpaper-2ft b))
    (cl-subsetp a b :test 'equal))
   (t nil)))

(defun taskpaper-cslist-time-contain-p (a b)
  "Return t if second arg cslist is subset of first.
Each list element is converted to time value before time
comparing."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (setq a (mapcar #'taskpaper-2ft a) b (mapcar #'taskpaper-2ft b))
    (cl-subsetp b a :test 'equal))
   (t nil)))

(defun taskpaper-cslist-time-head-p (a b)
  "Return t if second arg cslist is tail of first.
Each list element is converted to time value before time
comparing."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (setq a (mapcar #'taskpaper-2ft a) b (mapcar #'taskpaper-2ft b))
    (let (tmp1 tmp2)
      (while (and a b) (push (pop a) tmp1) (push (pop b) tmp2))
      (and tmp1 tmp2 (equal tmp1 tmp2))))
   (t nil)))

(defun taskpaper-cslist-time-tail-p (a b)
  "Return t if second arg cslist is tail of first.
Each list element is converted to time value before time
comparing."
  (cond
   ((and a b)
    (setq a (taskpaper-attribute-value-to-list a)
          b (taskpaper-attribute-value-to-list b))
    (setq a (mapcar #'taskpaper-2ft a) b (mapcar #'taskpaper-2ft b))
    (while (and (consp a) (not (equal a b))) (setq a (cdr a)))
    (equal a b))
   (t nil)))

;;;; Outline sorting

(defun taskpaper-sort-items-generic
  (getkey-func compare-func &optional with-case reverse)
  "Sort items on a certain level.
When point is at the beginning of the buffer, sort the top-level
items. Else, the children of the current item are sorted.

The GETKEY-FUNC specifies a function to be called with point at
the beginning of the item. It must return either a string or a
number that should serve as the sorting key for that item. The
COMPARE-FUNC specifies a function to compare the sorting keys; it
is called with two arguments, the sorting keys, and should return
non-nil if the first key should sort before the second.

Comparing items ignores case by default. However, with an
optional argument WITH-CASE, the sorting considers case as well.
The optional argument REVERSE will reverse the sort order.

When sorting is done, call `taskpaper-after-sorting-items-hook'."
  (when (buffer-narrowed-p) (widen))
  (let ((case-func (if with-case 'identity 'downcase))
        begin end)
    ;; Set boundaries
    (cond
     ((bobp)
      ;; Sort top-level items
      (setq begin (point))
      (goto-char (point-max))
      ;; Add newline, if nessessary
      (unless (bolp) (end-of-line 1) (newline))
      (setq end (point-max))
      (goto-char begin)
      (taskpaper-outline-show-all)
      (or (outline-on-heading-p)
          (taskpaper-outline-next-item)))
     (t
      ;; Sort children of the current item
      (setq begin (point))
      (taskpaper-outline-end-of-subtree)
      (if (eq (char-after) ?\n) (forward-char 1)
        ;; Add newline, if nessessary
        (unless (bolp) (end-of-line 1) (newline)))
      (setq end (point))
      (goto-char begin)
      (taskpaper-outline-show-subtree)
      (taskpaper-outline-next-item)))
    ;; Check boundaries
    (when (>= begin end)
      (goto-char begin) (user-error "Nothing to sort"))
    ;; Sort items
    (message "Sorting items...")
    (save-restriction
      (narrow-to-region begin end)
      (let ((case-fold-search nil) tmp)
        (sort-subr
         ;; REVERSE arg
         reverse
         ;; NEXTRECFUN arg
         (lambda nil
           (if (re-search-forward "^[\t]*[^\t\f\n]" nil t)
               (goto-char (match-beginning 0))
             (goto-char (point-max))))
         ;; ENDRECFUN arg
         (lambda nil
           (save-match-data
             (condition-case nil
                 (taskpaper-outline-forward-same-level 1)
               (error (goto-char (point-max))))))
         ;; STARTKEYFUN arg
         (lambda nil
           (progn
             (setq tmp (funcall getkey-func))
             (when (stringp tmp)
               (setq tmp (funcall case-func tmp)))
             tmp))
         ;; ENDKEYFUN arg
         nil
         ;; PREDICATE arg
         compare-func))))
  (run-hooks 'taskpaper-after-sorting-items-hook)
  (message "Sorting items...done"))

(defun taskpaper-item-sorting-key-text ()
  "Return sorting key of current item for lexicographic sorting.
Remove indentation, type formatting and inline markup and return
sorting key as string."
  (let ((item (buffer-substring
               (line-beginning-position) (line-end-position))))
    (setq item (taskpaper-remove-markup-chars item)
          item (taskpaper-remove-indentation item)
          item (taskpaper-remove-type-formatting item))
    (set-text-properties 0 (length item) nil item)
    item))

(defun taskpaper-item-sorting-key-type ()
  "Return sorting key of current item for sorting by type.
Get type of item and return sorting key as number."
  (let ((type (taskpaper-item-get-attribute "type"))
        (prec '(("project" . 3) ("task" . 2) ("note" . 1))))
    (cdr (assoc type prec))))

(defun taskpaper-string-sorting-key-text (str)
  "Return sorting key of item string STR for lexicographic sorting.
Like `taskpaper-item-sorting-key-text' but uses argument string
instead of item at point."
  (with-temp-buffer
    (erase-buffer) (insert str)
    (delay-mode-hooks (taskpaper-mode))
    (font-lock-default-function 'taskpaper-mode)
    (font-lock-default-fontify-region (point-min) (point-max) nil)
    (goto-char (point-min))
    (taskpaper-item-sorting-key-text)))

(defun taskpaper-string-sorting-key-type (str)
  "Return sorting key of item string STR for sorting by type.
Like `taskpaper-item-sorting-key-type' but uses argument string
instead of item at point."
  (with-temp-buffer
    (erase-buffer) (insert str) (goto-char (point-min))
    (taskpaper-item-sorting-key-type)))

(defun taskpaper-sort-by-text (&optional reverse)
  "Sort items on a certain level in lexicographic order.
The optional argument REVERSE will reverse the sort order."
  (interactive "P")
  (taskpaper-sort-items-generic
   '(lambda nil (taskpaper-item-sorting-key-text))
   'string-collate-lessp nil reverse))

(defun taskpaper-sort-by-type (&optional reverse)
  "Sort items on a certain level by type.
Tasks will be sorted before notes and projects will be sorted
before tasks. The optional argument REVERSE will reverse the sort
order."
  (interactive "P")
  (taskpaper-sort-items-generic
   '(lambda nil (taskpaper-item-sorting-key-type))
   '> nil reverse))

(defalias 'taskpaper-sort-alpha 'taskpaper-sort-by-text)
(defalias 'taskpaper-item-sorting-key-alpha 'taskpaper-item-sorting-key-text)
(defalias 'taskpaper-string-sorting-key-alpha 'taskpaper-string-sorting-key-text)
(make-obsolete 'taskpaper-sort-alpha 'taskpaper-sort-by-text "1.0")
(make-obsolete 'taskpaper-item-sorting-key-alpha 'taskpaper-item-sorting-key-text "1.0")
(make-obsolete 'taskpaper-string-sorting-key-alpha 'taskpaper-string-sorting-key-text "1.0")

;;;; Outline path

(defun taskpaper-item-get-outline-path (&optional self)
  "Return outline path to the current item.
An outline path is a list of ancestors for the current item, in
reverse order, as a list of strings. When SELF is non-nil, the
path also includes the current item."
  (let (item olpath)
    (save-excursion
      (outline-back-to-heading t)
      (when self
        (setq item (taskpaper-item-get-attribute "text"))
        (push item olpath))
      (while (taskpaper-outline-up-level-safe)
        (setq item (taskpaper-item-get-attribute "text"))
        (push item olpath)))
    olpath))

(defun taskpaper-format-olpath-entry (entry)
  "Format the outline path entry ENTRY for display."
  (setq entry (taskpaper-remove-trailing-tags
               (taskpaper-remove-type-formatting entry))
        entry (replace-regexp-in-string "/" "\\\\/" entry))
  entry)

(defun taskpaper-format-outline-path (olpath &optional separator)
  "Format the outline path OLPATH for display.
SEPARATOR can overwrite the default separator between the
different path entries."
  (setq olpath (delq nil olpath) separator (or separator "/"))
  (mapconcat #'taskpaper-format-olpath-entry olpath separator))

;;;; Goto interface

(defun taskpaper-goto-get-targets (&optional excluded-entries)
  "Produce a table with possible outline targets.
Return a list of cons cells (OLPATH . POS), where OLPATH is the
formatted outline path as string and POS is the corresponding
buffer position. EXCLUDED-ENTRIES is a list of OLPATH elements,
which will be excluded from the results."
  (let ((re (concat "^" outline-regexp)) target targets)
    (save-excursion
      (save-restriction
        (widen) (goto-char (point-min))
        (message "Get targets...")
        (while (re-search-forward re nil t)
          (setq target (taskpaper-format-outline-path
                        (taskpaper-item-get-outline-path t)))
          (unless (or (not target) (member target excluded-entries))
            (push (cons target (point-at-bol)) targets)))))
    (message "Get targets...done")
    (nreverse targets)))

(defun taskpaper-goto-get-location (&optional prompt no-exclude)
  "Prompt the user for a location, using PROMPT.
Return a cons cell (OLPATH . POS), where OLPATH is the formatted
outline path as string and POS is the corresponding buffer
position. When NO-EXCLUDE is set, do not exclude entries in the
current subtree."
  (let ((prompt (or prompt "Path: "))
        excluded-entries targets target)
    (when (and (outline-on-heading-p) (not no-exclude))
      ;; Exclude the subtree at point
      (taskpaper-outline-map-tree
       (lambda ()
         (setq excluded-entries
               (append excluded-entries
                       (list (taskpaper-format-outline-path
                              (taskpaper-item-get-outline-path t))))))))
    ;; Set possible targets
    (setq targets (taskpaper-goto-get-targets excluded-entries))
    (unless targets (user-error "No targets"))
    (let ((partial-completion-mode nil) (completion-ignore-case t))
      ;; Select outline path
      (setq target (completing-read prompt targets nil t))
      ;; Return the associated outline path and buffer position
      (assoc target targets))))

(defun taskpaper-goto ()
  "Prompt the user for a location and go to it."
  (interactive)
  (let* ((loc (taskpaper-goto-get-location "Goto: " t))
         (pos (cdr loc)))
    (taskpaper-mark-ring-push)
    (widen) (goto-char pos) (back-to-indentation)
    (taskpaper-outline-show-context)))

;;;; Copying, cutting, and pasting of trees

(defun taskpaper-copy-subtree (&optional cut)
  "Copy the current subtree into the kill ring.
If CUT is non-nil, actually cut the subtree."
  (interactive)
  (let (begin end)
    (save-excursion
      (save-match-data
        ;; Bound the current subtree
        (outline-back-to-heading) (setq begin (point))
        (taskpaper-outline-end-of-subtree)
        (if (eq (char-after) ?\n) (forward-char 1)
          ;; Add newline, if nessessary
          (unless (bolp) (end-of-line 1) (newline)))
        (setq end (point))
        ;; Cut or copy region into the kill ring
        (if cut
            (kill-region begin end)
          (copy-region-as-kill begin end))))))

(defun taskpaper-cut-subtree ()
  "Cut the current subtree and put it into the kill ring."
  (interactive)
  (taskpaper-copy-subtree 'cut))

(defun taskpaper-paste-subtree (&optional level text remove)
  "Paste the current kill as a subtree, with modification of level.
If point is on a (possibly invisible) item, paste as child of the
current item. You can force a different level by specifying LEVEL
or using a numeric prefix argument. If optional TEXT is given,
use this text instead of the current kill. Place point at the
beginning of pasted subtree. When REMOVE is non-nil, remove the
subtree from the kill ring."
  (interactive "P")
  (setq text (or text (and kill-ring (current-kill 0))))
  (unless text (user-error "Nothing to paste"))
  (unless (taskpaper-kill-is-subtree-p text)
    (user-error "The text is not a (set of) tree(s)"))
  (let* ((old-level (if (string-match "^\\([\t]*[^\t\f\n]\\)" text)
                        (- (match-end 1) (match-beginning 1))
                      1))
         (cur-level (if (outline-on-heading-p t)
                        (save-match-data (funcall outline-level))
                      0))
         (force-level (when level (prefix-numeric-value level)))
         (new-level (or force-level (1+ cur-level) 1))
         (shift (- new-level old-level))
         (delta (if (> shift 0) -1 1))
         (func (if (> shift 0)
                   'taskpaper-outline-demote
                 'taskpaper-outline-promote))
         begin end)
    ;; Paste the subtree and bound it
    (beginning-of-line 2)
    (unless (bolp) (end-of-line 1) (newline))
    (setq begin (point))
    (insert-before-markers text)
    ;; Add newline, if nessessary
    (unless (string-match-p "\n\\'" text) (newline))
    (setq end (point))
    ;; Adjust outline level
    (unless (= shift 0)
      (save-restriction
        (narrow-to-region begin end)
        (while (not (= shift 0))
          (taskpaper-outline-map-region func (point-min) (point-max))
          (setq shift (+ delta shift)))
        (goto-char (point-min))
        (setq end (point-max))))
    ;; Place point at the beginning of the subtree
    (goto-char begin)
    (when (called-interactively-p 'any)
      (message "Clipboard pasted as level %d subtree." new-level)))
  (when remove (setq kill-ring (cdr kill-ring))))

(defun taskpaper-clone-subtree ()
  "Duplicate the current subtree.
 Paste a copy of the current subtree as its next sibling."
  (interactive)
  (outline-back-to-heading)
  (let ((level (save-match-data (funcall outline-level))))
    (taskpaper-copy-subtree)
    (taskpaper-outline-end-of-subtree)
    (taskpaper-paste-subtree level nil t)))

;;;; Refiling

(defun taskpaper-refile-subtree (&optional arg rfloc)
  "Move the subtree at point to another (possibly invisible) location.
The subtree is filed below the target location as a subitem.
Depending on the value of `taskpaper-reverse-note-order', it will
be either the first or last subitem. If ARG is non-nil, just copy
the subtree. RFLOC can be a refile location in form (OLPATH . POS)
obtained in a different way."
  (interactive)
  (let* ((loc (or rfloc (taskpaper-goto-get-location nil arg)))
         (path (car loc)) (pos (cdr loc)) level)
    ;; Check the target position
    (when (and (not arg) pos
               (>= pos (point))
               (<  pos (save-excursion
                         (taskpaper-outline-end-of-subtree) (point))))
      (error "Cannot refile to item inside the current subtree"))
    ;; Copy the subtree
    (taskpaper-copy-subtree)
    ;; Move to the target position and paste the subtree
    (save-excursion
      (widen) (goto-char pos) (outline-back-to-heading t)
      (setq level (save-match-data (funcall outline-level)))
      (unless taskpaper-reverse-note-order
        (taskpaper-outline-end-of-subtree))
      (taskpaper-paste-subtree (1+ level)))
    ;; Cut the subtree from the original location
    (when (not arg) (taskpaper-cut-subtree))
    (when (called-interactively-p 'any)
      (message "Subtree refiled to %s." path))))

(defun taskpaper-refile-subtree-copy ()
  "Copy the subtree at point to another location.
Copying works like refiling, except that the subtree is not
deleted from the original location."
  (interactive)
  (taskpaper-refile-subtree t))

;;;; Archiving

(defun taskpaper-extract-archive-file (&optional location)
  "Extract and expand the file name from archive LOCATION.
Return file name for archive file. If LOCATION is not given, the
value of `taskpaper-archive-location' is used."
  (setq location (or location taskpaper-archive-location))
  (when (string-match "\\(.*\\)::\\(.*\\)" location)
    (if (= (match-beginning 1) (match-end 1))
        (buffer-file-name (buffer-base-buffer))
      (expand-file-name
       (format (match-string-no-properties 1 location)
               (file-name-sans-extension
                (file-name-nondirectory
                 (buffer-file-name (buffer-base-buffer)))))))))

(defun taskpaper-extract-archive-heading (&optional location)
  "Extract the heading from archive LOCATION.
If LOCATION is not given, the value of
`taskpaper-archive-location' is used."
  (setq location (or location taskpaper-archive-location))
  (when (string-match "\\(.*\\)::\\(.*\\)" location)
    (format (match-string-no-properties 2 location)
            (file-name-sans-extension
             (file-name-nondirectory
              (buffer-file-name (buffer-base-buffer)))))))

(defun taskpaper-archive-get-project ()
  "Get project hierarchy for the current item.
Return formatted project hierarchy as string or nil, if there are
no parent projects."
  (let (project projects)
    (save-excursion
      (save-restriction
        (widen) (outline-back-to-heading t)
        (while (taskpaper-outline-up-level-safe)
          (when (equal (taskpaper-item-get-attribute "type") "project")
            (setq project (taskpaper-item-get-attribute "text"))
            (push project projects)))))
    (if projects (taskpaper-format-outline-path projects) nil)))

(defun taskpaper-archive-subtree ()
  "Move the current subtree to the archive location.
The archive can be a certain top-level heading in the current
file, or in a different file. For details see the variable
`taskpaper-archive-location'. The subtree is filed below the
archive heading as a subitem. Depending on the value of
`taskpaper-reverse-note-order', it will be either the first or
last subitem."
  (interactive)
  (let ((this-buffer (current-buffer))
        (file (abbreviate-file-name
               (or (buffer-file-name (buffer-base-buffer))
                   (error "No file associated to buffer"))))
        afile heading buffer project level)
    ;; Extract archive heading and file name
    (setq afile (taskpaper-extract-archive-file
                 taskpaper-archive-location)
          heading (taskpaper-extract-archive-heading
                   taskpaper-archive-location))
    (unless afile (error "Invalid `taskpaper-archive-location'"))
    ;; When an archive file is specified, visit it
    ;; and set this buffer as archive buffer;
    ;; otherwise fall back to the current buffer
    (if (> (length afile) 0)
        (setq buffer (or (find-buffer-visiting afile)
                         (find-file-noselect afile)))
      (setq buffer (current-buffer)))
    (unless buffer (error "Cannot access file: %s" afile))
    ;; Archive subtree
    (save-excursion
      ;; Get context information
      (setq project (taskpaper-archive-get-project))
      ;; Copy subtree
      (taskpaper-copy-subtree)
      ;; Go to the archive buffer
      (set-buffer buffer)
      ;; Enforce TaskPaper mode for the archive buffer
      (when (not (derived-mode-p 'taskpaper-mode))
        (call-interactively #'taskpaper-mode))
      ;; Show everything
      (widen) (goto-char (point-min)) (taskpaper-outline-show-all)
      ;; Go to the archive location and paste the subtree
      (cond
       ((and (stringp heading) (> (length heading) 0))
        ;; Archive heading specified
        (if (re-search-forward
             (format "^%s" (regexp-quote heading)) nil t)
            ;; Archive heading found
            (goto-char (match-end 0))
          ;; No archive heading found, insert it at EOB
          (goto-char (point-max)) (delete-blank-lines)
          (unless (bolp) (end-of-line 1) (newline))
          (insert heading "\n"))
        ;; File the subtree under the archive heading
        (outline-back-to-heading)
        (setq level (save-match-data (funcall outline-level)))
        (unless taskpaper-reverse-note-order
          (taskpaper-outline-end-of-subtree))
        (taskpaper-paste-subtree (1+ level)))
       (t
        ;; No archive heading specified, go to EOB
        (goto-char (point-max)) (delete-blank-lines)
        (unless (bolp) (end-of-line 1) (newline))
        ;; Paste the subtree at EOB
        (taskpaper-paste-subtree)))
      ;; Add the context information
      (and taskpaper-archive-save-context project
           (taskpaper-item-set-attribute "project" project))
      ;; Save the buffer, if it is not the current buffer
      (when (not (eq this-buffer buffer)) (save-buffer)))
    ;; Run hooks
    (run-hooks 'taskpaper-archive-hook)
    ;; Bind `this-command' to avoid `kill-region' changes it,
    ;; which may lead to duplication of subtrees
    ;; NOTE: Do not bind `this-command' with `let' because
    ;; that would restore the old value in case of error
    (let (old-this-command this-command)
      (setq this-command t)
      ;; Cut the subtree from the original location
      (taskpaper-cut-subtree)
      (setq this-command old-this-command)))
  (when (called-interactively-p 'any) (message "Subtree archived.")))

;;;; Quick entry API

;;;###autoload
(defun taskpaper-add-entry (&optional text location file)
  "Add entry TEXT to LOCATION in FILE.
Prompt the user for entry TEXT and add it as child of the
top-level LOCATION item. The entry is filed below the target
location as a subitem. Depending on the value of
`taskpaper-reverse-note-order', it will be either the first or
last subitem. When the location is omitted, the item is simply
filed at the end of the file, as top-level item. When FILE is
specified, visit it and set this buffer as target buffer,
otherwise fall back to the current buffer."
  (interactive)
  (let ((text (or text (read-string "Entry: ")))
        (this-buffer (current-buffer)) buffer level)
    ;; Check the entry text
    (unless (taskpaper-kill-is-subtree-p text)
      (user-error "The text is not a (set of) tree(s)"))
    ;; Select buffer
    (if (and (stringp file) (> (length file) 0))
        (setq buffer (or (find-buffer-visiting file)
                         (find-file-noselect file)))
      (setq buffer (current-buffer)))
    (unless buffer (error "Cannot access file: %s" file))
    ;; Go to the target buffer
    (with-current-buffer buffer
      ;; Enforce TaskPaper mode
      (when (not (derived-mode-p 'taskpaper-mode)) (taskpaper-mode))
      ;; Show everything
      (widen) (goto-char (point-min)) (taskpaper-outline-show-all)
      ;; Go to the target location and paste the entry
      (cond
       ((and (stringp location) (> (length location) 0))
        ;; Target location specified
        (if (re-search-forward
             (format "^%s" (regexp-quote location)) nil t)
            ;; Location found
            (goto-char (match-end 0))
          ;; No location found, insert it at EOB
          (goto-char (point-max)) (delete-blank-lines)
          (unless (bolp) (end-of-line 1) (newline))
          (insert location "\n"))
        ;; File the entry under the target location
        (outline-back-to-heading)
        (setq level (save-match-data (funcall outline-level)))
        (unless taskpaper-reverse-note-order
          (taskpaper-outline-end-of-subtree))
        (taskpaper-paste-subtree (1+ level) text))
       (t
        ;; No location specified, go to EOB
        (goto-char (point-max)) (delete-blank-lines)
        (unless (bolp) (end-of-line 1) (newline))
        ;; Paste the entry at EOB
        (taskpaper-paste-subtree nil text)))
      ;; Save the buffer, if it is not the current buffer
      (when (not (eq this-buffer buffer)) (save-buffer))))
  (when (called-interactively-p 'any) (message "Entry added.")))

;;;; Filtering

(defvar taskpaper-occur-highlights nil
  "List of overlays used for occur matches.")
(make-variable-buffer-local 'taskpaper-occur-highlights)

(defun taskpaper-occur-add-highlights (begin end)
  "Highlight from BEGIN to END."
  (let ((overlay (make-overlay begin end)))
    (overlay-put overlay 'face 'secondary-selection)
    (overlay-put overlay 'taskpaper-type 'taskpaper-occur)
    (push overlay taskpaper-occur-highlights)))

(defun taskpaper-occur-remove-highlights (&optional _begin _end)
  "Remove the occur highlights from the buffer."
  (interactive)
  (mapc 'delete-overlay taskpaper-occur-highlights)
  (setq taskpaper-occur-highlights nil))

(defun taskpaper-occur (&optional regexp)
  "Make a sparse tree view showing items matching REGEXP.
Return the number of matches."
  (interactive)
  (setq regexp (or regexp (read-regexp "Regexp: ")))
  (when (equal regexp "") (user-error "Regexp must not be empty"))
  (taskpaper-occur-remove-highlights)
  (outline-flag-region (point-min) (point-max) t)
  (goto-char (point-min))
  (let ((cnt 0))
    (while (re-search-forward regexp nil t)
      (setq cnt (1+ cnt))
      (taskpaper-occur-add-highlights
       (match-beginning 0) (match-end 0))
      (taskpaper-outline-show-context))
    (add-hook 'before-change-functions
              'taskpaper-occur-remove-highlights
              nil 'local)
    (when (called-interactively-p 'any)
      (message "%d %s" cnt (if (= cnt 1) "match" "matches")))
    cnt))

(defun taskpaper-occur-next-match (&optional n _reset)
  "Function for `next-error-function' to find highlight matches.
N is the number of matches to move, when negative move backwards.
This function always goes back to the starting point when no
match is found."
  (let* ((limit (if (< n 0) (point-min) (point-max)))
         (search-func (if (< n 0)
                          'previous-single-char-property-change
                        'next-single-char-property-change))
         (n (abs n)) (pos (point)) p1)
    (catch 'exit
      (while (setq p1 (funcall search-func (point) 'taskpaper-type))
        (when (equal p1 limit)
          (goto-char pos) (user-error "No more matches"))
        (when (equal (get-char-property p1 'taskpaper-type) 'taskpaper-occur)
          (setq n (1- n))
          (when (= n 0)
            (goto-char p1) (throw 'exit (point))))
        (goto-char p1))
      (goto-char p1) (user-error "No more matches"))))

;;;; Querying

(defconst taskpaper-query-whitespace-regexp
  "\\`[ \t\n\r]*"
  "Regular expression matching whitespace.")

(defconst taskpaper-query-attribute-regexp
  (format "\\(@%s+\\)" taskpaper-tag-name-char-regexp)
  "Regular expression matching attribute.")

(defconst taskpaper-query-operator-regexp
  "\\([<>~!]=\\|[<>=]\\)"
  "Regular expression matching non-word relational operator.")

(defconst taskpaper-query-modifier-regexp
  "\\(\\[\\(?:[isnd]l?\\|l\\)\\]\\)"
  "Regular expression matching relational modifier.")

(defconst taskpaper-query-quoted-string-regexp
  "\\(\"\\(?:\\\\\"\\|[^\"]\\)*\"\\)"
  "Regular expression matching double-quoted string.")

(defconst taskpaper-query-word-regexp
  "\\([^][@<>=~!()\" \t\n\r]+\\)"
  "Regular expression matching word.")

(defconst taskpaper-query-word-operator
  '("and" "or" "not"
    "contains" "beginswith" "endswith" "matches")
  "List of valid query word operators.")

(defconst taskpaper-query-non-word-operator
  '("=" "<" ">" "<=" ">=" "!=" "~=")
  "List of valid query non-word operators.")

(defconst taskpaper-query-word-shortcut
  '("project" "task" "note")
  "List of valid query type shortcuts.")

(defconst taskpaper-query-relation-operator
  '("=" "<" ">" "<=" ">=" "!=" "~="
    "contains" "beginswith" "endswith" "matches")
  "List of valid query relational operators.")

(defconst taskpaper-query-relation-modifier
  '("[i]" "[s]" "[n]" "[d]" "[l]" "[il]" "[sl]" "[nl]" "[dl]")
  "List of valid query relation modifiers.")

(defconst taskpaper-query-boolean-not
  '("not")
  "List of valid Boolean NOT operators.")

(defconst taskpaper-query-boolean-binary
  '("and" "or")
  "List of valid Boolean binary operators.")

(defconst taskpaper-query-lparen-regexp
  "\\((\\)"
  "Regular expression matching opening parenthesis.")

(defconst taskpaper-query-rparen-regexp
  "\\()\\)"
  "Regular expression matching closing parenthesis.")

(defconst taskpaper-query-lparen-rparen
  '("(" ")")
  "List of opening and closing parentheses.")

(defun taskpaper-query-attribute-p (token)
  "Return non-nil if TOKEN is a valid attribute."
  (let ((re (format "\\`%s\\'" taskpaper-query-attribute-regexp)))
    (and (stringp token) (string-match-p re token))))

(defun taskpaper-query-relation-operator-p (token)
  "Return non-nil if TOKEN is a valid relational operator."
  (and (stringp token) (member token taskpaper-query-relation-operator)))

(defun taskpaper-query-relation-modifier-p (token)
  "Return non-nil if TOKEN is a valid relational modifier."
  (and (stringp token) (member token taskpaper-query-relation-modifier)))

(defun taskpaper-query-word-operator-p (token)
  "Return non-nil if TOKEN is a valid word operator."
  (and (stringp token) (member token taskpaper-query-word-operator)))

(defun taskpaper-query-boolean-not-p (token)
  "Return non-nil if TOKEN is a valid Boolean NOT operator."
  (and (stringp token) (member token taskpaper-query-boolean-not)))

(defun taskpaper-query-boolean-binary-p (token)
  "Return non-nil if TOKEN is a valid Boolean binary operator."
  (and (stringp token) (member token taskpaper-query-boolean-binary)))

(defun taskpaper-query-lparen-p (token)
  "Return non-nil if TOKEN is the opening parenthesis."
  (and (stringp token) (equal token "(")))

(defun taskpaper-query-rparen-p (token)
  "Return non-nil if TOKEN is the closing parenthesis."
  (and (stringp token) (equal token ")")))

(defun taskpaper-query-type-shortcut-p (token)
  "Return non-nil if TOKEN is a valid type shortcut."
  (and (stringp token) (member token taskpaper-query-word-shortcut)))

(defun taskpaper-query-search-term-p (token)
  "Return non-nil if TOKEN is a valid search term."
  (and (stringp token)
       (not (taskpaper-query-attribute-p token))
       (not (taskpaper-query-word-operator-p token))
       (not (taskpaper-query-relation-operator-p token))
       (not (taskpaper-query-relation-modifier-p token))
       (not (taskpaper-query-lparen-p token))
       (not (taskpaper-query-rparen-p token))))

(defun taskpaper-query-read-tokenize (str)
  "Read query string STR into tokens.
Return list of substrings. Each substring is a run of valid
characters repsesenting different types ot tokens."
  (let ((depth 0) tokens val st)
    (while (> (length str) 0)
      ;; Trim leading whitespaces
      (when (string-match taskpaper-query-whitespace-regexp str)
        (setq str (replace-match "" nil nil str)))
      (unless (= (length str) 0)
        (cond
         ((eq (string-to-char str) ?@)
          ;; Read attribute
          (if (string-match
               (concat "\\`" taskpaper-query-attribute-regexp) str)
              (progn
                (setq val (match-string-no-properties 1 str))
                (setq str (replace-match "" nil nil str))
                (when st (push st tokens) (setq st nil))
                (push val tokens))
            (error "Error while reading attribute")))
         ((member (string-to-char str) '(?< ?> ?= ?! ?~))
          ;; Read non-word relational operator
          (if (string-match
               (concat "\\`" taskpaper-query-operator-regexp) str)
              (progn
                (setq val (match-string-no-properties 1 str))
                (setq str (replace-match "" nil nil str))
                (when st (push st tokens) (setq st nil))
                (push val tokens))
            (error "Error while reading relational operator")))
         ((eq (string-to-char str) ?\[)
          ;; Read relational modifier
          (if (string-match
               (concat "\\`" taskpaper-query-modifier-regexp) str)
              (progn
                (setq val (match-string-no-properties 1 str))
                (setq str (replace-match "" nil nil str))
                (when st (push st tokens) (setq st nil))
                (push val tokens))
            (error "Error while reading relational modifier")))
         ((eq (string-to-char str) ?\()
          ;; Read opening parenthesis
          (if (string-match
               (concat "\\`" taskpaper-query-lparen-regexp) str)
              (progn
                (setq val (match-string-no-properties 1 str))
                (setq str (replace-match "" nil nil str))
                (when st (push st tokens) (setq st nil))
                (setq depth (1+ depth))
                (push val tokens))
            (error "Error while reading opening parenthesis")))
         ((eq (string-to-char str) ?\))
          ;; Read closing parenthesis
          (if (string-match
               (concat "\\`" taskpaper-query-rparen-regexp) str)
              (progn
                (setq val (match-string-no-properties 1 str))
                (setq str (replace-match "" nil nil str))
                (when st (push st tokens) (setq st nil))
                (if (= depth 0)
                    (error "Unbalanced closing parenthesis")
                  (setq depth (1- depth)))
                (push val tokens))
            (error "Error while reading closing parenthesis")))
         ((eq (string-to-char str) ?\")
          ;; Read quoted string
          (if (string-match
               (concat "\\`" taskpaper-query-quoted-string-regexp) str)
              (progn
                (setq val (match-string-no-properties 1 str))
                (setq str (replace-match "" nil nil str))
                (when st (push st tokens) (setq st nil))
                (push val tokens))
            (error "Error while reading quoted string")))
         (t
          ;; Read word
          (if (string-match
               (concat "\\`" taskpaper-query-word-regexp) str)
              (progn
                (setq val (match-string-no-properties 1 str))
                (setq str (replace-match "" nil nil str))
                (cond ((or (taskpaper-query-word-operator-p val)
                           (taskpaper-query-type-shortcut-p val))
                       (when st (push st tokens) (setq st nil))
                       (push val tokens))
                      (t
                       (setq st (if st (concat st " " val) val)))))
            (error "Error while reading word"))))))
    (when st (push st tokens))
    (when (> depth 0) (error "Unbalanced opening parenthesis"))
    (nreverse tokens)))

(defun taskpaper-query-expand-type-shortcuts (tokens)
  "Expand type shortcuts in TOKENS."
  (let (token prev next expanded)
    (while tokens
      (setq token (pop tokens) next (nth 0 tokens))
      (cond ((and (taskpaper-query-type-shortcut-p token)
                  (not (taskpaper-query-relation-operator-p prev))
                  (not (taskpaper-query-relation-modifier-p prev)))
             (setq prev nil)
             (push "@type" expanded) (push "=" expanded)
             (push token expanded)
             (and next (not (taskpaper-query-boolean-binary-p next))
                  (push "and" expanded)))
            (t
             (setq prev token)
             (push token expanded))))
    (nreverse expanded)))

(defun taskpaper-query-relop-to-func (op &optional mod)
  "Convert relational operator OP and modifier MOD into function."
  (cond ((equal op "=")
         (cond ((equal "i"  mod) 'taskpaper-istring=)
               ((equal "s"  mod) 'taskpaper-string=)
               ((equal "n"  mod) 'taskpaper-num=)
               ((equal "d"  mod) 'taskpaper-time=)
               ((equal "l"  mod) 'taskpaper-cslist-istring=)
               ((equal "il" mod) 'taskpaper-cslist-istring=)
               ((equal "sl" mod) 'taskpaper-cslist-string=)
               ((equal "nl" mod) 'taskpaper-cslist-num=)
               ((equal "dl" mod) 'taskpaper-cslist-time=)
               (t                'taskpaper-istring=)))
        ((equal op "<")
         (cond ((equal "i"  mod) 'taskpaper-istring<)
               ((equal "s"  mod) 'taskpaper-string<)
               ((equal "n"  mod) 'taskpaper-num<)
               ((equal "d"  mod) 'taskpaper-time<)
               ((equal "l"  mod) 'taskpaper-cslist-istring<)
               ((equal "il" mod) 'taskpaper-cslist-istring<)
               ((equal "sl" mod) 'taskpaper-cslist-string<)
               ((equal "nl" mod) 'taskpaper-cslist-num<)
               ((equal "dl" mod) 'taskpaper-cslist-time<)
               (t                'taskpaper-istring<)))
        ((equal op "<=")
         (cond ((equal "i"  mod) 'taskpaper-istring<=)
               ((equal "s"  mod) 'taskpaper-string<=)
               ((equal "n"  mod) 'taskpaper-num<=)
               ((equal "d"  mod) 'taskpaper-time<=)
               ((equal "l"  mod) 'taskpaper-cslist-istring<=)
               ((equal "il" mod) 'taskpaper-cslist-istring<=)
               ((equal "sl" mod) 'taskpaper-cslist-string<=)
               ((equal "nl" mod) 'taskpaper-cslist-num<=)
               ((equal "dl" mod) 'taskpaper-cslist-time<=)
               (t                'taskpaper-istring<=)))
        ((equal op ">")
         (cond ((equal "i"  mod) 'taskpaper-istring>)
               ((equal "s"  mod) 'taskpaper-string>)
               ((equal "n"  mod) 'taskpaper-num>)
               ((equal "d"  mod) 'taskpaper-time>)
               ((equal "l"  mod) 'taskpaper-cslist-istring>)
               ((equal "il" mod) 'taskpaper-cslist-istring>)
               ((equal "sl" mod) 'taskpaper-cslist-string>)
               ((equal "nl" mod) 'taskpaper-cslist-num>)
               ((equal "dl" mod) 'taskpaper-cslist-time>)
               (t                'taskpaper-istring>)))
        ((equal op ">=")
         (cond ((equal "i"  mod) 'taskpaper-istring>=)
               ((equal "s"  mod) 'taskpaper-string>=)
               ((equal "n"  mod) 'taskpaper-num>=)
               ((equal "d"  mod) 'taskpaper-time>=)
               ((equal "l"  mod) 'taskpaper-cslist-istring>=)
               ((equal "il" mod) 'taskpaper-cslist-istring>=)
               ((equal "sl" mod) 'taskpaper-cslist-string>=)
               ((equal "nl" mod) 'taskpaper-cslist-num>=)
               ((equal "dl" mod) 'taskpaper-cslist-time>=)
               (t                'taskpaper-istring>=)))
        ((equal op "!=")
         (cond ((equal "i"  mod) 'taskpaper-istring<>)
               ((equal "s"  mod) 'taskpaper-string<>)
               ((equal "n"  mod) 'taskpaper-num<>)
               ((equal "d"  mod) 'taskpaper-time<>)
               ((equal "l"  mod) 'taskpaper-cslist-istring<>)
               ((equal "il" mod) 'taskpaper-cslist-istring<>)
               ((equal "sl" mod) 'taskpaper-cslist-string<>)
               ((equal "nl" mod) 'taskpaper-cslist-num<>)
               ((equal "dl" mod) 'taskpaper-cslist-time<>)
               (t                'taskpaper-istring<>)))
        ((equal op "contains")
         (cond ((equal "i"  mod) 'taskpaper-istring-contain-p)
               ((equal "s"  mod) 'taskpaper-string-contain-p)
               ((equal "l"  mod) 'taskpaper-cslist-istring-contain-p)
               ((equal "il" mod) 'taskpaper-cslist-istring-contain-p)
               ((equal "sl" mod) 'taskpaper-cslist-string-contain-p)
               ((equal "nl" mod) 'taskpaper-cslist-num-contain-p)
               ((equal "dl" mod) 'taskpaper-cslist-time-contain-p)
               (t                'taskpaper-istring-contain-p)))
        ((equal op "beginswith")
         (cond ((equal "i"  mod) 'taskpaper-istring-prefix-p)
               ((equal "s"  mod) 'taskpaper-string-prefix-p)
               ((equal "l"  mod) 'taskpaper-cslist-istring-head-p)
               ((equal "il" mod) 'taskpaper-cslist-istring-head-p)
               ((equal "sl" mod) 'taskpaper-cslist-string-head-p)
               ((equal "nl" mod) 'taskpaper-cslist-num-head-p)
               ((equal "dl" mod) 'taskpaper-cslist-time-head-p)
               (t                'taskpaper-istring-prefix-p)))
        ((equal op "endswith")
         (cond ((equal "i"  mod) 'taskpaper-istring-suffix-p)
               ((equal "s"  mod) 'taskpaper-string-suffix-p)
               ((equal "l"  mod) 'taskpaper-cslist-istring-tail-p)
               ((equal "il" mod) 'taskpaper-cslist-istring-tail-p)
               ((equal "sl" mod) 'taskpaper-cslist-string-tail-p)
               ((equal "nl" mod) 'taskpaper-cslist-num-tail-p)
               ((equal "dl" mod) 'taskpaper-cslist-time-tail-p)
               (t                'taskpaper-istring-suffix-p)))
        ((member op '("matches" "~="))
         (cond ((equal "i"  mod) 'taskpaper-istring-match-p)
               ((equal "s"  mod) 'taskpaper-string-match-p)
               ((equal "l"  mod) 'taskpaper-cslist-istring-match-p)
               ((equal "il" mod) 'taskpaper-cslist-istring-match-p)
               ((equal "sl" mod) 'taskpaper-cslist-string-match-p)
               ((equal "nl" mod) 'taskpaper-cslist-num-match-p)
               ((equal "dl" mod) 'taskpaper-cslist-time-match-p)
               (t                'taskpaper-istring-match-p)))
        (t (error "Invalid relational operator: %s" op))))

(defun taskpaper-query-bool-to-func (bool)
  "Convert Boolean operator to function."
  (cond ((equal bool  "or") 'or)
        ((equal bool "and") 'and)
        ((equal bool "not") 'not)
        (t (error "Invalid Boolean operator: %s" bool))))

(defconst taskpaper-query-precedence-boolean
  '(("and" . 0) ("or" . 1))
  "Order of precedence for binary Boolean operators.
Operators with lower precedence bind more strongly.")

(defun taskpaper-query-parse-predicate (tokens)
  "Parse next predicate expression in token list TOKENS.
Return a cons of the constructed Lisp form implementing the
matcher and the rest of the token list."
  (let (attr op mod val form)
    ;; Get predicate arguments
    (when (taskpaper-query-attribute-p (nth 0 tokens))
      (setq attr (substring (nth 0 tokens) 1)) (pop tokens))
    (when (taskpaper-query-relation-operator-p (nth 0 tokens))
      (setq op (nth 0 tokens)) (pop tokens))
    (when (taskpaper-query-relation-modifier-p (nth 0 tokens))
      (setq mod (substring (nth 0 tokens) 1 -1)) (pop tokens))
    (when (taskpaper-query-search-term-p (nth 0 tokens))
      (setq val (if (eq (string-to-char (nth 0 tokens)) ?\")
                    (substring (nth 0 tokens) 1 -1)
                  (nth 0 tokens)))
      (pop tokens))
    ;; Provide default values
    (setq attr (or attr "text") op (or op "contains") mod (or mod "i"))
    ;; Convert operator to function
    (setq op (taskpaper-query-relop-to-func op mod))
    ;; Unescape double quotes in search term
    (when val (setq val (taskpaper-unescape-double-quotes val)))
    ;; Convert time string to time to speed up matching
    (when (and val (equal "d" mod) (setq val (taskpaper-2ft val))))
    ;; Build Lisp form
    (cond
     ((not val)
      (setq form `(taskpaper-item-has-attribute ,attr t)))
     (t
      (setq form `(,op (taskpaper-item-get-attribute ,attr t) ,val))))
    ;; Return Lisp form and list of remaining tokens
    (cons form tokens)))

(defun taskpaper-query-parse-boolean-unary (tokens)
  "Parse next unary Boolean expression in token list TOKENS.
Return a cons of the constructed Lisp form implementing the
matcher and the rest of the token list."
  (let (tmp bool right form)
    ;; Get operator
    (when (taskpaper-query-boolean-not-p (nth 0 tokens))
      (setq bool (nth 0 tokens)) (pop tokens))
    ;; Get right side
    (when tokens
      (cond
       ((taskpaper-query-lparen-p (nth 0 tokens))
        (setq tmp (taskpaper-query-parse-parentheses tokens)))
       (t
        (setq tmp (taskpaper-query-parse-predicate tokens))))
      (setq right (car tmp) tokens (cdr tmp)))
    ;; Convert operator to function
    (when bool (setq bool (taskpaper-query-bool-to-func bool)))
    ;; Build Lisp form
    (cond
     ((and bool right) (setq form `(,bool ,right)))
     (right (setq form right))
     (t (error "Invalid Boolean unary expression")))
    ;; Return Lisp form and list of remaining tokens
    (cons form tokens)))

(defun taskpaper-query-parse-boolean-binary (tokens prec &optional left)
  "Parse next binary Boolean expression in token list TOKENS.
Return a cons of the constructed Lisp form implementing the
matcher and the rest of the token list. PREC is the current
precedence for Boolean operators. LEFT is a Lisp form
representing the left side of the Boolean expression. This
function implements the top-down recursive parsing algorithm
known as Pratt's algorithm."
  (let (tmp bool cprec right form)
    ;; Get left side
    (when (and tokens (not left))
      (cond
       ((taskpaper-query-lparen-p (nth 0 tokens))
        (setq tmp (taskpaper-query-parse-parentheses tokens)))
       (t
        (setq tmp (taskpaper-query-parse-boolean-unary tokens))))
      (setq left (car tmp) tokens (cdr tmp)))
    ;; Get operator
    (when (taskpaper-query-boolean-binary-p (nth 0 tokens))
      (setq bool (nth 0 tokens)) (pop tokens))
    ;; Get right side
    (when (and tokens bool left)
      (cond
       ((taskpaper-query-lparen-p (nth 0 tokens))
        (setq tmp (taskpaper-query-parse-parentheses tokens)))
       (t
        (setq cprec (cdr (assoc bool taskpaper-query-precedence-boolean)))
        (setq tmp (if (> cprec prec)
                      (taskpaper-query-parse-boolean-binary tokens cprec)
                    (taskpaper-query-parse-boolean-unary tokens)))))
      (setq right (car tmp) tokens (cdr tmp)))
    ;; Convert operator to function
    (when bool (setq bool (taskpaper-query-bool-to-func bool)))
    ;; Build Lisp form
    (cond
     ((and left bool right) (setq form `(,bool ,left ,right)))
     ((and left (not bool)) (setq form left))
     (t (error "Invalid Boolean binary expression")))
    ;; Return Lisp form and list of remaining tokens
    (cons form tokens)))

(defun taskpaper-query-parse-parentheses (tokens)
  "Parse next parenthetical expression in token list TOKENS.
Return a cons of the constructed Lisp form implementing the
matcher and the rest of the token list."
  (let (tmp left)
    (if (taskpaper-query-lparen-p (nth 0 tokens))
        (pop tokens)
      (error "Opening parenthesis expected"))
    (while (and tokens (not (taskpaper-query-rparen-p (nth 0 tokens))))
      ;; Parse Boolean binary expression
      (setq tmp (taskpaper-query-parse-boolean-binary tokens 0 left)
            left (car tmp) tokens (cdr tmp))
      (when (and (not (taskpaper-query-rparen-p (nth 0 tokens)))
                 (not (taskpaper-query-boolean-binary-p (nth 0 tokens))))
        (error "Boolean binary operator or closing parenthesis expected")))
    (if (taskpaper-query-rparen-p (nth 0 tokens))
        (pop tokens)
      (error "Closing parenthesis expected"))
    ;; Return Lisp form and list of remaining tokens
    (cons left tokens)))

(defun taskpaper-query-parse (tokens)
  "Parse token list TOKENS.
Return constructed Lisp form implementing the matcher."
  (let (tmp left)
    (while tokens
      (setq tmp (taskpaper-query-parse-boolean-binary tokens 0 left)
            left (car tmp) tokens (cdr tmp))
      (when (and tokens
                 (not (taskpaper-query-boolean-binary-p (nth 0 tokens))))
        (error "Boolean binary operator expected")))
    ;; Return Lisp form
    left))

(defun taskpaper-query-matcher (query)
  "Parse query string QUERY.
Return constructed Lisp form implementing the matcher. The
matcher is to be evaluated at an outline item and returns non-nil
if the item matches the query string."
  (let (tokens)
    ;; Tokenize query string and expand shortcuts
    (setq tokens (taskpaper-query-read-tokenize query))
    (setq tokens (taskpaper-query-expand-type-shortcuts tokens))
    ;; Parse token list and construct matcher
    (if tokens (taskpaper-query-parse tokens) nil)))

(defun taskpaper-query-item-match-p (query)
  "Return non-nil if the current item matches query string QUERY."
  (eval (taskpaper-query-matcher query)))

(defun taskpaper-query-fontify-query ()
  "Fontify query string in the minibuffer."
  (save-excursion
    (let ((case-fold-search nil))
      ;; Fontify word operators
      (goto-char (point-min))
      (while (re-search-forward
              (regexp-opt taskpaper-query-word-operator 'words) nil t)
        (put-text-property (match-beginning 0) (match-end 0)
                           'face 'taskpaper-query-secondary-text))
      ;; Fontify non-word operators, modifiers, and parentheses
      (goto-char (point-min))
      (while (re-search-forward
              (regexp-opt (append taskpaper-query-non-word-operator
                                  taskpaper-query-relation-modifier
                                  taskpaper-query-lparen-rparen))
              nil t)
        (put-text-property (match-beginning 0) (match-end 0)
                           'face 'taskpaper-query-secondary-text))
      ;; Fontify attributes
      (goto-char (point-min))
      (while (re-search-forward
              (format "@%s" taskpaper-tag-name-regexp)
              nil t)
        (put-text-property (match-beginning 0) (match-end 0)
                           'face 'default))
      ;; Finally fontify double-quoted strings
      (goto-char (point-min))
      (while (re-search-forward
              taskpaper-query-quoted-string-regexp nil t)
        (put-text-property (match-beginning 1) (match-end 1)
                           'face 'default)))))

(defun taskpaper-read-query-propertize (&optional _begin _end _length)
  "Propertize query string live in the minibuffer.
Incrementally read query string, validate it and propertize
accordingly. The function should be called from the minibuffer as
part of `after-change-functions' hook."
  (when (minibufferp (current-buffer))
    (condition-case nil
        (progn
          (remove-text-properties
           (point-at-bol) (point-max) (list 'face))
          (taskpaper-query-fontify-query)
          (taskpaper-query-matcher (minibuffer-contents-no-properties)))
      (error
       (put-text-property (point-at-bol) (point-max)
                          'face 'taskpaper-query-error)))))

(defun taskpaper-match-sparse-tree (matcher)
  "Create a sparse tree view according to MATCHER.
MATCHER is a Lisp form to be evaluated at an outline item and
returns non-nil if the item matches."
  (taskpaper-occur-remove-highlights)
  (outline-flag-region (point-min) (point-max) t)
  (let ((re (concat "^" outline-regexp)))
    (goto-char (point-min))
    (save-excursion
      (while (let (case-fold-search)
               (re-search-forward re nil t))
        (when (let ((case-fold-search t))
                (save-excursion (eval matcher)))
          (taskpaper-outline-show-context))))))

(defun taskpaper-query-read-query (&optional prompt)
  "Prompt the user for a search query.
Validate input and provide tab completion for attributes in the
minibuffer. Return query string. PROMPT can overwrite the default
prompt."
  (let ((attrs (taskpaper-add-tag-prefix
                (append (taskpaper-get-buffer-tags)
                        taskpaper-special-attributes)))
        (map (make-sparse-keymap))
        (prompt (or prompt "Query: ")) str)
    (set-keymap-parent map minibuffer-local-map)
    (define-key map (kbd "TAB")
      (lambda () (interactive) (taskpaper-complete-tag-at-point attrs)))
    (define-key map (kbd "C-c C-c")
      (lambda () (interactive) (delete-minibuffer-contents)))
    (define-key map (kbd "ESC ESC")
      (lambda () (interactive) (abort-recursive-edit)))
    (let ((minibuffer-local-map (copy-keymap map))
          (minibuffer-message-timeout 0.5))
      (unwind-protect
          (progn
            ;; Add hooks
            (add-hook 'after-change-functions
                      'taskpaper-read-query-propertize)
            ;; Read query string
            (setq str (read-string prompt nil taskpaper-query-history nil t)))
        ;; Remove hooks
        (remove-hook 'after-change-functions
                     'taskpaper-read-query-propertize))
      str)))

(defun taskpaper-query (&optional query)
  "Create a sparse tree view according to query string QUERY."
  (interactive)
  (setq query (or query (taskpaper-query-read-query)))
  (message "Querying...")
  (let ((matcher (taskpaper-query-matcher query)))
    (if matcher
        (taskpaper-match-sparse-tree matcher)
      (taskpaper-outline-show-all)))
  (message "Querying...done"))

(defun taskpaper-iquery-query ()
  "Evaluate query in the main window."
  (when (and (minibufferp (current-buffer))
             (minibuffer-selected-window))
    (let* ((str (minibuffer-contents-no-properties))
           (matcher (ignore-errors (taskpaper-query-matcher str))))
      (with-selected-window (minibuffer-selected-window)
        (if matcher
            (condition-case nil
                (taskpaper-match-sparse-tree matcher) (error nil))
          (taskpaper-outline-show-all))))))

(defvar taskpaper-iquery-idle-timer nil
  "The idle timer object for I-query mode.")

(defun taskpaper-iquery (&optional query prompt)
  "Create a sparse tree view according to query string.
Query results are updated incrementally as you type, showing
items, that matches. If non-nil, QUERY is an initial query
string. PROMPT can overwrite the default prompt."
  (interactive)
  (let ((map (make-sparse-keymap))
        (prompt (or prompt "I-query: "))
        (attrs (taskpaper-add-tag-prefix
                (append (taskpaper-get-buffer-tags)
                        taskpaper-special-attributes)))
        (win (get-buffer-window (current-buffer))) str)
    (set-keymap-parent map minibuffer-local-map)
    (define-key map (kbd "TAB")
      (lambda () (interactive) (taskpaper-complete-tag-at-point attrs)))
    (define-key map (kbd "C-c C-c")
      (lambda () (interactive) (delete-minibuffer-contents)))
    (define-key map (kbd "ESC ESC")
      (lambda () (interactive) (abort-recursive-edit)))
    (let ((minibuffer-local-map (copy-keymap map))
          (minibuffer-message-timeout 0.5))
      (unwind-protect
          (progn
            ;; Build attribute cache
            (taskpaper-attribute-cache-build)
            ;; Add hooks and set idle timer
            (setq taskpaper-iquery-idle-timer
                  (run-with-idle-timer
                   taskpaper-iquery-delay t 'taskpaper-iquery-query))
            (add-hook 'after-change-functions
                      'taskpaper-read-query-propertize 'append)
            ;; Read query string
            (read-string prompt query taskpaper-query-history nil t))
        ;; Remove hooks and cancel idle timer
        (remove-hook 'after-change-functions
                     'taskpaper-read-query-propertize)
        (cancel-timer taskpaper-iquery-idle-timer)
        ;; Clear attribute cache
        (taskpaper-attribute-cache-clear)))))

(defun taskpaper-get-buffer-queries ()
  "Return a list of embedded buffer queries for selection."
  (let (desc query queries)
    (save-excursion
      (save-restriction
        (widen) (goto-char (point-min))
        (save-match-data
          (while (re-search-forward "@search" nil t)
            (when (taskpaper-in-tag-p (match-beginning 1))
              ;; Get query
              (setq query (taskpaper-item-get-attribute "search"))
              (when (and query (not (equal query "")))
                ;; Format description
                (setq desc (taskpaper-item-get-attribute "text")
                      desc (taskpaper-remove-trailing-tags
                            (taskpaper-remove-type-formatting
                             (taskpaper-remove-inline-markup desc))))
                ;; Add entry to the list
                (when (and desc (not (equal desc "")))
                  (push (cons desc query) queries))))))))
    (nreverse queries)))

(defun taskpaper-query-read-select ()
  "Query buffer using predefined queries."
  (interactive)
  (let ((queries (append (taskpaper-get-buffer-queries)
                         (delq nil (mapcar #'cdr taskpaper-custom-queries))))
        desc query)
    (unless queries (error "No predefined queries"))
    (let ((partial-completion-mode nil) (completion-ignore-case t))
      (setq desc (completing-read "Select query: " queries nil t)))
    (setq query (cdr (assoc desc queries)))
    (if taskpaper-iquery-default
        (taskpaper-iquery query) (taskpaper-query query))))

(defun taskpaper-query-fast-selection ()
  "Provide fast selection interface for custom queries.
Return selected query string."
  (unless taskpaper-custom-queries (error "No custom queries"))
  (save-excursion
    (save-window-excursion
      (switch-to-buffer-other-window
       (get-buffer-create "*TaskPaper custom queries*"))
      (erase-buffer)
      (toggle-truncate-lines 1)
      (setq show-trailing-whitespace nil)
      (let ((tbl taskpaper-custom-queries) e c desc qs)
        ;; Insert selection dialog
        (insert "\n")
        (while (setq e (pop tbl))
          (if (stringp (nth 0 e))
              (insert (format "\n%s\n\n" (nth 0 e)))
            (setq c (nth 0 e) desc (nth 1 e) qs (nth 2 e))
            (when (and c desc qs)
              (insert (format "%s %s\n"
                              (propertize (char-to-string c)
                                          'face 'taskpaper-fast-select-key)
                              desc)))))
        (insert "\n") (goto-char (point-min)) (fit-window-to-buffer)
        ;; Select query
        (setq c (read-char-exclusive "Press key for query:"))
        (if (setq e (assoc c taskpaper-custom-queries) qs (nth 2 e))
            (prog1 qs (kill-buffer))
          (kill-buffer) (setq quit-flag t))))))

(defun taskpaper-query-fast-select ()
  "Query buffer using fast selection interface."
  (interactive)
  (let ((query (taskpaper-query-fast-selection)))
    (if taskpaper-iquery-default
        (taskpaper-iquery query) (taskpaper-query query))))

(defun taskpaper-query-tag-at-point ()
  "Query buffer for tag at point.
When point is on a \"@search\" tag, execute query stored in the
tag value. For other tags when point is on the tag name, query
for the tag name, otherwise query for the name-value
combination."
  (interactive)
  (if (and (taskpaper-in-tag-p)
           (taskpaper-in-regexp taskpaper-tag-regexp))
      (let* ((name  (match-string-no-properties 2))
             (value (match-string-no-properties 3))
             (value (taskpaper-tag-value-unescape value))
             (query (cond
                     ((and (equal name "search") value)
                      value)
                     ((and name
                           (>= (point) (match-beginning 2))
                           (<= (point) (match-end 2)))
                      (format "@%s" name))
                     ((and name value)
                      (setq value (taskpaper-escape-double-quotes value))
                      (format "@%s = \"%s\"" name value))
                     (t (format "@%s" name)))))
        (if taskpaper-iquery-default
            (taskpaper-iquery query) (taskpaper-query query)))
    (user-error "No tag at point")))

;;;; Ispell and Flyspell support

(defun taskpaper-ispell-setup ()
  "Ispell setup for TaskPaper mode."
  (add-to-list 'ispell-skip-region-alist (list taskpaper-tag-regexp))
  (add-to-list 'ispell-skip-region-alist (list taskpaper-uri-regexp))
  (add-to-list 'ispell-skip-region-alist (list taskpaper-email-regexp))
  (add-to-list 'ispell-skip-region-alist (list taskpaper-file-path-regexp)))

(defun taskpaper-mode-flyspell-verify ()
  "Function used for `flyspell-generic-check-word-predicate'."
  (and (not (taskpaper-in-regexp taskpaper-tag-regexp))
       (not (taskpaper-in-regexp taskpaper-uri-regexp))
       (not (taskpaper-in-regexp taskpaper-email-regexp))
       (not (taskpaper-in-regexp taskpaper-file-path-regexp))))
(put 'taskpaper-mode 'flyspell-mode-predicate 'taskpaper-mode-flyspell-verify)

;;;; Bookmarks support

(defun taskpaper-bookmark-jump-unhide ()
  "Reveal the current position to show the bookmark location."
  (and (derived-mode-p 'taskpaper-mode)
       (or (outline-invisible-p)
           (save-excursion
             (goto-char (max (point-min) (1- (point))))
             (outline-invisible-p)))
       (taskpaper-outline-show-context)))

(eval-after-load "bookmark"
  '(if (boundp 'bookmark-after-jump-hook)
       (add-hook 'bookmark-after-jump-hook 'taskpaper-bookmark-jump-unhide)
     (defadvice bookmark-jump (after taskpaper-make-visible activate)
       "Make the position visible."
       (taskpaper-bookmark-jump-unhide))))

;;;; Imenu support

(eval-after-load "imenu"
  '(progn
     (add-hook 'imenu-after-jump-hook
               (lambda ()
                 (when (derived-mode-p 'taskpaper-mode)
                   (taskpaper-outline-show-context))))))

;;;; Miscellaneous

(defun taskpaper-tab ()
  "Demote current item or indent line.
When multiple items are selected, demote every item in the active
region."
  (interactive)
  (cond ((region-active-p)
         (taskpaper-outline-map-region
          'taskpaper-outline-demote (region-beginning) (region-end)))
        ((outline-on-heading-p)
         (call-interactively #'taskpaper-outline-demote))
        (t (call-interactively #'indent-for-tab-command))))

(defun taskpaper-shifttab ()
  "Promote current item.
When multiple items are selected, promote every item in the
active region."
  (interactive)
  (cond ((region-active-p)
         (taskpaper-outline-map-region
          'taskpaper-outline-promote (region-beginning) (region-end)))
        ((outline-on-heading-p)
         (call-interactively #'taskpaper-outline-promote))))

(defvar taskpaper-mode-transpose-word-syntax-table
  (let ((st (make-syntax-table text-mode-syntax-table)))
    (modify-syntax-entry ?\* "w p" st)
    (modify-syntax-entry ?\_ "w p" st)
    st))

(defun taskpaper-transpose-words ()
  "Transpose words in a TaskPaper buffer."
  (interactive)
  (let ((st (if taskpaper-use-inline-emphasis
                taskpaper-mode-transpose-word-syntax-table
              taskpaper-mode-syntax-table)))
    (with-syntax-table st (call-interactively #'transpose-words))))

(taskpaper-remap taskpaper-mode-map #'transpose-words #'taskpaper-transpose-words)

(defun taskpaper-save-all-taskpaper-buffers ()
  "Save all TaskPaper buffers without user confirmation."
  (interactive)
  (save-some-buffers t (lambda () (derived-mode-p 'taskpaper-mode))))

;;;; Major mode definition

;;;###autoload
(define-derived-mode taskpaper-mode outline-mode "TaskPaper"
  "Major mode for editing and querying files in TaskPaper format.
TaskPaper mode is implemented on top of Outline mode. Turning on
TaskPaper mode runs the normal hook `text-mode-hook', and then
`outline-mode-hook' and `taskpaper-mode-hook'."
  (kill-all-local-variables)
  ;; Disable Outline mode menus
  (define-key taskpaper-mode-map [menu-bar headings] 'undefined)
  (define-key taskpaper-mode-map [menu-bar hide]     'undefined)
  (define-key taskpaper-mode-map [menu-bar show]     'undefined)
  ;; General settings
  (setq major-mode 'taskpaper-mode)
  (setq mode-name "TaskPaper")
  (use-local-map taskpaper-mode-map)
  ;; Invisibility spec
  (taskpaper-set-local 'line-move-ignore-invisible t)
  (add-to-invisibility-spec '(outline . t))
  (if taskpaper-hide-markup
      (add-to-invisibility-spec 'taskpaper-markup)
    (remove-from-invisibility-spec 'taskpaper-markup))
  ;; Outline settings
  ;; NOTE: Group 1 in `outline-regexp' is used by `replace-match'
  ;; in `taskpaper-promote' and `taskpaper-demote' functions.
  (taskpaper-set-local 'outline-regexp "\\([\t]*\\)[^\t\f\n]")
  (taskpaper-set-local 'outline-heading-end-regexp "\n")
  (taskpaper-set-local 'outline-blank-line t)
  ;; Paragraph filling
  (taskpaper-set-local 'paragraph-start
                       (concat "\f\\|[ \t]*$\\|\\(?:" outline-regexp "\\)"))
  (taskpaper-set-local 'paragraph-separate "[ \t\f]*$")
  (taskpaper-set-local 'auto-fill-inhibit-regexp outline-regexp)
  (taskpaper-set-local 'adaptive-fill-regexp
                       "[ \t]*\\(\\(?:[-+*]+\\|[0-9]+\\.\\)[ \t]*\\)*")
  ;; Font lock settings
  (taskpaper-set-font-lock-defaults)
  (taskpaper-set-local 'font-lock-unfontify-region-function 'taskpaper-unfontify-region)
  ;; Indentation settings
  (taskpaper-set-local 'indent-tabs-mode t)
  (taskpaper-set-local 'indent-line-function 'indent-to-left-margin)
  ;; Syntax table settings
  (set-syntax-table taskpaper-mode-syntax-table)
  ;; Next error function for sparse trees
  (setq-local next-error-function 'taskpaper-occur-next-match)
  ;; Imenu settings
  (setq imenu-generic-expression (list (list nil taskpaper-project-regexp 1)))
  ;; I-search settings
  (setq-local outline-isearch-open-invisible-function
              (lambda (&rest _) (taskpaper-outline-show-context)))
  ;; Miscellaneous settings
  (taskpaper-ispell-setup)
  (setq-local require-final-newline mode-require-final-newline)
  ;; Startup settings
  (taskpaper-set-startup-visibility)
  (when taskpaper-startup-with-inline-images (taskpaper-display-inline-images))
  ;; Hooks
  (add-hook 'change-major-mode-hook 'taskpaper-outline-show-all nil t)
  (add-hook 'change-major-mode-hook 'taskpaper-remove-inline-images nil t)
  (add-hook 'change-major-mode-hook 'taskpaper-occur-remove-highlights nil t)
  (add-hook 'change-major-mode-hook
            '(lambda () (remove-from-invisibility-spec 'taskpaper-markup) nil t))
  (run-hooks 'taskpaper-mode-hook))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.taskpaper\\'" . taskpaper-mode))

;;;; Key bindings

(define-key taskpaper-mode-map (kbd "TAB") 'taskpaper-tab)
(define-key taskpaper-mode-map (kbd "<tab>") 'taskpaper-tab)
(define-key taskpaper-mode-map (kbd "S-<tab>") 'taskpaper-shifttab)
(define-key taskpaper-mode-map (kbd "<backtab>") 'taskpaper-shifttab)
(define-key taskpaper-mode-map (kbd "<S-iso-lefttab>") 'taskpaper-shifttab)
(define-key taskpaper-mode-map (kbd "C-<tab>") 'taskpaper-cycle)
(define-key taskpaper-mode-map (kbd "C-<up>") 'taskpaper-outline-backward-same-level)
(define-key taskpaper-mode-map (kbd "C-<down>") 'taskpaper-outline-forward-same-level)
(define-key taskpaper-mode-map (kbd "RET") 'taskpaper-new-item-same-level)
(define-key taskpaper-mode-map (kbd "<return>") 'taskpaper-new-item-same-level)
(define-key taskpaper-mode-map (kbd "M-<up>") 'taskpaper-outline-move-subtree-up)
(define-key taskpaper-mode-map (kbd "M-<down>") 'taskpaper-outline-move-subtree-down)
(define-key taskpaper-mode-map (kbd "M-<left>") 'taskpaper-outline-promote-subtree)
(define-key taskpaper-mode-map (kbd "M-<right>") 'taskpaper-outline-demote-subtree)
(define-key taskpaper-mode-map (kbd "M-RET") 'taskpaper-new-task-same-level)
(define-key taskpaper-mode-map (kbd "M-<return>") 'taskpaper-new-task-same-level)
(define-key taskpaper-mode-map (kbd "C-M-i") 'taskpaper-complete-tag-at-point)
(define-key taskpaper-mode-map (kbd "M-<tab>") 'taskpaper-complete-tag-at-point)
(define-key taskpaper-mode-map (kbd "ESC TAB") 'taskpaper-complete-tag-at-point)
(define-key taskpaper-mode-map (kbd "S-<up>") 'taskpaper-outline-up-level)
(define-key taskpaper-mode-map (kbd "ESC ESC") 'taskpaper-outline-show-all)

(define-key taskpaper-mode-map (kbd "C-c SPC") 'taskpaper-show-in-calendar)
(define-key taskpaper-mode-map (kbd "C-c #") 'taskpaper-narrow-to-subtree)
(define-key taskpaper-mode-map (kbd "C-c *") 'taskpaper-outline-hide-other)
(define-key taskpaper-mode-map (kbd "C-c >") 'taskpaper-goto-calendar)
(define-key taskpaper-mode-map (kbd "C-c <") 'taskpaper-date-from-calendar)
(define-key taskpaper-mode-map (kbd "C-c .") 'taskpaper-read-date-insert-timestamp)
(define-key taskpaper-mode-map (kbd "C-c @") 'taskpaper-item-set-tag-fast-select)
(define-key taskpaper-mode-map (kbd "C-c /") 'taskpaper-occur)
(define-key taskpaper-mode-map (kbd "C-c ?") 'taskpaper-query-read-select)
(define-key taskpaper-mode-map (kbd "C-c !") 'taskpaper-query-fast-select)
(define-key taskpaper-mode-map (kbd "C-c %") 'taskpaper-mark-ring-push)
(define-key taskpaper-mode-map (kbd "C-c &") 'taskpaper-mark-ring-goto)

(define-key taskpaper-mode-map (kbd "C-c C-a") 'taskpaper-outline-show-all)
(define-key taskpaper-mode-map (kbd "C-c C-z") 'taskpaper-outline-overview)
(define-key taskpaper-mode-map (kbd "C-c C-c") 'taskpaper-occur-remove-highlights)
(define-key taskpaper-mode-map (kbd "C-c C-d") 'taskpaper-item-toggle-done)
(define-key taskpaper-mode-map (kbd "C-c C-j") 'taskpaper-goto)
(define-key taskpaper-mode-map (kbd "C-c C-l") 'taskpaper-insert-file-link-at-point)
(define-key taskpaper-mode-map (kbd "C-c C-m") 'taskpaper-mark-subtree)
(define-key taskpaper-mode-map (kbd "C-c C-o") 'taskpaper-open-link-at-point)
(define-key taskpaper-mode-map (kbd "C-c C-i") 'taskpaper-iquery)
(define-key taskpaper-mode-map (kbd "C-c C-q") 'taskpaper-query)
(define-key taskpaper-mode-map (kbd "C-c C-r") 'taskpaper-remove-tag-at-point)
(define-key taskpaper-mode-map (kbd "C-c C-t") 'taskpaper-query-tag-at-point)
(define-key taskpaper-mode-map (kbd "C-c C-w") 'taskpaper-refile-subtree)
(define-key taskpaper-mode-map (kbd "C-c M-w") 'taskpaper-refile-subtree-copy)

(define-key taskpaper-mode-map (kbd "C-c C-f p") 'taskpaper-item-format-as-project)
(define-key taskpaper-mode-map (kbd "C-c C-f t") 'taskpaper-item-format-as-task)
(define-key taskpaper-mode-map (kbd "C-c C-f n") 'taskpaper-item-format-as-note)

(define-key taskpaper-mode-map (kbd "C-c C-s a") 'taskpaper-sort-by-text)
(define-key taskpaper-mode-map (kbd "C-c C-s t") 'taskpaper-sort-by-type)

(define-key taskpaper-mode-map (kbd "C-c C-x a") 'taskpaper-archive-subtree)
(define-key taskpaper-mode-map (kbd "C-c C-x v") 'taskpaper-outline-copy-visible)

(define-key taskpaper-mode-map (kbd "C-c C-x C-c") 'taskpaper-clone-subtree)
(define-key taskpaper-mode-map (kbd "C-c C-x C-w") 'taskpaper-cut-subtree)
(define-key taskpaper-mode-map (kbd "C-c C-x M-w") 'taskpaper-copy-subtree)
(define-key taskpaper-mode-map (kbd "C-c C-x C-y") 'taskpaper-paste-subtree)
(define-key taskpaper-mode-map (kbd "C-c C-x C-n") 'taskpaper-next-link)
(define-key taskpaper-mode-map (kbd "C-c C-x C-p") 'taskpaper-previous-link)

(define-key taskpaper-mode-map (kbd "C-c C-x C-m") 'taskpaper-toggle-markup-hiding)
(define-key taskpaper-mode-map (kbd "C-c C-x C-v") 'taskpaper-toggle-inline-images)

;;;; Menu

(easy-menu-define taskpaper-mode-menu taskpaper-mode-map
  "Menu for TaskPaper mode."
  '("TaskPaper"
    ("Format"
     ["Format Item as Project" taskpaper-item-format-as-project
      :active (outline-on-heading-p)]
     ["Format Item as Task" taskpaper-item-format-as-task
      :active (outline-on-heading-p)]
     ["Format Item as Note" taskpaper-item-format-as-note
      :active (outline-on-heading-p)]
     "--"
     ["Hide Inline Markup" taskpaper-toggle-markup-hiding
      :style toggle
      :selected taskpaper-hide-markup])
    ("Visibility"
     ["Cycle Visibility" taskpaper-cycle
      :active (outline-on-heading-p)]
     ["Cycle Visibility (Global)" (taskpaper-cycle t)]
     ["Hide Other" taskpaper-outline-hide-other
      :active (outline-on-heading-p)]
     ["Overview" taskpaper-outline-overview]
     ["Show All" taskpaper-outline-show-all])
    ("Navigation"
     ["Up Level" taskpaper-outline-up-level
      :active (outline-on-heading-p)]
     ["Forward Same Level" taskpaper-outline-forward-same-level
      :active (outline-on-heading-p)]
     ["Backward Same Level" taskpaper-outline-backward-same-level
      :active (outline-on-heading-p)]
     "--"
     ["Go To..." taskpaper-goto])
    ("Structure Editing"
     ["Promote Item" taskpaper-outline-promote
      :active (outline-on-heading-p)]
     ["Demote Item" taskpaper-outline-demote
      :active (outline-on-heading-p)]
     "--"
     ["Promote Subtree" taskpaper-outline-promote-subtree
      :active (outline-on-heading-p)]
     ["Demote Subtree" taskpaper-outline-demote-subtree
      :active (outline-on-heading-p)]
     "--"
     ["Move Subtree Up" taskpaper-outline-move-subtree-up
      :active (outline-on-heading-p)]
     ["Move Substree Down" taskpaper-outline-move-subtree-down
      :active (outline-on-heading-p)]
     "--"
     ["Copy Subtree" taskpaper-copy-subtree
      :active (outline-on-heading-p)]
     ["Cut Subtree" taskpaper-cut-subtree
      :active (outline-on-heading-p)]
     ["Paste Subtree" taskpaper-paste-subtree
      :active (and kill-ring (current-kill 0))]
     ["Duplicate Subtree" taskpaper-clone-subtree
      :active (outline-on-heading-p)]
     "--"
     ["Mark Subtree" taskpaper-mark-subtree
      :active (outline-on-heading-p)]
     ["Narrow to Subtree" taskpaper-narrow-to-subtree
      :active (outline-on-heading-p)]
     "--"
     ["Sort Children by Text" taskpaper-sort-by-text
      :active (or (bobp) (outline-on-heading-p))]
     ["Sort Children by Type" taskpaper-sort-by-type
      :active (or (bobp) (outline-on-heading-p))]
     "--"
     ["Refile Subtree..." taskpaper-refile-subtree
      :active (outline-on-heading-p)]
     ["Refile Subtree (Copy)..." taskpaper-refile-subtree-copy
      :active (outline-on-heading-p)]
     "--"
     ["Archive Subtree" taskpaper-archive-subtree
      :active (outline-on-heading-p)]
     "--"
     ["Copy Visible Items" taskpaper-outline-copy-visible
      :active (region-active-p)])
    ("Tags"
     ["Complete Tag" taskpaper-complete-tag-at-point
      :active (taskpaper-in-regexp (format "@%s*" taskpaper-tag-name-char-regexp))
      :keys "<M-tab>"]
     ["Select Tag..." taskpaper-item-set-tag-fast-select]
     ["Remove Tag" taskpaper-remove-tag-at-point
      :active (taskpaper-in-regexp taskpaper-tag-regexp)]
     "--"
     ["Toggle Done" taskpaper-item-toggle-done
      :active (outline-on-heading-p)])
    ("Date & Time"
     ["Show Date in Calendar" taskpaper-show-in-calendar
      :active (taskpaper-in-regexp taskpaper-tag-regexp)]
     ["Access Calendar" taskpaper-goto-calendar]
     ["Insert Date from Calendar" taskpaper-date-from-calendar
      :active (get-buffer "*Calendar*")]
     ["Insert Time Stamp..." taskpaper-read-date-insert-timestamp])
    ("Links & Images"
     ["Next Link" taskpaper-next-link]
     ["Previous Link" taskpaper-previous-link]
     "--"
     ["Insert File Link..." taskpaper-insert-file-link-at-point]
     "--"
     ["Show Inline Images" taskpaper-toggle-inline-images
      :style toggle
      :selected taskpaper-inline-image-overlays])
    ("Search"
     ["Start Incremental Search..." taskpaper-iquery
      :keys "C-c C-i"]
     ["Start Non-incremental Search..." taskpaper-query]
     ["Select Search Query..." taskpaper-query-read-select]
     ["Select Custom Search Query..." taskpaper-query-fast-select]
     "--"
     ["Filter by Regexp..." taskpaper-occur]
     ["Next Match" next-error
      :active taskpaper-occur-highlights]
     ["Previous Match" previous-error
      :active taskpaper-occur-highlights]
     ["Remove Highlights" taskpaper-occur-remove-highlights
      :active taskpaper-occur-highlights])
    ("Agenda View"
     ["Create Agenda View..." taskpaper-agenda-search]
     ["Select Agenda View..." taskpaper-agenda-select])
    "--"
    ("Documentation"
     ["Show Version" taskpaper-mode-version]
     ["Browse Manual" taskpaper-mode-browse-manual])
    "--"
    ["Customize..." (customize-browse 'taskpaper)]))

;;;; Agenda view

(defcustom taskpaper-agenda-files nil
  "List of files to be used for agenda view.
If an entry is a directory, all files in that directory that are
matched by `taskpaper-agenda-file-regexp' will be part of the
file list."
  :group 'taskpaper
  :type 'list)

(defcustom taskpaper-agenda-file-regexp "^[^.].*\\.taskpaper\\'"
  "Regular expression to match files for `taskpaper-agenda-files'.
If any element in the list in that variable contains a directory
instead of a normal file, all files in that directory that are
matched by this regular expression will be included."
  :group 'taskpaper
  :type 'regexp)

(defcustom taskpaper-agenda-skip-unavailable-files nil
  "Non-nil means, silently skip unavailable agenda files."
  :group 'taskpaper
  :type 'boolean)

(defcustom taskpaper-agenda-sorting-predicate nil
  "Predicate function for sorting items in an Agenda mode buffer.
If non-nil, it is called with two arguments, the items to
compare, and should return non-nil if the first item should sort
before the second one."
  :group 'taskpaper
  :type 'symbol)

(defcustom taskpaper-agenda-start-with-follow-mode nil
  "The initial value of Follow mode in an Agenda mode buffer."
  :group 'taskpaper
  :type 'boolean)

(defcustom taskpaper-agenda-after-show-hook nil
  "Normal hook run after an item has been shown from agenda view.
Point is in the buffer where the item originated."
  :group 'taskpaper
  :type 'hook)

(defcustom taskpaper-agenda-window-setup 'reorganize-frame
  "How the Agenda mode buffer should be displayed.
Possible values for this option are:

 current-window    Show agenda in the current window, keeping other windows
 other-window      Show agenda in other window
 only-window       Show agenda in the current window, deleting other windows
 other-frame       Show agenda in other frame
 reorganize-frame  Show only the current window and the agenda window"
  :group 'taskpaper
  :type '(choice
          (const :tag "Current window" current-window)
          (const :tag "Other window" other-window)
          (const :tag "Current window only" only-window)
          (const :tag "Other frame" other-frame)
          (const :tag "Current window and agenda window" reorganize-frame)))

(defcustom taskpaper-agenda-restore-windows-after-quit nil
  "Non-nil means, restore window configuration upon exiting agenda.
Before the window configuration is changed for displaying the
agenda, the current status is recorded. When the Agenda mode is
exited and this option is set, the old state is restored. If
`taskpaper-agenda-window-setup' is `other-frame', the value of
this option will be ignored."
  :group 'taskpaper
  :type 'boolean)

(defconst taskpaper-agenda-buffer-name "*TaskPaper Agenda*")

(defvar taskpaper-agenda-pre-window-conf nil)
(defvar taskpaper-agenda-pre-follow-window-conf nil)

(defvar taskpaper-agenda-matcher-form nil
  "Recent matcher form for re-building agenda view.")
(make-variable-buffer-local 'taskpaper-agenda-matcher-form)

(defvar taskpaper-agenda-new-buffers nil
  "Buffers created to visit agenda files.")

(defvar taskpaper-agenda-follow-mode
  taskpaper-agenda-start-with-follow-mode)

(defun taskpaper-agenda-buffer-p ()
  "Return non-nil if current buffer is an Agenda mode buffer."
  (and (derived-mode-p 'taskpaper-agenda-mode)
       (equal (buffer-name) taskpaper-agenda-buffer-name)))

(defun taskpaper-agenda-buffer-error ()
  "Throw an error when not in an Agenda mode buffer."
  (error "Not in TaskPaper Agenda mode buffer"))

(defun taskpaper-agenda-error ()
  "Throw an error when a command is not allowed."
  (user-error "Command not allowed in this line"))

(defun taskpaper-agenda-set-mode-name ()
  "Set mode name to indicate all Agenda mode settings."
  (setq mode-name
        (list "TP-Agenda"
              (if taskpaper-agenda-follow-mode " Follow" "")
              (force-mode-line-update))))

(defun taskpaper-agenda-files ()
  "Get list of agenda files."
  (let ((files
         (if (listp taskpaper-agenda-files)
             taskpaper-agenda-files
           (error "Invalid value of `taskpaper-agenda-files'"))))
    (setq files
          (apply 'append
                 (mapcar (lambda (f)
                           (if (file-directory-p f)
                               (directory-files
                                f t taskpaper-agenda-file-regexp)
                             (list f)))
                         files)))
    (when taskpaper-agenda-skip-unavailable-files
      (setq files
            (delq nil
                  (mapcar (function
                           (lambda (file)
                             (and (file-readable-p file) file)))
                          files))))
    files))

(defun taskpaper-agenda-file-p (&optional file)
  "Return non-nil, if FILE is an agenda file.
If FILE is omitted, use the file associated with the current
buffer."
  (let ((fname (or file (buffer-file-name))))
    (and fname
         (member (file-truename fname)
                 (mapcar #'file-truename
                         (taskpaper-agenda-files))))))

(defun taskpaper-agenda-get-file-buffer (file)
  "Get an agenda buffer visiting FILE.
If the buffer needs to be created, add it to the list of buffers
which might be released later."
  (let ((buf (taskpaper-find-base-buffer-visiting file)))
    (if buf buf
      (setq buf (find-file-noselect file))
      (when buf (push buf taskpaper-agenda-new-buffers))
      buf)))

(defun taskpaper-agenda-collect-items (matcher)
  "Return list of items from agenda files matching MATCHER.
Cycle through agenda files and collect items matching MATCHER.
MATCHER is a Lisp form to be evaluated at an item; returning a
non-nil value qualifies the item for inclusion. Return list of
items flatten and linked back to the corresponding buffer
position where the item originated."
  (let ((files (taskpaper-agenda-files))
        file buffer marker item items)
    ;; Iterate through agenda files
    (while (setq file (pop files))
      (setq buffer
            (if (file-exists-p file)
                (taskpaper-agenda-get-file-buffer file)
              (error "Non-existent agenda file: %s" file)))
      (with-current-buffer buffer
        (unless (derived-mode-p 'taskpaper-mode)
          (error "Agenda file is not in TaskPaper mode: %s" file))
        (let ((re (concat "^" outline-regexp)))
          (save-excursion
            (save-restriction
              (widen) (goto-char (point-min))
              (while (let (case-fold-search)
                       (re-search-forward re nil t))
                (when (let ((case-fold-search t))
                        (save-excursion (eval matcher)))
                  ;; Set marker and add the item to the list
                  (setq marker (taskpaper-new-marker (point-at-bol))
                        item (taskpaper-item-get-attribute "text")
                        item (propertize item 'taskpaper-marker marker))
                  (push item items))))))))
    (nreverse items)))

(defun taskpaper-agenda-sort-init (list)
  "Sort list of items for agenda view."
  (let ((sfunc taskpaper-agenda-sorting-predicate))
    (if sfunc (sort list sfunc) list)))

(defun taskpaper-agenda-insert-items (matcher)
  "Insert items matching MATCHER in the current Agenda mode buffer.
Return number of items."
  (unless (taskpaper-agenda-buffer-p) (taskpaper-agenda-buffer-error))
  (let ((inhibit-read-only t)
        (items (taskpaper-agenda-collect-items matcher)))
    (erase-buffer) (goto-char (point-min))
    (when items
      (setq items (taskpaper-agenda-sort-init items))
      (save-excursion (dolist (item items) (insert item "\n"))))
    (length items)))

(defun taskpaper-agenda-redo ()
  "Re-build the current Agenda mode buffer."
  (interactive)
  (unless (taskpaper-agenda-buffer-p) (taskpaper-agenda-buffer-error))
  (when taskpaper-agenda-matcher-form
    (let ((cnt))
      (message "Re-building agenda buffer...")
      (setq cnt (taskpaper-agenda-insert-items taskpaper-agenda-matcher-form))
      (message "Re-building agenda buffer...done")
      (when cnt (message "%d %s" cnt (if (= cnt 1) "item" "items"))))))

(defun taskpaper-agenda-goto ()
  "Go to the original location of the current item."
  (interactive)
  (unless (taskpaper-agenda-buffer-p) (taskpaper-agenda-buffer-error))
  (let* ((marker (or (taskpaper-get-at-bol 'taskpaper-marker)
                     (taskpaper-agenda-error)))
         (buffer (marker-buffer marker))
         (pos (marker-position marker)))
    (switch-to-buffer-other-window buffer)
    (widen) (push-mark) (goto-char pos))
  (run-hooks 'taskpaper-agenda-after-show-hook))

(defun taskpaper-agenda-switch-to ()
  "Go to the original location of the current item and delete other windows."
  (interactive)
  (unless (taskpaper-agenda-buffer-p) (taskpaper-agenda-buffer-error))
  (let* ((marker (or (taskpaper-get-at-bol 'taskpaper-marker)
                     (taskpaper-agenda-error)))
         (buffer (marker-buffer marker))
         (pos (marker-position marker)))
    (unless buffer (user-error "Trying to switch to non-existent buffer"))
    (pop-to-buffer-same-window buffer)
    (delete-other-windows) (widen) (goto-char pos))
  (run-hooks 'taskpaper-agenda-after-show-hook))

(defun taskpaper-agenda-show ()
  "Display the original location of the current item."
  (interactive)
  (unless (taskpaper-agenda-buffer-p) (taskpaper-agenda-buffer-error))
  (let ((win (selected-window)))
    (taskpaper-agenda-goto) (select-window win)))

(defun taskpaper-agenda-do-context-action ()
  "Show Follow mode window."
  (let ((marker (taskpaper-get-at-bol 'taskpaper-marker)))
    (and (markerp marker) (marker-buffer marker)
         taskpaper-agenda-follow-mode (taskpaper-agenda-show))))

(defun taskpaper-agenda-follow-mode ()
  "Toggle Follow mode in the Agenda mode buffer."
  (interactive)
  (unless (taskpaper-agenda-buffer-p) (taskpaper-agenda-buffer-error))
  (unless taskpaper-agenda-follow-mode
    (setq taskpaper-agenda-pre-follow-window-conf
          (current-window-configuration)))
  (setq taskpaper-agenda-follow-mode
        (not taskpaper-agenda-follow-mode))
  (unless taskpaper-agenda-follow-mode
    (set-window-configuration
     taskpaper-agenda-pre-follow-window-conf))
  (taskpaper-agenda-set-mode-name)
  (taskpaper-agenda-do-context-action)
  (message "Follow mode is %s"
           (if taskpaper-agenda-follow-mode "on" "off")))

(defun taskpaper-agenda-next-line ()
  "Move cursor to the next line.
Display the origin of the current item if Follow mode is active."
  (interactive)
  (unless (taskpaper-agenda-buffer-p) (taskpaper-agenda-buffer-error))
  (call-interactively #'next-line)
  (taskpaper-agenda-do-context-action))

(defun taskpaper-agenda-previous-line ()
  "Move cursor to the previous line.
Display the origin of the current item if Follow mode is active."
  (interactive)
  (unless (taskpaper-agenda-buffer-p) (taskpaper-agenda-buffer-error))
  (call-interactively #'previous-line)
  (taskpaper-agenda-do-context-action))

(defun taskpaper-agenda-quit ()
  "Quit the agenda.
Kill the current Agenda mode buffer and restore window
configuration."
  (interactive)
  (unless (taskpaper-agenda-buffer-p) (taskpaper-agenda-buffer-error))
  (let ((buf (current-buffer)))
    ;; Restore window configuration
    (cond
     ((eq taskpaper-agenda-window-setup 'other-frame)
      (delete-frame))
     ((and taskpaper-agenda-pre-window-conf
           taskpaper-agenda-restore-windows-after-quit)
      (set-window-configuration taskpaper-agenda-pre-window-conf)
      (setq taskpaper-agenda-pre-window-conf nil))
     (t
      (and (not (eq taskpaper-agenda-window-setup 'current-window))
           (not (one-window-p))
           (delete-window))))
    ;; Kill the agenda buffer
    (kill-buffer buf)))

(defun taskpaper-agenda-exit ()
  "Exit the agenda.
Like `taskpaper-agenda-quit', but kill all TaskPaper buffers that
were created by the agenda. TaskPaper buffers visited directly by
the user will not be touched."
  (interactive)
  (unless (taskpaper-agenda-buffer-p) (taskpaper-agenda-buffer-error))
  (taskpaper-release-buffers taskpaper-agenda-new-buffers)
  (taskpaper-agenda-quit))

(defvar taskpaper-agenda-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "r") 'taskpaper-agenda-redo)
    (define-key map (kbd "a") 'taskpaper-outline-show-all)
    (define-key map (kbd "c") 'taskpaper-show-in-calendar)
    (define-key map (kbd ">") 'taskpaper-goto-calendar)
    (define-key map (kbd "F") 'taskpaper-agenda-follow-mode)
    (define-key map (kbd "p") 'taskpaper-agenda-previous-line)
    (define-key map (kbd "n") 'taskpaper-agenda-next-line)
    (define-key map (kbd "<up>") 'taskpaper-agenda-previous-line)
    (define-key map (kbd "<down>") 'taskpaper-agenda-next-line)
    (define-key map (kbd "SPC") 'taskpaper-agenda-show)
    (define-key map (kbd "TAB") 'taskpaper-agenda-goto)
    (define-key map (kbd "RET") 'taskpaper-agenda-switch-to)
    (define-key map (kbd "I") 'taskpaper-iquery)
    (define-key map (kbd "Q") 'taskpaper-query)
    (define-key map (kbd "S") 'taskpaper-query-fast-select)
    (define-key map (kbd "t") 'taskpaper-query-tag-at-point)
    (define-key map (kbd "/") 'taskpaper-occur)
    (define-key map (kbd "C-c C-c") 'taskpaper-occur-remove-highlights)
    (define-key map (kbd "v") 'taskpaper-outline-copy-visible)
    (define-key map (kbd "o") 'delete-other-windows)
    (define-key map (kbd "q") 'taskpaper-agenda-quit)
    (define-key map (kbd "x") 'taskpaper-agenda-exit)
    map)
  "Keymap for TaskPaper Agenda mode.")

(defun taskpaper-agenda-prepare-window (abuf)
  "Setup Agenda mode buffer in the window.
ABUF is the buffer for the agenda window."
  (setq taskpaper-agenda-pre-window-conf
        (current-window-configuration))
  (cond
   ((eq taskpaper-agenda-window-setup 'current-window)
    (pop-to-buffer-same-window abuf))
   ((eq taskpaper-agenda-window-setup 'other-window)
    (switch-to-buffer-other-window abuf))
   ((eq taskpaper-agenda-window-setup 'other-frame)
    (switch-to-buffer-other-frame abuf))
   ((eq taskpaper-agenda-window-setup 'only-window)
    (delete-other-windows)
    (pop-to-buffer-same-window abuf))
   ((eq taskpaper-agenda-window-setup 'reorganize-frame)
    (delete-other-windows)
    (switch-to-buffer-other-window abuf)))
  (unless (equal (current-buffer) abuf)
    (pop-to-buffer-same-window abuf)))

(defun taskpaper-agenda-build (matcher)
  "Build Agenda mode buffer using MATCHER."
  (let ((cnt))
    (message "Building agenda...")
    (taskpaper-agenda-prepare-window
     (get-buffer-create taskpaper-agenda-buffer-name))
    (taskpaper-mode)
    (setq major-mode 'taskpaper-agenda-mode)
    (taskpaper-agenda-set-mode-name)
    (use-local-map taskpaper-agenda-mode-map)
    (setq cnt (taskpaper-agenda-insert-items matcher))
    (setq buffer-read-only t)
    (setq taskpaper-agenda-matcher-form matcher)
    (message "Building agenda...done")
    (when cnt (message "%d %s" cnt (if (= cnt 1) "item" "items")))))

;;;###autoload
(defun taskpaper-agenda-search ()
  "Promt for query string and build agenda view."
  (interactive)
  (let ((matcher (taskpaper-query-matcher
                  (taskpaper-query-read-query "Agenda query: "))))
    (taskpaper-agenda-build matcher)))

;;;###autoload
(defun taskpaper-agenda-select ()
  "Promts for query selection and build agenda view."
  (interactive)
  (let ((matcher (taskpaper-query-matcher (taskpaper-query-fast-selection))))
    (taskpaper-agenda-build matcher)))

;;;; Provide `taskpaper-mode'

(provide 'taskpaper-mode)

;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; taskpaper-mode.el ends here

