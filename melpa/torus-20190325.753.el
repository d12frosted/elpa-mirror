;;; torus.el --- A buffer groups manager             -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Chimay

;; Author : Chimay
;; Name: Torus
;; Package-Version: 20190325.753
;; Package-X-Original-Version: 1.10
;; Package-requires: ((emacs "26"))
;; Package-Commit: b309da8c2eaee573a2e2572f25a08ce5da9e9990
;; Keywords: files, buffers, groups, persistent, history, layout, tabs
;; URL: https://github.com/chimay/torus

;;; Commentary:

;; If you ever dreamed about creating and switching buffer groups at will
;; in Emacs, Torus is the tool you want.
;;
;; In short, this plugin let you organize your buffers by creating as
;; many buffer groups as you need, add the files you want to it and
;; quickly navigate between :
;;
;;   - Buffers of the same group
;;   - Buffer groups
;;   - Workspaces, ie sets of buffer groups
;;
;; Note that :
;;
;;   - A location is a pair (buffer (or filename) . position)
;;   - A buffer group, in fact a location group, is called a circle
;;   - A set of buffer groups is called a torus (a circle of circles)
;;
;; Original idea by Stefan Kamphausen, see https://www.skamphausen.de/cgi-bin/ska/mtorus
;;
;; See https://github.com/chimay/torus/blob/master/README.org for more details

;;; License
;;; ------------------------------

;; This file is not part of Emacs.

;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING. If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Credits:
;;; ------------------------------

;; Stefan Kamphausen, https://www.skamphausen.de/cgi-bin/ska/mtorus
;; Sebastian Freundt, https://sourceforge.net/projects/mtorus.berlios/

;;; Code:
;;; ------------------------------------------------------------

;;; Requires
;;; ------------------------------

