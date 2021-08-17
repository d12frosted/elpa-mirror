;;; efar.el --- FAR-like file manager -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Vladimir Suntsov

;; Author: "Vladimir Suntsov" <vladimir@suntsov.online>
;; Maintainer: vladimir@suntsov.online
;; Version: 1.20
;; Package-Version: 20210604.503
;; Package-Commit: afc19e212a6f1227b5747b42407226b8222f92c5
;; Package-Requires: ((emacs "26.1"))
;; Keywords: files
;; URL: https://github.com/suntsov/efar

;; This package is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This package is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides FAR-like file manager.

;; To start eFar just type M-x efar.
;; When Efar is called with universal argument (C-u M-x efar),
;; default-directory of actual buffer is automatically opened in left panel.

;; Press C-? to show buffer with all available key bindings.

;; Use M-x customize to configure numerous eFar parameters
;; including key bindings and faces.


;;; Code:

(require 'subr-x)
(require 'filenotify)
(require 'dired)
(require 'eshell)
(require 'esh-mode)
(require 'em-dirs)

(defconst efar-version 1.20 "Current eFar version number.")

(defvar efar-state nil)
(defvar efar-mouse-down-p nil)
(defvar efar-rename-map nil)
;;variables for file search
(defvar efar-search-processes '())
(defvar efar-search-process-manager nil)
(defvar efar-search-results '())
(defvar efar-last-search-params nil)
(defvar efar-update-search-results-timer nil)
(defvar efar-search-server nil)
(defvar efar-search-server-port nil)
(defvar efar-search-clients '())
(defvar efar-search-running-p nil)
(defvar efar-search-process-pending-messages '())

(provide 'efar)

;;--------------------------------------------------------------------------------
;; eFar customization variables
;;--------------------------------------------------------------------------------
;; GROUPS
(defgroup efar nil
  "FAR-like file manager"
  :group 'applications)

(defgroup efar-parameters nil
  "eFar main customization parameters"
  :group 'efar)

(defgroup efar-search-parameters nil
  "eFar file search parameters"
  :group 'efar-parameters)

(defgroup efar-faces nil
  "eFar faces"
  :group 'efar)

(defgroup efar-search-faces nil
  "eFar faces"
  :group 'efar-search-parameters)

(defgroup efar-keys nil
  "eFar key bindings"
  :group 'efar)

;; MAIN PARAMETERS
(eval-and-compile
  (defcustom efar-buffer-name "*eFAR*"
    "Name for the Efar buffer."
    :group 'efar-parameters
    :type 'string))

(eval-and-compile
  (defcustom efar-shell-buffer-name "*eFAR shell*"
    "Name for the Efar shell buffer."
    :group 'efar-parameters
    :type 'string))

(eval-and-compile
  (defcustom efar-batch-buffer-name "*eFAR batch operation*"
    "Name for the buffer to perform batch operations."
    :group 'efar-parameters
    :type 'string))

(defcustom efar-state-file-name (concat user-emacs-directory ".efar-state")
  "Path to the eFar state save file."
  :group 'efar-parameters
  :type 'string)

(defcustom efar-default-startup-dirs (cons user-emacs-directory user-emacs-directory)
  "Default directories shown at startup."
  :group 'efar-parameters
  :type 'cons)

(defcustom efar-save-state-p t
  "Save eFar state when eFar buffer is killed to restore it at next open."
  :group 'efar-parameters
  :type 'boolean)

(defcustom efar-filter-directories-p nil
  "Apply filter to the directories and files (t) or to files only (nil)."
  :group 'efar-parameters
  :type 'boolean)

(defcustom efar-add-slash-to-directories t
  "Add ending / to directories."
  :group 'efar-parameters
  :type 'boolean)

(defcustom efar-auto-read-directories nil
  "Automatically show content of the directory under cursor in other buffer."
  :group 'efar-parameters
  :type 'boolean)

(defcustom efar-auto-read-files t
  "Automatically show content of the file under cursor in other buffer."
  :group 'efar-parameters
  :type 'boolean)

(defcustom efar-auto-read-file-extensions (list "el" "py" "magik" "txt")
  "List of file types (extensions) to be automatically read."
  :group 'efar-parameters
  :type 'list)

(defcustom efar-auto-read-max-file-size 1048576
  "Maximum size in bytes for files which will be automatically read."
  :group 'efar-parameters
  :type 'integer)

(defcustom efar-max-items-in-directory-history 100
  "Maximum number of directories to be stored in directory history."
  :group 'efar-parameters
  :type 'integer)

(defcustom efar-fast-search-filter-enabled-p t
  "Filter out not matching files in fast search mode."
  :group 'efar-parameters
  :type 'boolean)

(defcustom efar-max-search-processes 4
  "Number of subprocesses to use for file search."
  :group 'efar-search-parameters
  :type 'integer)

(defcustom efar-search-results-buffer-name "*eFar search results*"
  "Name of the buffer to display search results in."
  :group 'efar-search-parameters
  :type 'string)

(defcustom efar-search-default-file-mask "*.el"
  "Default file name mask to use for file search."
  :group 'efar-search-parameters
  :type 'string)

(defcustom efar-search-coding 'iso-latin-1
  "Coding system to use for file search."
  :group 'efar-search-parameters
  :type 'symbol)

(defcustom efar-search-follow-symlinks-p t
  "Follow directory symlinks when searching?"
  :group 'efar-search-parameters
  :type 'boolean)

;; FACES
(defface efar-border-line-face
  '((t :foreground "white"
       :background "navy"
       :underline nil))
  "Border line face"
  :group 'efar-faces)


(defface efar-file-face
  '((t :foreground "deep sky blue"
       :background "navy"
       :underline nil))
  "File item style (default)"
  :group 'efar-faces)

(defface efar-file-executable-face
  '((t :foreground "green"
       :background "navy"
       :underline nil))
  "File item style (executable file)"
  :group 'efar-faces)

(defface efar-file-current-executable-face
  '((t :foreground "green"
       :background "cadet blue"
       :underline nil))
  "Current file item style (executable file)"
  :group 'efar-faces)

(defface efar-marked-current-face
  '((t :foreground "gold"
       :background "cadet blue"
       :underline nil))
  "Current marked item style"
  :group 'efar-faces)

(defface efar-dir-face
  '((t :foreground "white"
       :background "navy"
       :underline nil))
  "Directory item style"
  :group 'efar-faces)

(defface efar-file-current-face
  '((t :foreground "black"
       :background "cadet blue"
       :underline nil))
  "Current file item style"
  :group 'efar-faces)

(defface efar-dir-current-face
  '((t :foreground "white"
       :background "cadet blue"
       :underline nil))
  "Current directory item style"
  :group 'efar-faces)

(defface efar-marked-face
  '((t :foreground "gold"
       :background "navy"
       :underline nil))
  "Marked item style"
  :group 'efar-faces)

(defface efar-marked-current-face
  '((t :foreground "gold"
       :background "cadet blue"
       :underline nil))
  "Current marked item style"
  :group 'efar-faces)


(defface efar-dir-name-face
  '((t :foreground "white"
       :background "navy"
       :underline nil))
  "Directory name header style"
  :group 'efar-faces)

(defface efar-header-face
  '((t :foreground "orange"
       :background "navy"
       :underline nil))
  "Header style"
  :group 'efar-faces)

(defface efar-dir-name-current-face
  '((t :foreground "navy"
       :background "bisque"
       :underline nil))
  "Current directory name header style"
  :group 'efar-faces)

(defface efar-non-existing-file-face
  '((t :foreground "red"
       :background "navy"
       :underline nil))
  "Style for non-existing files (in bookmarks and directory history"
  :group 'efar-faces)

(defface efar-non-existing-current-file-face
  '((t :foreground "red"
       :background "bisque"
       :underline nil))
  "Style for non-existing current files (in bookmarks and directory history"
  :group 'efar-faces)

(defface efar-search-file-link-face
  '((t :foreground "black"
       :background "snow2"
       :bold t
       :underline t))
  "The face used for representing the link to the file"
  :group 'efar-search-faces)

(defface efar-search-line-link-face
  '((t :foreground "black"
       :background "ivory"))
  "The face used for representing the link to the source code line"
  :group 'efar-search-faces)


;; macros
(defmacro efar-with-notification-disabled(&rest body)
  "Execute BODY with efar-notifications disabled."
  `(let ((file-notifier-left (efar-get :panels :left :file-notifier))
	 (file-notifier-right (efar-get :panels :right :file-notifier)))
     
     (when (file-notify-valid-p (cdr file-notifier-left))
       (efar-remove-notifier :left))
     
     (when (file-notify-valid-p (cdr file-notifier-right))
       (efar-remove-notifier :right))
     
     ,@body
     
     (efar-setup-notifier (efar-get :panels :left :dir) :left)
     (efar-setup-notifier (efar-get :panels :right :dir) :right)))

(defmacro efar-write-enable (&rest body)
  "Make eFar buffer writable, execute BODY and then make it back read-only."
  `(with-current-buffer ,efar-buffer-name
     (read-only-mode -1)
     ,@body
     (read-only-mode 1)))

(defmacro efar-retry-when-error (&rest body)
  "Retry BODY until success or user answers 'No'."
  `(while
       (string=
	"error"
	(condition-case err
	    ,@body
	  (error (when
		     (string= "Yes"
			      (efar-completing-read
			       (concat "Error: \"" (error-message-string err) "\". Try again? ")
			       (list "Yes" "No")))
		   "error"))))))


;; KEY bindings

(defvar efar-keys '()
  "The list of eFar keybindings.")

(setq efar-keys '())

(defun efar-register-key (key func arg custom-key-name description &optional show-in-help ignore-in-modes)
  "Registers a new KEY binding.
This list is used to set up local key bindings,
generate content of help buffer and prepare key binding customizaton entries.

FUNC is a function to call with argument ARG.
CUSTOM-KEY-NAME is a name of custom variable by which a key binding is available
in customization menu.
DESCRIPTION is a string describing the key in customization menu.
SHOW-IN-HELP is optional boolean indicating whether to show key in help buffer.
IGNORE-IN-MODES is a list of modes which should ignore this key binding."
  (push (list key func arg custom-key-name description show-in-help ignore-in-modes) efar-keys))

;;   key-sequence function to call  arg variable name to save custom Key description
(efar-register-key "<down>"  'efar-move-cursor  :down 'efar-move-down-key
		   "move cursor one line down" t)
(efar-register-key "<up>"   'efar-move-cursor  :up 'efar-move-up-key
		   "move cursor one line up" t)
(efar-register-key "<right>"  'efar-move-cursor  :right  'efar-move-right-key
		   "move cursor to the column on the right" t)
(efar-register-key "<left>"  'efar-move-cursor  :left  'efar-move-left-key
		   "move cursor to the column on the left" t)
(efar-register-key "<prior>"  'efar-move-cursor  :left  nil "" nil)
(efar-register-key "<next>"  'efar-move-cursor  :right  nil "" nil)
(efar-register-key "<home>"  'efar-move-cursor  :home 'efar-move-home-key
 		   "move cursor to the beginning of the list" t)
(efar-register-key "C-<left>"  'efar-move-cursor  :home  'efar-move-home-alt-key
 		   "move cursor to the beginning of the list (alternative)" t)
(efar-register-key "<end>"  'efar-move-cursor  :end 'efar-move-end-key
 		   "move cursot to the end of the list" t)
(efar-register-key "C-<right>"  'efar-move-cursor  :end 'efar-move-end-alt-key
 		   "move cursot to the end of the list (alternative)" t)
(efar-register-key "C-<up>" 'efar-enter-directory t 'efar-go-to-parent-dir-key
 		   "go to parent directory" t (list :file-hist :dir-hist :bookmark :disks :search))
(efar-register-key "C-M-<down>" 'efar-go-directory-history-cicle :forward 'efar-next-directory-in-history-key
 		   "loop over directories in directory history forward" t)
(efar-register-key "C-M-<up>" 'efar-go-directory-history-cicle :backward 'efar-prev-directory-in-history-key
 		   "loop over directories in directory history backward" t)
(efar-register-key "RET" '((:files . efar-handle-enter) (:dir-hist . efar-navigate-to-file) (:file-hist . efar-navigate-to-file) (:bookmark . efar-navigate-to-file) (:disks . efar-switch-to-disk) (:search . efar-navigate-to-file))  nil  'efar-enter-directory-key
 		   "go into/to the item under cursor or run executable file in the shell" :space-after)

(efar-register-key "M-RET" 'efar-handle-enter t 'efar-copy-to-shell-key
		   "insert file name into the shell buffer" t (list :file-hist :dir-hist :bookmark :disks :search))

(efar-register-key "M-<down>" 'efar-scroll-other-window :down 'efar-scroll-other-down-key
 		   "scroll other window down" t)
(efar-register-key "M-<up>" 'efar-scroll-other-window :up 'efar-scroll-other-up-key
 		   "scroll other window up" t)

(efar-register-key "<insert>" 'efar-mark-file   nil 'efar-mark-file-key
 		   "mark item under cursor" t (list :file-hist :dir-hist :bookmark :disks :search))
(efar-register-key "<C-insert>" 'efar-deselect-all  nil 'efar-deselect-all-key
 		   "unmark all items in the list" :space-after (list :file-hist :dir-hist :bookmark :disks :search))

(efar-register-key "TAB" 'efar-switch-to-other-panel nil 'efar-switch-to-other-panel-key
 		   "switch to other panel" t)
(efar-register-key "C-c TAB"  'efar-open-dir-other-panel nil 'efar-open-dir-other-panel-key
 		   "open current directory in other panel" :space-after)

(efar-register-key "<f4>"   'efar-edit-file   nil 'efar-open-file-key
 		   "edit file under cursor" t)
(efar-register-key "<M-f4>"  'efar-open-file-in-ext-app nil 'efar-open-file-in-ext-app-key
 		   "open file under cursor in external application" t)
(efar-register-key "<f3>"  'efar-edit-file   t 'efar-read-file-key
 		   "show content of the file in other window" :space-after)

(efar-register-key "C-c f m"  'efar-set-file-modes  nil 'efar-set-file-modes-key
 		   "set file modes (permissions) for selected items" :space-after)

(efar-register-key "<f5>"   'efar-copy-or-move-files :copy 'efar-copy-file-key
  		   "copy selected file(s)" t (list :file-hist :dir-hist :bookmark :disks :search))
(efar-register-key "<f6>"  'efar-copy-or-move-files :move 'efar-move-file-key
 		   "move selected file(s)" t (list :file-hist :dir-hist :bookmark :disks :search))
(efar-register-key "<f7>"  'efar-create-new-directory nil 'efar-create-direcotry-key
 		   "create new directory" t (list :file-hist :dir-hist :bookmark :disks :search))
(efar-register-key "<f8>"  '((:files . efar-delete-selected) (:bookmark . efar-delete-bookmark))   nil 'efar-delete-file-key
 		   "delete selected file(s) or bookmark" :space-after '(:file-hist :dir-hist :disks :search))

(efar-register-key "S-C-<left>"  'efar-move-splitter  :left 'efar-move-splitter-left-key
		   "move splitter between panels to the left" t)
(efar-register-key "S-C-<right>"  'efar-move-splitter  :right 'efar-move-splitter-right-key
		   "move splitter between panels to the right" t)
(efar-register-key "S-C-<down>"  'efar-move-splitter  :center 'efar-move-splitter-center-key
		   "Center the splitter between panels" t)
(efar-register-key "C-c f d" 'efar-change-panel-mode  :disks 'efar-show-disk-selector-key
		   "show list of available disks (Windows) or mount points (Unix)" t)
(efar-register-key "C-c f s" 'efar-change-sort-function  nil 'efar-change-sort-key
		   "change sort function and/or order for current panel" t (list :file-hist :dir-hist :bookmark :disks))
(efar-register-key "C-c f f" 'efar-filter-files  nil 'efar-filter-files-key
		   "set/remove filtering for current panel" :space-after (list :file-hist :dir-hist :bookmark :disks :search))

(efar-register-key "C-c v M" 'efar-change-mode  nil 'efar-change-mode-key
		   "toggle mode: double panel <-> single panel" t)
(efar-register-key "C-c v +" 'efar-change-column-number t 'efar-inc-column-number-key
		   "increase number of columns in current panel" t)
(efar-register-key "C-c v -" 'efar-change-column-number nil 'efar-dec-column-number-key
		   "decrease number of columns in current panel" t)
(efar-register-key "C-c v m" 'efar-change-file-disp-mode nil 'efar-change-file-disp-mode-key
		   "change file display mode (short, long, detailed) for current panel" :space-after)

(efar-register-key "C-c c p" 'efar-copy-current-path  nil 'efar-copy-current-path-key
		   "copy to the clipboard the path to the current file" t)
(efar-register-key "C-c c d" 'efar-cd   nil 'efar-cd-key
		   "go to specific directory" t)
(efar-register-key "C-c c e" 'efar-ediff-files  nil 'efar-ediff-files-key
		   "run ediff for selected files" t (list :file-hist :dir-hist :bookmark :disks :search))
(efar-register-key "C-c c s" 'efar-current-file-stat  nil 'efar-current-file-stat-key
		   "show directory stats (size and files number)" t)
(efar-register-key "C-c c o" 'efar-display-shell  t 'efar-display-shell-key
		   "open console window"  t)
(efar-register-key "<f12> <f12>"  'efar-reinit  nil 'efar-reinit-key
		   "reinit and redraw eFar buffer" t)
(efar-register-key "C-c ?"  'efar-show-help   nil 'efar-show-help-key
		   "show frame with all key bindings" t)
(efar-register-key "C-c c b" 'efar-change-panel-mode  :bookmark 'efar-show-bookmarks-key
		   "show bookmarks" t)
(efar-register-key "C-c c B" 'efar-add-bookmark  nil 'efar-add-bookmark-key
		   "add item under cursor to the bookmarks" t)
(efar-register-key "C-c c h" 'efar-change-panel-mode  :dir-hist 'efar-show-directory-history-key
		   "show last visited directories" t)
(efar-register-key "C-c c f" 'efar-change-panel-mode  :file-hist 'efar-show-file-history-key
		   "show last edited files" t)
(efar-register-key "C-c c n" 'efar-batch-rename  nil 'efar-batch-rename-key
		   "perform batch file renaming" t)
(efar-register-key "C-c c r" 'efar-batch-replace  nil 'efar-batch-replace-key
		   "perform batch regexp replace in files" t)
(efar-register-key "C-c c m" 'efar-show-mode-selector  nil 'efar-show-mode-selector-key
		   "show panel mode selector" :space-after)

(efar-register-key "<M-f7>" 'efar-start-search nil 'efar-start-search-key
		   "run file search" t)
(efar-register-key "<S-f7>" 'efar-change-panel-mode :search 'efar-show-search-results-key
		   "show file search results" t)
(efar-register-key "<C-M-f7>" 'efar-show-search-results-in-buffer nil 'efar-show-search-results-in-buffer-key
		   "display search results in a separate buffer" :space-after (list :file-hist :dir-hist :bookmark :disks :files))

(efar-register-key "C-g" 'efar-abort  nil nil
		   "quit fast search mode or switch panel to files mode" t)

(efar-register-key "C-n" 'efar-suggest-hint nil nil nil nil)

;; fast-search keys
(efar-register-key "DEL" 'efar-fast-search  :back nil
		   "Backspace for fast search")
(efar-register-key "C-s"  'efar-fast-search  :next nil
		   "start fast search/go to next fast search match" t)
(efar-register-key "C-r"  'efar-fast-search  :prev nil
		   "start fast search/go to previous fast search match" :space-after)

(cl-loop for char in
	 (list ?a ?b ?c ?d ?e ?f ?g ?h ?i ?j ?k ?l ?m ?n ?o ?p ?q ?r ?s ?t ?u ?v ?w ?x ?y ?z
	       ?A ?B ?C ?D ?E ?F ?G ?H ?I ?J ?K ?L ?M ?N ?O ?P ?Q ?R ?S ?T ?U ?V ?W ?X ?Y ?Z
	       ?1 ?2 ?3 ?4 ?5 ?6 ?7 ?8 ?9 ?0
	       ?\( ?\) ?. ?? ?*
	       ?- ?_
	       32) do
	       (efar-register-key	(char-to-string char)	'efar-fast-search	char	nil	""))

;; create customization entries for key bindings
(cl-loop for key in efar-keys do
	 (when (nth 3 key)
	   (custom-declare-variable
	    (intern (symbol-name (nth 3 key)))
	    (kbd (nth 0 key))
	    (nth 4 key)
	    :type 'key-sequence
	    :group 'efar-keys)))


;;--------------------------------------------------------------------------------
;; eFar main functions
;;--------------------------------------------------------------------------------
;;;###autoload
(defun efar (arg &optional reinit? no-switch?)
  "Main function to run eFar commander.
When ARG is t open default directory of current buffer.
When REINIT? is t then current eFar state is discarded and it is reinitialized.
When NO-SWITCH? is t then don't switch to eFar buffer."
  (interactive "P")
  (let
      ;; if eFar buffer doesn't exist, we need to do initialisation
      ((need-init? (or reinit? (not (get-buffer efar-buffer-name))))
       ;; get existing or create new eFar buffer
       (efar-buffer (get-buffer-create efar-buffer-name))
       ;; if eFar is called with prefix argument, then go to default-directory of current buffer
       (go-to-dir (when arg default-directory)))
    
    (with-current-buffer efar-buffer
      
      (unless (equal major-mode 'efar-mode)
	(efar-mode))
      ;; do initialisation if necessary and redraw the content of the buffer
      (when need-init?
	(efar-init)
	
	;; make search processes
	;; we do this in advance to speed up search process
	(make-thread 'efar-run-search-processes)
	
	(efar-calculate-window-size)
	(efar-calculate-widths)
	(efar-go-to-dir (efar-get :panels :left :dir) :left)
	(efar-go-to-dir (efar-get :panels :right :dir) :right)
	(efar-write-enable
	 (efar-redraw)))
      
      ;; go to default-directory of current buffer if function is called with prefix argument
      (when go-to-dir
	(efar-go-to-dir go-to-dir :left)
	(efar-write-enable (efar-redraw)))
      
      (unless no-switch? (efar-suggest-hint)))
    
    (unless (or no-switch?
		(equal efar-buffer (current-buffer)))
      (switch-to-buffer-other-window efar-buffer))
    (efar-write-enable (efar-redraw))))


(defun efar-init (&optional reinit?)
  "Set up main eFAR configuration.
This function is executed only once when eFAR buffer is created.

REINIT? is a boolean indicating that configuration should be generated enew."
  
  ;; disable cursor
  (setq cursor-type nil)
  
  ;; if saving/restoring of state is allowed then read state from file
  (when (and
	 efar-save-state-p
	 (file-exists-p efar-state-file-name))
    (efar-read-state))
  
  ;; if eFAR state cannot be restored from file (missing or broken file) or saving/restoring of state is disabled
  ;; then initialize state storage with default values
  (when (or reinit?
	    (null efar-state))
    (setf efar-state nil)
    (efar-init-state)))

(defun efar-init-state ()
  "Initialize state with default values."
  (setf efar-state (make-hash-table :test `equal))
  
  ;; set directories for both panels
  (efar-set (car efar-default-startup-dirs) :panels :left :dir)
  (efar-set (cdr efar-default-startup-dirs) :panels :right :dir)
  
  ;; make left panel active
  (efar-set :left :current-panel)
  
  ;; set cursor to the first file for both panels
  (efar-set 0 :panels :left :current-pos)
  (efar-set 0 :panels :right :current-pos)
  
  (efar-set '() :panels :left :selected)
  (efar-set '() :panels :right :selected)
  
  (efar-set 0 :panels :left :start-file-number)
  (efar-set 0 :panels :right :start-file-number)
  
  (efar-set nil :fast-search-string)
  (efar-set 0 :fast-search-occur)
  
  (efar-set nil :notification-timer)
  
  (efar-set "" :panels :left :file-filter)
  (efar-set "" :panels :right :file-filter)
  
  (efar-set nil :panels :left :file-notifier)
  (efar-set nil :panels :right :file-notifier)
  
  (efar-set :files :panels :left :mode)
  (efar-set :files :panels :right :mode)
  
  (efar-set '() :pending-notifications)
  
  (efar-set nil :panels :left :sort-order)
  (efar-set nil :panels :right :sort-order)
  
  (efar-set "Name" :panels :left :sort-function-name)
  (efar-set "Name" :panels :right :sort-function-name)
  
  (efar-set :both :mode)
  
  (efar-set nil :column-widths)
  
  (efar-set "Ready" :status)
  (efar-set nil :reset-status?)
  
  (efar-set 1 :panels :left :view :files :column-number)
  (efar-set '(:short :long :detailed :full) :panels :left :view :files :file-disp-mode)
  (efar-set 1 :panels :left :view :dir-hist :column-number)
  (efar-set '(:long) :panels :left :view :dir-hist :file-disp-mode)
  (efar-set 1 :panels :left :view :file-hist :column-number)
  (efar-set '(:long) :panels :left :view :file-hist :file-disp-mode)
  (efar-set 1 :panels :left :view :bookmark :column-number)
  (efar-set '(:long) :panels :left :view :bookmark :file-disp-mode)
  (efar-set 1 :panels :left :view :disks :column-number)
  (efar-set '(:long) :panels :left :view :disks :file-disp-mode)
  (efar-set 1 :panels :left :view :search :column-number)
  (efar-set '(:long) :panels :left :view :search :file-disp-mode)
  
  (efar-set 1 :panels :right :view :files :column-number)
  (efar-set '(:short :long :detailed :full) :panels :right :view :files :file-disp-mode)
  (efar-set 1 :panels :right :view :dir-hist :column-number)
  (efar-set '(:long) :panels :right :view :dir-hist :file-disp-mode)
  (efar-set 1 :panels :right :view :file-hist :column-number)
  (efar-set '(:long) :panels :right :view :file-hist :file-disp-mode)
  (efar-set 1 :panels :right :view :bookmark :column-number)
  (efar-set '(:long) :panels :right :view :bookmark :file-disp-mode)
  (efar-set 1 :panels :right :view :disks :column-number)
  (efar-set '(:long) :panels :right :view :disks :file-disp-mode)
  (efar-set 1 :panels :right :view :search :column-number)
  (efar-set '(:long) :panels :right :view :search :file-disp-mode)
  
  (efar-set nil :last-auto-read-buffer)
  
  (efar-set '() :directory-history)
  (efar-set '() :bookmarks)
  (efar-set '() :file-history)
  
  (efar-set 0 :splitter-shift)
  
  (efar-set 0 :next-hint-number))

(defun efar-get (&rest keys)
  "Get value stored by KEYS."
  (let ((value nil))
    (mapc
     (lambda(key)
       (if value
	   (setf value (gethash key value))
	 (setf value (gethash key efar-state))))
     keys)
    value))

(defun efar-set (value &rest keys)
  "Store VALUE by KEYS."
  (let ((place nil))
    (mapc
     (lambda(key)
       (if place
	   (setf place (puthash key (gethash key place (make-hash-table :test `equal)) place))
	 (setf place (puthash key (gethash key efar-state (make-hash-table :test `equal)) efar-state))))
     
     (cl-subseq keys 0 -1))
    
    (puthash (car (cl-subseq keys -1)) value (or place efar-state))))

;;--------------------------------------------------------------------------------
;; file sort functions
;;--------------------------------------------------------------------------------
(defconst efar-sort-functions '(("Name" . efar-sort-files-by-name)
				("Date" . efar-sort-files-by-modification-date)
				("Extension" . efar-sort-files-by-extension)
				("Size" . efar-sort-files-by-size)
				("Unsorted" . nil)))

(defun efar-get-sort-function (name)
  "Return sort function by NAME."
  (cdr (assoc name efar-sort-functions)))


(defun efar-sort-function-names (side)
  "Return a list of sort function names.
The name of a function which is currently used for the panel SIDE (or current panel) becomes a first entry in the list."
  (let ((current-function-name (efar-get :panels side :sort-function-name)))
    (append (list current-function-name)
	    (cl-remove current-function-name
		       (mapcar
			(lambda(e)
			  (car e))
			efar-sort-functions)
		       :test 'equal))))

(defun efar-sort-files-by-name (a b)
  "Function to sort files A and B by name.
Directories always go before normal files.
Function string< is used for comparing file names.
Case is ignored."
  (cond
   ;; directories go first
   ((and (cadr a) (not (cadr b)))
    t)
   ((and (not (cadr a)) (cadr b))
    nil)
   ;; entries of same type (directory or usual files) sorted in lexicographic order
   (t (string<
       (downcase (car a))
       (downcase (car b))))))

(defun efar-sort-files-by-modification-date (a b)
  "Function to sort files A and B by modification date.
Directories always go before normal files."
  (cond
   ;; directories go first
   ((and (cadr a) (not (cadr b)))
    t)
   ((and (not (cadr a)) (cadr b))
    nil)
   ;; entries of same type (directory or usual files) sorted by comparing modification date
   (t (<
       (time-to-seconds (nth 6 a))
       (time-to-seconds (nth 6 b))))))

(defun efar-sort-files-by-size (a b)
  "Function to sort files A and B by file size.
Directories always go before normal files."
  (cond
   ;; directories go first
   ((and (cadr a) (not (cadr b)))
    t)
   ((and (not (cadr a)) (cadr b))
    nil)
   ;; entries of same type (directory or usual files) sorted by comparing file size
   (t (<
       (nth 8 a)
       (nth 8 b)))))

(defun efar-sort-files-by-extension (a b)
  "Function to sort files A and B by type (extension).
Directories always go before normal files.
Function string< is used for comparing file extensions.
Case is ignored."
  (cond
   ;; directories go first
   ((and (cadr a) (not (cadr b)))
    t)
   ((and (not (cadr a)) (cadr b))
    nil)
   ;; files sorted by extension (if any) in lexicographic order
   (t (string<
       (downcase (or (file-name-extension (car a)) ""))
       (downcase (or (file-name-extension (car b)) ""))))))

(defun efar-change-sort-function ()
  "Ask user for sort function and order and set them for panel SIDE."
  (let ((side (efar-get :current-panel)))
    (efar-set (efar-completing-read "Sort files by" (efar-sort-function-names side))
	      :panels side :sort-function-name)
    
    (efar-set (string= (char-to-string 9660) (efar-completing-read "Sort order" (list (char-to-string 9650) (char-to-string 9660) )))
	      :panels side :sort-order)
    (efar-refresh-panel side nil (efar-get-short-file-name (efar-current-file)))))

;;--------------------------------------------------------------------------------
;; file notification functions
;;--------------------------------------------------------------------------------

(defun efar-setup-notifier (dir side)
  "Set up file-notify-watch for the directory DIR and register it for panel SIDE."
  ;; first remove existing file-notify-watch
  (efar-remove-notifier side)
  
  (let* ((other-side-notifier (efar-get :panels (efar-other-side side) :file-notifier))
	 (descriptor
	  ;; if file-notify-watch for given DIR is already registered for other panel and it is valid, use it
	  (if (and
	       (string= (car other-side-notifier) dir)
	       (file-notify-valid-p (cdr other-side-notifier)))
	      (cdr other-side-notifier)
	    ;; otherwise create new one
	    (file-notify-add-watch dir '(change attribute-change) 'efar-notification))))
    
    (efar-set (cons dir descriptor) :panels side :file-notifier)))


(defun efar-remove-notifier (side &optional dont-check-other)
  "Remove file-notify-watch registered for panel SIDE.
If same watch is registered for other panel, then don't remove the watch, but just unregister it for panel SIDE, unless DONT-CHECK-OTHER is t"
  (let ((descriptor (cdr (efar-get :panels side :file-notifier)))
	(other-descriptor (cdr (efar-get :panels (efar-other-side side) :file-notifier))))
    (when (or dont-check-other (not (equal descriptor other-descriptor)))
      (file-notify-rm-watch descriptor))
    (efar-set nil :panels side :file-notifier)))

(defun efar-notification (event)
  "Callback function triggered when a file EVENT occurs.
It stores notification in the queue and runs timer for 1 second.
Notifications in the queue will be processed only if there are no new notifications within 1 second."
  (let ((descriptor (car event))
	(event-type (nth 1 event)))
    
    ;; for any event except 'stopped
    (unless (equal event-type 'stopped)
      ;; if eFAR buffer exists
      (when (get-buffer efar-buffer-name)
	
	;; if there is yet no notifications in the queue for given descriptor
	;; add descriptor to the queue
	(let ((pending-notifications (efar-get :pending-notifications)))
	  (unless (member descriptor pending-notifications)
	    (push descriptor pending-notifications)
	    (efar-set pending-notifications :pending-notifications)))
	
	;; if there is a running timer, cancel it
	(let ((timer (efar-get :notification-timer)))
	  (when timer (cancel-timer timer))
	  ;; create new timer
	  (efar-set (run-at-time "1 sec" nil
				 (lambda()
				   (efar-process-pending-notifications)))
		    :notification-timer))))))


(defun efar-process-pending-notifications ()
  "Process all pending file notifications."
  ;; while there are notifications in a queue
  (while
      ;; pop next notification
      (let* ((pending-notifications (efar-get :pending-notifications))
	     (descriptor (prog1
			     (pop pending-notifications)
			   (efar-set pending-notifications :pending-notifications))))
	(when descriptor
	  ;; if event comes from the watcher registered for left panel directory, refersh left panel
	  (when (equal descriptor (cdr (efar-get :panels :left :file-notifier)))
	    (efar-refresh-panel :left))
	  ;; if event comes from the watcher registered for right panel directory, refersh right panel
	  (when (equal descriptor (cdr (efar-get :panels :right :file-notifier)))
	    (efar-refresh-panel :right))))))

;;--------------------------------------------------------------------------------
;; save/resore state functions
;;--------------------------------------------------------------------------------

(defun efar-remove-file-state ()
  "Remove eFar state file.  Could be helpful in case of errors during startup."
  (interactive)
  (delete-file efar-state-file-name))

(defun efar-save-state ()
  "Save eFar state to the state file.  Data from this file is used during startup to restore last state."
  (with-temp-file efar-state-file-name
    (let ((copy (copy-hash-table efar-state)))
      
      ;; clear up data not relevant for saving
      (puthash :file-notifier nil (gethash :left (gethash :panels copy)))
      (puthash :file-notifier nil (gethash :right (gethash :panels copy)))
      (puthash :notification-timer nil copy)
      (puthash :pending-notifications () copy)
      (puthash :files () (gethash :left (gethash :panels copy)))
      (puthash :files () (gethash :right (gethash :panels copy)))
      (puthash :selected () (gethash :left (gethash :panels copy)))
      (puthash :selected () (gethash :right (gethash :panels copy)))
      
      (puthash :last-auto-read-buffer nil copy)
      
      ;; add eFar version tag
      (puthash :version efar-version copy)
      
      (print copy (current-buffer)))))

(defun efar-read-state ()
  "Read eFar state from the file."
  (setf efar-state
	(efar-check-state-file-version
	 (with-temp-buffer
	   (insert-file-contents efar-state-file-name)
	   (cl-assert (bobp))
	   (read (current-buffer))))))

(defun efar-check-state-file-version (state)
  "Check version of STATE file and upgrade it if necessary."
  (let ((state-version (or (gethash :version state) 0.0)))
    (cond
     ;; if current eFar version matches version stored in state file
     ;; then we have nothing to do - we use loaded state
     ((equal efar-version state-version)
      (message "eFar state loaded from file %s" efar-state-file-name)
      state)
     
     ;; else if curent version of eFar is lower then version stored in state file
     ;; we have to skip loading state
     ((< efar-version state-version)
      (message "Version of state file is greater then eFar version. State file loading skipped...")
      nil)
     
     ;; else if current eFar version is greater then version stored in state file
     ;; we do "upgrade" of state file
     (t
      (copy-file efar-state-file-name (concat efar-state-file-name "_" (int-to-string state-version)) 1)
      (efar-upgrade-state-file state state-version)))))

(defun efar-upgrade-state-file (state from-version)
  "Upgrade state file.
Do necessary changes in STATE in order to switch
from version FROM-VERSION to actual version."
  (let ((copy (copy-hash-table state)))
    (setq efar-state copy)
    (condition-case err
	(progn
	  ;; 0.9 -> 1.0
	  (when (< from-version 1.0)
	    ;; transform :directory-history to keep date
	    (let ((dir-history (mapcar (lambda(e) (cons (car e) (list (cons :side (cdr e)) (cons :time nil))))
				       (gethash :directory-history efar-state))))
	      (puthash :directory-history dir-history efar-state))
	    
	    ;; add file-history
	    (puthash :file-history '() efar-state)
	    (efar-set 1 :panels :left :view :file-hist :column-number)
	    (efar-set '(:long) :panels :left :view :file-hist :file-disp-mode)
	    (efar-set 1 :panels :right :view :file-hist :column-number)
	    (efar-set '(:long) :panels :right :view :file-hist :file-disp-mode)
	    (message "State file upgraded to version 1.0"))
	  
	  ;; 1.12 -> 1.13
	  (when (< from-version 1.13)
	    (efar-set '(:short :long :detailed :full) :panels :right :view :files :file-disp-mode)
	    (efar-set '(:short :long :detailed :full) :panels :left :view :files :file-disp-mode)
	    (message "State file upgraded to version 1.13"))
	  
	  ;; 1.17 -> 1.18
	  (when (< from-version 1.18)
	    (efar-set '() :panels :left :selected)
	    (efar-set '() :panels :left :selected)
	    (message "State file upgraded to version 1.17")))
      
      (error
       (message "Error occured during upgrading state file: %s. State file skipped." (error-message-string err))
       (setf efar-state nil)))
    
    efar-state))

;;------------------------------------------------------------------
;; efar file operations
;;------------------------------------------------------------------
(defun efar-create-new-directory ()
  "Create new directory."
  
  (efar-with-notification-disabled
   (let ((new-dir-name (read-string "Input name for new directory: "))
	 (side (efar-get :current-panel)))
     
     ;; try to create a directory
     (efar-retry-when-error
      (make-directory new-dir-name nil))
     
     ;; refresh panel and move selection
     (efar-refresh-panel side nil new-dir-name)
     
     ;; if other panel displays same directory as current one, refresh it as well
     (when (string= (efar-get :panels side :dir) (efar-get :panels (efar-other-side) :dir))
       (efar-refresh-panel (efar-other-side))))))


(defun efar-copy-or-move-files (operation &optional dest)
  "Copy or move selected files depending on OPERATION.
When DEST is given then use this path as destination path.
Otherwise ask user where to copy/move files to."
  (unwind-protect
      (progn
	(let ((use-dialog-box nil))
	  (efar-with-notification-disabled
	   (let* ((side (efar-get :current-panel))
		  (todir  (let ((todir (efar-get :panels (efar-other-side) :dir)))
			    (if (file-exists-p todir)
				todir
			      (efar-get :panels side :dir))))
		  (files (efar-selected-files side nil)))
	     
	     (when files
	       
	       (let ((destination (or dest
				      (read-directory-name (if (equal operation :copy)
							       "Copy selected file(s) to "
							     "Move selected file(s) to ")
							   (file-name-as-directory todir)
							   nil
							   nil
							   ;;when only one file is selected we add file name to proposed path
							   (when (equal (length files) 1) (efar-get-short-file-name (car files)))))))
		 
		 (efar-set-status (if (equal operation :copy)
				      "Copying files..."
				    "Moving files..."))
		 
		 (efar-copy-or-move-files-int (pcase operation
						(:copy :copy)
						(:move :move)
						(:rename :move))
					      files destination)))
	     
	     (efar-refresh-panel :left)
	     (efar-refresh-panel :right))))
	
	(efar-set-status "Ready"))))

(defun efar-copy-or-move-files-int (operation files todir &optional fromdir overwrite?)
  "Copy or move (depending on OPERATION) FILES into TODIR.
When FROMDIR is not defined then `default-directory' is used.
OVERWRITE? is a boolean indicating that existing files have to be overwritten.
Existing files can be skipped or overwritten depending on user's choice.
User also can select an option to overwrite all remaining files to not be asked multiple times."
  (cl-labels ;; make local recursive function (needed to share variable overwrite? in recursion)
      ((do-operation (operation files todir fromdir)
		     ;; if FROMDIR is not set, we use default-directory as source directory
		     (let ((default-directory (if fromdir fromdir default-directory)))
		       
		       (mapc ;; for each file in FILES
			(lambda (f)
			  ;; skip files "." and ".."
			  (unless (or (string= (car f) ".") (string= (car f) ".."))
			    ;; get new file name in destination folder
			    (let ((newfile
				   (if (file-directory-p todir)
				       (expand-file-name (efar-get-short-file-name f) todir)
				     todir)))
			      
			      (cond
			       ;; if file is a real file and doesn't exist in destination folder
			       ((and (not (equal (cadr f) t)) (not (file-exists-p newfile)))
				;; we just copy it using elisp function
				
				(if (equal operation :copy)
				    (efar-retry-when-error (copy-file (car f) newfile))
				  (efar-retry-when-error (rename-file (car f) newfile nil))))
			       
			       
			       ;; if file is a directory and doesn't exist in destination folder
			       ((and (equal (cadr f) t) (not (file-exists-p newfile)))
				;; we just copy directory using elisp function
				(if (equal operation :copy)
				    (efar-retry-when-error (copy-directory (car f) newfile nil nil nil))
				  (efar-retry-when-error (rename-file (car f) newfile))))
			       
			       ;; if file is a real file and does exist in destination folder
			       ((and (not (equal (cadr f) t)) (file-exists-p newfile))
				(progn
				  ;; we ask user what to do (overwrite, not overwrite, overwrite all remaining)
				  ;; if user was already asked before and the answer was "All", we don't ask again
				  (setf overwrite? (cond
						    ((or (null overwrite?) (string= overwrite? "No") (string= overwrite? "Yes"))
						     (efar-completing-read (concat "File " newfile " already exists. Overwrite? ") (list "Yes" "No" "All")))
						    (t overwrite?)))
				  ;; we copy file (overwrite) using elisp function if user approved it
				  (unless (string= overwrite? "No")
				    (if (equal operation :copy)
					(efar-retry-when-error (copy-file (car f) newfile t nil nil nil))
				      (efar-retry-when-error (rename-file (car f) newfile t))))))
			       
			       ;; if file is a directory and does exist in destination folder
			       ((and (equal (cadr f) t) (file-exists-p newfile))
				;; we call local function recursively
				(do-operation operation (directory-files-and-attributes (car f) nil nil t 'string) newfile (expand-file-name (efar-get-short-file-name f) default-directory) )
				(when (equal operation :move)
				  (delete-directory (car f))))))))
			
			files))))
    ;; call local function first time
    (do-operation operation files todir fromdir)) )

(defun efar-completing-read (prompt &optional options)
  "Read a string in the minibuffer, with completion.
PROMPT is a string to prompt with.
OPTIONS is a collection with possible answers."
  (let* ((completion-ignore-case t)
	 (options (or options '("Yes" "No")))
	 (prompt (concat prompt " ("
			 (mapconcat #'identity options " | ")
			 ") ")))
    (completing-read prompt options nil t nil 'options (car options))))

(defun efar-delete-selected ()
  "Delete selected file(s)."
  (unwind-protect
      (efar-with-notification-disabled
       (let* ((side (efar-get :current-panel))
	      (selected-files (efar-selected-files side nil)))
	 ;; ask user for confirmation
	 (when (and selected-files (string= "Yes" (efar-completing-read "Delete selected files?")))
	   ;; do the deletion of selected files
	   (efar-set-status "Deleting files...")
	   (mapc(lambda (f)
		  (if (equal (cadr f) t)
		      (efar-retry-when-error (delete-directory (car f) t))
		    (efar-retry-when-error (delete-file (car f)))))
		selected-files)
	   
	   (efar-refresh-panel side)
	   
	   (when (string= (efar-get :panels side :dir) (efar-get :panels (efar-other-side) :dir))
	     (efar-refresh-panel (efar-other-side)))))))
  
  (efar-set-status "Ready"))

(defun efar-set-file-modes ()
  "Set file modes for selected items."
  (unwind-protect
      (efar-with-notification-disabled
       (let* ((side (efar-get :current-panel))
	      (selected-files (efar-selected-files side nil)))
	 (when selected-files
	   (let ((modes (read-file-modes)))
	     (efar-set-status "Setting mode for selected files...")
	     (mapc (lambda (f)
		     (efar-retry-when-error (set-file-modes (car f) modes)))
		   selected-files))
	   
	   (efar-refresh-panel side nil nil)
	   
	   (when (string= (efar-get :panels side :dir) (efar-get :panels (efar-other-side) :dir))
	     (efar-refresh-panel (efar-other-side)))))))
  
  (efar-set-status "Ready"))

;;------------------------------------------------------------------
;; efar displaying status
;;------------------------------------------------------------------

(defun efar-reset-status ()
  "Reset eFar status to default one."
  (when (efar-get :reset-status?)
    (efar-set-status "Ready")))

(defun efar-set-status (&optional status seconds reset?)
  "Set eFar status to STATUS.
When STATUS is nil use default 'Ready' status.
When SECONDS is defined then status is displayed given time.
When RESET? is t then status will be automatically changed to default
on any next cursor movement."
  (with-current-buffer efar-buffer-name
    
    (when reset?
      (efar-set t :reset-status?))
    
    (let ((prev-status (efar-get :status))
	  (status (or status "Ready")))
      
      (efar-set status :status)
      (setq mode-line-format (list " " mode-line-modes (or status (efar-get :status))))
      (force-mode-line-update)
      
      (when seconds
	(run-at-time seconds nil
		     `(lambda()
			(efar-set-status ',prev-status)))))))

(defun efar-key-press-handle (func arg ignore-in-modes)
  "Handler for registered key-bindings.
This handler calls function FUNC with argument ARG only in case when current
mode is not in the list IGNORE-IN-MODES."
  (let ((mode (efar-get :panels (efar-get :current-panel) :mode)))
    (when (consp func)
      (setq func (symbol-function (cdr (assoc mode func)))))
    
    (if (cl-member mode ignore-in-modes)
	(efar-set-status (concat "Function is not allowed in mode " (symbol-name mode)) nil t)
      (if arg
	  (funcall func arg)
	(funcall func)))))

(defun efar-show-help ()
  "Display a buffer with list of registered Efar key bindings."
  (interactive)
  (let ((buffer (get-buffer-create "*Efar key bindings*")))
    (with-current-buffer buffer
      (read-only-mode -1)
      (erase-buffer)
      
      (cl-loop for key in (reverse efar-keys) do
	       (when (nth 5 key)
		 (let ((key-seq (if (null (nth 3 key)) (nth 0 key) (symbol-value (nth 3 key)))))
		   (insert (key-description key-seq) "\t"  (nth 4 key) "\n")))
	       (when (equal :space-after (nth 5 key))
		 (insert "\n")))
      
      (align-regexp (point-min) (point-max) "\\(\\s-*\\)\t")
      (goto-char 0)
      (read-only-mode 1)
      (setq-local mode-line-format nil)
      (local-set-key (kbd "q") 'delete-frame))
    
    (display-buffer buffer)))


(defun efar-process-mouse-event (event)
  "Process mouse event EVENT."
  (select-window (get-buffer-window efar-buffer-name))
  
  (let ((click-type (car event)))
    
    (cond
     ;; BUTTON DOWN
     ((or (equal "down-mouse-1" (symbol-name click-type))
	  (equal "C-down-mouse-1" (symbol-name click-type))
	  (equal "S-down-mouse-1" (symbol-name click-type)))
      (efar-process-mouse-down event))
     
     
     ;; MOUSE DRAG HAPPENED
     ((or (equal "drag-mouse-1" (symbol-name click-type))
	  (equal "C-drag-mouse-1" (symbol-name click-type)))
      (efar-process-mouse-drag event))
     
     ;; MOUSE WHEEL SCROLLED
     ((string-match-p "wheel-" (symbol-name click-type))
      (efar-process-mouse-wheel event))
     
     ;; BUTTON CLICKED
     ((or (equal "mouse-1" (symbol-name click-type))
	  (equal "double-mouse-1" (symbol-name click-type))
	  (equal "C-mouse-1" (symbol-name click-type))
	  (equal "S-mouse-1" (symbol-name click-type)))
      (efar-process-mouse-click event))))
  
  ;; finally redraw if necessary
  (efar-write-enable (efar-redraw)))

(defun efar-process-mouse-down (event)
  "Do actions when mouse button is pressed.
The point where mouse click occurred determined out of EVENT parameters."
  (let* ((pos (nth 1 (nth 1 event)))
	 (props (plist-get (text-properties-at pos) :control))
	 (side (cdr (assoc :side props)))
	 (control (cdr (assoc :control props))))
    
    (setf efar-mouse-down-p t)
    
    ;; when clicked on file entry select it
    (when (equal control :file-pos)
      (efar-set (cdr (assoc :file-number props)) :panels side :current-pos))
    ;; switch to panel if necessarry
    (when (and side
	       (cdr (assoc :switch-to-panel props))
	       (not (equal (efar-get :current-panel) side)))
      (efar-switch-to-other-panel))))

(defun efar-process-mouse-drag (event)
  "Do actions when drag&drop action occurrs.
The start and end points of drag&drop action determined out of EVENT parameters."
  (let* ((click-type (car event))
	 (source (nth 1 (nth 1 event)))
	 (source-props (plist-get (text-properties-at source) :control))
	 (source-side (cdr (assoc :side source-props)))
	 (source-control (cdr (assoc :control source-props)))
	 (operation (if (equal "C-drag-mouse-1" (symbol-name click-type))
			:copy :move)))
    
    (setf efar-mouse-down-p nil)
    
    (let ((destination (nth 0 (nth 2 event))))
      
      (pcase (type-of destination)
	
	;; DRAG&DROP WITHIN EMACS frame
	('window
	 (let ((dest-props (plist-get (text-properties-at (nth 1 (nth 2 event))
							  (window-buffer destination)) :control)))
	   ;; if dragged to eFar
	   (if (equal destination (get-buffer-window efar-buffer-name))
	       
	       (cond
		;; when panel splitter is dragged
		((equal source-control :splitter)
		 ;; calulate the distance and move the splitter
		 (let* ((shift (- (car (nth 6 (nth 1 event)))
				  (car (nth 6 (nth 2 event)))))
			(percentage (/ (* (abs shift) 100) (floor (efar-get :window-width) 2))))
		   (efar-move-splitter (if (< shift 0) (* percentage -1) percentage))))
		
		;; else we process dragging in :files mode only
		(t (when (equal (efar-get :panels source-side :mode) :files)
		     (let* ((dest-side (cdr (assoc :side dest-props)))
			    (dest-control (cdr (assoc :control dest-props)))
			    (dest-file (cdr (assoc :file-name dest-props))))
		       
		       (when (equal (efar-get :panels dest-side :mode) :files)
			 (cond
			  ;; dragged to the same panel
			  ((equal source-side dest-side)
			   
			   (cond
			    ;; if button released over file entry
			    ((equal dest-control :file-pos)
			     (when (file-directory-p dest-file)
			       (efar-copy-or-move-files operation dest-file)))
			    
			    ;; else if button released over any other panel area
			    (t
			     (let ((files (efar-selected-files source-side nil nil t)))
			       (when (equal source-control :file-pos)
				 ;; we make a copy of selected files by new names
				 (cl-loop for file in files do
					  (efar-copy-or-move-files-int :copy (list file) (expand-file-name (concat "copy_" (efar-get-short-file-name file)) (efar-get :panels dest-side :dir))))
				 (efar-get-file-list dest-side))))))
			  
			  ;; dragged to the other panel
			  (t
			   (efar-copy-or-move-files operation
						    ;; when dropped on empty area or on a file
						    (if (or (string-empty-p dest-file)
							    (not (file-directory-p dest-file)))
							;; then copy/move files to the directory of other panel
							(efar-get :panels dest-side :dir)
						      ;; else if dropped on an directory item then copy/move to that directory
						      dest-file)))))))))
	     
	     ;; else if dragged to another buffer
	     ;; then we just open file in another buffer
	     (let ((file (caar (efar-selected-files source-side t nil t))))
	       (when (and (equal source-control :file-pos)
			  file)
		 (set-window-buffer destination (find-file-noselect file)))))))
	
	
	;; DRAG&DROP OUTSIDE EMACS (not suported)
	('frame (message-box "Drag&drop to outside world is not supported."))))))


(defun efar-process-mouse-click (event)
  "Do actions when mouse button released.
The point where mouse click occurred determined out of EVENT parameters."
  
  (setf efar-mouse-down-p nil)
  
  (let* ((click-type (car event))
	 (pos (nth 1 (nth 1 event)))
	 (props (plist-get (text-properties-at pos) :control))
	 (side (cdr (assoc :side props)))
	 (files (efar-get :panels side :files))
	 (control (cdr (assoc :control props))))
    
    ;; when single click on a file entry - auto read file
    (when (and (equal control :file-pos)
	       (equal click-type 'mouse-1))
      (efar-auto-read-file))
    
    ;; when clicked with ctrl we mark single item
    (when (equal click-type 'C-mouse-1)
      (efar-mark-file t))
    
    ;; when clicked with shift we mark all items between clicked item and item marked last time
    (when (and (equal click-type 'S-mouse-1)
	       (equal control :file-pos))
      (let ((last-marked (cl-position-if
			  (lambda(e) (equal (car e) (caar (efar-get :panels side :selected))))
			  files))
	    (selected-file-number (+ (cdr (assoc :file-number props)) (efar-get :panels side :start-file-number)))
	    (selected '()))
	(if (not last-marked)
	    (efar-mark-file t)
	  
	  (cl-loop for n in (number-sequence last-marked
					     selected-file-number
					     (if (< last-marked selected-file-number) 1 -1))
		   do (push (nth n files) selected))
	  (efar-set selected :panels side :selected))))
    
    ;;when double clicked
    (when (equal click-type 'double-mouse-1)
      (if (equal control :splitter)
	  (efar-move-splitter :center))
      (when (and (equal side (efar-get :current-panel))
		 (equal control :file-pos))
	(execute-kbd-macro (read-kbd-macro (symbol-value 'efar-enter-directory-key)))))
    
    ;; when clicked on sorting controls
    (when (or (equal control :sort-func)
	      (equal control :sort-order))
      ;; if clicked on sort func control then change sort function to the next one
      (and (equal control :sort-func)
	   (efar-set (let ((p (cl-position (efar-get :panels side :sort-function-name) efar-sort-functions :test (lambda(a b) (equal (car b) a)))))
		       (cond ((equal p (- (length efar-sort-functions) 1))
			      (caar efar-sort-functions))
			     (t (car (nth (+ p 1) efar-sort-functions)))))
		     :panels side :sort-function-name))
      ;; if clicked on sort order control then switch sort order
      (and (equal control :sort-order)
	   (efar-set (not (efar-get :panels side :sort-order)) :panels side :sort-order))
      (efar-get-file-list side))
    
    ;; when clicked on col number control
    (when (equal control :col-number)
      (pcase (char-to-string (char-after pos))
	("+" (efar-change-column-number t side))
	("-" (efar-change-column-number nil side))))
    
    ;;when clicked maximize
    (when (equal control :maximize)
      (efar-change-mode side))
    
    ;; when clicked on file display mode switcher
    (when (equal control :file-disp-mode)
      (efar-change-file-disp-mode side))
    
    ;; when clicked on a directory name header
    ;; we show disks/mount points selector
    (when (equal control :directory-name)
      (efar-change-panel-mode :disks side))))

(defun efar-process-mouse-wheel (event)
  "Do actions when mouse wheel is scrolled.
The point where mouse scroll occurred determined out of EVENT parameters."
  (efar-move-cursor (if (string-match-p "down$" (symbol-name (car event)))
			:right
		      :left)
		    'no-auto-read))

(defun efar-cd ()
  "Open directory selector (read-directory-name) and go to selected directory."
  (efar-go-to-dir (read-directory-name "Go to directory: " default-directory))
  (efar-write-enable (efar-redraw)))

(defun efar-change-column-number (&optional increase side)
  "Change the number of columns in panel SIDE if given or in current panel.
Increase by 1 when INCREASE is t, decrease by 1 otherwise."
  (let* ((side (or side (efar-get :current-panel)))
	 (panel-mode (efar-get :panels side :mode))
	 (increase (or increase nil)))
    
    (if increase
	(when (< (efar-get :panels side :view panel-mode :column-number) 5)
	  (efar-set (+ (efar-get :panels side :view panel-mode :column-number) 1) :panels side :view panel-mode :column-number))
      (when (> (efar-get :panels side :view panel-mode :column-number) 1)
	(efar-set (- (efar-get :panels side :view panel-mode :column-number) 1) :panels side :view panel-mode :column-number)
	(let ((file (car (efar-current-file side))))
	  (unless (string= file "..") (efar-go-to-file file side))))))
  
  (efar-calculate-widths)
  (efar-write-enable (efar-redraw)))

(defun efar-change-mode (&optional side)
  "Switch mode from double to single-panel or vice versa.
If a double mode is active then panel SIDE (or active one if not given)
becomes fullscreen."
  (let ((current-mode (efar-get :mode))
	(side (or side (efar-get :current-panel))))
    (efar-set (cond
	       ((equal current-mode :both) side)
	       (t :both))
	      :mode)
    (when (equal current-mode :both)
      (efar-set side :current-panel))
    
    (efar-calculate-widths)
    (efar-write-enable (efar-redraw))))

(defun efar-open-dir-other-panel ()
  "Opens current pannel's direcotry in other panel."
  (efar-go-to-dir default-directory (efar-other-side))
  (efar-write-enable (efar-redraw)))

(defun efar-copy-current-path ()
  "Copies to the clipboard the full path to the current file or directory."
  (kill-new
   (caar
    (efar-selected-files (efar-get :current-panel) t t))))

(defun efar-open-file-in-ext-app ()
  "Open file under cursor in external application."
  (let* ((side (efar-get :current-panel))
	 (fnum (+ (efar-get :panels side :start-file-number) (efar-get :panels side :current-pos) ))
	 (file (nth fnum (efar-get :panels side :files)))
	 (@fname (expand-file-name (car file) (efar-get :panels side :dir))))
    
    (let* (
	   ($file-list
	    (if @fname
		(progn (list @fname))
	      (if (eq major-mode 'dired-mode)
		  (dired-get-marked-files)
		(list (buffer-file-name)))))
	   ($do-it-p (if (<= (length $file-list) 5)
			 t
		       (y-or-n-p "Open more than 5 files? "))))
      (when $do-it-p
	(cond
	 ((string-equal system-type "windows-nt")
	  (mapc
	   (lambda ($fpath)
	     (let ((f 'w32-shell-execute))
	       (funcall f nil $fpath))) $file-list))
	 ((string-equal system-type "darwin")
	  (mapc
	   (lambda ($fpath)
	     (shell-command
	      (concat "open " (shell-quote-argument $fpath))))  $file-list))
	 ((string-equal system-type "gnu/linux")
	  (mapc
	   (lambda ($fpath) (let ((process-connection-type nil))
			      (start-process "" nil "xdg-open" $fpath))) $file-list)))))))

(defun efar-filter-files ()
  "Set up file filtering in current panel.
Ask user for file mask and show files in current panel matching this mask only."
  (let ((side (efar-get :current-panel)))
    
    (efar-set (read-string "String to filter file names: " (efar-get :panels side :file-filter))
	      :panels side :file-filter)
    
    (efar-get-file-list side)
    (efar-set 0 :panels side :start-file-number)
    (efar-set 0 :panels side :current-pos)
    (efar-write-enable (efar-redraw))))

(defun efar-fast-search (k)
  "Activate and/or perform incremental search.
K is a character typed by the user."
  (let ((str (efar-get :fast-search-string)))
    
    ;; if a printable character was pressed
    ;; add it to the end of search string
    (unless (member k '(:next :prev :back :clear))
      (setf str (concat str (format "%c" k))))
    
    ;; if user entered at least one character
    ;; we can navigate to file(s) with matching name
    (when (and str
	       (not (string-empty-p  str)))
      
      ;; if user pressed DEL
      ;; then remove last character of the search string
      (when (equal k :back)
	(setf str (substring str 0 (- (length str) 1))))
      
      ;; get the list of files in current directory with names matching the search string
      (let* ((side (efar-get :current-panel))
	     (filtered-list (mapcan (lambda (e)
				      (when (string-match str (if (equal (efar-get :panels side :mode) :files)
								  (efar-get-short-file-name e)
								(car e)))
					(list (car e))))
				    (efar-get :panels side :files))))
	
	;; if user pressed key binding to go to next or previous occurence
	;; shift selector accordingly
	(cond ((equal k :next)
	       (if (= (+ (efar-get :fast-search-occur) 1) (length filtered-list))
		   (efar-set 0 :fast-search-occur)
		 (efar-set (+ 1 (efar-get :fast-search-occur)) :fast-search-occur)))
	      
	      ((equal k :prev)
	       (if (= (efar-get :fast-search-occur) 0)
		   (efar-set (- (length filtered-list) 1) :fast-search-occur)
		 (efar-set (- (efar-get :fast-search-occur) 1) :fast-search-occur))))
	
	;; store search string
	(efar-set str :fast-search-string)
	(efar-get-file-list side)
	
	;; navigate to matched file
	(let ((file-name (or (nth (efar-get :fast-search-occur) filtered-list) "")))
	  (efar-go-to-file file-name nil 0))
	
	(efar-write-enable (efar-redraw))))))


(defun efar-quit-fast-search (&optional no-refresh?)
  "Quite fast search mode.
When NO-REFRESH? is t the no eFar redraw occurs."
  (when efar-state
    (efar-set nil :fast-search-string)
    (efar-set 0 :fast-search-occur)
    (unless no-refresh?
      (let ((file (caar (efar-selected-files (efar-get :current-panel) t t))))
	(efar-get-file-list (efar-get :current-panel))
	(efar-go-to-file (or file "") nil 0)
	(efar-write-enable (efar-redraw))))))

(defun efar-get-accessible-directory-in-path (path)
  "Return first accessible directory in the PATH going from bottom to up.
If there are no accessible directories, return `user-emacs-directory'."
  
  ;; if directory PATH exists or is accessible
  (if (and (file-exists-p path)
	   (file-accessible-directory-p path))
      ;; return this directory
      (if (equal path "/")
	  path
	(string-trim-right path "[/]"))
    ;; else get parent directory
    (let ((parent-dir
	   (file-name-directory
	    (directory-file-name path))))
      ;; if we are in root directory already
      (if (string= parent-dir path)
	  ;; that means there are no accessible directories in the path and we return user-emacs-directory
	  user-emacs-directory
	;; otherwise check parent directory
	(efar-get-accessible-directory-in-path parent-dir )))))

(defun efar-refresh-panel (&optional side move-to-first? move-to-file-name)
  "Refresh given panel (or a current one when SIDE is not given).
When MOVE-TO-FIRST? is t move cursot to the first file.
When MOVE-TO-FILE-NAME is given then move cursor to the file with that name.
When DONT-UNMARK is t then marked items remains marked."
  (let* ((side (or side (efar-get :current-panel)))
	 (mode (efar-get :panels side :mode)))
    
    (when (equal mode :files)
      (efar-set (efar-get-accessible-directory-in-path (efar-get :panels side :dir))
		:panels side :dir))
    
    (efar-set nil :panels side :fast-search-string)
    
    (let ((current-file-name (cond
			      (move-to-first? "")
			      (move-to-file-name move-to-file-name)
			      (t (efar-current-file-name side))))
	  (current-file-number (if move-to-first? 0 (efar-current-file-number side))))
      
      (efar-get-file-list side)
      
      ;; keep selection of still existing files
      (let ((selected (efar-get :panels side :selected))
	    (files (efar-get :panels side :files)))
	(efar-set (cl-remove-if (lambda(e1)
				  (not (cl-member-if (lambda(e2)
						       (equal (car e1) (car e2)))
						     files)))
				selected)
		  :panels side :selected))
      
      (when (> (length (efar-get :panels side :files)) 0)
	(efar-go-to-file current-file-name side current-file-number)))
    
    (efar-write-enable (efar-redraw))))

(defun efar-go-to-dir (dir &optional side no-hist?)
  "Go to given DIR.
When SIDE is given show directory in this panel, otherwise in current one.
When NO-HIST? is t then DIR is not saved in the history list."
  (let* ((dir (when dir (efar-get-accessible-directory-in-path (expand-file-name dir))))
	 (side (or side (efar-get :current-panel)))
	 (current-dir (efar-get :panels side :dir))
	 (parent-dir (when (equal (efar-get :panels side :mode) :files) (efar-get-parent-dir current-dir)))
	 (go-to-parent? (string= dir parent-dir)))
    
    (when (eq side (efar-get :current-panel))
      (setf default-directory dir))
    
    (efar-set () :panels side :selected)
    (efar-set dir :panels side :dir)
    
    (efar-set nil :fast-search-string)
    
    (efar-set :files :panels side :mode)
    
    (efar-get-file-list side)
    
    ;; if we go to the directory which is a parent of current one
    ;; then we move cursor to the current directory in the list
    (if go-to-parent?
	(progn
	  (efar-go-to-file current-dir side 0))
      ;; otherwise go to the first item
      (progn
	(efar-set 0 :panels side :start-file-number)
	(efar-set 0 :panels side :current-pos)))
    
    ;; add directory in the list of last visited directories
    (unless no-hist?
      (let* ((current-hist (efar-get :directory-history))
	     (new-hist (cl-subseq (cl-remove-if (lambda(e) (equal dir (car e))) current-hist)
				  0 (when (> (length current-hist) efar-max-items-in-directory-history)
				      (- efar-max-items-in-directory-history 1)))))
	(push (cons (if (equal dir "/") dir (string-trim-right dir "[/]")) (list (cons :side side)  (cons :time (current-time)))) new-hist)
	
	(efar-set new-hist :directory-history)))
    
    ;; set up file change notification for the directory
    (efar-setup-notifier dir side)
    (efar-calculate-widths)
    (efar-write-enable (efar-redraw))))


(defun efar-get-parent-dir (dir)
  "Return parent directory of given DIR."
  (let ((parent (file-name-directory (directory-file-name dir))))
    (if (equal parent "/")
        parent
      (string-trim-right parent "[/]"))))

(defun efar-go-to-file (file &optional side prev-file-number)
  "Move cursor to the given FILE or to PREV-FILE-NUMBER if file cannot be found.
Do this in current panel, unless SIDE is given."
  (let* ((side (or side (efar-get :current-panel)))
	 (file (if (equal (efar-get :panels side :mode) :files)
		   (directory-file-name (expand-file-name file (efar-get :panels side :dir)))
		 file))
	 (number-of-files (length (efar-get :panels side :files)))
	 (panel-mode (efar-get :panels side :mode))
	 (column-number (efar-get :panels side :view panel-mode :column-number))
	 (new-file-number
	  (or
	   (cl-position file
			(mapcar (lambda (e) (car e)) (efar-get :panels side :files))
			:test 'string=)
	   (if (>= prev-file-number number-of-files)
	       (- number-of-files 1)
	     prev-file-number))))
    (cond
     
     ((and
       (>= new-file-number (efar-get :panels side :start-file-number))
       (< new-file-number (+ (efar-get :panels side :start-file-number) (* column-number (efar-get :panel-height)))))
      
      (progn
	(efar-set (- new-file-number (efar-get :panels side :start-file-number)) :panels side :current-pos)))
     
     ((< new-file-number (* column-number (efar-get :panel-height)))
      (progn
	(efar-set 0 :panels side :start-file-number)
	(efar-set new-file-number :panels side :current-pos)))
     
     (t
      (progn
	(efar-set new-file-number :panels side :start-file-number)
	(efar-set 0 :panels side :current-pos))))))


(defun efar-current-file-number (&optional side)
  "Return the number of file under cursor.
Do that for current panel or for panel SIDE if it's given."
  (let* ((side (or side (efar-get :current-panel)))
	 (start-file-number (efar-get :panels side :start-file-number)))
    
    (+ start-file-number (efar-get :panels side :current-pos))))

(defun efar-current-file-name (&optional side)
  "Return the full name of file under cursor.
Do that for current panel or for panel SIDE if it's given."
  (car (efar-current-file side)))

(defun efar-current-file (&optional side)
  "Return the file under cursor with it's attributes.
Do that for current panel or for panel SIDE if it's given."
  (let ((side (or side (efar-get :current-panel))))
    (nth (efar-current-file-number side) (efar-get :panels side :files))))

(defun efar-other-side (&optional side)
  "Return opposite panel to current panel or to panel SIDE if one is given.
:left <-> :right"
  (let ((side (if side side (efar-get :current-panel))))
    (if (equal side :left) :right :left)))

(defun efar-deselect-all ()
  "Unmark all marked files in current panel."
  (efar-write-enable
   (let ((side (efar-get :current-panel)))
     (efar-set '() :panels side :selected)
     (efar-redraw))))

(defun efar-mark-file (&optional no-move?)
  "Mark file under cursor in current panel.
Unless NO-MOVE? move curosr one item down."
  (let* ((side (efar-get :current-panel))
	 (current-item (car (efar-selected-files side t nil)))
	 (selected-items (efar-get :panels side :selected)))
    
    (when current-item
      (if (cl-member-if (lambda(e) (equal (car e) (car current-item))) selected-items)
	  (efar-set (cl-delete-if  (lambda(e) (equal (car e) (car current-item))) selected-items) :panels side :selected)
	(efar-set (push current-item selected-items) :panels side :selected)))
    
    (unless no-move? (efar-move-cursor  :down))))

(defun efar-edit-file (&optional for-read?)
  "Visit file under cursor.
When FOR-READ? is t switch back to eFar buffer."
  (let* ((side (efar-get :current-panel))
	 (file (caar (efar-selected-files side t)))
	 (mode (efar-get :panels side :mode)))
    
    ;; open file in other window
    (when file
      (let ((buffer (find-file-other-window file)))
	
	;; if file is opened from search result list then enable isearch mode
	(when (and (equal mode :search)
		   (not (string-empty-p (or (cdr(assoc :text efar-last-search-params)) ""))))
	  (setq case-fold-search (cdr (assoc :ignore-case? efar-last-search-params)))
	  
	  (isearch-mode t (cdr (assoc :regexp? efar-last-search-params)))
	  
	  (let ((string (cdr (assoc :text efar-last-search-params))))
	    (if case-fold-search
		(setq string (downcase string)))
	    (isearch-process-search-string string
					   (mapconcat #'isearch-text-char-description string ""))))
	
	;; if file opened for editing unmark its buffer to prevent auto kill of the buffer
	(when (and (equal buffer (efar-get :last-auto-read-buffer))
		   (not for-read?))
	  (efar-set nil :last-auto-read-buffer))
	
	;; if file opened for reading only then goto back to eFar
	(when for-read?
	  (select-window (get-buffer-window (get-buffer efar-buffer-name))))
	
	;; add file to the list of last opned files
	(unless for-read?
	  (let* ((current-hist (efar-get :file-history))
		 (new-hist (cl-subseq (cl-remove-if (lambda(e) (equal file (car e))) current-hist)
				      0 (when (> (length current-hist) efar-max-items-in-directory-history)
					  (- efar-max-items-in-directory-history 1)))))
	    (push (cons file (list (cons :side side)  (cons :time (current-time)))) new-hist)
	    
	    (efar-set new-hist :file-history)))
	
	buffer))))

(defun efar-set-files-order (files side)
  "Change sort direction of FILES in panel SIDE."
  (if (efar-get :panels side :sort-order)
      (reverse files)
    files))

(defun efar-is-root-directory (dir)
  "Return t if DIR is a root directory, nil otherwise."
  (string= (file-name-as-directory dir)
	   (file-name-directory (directory-file-name dir))))

(defun efar-get-file-list (side)
  "Read file list from the directory showed in panel SIDE."
  (let* ((filter (efar-get :panels side :file-filter))
	 (fast-search-string (efar-get :fast-search-string))
	 (mode (efar-get :panels side :mode))
	 (root? (or (not (equal mode :files))
		    (efar-is-root-directory (efar-get :panels side :dir)))))
    
    (efar-set
     ;; if we are not in the root directory, we add entry to go up
     (append (unless root? (list (list ".." t)))
	     ;; change order of files according to selected mode (ASC or DESC)
	     (efar-set-files-order
	      
	      ;; build file list
	      (let ((files
		     ;; remove entries "." and ".." and filter file list according to selected wildcard
		     (cl-remove-if
		      (lambda (f)  (or
				    (string-suffix-p "/." (car f))
				    (string-suffix-p "/.." (car f))
				    (and (or (not (cadr f))
					     efar-filter-directories-p)
					 (not (string-suffix-p "/.." (car f)))
					 (> (length filter) 0 )
					 (not (string-match (wildcard-to-regexp filter) (car f))))
				    (and efar-fast-search-filter-enabled-p
					 fast-search-string
					 (not (string-match (if (cl-position ?* fast-search-string) (wildcard-to-regexp fast-search-string) fast-search-string)
							    (if (equal (car (efar-get :panels side :view (efar-get :panels side :mode) :file-disp-mode)) :long)
								(car f)
							      (efar-get-short-file-name f)))))))
		      
		      ;; get files and attributes
		      (pcase mode
			
			;; panel is in mode :files
			(:files
			 (directory-files-and-attributes (efar-get :panels side :dir) t nil t 'string))
			
			;; entries to be displayed in directory history
			(:dir-hist
			 (mapcar (lambda(d) (let ((attrs (file-attributes (car d) 'string)))
					      (append (push (car d) attrs) (list (cdr (assoc :time (cdr d)))))))
				 (efar-get :directory-history)))
			;; entries to be displayed in file history
			(:file-hist
			 (mapcar (lambda(d) (let ((attrs (file-attributes (car d) 'string)))
					      (append (push (car d) attrs) (list (cdr (assoc :time (cdr d)))))))
				 (efar-get :file-history)))
			;; entries to be displayed in bookmark mode
			(:bookmark
			 (mapcar (lambda(d) (let ((attrs (file-attributes d 'string)))
					      (push d attrs)))
				 (efar-get :bookmarks)))
			
			(:disks
			 (let ((default-directory user-emacs-directory))
			   (mapcar (lambda(d) (list d (file-directory-p d)))
				   (nconc (if (eq window-system 'w32)
					      (mapcar (lambda(e) (car (split-string e " " t)))
						      (cdr (split-string  (downcase (shell-command-to-string "wmic LogicalDisk get Caption"))
									  "\r\n" t)))
					    (split-string (shell-command-to-string "df -h --output=target | tail -n +2") "\n" t))))))
			
			
			(:search
			 (cl-copy-list (reverse efar-search-results))))))
		    
		    
		    ;; get selected sort function
		    ;; we do sorting only in modes :files and :search
		    (sort-function (when (or (equal mode :files)
					     (and (equal mode :search)
						  (not efar-search-running-p)))
				     ;;(cl-member mode '(:search :files))
				     (efar-get-sort-function (efar-get :panels side :sort-function-name)))))
		
	 	;;sort file list according to selected sort function
		(if sort-function
		    (sort files sort-function)
		  files))
	      
	      side))
     :panels side :files)))

(defun efar-move-cursor (direction &optional no-auto-read?)
  "Move cursor in direction DIRECTION.
When NO-AUTO-READ? is t then no auto file read happens."
  
  (let ((side (efar-get :current-panel)))
    (unless (= 0 (length (efar-get :panels side :files)))
      
      (unless efar-fast-search-filter-enabled-p
	(efar-quit-fast-search))
      
      (efar-write-enable
       (let* ((curr-pos (efar-get :panels side :current-pos))
	      (max-files-in-column (efar-get :panel-height))
	      (max-file-number (length (efar-get :panels side :files)))
	      (start-file-number (efar-get :panels side :start-file-number))
	      (panel-mode (efar-get :panels side :mode))
	      (col-number (efar-get :panels side :view panel-mode :column-number))
	      (affected-item-numbers ()))
	 (cond
	  ;; if UP key pressed
	  ((equal direction :up)
	   (cond
	    ;; if we are on the first file in the list - do nothing
	    ((and (= start-file-number 0) (= curr-pos 0)) nil)
	    ;; if we are on first item
	    ((= curr-pos 0)
	     (progn (let ((rest (- start-file-number (* col-number max-files-in-column))))
		      (efar-set (if (< rest 0) 0 rest)
				:panels side :start-file-number)
		      (efar-set (if (< rest 0) (- start-file-number 1) (- (* col-number max-files-in-column) 1))
				:panels side :current-pos))))
	    ;; else move up by one
	    (t (progn
		 (push  curr-pos affected-item-numbers)
		 (cl-decf curr-pos)
		 (push  curr-pos affected-item-numbers)
		 (efar-set curr-pos :panels side :current-pos)))))
	  
	  ;; if DOWN key is pressed
	  ((equal direction :down)
	   (cond
	    ;; if we are on the last file in the list - do nohing
	    ((= (+ start-file-number curr-pos) (- max-file-number 1)) nil)
	    ;; else if we are on last item
	    ((= curr-pos (- (* max-files-in-column col-number) 1))
	     (progn (efar-set (+ start-file-number curr-pos 1)
			      :panels side :start-file-number)
		    (efar-set 0
			      :panels side :current-pos) ))
	    ;; else move down by one
	    (t (progn
		 (push  curr-pos affected-item-numbers)
		 (cl-incf curr-pos)
		 (push  curr-pos affected-item-numbers)
		 (efar-set curr-pos :panels side :current-pos)))))
	  
	  ;; if LEFT key is pressed
	  ((equal direction :left)
	   (cond
	    ;; if we are on the first file in the list - do nothing
	    ((and (= start-file-number 0) (= curr-pos 0)) nil)
	    
	    ;; we are in right column - move left by max-files-in-column
	    ((>= curr-pos max-files-in-column) (efar-set (- curr-pos max-files-in-column)
							 :panels side :current-pos))
	    
	    ;; we are in left column
	    ((< curr-pos max-files-in-column)
	     (cond
	      ((= start-file-number 0) (efar-set 0
						 :panels side :current-pos))
	      ((> start-file-number (* col-number max-files-in-column)) (efar-set (- start-file-number max-files-in-column)
										  :panels side :start-file-number))
	      ((<= start-file-number (* col-number max-files-in-column)) (and
									  (efar-set 0
										    :panels side :start-file-number)
									  (efar-set 0
										    :panels side :current-pos)))))))
	  
	  ;; if HOME key is pressed
	  ((equal direction :home)
	   (and
	    (efar-set 0
		      :panels side :start-file-number)
	    (efar-set 0
		      :panels side :current-pos)))
	  
	  
	  ;; if END key is pressed
	  ((equal direction :end)
	   (and
	    (efar-set (if (< max-file-number (* col-number max-files-in-column)) 0 (- max-file-number (* col-number max-files-in-column)))
		      :panels side :start-file-number)
	    (efar-set (- (if (< max-file-number (* col-number max-files-in-column))  max-file-number (* col-number max-files-in-column)) 1)
		      :panels side :current-pos)))
	  
	  
	  ;; if RIGHT key is pressed
	  ((equal direction :right)
	   (cond
	    ;; if we are on the last file in the list - do nohing
	    ((= (+ start-file-number curr-pos) (- max-file-number 1)) nil)
	    
	    ;; if there is more than max-files-in-column left then "scroll-down" column
	    ((> (- max-file-number start-file-number curr-pos) max-files-in-column)
	     (if (< curr-pos (* (- col-number 1) max-files-in-column))
		 (efar-set (+ curr-pos max-files-in-column)
			   :panels side :current-pos)
	       (efar-set (+ start-file-number max-files-in-column)
			 :panels side :start-file-number)))
	    ;; else go to the last file in the list
	    (t (efar-set (- max-file-number start-file-number 1) :panels side :current-pos)))))
	 
	 (efar-output-files side affected-item-numbers)
	 
	 (efar-output-file-details side)
	 
	 (efar-set-status)
	 
	 (condition-case err
	     (unless no-auto-read? (efar-auto-read-file))
	   (error (efar-set-status (concat "Error: "(error-message-string err)) nil t))))))))

(defun efar-auto-read-file ()
  "Automatically show content of the directory or file under cursor."
  
  (let* ((file (caar (efar-selected-files (efar-get :current-panel) t nil t)))
	 (file-ext (file-name-extension (downcase (or file "")))))
    (when (and file
	       (not (one-window-p)) ;; don't show when eFar occupies whole frame
	       (or  (and efar-auto-read-files ;; if file auto read is enabled
			 (< (file-attribute-size (file-attributes file)) efar-auto-read-max-file-size) ;; if file size is less than maximum allowed size
			 (or (and (equal (length efar-auto-read-file-extensions) 1) (string= "*" (car efar-auto-read-file-extensions))) ;; if any file type is configured to be auto read
			     (and file-ext (cl-member file-ext efar-auto-read-file-extensions :test 'equal)))) ;; or if files type is configured to be ato read
		    
		    (and efar-auto-read-directories ;; if directory auto read is enabled
			 (file-directory-p file)))) ;; current item under cursor is a directory
      
      (let ((last-auto-read-buffer (efar-get :last-auto-read-buffer))) ;; get the last auto read buffer
	;; we don't want to keep buffers for auto-opened files/dirs
	;; so we kill last auto read buffer if:
	;; - now we open different file
	;; - last auto read buffer is not modified
	(when (and
	       last-auto-read-buffer
	       (not (string= file (buffer-file-name last-auto-read-buffer)))
	       (not (buffer-modified-p last-auto-read-buffer)))
	  (kill-buffer last-auto-read-buffer))
	
	(let ((last-auto-read-buffer-exists? (get-file-buffer file)) ;; check if buffer for last auto read file exists
	      (buffer (efar-edit-file t))) ;; open current file for read
	  
	  ;; if buffer for last auto read file does not exists
	  ;; remember current buffer as last read one
	  (unless last-auto-read-buffer-exists?
 	    (efar-set buffer :last-auto-read-buffer)))))))

(defun efar-handle-enter (&optional copy-to-shell?)
  "Handle enter key pressing.
Do action depending on the type of item under cursor:
when directory - enter this directory
when executable file - open shell and execute it in the shell
when normal file - open it in external application.
When COPY-TO-SHELL? is t file name is copied to the shell."
  (let* ((side (efar-get :current-panel))
	 (file (car (efar-selected-files side t t))))
    
    (cond ((and (not copy-to-shell?)
		(or
		 ;; file is a normal directory
		 (equal (cadr file) t)
		 ;; file is a symlink pointing to the directory
		 (and (stringp (cadr file))
		      (file-directory-p (cadr file)))))
	   
	   (efar-enter-directory))
	  
	  ((or copy-to-shell?
	       (file-executable-p (car file)))
	   (efar-execute-file copy-to-shell?))
	  
	  (t (efar-open-file-in-ext-app)))))

(defun efar-display-shell (&optional go-to-dir?)
  "Open eshell buffer.
CD to `default-directory' when GO-TO-DIR? is t."
  (save-window-excursion
    (let* ((dir default-directory)
	   (eshell-buffer-name efar-shell-buffer-name))
      (eshell)
      (when (and (null eshell-current-command)
		 go-to-dir?)
	(with-current-buffer eshell-buffer-name
	  (goto-char (point-max))
	  (let ((old-input (eshell-get-old-input)))
	    (eshell-kill-input)
	    (eshell/cd dir)
	    (eshell-send-input)
	    (insert old-input))))))
  (switch-to-buffer-other-window efar-shell-buffer-name)
  (goto-char (point-max)))

(defun efar-execute-file (&optional dont-run?)
  "Insert file name under cursor to shell buffer.
Execute it unless DONT-RUN? is t."
  (efar-display-shell nil)
  (sit-for 0.1)
  (select-window (get-buffer-window (get-buffer efar-buffer-name)))
  
  (let* ((subtask-running? (with-current-buffer efar-shell-buffer-name
			     eshell-current-command ))
	 (ready? (or (null (get-buffer efar-shell-buffer-name))
		     (null subtask-running?)
		     (equal "Yes" (efar-completing-read (concat "Operation is in progress '"
								(with-current-buffer efar-shell-buffer-name
								  (concat eshell-last-command-name
									  (when eshell-last-arguments
									    (concat " "
										    (string-join eshell-last-arguments " ")))))
								"'. Abort? "))))))
    
    (when ready?
      (let* ((side (efar-get :current-panel))
	     (file (caar (efar-selected-files side t t))))
	
	(when subtask-running?
	  (with-current-buffer efar-shell-buffer-name
	    (eshell-kill-process)))
	(sit-for 0.1)
	(efar-display-shell nil)
	(goto-char (point-max))
	(unless dont-run?
	  (eshell-kill-input))
	(insert "\"" file "\" ")
	(unless dont-run?
	  (eshell-send-input))))))

(defun efar-enter-directory (&optional go-to-parent?)
  "Enter directory under cursor or parent directory when GO-TO-PARENT? is t."
  (let* ((side (efar-get :current-panel))
	 (current-dir-path (efar-get :panels side :dir))
	 (selected-file (car (efar-selected-files side t t)))
	 (file (if (or go-to-parent?
		       (equal (car selected-file) ".."))
		   ;; get parent directory
		   (list (efar-get-accessible-directory-in-path (efar-get-parent-dir current-dir-path)) t)
		 ;; get directory under cursor
		 selected-file)))
    (efar-quit-fast-search 'no-refresh)
    (when (or
	   ;; file is a normal directory
	   (equal (cadr file) t)
	   ;; file is a symlink pointing to the directory
	   (and (stringp (cadr file))
		(file-directory-p (cadr file))))
      (let ((newdir (expand-file-name (car file) current-dir-path)))
	(cond
	 ((not (file-accessible-directory-p  newdir))
	  (efar-set-status (concat "Directory "  newdir " is not accessible") 3))
	 
	 (t
	  (efar-go-to-dir newdir side)))))))

(defun efar-go-directory-history-cicle (direction)
  "Loop over directory history entries in direction DIRECTION."
  (let ((dir-hist (efar-get :directory-history)))
    (if (or (not dir-hist)
	    (zerop (length dir-hist)))
	
	(efar-set-status "Directory history is empty" 2 t)
      
      (let* ((side (efar-get :current-panel))
	     (index (cl-position (efar-get :panels side :dir) dir-hist :test (lambda(a b) (equal a (car b)))))
	     (new-index (if (equal direction :forward) (+ 1 index) (- index 1))))
	(when (< new-index 0) (setf new-index (- (length dir-hist) 1)))
	(when (> new-index (- (length dir-hist) 1)) (setf new-index 0))
	(efar-go-to-dir (car (nth new-index dir-hist)) side t)
	(efar-write-enable (efar-redraw))))))

(defun efar-scroll-other-window (direction)
  "Scroll content of other window in direction DIRECTION."
  (scroll-other-window (if (eq direction :down) 1 -1)))

(defun efar-switch-to-other-panel ()
  "Make other panel active."
  (efar-quit-fast-search)
  (when (equal (efar-get :mode) :both)
    (let ((side (efar-get :current-panel)))
      
      (if (equal side  :left)
	  (progn
	    (efar-set :right :current-panel)
	    (setf default-directory (efar-get :panels :right :dir)))
	(progn
	  (efar-set :left :current-panel)
	  (setf default-directory (efar-get :panels :left :dir)))))
    (efar-write-enable (efar-redraw))))

(defun efar-calculate-window-size ()
  "Calculate and set windows sizes."
  (efar-set (- (window-width) 1) :window-width)
  (efar-set (window-height) :window-height)
  (efar-set (- (window-height) 6) :panel-height))

(defun efar-redraw (&optional reread-files?)
  "The main function to output content of eFar buffer.
When REREAD-FILES? is t then reread file list for both panels."
  (interactive)
  (with-current-buffer efar-buffer-name
    (efar-calculate-window-size)
    (erase-buffer)
    
    (if (< (efar-get :window-width) 30)
	(insert "eFar buffer is too narrow")
      ;; draw all border lines
      (efar-draw-border )
      ;; apply default face
      (put-text-property (point-min) (point-max) 'face 'efar-border-line-face)
      ;; output directory names above each panel
      (efar-output-dir-names :left)
      (efar-output-dir-names :right)
      ;; output panel headers with panel controls
      (efar-output-header :left)
      (efar-output-header :right)
      ;; output file lists
      (when reread-files?
	(efar-get-file-list :left)
	(efar-get-file-list :right))
      (efar-output-files :left)
      (efar-output-files :right)
      ;; output details about files under cursor
      (efar-output-file-details :left)
      (efar-output-file-details :right)
      ;; during drag we show hand pointer
      (when efar-mouse-down-p
	(put-text-property (point-min) (point-max) 'pointer 'hand)))))

(defun efar-reinit ()
  "Reinitialize eFar state."
  (efar nil t))

(defun efar-get-short-file-name (file)
  "Return short name of a given FILE."
  (if (nth 1 file)
      (file-name-nondirectory (directory-file-name (nth 0 file)))
    (file-name-nondirectory (nth 0 file))))

(defun efar-output-file-details (side)
  "Output details of the file under cursor in panel SIDE."
  (let ((mode (efar-get :mode))
	(file (car (efar-selected-files side t t t)))
	(width (efar-panel-width side))
	(status-string (if (efar-get :panels side :files) "Non-existing or not-accessible file!" "")))
    
    (when (or (equal mode :both) (equal mode side))
      (when (and file
		 (efar-get :panels side :files)
		 (or (equal mode :both) (equal mode side)))
	
	(setf status-string (concat  (efar-get-short-file-name file)
				     "  "
				     (format-time-string "%x %X" (nth 6 file))
				     "  "
				     (if (equal (nth 1 file) t)
					 "Directory"
				       (when (numberp (nth 8 file))
					 (format "%d bytes (%s)" (nth 8 file) (efar-file-size-as-string (nth 8 file))))))))
      
      (efar-place-item nil (+ 3 (efar-get :panel-height))
		       status-string
		       'efar-border-line-face
		       width nil side :left t))))

(defun efar-panel-width (side)
  "Calculate and return the width of panel SIDE."
  (let ((widths (if (equal side :left)
		    (car (efar-get :column-widths))
		  (cdr (efar-get :column-widths)))))
    (if (null widths)
	0
      (+ (apply #'+ widths)
	 (- (length widths) 1)))))

(defun efar-output-files (side &optional affected-item-numbers)
  "Output the list of files in panel SIDE.
Redraw files with numbers in AFFECTED-ITEM-NUMBERS if given,
otherwise redraw all."
  (let ((mode (efar-get :mode)))
    (when (and
	   ;; when there are files to output
	   (not (zerop (length (efar-get :panels side :files))))
	   ;; and panel is displayed
	   (or (equal mode :both) (equal mode side)))
      
      (let ;; get column widths for given panel
	  ((widths (if (equal side :left)
		       (car (efar-get :column-widths))
		     (cdr (efar-get :column-widths))))
	   ;; get display mode for current panel
	   (disp-mode (car (efar-get :panels side :view (efar-get :panels side :mode) :file-disp-mode)))
	   (panel-mode (efar-get :panels side :mode)))
	
	(goto-char 0)
	(forward-line 1)
	
	(let*
	    ;; calculate start column for printing file names
	    ((start-column (cond ((equal side :left) 1) ;; left panel always starts at 1
				 ((and (equal side :right) (equal mode :right)) 1) ;; right panel when it's alone also starts at 1
				 (t (+ (efar-panel-width :left) 2)))) ;; otherwise start at position where left panel ends
	     ;; maximum number in one column
	     (max-files-in-column (efar-get :panel-height))
	     ;; file counter
	     (cnt 0)
	     ;; number of columns in the panel
	     (col-number (length widths))
	     ;; get subset of file which that should be displayed and will fit to the panel
	     (files (append (cl-subseq  (efar-get :panels side :files)
					(efar-get :panels side :start-file-number)
					(+ (efar-get :panels side :start-file-number)
					   (if (> (- (length (efar-get :panels side :files)) (efar-get :panels side :start-file-number)) (* max-files-in-column col-number))
					       (* max-files-in-column col-number)
					     (- (length (efar-get :panels side :files)) (efar-get :panels side :start-file-number)))))
			    
			    ;; append empty items if number of files to display is less then max files in panel
			    ;; in order to overwrite old entries
			    (make-list (let ((rest (- (length (efar-get :panels side :files)) (efar-get :panels side :start-file-number))))
					 (if (> rest (* max-files-in-column col-number))
					     0 (- (* max-files-in-column col-number) rest)))
				       (list "")))))
	  
	  ;; loop over column numbers
	  (cl-loop for col from 0 upto (- col-number 1) do
		   
		   (let* ;; get subset of files which fit in column
		       ((files-in-column (cl-subseq files
						    (* col max-files-in-column)
						    (* (+ col 1) max-files-in-column)))
			;; width of current column
			(column-width (nth col widths))
			;; calculate max widths of uid/gid if panel is in full mode
			(uid-gid-max-widths (when (equal disp-mode :full)
					      (let ((uid-width 0)
						    (gid-width 0))
						(cl-loop for f in files-in-column do
							 (setf uid-width (max uid-width (length (nth 3 f))))
							 (setf gid-width (max gid-width (length (nth 4 f)))))
						(cons uid-width gid-width)))))
		     
		     ;; loop over this subset
		     (cl-loop repeat (length files-in-column)  do
			      ;; move one line down
			      (forward-line)
			      
			      ;; we skip output if file number is not in the list of file numbers to be redrawed
			      (when (or (null affected-item-numbers) (member cnt affected-item-numbers))
				
				(let*
				    ;; current file to output
				    ((file (nth cnt files))
				     ;; is current file marked?
				     (marked? (cl-member-if (lambda(e) (equal (car file) (car e)))
							    (efar-get :panels side :selected)))
				     ;; is it an existing file?
				     (exists? (file-exists-p (car file)))
				     ;; get real file (for symlinks)
				     (real-file (if (not (stringp (cadr file)))
						    (cdr file)
						  (file-attributes (cadr file) 'string)))
				     ;; is it a directory?
				     (dir? (car real-file))
				     ;; is it a normal file?
				     (file? (not (car real-file)))
				     ;; file is executable?
				     (executable? (and file? (file-executable-p (car file))))
				     ;; is it a file under cursor?
				     (current? (and
						(= cnt (efar-get :panels side :current-pos))
						(equal side (efar-get :current-panel))))
				     
				     ;; prepare string representing the file
				     (str (pcase disp-mode
					    ;; in short mode we just output short file name with optional ending "/"
					    (:short
					     (concat (file-name-nondirectory (car file)) (when (and efar-add-slash-to-directories (car real-file) (not (equal (car file) "/"))) "/")))
					    ;; in long mode we output full file path + some additional info depending on current mode
					    (:long
					     (let ((file-name (concat (car file)
								      (when (and efar-add-slash-to-directories (car real-file) (not (equal (car file) "/"))) "/"))))
					       (cond ((equal panel-mode :search)
						      (concat file-name
							      (when (nth 13 file) (format " (%s)" (length (nth 13 file))))))
						     ((or (equal panel-mode :dir-hist) (equal panel-mode :file-hist))
						      (concat (when (nth 13 file) (format-time-string "%Y-%m-%d   " (nth 13 file))) file-name))
						     (t file-name))))
					    ;; in deteiled mode we output detailed info about file
					    (:detailed (efar-prepare-detailed-file-info file column-width))
					    ;; in full mode we output all possible info about file
					    (:full (efar-prepare-detailed-file-info file column-width 'full uid-gid-max-widths))))
				     ;; get corresponding face
				     (face
				      (cond
				       ((and (not exists?) current?) 'efar-non-existing-current-file-face)
				       ((not exists?) 'efar-non-existing-file-face)
				       
				       ((and current? marked?) 'efar-marked-current-face)
				       ((and (not current?) marked?) 'efar-marked-face)
				       
				       ((and current? executable?) 'efar-file-current-executable-face)
				       ((and (not current?) executable?) 'efar-file-executable-face)
				       
				       ((and dir? current?) 'efar-dir-current-face)
				       ((and file? current?) 'efar-file-current-face)
				       ((and dir? (not current?)) 'efar-dir-face)
				       ((and file? (not current?)) 'efar-file-face))))
				  
				  
				  
				  (efar-place-item
				   ;; calculate start output position for column
				   (+ start-column
				      (apply #'+ (cl-subseq widths 0 col))
				      col)
				   nil  str face column-width (and (eq :long disp-mode)
								   (not (cl-member panel-mode '(:dir-hist :file-hist))))
				   nil nil t
				   (list (cons :side side)
					 (cons :control (unless (string-empty-p str) :file-pos))
					 (cons :file-name (car file))
					 (cons :file-number cnt)
					 (cons :switch-to-panel t)))))
			      
			      ;; go to next file
			      (cl-incf cnt))
		     
		     (goto-char 0)
		     (forward-line 1))))))))

(defun efar-output-header (side)
  "Output eFar header in panel SIDE."
  (let ((mode (efar-get :mode)))
    
    (when (or (equal mode :both) (equal mode side))
      
      (goto-char 0)
      (forward-line)
      
      (let* ((col (cond
		   ((or (equal side :left) (not (equal mode :both))) 1)
		   (t (+ (efar-panel-width :left) 2))))
	     
	     (filter (efar-get :panels side :file-filter))
	     (fast-search-string (efar-get :fast-search-string))
	     (panel-mode (efar-get :panels side :mode))
	     (column-number (efar-get :panels side :view panel-mode :column-number))
	     (str))
	
	;; output controls to change sort function and sort order
	(let ((panel-mode (efar-get :panels side :mode)))
	  
	  (when (or (equal panel-mode :files)
		    (and (equal panel-mode :search)
			 (not efar-search-running-p)))
	    
	    (setf str (substring (efar-get :panels side :sort-function-name) 0 1))
	    (efar-place-item col 1 str 'efar-header-face nil nil nil nil nil
			     (list (cons :side side) (cons :control :sort-func))
			     'hand)
	    
	    (setf str (if (efar-get :panels side :sort-order) (char-to-string 9660) (char-to-string 9650)))
	    (efar-place-item (+ col 1) 1 str 'efar-header-face nil nil nil nil nil
			     (list (cons :side side) (cons :control :sort-order))
			     'hand)))
	
	;; output filter string
	(unless (and (string-empty-p filter)
	 	     (null fast-search-string))
	  (setf str (if (and fast-search-string
	 		     (equal side (efar-get :current-panel)))
	 		(concat "Fast search: " fast-search-string)
	 	      (if (string-empty-p filter) "" (concat "Filter: " filter))))
	  (efar-place-item (+ col 4) 1 str 'efar-border-line-face))
	
	;; output control for changing column number and panel mode
	(setf str (concat "- " (int-to-string column-number) " +"))
	(efar-place-item nil 1 str 'efar-header-face nil nil side :center nil
			 (list (cons :side side) (cons :control :col-number))
			 'hand)
	
	;; output panel mode switcher
	(when (equal (efar-get :panels side :mode) :files)
	  (setf str (pcase (car (efar-get :panels side :view (efar-get :panels side :mode) :file-disp-mode))
	 	      (:short "S")
	 	      (:long "L")
	 	      (:detailed "D")
		      (:full "F")))
	  (efar-place-item (+ col (- (efar-panel-width side) 3)) 1 str 'efar-header-face nil nil nil nil nil
			   (list (cons :side side) (cons :control :file-disp-mode))
			   'hand))
	
	;; output maximize/minimize control
	(setf str (if (equal (efar-get :mode) :both)
	 	      (char-to-string 9633)
	 	    (char-to-string 8213)))
	(efar-place-item (+ col (- (efar-panel-width side) 1)) 1 str 'efar-header-face nil nil nil nil nil
			 (list (cons :side side) (cons :control :maximize))
			 'hand)))))

(defun efar-prepare-string (str len &optional cut-from-beginn? dont-fill?)
  "Prepare file name STR.
String is truncated to be not more than LEN characters long.
When CUT-FROM-BEGINN? is t then string is truncated from the beginn,
otherwise from the end.
Unless DONT-FILL? fill string with spaces if it shorter than LEN."
  (let ((cut-from-beginn? (or cut-from-beginn?))
	(dont-fill? (or dont-fill?)))
    
    (cond ((> (length str) len)
	   (if cut-from-beginn?
	       (concat "<" (cl-subseq str (+ (- (length str) len) 1)))
	     (concat (cl-subseq str 0 (- len 1)) ">")))
	  
	  ((and (not dont-fill?)
		(< (length str) len))
	   (concat str (make-string (- len (length str)) ?\s)))
	  
	  (t
	   str))))

(defun efar-place-item (column line text face &optional max-length cut-from-beginn? side start-pos fill? control-params pointer)
  "Outputs an UI item.
Start output from COLUMN in LINE.
TEXT is a string representing item.
FACE is a face applied to the text.

When MAX-LENGTH is given then truncate or extand (when FILL? is t) text
to be MAX-LENGTH characters long.
When CUT-FROM-BEGIN? is t then string is truncated from beginning,
otherwise from end.

If COLUMN is not given then following optional parameters move into action:
SIDE - place in given panel
START-POS (:left or :center) - defines how to align item within the panel.

CONTROL-PARAMS - item is considered as control with given parameters"
  
  ;; when line number is given goto this line
  ;; otherwise we place item in current line
  (when line
    (goto-char 0)
    (forward-line line))
  
  (let* ((mode (efar-get :mode))
	 (text (if max-length
		   (efar-prepare-string text max-length cut-from-beginn? (not fill?))
		 text))
	 (length (length text))
	 (col (if column column
		(pcase start-pos
		  (:left
		   (if (equal side :right)
		       (+ (if (equal mode :both) 2 1) (efar-panel-width :left))
		     1))
		  
		  (:center
		   
		   (if (equal side :right)
		       (+ (if (equal mode :both) 1 0) (efar-panel-width :left) (- (ceiling (efar-panel-width :right) 2) (floor length 2)))
		     (- (ceiling (efar-panel-width :left) 2) (floor length 2)))))))
	 (pointer (or pointer 'arrow)))
    
    (move-to-column col)
    (let ((p (point)))
      (delete-region p (+ p length))
      (insert text)
      (put-text-property p (+ p length) 'face face)
      (put-text-property p (+ p length) 'pointer pointer)
      (when control-params
	(put-text-property p (+ p length) :control control-params)))))

(defun efar-output-dir-names (side)
  "Output current directory name for panel SIDE."
  (let ((mode (efar-get :mode)))
    
    (when (or (equal mode :both) (equal mode side))
      
      (let* ((dir (efar-get :panels side :dir))
	     (face (if (equal side (efar-get :current-panel))
		       'efar-dir-name-current-face
		     'efar-dir-name-face)))
	
	(efar-place-item nil 0 dir face (efar-panel-width side) t side :center nil
			 (list (cons :side side) (cons :switch-to-panel t) (cons :control :directory-name))
			 'hand)))))

(defun efar-draw-border ()
  "Draw eFar border using pseudo graphic characters."
  (goto-char 0)
  
  (let ((panel-height (efar-get :panel-height)))
    
    ;; header area
    (efar-draw-border-line 9556 ;; ╔
			   9574 ;; ╦
			   9559 ;; ╗
			   9552 ;; ═
			   9552 ;; ═
			   'newline)
    
    (efar-draw-border-line 9553 ;; ║
			   9553 ;; ║
			   9553 ;; ║
			   32 ;; space
			   nil
			   'newline)
    
    ;; files area
    (cl-loop repeat panel-height do
	     (efar-draw-border-line 9553 ;; ║
				    9553 ;; ║
				    9553 ;; ║
				    32 ;; space
				    9474 ;; │
				    'newline))
    ;; file details area
    (efar-draw-border-line 9568 ;; ╠
			   9580 ;; ╬
			   9571 ;; ╣
			   9552 ;; ═
			   9575 ;; ╧
			   'newline)
    
    (efar-draw-border-line 9553 ;; ║
			   9553 ;; ║
			   9553 ;; ║
			   32 ;; space
			   nil
			   'newline)
    
    (efar-draw-border-line 9562 ;; ╚
			   9577 ;; ╩
			   9565 ;; ╝
			   9552 ;; ═
			   nil)))

(defun efar-draw-border-line (left center right filler splitter &optional newline)
  "Draw the line according to given arguments.
LEFT is a character to be used to draw left border.
CENTER is a character to be used to draw vertical splitter between panels.
RIGHT is a character to be used to draw right border.
FILLER is a character to be used as a filler between borders
when SPLITTER is not given, otherwise use SPLITTER.
NEWLINE - if t the insert newline character."
  (let ((mode (efar-get :mode)))
    (cl-loop for side
	     from (if (or (equal mode :left) (equal mode :both)) 1 2)
	     upto (if (or (equal mode :right) (equal mode :both)) 2 1)
	     initially do (insert-char left 1)
	     finally do (insert-char right 1)
	     do
	     (let* ((s (if (= side 1) :left :right))
		    (panel-mode (efar-get :panels s :mode))
		    (column-number (efar-get :panels s :view panel-mode :column-number)))
	       
	       (let ((p (point)))
		 (cl-loop for col from 0 upto (- column-number 1)	do
			  
			  (let ((col-number column-number))
			    
			    (insert-char filler (nth col (if (= side 1)
							     (car (efar-get :column-widths))
							   (cdr (efar-get :column-widths)))))
			    
			    (if (not (= (+ col 1) col-number))
				(insert-char (or splitter filler) 1)))
			  
			  (put-text-property p (point) 'pointer 'arrow)))
	       
	       (when (and (equal mode :both) (equal s :left))
		 (insert-char center 1)
		 (put-text-property (- (point) 1) (point) :control (list (cons :control :splitter)))
		 (put-text-property (- (point) 1) (point) 'pointer 'hdrag))))
    (when newline
      (newline)
      (forward-line))))

(defun efar-calculate-widths ()
  "Calculate widths of all columns in the panels."
  (let* ((splitter-shift (or (efar-get :splitter-shift) 0))
	 (shift (cond ((equal splitter-shift 0) 0)
		      (t (floor (* (floor (efar-get :window-width) 2) (/ splitter-shift 100.0))))))
	 (widths ())
	 (left-widths ())
	 (right-widths ())
	 
	 (window-width (efar-get :window-width))
	 (mode (efar-get :mode))
	 (cols-left (efar-get :panels :left :view (efar-get :panels :left :mode) :column-number))
	 (cols-right (efar-get :panels :right :view (efar-get :panels :right :mode) :column-number))
	 
	 
	 (left-width (cond
		      ((equal mode :both) (- (floor (- window-width 3) 2) shift))
		      ((equal mode :left) (- window-width 2))
		      ((equal mode :right) 0)))
	 
	 (right-width (cond
		       ((equal mode :both) (+ (ceiling (- window-width 3) 2) shift))
		       ((equal mode :left) 0)
		       ((equal mode :right) (- window-width 2)))))
    
    (unless (zerop left-width)
      (let* ((left-min-col-width (floor (/ (- left-width (- cols-left 1)) cols-left)))
	     (left-leftover (- left-width (- cols-left 1) (* left-min-col-width cols-left))))
	
	(setf left-widths (make-list cols-left left-min-col-width))
	
	(let ((cnt 0))
	  (while (not (zerop left-leftover))
	    (cl-incf (nth cnt left-widths))
	    (cl-decf left-leftover)
	    (cl-incf cnt)
	    (when (= cnt (length left-widths))
	      (setf cnt 0))))))
    
    (unless (zerop right-width)
      (let* ((right-min-col-width (floor (/ (- right-width (- cols-right 1))  cols-right)))
	     (right-leftover (- right-width (- cols-right 1) (* right-min-col-width cols-right))))
	
	(setf right-widths (make-list cols-right right-min-col-width))
	
	(let ((cnt 0))
	  (while (not (zerop right-leftover))
	    (cl-incf (nth cnt right-widths))
	    (cl-decf right-leftover)
	    (cl-incf cnt)
	    (when (= cnt (length right-widths))
	      (setf cnt 0))))))
    
    (setf widths (cons left-widths right-widths))
    
    (efar-set widths :column-widths)))

(defun efar-window-conf-changed ()
  "Function called when window configuration is changed.
Redraws entire eFar buffer."
  (let ((window (get-buffer-window efar-buffer-name)))
    (when window
      (efar-calculate-window-size)
      (efar-calculate-widths)
      (efar-write-enable
       (efar-redraw)))))

(defun efar-frame-size-changed (frame)
  "Function called when FRAME size is changed.
Redraws entire eFar buffer."
  
  (let ((window (get-buffer-window efar-buffer-name)))
    (when (and window
	       (equal (window-frame window) frame))
      (efar-calculate-window-size)
      (efar-calculate-widths)
      (efar-write-enable
       (efar-redraw)))))

(defun efar-buffer-killed ()
  "Function is called when eFar buffer is killed.
Saves eFar state and kills all subprocesses."
  (when (string= (buffer-name) efar-buffer-name)
    (efar-search-kill-all-processes)
    (when (and
	   efar-save-state-p
	   
	   (ignore-errors
	     (efar-save-state))
	   (efar-remove-notifier :left)
	   (efar-remove-notifier :right)))
    (setf efar-state nil)))

(defun efar-emacs-killed ()
  "Function is called when Emacs is killed.
Saves eFar state and kills all subprocesses."
  (efar-search-kill-all-processes)
  (when (and
	 efar-save-state-p
	 (get-buffer efar-buffer-name))
    (ignore-errors
      (efar-save-state))))

(defun efar-get-root-directory (path)
  "Return a root directory for given PATH."
  ;; get parent directory
  (let ((parent-dir
	 (file-name-directory
	  (directory-file-name path))))
    ;; if we are in root directory already
    (if (string= parent-dir path)
	path
      ;; otherwise check parent directory
      (efar-get-root-directory parent-dir ))))

(defun efar-selected-files (side current? &optional up-included? skip-non-existing?)
  "Return a list of selected files in panel SIDE.
When CURRENT? is t return file under cursor only even if some more files marked.
When UP-INCLUDED? is t include '..' directory in the list.
When SKIP-NON-EXISTING? is t then non-existing files removed from the list."
  (let* ((marked-files (efar-get :panels side :selected))
	 (start-file-number (efar-get :panels side :start-file-number))
	 (current-file-number (+ start-file-number (efar-get :panels side :current-pos)))
	 (files (efar-get :panels side :files)))
    
    (when (> (length files) 0)
      (cl-remove-if (lambda(f) (and skip-non-existing? (not (file-exists-p (car f)))))
		    (remove (unless up-included? (list ".." t))
			    (if (or current? (not marked-files))
				(list (nth current-file-number files))
			      marked-files))))))

(defun efar-abort ()
  "Quit fast search mode when it's active.
Switch current panel to :files mode otherwise."
  (unless (efar-get :fast-search-string)
    (let ((side (efar-get :current-panel)))
      (when (cl-member (efar-get :panels side :mode) '(:search :bookmark :dir-hist :file-hist :disks))
	(efar-go-to-dir (efar-last-visited-dir side) side))))
  (efar-quit-fast-search))

(defun efar-last-visited-dir (&optional thing)
  "Return last visited directory for the THING.
THING could be :left or :right.  In this case it indicates corresponding panel.
Or it could be a string representing Windows drive letter."
  (let ((thing (or thing (efar-get :current-panel))))
    (or (catch 'dir
	  (cl-loop for d in (efar-get :directory-history) do
		   (when (or (and (symbolp thing)
				  (equal (cdr (assoc :side d)) thing))
			     (and (stringp thing)
				  (equal (efar-get-root-directory (expand-file-name (car d))) (file-name-as-directory thing))))
		     (throw 'dir (car d)))))
	(if (symbolp thing)
	    user-emacs-directory
	  thing))))

(defun efar-change-file-disp-mode (&optional side)
  "Change file display mode in panel SIDE.
Mode is changed in the loop :short -> :detail -> :long."
  (let* ((side (or side (efar-get :current-panel)))
	 (modes (efar-get :panels side :view (efar-get :panels side :mode) :file-disp-mode))
	 (new-modes (reverse (cons (car modes) (reverse (cdr modes))))))
    (efar-set new-modes
	      :panels side :view (efar-get :panels side :mode) :file-disp-mode)
    
    (when (member (car new-modes) '(:full :detailed))
      (efar-set 1 :panels side :view (efar-get :panels side :mode) :column-number)))
  
  (efar-calculate-widths)
  (efar-write-enable (efar-redraw)))

(defun efar-prepare-detailed-file-info (file width &optional full? max-uid-gid-widths)
  "Prepare string with detailed info for FILE (size and date).
Truncate string to WIDTH characters.
When FULL? t, then include also file modes, uid and gid.
MAX-UID-GID-WIDTHS is relevant when FULL?.  It contains precalculated maximal
widths for uid and gid columns."
  (if (or (equal (car file) "..") (string-empty-p (car file)))
      (car file)
    (let* ((size (if (cadr file)
		     "DIR"
		   (efar-file-size-as-string (nth 8 file))))
	   (name (file-name-nondirectory  (car file)))
	   (time (format-time-string "%D %T" (nth 6 file)))
	   (file-modes (when full? (nth 9 file)))
	   (uid (when full? (nth 3 file)))
	   (gid (when full? (nth 4 file)))
	   (file-details-format (concat "%s   %s"
					(when full?
					  (concat
					   "   %s   "
					   "%-" (int-to-string (car max-uid-gid-widths)) "s   "
					   "%-" (int-to-string (cdr max-uid-gid-widths)) "s"))))
	   (file-details (format file-details-format size time file-modes uid gid)))
      
      (cond ((>= width (+ (length file-details)
			  (length name)
			  3))
	     (concat (efar-prepare-string name (- width (length file-details) 3)) "   " file-details))
	    
	    ((>= width (+ (length file-details)
			  5))
	     (concat (efar-prepare-string name (- width (length file-details) 3)) "   " file-details))
	    
	    (t
	     (concat (efar-prepare-string name 2) "   " (efar-prepare-string file-details (- width 5))))))))

(defun efar-file-size-as-string (size)
  "Prepare human readable string representing file SIZE."
  (cond ((< size 1024)
	 (concat (int-to-string size) " B"))
	((< size 1048576)
	 (concat (int-to-string (/ size 1024)) " KB"))
	((< size 1073741824)
	 (concat (int-to-string (/ size 1024 1024)) " MB"))
	(t
	 (concat (int-to-string (/ size 1024 1024 1024)) " GB"))))

(defun efar-ediff-files ()
  "Run ediff to compare files under cursor in both panels."
  (let ((file1 (efar-selected-files :left nil))
	(file2 (efar-selected-files :right nil)))
    (if (or
	 (not (= 1 (length file1)))
	 (not (= 1 (length file2)))
	 (car (cadr file1))
	 (car (cadr file2)))
	(efar-set-status "Please mark 2 files to run ediff" 5 t)
      (ediff (caar file1) (caar file2)))))

;;--------------------------------------------------------------------------------
;; Batch file renaming
;;--------------------------------------------------------------------------------
(defun efar-batch-rename ()
  "Very simple batch file renamer.
It's allowed to use following tags in the format string:
  <name>  -  replaced by whole file name with extension
  <basename>  -  replaced by file name without extension
  <ext>  -  replaced by extension with leading '.'
  <number>  -  replaced by running number.

Tags also can be written in different form:
  <name>, <NAME>, <Name>

Depending on the form corresponding part will be written in
lower case, upper case or will be capitalized."
  (let* ((side (efar-get :current-panel))
	 (selected-files (efar-get :panels side :selected))
	 ;;gather files to rename
	 ;; get marked files if any
	 ;; get all files shown in the directory otherwise
	 (files (cl-remove-if (lambda(e)
				(or (equal (car e) "..")
				    (and selected-files
					 (not (cl-member-if (lambda(e1) (equal (car e) (car e1)))
							    selected-files)))))
			      (efar-get :panels side :files)))
	 ;; format string to use for renaming
	 (format-string (read-string "Input format string: " "<basename>-<number><ext>"))
	 (cnt 0)
	 (rename-map '()))
    
    ;; fill the renaming map
    (cl-loop for f in files do
	     (cl-incf cnt)
	     (let* ((name (efar-get-short-file-name f))
		    (base-name (file-name-base (car f)))
		    (ext (file-name-extension (car f)))
		    (new-name format-string))
	       
	       (cl-labels
		   ((change-case (tag string value)
				 (let ((case-fold-search nil))
				   (cond ((string-match (upcase tag) string)
					  (upcase value))
					 ((string-match (downcase tag) string)
					  (downcase value))
					 ((string-match (capitalize tag) string)
					  (capitalize value))
					 (t value)))))
		 
		 (setf new-name (replace-regexp-in-string "<name>" (change-case "<name>" format-string name) new-name))
		 (setf new-name (replace-regexp-in-string "<basename>" (change-case "<basename>" format-string base-name) new-name))
		 (setf new-name (replace-regexp-in-string "<ext>" (if ext
								      (concat "." (change-case "<ext>" format-string ext)))
							  new-name)))
	       (setf new-name (replace-regexp-in-string "<number>" (int-to-string cnt) new-name))
	       (push (cons (car f) new-name) rename-map)))
    
    ;; show renaming map in the separate buffer
    (and (get-buffer efar-batch-buffer-name) (kill-buffer efar-batch-buffer-name))
    (let ((buffer (get-buffer-create efar-batch-buffer-name))
	  (duplicates? nil))
      
      (with-current-buffer buffer
	(read-only-mode 0)
	(erase-buffer)
	(setq-local efar-rename-map rename-map)
	(cl-loop for f in (reverse rename-map) do
		 (let ((p (point)))
		   (insert (car f) "\t->\t" (cdr f))
		   ;; when the result list contains duplicated file names
		   (when (or (> (cl-count-if (lambda(e) (equal (cdr f) (cdr e))) efar-rename-map) 1))
		     ;; highlight these duplicates
		     (setf duplicates? t)
		     (add-text-properties p (point)
					  '(face efar-non-existing-current-file-face))))
		 (newline))
	
	(align-regexp (point-min) (point-max) "\\(\\s-*\\)\t")
	(goto-char 0)
	
	;; insert header
	(insert "Check the preliminary renaming results  bellow.")
	(newline)
	(if duplicates?
	    (progn
	      (insert "There are duplicates in the result list or files with resulting names already exist. Renaming is not possible.")
	      (newline)
	      (insert "Press 'C-g' to quit"))
	  (insert "Press 'r' to confirm and run batch renaming or 'C-g' to cancel it."))
	(newline)
	(newline)
	(read-only-mode 1)
	
	;; activate key binding to run actual renaming
	(unless duplicates?
	  (local-set-key (kbd "r") (lambda()
				     (interactive)
				     ;; do the renaming
				     (cl-loop for f in efar-rename-map do
					      (efar-retry-when-error (rename-file (car f) (cdr f))))
				     (kill-buffer efar-batch-buffer-name)
				     (efar-write-enable (efar-redraw 'reread-files))
				     (efar nil))))
	;; activate key binding to quit
	(local-set-key (kbd "C-g") (lambda()
				     (interactive)
				     (kill-buffer efar-batch-buffer-name)
				     (efar nil)))
	(switch-to-buffer-other-window buffer)))))

;;--------------------------------------------------------------------------------
;; Batch replace in files
;;--------------------------------------------------------------------------------
(define-button-type 'efar-batch-replace-line-button
  'face 'efar-search-line-link-face )

(define-button-type 'efar-batch-replace-file-button
  'face 'efar-search-file-link-face )

(defun efar-batch-replace ()
  "Replace text in selected files interactively."
  (let* ((side (efar-get :current-panel))
	 (selected-files (efar-get :panels side :selected))
	 ;;gather files
	 ;; get marked files if any
	 ;; get all files shown in the directory otherwise
	 (files (cl-remove-if (lambda(e)
				(or (equal (car e) "..")
				    (and selected-files
					 (not (cl-member-if (lambda(e1) (equal (car e) (car e1)))
							    selected-files)))))
			      (efar-get :panels side :files)))
	 (regexp (read-string "String to replace (regexp): " ))
	 (replacement (read-string "Replace by: ")))
    
    ;; search string in selected files
    (let ((hits (make-hash-table)))
      (cl-loop for f in files do
	       (with-temp-buffer
		 (insert-file-contents (car f))
		 (goto-char 0)
		 (while (re-search-forward regexp nil 'noerror)
		   (let ((h (or (gethash (car f) hits)
				(puthash (car f) '() hits))))
		     
		     (push (cons (line-number-at-pos)
				 (replace-regexp-in-string "\n" "" (thing-at-point 'line t)))
			   h)
		     (puthash (car f) h hits))
		   (forward-line))))
      
      ;; prepare buffer to output preliminary results
      (and (get-buffer efar-batch-buffer-name) (kill-buffer efar-batch-buffer-name))
      (let ((buffer (get-buffer-create efar-batch-buffer-name))
	    (files 0)
	    (matches 0))
	
	(with-current-buffer buffer
	  (read-only-mode 0)
	  (erase-buffer)	  
	  ;; output file names and matches found in these files
	  (cl-loop for f being the hash-key of hits do
		   (insert-button f
				  :type 'efar-batch-replace-file-button
				  :file f)
		   (newline)
		   (cl-incf files)
		   (cl-loop for hit in (reverse (gethash f hits)) do
			    
			    (insert-button (concat (int-to-string (car hit)) ":\t" (cdr hit))
					   :type 'efar-batch-replace-line-button
					   :file f
					   :line-number (car hit))
			    (newline)
			    (cl-incf matches))
		   (newline))
	  
	  ;; output header
	  (goto-char 0)
	  (highlight-regexp regexp 'hi-yellow)
	  (goto-char 0)
	  ;; insert header
	  (insert "Replace '" regexp "' by '" replacement "'\n\n")
	  (insert "Press 'R' to replace all matches in all files\n\n")
	  (insert "Press 'r' to:\n")
	  (insert "  - replace all matches in particular file when point is over the line with file name\n")
	  (insert "  - replace matches in a single line when point is over the sorce line\n\n")
	  (insert "Press 'd' to remove from the list the item at point\n\n")
	  (insert "Press 'q' to close this buffer.\n\n")
	  (insert (int-to-string matches) " hit(s) in " (int-to-string files) " file(s)\n\n")
	  (read-only-mode 1)
	  
	  ;; setup keys
	  ;; key to close buffer
	  (local-set-key (kbd "q") (lambda ()
				     (interactive)
				     (kill-buffer efar-batch-buffer-name)
				     (efar nil)))
	  ;; function to process single line from the buffer
	  (cl-labels ((process-single (&optional replace)
				      ;; look for button at current position
				      (let* ((button (button-at (point)))
					     (file (when button (button-get button :file)))
					     (line-number (when button (button-get button :line-number))))
					;; if buton exists
					(if button
					    (progn
					      ;; do replacement in the corrsponding file
					      (when replace
						(efar-retry-when-error (efar-batch-replace-in-file file regexp replacement line-number)))
					      (read-only-mode 0)
					      ;; delete processed line from the buffer
					      (delete-region (line-beginning-position) (1+ (line-end-position)))
					      ;; if thatwas a line representing file name
					      ;; delete all source line belonging to that file
					      (unless line-number
						(while (and (button-at (point))
							    (button-get (button-at (point)) :line-number))
						  (delete-region (line-beginning-position) (1+ (line-end-position)))
						  (when (equal (length (thing-at-point 'line t)) 1)
						    (delete-region (line-beginning-position) (1+ (line-end-position))))))
					      (read-only-mode 1))
					  (forward-line)))))
	    
	    ;; key to process all lines in the buffer
	    (local-set-key (kbd "R") (lambda ()
				       (interactive)
				       (goto-char 0)
				       (while (not (eobp))
					 (process-single t))))
	    ;; to process single line
	    (local-set-key (kbd "r") (lambda ()
				       (interactive)
				       (process-single t)))
	    
	    ;; to remove single line without processing
	    (local-set-key (kbd "d") (lambda ()
				       (interactive)
				       (process-single)))))
	
	(switch-to-buffer-other-window buffer)))))

(defun efar-batch-replace-in-file (file regexp replacement &optional line-number)
  "Replace in FILE text matching REGEXP by REPLACEMENT.
When optional LINE-NUMBER is given then do replacement on corresponding line only."
  (let ((visited (get-file-buffer file))
	(buffer (find-file-noselect file))
	(modified nil))
    
    (with-current-buffer buffer
      (setf modified (buffer-modified-p))
      (goto-char 0)
      (when line-number (forward-line (- line-number 1)))
      (while (search-forward regexp (when line-number (line-end-position)) t)
	(replace-match replacement))
      (when (or (not modified)
		(equal "Yes" (efar-completing-read (concat "File " file " has unsaved changes. Save?"))))
	(save-buffer))
      (unless visited
	(kill-buffer buffer)))))

(defun efar-current-file-stat ()
  "Display statisctics for selected file/directory."
  (let ((ok? nil)
	(current-file-entry (caar (efar-selected-files (efar-get :current-panel) t))))
    
    (unwind-protect
	(let ((size 0)
	      (files 0)
	      (dirs 0)
	      (skipped 0))
	  
	  (efar-set-status (format "Calculating size of '%s'..." current-file-entry))
	  (sit-for 0.001)
	  (cl-labels
	      ((int-file-size(file)
			     ;; if item is a directory
			     (if (file-directory-p file)
	        		 ;; if directory is not accessible
				 (if (not (file-accessible-directory-p file))
				     ;; increment number of skipped directories
				     (cl-incf skipped)
				   
				   ;; get all items in the directory and call function recursively for each item
				   (mapc (lambda(f)
					   (unless (member f '(".." "."))
					     (int-file-size (expand-file-name f file))))
					 (directory-files file nil nil t))
				   (cl-incf dirs))
			       
			       ;; otherwise if item is a file
			       (cl-incf size (nth 7 (file-attributes file 'string)))
			       (cl-incf files))))
	    
	    ;; run calculation for the current item in current panel
	    (int-file-size current-file-entry))
	  
	  ;; output stat in the status line
	  (let ((format-str (concat "%d bytes (%s) in %d directories and %d files."
				    (unless (zerop skipped) " %d directories skipped (no access)." ))))
	    (efar-set-status (format format-str
				     size (efar-file-size-as-string size) dirs files skipped)
			     nil t))
	  (setf ok? t))
      
      (unless ok?
	(efar-set-status "Size calculation failed" nil t)))))

(defconst efar-panel-modes '((:files . "Files")
			     (:bookmark . "Bookmarks")
			     (:dir-hist . "Directory history")
			     (:file-hist . "File history")
			     (:disks . "Disks/mount points")
			     (:search . "Search results")))


(defun efar-move-splitter (&optional shift)
  "Shift splitter between panels by SHIFT percantages."
  (let ((shift (cond ((equal shift :left)
		      (+ (or (efar-get :splitter-shift) 0) 2))
		     ((equal shift :right)
		      (- (or (efar-get :splitter-shift) 0) 2))
		     ((equal shift :center)
		      0)
		     ((numberp shift)
		      (+ (or (efar-get :splitter-shift) 0) shift)))))
    ;; we don't want to make panels too narrow
    (when (> shift 80) (setf shift 80))
    (when (< shift -80) (setf shift -80))
    (efar-set shift :splitter-shift)
    (efar-calculate-widths)
    (efar-write-enable (efar-redraw))))

(defun efar-change-panel-mode (mode &optional side)
  "Change mode of panel SIDE to MODE."
  (let ((side (or side (efar-get :current-panel)))
	(mode-name (cdr (assoc mode efar-panel-modes))))
    (efar-quit-fast-search 'no-refresh)
    
    (efar-set mode :panels side :mode)
    (efar-get-file-list side)
    
    (cond
     ((equal mode :search)
      (efar-show-search-results side))
     
     (t
      (efar-set mode-name :panels side :dir)
      
      (efar-remove-notifier side)
      (efar-set 0 :panels side :current-pos)
      
      (efar-calculate-widths)
      (efar-write-enable (efar-redraw))))))

(defun efar-show-mode-selector ()
  "Show selector of panel modes.
Current panel switched to selected mode."
  (let* ((side (efar-get :current-panel))
	 (current-mode (efar-get :panels side :mode))
	 (new-mode (car (rassoc (efar-completing-read "Switch to mode: "
						      (mapcar (lambda(m) (cdr m))
							      (append (list (cons current-mode (cdr (assoc current-mode efar-panel-modes))))
								      (cl-remove-if (lambda(m) (equal current-mode (car m))) efar-panel-modes))))
				efar-panel-modes))))
    
    (pcase new-mode
      (:files (efar-go-to-dir (efar-last-visited-dir side) side))
      (:dir-hist (efar-change-panel-mode :dir-hist))
      (:file-hist (efar-change-panel-mode :file-hist))
      (:bookmark (efar-change-panel-mode :bookmark))
      (:disks (efar-change-panel-mode :disks))
      (:search (efar-change-panel-mode :search)))
    
    (efar-write-enable (efar-redraw))))

(defun efar-add-bookmark ()
  "Add file under cursor to bookmark list."
  (let ((current-file-entry (caar (efar-selected-files (efar-get :current-panel) t)))
	(bookmarks (efar-get :bookmarks)))
    (push current-file-entry bookmarks)
    (efar-set bookmarks :bookmarks))
  (when (equal (efar-get :panels :left :mode) :bookmark)
    (efar-change-panel-mode :bookmark :left))
  (when (equal (efar-get :panels :right :mode) :bookmark)
    (efar-change-panel-mode :bookmark :right)))



(defun efar-delete-bookmark ()
  "Delete file from the bookmark list."
  (let* ((side (efar-get :current-panel))
	 (bookmarks (efar-get :bookmarks))
	 (entry (caar (efar-selected-files side t))))
    (when (and bookmarks
	       (string= "Yes" (efar-completing-read "Delete bookmark?")))
      (setq bookmarks (cl-remove entry bookmarks :test 'equal))
      (efar-set bookmarks :bookmarks)
      (when (equal (efar-get :panels :left :mode) :bookmark)
	(efar-change-panel-mode :bookmark :left))
      (when (equal (efar-get :panels :right :mode) :bookmark)
	(efar-change-panel-mode :bookmark :right)))))

(defun efar-navigate-to-file ()
  "Go to the file under cursor."
  (let ((entry (caar (efar-selected-files (efar-get :current-panel) t nil t))))
    (efar-quit-fast-search)
    (when entry
      (efar-go-to-dir (file-name-directory entry))
      (when (and (file-name-nondirectory entry) (not (string-empty-p (file-name-nondirectory entry))))
	(efar-go-to-file (file-name-nondirectory entry)))
      (efar-calculate-widths)
      (efar-write-enable (efar-redraw)))))

(defun efar-switch-to-disk ()
  "Change to the selected Windows drive or Unix mount point."
  (let ((entry (caar (efar-selected-files (efar-get :current-panel) t nil t))))
    (efar-quit-fast-search)
    (when entry
      (efar-go-to-dir (efar-last-visited-dir entry))
      (efar-calculate-widths)
      (efar-write-enable (efar-redraw)))))

(defun efar-suggest-hint ()
  "Display in the statusbar the next tip for key bindings."
  (let* ;; get next tip number to show
      ((hint-number (efar-get :next-hint-number))
       ;; all registered key bindings having description
       (keys (reverse (cl-remove-if (lambda(e) (not (nth 5 e))) efar-keys)))
       ;; key binding to show this time
       (key (nth hint-number keys)))
    
    ;; display tip in the statusbar
    (let ((key-seq (if (null (nth 3 key)) (nth 0 key) (symbol-value (nth 3 key)))))
      (efar-set-status (concat "Hint: use key binding '" (key-description key-seq) "' to " (nth 4 key) " (C-n to get next hint)") nil t))
    
    ;; calculate and store next tip number
    (if (= (length keys) (+ hint-number 1))
	(setq hint-number 0)
      (cl-incf hint-number))
    (efar-set hint-number :next-hint-number)))


;;--------------------------------------------------------------------------------
;; File search functionality
;;--------------------------------------------------------------------------------

(define-button-type 'efar-search-find-file-button
  'follow-link t
  'action #'efar-search-find-file-button
  'face 'efar-search-file-link-face)

(define-button-type 'efar-search-find-line-button
  'follow-link t
  'action #'efar-search-find-file-button
  'face 'efar-search-line-link-face )

(defun efar-search-process-command ()
  "Prepare the list with command line arguments for the search processes."
  (list (expand-file-name invocation-name invocation-directory)
	"--batch"
	"-l" (symbol-file 'efar)
	"-eval" "(efar-process-search-request)"))

(defun efar-run-search-processes ()
  "Run search processes."
  (efar-search-kill-all-processes)
  (sleep-for 1)
  ;; start network server that will listen for the messages from subprocesses
  (efar-search-start-server)
  (setq efar-search-clients '())
  ;; start subprocess that acts as a search manager:
  ;; - it receives and exeutes commands from eFar
  ;; - it does the file search by given file mask
  ;; - it creates and manages subprocesses for text search
  (setq efar-search-process-manager (efar-make-search-process))
  ;; ask search manager to create text search processes
  (efar-search-send-command efar-search-process-manager
			    :run-search-processes
			    '()))

(defun efar-start-search ()
  "Start file search."
  (interactive)
  ;; if search is already running, ask user if current search must be aborted
  (when efar-search-running-p
    (when (string= "Yes" (efar-completing-read "Search is still running. Kill it?"))
      ;; restart search processes
      (efar-run-search-processes)
      (setq efar-search-running-p nil)))
  
  ;; init efar if needed
  (efar nil nil t)
  
  (unless efar-search-running-p
    ;; gather search parameters
    (let* ((proposed-dir (if (called-interactively-p "interactive")
			     default-directory
			   (let ((selected-item (caar (efar-selected-files (efar-get :current-panel) t))))
			     (cond ((null  selected-item)
				    default-directory)
				   ((file-directory-p selected-item)
				    selected-item)
				   (t
				    (efar-get-parent-dir selected-item))))))
	   (dir (read-directory-name "Search in: " proposed-dir proposed-dir))
	   (wildcards (split-string (read-string "File name mask(s): "
				   (let ((wildcards (cdr (assoc :wildcards efar-last-search-params))))
				     (if wildcards (string-join wildcards ",")
				       efar-search-default-file-mask)))
				    "[, ]+"))
	   (text (read-string "Text to search: " (cdr (assoc :text efar-last-search-params))))
	   (ignore-case? (and (not (string-empty-p text)) (string=  "Yes" (efar-completing-read "Ignore case? " (list "Yes" "No")))))
	   (regexp? (and (not (string-empty-p text)) (string=  "Yes" (efar-completing-read "Use regexp? " (list "No" "Yes"))))))
      
      (setq efar-last-search-params nil)
      (setq efar-last-search-params (list (cons :dir dir)
					  (cons :wildcards wildcards)
					  (cons :text (if (string-empty-p text) nil text))
					  (cons :ignore-case? ignore-case?)
					  (cons :regexp? regexp?)
					  (cons :start-time (time-to-seconds (current-time)))))
      
      ;; set up timer that will update search list result during search
      (setq efar-update-search-results-timer
	    (run-at-time nil 2
			 (lambda()
			   (when (equal :search (efar-get :panels :left :mode))
			     (efar-change-panel-mode :search :left))
			   
			   (when (equal :search (efar-get :panels :right :mode))
			     (efar-change-panel-mode :search :right)))))
      (setq efar-search-results '())
      (setq efar-search-running-p t)
      (efar-set 0 :panels :left :current-pos)
      (efar-change-panel-mode :search)
      ;; send command to the manager to start the search with given parameters
      (efar-search-send-command efar-search-process-manager
				:start-search
				efar-last-search-params)
      
      (when (called-interactively-p "interactive") (efar nil)))))


(defun efar-search-kill-all-processes ()
  "Kill all search processes."
  (when (and efar-search-process-manager (process-live-p efar-search-process-manager))
    (kill-process efar-search-process-manager))
  (setq efar-search-process-manager nil)
  
  (cl-loop for proc in efar-search-processes do
	   (kill-process proc))
  
  (when (and efar-search-server
	     (process-live-p efar-search-server))
    (delete-process efar-search-server))
  (setq efar-search-server nil)
  (setq efar-last-search-params nil)
  (setq efar-search-results '())
  (setq efar-search-running-p nil))

(defun efar-search-start-server ()
  "Start search server which will consume messages from search subprocesses."
  (when (and efar-search-server
	     (process-live-p efar-search-server))
    (delete-process efar-search-server))
  
  (setq efar-search-server
	(make-network-process :server t
			      :service t
			      :name "efar-search-server"
			      :filter #'efar-search-process-filter
			      :sentinel #'efar-search-server-sentinel
			      :noquery t))
  (set-process-query-on-exit-flag efar-search-server nil)
  (setq efar-search-server-port (cadr (process-contact efar-search-server))))

(defun efar-search-server-sentinel (proc message)
  "Set up sentinel for the search server.
When a connection from subprocess PROC is opened (MESSAGE 'open'),
this subprocess is registered in the list of clients."
  (unless (equal proc efar-search-server)
    (when (and (process-live-p proc)
	       (equal message "open from 127.0.0.1\n"))
      (set-process-query-on-exit-flag proc nil)
      (push (process-name proc) efar-search-clients))))

(defun efar-search-finished ()
  "Function is called when search is finished."
  (while (accept-process-output))
  ;; cancel update timer
  (when (timerp efar-update-search-results-timer)
    (cancel-timer efar-update-search-results-timer))
  (setq efar-update-search-results-timer nil)
  ;; fix end time
  (push (cons :end-time (time-to-seconds (current-time))) efar-last-search-params)
  
  (setq efar-search-running-p nil)
  
  (efar-change-panel-mode :search))

(defun efar-make-search-process ()
  "Make search subprocess."
  (let ((proc (make-process
	       :name "efar-search-process"
	       :stderr (get-buffer-create "*eFar search error*")
	       :command (efar-search-process-command)
	       :filter #'efar-search-process-filter
	       :coding efar-search-coding
	       :noquery t)))
    
    (set-process-query-on-exit-flag proc nil)
    ;; send command to setup network connection to the server
    (efar-search-send-command proc :setup-server-connection efar-search-server-port)
    
    proc))

(defun efar-search-send-command (proc command args)
  "Send COMMAND and ARGS to the subprocess PROC."
  (let ((cmd (concat (prin1-to-string (cons command args)) "\n")))
    
    (if (process-live-p proc)
	(process-send-string proc cmd)
      (message "Process is not active!"))))

(defun efar-search-process-filter (proc string)
  "Filter function for the search server.
Processes message STRING arriving from search subprocess PROC."
  (let ((pending (assoc proc efar-search-process-pending-messages))
	message
	index)
    (unless pending
      (setq efar-search-process-pending-messages (cons (cons proc "") efar-search-process-pending-messages))
      (setq pending  (assoc proc efar-search-process-pending-messages)))
    
    (setq message (concat (cdr pending) string))
    
    (while (setq index (string-match "\n" message))
      (setq index (1+ index))
      
      (let* ((res (car (read-from-string (substring message 0 index))))
	     (message-type (car res))
	     (data (cdr res)))
	;; process message once we get full one (messaged separated by \n)
	(efar-search-process-message proc message-type data))
      
      (setq message (substring message index)))
    
    (setcdr pending message)))

(defvar efar-count 0)
(defun efar-search-process-message (proc message-type data)
  "Process a message form subprocess PROC.
Message consists of MESSAGE-TYPE and DATA."
  (pcase message-type
    ;; message from subprocess about found files
    ;; we just push this file to the search result list
    (:found-file (let* ((file (cdr (assoc :name data)))
			(attrs (file-attributes file 'string)))
		   (push (append (push file attrs) (list (cdr (assoc :lines data)))) efar-search-results)))
    ;; message from the subprocess indicating that it finished his work
    ;; once all subprocesses send this message we finish search
    (:finished (setq efar-search-clients (cl-remove (process-name proc) efar-search-clients :test 'equal))
	       (unless efar-search-clients
		 (efar-search-finished)))
    ;; message from subprocess indicating that file was skipped during search due to inaccessibility
    ;; we just add ths file to the list of skipped ones
    (:file-error (let ((errors (cdr (assoc :errors efar-last-search-params))))
		   (push data errors)
		   (push (cons :errors errors) efar-last-search-params)))
    ;; message from the subprocess about unhandled error
    ;; we show error message and abort the search
    (:common-error (push (cons :errors data) efar-last-search-params)
		   (efar-search-kill-all-processes)
		   (make-thread 'efar-run-search-processes)
		   (efar-search-finished)
		   (efar-set-status (concat "Error occurred during search: " data)))))

(defun efar-search-int-start-search (args)
  "Start file search with parameters defined in ARGS in the subprocess.
Executed in search manager process."
  (let ((dir (cdr (assoc :dir args)))
	(wildcards (cdr (assoc :wildcards args)))
	(text (cdr (assoc :text args)))
	(regexp? (or (cdr (assoc :regexp? args)) nil))
	(ignore-case? (or (cdr (assoc :ignore-case? args)) nil)))
    ;; do the search with given parameters
    (efar-search-files-recursively dir wildcards text regexp? ignore-case?)
    ;; once all files in the directory are processed, send command to subprocesses to finish work
    (cl-loop for proc in efar-search-processes do
	     (efar-search-send-command proc :finished '()))
    ;; inform main process that manager finished the search
    (process-send-string efar-search-server (concat (prin1-to-string (cons :finished '())) "\n"))))

(defun efar-search-files-recursively (dir wildcards &optional text regexp? ignore-case?)
  "Main search function.
Does the search for files in directory DIR.
Files should match file mask(s) WILDCARDS.
When TEXT is not nil given string is searched in the files.
When REGEXP? is t text is treated as regular expression.
Case is ignored when IGNORE-CASE? is t."
  ;; loop over all entries in the DIR
  (cl-loop for entry in (cl-remove-if (lambda(e) (or (string= (car e) ".") (string= (car e) ".."))) (directory-files-and-attributes dir nil nil t 'string)) do
	   
	   (let* ((symlink? (stringp (cadr entry)))
		  (dir? (or (equal (cadr entry) t)
			    (and symlink?
				 (file-directory-p (cadr entry)))))
		  (real-file-name (expand-file-name (if symlink?
							(cadr entry)
						      (car entry))
						    dir)))
	     
	     ;; we process directory only if it is accessible
	     ;; otherwise we skip it and report an error
	     (if (and dir?
		      (not (file-accessible-directory-p real-file-name)))
		 (process-send-string  efar-search-server (concat (prin1-to-string (cons :file-error (cons real-file-name "directory is inaccessible"))) "\n"))
	       
	       ;; when entry is a directory or a symlink pointing to the directory call function recursivelly for it
	       (when (and dir?
			  (or (not symlink?)
			      efar-search-follow-symlinks-p))
		 (efar-search-files-recursively real-file-name wildcards text regexp? ignore-case?))
	       
	       ;; when entry is a file or text for search inside files is not given
	       (when (or (not dir?)
			 (not text))
		 
		 ;; if file name matches any of given WILDCARDS
		 (when (catch :matched
			 (cl-loop for wildcard in wildcards do
				  (when (string-match-p (wildcard-to-regexp wildcard) (car entry))
				    (throw :matched t)))
			 nil)
		   ;; if text to search is given
		   (if text
		       ;; if file is readable then send file to subprocess to search the text inside
		       (if (file-readable-p real-file-name)
			   (progn
			     ;; we do text search parallel sending files one by one to all subprocesses by turns
			     (let* ((proc (efar-next-search-process))
				    (request (cons :process-file (list (cons :file real-file-name) (cons :text text) (cons :regexp? regexp?) (cons :ignore-case? ignore-case?)))))
			       (when real-file-name
				 (process-send-string proc (concat
							    (prin1-to-string
							     request)
							    "\n")))))
			 ;; otherwise skip it and report a file error
			 (process-send-string  efar-search-server (concat (prin1-to-string (cons :file-error (cons real-file-name "file is not readable"))) "\n")))
		     
		     ;; otherwise report about found file
		     (process-send-string  efar-search-server (concat (prin1-to-string (cons :found-file (list (cons :name real-file-name) (cons :lines '())))) "\n")))))))))


(defun efar-search-process-file (args)
  "Search text in the file according to the parameters defined in ARGS."
  (let ((file (cdr (assoc :file args)))
	(text (cdr (assoc :text args)))
	(regexp? (or (cdr (assoc :regexp? args)) nil))
	(ignore-case? (or (cdr (assoc :ignore-case? args)) nil)))
    (when (and file text)
      
      (condition-case error
	  (let ((hits (let ((hits '())
			    (case-fold-search ignore-case?) ;; case insensitive search when ignore-case? is t
			    (search-func (if regexp? 're-search-forward 'search-forward))) ;; use regular expression for search when regexp? is t
			;; open file in temp buffer
			(with-temp-buffer
			  (insert-file-contents file)
			  (goto-char 0)
			  ;; do search the text
			  (while (funcall search-func text nil t)
			    ;; store line number and whole line where searched text occurs
			    (push (cons (line-number-at-pos)
					(replace-regexp-in-string "\n" "" (thing-at-point 'line t)))
				  hits)
			    (forward-line)))
			
			(reverse hits))))
	    ;; if text is found in the file send information to main process
	    (when hits
	      (process-send-string  efar-search-server (concat (prin1-to-string (cons :found-file (list (cons :name file) (cons :lines hits)))) "\n"))))
	;; if any error occur skip file and report an error
	(error
	 (process-send-string efar-search-server (concat (prin1-to-string (cons :file-error (cons file (error-message-string error)))) "\n")))))))


(defun efar-process-search-request ()
  "Main entry point for search subprocesses.
Waits for commands in standard input."
  (let ((coding-system-for-write efar-search-coding))
    (condition-case err
	(catch :exit
	  ;; subprocess main loop
	  (while t
	    ;; get command and arguments from the request arriving to standard input
	    (let* ((request-string (read-from-minibuffer ""))
		   (request (car (read-from-string request-string)))
		   (command (car request))
		   (args (cdr request)))
	      
	      (pcase command
		;; command to set up connection to the main process
		(:setup-server-connection
		 (setq efar-search-server (make-network-process :name "efar-server"
								:host "localhost"
								:service args
								:noquery t
								:nowait t))
		 (set-process-query-on-exit-flag efar-search-server nil)
		 (setq efar-search-server-port args))
		
		;; command to start search subprocesses (relevant for search manager only)
		(:run-search-processes
		 (cl-loop repeat efar-max-search-processes  do
			  (push (efar-make-search-process) efar-search-processes)))
		
		;; command to start the search (relevant for search manager only)
		(:start-search
		 (progn
		   (efar-search-int-start-search args)
		   (cl-loop for proc in efar-search-processes do
			    (while (accept-process-output proc 1)))
		   (while (accept-process-output nil 1))))
		
		;; command to inform main process that search in subprocess is finished
		(:finished
		 (process-send-string efar-search-server (concat (prin1-to-string (cons :finished '())) "\n")))
		
		;; command to subprocess to search text in the file
		(:process-file
		 (efar-search-process-file args))
		
		;; command to subprocess to finish work (process "dies")
		(:exit
		 (cl-loop for proc in efar-search-processes do
			  (process-send-string proc (concat (prin1-to-string (cons :exit '())) "\n")))
		 (throw :exit t))))))
      
      (error
       (process-send-string  efar-search-server (concat (prin1-to-string (cons :common-error (error-message-string err))) "\n"))))))

(defun efar-next-search-process ()
  "Get next search process from the pool.
We do text search parallel sending files one by one to all subprocesses by turns."
  (let* ((processes efar-search-processes)
	 (last (car (last processes))))
    (setq efar-search-processes (cons last (remove last processes)))
    (car efar-search-processes)))

(defun efar-show-search-results (&optional side)
  "Show search results in panel SIDE."
  
  (let* ((side (or side (efar-get :current-panel)))
	 (errors (cdr (assoc :errors efar-last-search-params)))
	 (result-string nil)
	 (status-string nil))
    
    ;; if unexpected/unhandled error occurred during search we report failure
    (if (stringp errors)
	(progn
	  (setf result-string "Search results [failed]")
	  (setf status-string (concat "Search failed with erorr: " errors)))
      
      (setf result-string (concat "Search results"
				  (when efar-last-search-params
				    (concat " - " (int-to-string (length (efar-get :panels side :files)))
					    (if (cdr (assoc :end-time efar-last-search-params))
						" [finished]" " [in progress]" )
					    
					    (when errors
					      (concat " (" (int-to-string (length errors)) " skipped)"))))))
      
      
      
      (setf status-string (concat (cond (efar-search-running-p
					 "Search running for files ")
					((cdr (assoc :end-time efar-last-search-params))
					 (concat "Search finished in " (int-to-string (round (- (cdr (assoc :end-time efar-last-search-params)) (cdr (assoc :start-time efar-last-search-params))))) " second(s) for files "))
					(t
					 "No search has been executed yet"))
				  
				  (when (cdr (assoc :start-time efar-last-search-params))
				    (setq status-string (concat status-string
								"in " (cdr (assoc :dir efar-last-search-params))
								" matching mask(s) '" (string-join (cdr (assoc :wildcards efar-last-search-params)) ",") "'"
								(when (cdr (assoc :text efar-last-search-params))
								  (concat " and containing text '" (cdr (assoc :text efar-last-search-params)) "'"
									  " (" (if (cdr (assoc :ignore-case? efar-last-search-params)) "CI" "CS") ")"))))))))
    
    (efar-set result-string :panels side :dir)
    
    (efar-remove-notifier side)
    
    (efar-set-status status-string nil t)
    (efar-calculate-widths)
    (efar-write-enable (efar-redraw))))


(defun efar-show-search-results-in-buffer ()
  "Show detailed search results in other buffer."
  (if efar-search-running-p
      
      (efar-set-status "Search is still running" nil t)
    
    (efar-set-status "Generating report with search results...")
    
    (and (get-buffer efar-search-results-buffer-name) (kill-buffer efar-search-results-buffer-name))
    
    (let ((buffer (get-buffer-create efar-search-results-buffer-name))
	  (dir (cdr (assoc :dir efar-last-search-params)))
	  (wildcards (cdr (assoc :wildcards efar-last-search-params)))
	  (text (cdr (assoc :text efar-last-search-params)))
	  (ignore-case? (cdr (assoc :ignore-case? efar-last-search-params)))
	  (regexp? (cdr (assoc :regexp? efar-last-search-params)))
	  (errors (cdr (assoc :errors efar-last-search-params))))
      
      (with-current-buffer buffer
	(read-only-mode 0)
	(erase-buffer)
	
	;; insert header with description of search parameters
	(insert "Found " (int-to-string (length (efar-get :panels (efar-get :current-panel) :files)))
		" files in " (int-to-string (round (- (cdr (assoc :end-time efar-last-search-params)) (cdr (assoc :start-time efar-last-search-params))))) " second(s).\n")
	
	;; in case if some file were skipped uring search we add corresponding hint to the header
	(when errors
	  (let ((p (point)))
	    (insert (int-to-string (length errors)) " file(s) skipped. See list at the bottom.")
	    (add-text-properties p (point)
				 '(face efar-non-existing-current-file-face))
	    (insert "\n")))
	
	(insert "Directory: " dir "\n"
		"File name mask(s): " (string-join wildcards ",") "\n"
		(or (when text
		      (concat "Text '" text "' found in "
			      (let ((hits 0))
				(cl-loop for file in (efar-get :panels (efar-get :current-panel) :files) do
					 (setq hits (+ hits (length (nth 13 file)))))
				(int-to-string hits)) " line(s)\n"
				"Ignore case: " (if ignore-case? "yes" "no") "\n"
				"Use regexp: " (if regexp? "yes" "no") "\n"))
		    "")
		"\n")
	
	;; output list of found files (and source lines when searching for text)
	(cl-loop for file in (efar-get :panels (efar-get :current-panel) :files) do
		 
		 ;; create a link to the file
		 (insert-button (car file)
				:type 'efar-search-find-file-button
				:file (car file))
		 (insert "\n")
		 
		 ;; create links to source lines
		 (cl-loop for line in (nth 13 file) do
			  
			  (let ((line-number (car line))
				(line-text (cdr line)))
			    (insert-button (concat (int-to-string line-number) ":\t" line-text)
					   :type 'efar-search-find-line-button
					   :file (car file)
					   :line-number line-number
					   :text text
					   :ignore-case? ignore-case?
					   :regexp? regexp?))
			  (insert "\n"))
		 (insert "\n"))
	
	
	;; output skipped files
	(when errors
	  (insert "\nFollowing files/directries are inaccessible and therefore were skipped:\n")
	  (cl-loop for file in errors do
		   (insert (car file) " (" (cdr file) ")")
		   (insert "\n")))
	
	;; highlight searched text
	(goto-char (point-min))
	(when text
	  (if (cdr (assoc :regexp? efar-last-search-params))
	      (highlight-regexp text 'hi-yellow)
	    (highlight-phrase text 'hi-yellow)))
	
	(read-only-mode 1))
      
      (switch-to-buffer-other-window buffer)
      (efar-set-status "Ready"))))

(defun efar-search-find-file-button (button)
  "Open file from search results buffer and navigate to searched text.
BUTTON is a button clicked."
  (let ((file (button-get button :file))
	(line-number (button-get button :line-number))
	(text (button-get button :text))
	(ignore-case? (button-get button :ignore-case?))
	(regexp? (button-get button :regexp?)))
    
    ;; open file in other window
    (find-file-other-window file)
    (goto-char 0)
    
    ;; navigate to the line containing searched text
    ;; and activate isearch for the searched text
    (when line-number
      (forward-line (- line-number 1))
      (isearch-mode t regexp?)
      (if ignore-case?
	  (setq text (downcase text)))
      (isearch-process-search-string text
				     (mapconcat #'isearch-text-char-description text "")))))

;;--------------------------------------------------------------------------------
;; eFar major mode
;;--------------------------------------------------------------------------------

(defvar efar-mode-map
  (let ((keymap (make-sparse-keymap)))
    (cl-loop for key in efar-keys do
	     (let ((key-seq (if (null (nth 3 key))
				(kbd (nth 0 key))
			      (symbol-value (nth 3 key)))))
	       (define-key keymap
		 key-seq
		 `(lambda()
		    (interactive)
		    (efar-key-press-handle (nth 1 ',key) (nth 2 ',key) (nth 6 ',key))))))
    
    (cl-loop for k in '("<double-mouse-1>"
			"<mouse-1>"
			"<wheel-down>"
			"<wheel-up>"
			"<C-mouse-1>"
			"<C-down-mouse-1>"
			"<S-mouse-1>"
			"<S-down-mouse-1>"
			"<drag-mouse-1>"
			"<down-mouse-1>")
	     do
	     (define-key keymap (kbd k) (lambda (event)
					  (interactive "e")
					  (efar-process-mouse-event event))))
    keymap)
  "Keymap for eFar buffer.")

(defvar efar-menu  "Keymap for the eFar buffer menu bar.")

(defun efar-customize ()
  "Open customization buffer for eFar."
  (interactive)
  (customize-group 'efar))

(easy-menu-define efar-menu efar-mode-map
  "Menu for eFar mode."
  `(,"eFar"
    [,"Describe keys" efar-show-help :active t :keys "C-c ?"]
    [,"Customize" efar-customize t]))

(define-derived-mode
  efar-mode fundamental-mode "eFar"
  "Major mode for the eFar buffer."
  :group 'efar
  
  (if (not (equal (buffer-name (current-buffer)) efar-buffer-name))
      (warn "Mode is intended be used for eFar buffer only")
    
    (easy-menu-add efar-menu)
    ;; hooks
    (add-hook 'window-configuration-change-hook #'efar-window-conf-changed)
    (add-hook 'kill-buffer-hook #'efar-buffer-killed nil 'local)
    (add-hook 'kill-emacs-hook #'efar-emacs-killed)))

;;; efar.el ends here