(eval-when-compile
  (require 'cl-lib)
  (require 'cl-extra)
  (require 'seq)
  (require 'subr-x))

(declare-function cl-copy-seq "cl-lib")

(declare-function cl-subseq "cl-extra")

(declare-function cl-position "cl-lib")
(declare-function cl-find "cl-lib")
(declare-function cl-remove "cl-lib")

(declare-function seq-intersection "seq")
(declare-function seq-filter "seq")
(declare-function seq-group-by "seq")

(declare-function string-join "subr-x")

;;; Custom
;;; ------------------------------

(defgroup torus nil
  "An interface to navigating groups of buffers."
  :tag "Torus"
  :link '(url-link :tag "Home Page"
                   "https://github.com/chimay/torus")
  :link '(emacs-commentary-link
                  :tag "Commentary in torus.el" "torus.el")
  :prefix "torus-"
  :group 'environment
  :group 'extensions
  :group 'convenience)

(defcustom torus-prefix-key "s-t"
  "Prefix key for the torus key mappings.
Will be processed by `kbd'."
  :type 'string
  :group 'torus)

(defcustom torus-binding-level 1
  "Whether to activate optional keybindings."
  :type 'integer
  :group 'torus)

(defcustom torus-verbosity 1
  "Level of verbosity.
1 = normal
2 = light debug
3 = heavy debug."
  :type 'integer
  :group 'torus)

(defcustom torus-dirname user-emacs-directory
  "The directory where the torus are read and written."
  :type 'string
  :group 'torus)

(defcustom torus-load-on-startup nil
  "Whether to load torus on startup of Emacs."
  :type 'boolean
  :group 'torus)

(defcustom torus-save-on-exit nil
  "Whether to save torus on exit of Emacs."
  :type 'boolean
  :group 'torus)

(defcustom torus-autoread-file nil
  "The file to load on startup when `torus-load-on-startup' is t."
  :type 'string
  :group 'torus)

(defcustom torus-autowrite-file nil
  "The file to write before quitting Emacs when `torus-save-on-exit' is t."
  :type 'string
  :group 'torus)

(defcustom torus-backup-number 3
  "Number of backups of torus files."
  :type 'integer
  :group 'torus)

(defcustom torus-history-maximum-elements 30
  "Maximum number of elements in `torus-history' and `torus-meta-history'."
  :type 'integer
  :group 'torus)

(defcustom torus-maximum-horizontal-split 3
  "Maximum number of horizontal split, see `torus-split-horizontally'."
  :type 'integer
  :group 'torus)

(defcustom torus-maximum-vertical-split 4
  "Maximum number of vertical split, see `torus-split-vertically'."
  :type 'integer
  :group 'torus)

(defcustom torus-display-tab-bar nil
  "Whether to display a tab bar in `header-line-format'."
  :type 'boolean
  :group 'torus)

(defcustom torus-separator-torus-circle " >> "
  "String between torus and circle in the dashboard."
  :type 'string
  :group 'torus)

(defcustom torus-separator-circle-location " > "
  "String between circle and location(s) in the dashboard."
  :type 'string
  :group 'torus)

(defcustom torus-location-separator " | "
  "String between location(s) in the dashboard."
  :type 'string
  :group 'torus)

(defcustom torus-prefix-separator "/"
  "String between the prefix and the circle names.
The name of the new circles will be of the form :
\"User_input_prefix `torus-prefix-separator' Name_of_the_added_circle\"
without the spaces. If the user enter a blank prefix,
the added circle names remain untouched."
  :type 'string
  :group 'torus)

(defcustom torus-join-separator " & "
  "String between the names when joining.
The name of the new object will be of the form :
\"Object-1 `torus-join-separator' Object-2\"
without the spaces."
  :type 'string
  :group 'torus)

;;; Variables
;;; ------------------------------

(defvar torus-meta nil
  "List of existing toruses.
You can create new torus with `torus-add-torus'or `torus-add-copy-of-torus'.
Some functions also create a new torus to work with.")

(defvar torus-torus nil
  "The torus is a list of circles.
A circle is a list of locations, stored in the form :
\(\"circle name\" locations)
A location is a pair (file . position)
Most recent entries are in the beginning of the lists.")

(defvar torus-history nil
  "Alist containing the history of locations in the torus.
Each element is of the form :
\((file . position) . circle)")

(defvar torus-layout nil
  "Alist containing split layout of circles.
Each element is of the form:
\(circle . layout)")

(defvar torus-input-history nil
  "History of user input.")

(defvar torus-index nil
  "Alist giving circles corresponding to torus locations.
Each element has the form :
\((file . position) . circle)
Allow to search among all files of the torus.")

(defvar torus-meta-history nil
  "Alist containing the history of locations in all toruses.
Each element is of the form :
\((file . position) . (circle . torus))")

(defvar torus-meta-index nil
  "Alist giving circles and toruses corresponding to torus locations.
Each element has the form :
\((file . position) . (circle . torus))
Allows to search among all files of the meta torus.")

(defvar torus-line-col nil
  "Alist storing locations and corresponding lines & columns in files.
Each element is of the form :
\((file . position) . (line . column))
Allows to display lines & columns.")

(defvar torus-markers nil
  "Alist containing markers to opened files.
Each element is of the form :
\((file . position) . marker)
Contain only the files opened in buffers.")

(defvar torus-original-header-lines nil
  "Alist containing orginal header lines, before torus changed it.
Each element is of the form :
\(buffer . original-header-line)")

;;; Extensions
;;; ------------

(defvar torus-extension ".el"
  "Extension for torus files.")

;;; Prompts
;;; ------------

(defvar torus--message-reset-choice
  "Reset [a] all [m] meta [t] torus [h] history [H] meta-history [l] layout [n] input history\n\
      [i] index [I] meta-index [p] line & col [C-m] markers [o] orig header line")

(defvar torus--message-print-choice
  "Print [a] all [m] meta [t] torus [h] history [H] meta-history [l] layout [n] input history\n\
      [i] index [I] meta-index [p] line & col [C-m] marker [o] orig header line")

(defvar torus--message-alternate-choice
  "Alternate [m] in meta torus [t] in torus [c] in circle [T] toruses [C] circles")

(defvar torus--message-reverse-choice
  "Reverse [l] locations [c] circle [d] deep : locations & circles")

(defvar torus--message-autogroup-choice
  "Autogroup by [p] path [d] directory [e] extension")

(defvar torus--message-batch-choice
  "Run on circle files [e] Elisp code [c] Elisp command \n\
                    [!] Shell command [&] Async Shell command")

(defvar torus--message-layout-choice
  "Layout [m] manual [o] one window [h] horizontal [v] vertical [g] grid \n\
       main window on [l] left [r] right [t] top [b] bottom")

(defvar torus--message-file-does-not-exist
  "File %s does not exist anymore. It will be removed from the torus.")

(defvar torus--message-empty-circle
  "No location in circle %s. You can use torus-add-location to fill the circle.")

(defvar torus--message-empty-torus
  "Torus is empty. Please use torus-add-location.")

(defvar torus--message-empty-meta
  "Meta Torus is empty. Please use torus-add-location.")

(defvar torus--message-existent-location
  "Location %s already exists in circle %s")

(defvar torus--message-prefix-circle
  "Prefix for the circle of torus %s (leave blank for none) ? ")

(defvar torus--message-circle-name-collision
  "Circle name collision. Please add/adjust prefixes to avoid confusion.")

(defvar torus--message-replace-torus
  "This will replace the current torus variables. Continue ? ")

;;; Mappings
;;; ------------------------------

(defvar torus-map)

(define-prefix-command 'torus-map)

(defvar torus-map-mouse-torus (make-sparse-keymap))
(defvar torus-map-mouse-circle (make-sparse-keymap))
(defvar torus-map-mouse-location (make-sparse-keymap))

;;; Toolbox
;;; ------------------------------

(defun torus--eval-string (string)
  "Eval Elisp code in STRING."
  (eval (car (read-from-string (format "(progn %s)" string)))))

(defun torus--equal-car-p (one two)
  "Whether the cars of ONE and TWO are equal."
  (equal (car one) (car two)))

(defmacro torus--set-ref (ptr list)
  "Set pointer PTR as reference to LIST."
  `(setq ,ptr ,list))

;; (defun torus--set-ref (ptr list)
;;   "Set pointer PTR as reference to LIST.
;; PTR must be quoted."
;;   (set ptr list))

(defun torus--set-deref (ptr list)
  "Change the list referenced by PTR to LIST."
  (setcar ptr (car list))
  (setcdr ptr (cdr list))
  ptr)

(defun torus--value-assoc (key alist)
  "Return value associated with KEY in ALIST."
  (cdr (assoc key alist)))

(defun torus--key-rassoc (value alist)
  "Return key associated with VALUE in ALIST."
  (car (rassoc value alist)))

(defun torus--assoc-delete-all (key alist)
  "Remove all elements with key matching KEY in ALIST."
  (cl-remove key alist :test 'equal :key 'car))

(when (fboundp 'assoc-delete-all)
  (defalias 'torus--assoc-delete-all 'assoc-delete-all))

(defun torus--reverse-assoc-delete-all (value alist)
  "Remove all elements with value matching VALUE in ALIST."
  (cl-remove value alist :test 'equal :key 'cdr))

(defun torus--directory (object)
  "Return the last directory component of OBJECT."
  (let* ((filename (pcase object
                     (`(,(and (pred stringp) one) . ,(pred integerp)) one)
                     ((pred stringp) object)))
         (grandpa (file-name-directory (directory-file-name
                                        (file-name-directory
                                         (directory-file-name filename)))))
         (relative (file-relative-name filename grandpa)))
    (directory-file-name (file-name-directory relative))))

(defun torus--extension-description (object)
  "Return the extension description of OBJECT."
  (let* ((filename (pcase object
                     (`(,(and (pred stringp) one) . ,(pred integerp)) one)
                     ((pred stringp) object)))
         (extension (file-name-extension filename)))
    (when (> torus-verbosity 1)
      (message "filename extension : %s %s" filename extension))
    (pcase extension
      ('nil "Nil")
      ('"" "Ends with a dot")
      ('"sh" "Shell POSIX")
      ('"zsh" "Shell Zsh")
      ('"bash" "Shell Bash")
      ('"org" "Org mode")
      ('"el" "Emacs Lisp")
      ('"vim" "Vim Script")
      ('"py" "Python")
      ('"rb" "Ruby")
      (_ extension))))

;;; Private Functions
;;; ------------------------------

;;; Strings
;;; ------------

(defun torus--buffer-or-filename (location)
  "Return buffer name of LOCATION if existent in `torus-markers', file basename otherwise."
  (unless (consp location)
    (error "Function torus--buffer-or-filename : wrong type argument"))
  (let* ((bookmark (cdr (assoc location torus-markers)))
         (buffer (when bookmark
                   (marker-buffer bookmark))))
    (if buffer
        (buffer-name buffer)
      (file-name-nondirectory (car location)))))

(defun torus--position (location)
  "Return position in LOCATION in raw format or in line & column if available.
Line & Columns are available in `torus-line-col'"
  (let ((entry (assoc location torus-line-col)))
    (if entry
        (format " at line %s col %s" (cadr entry) (cddr entry))
      (format " at position %s" (cdr location)))))

(defun torus--concise (object)
  "Return OBJECT in concise string format.
If OBJECT is a string : simply returns OBJECT.
If OBJECT is \(File . Position) : returns \"File at Position.\"
If OBJECT is \((File . Position) . Circle) : returns
\"Circle > File at Position.\""
  (let ((location))
    (pcase object
      (`((,(and (pred stringp) file) . ,(and (pred integerp) position)) .
         (,(and (pred stringp) circle) . ,(and (pred stringp) torus)))
       (setq location (cons file position))
       (concat torus
               torus-separator-torus-circle
               circle
               torus-separator-circle-location
               (torus--buffer-or-filename location)
               (torus--position location)))
      (`((,(and (pred stringp) file) . ,(and (pred integerp) position)) .
         ,(and (pred stringp) circle))
       (setq location (cons file position))
       (concat circle
               torus-separator-circle-location
               (torus--buffer-or-filename location)
               (torus--position location)))
      (`(,(and (pred stringp) file) . ,(and (pred integerp) position))
       (setq location (cons file position))
       (concat (torus--buffer-or-filename location)
               (torus--position location)))
      ((pred stringp) object)
      (_ (error "Function torus--concise : wrong type argument")))))

(defun torus--equal-concise-p (one two)
  "Whether the concise representations of ONE and TWO are equal."
  (equal (torus--concise one)
         (torus--concise two)))

(defun torus--short (location)
  "Return LOCATION in short string format.
Shorter than concise. Used for dashboard and tabs."
  (unless (consp location)
    (error "Function torus--short : wrong type argument"))
  (let* ((entry (assoc location torus-line-col))
         (position (if entry
                       (format " : %s" (cadr entry))
                     (format " . %s" (cdr location)))))
    (if (equal location (cadar torus-torus))
        (concat "[ "
                (torus--buffer-or-filename location)
                position
                " ]")
      (concat (torus--buffer-or-filename location)
              position))))

(defun torus--dashboard ()
  "Display summary of current torus, circle and location."
  (if torus-meta
      (if (> (length (car torus-torus)) 1)
          (let*
              ((locations (string-join (mapcar #'torus--short
                                               (cdar torus-torus)) " | ")))
            (format (concat " %s"
                            torus-separator-torus-circle
                            "%s"
                            torus-separator-circle-location
                            "%s")
                     (caar torus-meta)
                     (caar torus-torus)
                     locations))
        (message torus--message-empty-circle (car (car torus-torus))))
    (message torus--message-empty-meta)))

(defun torus--prefix-circles (prefix torus-name)
  "Return vars of TORUS-NAME with PREFIX to the circle names."
  (unless (and (stringp prefix) (stringp torus-name))
    (error "Function torus--prefix-circles : wrong type argument"))
  (let* ((entry (cdr (assoc torus-name torus-meta)))
         (torus (copy-tree (cdr (assoc "torus" entry))))
         (history (copy-tree (cdr (assoc "history" entry)))))
    (if (> (length prefix) 0)
        (progn
          (message "Prefix is %s" prefix)
          (dolist (elem torus)
            (setcar elem
                    (concat prefix torus-prefix-separator (car elem))))
          (dolist (elem history)
            (setcdr elem
                    (concat prefix torus-prefix-separator (cdr elem)))))
      (message "Prefix is blank"))
    (list torus history)))

;;; Files
;;; ------------

(defun torus--inside-p (&optional buffer)
  "Whether BUFFER (the current location if nil) belongs to the torus."
  (let ((filename (buffer-file-name  (if buffer
                                         buffer
                                       (current-buffer))))
        (locations (append (mapcar 'caar torus-meta-index)
                           (mapcar 'caar torus-index))))
    (member filename locations)))

(defun torus--roll-backups (filename)
  "Roll backups of FILENAME."
  (unless (stringp filename)
    (error "Function torus--roll-backups : wrong type argument"))
  (let ((file-list (list filename))
        (file-src)
        (file-dest))
    (dolist (iter (number-sequence 1 torus-backup-number))
      (push (concat filename "." (prin1-to-string iter)) file-list))
    (while (> (length file-list) 1)
      (setq file-dest (pop file-list))
      (setq file-src (car file-list))
      (when (> torus-verbosity 2)
        (message "files %s %s" file-src file-dest))
      (when (and file-src (file-exists-p file-src))
        (when (> torus-verbosity 2)
          (message "copy %s -> %s" file-src file-dest))
        (copy-file file-src file-dest t)))))

;;; Build
;;; ------------

(defun torus--build-index ()
  "Build `torus-index'."
  (setq torus-index nil)
  (dolist (circle torus-torus)
    (dolist (location (cdr circle))
      (let ((location-circle (cons location (car circle))))
        (unless (member location-circle torus-index)
          (push location-circle torus-index)))))
  (setq torus-index (reverse torus-index)))

(defun torus--build-meta-index ()
  "Build `torus-meta-index'."
  (setq torus-meta-index nil)
  (let ((torus-name)
        (torus)
        (circle-torus)
        (index-entry))
    (dolist (elem torus-meta)
      (setq torus-name (car elem))
      (setq torus (cdr (assoc "torus" elem)))
      (dolist (circle torus)
        (setq circle-torus (cons (car circle) torus-name))
        (dolist (location (cdr circle))
          (setq index-entry (cons location circle-torus))
          (unless (member index-entry torus-meta-index)
            (push index-entry torus-meta-index))))))
  (setq torus-meta-index (reverse torus-meta-index)))

;;; Updates
;;; ------------

(defun torus--update-history ()
  "Add current location to `torus-history'."
  (when (and torus-torus
             (listp torus-torus)
             (car torus-torus)
             (listp (car torus-torus))
             (> (length (car torus-torus)) 1))
    (let* ((circle (car torus-torus))
           (circle-name (car circle))
           (location (car (cdr circle)))
           (location-circle (cons location circle-name)))
      (push location-circle torus-history)
      (delete-dups torus-history)
      (setq torus-history
            (cl-subseq torus-history 0
                       (min (length torus-history)
                            torus-history-maximum-elements))))))

(defun torus--update-meta-history ()
  "Add current location to `torus-meta-history'."
  (when (and torus-meta
             (listp torus-meta)
             (car torus-meta)
             (listp (car torus-meta))
             (> (length (car torus-meta)) 1))
    (let* ((circle (car torus-torus))
           (circle-name (car circle))
           (torus-name (caar torus-meta))
           (location (car (cdr circle)))
           (location-circle-torus (cons location
                                        (cons circle-name torus-name))))
      (when (> torus-verbosity 2)
        (message "Loc circ tor %s" location-circle-torus))
      (push location-circle-torus torus-meta-history)
      (delete-dups torus-meta-history)
      (setq torus-meta-history
            (cl-subseq torus-meta-history 0
                       (min (length torus-meta-history)
                            torus-history-maximum-elements))))))

(defun torus--update-position ()
  "Update position in current location.
Do nothing if file does not match current buffer."
  (when (and torus-torus
             (listp torus-torus)
             (car torus-torus)
             (listp (car torus-torus))
             (> (length (car torus-torus)) 1))
    (let* ((torus-name (caar torus-meta))
           (circle-name (caar torus-torus))
           (circle-torus (cons circle-name torus-name))
           (old-location (car (cdr (car torus-torus))))
           (old-here (cdr old-location))
           (old-location-circle (cons old-location circle-name))
           (old-location-circle-torus (cons old-location circle-torus))
           (file (car old-location))
           (here (point))
           (marker (point-marker))
           (line-col (cons (line-number-at-pos) (current-column)))
           (new-location (cons file here))
           (new-location-circle (cons new-location circle-name))
           (new-location-circle-torus (cons new-location circle-torus))
           (new-location-line-col (cons new-location line-col))
           (new-location-marker (cons new-location marker)))
      (when (> torus-verbosity 2)
        (message "Update position -->")
        (message "here old : %s %s" here old-here)
        (message "old-location : %s" old-location)
        (message "loc history : %s" (caar torus-history))
        (message "loc meta history : %s" (caar torus-meta-history))
        (message "assoc index : %s" (assoc old-location torus-index))
        (message "assoc meta index : %s" (assoc old-location torus-meta-index)))
      (when (and (equal file (buffer-file-name (current-buffer)))
                 (equal old-location (caar torus-history))
                 (equal old-location (caar torus-meta-history))
                 (not (equal here old-here)))
        (when (> torus-verbosity 2)
          (message "Old location : %s" old-location)
          (message "New location : %s" new-location))
        (setcar (cdr (car torus-torus)) new-location)
        (if (member old-location-circle torus-index)
            (setcar (member old-location-circle torus-index)
                    new-location-circle)
          (torus--build-index))
        (if (member old-location-circle-torus torus-meta-index)
            (setcar (member old-location-circle-torus torus-meta-index)
                    new-location-circle-torus)
          (torus--build-meta-index))
        (if (member old-location-circle torus-history)
            (setcar (member old-location-circle torus-history)
                    new-location-circle)
          (torus--update-history))
        (if (member old-location-circle-torus torus-meta-history)
            (setcar (member old-location-circle-torus torus-meta-history)
                    new-location-circle-torus)
          (torus--update-meta-history))
        (if (assoc old-location torus-line-col)
            (progn
              (setcdr (assoc old-location torus-line-col) line-col)
              (setcar (assoc old-location torus-line-col) new-location))
          (push new-location-line-col torus-line-col))
        (if (assoc old-location torus-markers)
            (progn
              (setcdr (assoc old-location torus-markers) marker)
              (setcar (assoc old-location torus-markers) new-location))
          (push new-location-marker torus-markers))))))

(defun torus--update-layout ()
  "Fill `torus-layout' from missing elements. Delete useless ones."
  (let ((circles (mapcar #'car torus-torus)))
    (dolist (elem circles)
      (unless (assoc elem torus-layout)
        (push (cons elem ?m) torus-layout)))
    (dolist (elem torus-layout)
      (unless (member (car elem) circles)
        (setq torus-layout (torus--assoc-delete-all (car elem) torus-layout))))
    (setq torus-layout (reverse torus-layout))))

(defun torus--apply-or-fill-layout ()
  "Apply layout of current circle, or add default is not present."
  (let ((circle-name (caar torus-torus)))
    (if (consp (assoc circle-name torus-layout))
        (torus-layout-menu (cdr (assoc (caar torus-torus) torus-layout)))
      (push (cons circle-name ?m) torus-layout))))

(defun torus--update-input-history (name)
  "Add NAME to `torus-input-history' if not already there."
  (push name torus-input-history)
  (delete-dups torus-input-history)
  (setq torus-input-history
        (cl-subseq torus-input-history 0
                   (min (length torus-input-history)
                        torus-history-maximum-elements))))

(defun torus--update-meta ()
  "Update current torus in `torus-meta'."
  (torus--update-position)
  (when torus-meta
    (let ((entry (cdar torus-meta)))
      (if (equal '("torus" "history" "layout" "input history")
                 (mapcar 'car entry))
          (progn
            (if (assoc "input history" entry)
                (setcdr (assoc "input history" (cdar torus-meta)) (cl-copy-seq torus-input-history))
              (push (cons "input history" torus-input-history) (cdar torus-meta)))
            (if (assoc "layout" entry)
                (setcdr (assoc "layout" (cdar torus-meta)) (copy-tree torus-layout))
              (push (cons "layout" torus-layout) (cdar torus-meta)))
            (if (assoc "history" entry)
                (setcdr (assoc "history" (cdar torus-meta)) (copy-tree torus-history))
              (push (cons "history" torus-history) (cdar torus-meta)))
            (if (assoc "torus" entry)
                (setcdr (assoc "torus" (cdar torus-meta)) (copy-tree torus-torus))
              (push (cons "torus" torus-torus) (cdar torus-meta))))
        ;; Reordering if needed
        (push (cons "input history" torus-input-history) (cdar torus-meta))
        (push (cons "layout" torus-layout) (cdar torus-meta))
        (push (cons "history" torus-history) (cdar torus-meta))
        (push (cons "torus" torus-torus) (cdar torus-meta))
        (setf (cdar torus-meta) (cl-subseq (cdar torus-meta) 0 4))))))

(defun torus--update-from-meta ()
  "Update main torus variables from `torus-meta'."
  (when (and torus-meta
             (listp torus-meta)
             (listp (car torus-meta)))
    (let ((entry (cdr (car torus-meta))))
      (if (assoc "torus" entry)
          (setq torus-torus (copy-tree (cdr (assoc "torus" entry))))
        (setq torus-torus nil))
      (if (assoc "history" entry)
          (setq torus-history (copy-tree (cdr (assoc "history" entry))))
        (setq torus-history nil))
      (if (assoc "layout" entry)
          (setq torus-layout (copy-tree (cdr (assoc "layout" entry))))
        (setq torus-layout nil))
      (if (assoc "input history" entry)
          (setq torus-input-history (cl-copy-seq (cdr (assoc "input history" entry))))
        (setq torus-input-history nil)))))

(defun torus--jump ()
  "Jump to current location (buffer & position) in torus.
Add the location to `torus-markers' if not already present."
  (when (and torus-torus
             (listp torus-torus)
             (car torus-torus)
             (listp (car torus-torus))
             (> (length (car torus-torus)) 1))
    (let* ((location (car (cdr (car torus-torus))))
           (circle-name (caar torus-torus))
           (torus-name (caar torus-meta))
           (circle-torus (cons circle-name torus-name))
           (location-circle (cons location circle-name))
           (location-circle-torus (cons location circle-torus))
           (file (car location))
           (position (cdr location))
           (bookmark (cdr (assoc location torus-markers)))
           (buffer (when bookmark
                     (marker-buffer bookmark))))
      (if (and bookmark buffer (buffer-live-p buffer))
          (progn
            (when (> torus-verbosity 2)
              (message "Found %s in markers" bookmark))
            (when (not (equal buffer (current-buffer)))
              (switch-to-buffer buffer))
            (goto-char bookmark))
        (when (> torus-verbosity 2)
          (message "Found %s in torus" location))
        (when bookmark
          (setq torus-markers (torus--assoc-delete-all location torus-markers)))
        (if (file-exists-p file)
            (progn
              (when (> torus-verbosity 1)
                (message "Opening file %s at %s" file position))
              (find-file file)
              (goto-char position)
              (push (cons location (point-marker)) torus-markers))
          (message (format torus--message-file-does-not-exist file))
          (setcdr (car torus-torus) (cl-remove location (cdr (car torus-torus))))
          (setq torus-line-col (torus--assoc-delete-all location torus-line-col))
          (setq torus-markers (torus--assoc-delete-all location torus-markers))
          (setq torus-index (cl-remove location-circle torus-index))
          (setq torus-meta-index (cl-remove location-circle-torus torus-meta-index))
          (setq torus-history (cl-remove location-circle torus-history))
          (setq torus-meta-history (cl-remove location-circle-torus torus-meta-history))))
      (torus--update-history)
      (torus--update-meta-history)
      (torus--tab-bar))
    (recenter)))

;;; Switch
;;; ------------

(defun torus--switch (location-circle)
  "Jump to circle and location countained in LOCATION-CIRCLE."
  (unless (and location-circle
               (consp location-circle)
               (consp (car location-circle)))
    (error "Function torus--switch : wrong type argument"))
  (torus--update-position)
  (let* ((circle-name (cdr location-circle))
         (circle (assoc circle-name torus-torus))
         (index (cl-position circle torus-torus :test #'equal))
         (before (cl-subseq torus-torus 0 index))
         (after (cl-subseq torus-torus index)))
    (if index
        (setq torus-torus (append after before))
      (message "Circle not found.")))
  (let* ((circle (cdr (car torus-torus)))
         (location (car location-circle))
         (index (cl-position location circle :test #'equal))
         (before (cl-subseq circle 0 index))
         (after (cl-subseq circle index)))
    (if index
        (setcdr (car torus-torus) (append after before))
      (message "Location not found.")))
  (torus--jump)
  (torus--apply-or-fill-layout))

(defun torus--meta-switch (location-circle-torus)
  "Jump to torus, circle and location countained in LOCATION-CIRCLE-TORUS."
  (unless (and location-circle-torus
               (consp location-circle-torus)
               (consp (car location-circle-torus))
               (consp (cdr location-circle-torus)))
    (error "Function torus--switch : wrong type argument"))
  (when (> torus-verbosity 2)
    (message "meta switch : location-circle-torus : %s" location-circle-torus))
  (torus--update-meta)
  (let* ((torus-name (cdr (cdr location-circle-torus)))
         (torus (assoc torus-name torus-meta))
         (index (cl-position torus torus-meta :test #'equal))
         (before (cl-subseq torus-meta 0 index))
         (after (cl-subseq torus-meta index)))
    (if index
        (setq torus-meta (append after before))
      (message "Torus not found.")))
  (torus--update-from-meta)
  (torus--build-index)
  (torus--build-meta-index)
  (torus--update-layout)
  (let* ((circle-name (car (cdr location-circle-torus)))
         (circle (assoc circle-name torus-torus))
         (index (cl-position circle torus-torus :test #'equal))
         (before (cl-subseq torus-torus 0 index))
         (after (cl-subseq torus-torus index)))
    (if index
        (setq torus-torus (append after before))
      (message "Circle not found.")))
  (let* ((circle (cdr (car torus-torus)))
         (location (car location-circle-torus))
         (index (cl-position location circle :test #'equal))
         (before (cl-subseq circle 0 index))
         (after (cl-subseq circle index)))
    (if index
        (setcdr (car torus-torus) (append after before))
      (message "Location not found.")))
  (torus--jump)
  (torus--apply-or-fill-layout))

;;; Windows
;;; ------------

(defsubst torus--windows ()
  "Windows displaying a torus buffer."
  (seq-filter (lambda (elem) (torus--inside-p (window-buffer elem)))
              (window-list)))

(defun torus--main-windows ()
  "Return main window of layout."
  (let* ((windows (torus--windows))
         (columns (mapcar #'window-text-width windows))
         (max-columns (when columns
                    (eval `(max ,@columns))))
         (widest)
         (lines)
         (max-lines)
         (biggest))
    (when windows
      (dolist (index (number-sequence 0 (1- (length windows))))
        (when (equal (nth index columns) max-columns)
          (push (nth index windows) widest)))
      (setq lines (mapcar #'window-text-height widest))
      (setq max-lines (eval `(max ,@lines)))
      (dolist (index (number-sequence 0 (1- (length widest))))
        (when (equal (nth index lines) max-lines)
          (push (nth index widest) biggest)))
      (when (> torus-verbosity 2)
        (message "toruw windows : %s" windows)
        (message "columns : %s" columns)
        (message "max-columns : %s" max-columns)
        (message "widest : %s" widest)
        (message "lines : %s" lines)
        (message "max-line : %s" max-lines)
        (message "biggest : %s" biggest))
      biggest)))

(defun torus--prefix-argument-split (prefix)
  "Handle prefix argument PREFIX. Used to split."
  (pcase prefix
   ('(4)
    (split-window-below)
    (other-window 1))
   ('(16)
    (split-window-right)
    (other-window 1))))

;;; Tab bar
;;; ------------

(defun torus--eval-tab ()
  "Build tab bar."
  (when torus-meta
      (let*
          ((locations (mapcar #'torus--short (cdar torus-torus)))
           (tab-string))
        (setq tab-string
              (propertize (format (concat " %s"
                                          torus-separator-torus-circle)
                                  (caar torus-meta))
                          'keymap torus-map-mouse-torus))
        (setq tab-string
              (concat tab-string
                      (propertize (format (concat "%s"
                                                  torus-separator-circle-location)
                                          (caar torus-torus))
                                  'keymap torus-map-mouse-circle)))
        (dolist (filepos locations)
          (setq tab-string
                (concat tab-string (propertize filepos
                                               'keymap torus-map-mouse-location)))
          (setq tab-string (concat tab-string torus-location-separator)))
        tab-string)))

(defun torus--tab-bar ()
  "Display tab bar."
  (let* ((main-windows (torus--main-windows))
         (current-window (selected-window))
         (buffer (current-buffer))
         (original (assoc buffer torus-original-header-lines))
         (eval-tab '(:eval (torus--eval-tab))))
    (when (> torus-verbosity 2)
      (pp torus-original-header-lines)
      (message "original : %s" original)
      (message "cdr original : %s" (cdr original)))
    (if (and torus-display-tab-bar
             (member current-window main-windows))
        (progn
          (unless original
            (push (cons buffer header-line-format)
                  torus-original-header-lines))
          (unless (equal header-line-format eval-tab)
            (when (> torus-verbosity 2)
              (message "Set :eval in header-line-format."))
            (setq header-line-format eval-tab)))
      (when original
        (setq header-line-format (cdr original))
        (setq torus-original-header-lines
              (torus--assoc-delete-all buffer
                                       torus-original-header-lines)))
      (message (torus--dashboard)))))

;;; Hooks & Advices
;;; ------------------------------

;;;###autoload
(defun torus-quit ()
  "Write torus before quit."
  (when torus-save-on-exit
    (if torus-autowrite-file
        (torus-write torus-autowrite-file)
      (when (y-or-n-p "Write torus ? ")
        (call-interactively 'torus-write))))
  ;; To be sure they will be nil at startup, even if some plugin saved
  ;; global variables
  (torus-reset-menu ?a))

;;;###autoload
(defun torus-start ()
  "Read torus on startup."
  (when torus-load-on-startup
    (if torus-autoread-file
        (torus-read torus-autoread-file)
      (message "Set torus-autoread-file if you want to load it."))))

;;;###autoload
(defun torus-after-save-torus-file ()
  "Ask whether to read torus file after edition."
  (let* ((filename (buffer-file-name (current-buffer)))
         (directory (file-name-directory filename))
         (torus-dir (expand-file-name (file-name-as-directory torus-dirname))))
    (when (> torus-verbosity 2)
      (message "filename : %s" filename)
      (message "filename directory : %s" directory)
      (message "torus directory : %s" torus-dir))
    (when (equal directory torus-dir)
      (when (y-or-n-p "Apply changes to current torus variables ? ")
        (torus-read filename)))))

;;;###autoload
(defun torus-advice-switch-buffer (&rest args)
  "Advice to `switch-to-buffer'. ARGS are irrelevant."
  (when (> torus-verbosity 2)
    (message "Advice called with args %s" args))
  (when (and torus-torus (torus--inside-p))
    (torus--update-position)))

;;; Commands
;;; ------------------------------

;;;###autoload
(defun torus-init ()
  "Initialize torus. Add hooks and advices.
Create `torus-dirname' if needed."
  (interactive)
  (add-hook 'emacs-startup-hook 'torus-start)
  (add-hook 'kill-emacs-hook 'torus-quit)
  (add-hook 'after-save-hook 'torus-after-save-torus-file)
  (advice-add #'switch-to-buffer :before #'torus-advice-switch-buffer)
  (unless (file-exists-p torus-dirname)
    (make-directory torus-dirname)))

;;;###autoload
(defun torus-install-default-bindings ()
  "Install default keybindings."
  (interactive)
  ;; Keymap
  (if (stringp torus-prefix-key)
      (global-set-key (kbd torus-prefix-key) 'torus-map)
    (global-set-key torus-prefix-key 'torus-map))
  (when (>= torus-binding-level 0)
    (define-key torus-map (kbd "i") 'torus-info)
    (define-key torus-map (kbd "c") 'torus-add-circle)
    (define-key torus-map (kbd "l") 'torus-add-location)
    (define-key torus-map (kbd "f") 'torus-add-file)
    (define-key torus-map (kbd "+") 'torus-add-torus)
    (define-key torus-map (kbd "*") 'torus-add-copy-of-torus)
    (define-key torus-map (kbd "<left>") 'torus-previous-circle)
    (define-key torus-map (kbd "<right>") 'torus-next-circle)
    (define-key torus-map (kbd "<up>") 'torus-previous-location)
    (define-key torus-map (kbd "<down>") 'torus-next-location)
    (define-key torus-map (kbd "C-p") 'torus-previous-torus)
    (define-key torus-map (kbd "C-n") 'torus-next-torus)
    (define-key torus-map (kbd "SPC") 'torus-switch-circle)
    (define-key torus-map (kbd "=") 'torus-switch-location)
    (define-key torus-map (kbd "@") 'torus-switch-torus)
    (define-key torus-map (kbd "s") 'torus-search)
    (define-key torus-map (kbd "S") 'torus-meta-search)
    (define-key torus-map (kbd "d") 'torus-delete-location)
    (define-key torus-map (kbd "D") 'torus-delete-circle)
    (define-key torus-map (kbd "-") 'torus-delete-torus)
    (define-key torus-map (kbd "r") 'torus-read)
    (define-key torus-map (kbd "w") 'torus-write)
    (define-key torus-map (kbd "e") 'torus-edit))
  (when (>= torus-binding-level 1)
    (define-key torus-map (kbd "<next>") 'torus-history-older)
    (define-key torus-map (kbd "<prior>") 'torus-history-newer)
    (define-key torus-map (kbd "h") 'torus-search-history)
    (define-key torus-map (kbd "H") 'torus-search-meta-history)
    (define-key torus-map (kbd "a") 'torus-alternate-menu)
    (define-key torus-map (kbd "^") 'torus-alternate-in-same-torus)
    (define-key torus-map (kbd "<") 'torus-alternate-circles)
    (define-key torus-map (kbd ">") 'torus-alternate-in-same-circle)
    (define-key torus-map (kbd "n") 'torus-rename-circle)
    (define-key torus-map (kbd "N") 'torus-rename-torus)
    (define-key torus-map (kbd "m") 'torus-move-location)
    (define-key torus-map (kbd "M") 'torus-move-circle)
    (define-key torus-map (kbd "M-m") 'torus-move-torus)
    (define-key torus-map (kbd "v") 'torus-move-location-to-circle)
    (define-key torus-map (kbd "V") 'torus-move-circle-to-torus)
    (define-key torus-map (kbd "y") 'torus-copy-location-to-circle)
    (define-key torus-map (kbd "Y") 'torus-copy-circle-to-torus)
    (define-key torus-map (kbd "j") 'torus-join-circles)
    (define-key torus-map (kbd "J") 'torus-join-toruses)
    (define-key torus-map (kbd "#") 'torus-layout-menu))
  (when (>= torus-binding-level 2)
    (define-key torus-map (kbd "o") 'torus-reverse-menu)
    (define-key torus-map (kbd ":") 'torus-prefix-circles-of-current-torus)
    (define-key torus-map (kbd "g") 'torus-autogroup-menu)
    (define-key torus-map (kbd "!") 'torus-batch-menu))
  (when (>= torus-binding-level 3)
    (define-key torus-map (kbd "p") 'torus-print-menu)
    (define-key torus-map (kbd "z") 'torus-reset-menu)
    (define-key torus-map (kbd "C-d") 'torus-delete-current-location)
    (define-key torus-map (kbd "M-d") 'torus-delete-current-circle))
  ;; Mouse
  (define-key torus-map-mouse-torus [header-line mouse-1] 'torus-switch-torus)
  (define-key torus-map-mouse-torus [header-line mouse-2] 'torus-alternate-toruses)
  (define-key torus-map-mouse-torus [header-line mouse-3] 'torus-meta-search)
  (define-key torus-map-mouse-torus [header-line mouse-4] 'torus-previous-torus)
  (define-key torus-map-mouse-torus [header-line mouse-5] 'torus-next-torus)
  (define-key torus-map-mouse-circle [header-line mouse-1] 'torus-switch-circle)
  (define-key torus-map-mouse-circle [header-line mouse-2] 'torus-alternate-circles)
  (define-key torus-map-mouse-circle [header-line mouse-3] 'torus-search)
  (define-key torus-map-mouse-circle [header-line mouse-4] 'torus-previous-circle)
  (define-key torus-map-mouse-circle [header-line mouse-5] 'torus-next-circle)
  (define-key torus-map-mouse-location [header-line mouse-1] 'torus-tab-mouse)
  (define-key torus-map-mouse-location [header-line mouse-2] 'torus-alternate-in-meta)
  (define-key torus-map-mouse-location [header-line mouse-3] 'torus-switch-location)
  (define-key torus-map-mouse-location [header-line mouse-4] 'torus-previous-location)
  (define-key torus-map-mouse-location [header-line mouse-5] 'torus-next-location))

;;;###autoload
(defun torus-reset-menu (choice)
  "Reset CHOICE variables to nil."
  (interactive
   (list (read-key torus--message-reset-choice)))
  (let ((varlist))
    (pcase choice
      (?m (push 'torus-meta varlist))
      (?t (push 'torus-torus varlist))
      (?h (push 'torus-history varlist))
      (?H (push 'torus-meta-history varlist))
      (?l (push 'torus-layout varlist))
      (?n (push 'torus-input-history varlist))
      (?i (push 'torus-index varlist))
      (?I (push 'torus-meta-index varlist))
      (?p (push 'torus-line-col varlist))
      (?\^m (push 'torus-markers varlist))
      (?o (push 'torus-original-header-lines varlist))
      (?a (setq varlist (list 'torus-meta
                              'torus-torus
                              'torus-history
                              'torus-meta-history
                              'torus-layout
                              'torus-input-history
                              'torus-index
                              'torus-meta-index
                              'torus-line-col
                              'torus-markers
                              'torus-original-header-lines)))
      (?\a (message "Reset cancelled by Ctrl-G."))
      (_ (message "Invalid key.")))
    (dolist (var varlist)
      (when (> torus-verbosity 1)
        (message "%s -> nil" (symbol-name var)))
      (set var nil))))

;;; Print
;;; ------------

;;;###autoload
(defun torus-info ()
  "Print local info : circle name and locations."
  (interactive)
  (message (torus--dashboard)))

;;;###autoload
(defun torus-print-menu (choice)
  "Print CHOICE variables."
  (interactive
   (list (read-key torus--message-print-choice)))
  (let ((varlist)
        (window (view-echo-area-messages)))
    (pcase choice
      (?m (push 'torus-meta varlist))
      (?t (push 'torus-torus varlist))
      (?h (push 'torus-history varlist))
      (?H (push 'torus-meta-history varlist))
      (?l (push 'torus-layout varlist))
      (?n (push 'torus-input-history varlist))
      (?i (push 'torus-index varlist))
      (?I (push 'torus-meta-index varlist))
      (?p (push 'torus-line-col varlist))
      (?\^m (push 'torus-markers varlist))
      (?o (push 'torus-original-header-lines varlist))
      (?a (setq varlist (list 'torus-meta
                              'torus-torus
                              'torus-index
                              'torus-history
                              'torus-meta-history
                              'torus-layout
                              'torus-input-history
                              'torus-line-col
                              'torus-markers
                              'torus-original-header-lines)))
      (?\a (delete-window window)
           (message "Print cancelled by Ctrl-G."))
      (_ (message "Invalid key.")))
    (dolist (var varlist)
      (message "%s" (symbol-name var))
      (pp (symbol-value var)))))

;;; Add
;;; ------------

;;;###autoload
(defun torus-add-circle (circle-name)
  "Add a new circle CIRCLE-NAME to torus."
  (interactive
   (list
    (read-string "Name of the new circle : "
                 nil
                 'torus-input-history)))
  (unless (stringp circle-name)
    (error "Function torus-add-circle : wrong type argument"))
  (torus--update-input-history circle-name)
  (let ((torus-name (car (car torus-meta))))
    (if (assoc circle-name torus-torus)
        (message "Circle %s already exists in torus" circle-name)
      (message "Adding circle %s to torus %s" circle-name torus-name)
      (push (list circle-name) torus-torus)
      (push (cons circle-name ?m) torus-layout))))

;;;###autoload
(defun torus-add-location ()
  "Add current file and point to current circle."
  (interactive)
  (unless torus-meta
    (when (y-or-n-p "Meta Torus is empty. Do you want to add a first torus ? ")
      (call-interactively 'torus-add-torus)))
  (unless torus-torus
    (when (y-or-n-p "Torus is empty. Do you want to add a first circle ? ")
      (call-interactively 'torus-add-circle)))
  (if (and torus-meta
           torus-torus)
      (if (buffer-file-name)
          (let* ((circle (car torus-torus))
                 (pointmark (point-marker))
                 (location (cons (buffer-file-name)
                                 (marker-position pointmark)))
                 (location-marker (cons location pointmark))
                 (location-circle (cons location (car circle)))
                 (location-line-col (cons location
                                          (cons (line-number-at-pos)
                                                (current-column)))))
            (if (member location (cdr circle))
                (message torus--message-existent-location
                         (torus--concise location) (car circle))
              (message "Adding %s to circle %s" location (car circle))
              (if (> (length circle) 1)
                  (setcdr circle (append (list location) (cdr circle)))
                (setf circle (append circle (list location))))
              (setf (car torus-torus) circle)
              (unless (member location-circle torus-index)
                (push location-circle torus-index))
              (torus--update-history)
              (torus--update-meta-history)
              (unless (member location-line-col torus-line-col)
                (push location-line-col torus-line-col))
              (unless (member location-marker torus-markers)
                (push location-marker torus-markers))
              (torus--tab-bar)))
        (message "Buffer must have a filename to be added to the torus."))
    (message "Please add at least a first torus and a first circle.")))

;;;###autoload
(defun torus-add-file (filename)
  "Add FILENAME to the current circle.
The location added will be (file . 1)."
  (interactive (list (read-file-name "File to add : ")))
  (if (file-exists-p filename)
      (progn
        (find-file filename)
        (torus-add-location))
    (message "File %s does not exist." filename)))

;;;###autoload
(defun torus-add-torus (torus-name)
  "Create a new torus named TORUS-NAME."
  (interactive
   (list (read-string "Name of the new torus : "
                      nil
                      'torus-input-history)))
  (torus--update-meta)
  (setq torus-torus nil)
  (setq torus-history nil)
  (setq torus-layout nil)
  (setq torus-input-history nil)
  (push (list torus-name) torus-meta)
  (push (list "input history") (cdr (car torus-meta)))
  (push (list "layout") (cdr (car torus-meta)))
  (push (list "history") (cdr (car torus-meta)))
  (push (list "torus") (cdr (car torus-meta))))

;;;###autoload
(defun torus-add-copy-of-torus (torus-name)
  "Create a new torus named TORUS-NAME as copy of the current torus."
  (interactive
   (list (read-string "Name of the new torus : "
                      nil
                      'torus-input-history)))
  (torus--update-meta)
  (if (and torus-torus torus-history torus-input-history)
      (progn
        (torus--update-input-history torus-name)
        (if (assoc torus-name torus-meta)
            (message "Torus %s already exists in torus-meta" torus-name)
          (message "Creating torus %s" torus-name)
          (push (list torus-name) torus-meta)
          (push (cons "input history" torus-input-history) (cdr (car torus-meta)))
          (push (cons "layout" torus-layout) (cdr (car torus-meta)))
          (push (cons "history" torus-history) (cdr (car torus-meta)))
          (push (cons "torus" torus-torus) (cdr (car torus-meta)))))
    (message "Cannot create an empty torus. Please add at least a location.")))

;;; Navigate
;;; ------------

;;;###autoload
(defun torus-previous-circle ()
  "Jump to the previous circle."
  (interactive)
  (if torus-torus
      (if (> (length torus-torus) 1)
          (progn
            (torus--prefix-argument-split current-prefix-arg)
            (torus--update-position)
            (setf torus-torus (append (last torus-torus) (butlast torus-torus)))
            (torus--jump)
            (torus--apply-or-fill-layout))
        (message "Only one circle in torus."))
    (message torus--message-empty-torus)))

;;;###autoload
(defun torus-next-circle ()
  "Jump to the next circle."
  (interactive)
  (if torus-torus
      (if (> (length torus-torus) 1)
          (progn
            (torus--prefix-argument-split current-prefix-arg)
            (torus--update-position)
            (setf torus-torus (append (cdr torus-torus) (list (car torus-torus))))
            (torus--jump)
            (torus--apply-or-fill-layout))
        (message "Only one circle in torus."))
    (message torus--message-empty-torus)))

;;;###autoload
(defun torus-previous-location ()
  "Jump to the previous location."
  (interactive)
  (if torus-torus
      (if (> (length (car torus-torus)) 1)
          (let ((circle (cdr (car torus-torus))))
            (torus--prefix-argument-split current-prefix-arg)
            (torus--update-position)
            (setf circle (append (last circle) (butlast circle)))
            (setcdr (car torus-torus) circle)
            (torus--jump))
        (message torus--message-empty-circle (car (car torus-torus))))
    (message torus--message-empty-torus)))

;;;###autoload
(defun torus-next-location ()
  "Jump to the next location."
  (interactive)
  (if torus-torus
      (if (> (length (car torus-torus)) 1)
          (let ((circle (cdr (car torus-torus))))
            (torus--prefix-argument-split current-prefix-arg)
            (torus--update-position)
            (setf circle (append (cdr circle) (list (car circle))))
            (setcdr (car torus-torus) circle)
            (torus--jump))
        (message torus--message-empty-circle (car (car torus-torus))))
    (message torus--message-empty-torus)))

;;;###autoload
(defun torus-previous-torus ()
  "Jump to the previous torus."
  (interactive)
  (if torus-meta
      (if (> (length torus-meta) 1)
          (progn
            (torus--prefix-argument-split current-prefix-arg)
            (torus--update-meta)
            (setf torus-meta (append (last torus-meta) (butlast torus-meta)))
            (torus--update-from-meta)
            (torus--build-index)
            (torus--build-meta-index)
            (torus--update-layout)
            (torus--jump)
            (torus--apply-or-fill-layout))
        (message "Only one torus in meta."))
    (message torus--message-empty-meta)))

;;;###autoload
(defun torus-next-torus ()
  "Jump to the next torus."
  (interactive)
  (if torus-meta
      (if (> (length torus-meta) 1)
          (progn
            (torus--prefix-argument-split current-prefix-arg)
            (torus--update-meta)
            (setf torus-meta (append (cdr torus-meta) (list (car torus-meta))))
            (torus--update-from-meta)
            (torus--build-index)
            (torus--build-meta-index)
            (torus--update-layout)
            (torus--jump)
            (torus--apply-or-fill-layout))
        (message "Only one torus in meta."))
    (message torus--message-empty-meta)))

;;;###autoload
(defun torus-switch-circle (circle-name)
  "Jump to CIRCLE-NAME circle.
With prefix argument \\[universal-argument], open the buffer in a
horizontal split.
With prefix argument \\[universal-argument] \\[universal-argument], open the
buffer in a vertical split."
  (interactive
   (list (completing-read
          "Go to circle : "
          (mapcar #'car torus-torus) nil t)))
  (torus--prefix-argument-split current-prefix-arg)
  (torus--update-position)
  (let* ((circle (assoc circle-name torus-torus))
         (index (cl-position circle torus-torus :test #'equal))
         (before (cl-subseq torus-torus 0 index))
         (after (cl-subseq torus-torus index)))
    (setq torus-torus (append after before)))
  (torus--jump)
  (torus--apply-or-fill-layout))

;;;###autoload
(defun torus-switch-location (location-name)
  "Jump to LOCATION-NAME location.
With prefix argument \\[universal-argument], open the buffer in a
horizontal split.
With prefix argument \\[universal-argument] \\[universal-argument], open the
buffer in a vertical split."
  (interactive
   (list
    (completing-read
     "Go to location : "
     (mapcar #'torus--concise (cdr (car torus-torus))) nil t)))
  (torus--prefix-argument-split current-prefix-arg)
  (torus--update-position)
  (let* ((circle (cdr (car torus-torus)))
         (index (cl-position location-name circle
                          :test #'torus--equal-concise-p))
         (before (cl-subseq circle 0 index))
         (after (cl-subseq circle index)))
    (setcdr (car torus-torus) (append after before)))
  (torus--jump))

;;;###autoload
(defun torus-switch-torus (torus-name)
  "Jump to TORUS-NAME torus.
With prefix argument \\[universal-argument], open the buffer in a
horizontal split.
With prefix argument \\[universal-argument] \\[universal-argument], open the
buffer in a vertical split."
  (interactive
   (list (completing-read
          "Go to torus : "
          (mapcar #'car torus-meta) nil t)))
  (torus--prefix-argument-split current-prefix-arg)
  (torus--update-meta)
  (let* ((torus (assoc torus-name torus-meta))
         (index (cl-position torus torus-meta :test #'equal))
         (before (cl-subseq torus-meta 0 index))
         (after (cl-subseq torus-meta index)))
    (if index
        (setq torus-meta (append after before))
      (message "Torus not found.")))
  (torus--update-from-meta)
  (torus--build-index)
  (torus--build-meta-index)
  (torus--update-layout)
  (torus--jump)
  (torus--apply-or-fill-layout))

;;; Search
;;; ------------

;;;###autoload
(defun torus-search (location-name)
  "Search LOCATION-NAME in the torus.
Go to the first matching circle and location."
  (interactive
   (list
    (completing-read
     "Search location in torus : "
     (mapcar #'torus--concise torus-index) nil t)))
  (torus--prefix-argument-split current-prefix-arg)
  (let* ((location-circle
          (cl-find
           location-name torus-index
           :test #'torus--equal-concise-p)))
    (torus--switch location-circle)))


;;;###autoload
(defun torus-meta-search (location-name)
  "Search LOCATION-NAME in the torus.
Go to the first matching torus, circle and location."
  (interactive
   (list
    (completing-read
     "Search location in torus : "
     (mapcar #'torus--concise torus-meta-index) nil t)))
  (torus--prefix-argument-split current-prefix-arg)
  (let* ((location-circle-torus
          (cl-find
           location-name torus-meta-index
           :test #'torus--equal-concise-p)))
    (torus--meta-switch location-circle-torus)))

;;; History
;;; ------------

;;;###autoload
(defun torus-history-newer ()
  "Go to newer location in history."
  (interactive)
  (if torus-torus
      (progn
        (torus--prefix-argument-split current-prefix-arg)
        (if torus-history
            (progn
              (setq torus-history (append (last torus-history) (butlast torus-history)))
              (torus--switch (car torus-history)))
          (message "History is empty.")))
    (message torus--message-empty-torus)))

;;;###autoload
(defun torus-history-older ()
  "Go to older location in history."
  (interactive)
  (if torus-torus
      (progn
        (torus--prefix-argument-split current-prefix-arg)
        (if torus-history
            (progn
              (setq torus-history (append (cdr torus-history) (list (car torus-history))))
              (torus--switch (car torus-history)))
          (message "History is empty.")))
    (message torus--message-empty-torus)))

;;;###autoload
(defun torus-search-history (location-name)
  "Search LOCATION-NAME in `torus-history'."
  (interactive
   (list
    (completing-read
     "Search location in history : "
     (mapcar #'torus--concise torus-history) nil t)))
  (torus--prefix-argument-split current-prefix-arg)
  (when torus-history
    (let* ((index (cl-position location-name torus-history
                            :test #'torus--equal-concise-p))
           (before (cl-subseq torus-history 0 index))
           (element (nth index torus-history))
           (after (cl-subseq torus-history (1+ index))))
      (setq torus-history (append (list element) before after)))
    (torus--switch (car torus-history))))

;;;###autoload
(defun torus-search-meta-history (location-name)
  "Search LOCATION-NAME in `torus-meta-history'."
  (interactive
   (list
    (completing-read
     "Search location in history : "
     (mapcar #'torus--concise torus-meta-history) nil t)))
  (torus--prefix-argument-split current-prefix-arg)
  (when torus-meta-history
    (let* ((index (cl-position location-name torus-meta-history
                            :test #'torus--equal-concise-p))
           (before (cl-subseq torus-meta-history 0 index))
           (element (nth index torus-meta-history))
           (after (cl-subseq torus-meta-history (1+ index))))
      (setq torus-meta-history (append (list element) before after)))
    (torus--meta-switch (car torus-meta-history))))

;;; Alternate
;;; ------------

;;;###autoload
(defun torus-alternate-in-meta ()
  "Alternate last two locations in meta history.
If outside the torus, just return inside, to the last torus location."
  (interactive)
  (if torus-meta
      (progn
        (torus--prefix-argument-split current-prefix-arg)
        (if (torus--inside-p)
            (if (and torus-meta-history
                     (>= (length torus-meta-history) 2))
                (progn
                  (torus--update-meta)
                  (setq torus-meta-history (append (list (car (cdr torus-meta-history)))
                                                   (list (car torus-meta-history))
                                                   (nthcdr 2 torus-meta-history)))
                  (torus--meta-switch (car torus-meta-history)))
              (message "Meta history has less than two elements."))
          (torus--jump)))
    (message torus--message-empty-meta)))

;;;###autoload
(defun torus-alternate-in-same-torus ()
  "Alternate last two locations in history belonging to the current circle.
If outside the torus, just return inside, to the last torus location."
  (interactive)
  (if torus-torus
      (progn
        (torus--prefix-argument-split current-prefix-arg)
        (if (torus--inside-p)
            (if (and torus-history
                     (>= (length torus-history) 2))
                (progn
                  (torus--update-meta)
                  (setq torus-history (append (list (car (cdr torus-history)))
                                              (list (car torus-history))
                                              (nthcdr 2 torus-history)))
                  (torus--switch (car torus-history)))
              (message "History has less than two elements."))
          (torus--jump)))
    (message torus--message-empty-torus)))

;;;###autoload
(defun torus-alternate-in-same-circle ()
  "Alternate last two locations in history belonging to the current circle.
If outside the torus, just return inside, to the last torus location."
  (interactive)
  (if torus-torus
      (progn
        (torus--prefix-argument-split current-prefix-arg)
        (if (torus--inside-p)
            (if (and torus-history
                     (>= (length torus-history) 2))
                (progn
                  (torus--update-meta)
                  (let ((history torus-history)
                        (circle (car (car torus-torus)))
                        (element)
                        (location-circle))
                    (pop history)
                    (while (and (not location-circle) history)
                      (setq element (pop history))
                      (when (equal circle (cdr element))
                        (setq location-circle element)))
                    (if location-circle
                        (torus--switch location-circle)
                      (message "No alternate file in same circle in history."))))
              (message "History has less than two elements."))
          (torus--jump)))
    (message torus--message-empty-torus)))

;;;###autoload
(defun torus-alternate-toruses ()
  "Alternate last two toruses in meta history.
If outside the torus, just return inside, to the last torus location."
  (interactive)
  (if torus-meta
      (progn
        (torus--prefix-argument-split current-prefix-arg)
        (if (torus--inside-p)
            (if (and torus-meta-history
                     (>= (length torus-meta-history) 2))
                (progn
                  (torus--update-meta)
                  (let ((history torus-meta-history)
                        (torus (car (car torus-meta)))
                        (element)
                        (location-circle-torus))
                    (while (and (not location-circle-torus) history)
                      (setq element (pop history))
                      (when (not (equal torus (cddr element)))
                        (setq location-circle-torus element)))
                    (if location-circle-torus
                        (torus--meta-switch location-circle-torus)
                      (message "No alternate torus in history."))))
              (message "Meta History has less than two elements."))
          (torus--jump)))
    (message "Meta torus is empty.")))

;;;###autoload
(defun torus-alternate-circles ()
  "Alternate last two circles in history.
If outside the torus, just return inside, to the last torus location."
  (interactive)
  (if torus-torus
      (progn
        (torus--prefix-argument-split current-prefix-arg)
        (if (torus--inside-p)
            (if (and torus-history
                     (>= (length torus-history) 2))
                (progn
                  (torus--update-meta)
                  (let ((history torus-history)
                        (circle (car (car torus-torus)))
                        (element)
                        (location-circle))
                    (while (and (not location-circle) history)
                      (setq element (pop history))
                      (when (not (equal circle (cdr element)))
                        (setq location-circle element)))
                    (if location-circle
                        (torus--switch location-circle)
                      (message "No alternate circle in history."))))
              (message "History has less than two elements."))
          (torus--jump)))
    (message torus--message-empty-torus)))

;;;###autoload
(defun torus-alternate-menu (choice)
  "Alternate according to CHOICE."
  (interactive
   (list (read-key torus--message-alternate-choice)))
  (pcase choice
    (?m (funcall 'torus-alternate-in-meta))
    (?t (funcall 'torus-alternate-in-same-torus))
    (?c (funcall 'torus-alternate-in-same-circle))
    (?T (funcall 'torus-alternate-toruses))
    (?C (funcall 'torus-alternate-circles))
    (?\a (message "Alternate operation cancelled by Ctrl-G."))
    (_ (message "Invalid key."))))

;;; Rename
;;; ------------

;;;###autoload
(defun torus-rename-circle ()
  "Rename current circle."
  (interactive)
  (if torus-torus
      (let*
          ((old-name (car (car torus-torus)))
           (prompt (format "New name of circle %s : " old-name))
           (circle-name (read-string prompt nil 'torus-input-history)))
        (torus--update-input-history circle-name)
        (setcar (car torus-torus) circle-name)
        (dolist (location-circle torus-index)
          (when (equal (cdr location-circle) old-name)
            (setcdr location-circle circle-name)))
        (dolist (location-circle torus-history)
          (when (equal (cdr location-circle) old-name)
            (setcdr location-circle circle-name)))
        (dolist (location-circle-torus torus-meta-history)
          (when (equal (cadr location-circle-torus) old-name)
            (setcar (cdr location-circle-torus) circle-name)))
        (dolist (location-circle-torus torus-meta-index)
          (when (equal (cadr location-circle-torus) old-name)
            (setcar (cdr location-circle-torus) circle-name)))
        (message "Renamed circle %s -> %s" old-name circle-name))
    (message "Torus is empty. Please add a circle first with torus-add-circle.")))

;;;###autoload
(defun torus-rename-torus ()
  "Rename current torus."
  (interactive)
  (if torus-meta
      (let*
          ((old-name (car (car torus-meta)))
           (prompt (format "New name of torus %s : " old-name))
           (torus-name (read-string prompt nil 'torus-input-history)))
        (torus--update-input-history torus-name)
        (setcar (car torus-meta) torus-name)
        (message "Renamed torus %s -> %s" old-name torus-name))
    (message torus--message-empty-meta)))

;;; Move
;;; ------------

;;;###autoload
(defun torus-move-circle (circle-name)
  "Move current circle after CIRCLE-NAME."
  (interactive
   (list (completing-read
          "Move current circle after : "
          (mapcar #'car torus-torus) nil t)))
  (torus--update-position)
  (let* ((circle (assoc circle-name torus-torus))
         (index (1+ (cl-position circle torus-torus :test #'equal)))
         (current (list (car torus-torus)))
         (before (cl-subseq torus-torus 1 index))
         (after (cl-subseq torus-torus index)))
    (setq torus-torus (append before current after))
    (torus-switch-circle (caar current))))

;;;###autoload
(defun torus-move-location (location-name)
  "Move current location after LOCATION-NAME."
  (interactive
   (list
    (completing-read
     "Move current location after : "
     (mapcar #'torus--concise (cdr (car torus-torus))) nil t)))
  (torus--update-position)
  (let* ((circle (cdr (car torus-torus)))
         (index (1+ (cl-position location-name circle
                                 :test #'torus--equal-concise-p)))
         (current (list (car circle)))
         (before (cl-subseq circle 1 index))
         (after (cl-subseq circle index)))
    (setcdr (car torus-torus) (append before current after))
    (torus-switch-location (car current))))

;;;###autoload
(defun torus-move-torus (torus-name)
  "Move current torus after TORUS-NAME."
  (interactive
   (list (completing-read
          "Move current torus after : "
          (mapcar #'car torus-meta) nil t)))
  (torus--update-meta)
  (let* ((torus (assoc torus-name torus-meta))
         (index (1+ (cl-position torus torus-meta :test #'equal)))
         (current (copy-tree (list (car torus-meta))))
         (before (copy-tree (cl-subseq torus-meta 1 index)))
         (after (copy-tree (cl-subseq torus-meta index))))
    (setq torus-meta (append before current after))
    (torus--update-from-meta)
    (torus-switch-torus (caar current))))

;;;###autoload
(defun torus-move-location-to-circle (circle-name)
  "Move current location to CIRCLE-NAME."
  (interactive
   (list (completing-read
          "Move current location to circle : "
          (mapcar #'car torus-torus) nil t)))
  (torus--update-position)
  (let* ((location (car (cdr (car torus-torus))))
         (circle (cdr (assoc circle-name torus-torus)))
         (old-name (car (car torus-torus)))
         (old-pair (cons location old-name)))
    (if (member location circle)
        (message "Location %s already exists in circle %s."
                 (torus--concise location)
                 circle-name)
      (message "Moving location %s to circle %s."
               (torus--concise location)
               circle-name)
      (pop (cdar torus-torus))
      (setcdr (assoc circle-name torus-torus)
              (push location circle))
      (dolist (location-circle torus-index)
        (when (equal location-circle old-pair)
          (setcdr location-circle circle-name)))
      (dolist (location-circle torus-history)
        (when (equal location-circle old-pair)
          (setcdr location-circle circle-name)))
      (torus--jump))))


;;;###autoload
(defun torus-move-circle-to-torus (torus-name)
  "Move current circle to TORUS-NAME."
  (interactive
   (list (completing-read
          "Move current circle to torus : "
          (mapcar #'car torus-meta) nil t)))
  (torus--update-position)
  (let* ((circle (cl-copy-seq (car torus-torus)))
         (torus (copy-tree
                 (cdr (assoc "torus" (assoc torus-name torus-meta)))))
         (circle-name (car circle))
         (circle-torus (cons circle-name (caar torus-meta))))
    (if (member circle torus)
        (message "Circle %s already exists in torus %s."
                 circle-name
                 torus-name)
      (message "Moving circle %s to torus %s."
               circle-name
               torus-name)
      (when (> torus-verbosity 2)
        (message "circle-torus %s" circle-torus))
      (setcdr (assoc "torus" (assoc torus-name torus-meta))
              (push circle torus))
      (setq torus-torus (torus--assoc-delete-all circle-name torus-torus))
      (setq torus-index
            (torus--reverse-assoc-delete-all circle-name torus-index))
      (setq torus-history
            (torus--reverse-assoc-delete-all circle-name torus-history))
      (setq torus-markers
            (torus--reverse-assoc-delete-all circle-name torus-markers))
      (setq torus-meta-index
            (torus--reverse-assoc-delete-all circle-torus torus-meta-index))
      (setq torus-meta-history
            (torus--reverse-assoc-delete-all circle-torus torus-meta-history))
      (torus--build-index)
      (torus--build-meta-index)
      (torus--jump))))

;;;###autoload
(defun torus-copy-location-to-circle (circle-name)
  "Copy current location to CIRCLE-NAME."
  (interactive
   (list (completing-read
          "Copy current location to circle : "
          (mapcar #'car torus-torus) nil t)))
  (torus--update-position)
  (let* ((location (car (cdr (car torus-torus))))
         (circle (cdr (assoc circle-name torus-torus))))
    (if (member location circle)
        (message "Location %s already exists in circle %s."
                 (torus--concise location)
                 circle-name)
      (message "Copying location %s to circle %s."
                 (torus--concise location)
                 circle-name)
      (setcdr (assoc circle-name torus-torus) (push location circle))
      (torus--build-index)
      (torus--build-meta-index))))

;;;###autoload
(defun torus-copy-circle-to-torus (torus-name)
  "Copy current circle to TORUS-NAME."
  (interactive
   (list (completing-read
          "Copy current circle to torus : "
          (mapcar #'car torus-meta) nil t)))
  (torus--update-position)
  (let* ((circle (cl-copy-seq (car torus-torus)))
         (torus (copy-tree
                 (cdr (assoc "torus" (assoc torus-name torus-meta))))))
    (if (member circle torus)
        (message "Circle %s already exists in torus %s."
                 (car circle)
                 torus-name)
      (message "Copying circle %s to torus %s."
               (car circle)
               torus-name)
      (setcdr (assoc "torus" (assoc torus-name torus-meta))
              (push circle torus)))
    (torus--build-index)
    (torus--build-meta-index)))

;;; Reverse
;;; ------------

;;;###autoload
(defun torus-reverse-circles ()
  "Reverse order of the circles."
  (interactive)
  (torus--update-position)
  (setq torus-torus (reverse torus-torus))
  (torus--jump))

;;;###autoload
(defun torus-reverse-locations ()
  "Reverse order of the locations in the current circles."
  (interactive)
  (torus--update-position)
  (setcdr (car torus-torus) (reverse (cdr (car torus-torus))))
  (torus--jump))

;;;###autoload
(defun torus-deep-reverse ()
  "Reverse order of the locations in each circle."
  (interactive)
  (torus--update-position)
  (setq torus-torus (reverse torus-torus))
  (dolist (circle torus-torus)
    (setcdr circle (reverse (cdr circle))))
  (torus--jump))


;;;###autoload
(defun torus-reverse-menu (choice)
  "Split according to CHOICE."
  (interactive
   (list (read-key torus--message-reverse-choice)))
  (pcase choice
    (?c (funcall 'torus-reverse-circles))
    (?l (funcall 'torus-reverse-locations))
    (?d (funcall 'torus-deep-reverse))
    (?\a (message "Reverse operation cancelled by Ctrl-G."))
    (_ (message "Invalid key."))))

;;; Join
;;; ------------

;;;###autoload
(defun torus-prefix-circles-of-current-torus (prefix)
  "Add PREFIX to circle names of `torus-torus'."
  (interactive
   (list
    (read-string (format torus--message-prefix-circle
                         (car (car torus-meta)))
                 nil
                 'torus-input-history)))
  (let ((varlist))
    (setq varlist (torus--prefix-circles prefix (car (car torus-meta))))
    (setq torus-torus (car varlist))
    (setq torus-history (car (cdr varlist))))
  (torus--build-index)
  (torus--build-meta-index))

;;;###autoload
(defun torus-join-circles (circle-name)
  "Join current circle with CIRCLE-NAME."
  (interactive
   (list
    (completing-read "Join current circle with circle : "
                     (mapcar #'car torus-torus) nil t)))
  (let* ((current-name (car (car torus-torus)))
         (join-name (concat current-name torus-join-separator circle-name))
         (user-choice
          (read-string (format "Name of the joined torus [%s] : " join-name))))
    (when (> (length user-choice) 0)
      (setq join-name user-choice))
    (torus-add-circle join-name)
    (setcdr (car torus-torus)
            (append (cdr (assoc current-name torus-torus))
                    (cdr (assoc circle-name torus-torus))))
    (delete-dups (cdr (car torus-torus))))
  (torus--update-meta)
  (torus--build-index)
  (torus--build-meta-index)
  (torus--jump))

;;;###autoload
(defun torus-join-toruses (torus-name)
  "Join current torus with TORUS-NAME in `torus-meta'."
  (interactive
   (list
    (completing-read "Join current torus with torus : "
                     (mapcar #'car torus-meta) nil t)))
  (torus--prefix-argument-split current-prefix-arg)
  (torus--update-meta)
  (let* ((current-name (car (car torus-meta)))
         (join-name (concat current-name torus-join-separator torus-name))
         (user-choice
          (read-string (format "Name of the joined torus [%s] : " join-name)))
         (prompt-current
          (format torus--message-prefix-circle current-name))
         (prompt-added
          (format torus--message-prefix-circle torus-name))
         (prefix-current
          (read-string prompt-current nil 'torus-input-history))
         (prefix-added
          (read-string prompt-added nil 'torus-input-history))
         (varlist)
         (torus-added)
         (history-added)
         (input-added))
    (when (> (length user-choice) 0)
      (setq join-name user-choice))
    (torus--update-input-history prefix-current)
    (torus--update-input-history prefix-added)
    (torus-add-copy-of-torus join-name)
    (torus-prefix-circles-of-current-torus prefix-current)
    (setq varlist (torus--prefix-circles prefix-added torus-name))
    (setq torus-added (car varlist))
    (setq history-added (car (cdr varlist)))
    (setq input-added (car (cdr (cdr varlist))))
    (if (seq-intersection torus-torus torus-added #'torus--equal-car-p)
        (message torus--message-circle-name-collision)
      (setq torus-torus (append torus-torus torus-added))
      (setq torus-history (append torus-history history-added))
      (setq torus-input-history (append torus-input-history input-added))))
  (torus--update-meta)
  (torus--build-index)
  (torus--build-meta-index)
  (torus--jump))

;;; Autogroup
;;; ------------

;;;###autoload
(defun torus-autogroup (quoted-function)
  "Autogroup all torus locations according to the values of QUOTED-FUNCTION.
A new torus is created on `torus-meta' to contain the new circles.
The function must return the names of the new circles as strings."
  (interactive)
  (let ((torus-name
         (read-string "Name of the autogroup torus : "
                      nil
                      'torus-input-history))
        (all-locations))
    (if (assoc torus-name torus-meta)
        (message "Torus %s already exists in torus-meta" torus-name)
      (torus-add-copy-of-torus torus-name)
      (dolist (circle torus-torus)
        (dolist (location (cdr circle))
          (push location all-locations)))
      (setq torus-torus (seq-group-by quoted-function all-locations))))
  (setq torus-history nil)
  (setq torus-markers nil)
  (setq torus-input-history nil)
  (torus--build-index)
  (torus--build-meta-index)
  (torus--update-meta)
  (torus--jump))

;;;###autoload
(defun torus-autogroup-by-path ()
  "Autogroup all location of the torus by directories.
A new torus is created to contain the new circles."
  (interactive)
  (torus-autogroup (lambda (elem) (directory-file-name (file-name-directory (car elem))))))

;;;###autoload
(defun torus-autogroup-by-directory ()
  "Autogroup all location of the torus by directories.
A new torus is created to contain the new circles."
  (interactive)
  (torus-autogroup #'torus--directory))

;;;###autoload
(defun torus-autogroup-by-extension ()
  "Autogroup all location of the torus by extension.
A new torus is created to contain the new circles."
  (interactive)
  (torus-autogroup #'torus--extension-description))

;;;###autoload
(defun torus-autogroup-by-git-repo ()
  "Autogroup all location of the torus by git repositories.
A new torus is created to contain the new circles."
  ;; TODO
  )

;;;###autoload
(defun torus-autogroup-menu (choice)
  "Autogroup according to CHOICE."
  (interactive
   (list (read-key torus--message-autogroup-choice)))
    (pcase choice
      (?p (funcall 'torus-autogroup-by-path))
      (?d (funcall 'torus-autogroup-by-directory))
      (?e (funcall 'torus-autogroup-by-extension))
      (?\a (message "Autogroup cancelled by Ctrl-G."))
      (_ (message "Invalid key."))))

;;; Batch
;;; ------------


;;;###autoload
(defun torus-run-elisp-code-on-circle (elisp-code)
  "Run ELISP-CODE to all files of the circle."
  (interactive (list (read-string
                      "Elisp code to run to all files of the circle : ")))
  (dolist (iter (number-sequence 1 (length (cdar torus-torus))))
    (when (> torus-verbosity 1)
      (message "%d. Applying %s to %s" iter elisp-code (cadar torus-torus))
      (message "Evaluated : %s"
               (car (read-from-string (format "(progn %s)" elisp-code)))))
    (torus--eval-string elisp-code)
    (torus-next-location)))

;;;###autoload
(defun torus-run-elisp-command-on-circle (command)
  "Run an Emacs Lisp COMMAND to all files of the circle."
  (interactive (list (read-command
                      "Elisp command to run to all files of the circle : ")))
  (dolist (iter (number-sequence 1 (length (cdar torus-torus))))
    (when (> torus-verbosity 1)
      (message "%d. Applying %s to %s" iter command (cadar torus-torus)))
    (funcall command)
    (torus-next-location)))

;;;###autoload
(defun torus-run-shell-command-on-circle (command)
  "Run a shell COMMAND to all files of the circle."
  (interactive (list (read-string
                      "Shell command to run to all files of the circle : ")))
  (let ((keep-value shell-command-dont-erase-buffer))
    (setq shell-command-dont-erase-buffer t)
    (dolist (iter (number-sequence 1 (length (cdar torus-torus))))
      (when (> torus-verbosity 1)
        (message "%d. Applying %s to %s" iter command (cadar torus-torus)))
      (shell-command (format "%s %s"
                             command
                             (shell-quote-argument (buffer-file-name))))
      (torus-next-location))
    (setq shell-command-dont-erase-buffer keep-value)))

;;;###autoload
(defun torus-run-async-shell-command-on-circle (command)
  "Run a shell COMMAND to all files of the circle."
  (interactive (list (read-string
                      "Shell command to run to all files of the circle : ")))
  (let ((keep-value async-shell-command-buffer))
    (setq async-shell-command-buffer 'new-buffer)
    (dolist (iter (number-sequence 1 (length (cdar torus-torus))))
      (when (> torus-verbosity 1)
        (message "%d. Applying %s to %s" iter command (cadar torus-torus)))
      (async-shell-command (format "%s %s"
                             command
                             (shell-quote-argument (buffer-file-name))))
      (torus-next-location))
    (setq async-shell-command-buffer keep-value)))

;;;###autoload
(defun torus-batch-menu (choice)
  "Split according to CHOICE."
  (interactive
   (list (read-key torus--message-batch-choice)))
  (pcase choice
    (?e (call-interactively 'torus-run-elisp-code-on-circle))
    (?c (call-interactively 'torus-run-elisp-command-on-circle))
    (?! (call-interactively 'torus-run-shell-command-on-circle))
    (?& (call-interactively 'torus-run-async-shell-command-on-circle))
    (?\a (message "Batch operation cancelled by Ctrl-G."))
    (_ (message "Invalid key."))))

;;; Split
;;; ------------

;;;###autoload
(defun torus-split-horizontally ()
  "Split horizontally to view all buffers in current circle.
Split until `torus-maximum-horizontal-split' is reached."
  (interactive)
  (let* ((circle (cdr (car torus-torus)))
         (numsplit (1- (length circle))))
    (when (> torus-verbosity 1)
      (message "numsplit = %d" numsplit))
    (if (> numsplit (1- torus-maximum-horizontal-split))
        (message "Too many files to split.")
      (delete-other-windows)
      (dolist (iter (number-sequence 1 numsplit))
        (when (> torus-verbosity 2)
          (message "iter = %d" iter))
        (split-window-below)
        (balance-windows)
        (other-window 1)
        (torus-next-location))
      (other-window 1)
      (torus-next-location))))

;;;###autoload
(defun torus-split-vertically ()
  "Split vertically to view all buffers in current circle.
Split until `torus-maximum-vertical-split' is reached."
  (interactive)
  (let* ((circle (cdr (car torus-torus)))
         (numsplit (1- (length circle))))
    (when (> torus-verbosity 1)
      (message "numsplit = %d" numsplit))
    (if (> numsplit (1- torus-maximum-vertical-split))
        (message "Too many files to split.")
      (delete-other-windows)
      (dolist (iter (number-sequence 1 numsplit))
        (when (> torus-verbosity 2)
          (message "iter = %d" iter))
        (split-window-right)
        (balance-windows)
        (other-window 1)
        (torus-next-location))
      (other-window 1)
      (torus-next-location))))

;;;###autoload
(defun torus-split-main-left ()
  "Split with left main window to view all buffers in current circle."
  (interactive)
  (let* ((circle (cdr (car torus-torus)))
         (numsplit (- (length circle) 2)))
    (when (> torus-verbosity 1)
      (message "numsplit = %d" numsplit))
    (if (> numsplit (1- torus-maximum-horizontal-split))
        (message "Too many files to split.")
      (delete-other-windows)
      (split-window-right)
      (other-window 1)
      (torus-next-location)
      (dolist (iter (number-sequence 1 numsplit))
        (when (> torus-verbosity 2)
          (message "iter = %d" iter))
        (split-window-below)
        (balance-windows)
        (other-window 1)
        (torus-next-location))
      (other-window 1)
      (torus-next-location))))

;;;###autoload
(defun torus-split-main-right ()
  "Split with right main window to view all buffers in current circle."
  (interactive)
  (let* ((circle (cdr (car torus-torus)))
         (numsplit (- (length circle) 2)))
    (when (> torus-verbosity 1)
      (message "numsplit = %d" numsplit))
    (if (> numsplit (1- torus-maximum-horizontal-split))
        (message "Too many files to split.")
      (delete-other-windows)
      (split-window-right)
      (torus-next-location)
      (dolist (iter (number-sequence 1 numsplit))
        (when (> torus-verbosity 2)
          (message "iter = %d" iter))
        (split-window-below)
        (balance-windows)
        (other-window 1)
        (torus-next-location))
      (other-window 1)
      (torus-next-location))))

;;;###autoload
(defun torus-split-main-top ()
  "Split with main top window to view all buffers in current circle."
  (interactive)
  (let* ((circle (cdr (car torus-torus)))
         (numsplit (- (length circle) 2)))
    (when (> torus-verbosity 1)
      (message "numsplit = %d" numsplit))
    (if (> numsplit (1- torus-maximum-vertical-split))
        (message "Too many files to split.")
      (delete-other-windows)
      (split-window-below)
      (other-window 1)
      (torus-next-location)
      (dolist (iter (number-sequence 1 numsplit))
        (when (> torus-verbosity 2)
          (message "iter = %d" iter))
        (split-window-right)
        (balance-windows)
        (other-window 1)
        (torus-next-location))
      (other-window 1)
      (torus-next-location))))

;;;###autoload
(defun torus-split-main-bottom ()
  "Split with main bottom window to view all buffers in current circle."
  (interactive)
  (let* ((circle (cdr (car torus-torus)))
         (numsplit (- (length circle) 2)))
    (when (> torus-verbosity 1)
      (message "numsplit = %d" numsplit))
    (if (> numsplit (1- torus-maximum-vertical-split))
        (message "Too many files to split.")
      (delete-other-windows)
      (split-window-below)
      (torus-next-location)
      (dolist (iter (number-sequence 1 numsplit))
        (when (> torus-verbosity 2)
          (message "iter = %d" iter))
        (split-window-right)
        (balance-windows)
        (other-window 1)
        (torus-next-location))
      (other-window 1)
      (torus-next-location))))

;;;###autoload
(defun torus-split-grid ()
  "Split horizontally & vertically to view all current circle buffers in a grid."
  (interactive)
  (let* ((circle (cdr (car torus-torus)))
         (len-circle (length circle))
         (max-iter (1- len-circle))
         (ratio (/ (float (frame-text-width))
                   (float (frame-text-height))))
         (horizontal (sqrt (/ (float len-circle) ratio)))
         (vertical (* ratio horizontal))
         (int-hor (min (ceiling horizontal)
                       torus-maximum-horizontal-split))
         (int-ver (min (ceiling vertical)
                       torus-maximum-vertical-split))
         (getout)
         (num-hor-minus)
         (num-hor)
         (num-ver-minus)
         (total 0))
    (if (< (* int-hor int-ver) len-circle)
        (message "Too many files to split.")
      (let ((dist-dec-hor)
            (dist-dec-ver))
        (when (> torus-verbosity 2)
          (message "ratio = %f" ratio)
          (message "horizontal = %f" horizontal)
          (message "vertical = %f" vertical)
          (message "int-hor int-ver = %d %d" int-hor  int-ver))
        (while (not getout)
          (setq dist-dec-hor (abs (- (* (1- int-hor) int-ver) len-circle)))
          (setq dist-dec-ver (abs (- (* int-hor (1- int-ver)) len-circle)))
          (when (> torus-verbosity 2)
            (message "Distance hor ver = %f %f" dist-dec-hor dist-dec-ver))
          (cond ((and (<= dist-dec-hor dist-dec-ver)
                      (>= (* (1- int-hor) int-ver) len-circle))
                 (setq int-hor (1- int-hor))
                 (when (> torus-verbosity 2)
                   (message "Decrease int-hor : int-hor int-ver = %d %d"
                            int-hor  int-ver)))
                ((and (>= dist-dec-hor dist-dec-ver)
                      (>= (* int-hor (1- int-ver)) len-circle))
                 (setq int-ver (1- int-ver))
                 (when (> torus-verbosity 2)
                   (message "Decrease int-ver : int-hor int-ver = %d %d"
                            int-hor  int-ver)))
                (t (setq getout t)
                   (when (> torus-verbosity 2)
                     (message "Getout : %s" getout)
                     (message "int-hor int-ver = %d %d" int-hor int-ver))))))
      (setq num-hor-minus (number-sequence 1 (1- int-hor)))
      (setq num-hor (number-sequence 1 int-hor))
      (setq num-ver-minus (number-sequence 1 (1- int-ver)))
      (when (> torus-verbosity 2)
        (message "num-hor-minus = %s" num-hor-minus)
        (message "num-hor = %s" num-hor)
        (message "num-ver-minus = %s" num-ver-minus))
      (delete-other-windows)
      (dolist (iter-hor num-hor-minus)
        (when (> torus-verbosity 2)
          (message "iter hor = %d" iter-hor))
        (setq max-iter (1- max-iter))
        (split-window-below)
        (balance-windows)
        (other-window 1))
      (other-window 1)
      (dolist (iter-hor num-hor)
        (dolist (iter-ver num-ver-minus)
          (when (> torus-verbosity 2)
            (message "iter hor ver = %d %d" iter-hor iter-ver)
            (message "total max-iter = %d %d" total max-iter))
          (when (< total max-iter)
            (setq total (1+ total))
            (split-window-right)
            (balance-windows)
            (other-window 1)
            (torus-next-location)))
        (when (< total max-iter)
          (other-window 1)
          (torus-next-location)))
    (other-window 1)
    (torus-next-location))))

;;;###autoload
(defun torus-layout-menu (choice)
  "Split according to CHOICE."
  (interactive
   (list (read-key torus--message-layout-choice)))
  (torus--update-layout)
  (let ((circle (caar torus-torus)))
    (when (member choice '(?m ?o ?h ?v ?l ?r ?t ?b ?g))
      (setcdr (assoc circle torus-layout) choice))
    (pcase choice
      (?m nil)
      (?o (delete-other-windows))
      (?h (funcall 'torus-split-horizontally))
      (?v (funcall 'torus-split-vertically))
      (?l (funcall 'torus-split-main-left))
      (?r (funcall 'torus-split-main-right))
      (?t (funcall 'torus-split-main-top))
      (?b (funcall 'torus-split-main-bottom))
      (?g (funcall 'torus-split-grid))
      (?\a (message "Layout cancelled by Ctrl-G."))
      (_ (message "Invalid key.")))))

;;; Tabs
;;; ------------

(defun torus-tab-mouse (event)
  "Manage click EVENT on locations part of tab line."
  (interactive "@e")
  (let* ((index (cdar (nthcdr 4 (cadr event))))
        (before (substring-no-properties
                    (caar (nthcdr 4 (cadr event))) 0 index))
        (pipes (seq-filter (lambda (elem) (equal elem ?|)) before))
        (len-pipes (length pipes)))
    (if (equal len-pipes 0)
        (torus-alternate-in-same-circle)
      (torus-switch-location (nth (length pipes) (cdar torus-torus))))))

;;; Delete
;;; ------------

;;;###autoload
(defun torus-delete-circle (circle-name)
  "Delete circle given by CIRCLE-NAME."
  (interactive
   (list
    (completing-read "Delete circle : "
                     (mapcar #'car torus-torus) nil t)))
  (when (y-or-n-p (format "Delete circle %s ? " circle-name))
    (setq torus-torus (torus--assoc-delete-all circle-name torus-torus))
    (setq torus-index
          (torus--reverse-assoc-delete-all circle-name torus-index))
    (setq torus-history
          (torus--reverse-assoc-delete-all circle-name torus-history))
    (setq torus-markers
          (torus--reverse-assoc-delete-all circle-name torus-markers))
    (let ((circle-torus (cons (caar torus-torus) (caar torus-meta))))
      (setq torus-meta-index
            (torus--reverse-assoc-delete-all circle-torus torus-meta-index))
      (setq torus-meta-history
            (torus--reverse-assoc-delete-all circle-torus torus-meta-history)))
    (torus--build-index)
    (torus--build-meta-index)
    (torus--jump)))

;;;###autoload
(defun torus-delete-location (location-name)
  "Delete location given by LOCATION-NAME."
  (interactive
   (list
    (completing-read
     "Delete location : "
     (mapcar #'torus--concise (cdr (car torus-torus))) nil t)))
  (if (and
       (> (length (car torus-torus)) 1)
       (y-or-n-p
        (format
         "Delete %s from circle %s ? "
         location-name
         (car (car torus-torus)))))
      (let* ((circle (cdr (car torus-torus)))
             (index (cl-position location-name circle
                                 :test #'torus--equal-concise-p))
             (location (nth index circle))
             (location-circle (cons location (caar torus-torus)))
             (location-circle-torus (cons location (cons (caar torus-torus)
                                                         (caar torus-meta)))))
        (setcdr (car torus-torus) (cl-remove location circle))
        (setq torus-index (cl-remove location-circle torus-index))
        (setq torus-history (cl-remove location-circle torus-history))
        (setq torus-markers (cl-remove location-circle torus-markers))
        (setq torus-meta-index (cl-remove location-circle-torus torus-meta-index))
        (setq torus-meta-history (cl-remove location-circle-torus torus-meta-history))
        (torus--jump))
    (message "No location in current circle.")))

;;;###autoload
(defun torus-delete-current-circle ()
  "Delete current circle."
  (interactive)
  (torus-delete-circle (torus--concise (car (car torus-torus)))))

;;;###autoload
(defun torus-delete-current-location ()
  "Remove current location from current circle."
  (interactive)
  (torus-delete-location (torus--concise (car (cdr (car torus-torus))))))

;;;###autoload
(defun torus-delete-torus (torus-name)
  "Delete torus given by TORUS-NAME."
  (interactive
   (list
    (completing-read "Delete torus : "
                     (mapcar #'car torus-meta) nil t)))
  (when (y-or-n-p (format "Delete torus %s ? " torus-name))
    (when (equal torus-name (car (car torus-meta)))
      (torus-switch-torus (car (car (cdr torus-meta)))))
    (setq torus-meta (torus--assoc-delete-all torus-name torus-meta))))

;;; File R/W
;;; ------------

;;;###autoload
(defun torus-write (filename)
  "Write main torus variables to FILENAME as Lisp code.
An adequate extension is added if needed.
If called interactively, ask for the variables to save (default : all)."
  (interactive
   (list
    (read-file-name
     "Torus file : "
     (file-name-as-directory torus-dirname))))
  ;; We surely don’t want to load a file we’ve just written
  (remove-hook 'after-save-hook 'torus-after-save-torus-file)
  (if torus-meta
      (let*
          ((file-basename (file-name-nondirectory filename))
           (minus-len-ext (- (min (length torus-extension)
                                  (length filename))))
           (buffer)
           (varlist '(torus-torus
                      torus-history
                      torus-layout
                      torus-input-history
                      torus-meta
                      torus-index
                      torus-meta-history
                      torus-meta-index
                      torus-line-col)))
        (torus--update-position)
        (torus--update-input-history file-basename)
        (unless (equal (cl-subseq filename minus-len-ext) torus-extension)
          (setq filename (concat filename torus-extension)))
        (unless torus-index
          (torus--build-index))
        (unless torus-meta-index
          (torus--build-meta-index))
        (torus--update-layout)
        (torus--update-meta)
        (if varlist
            (progn
              (torus--roll-backups filename)
              (setq buffer (find-file-noselect filename))
              (with-current-buffer buffer
                (erase-buffer)
                (dolist (var varlist)
                  (when var
                    (insert (concat
                             "(setq "
                             (symbol-name var)
                             " (quote\n"))
                    (pp (symbol-value var) buffer)
                    (insert "))\n\n")))
                (save-buffer)
                (kill-buffer)))
          (message "Write cancelled : empty variables.")))
    (message "Write cancelled : empty torus."))
  ;; Restore the hook
  (add-hook 'after-save-hook 'torus-after-save-torus-file))

;;;###autoload
(defun torus-read (filename)
  "Read main torus variables from FILENAME as Lisp code."
  (interactive
   (list
    (read-file-name
     "Torus file : "
     (file-name-as-directory torus-dirname))))
  (let*
      ((file-basename (file-name-nondirectory filename))
       (minus-len-ext (- (min (length torus-extension)
                              (length filename))))
       (buffer))
    (unless (equal (cl-subseq filename minus-len-ext) torus-extension)
      (setq filename (concat filename torus-extension)))
    (when (or (and (not torus-meta)
                   (not torus-torus)
                   (not torus-index)
                   (not torus-history)
                   (not torus-layout)
                   (not torus-input-history)
                   (not torus-meta-index)
                   (not torus-meta-history))
              (y-or-n-p torus--message-replace-torus))
      (torus--update-input-history file-basename)
      (if (file-exists-p filename)
          (progn
            (setq buffer (find-file-noselect filename))
            (eval-buffer buffer)
            (kill-buffer buffer))
        (message "File %s does not exist." filename))))
  ;; Also saved in file
  ;; (torus--update-meta)
  ;; (torus--build-index)
  ;; (torus--build-meta-index)
  (torus--jump))

;;;###autoload
(defun torus-edit (filename)
  "Edit torus file FILENAME in the torus files dir.
Be sure to understand what you’re doing, and not leave some variables
in inconsistent state, or you might encounter strange undesired effects."
  (interactive
   (list
    (read-file-name
     "Torus file : "
     (file-name-as-directory torus-dirname))))
  (find-file filename))

;;; End
;;; ------------------------------

(provide 'torus)

;; Local Variables:
;; mode: emacs-lisp
;; indent-tabs-mode: nil
;; End:

;;; torus.el ends here
