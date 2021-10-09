;;; filetree.el --- File tree view/manipulatation package                     -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Ketan Patel
;;
;; Author: Ketan Patel <knpatel401@gmail.com>
;; URL: https://github.com/knpatel401/filetree
;; Package-Version: 20211008.2353
;; Package-Commit: 1f0bcf009bf124c213d64dd2726061db6af981b5
;; Package-Requires: ((emacs "27.1") (dash "2.12.0") (helm "3.7.0"))
;; Version: 1.0.1

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

;; Filetree is a package that provides two basic functions:

;; File tree viewer
;;  The viewer displays a file list as a directory tree in a
;;  special buffer.  The file list can be populated from any list of files.
;;  There are functions to populate from a number of common sources: recentf,
;;  files in buffer-list, files in the current directory, and files found
;;  recursively in the current directory.  Within the viewer, the file list can
;;  be filtered and expanded in various ways and operations can be performed on
;;  the filtered file list (e.g., grep over files in list).  Multiple file lists
;;  can be saved and retrieved between sessions.
;;
;; File notes
;;  The file notes enables the user to write and display (org-mode) notes
;;  associated with individual files and directories.  The note can be displayed
;;  in a side buffer either when cycling through files in the file tree viewer
;;  or when the file is open in a buffer.  The notes are kept in a single org-mode
;;  file with a heading for each file/directory.
;;
;; To use add the following to your ~/.emacs:
;; (require 'filetree')
;;
;; Use one of the following to run filetree for a common use case:
;; M-x filetree-show-recentf-files
;; M-x filetree-show-cur-dir
;; M-x filetree-show-cur-dir-recursively
;; M-x filetree-show-cur-buffers

;; -------------------------------------------
;;; Code:
(require 'dash)
(require 'xref)
(require 'helm)
(require 'seq)
(require 'vc)
(require 'dired-aux)
;;(require 'cl-lib)

;; External functions/variables
(declare-function org-narrow-to-subtree "org" ())
(declare-function all-the-icons-icon-for-dir "all-the-icons")
(declare-function all-the-icons-icon-for-file "all-the-icons")
(defvar recentf-list)
;;(defvar text-scale-mode-amount 0)

(defgroup filetree nil
  "Tree view of file list and file notes."
  :group 'matching
  :prefix "filetree-")

(defvar filetree-version "1.01")

(defconst filetree-buffer-name "*filetree*")

(defcustom filetree-notes-file (concat user-emacs-directory
                                       "filetree-notes.org")
  "File used for file specific notes."
  :type 'file)
(defcustom filetree-relative-notes-filename "filetree-notes-local.org"
  "Filename for file specific notes file with relative path."
  :type 'string)

(defcustom filetree-saved-lists-file (concat user-emacs-directory
                                             "filetree-saved-lists.el")
  "File used for saved file lists."
  :type 'file)
(defcustom filetree-default-file-face 'default
  "Default face to use for files.
This is used if the file doesn't match any regex in `filetree-filetype-list'."
  :type 'face)
(defcustom filetree-use-all-the-icons nil
  "Set to t to use file and directory icons.
This can also be toggled using `filetree-toggle-use-all-icons'."
  :type 'boolean)
(defcustom filetree-info-window nil
  "Set to t to show info in side window.
This can also be toggled using `filetree-toggle-info-buffer'."
  :type 'boolean)
(defcustom filetree-show-remote-file-info nil
  "Set to t to show additional file info for remote files as well."
  :type 'boolean)
(defcustom filetree-enable-nonexistent-file-removal t
  "Set to t to check for and remove non-existent files during filetree updates."
  :type 'boolean)
(defcustom filetree-exclude-list
  '("~$" "#$" ".git\/" ".gitignore$" "\/\.\/$" "\/\.\.\/$" ".DS_Store$")
  "List of regex for files to exclude from file list."
  :type '(repeat regexp))
(defcustom filetree-helm-candidate-number-limit 10000
  "Maximum number of candidates to show in tree when using helm-based filtering."
  :type 'integer)
(defcustom filetree-info-cycle-list
  '(;; cycle 0 - no info
    ()
    ;; cycle 1 - modes/size/last mod
    (("Modes" 11 filetree-get-file-modes "right")
     ("Size" 7 filetree-get-file-size "right")
     ("Last Mod" 12 filetree-get-file-last-modified "left"))
    ;; cycle 2 - size/last mod
    (("Size" 7 filetree-get-file-size "right")
     ("Last Mod" 12 filetree-get-file-last-modified "left"))
    ;; cycle 3 - last mod
    (("Last Mod" 12 filetree-get-file-last-modified "left"))
    ;; cycle 4 - last mod/modes
    (("Last Mod" 12 filetree-get-file-last-modified "left")
     ("Modes" 11 filetree-get-file-modes "right"))
    ;; cycle 5 - last mod/modes/size
    (("Last Mod" 12 filetree-get-file-last-modified "left")
     ("Modes" 11 filetree-get-file-modes "right")
     ("Size" 7 filetree-get-file-size "right")))
  "List of file info contents to show on left side of filetree window.
Each entry of this list is itself a list of the columns of information
to show.  A nil entry corresponds to showing no info.  Each entry of this
list has the following entries:
- column heading (this can be propertized if desired)
- width of the column
- function that take a file as argument and returns a (possibly propertized)
  string to show
- string with justification to use for the column contents
  (left, right, center), default is left."
  :type '(repeat (repeat :tag "View Set"
                         (list :tag "Column"
                               (string :tag "Heading")
                               (integer :tag "Column Width")
                               function
                               (choice :tag "Column Justification"
                                       (const "left")
                                       (const "right")
                                       (const "center"))))))

(defgroup filetree-symb-for nil
  "Symbols used for drawing tree in filetree package."
  :group 'filetree
  :prefix "filetree-symb-for-")

(defcustom filetree-symb-for-root "\u25ba"
  "Symbol for end of mark indicating root dir."
  :type 'character)
(defcustom filetree-symb-for-box "\u25a0"
  "Box symbol used in mark for root dir."
  :type 'character)
(defcustom filetree-symb-for-vertical-pipe "\u2502"
  "Symbol to indicate continuing branch."
  :type 'character)
(defcustom filetree-symb-for-horizontal-pipe "\u2500"
  "Symbol for branch for node on current line."
  :type 'character)
(defcustom filetree-symb-for-left-elbow "\u2514"
  "Symbol for last node on branch."
  :type 'character)
(defcustom filetree-symb-for-right-elbow "\u2518"
  "Symbol for bottom right hand corner."
  :type 'character)
(defcustom filetree-symb-for-branch-and-cont "\u251c"
  "Symbol indicating continuing branch which also includes node on current line."
  :type 'character)
(defcustom filetree-symb-for-file-node "\u25cf"
  "Symbol for file node."
  :type 'character)
(defcustom filetree-symb-for-mark (propertize "\u25b6"
                                              'font-lock-face
                                              '(:foreground "DarkOliveGreen4"))
  "Symbol for marking files."
  :type 'character)

(defvar filetree-info-buffer nil)
(defvar filetree-info-buffer-state nil)
(defvar filetree-saved-lists '(("recentf" (lambda ()
                                            recentf-list))))
(if (file-exists-p filetree-saved-lists-file)
    (with-temp-buffer
      (insert-file-contents filetree-saved-lists-file)
      (eval-buffer)))

(defvar filetree-start-position 0)
(defvar filetree-max-depth 0)
(defvar filetree-overall-depth nil)
(defvar filetree-current-file-list nil)
(defvar filetree-file-list-stack nil)
(defvar filetree-file-list-stack-save nil)
(defvar filetree-marked-file-list nil)
(defvar filetree-show-flat-list nil)
(defvar filetree-combine-dir-names t)
(defvar filetree-helm-source
  '((name . "filetree")
    (candidates . filetree-current-file-list)
    (candidate-number-limit . filetree-helm-candidate-number-limit)
    (cleanup . (lambda ()
                 (remove-hook 'helm-after-update-hook
                              #'filetree-helm-hook)
                 (setq filetree-file-list-stack filetree-file-list-stack-save)
                 (filetree-update-buffer)))
    (buffer . ("*helm-filetree-buffer*"))
    (prompt . ("selection:"))))
  
(defvar filetree-filetype-list nil
  "List of file types with filter shortcuts, regex for filetype, and face.
This is populated using `filetree-add-filetype', for example see
`filetree-configure-default-filetypes'")

(defvar filetree-current-info-cycle 0
  "This tracks the current state of file info on the left side of the window.")

(defvar filetree-map
  (let ((map (make-sparse-keymap)))
    ;; (define-key map "?" '(lambda () (interactive) (message "%s %s" (filetree-get-name)
    ;;                                                          (if (button-at (point))
    ;;                                                              (button-get (button-at (point)) 'subtree)
    ;;                                                            nil))))
    (define-key map "j" 'filetree-next-line)
    (define-key map "k" 'filetree-prev-line)
    (define-key map (kbd "<down>") 'filetree-next-line)
    (define-key map (kbd "<up>") 'filetree-prev-line)
    (define-key map (kbd "C-j") 'filetree-next-line)
    (define-key map (kbd "C-k") 'filetree-prev-line)
    (define-key map (kbd "SPC") 'filetree-next-branch)
    (define-key map (kbd "TAB") 'filetree-prev-branch)
    (define-key map "q" 'filetree-close-session)
    (define-key map "0" 'filetree-set-max-depth)
    (define-key map "1" 'filetree-set-max-depth-1)
    (define-key map "2" 'filetree-set-max-depth-2)
    (define-key map "3" 'filetree-set-max-depth-3)
    (define-key map "4" 'filetree-set-max-depth-4)
    (define-key map "5" 'filetree-set-max-depth-5)
    (define-key map "6" 'filetree-set-max-depth-6)
    (define-key map "7" 'filetree-set-max-depth-7)
    (define-key map "8" 'filetree-set-max-depth-8)
    (define-key map "9" 'filetree-set-max-depth-9)
    (define-key map "r" 'filetree-show-recentf-files)
    (define-key map "f" 'filetree-filter)
    (define-key map "/" 'filetree-toggle-combine-dir-names)
    (define-key map "b" 'filetree-pop-file-list-stack)
    (define-key map "-" 'filetree-diff-with-file-list-stack)
    (define-key map "+" 'filetree-union-with-file-list-stack)
    (define-key map "g" 'filetree-grep-marked-files)
    (define-key map "C" 'filetree-copy-marked-files-only)
    (define-key map "R" 'filetree-move-marked-files-only)
    (define-key map "d" 'filetree-run-dired)
    (define-key map "e" 'filetree-expand-dir)
    (define-key map "E" 'filetree-expand-dir-recursively)
    (define-key map "x" 'filetree-remove-item)
    (define-key map "o" 'filetree-open-marked-files)
    (define-key map "K" 'filetree-kill-marked-buffers)
    (define-key map "m" 'filetree-mark-item)
    (define-key map "A" 'filetree-mark-all)
    (define-key map "M" 'filetree-select-marked-items)
    (define-key map "!" 'filetree-do-shell-command-on-marked-files-only)
    (define-key map "c" 'filetree-clear-marks)
    (define-key map "L" 'filetree-select-file-list)
    (define-key map "S" 'filetree-save-list)
    (define-key map "D" 'filetree-delete-list)
    ;; (define-key map "-" 'filetree-reduce-list-by-10)
    (define-key map "." 'filetree-toggle-flat-vs-tree)
    (define-key map "i" 'filetree-toggle-info-buffer)
    (define-key map "I" (lambda ()
                          "Toggle filetree-info-buffer and switch to it if active"
                          (interactive)
                          (filetree-toggle-info-buffer t)))
    (define-key map "s" 'filetree-helm-filter)
    (define-key map ";" 'filetree-toggle-use-all-icons)
    (define-key map "]" 'filetree-increment-current-info-cycle)
    (define-key map "[" 'filetree-decrement-current-info-cycle)
    map)
  "Keymap for filetree.")

(defun filetree-close-session ()
  "Close filetree session."
  (interactive)
  (kill-buffer (current-buffer)))

(defun filetree-add-filetype (name shortcut regex face)
  "Add a filetype to `filetree-filetype-list' for special handling.
- NAME is the name of the filetype (e.g., \"elisp\")
- SHORTCUT is the shortcut char literal to use for this filetype when filtering
- REGEX is the regular expression to use for detecting the filetype
- FACE is the face to use for this filetype"
  (push (list shortcut name regex face) filetree-filetype-list))

(defun filetree-configure-default-filetypes ()
  "Define default `filetree-filetype-list'.
This defines filetype faces, filetype regex, and filter shortcuts.
This function is given as an example.  The user can generate their own
custom function with calls to `filetree-add-filetype'"
  (interactive)
  (setq filetree-filetype-list nil)
  (filetree-add-filetype "No Filter" 0   ""        ())
  (filetree-add-filetype "Python"    ?p  "\.py$"   '(:foreground "steel blue"))
  (filetree-add-filetype "Org-mode"  ?o  "\.org$"  '(:foreground "DarkOliveGreen4"))
  (filetree-add-filetype "elisp"     ?e  "\\(?:\\.e\\(?:l\\|macs\\)\\)"  '(:foreground "purple"))
  (filetree-add-filetype "C"         ?c  "\\(?:\\.[ch]$\\|\\.cpp\\)"     '(:foreground "navyblue"))
  (filetree-add-filetype "PDF"       ?d  "\.pdf$"  '(:foreground "maroon"))
  (filetree-add-filetype "Matlab"    ?m  "\.m$"    '(:foreground "orange"))
  (filetree-add-filetype "Text"      ?t  "\.txt$"  '(:foreground "gray50")))

(filetree-configure-default-filetypes)

;; (defun filetree-get-vc-state (filename)
;;   "Return a string with the `vc-state' of FILENAME."
;;   (let ((entry (format "%s"
;;                        (or
;;                         (if (not (file-remote-p filename))
;;                             (vc-state filename)
;;                           "remote")
;;                         ""))))
;;     (put-text-property 0 (length entry) 'face '(:foreground "steel blue")
;;                        entry)
;;     entry))

(defun filetree-get-file-size (filename)
  "Return a string with the size of FILENAME."
  (if (or filetree-show-remote-file-info
          (not (file-remote-p filename)))
      (let ((attributes (file-attributes filename)))
        (if attributes
            (format "%s"
                    (file-size-human-readable
                     (file-attribute-size attributes)))
          "N/A"))
    "remote"))

(defun filetree-get-file-modes (filename)
  "Return a string with the file modes of FILENAME."
  (if (or filetree-show-remote-file-info
          (not (file-remote-p filename)))
      (let ((attributes (file-attributes filename)))
        (if attributes
            (let ((modes (file-attribute-modes attributes)))
              (if (string-prefix-p "d" modes)
                  (propertize modes 'font-lock-face 'bold)
                modes))
          "N/A    "))
    "remote  "))

(defun filetree-get-file-last-modified (filename)
  "Return a string with the last modification time for FILENAME."
  (if (or filetree-show-remote-file-info
          (not (file-remote-p filename)))
      (let ((attributes (file-attributes filename)))
        (if attributes
            (format-time-string "%b %d %Y"
                                (file-attribute-modification-time attributes))
          "    N/A"))
    "   remote"))

(defun filetree-filter ()
  "Interactive function to filter 'filetree-current-file-list'.
Uses regular expression in 'filetree-filetype-list' or by expression entered by user."
  (interactive)
  (let ((my-filetree-mode-filter-list (mapcar (lambda (x)
                                              (seq-subseq x 0 3))
                                            filetree-filetype-list))
        (my-filetree-regex nil)
        (filetree-elem nil)
        (filetree-char-input (read-char)))
    (while (/= (length my-filetree-mode-filter-list) 0)
      (setq filetree-elem (car my-filetree-mode-filter-list))
      (if (eq filetree-char-input (car filetree-elem))
          (setq my-filetree-regex (nth 2 filetree-elem)))
      (setq my-filetree-mode-filter-list (cdr my-filetree-mode-filter-list)))
    (if (not my-filetree-regex)
        (setq my-filetree-regex (read-string "Type a string: ")))
    (setq filetree-current-file-list (delete nil (mapcar (lambda (x)
                                                         (if (string-match
                                                              my-filetree-regex
                                                              (file-name-nondirectory x))
                                                             x nil))
                                                       filetree-current-file-list)))
    (filetree-update-buffer)))

(defun filetree-remove-item (&optional file-or-dir)
  "Remove the file or subdir FILE-OR-DIR from the `filetree-current-file-list'.
If file-or-dir not specified, use file or dir at point."
  (interactive)
  (let ((file-or-dir (or file-or-dir (filetree-get-name))))
    (setq filetree-current-file-list (delete
                                    nil
                                    (if (string= "/"
                                                 (substring file-or-dir -1))
                                        ;; removing subdirectory
                                        (mapcar (lambda (x)
                                                  (if (string-match
                                                       file-or-dir
                                                       x)
                                                      nil x))
                                                filetree-current-file-list)
                                      ;; removing file
                                      (mapcar (lambda (x)
                                                (if (string=
                                                     file-or-dir
                                                     x)
                                                    nil x))
                                              filetree-current-file-list)))))
  (filetree-update-buffer))

(defun filetree-clear-marks ()
  "Remove all files from `filetree-marked-file-list'."
  (interactive)
  (setq filetree-marked-file-list nil)
  (filetree-update-buffer t))

(defun filetree-select-marked-items ()
  "Set `filetree-current-file-list' to files in `filetree-marked-file-list'."
  (interactive)
  (setq filetree-current-file-list filetree-marked-file-list)
  (filetree-clear-marks)
  (filetree-update-buffer))

(defun filetree-kill-marked-buffers ()
  "Kill buffers associated with files in `filetree-marked-file-list'.
If `filetree-marked-file-list' is empty, then use `filetree-current-file-list'."
  (interactive)
  ; if no marked files treat all files as marked
  (if (= (length filetree-marked-file-list) 0)
      (setq filetree-marked-file-list filetree-current-file-list))
  (let ((my-buffer-list (buffer-list))
        (my-buffer nil))
    (while my-buffer-list
      (setq my-buffer (car my-buffer-list))
      (setq my-buffer-list (cdr my-buffer-list))
      (if (member (buffer-file-name my-buffer)
                  filetree-marked-file-list)
          (kill-buffer my-buffer)))
    (setq filetree-current-file-list (-difference filetree-current-file-list filetree-marked-file-list))
    (setq filetree-marked-file-list nil)
  (filetree-update-buffer)))

(defun filetree-open-marked-files ()
  "Open buffer for each file in `filetree-marked-file-list'.
If buffer already exists, new buffer is not opened.  If 
`filetree-marked-file-list' is empty use `filetree-current-file-list'"
  (interactive)
  ; if no marked files treat all files as marked
  (if (= (length filetree-marked-file-list) 0)
      (setq filetree-marked-file-list filetree-current-file-list))
  (let ((this-file ""))
    (while filetree-marked-file-list
      (setq this-file (car filetree-marked-file-list))
      (setq filetree-marked-file-list (cdr filetree-marked-file-list))
      (if (file-exists-p this-file)
          (find-file-noselect this-file)
        (message (concat this-file " not found.")))))
  (filetree-update-buffer t))

(defun filetree-delete-marked-files-only ()
  "Delete files in `filetree-marked-file-list'.
Confirms with user before deleting."
  (interactive)
  (if (y-or-n-p (concat "Are you sure you want to delete "
                        (number-to-string (length filetree-marked-file-list))
                        " files?"))
      (while filetree-marked-file-list
        (setq my-file (car filetree-marked-file-list))
        (setq filetree-marked-file-list (cdr filetree-marked-file-list))
        (delete-file my-file)
        (setq filetree-current-file-list (delete my-file
                                                 filetree-current-file-list))))
  (filetree-update-buffer))


(defun filetree-do-shell-command-on-marked-files-only ()
  "Use dired-aux functions to run shell command on marked files.
Output appears in *Shell Command Output*"
  (interactive)
  (dired-do-shell-command (dired-read-shell-command
                           "! on %s: " current-prefix-arg
                           filetree-marked-file-list)
                          nil filetree-marked-file-list))

(defun filetree-move-marked-files-only ()
  "Move files in `filetree-marked-file-list'.
User is prompted with directory to move files to.  The starting dir that is 
shown to the user at the prompt is determined from the directory at point 
in the filetree."
  (interactive)
  (if (y-or-n-p (concat "Are you sure you want to move "
                        (number-to-string (length filetree-marked-file-list))
                        " files?"))
      (let ((dest-dir (read-directory-name
                       "Directory to mv files to: "
                       (file-name-directory (filetree-get-name))))
            (new-file nil)
            (orig-file nil))
        (while filetree-marked-file-list
          (setq orig-file (car filetree-marked-file-list))
          (setq filetree-marked-file-list (cdr filetree-marked-file-list))
          (setq new-file (concat dest-dir (file-name-nondirectory orig-file)))
          (rename-file orig-file new-file 1)
          (setq filetree-current-file-list (delete orig-file
                                                   filetree-current-file-list))
          (add-to-list 'filetree-current-file-list new-file))
        (filetree-update-buffer))))

(defun filetree-copy-marked-files-only ()
  "Copy files in `filetree-marked-file-list'.
User is prompted with directory to move files to.  The starting dir that is 
shown to the user at the prompt is determined from the directory at point 
in the filetree."
  (interactive)
  (if (y-or-n-p (concat "Are you sure you want to copy "
                        (number-to-string (length filetree-marked-file-list))
                        " files?"))
      (let ((dest-dir (read-directory-name
                       "Directory to copy files to: "
                       (file-name-directory (filetree-get-name))))
            (new-file nil)
            (orig-file nil))
        (while filetree-marked-file-list
          (setq orig-file (car filetree-marked-file-list))
          (setq filetree-marked-file-list (cdr filetree-marked-file-list))
          (setq new-file (concat dest-dir (file-name-nondirectory orig-file)))
          (if (not (string= orig-file new-file))
              (progn
                (copy-file orig-file new-file 1)
                (add-to-list 'filetree-current-file-list new-file))))
        (filetree-update-buffer))))

(defun filetree-mark-item (&optional file-or-dir)
  "Add/remove FILE-OR-DIR to/from `filetree-marked-file-list'.
If file-or-dir is a file then it's added to the list if not already on, and
removed if already on.  If file-or-dir is a dir then all files in
`filetree-current-file-list' within file-or-dir are added to
`filetree-marked-file-list'.
If file-or-dir not specified, use file or dir at point."
  (interactive)
  (let ((file-or-dir (or file-or-dir (filetree-get-name))))
    (if (string= "/" (substring file-or-dir -1))
        ;; add all files in directory to mark list
        (let ((files (delete nil
                             (mapcar (lambda (x)
                                       (if (string-match
                                            file-or-dir
                                            x)
                                           x nil))
                                     filetree-current-file-list))))
          (setq filetree-marked-file-list (-union files
                                                  filetree-marked-file-list))
          (filetree-update-buffer t)
          (filetree-next-branch))
      ;; add file if not in mark list otherwise remove from mark list
      (progn
        (if (member file-or-dir filetree-marked-file-list)
            (setq filetree-marked-file-list (delete file-or-dir
                                                    filetree-marked-file-list))
          (add-to-list 'filetree-marked-file-list file-or-dir))
        (filetree-update-buffer t)
        (filetree-next-line)))))

(defun filetree-mark-all ()
  "Add all files in `filetree-current-file-list' to marked files"
  (interactive)
  (setq filetree-marked-file-list (-union filetree-current-file-list
                                          filetree-marked-file-list))
  (filetree-update-buffer t))

(defun filetree-get-name ()
  "Get name of file/dir on line at current point."
  (interactive)
  (if (button-at (point))
      (button-get (button-at (point)) 'name)
    nil))

(defun filetree-expand-dir (&optional dir filter)
  "Add files in DIR to 'filetree-current-file-list'.
If DIR is not specified, use dir at point.
If FILTER is not specified, will 'read-char' from user.
The corresponding regular expression in 'filetree-filetype-list' will
be used to filter which files are included.  If FILTER does not
correspond to an entry in 'filetree-filetype-list' the user is
prompted for a string/regular expression to filter with."
  (interactive)
  (let ((dir (or dir (filetree-get-name)))
        (filetree-char-input (or filter (read-char)))
        (my-filetree-mode-filter-list (mapcar (lambda (x)
                                              (seq-subseq x 0 3))
                                            filetree-filetype-list))
        (filetree-new-files nil)
        (my-filetree-regex nil)
        (filetree-elem nil))
    (while (/= (length my-filetree-mode-filter-list) 0)
      (setq filetree-elem (car my-filetree-mode-filter-list))
      (if (eq filetree-char-input (car filetree-elem))
          (setq my-filetree-regex (nth 2 filetree-elem)))
      (setq my-filetree-mode-filter-list (cdr my-filetree-mode-filter-list)))
    (if (not my-filetree-regex)
        (setq my-filetree-regex (read-string "Type a string: ")))
    (setq filetree-new-files (delete nil (mapcar (lambda (x)
                                                  (if (string-match
                                                       my-filetree-regex
                                                         (file-name-nondirectory (car x)))
                                                        (if (stringp (nth 1 x))
                                                            nil
                                                          (if (null (nth 1 x))
                                                              (car x)
                                                            (concat (car x) "/")))
                                                      nil))
                                                (directory-files-and-attributes dir t))))
    (dolist (entry filetree-exclude-list)
                   (setq filetree-new-files (delete nil (mapcar (lambda (x)
                                                                 (if (string-match
                                                                      entry
                                                                      x)
                                                                     nil
                                                                   x))
                                                               filetree-new-files))))
    (setq filetree-current-file-list
          (-distinct (-non-nil
                      (nconc filetree-current-file-list
                             filetree-new-files)))))
  (filetree-update-buffer))

(defun filetree-expand-dir-recursively (&optional dir filter)
  "Recursively add files in DIR to 'filetree-current-file-list'.
If DIR is not specified, use dir at point.
If FILTER is not specified, will 'read-char' from user.  The corresponding
regular expression in 'filetree-filetype-list' will be used to filter
which files are included.  If FILTER does not correspond to an entry in
'filetree-filetype-list' the user is prompted for a string/regular
expression to filter with."
  (interactive)
  (let ((dir (or dir (filetree-get-name)))
        (filetree-char-input (or filter (read-char)))
        (my-filetree-mode-filter-list (mapcar (lambda (x)
                                              (seq-subseq x 0 3))
                                            filetree-filetype-list))
        (my-filetree-regex nil)
        (filetree-elem nil)
        (filetree-new-files nil))
    (while (/= (length my-filetree-mode-filter-list) 0)
      (setq filetree-elem (car my-filetree-mode-filter-list))
      (if (eq filetree-char-input (car filetree-elem))
          (setq my-filetree-regex (nth 2 filetree-elem)))
      (setq my-filetree-mode-filter-list (cdr my-filetree-mode-filter-list)))
    (if (not my-filetree-regex)
        (setq my-filetree-regex (read-string "Type a string: ")))
    (setq filetree-new-files (directory-files-recursively dir my-filetree-regex))
    (dolist (entry filetree-exclude-list)
      (setq filetree-new-files (delete nil (mapcar (lambda (x)
                                                    (if (string-match entry x)
                                                        nil
                                                      x))
                                                  filetree-new-files))))
    (setq filetree-current-file-list (-distinct (-non-nil
                                               (nconc filetree-current-file-list
                                                      filetree-new-files)))))
  (filetree-update-buffer))

(defun filetree-run-dired ()
  "Run dired on directory at point."
  (dired (filetree-get-name)))

(defun filetree-reduce-list-by-10 ()
  "Drop last 10 entries in `filetree-current-file-list'."
  (interactive)
  (if (>= (length filetree-current-file-list) 20)
      (setq filetree-current-file-list (butlast filetree-current-file-list 10))
    (if (>= (length filetree-current-file-list) 10)
        (setq filetree-current-file-list
              (butlast filetree-current-file-list
                       (- (length filetree-current-file-list) 10)))))
  (filetree-update-buffer))

(defun filetree-cycle-max-depth ()
  "Increase depth of file tree by 1 level cycle back to 0 when max depth reached."
  (interactive)
  (setq filetree-max-depth (% (+ filetree-max-depth 1)
                             filetree-overall-depth))
  (filetree-update-buffer t))
  
(defun filetree-set-max-depth (&optional max-depth)
  "Set depth of displayed file tree to MAX-DEPTH.
If maxdepth not specified, show full tree."
  (interactive)
  (setq filetree-max-depth (or max-depth 0))
  (filetree-update-buffer t))

(defun filetree-set-max-depth-1 ()
  "Set depth of displayed file to 1."
  (interactive)
  (filetree-set-max-depth 1))

(defun filetree-set-max-depth-2 ()
  "Set depth of displayed file to 2."
  (interactive)
  (filetree-set-max-depth 2))

(defun filetree-set-max-depth-3 ()
  "Set depth of displayed file to 3."
  (interactive)
  (filetree-set-max-depth 3))

(defun filetree-set-max-depth-4 ()
  "Set depth of displayed file to 4."
  (interactive)
  (filetree-set-max-depth 4))

(defun filetree-set-max-depth-5 ()
  "Set depth of displayed file to 5."
  (interactive)
  (filetree-set-max-depth 5))

(defun filetree-set-max-depth-6 ()
  "Set depth of displayed file to 6."
  (interactive)
  (filetree-set-max-depth 6))

(defun filetree-set-max-depth-7 ()
  "Set depth of displayed file to 7."
  (interactive)
  (filetree-set-max-depth 7))

(defun filetree-set-max-depth-8 ()
  "Set depth of displayed file to 8."
  (interactive)
  (filetree-set-max-depth 8))

(defun filetree-set-max-depth-9 ()
  "Set depth of displayed file to 9."
  (interactive)
  (filetree-set-max-depth 9))

(defun filetree-next-line ()
  "Go to file/dir on next line."
  (interactive)
  (move-end-of-line 2)
  (re-search-backward " ")
  (filetree-goto-node))

(defun filetree-prev-line ()
  "Go to file/dir on previous line."
  (interactive)
  (forward-line -1)
  (filetree-goto-node))

(defun filetree-goto-node ()
  "Move point to item on current line."
  (interactive)
  (if (< (point) filetree-start-position)
      (progn
        (goto-char (point-min))
        (recenter-top-bottom "Top")
        (goto-char filetree-start-position)))
  (move-end-of-line 1)
  (re-search-backward " ")
  (forward-char)
  (if (and (buffer-live-p filetree-info-buffer)
           (window-live-p filetree-info-window))
    (filetree-update-info-buffer (filetree-get-name))))

(defun filetree-next-branch ()
  "Go to next item at the same or higher level in the tree.
In other words go to next branch of tree."
  (interactive)
  (filetree-goto-node)
  (let ((filetree-original-line (line-number-at-pos))
        (filetree-looking t)
        (filetree-current-col (current-column))
        (filetree-current-line (line-number-at-pos)))
    (while filetree-looking
      (filetree-next-line)
      (if (<= (current-column)
              filetree-current-col)
          (setq filetree-looking nil)
        (if (eq (line-number-at-pos) filetree-current-line)
            (progn
              (setq filetree-looking nil)
              (forward-line (- filetree-original-line
                               filetree-current-line))
              (filetree-goto-node))
          (setq filetree-current-line (line-number-at-pos)))))))

(defun filetree-prev-branch ()
  "Go to previous item at the same or higher level in the tree.
In other wrods go to prev branch of tree."
  (interactive)
  (filetree-goto-node)
  (let ((filetree-original-line (line-number-at-pos))
        (filetree-looking t)
        (filetree-current-col (current-column))
        (filetree-current-line (line-number-at-pos)))
    (while filetree-looking
      (filetree-prev-line)
      (if (<= (current-column)
              filetree-current-col)
          (setq filetree-looking nil)
        (if (eq (line-number-at-pos) filetree-current-line)
            (progn
              (setq filetree-looking nil)
              (forward-line (- filetree-original-line
                               filetree-current-line))
              (filetree-goto-node))
          (setq filetree-current-line (line-number-at-pos)))))))

(defun filetree-goto-name (name)
  "Helper function to go to item with name NAME."
  (let ((filetree-looking (stringp name))
        (filetree-end-of-buffer nil)
        (filetree-new-name nil)
        (filetree-prev-point -1))
    (goto-char (point-min))
    (while (and filetree-looking
                (not filetree-end-of-buffer))
      (setq filetree-new-name (filetree-get-name))
      (setq filetree-end-of-buffer
            (>= filetree-prev-point (point)))
      (setq filetree-prev-point (point))
      (if (string-equal filetree-new-name name)
          (setq filetree-looking nil)
        (filetree-next-line)))
    (if filetree-end-of-buffer
        (goto-char (point-min)))
    (filetree-goto-node)))


(defun filetree-add-entry-to-tree (new-entry current-tree)
  "Add file NEW-ENTRY to CURRENT-TREE."
  (interactive)
  (if new-entry
      (let ((tree-head-entries (mapcar (lambda (x) (list (car x)
                                                       (nth 1 x)))
                                     current-tree))
            (new-entry-head (list (car new-entry) (nth 1 new-entry)))
            (matching-entry nil))
        (setq matching-entry (member new-entry-head tree-head-entries))
        (if (/= (length matching-entry) 0)
            (let ((entry-num (- (length current-tree)
                                (length matching-entry))))
              (setcar (nthcdr entry-num current-tree)
                      (list (car new-entry)
                            (nth 1 new-entry)
                            (filetree-add-entry-to-tree (car (nth 2 new-entry))
                                                        (nth 2 (car (nthcdr entry-num current-tree))))
                            (nth 3 new-entry))))
          (setq current-tree (cons new-entry current-tree)))))
  current-tree)

(defun filetree-print-flat (file-list)
  "Print FILE-LIST in flat format."
  (let ((first-file (car file-list))
        (remaining (cdr file-list)))
    (let ((filename (file-name-nondirectory first-file))
          (directory-name (file-name-directory first-file)))
      (insert-text-button  filename
                           'face (filetree-file-face first-file)
                           'action (lambda (x) (find-file (button-get x 'name)))
                           'name first-file)
      (insert (make-string (max 1 (- 30 (length filename))) ?\s))
      (insert-text-button (concat directory-name "\n")
                          'face 'default
                          'action (lambda (x) (find-file (button-get x 'name)))
                          'name first-file))
    (if remaining
        (filetree-print-flat remaining))))

(defun filetree-toggle-flat-vs-tree ()
  "Toggle flat vs tree view."
  (interactive)
  (if filetree-show-flat-list
      (setq filetree-show-flat-list nil)
    (setq filetree-show-flat-list t))
  (filetree-update-buffer t))

(defun filetree-toggle-combine-dir-names ()
  "Toggle combine dir names."
  (interactive)
  (if filetree-combine-dir-names
      (setq filetree-combine-dir-names nil)
    (setq filetree-combine-dir-names t))
  (filetree-update-buffer t))

(defun filetree-toggle-use-all-icons ()
  "Toggle use-all-icons."
  (interactive)
  (setq filetree-use-all-the-icons
        (if (require 'all-the-icons nil 'noerror)
            (not filetree-use-all-the-icons)
          nil))
  (filetree-update-buffer t))
  
(defun filetree-print-tree (dir-tree depth-list)
  "Print directory tree.
Print DIR-TREE up to a depth of DEPTH-LIST.
TODO: Break into smaller functions and clean-up."
  (interactive)
  (let ((my-depth-list depth-list)
        (my-dir-tree dir-tree)
        (my-depth-list-copy nil)
        (cur-depth nil)
        (this-type nil)
        (this-name nil)
        (this-entry nil)
        (draw-marks (> (length filetree-marked-file-list) 0)))
    (if (not my-depth-list)
        (setq my-depth-list (list (- (length my-dir-tree) 1)))
      (setcdr (last my-depth-list)
              (list (- (length my-dir-tree) 1))))
    (setq cur-depth (- (length my-depth-list) 1))
    (if (or (= filetree-max-depth 0)
            (< cur-depth filetree-max-depth))
        (while (/= (length my-dir-tree) 0)
          (setq this-entry (car my-dir-tree))
          (setq this-type (car this-entry))
          (setq this-name (nth 1 this-entry))
          (if (equal this-type "dir")
              (let ((my-prefix (apply #'concat (mapcar (lambda (x) (if (> x 0)
                                                                     ;; continue
                                                                     (concat " " filetree-symb-for-vertical-pipe "  ")
                                                                   "    "))
                                                     (butlast my-depth-list 1))))
                    (dir-contents (nth 2 this-entry))
                    (filetree-dir-string nil)
                    (marks-to-print ""))
                (if (> (length my-depth-list) 1)
                    (if (> (car (last my-depth-list)) 0)
                        ;; branch and continue
                        (setq marks-to-print (concat marks-to-print
                                                     " " filetree-symb-for-branch-and-cont
                                                     filetree-symb-for-horizontal-pipe
                                                     filetree-symb-for-horizontal-pipe " "))
                      ;; last branch
                      (setq marks-to-print (concat marks-to-print
                                                   " " filetree-symb-for-left-elbow
                                                   filetree-symb-for-horizontal-pipe
                                                   filetree-symb-for-horizontal-pipe " ")))
                  ;; Tree root
                  (setq marks-to-print (concat marks-to-print
                                               " " filetree-symb-for-box
                                               filetree-symb-for-box
                                               filetree-symb-for-root " ")))
                (setq filetree-dir-string this-name)
                (if (= (length dir-contents) 1)
                    (setq this-type (car (car dir-contents))))
                ;; combine dirname if no branching
                (if filetree-combine-dir-names
                    (while (and (= (length dir-contents) 1)
                                (equal this-type "dir")
                                (equal (car (car dir-contents)) "dir"))
                      (setq this-entry (car dir-contents))
                      (setq this-type (car this-entry))
                      (setq this-name (nth 1 this-entry))
                      (if (equal this-type "dir")
                          (progn
                            (setq filetree-dir-string (concat filetree-dir-string
                                                              "/"  this-name))
                            (setq dir-contents (nth 2 this-entry))))))
                (insert (filetree-extra-file-info (nth 3 this-entry)))
                (if draw-marks (insert " "))
                (insert my-prefix)
                (insert marks-to-print)
                (if filetree-use-all-the-icons
                    (insert (all-the-icons-icon-for-dir filetree-dir-string) " "))
                (insert-text-button filetree-dir-string
                                    'face 'bold
                                    'action (lambda (x) (filetree-narrow
                                                         (button-get x 'subtree)))
                                    'name (concat (nth 3 this-entry) "/")
                                    'subtree this-entry)
                (insert "/\n")
                (setq my-depth-list-copy (copy-tree my-depth-list))
                (if (> (length dir-contents) 0)
                    (filetree-print-tree dir-contents my-depth-list-copy)))
            ;; file
            (let ((my-link (nth 2 this-entry))
                  (file-text (concat this-name))
                  (my-prefix (apply #'concat (mapcar (lambda (x) (if (= x 0)
                                                                   "    "
                                                                 ;; continue
                                                                 (concat " " filetree-symb-for-vertical-pipe "  ")))
                                                   (butlast my-depth-list 1)))))
              (if (> (car (last my-depth-list)) 0)
                  ;; file and continue
                  (setq my-prefix (concat my-prefix " "
                                          filetree-symb-for-branch-and-cont
                                          filetree-symb-for-horizontal-pipe
                                          filetree-symb-for-file-node " "))
                ;; last file
                (setq my-prefix (concat my-prefix " "
                                        filetree-symb-for-left-elbow
                                        filetree-symb-for-horizontal-pipe
                                        filetree-symb-for-file-node " ")))
              (insert (filetree-extra-file-info my-link))
              (if draw-marks
                  (if (member my-link filetree-marked-file-list)
                      (insert filetree-symb-for-mark)
                    (insert " ")))
              (insert my-prefix)
              (let ((button-face (filetree-file-face file-text)))
                (if filetree-use-all-the-icons
                    (insert (all-the-icons-icon-for-file file-text) " "))
                (insert-text-button file-text
                                    'face button-face
                                    'action (lambda (x) (find-file (button-get x 'name)))
                                    'name my-link))
              (insert "\n")))
      (let ((remaining-entries (nth cur-depth my-depth-list)))
        (setcar (nthcdr cur-depth my-depth-list)
                (- remaining-entries 1)))
      (setq my-dir-tree (cdr my-dir-tree))))))

(defun filetree-extra-file-info (file-or-dir)
  "Helper function that gets extra info for FILE-OR-DIR."
  (let ((extra-info (nth filetree-current-info-cycle filetree-info-cycle-list)))
    (apply #'concat
           (mapcar (lambda (x)
                     (let ((field-size (nth 1 x))
                           (field-justification (nth 3 x))
                           (entry (apply (nth 2 x)
                                         (list file-or-dir))))
                       (if (> (length entry) (- field-size 1))
                           (concat (substring entry 0 (- field-size 2)) "\u21e2 ")
                         (if (string= field-justification "center")
                             (let ((space-length (- field-size
                                                    (length entry))))
                               (concat (make-string (/ space-length 2) ? )
                                       entry
                                       (make-string (- space-length
                                                       (/ space-length 2)) ? )))
                           (if (string= field-justification "right")
                               (concat
                                (make-string (- (- field-size 1)
                                                (length entry)) ? )
                                entry " ")
                             (concat entry
                                     (make-string (- field-size
                                                     (length entry)) ? )))))))
                   extra-info))))

(defun filetree-increment-current-info-cycle ()
  "Cycle to next info view"
  (interactive)
  (setq filetree-current-info-cycle (mod (+ 1 filetree-current-info-cycle)
                                         (length filetree-info-cycle-list)))
  (filetree-update-buffer t))

(defun filetree-decrement-current-info-cycle ()
  "Cycle to previous info view"
  (interactive)
  (setq filetree-current-info-cycle (mod (- filetree-current-info-cycle 1)
                                         (length filetree-info-cycle-list)))
  (filetree-update-buffer t))

(defun filetree-print-header ()
  "Print header at top of window."
  (let ((extra-info (nth filetree-current-info-cycle filetree-info-cycle-list))
        (header-length nil))
    (insert (propertize (apply #'concat
                               (mapcar (lambda (x)
                                         (let ((field-size (nth 1 x))
                                               (entry (car x)))
                                           (if (> (length entry) (- field-size 1))
                                               (concat (substring entry 0 (- field-size 2)) "\u21e2 ")
                                             (let ((space-length (- field-size
                                                                    (length entry))))
                                               (concat (make-string (/ space-length 2) ? )
                                                       entry
                                                       (make-string (- space-length
                                                                       (/ space-length 2)) ? ))))))
                                       extra-info))
                        'font-lock-face 'bold))
    (insert filetree-symb-for-vertical-pipe " "
            (propertize "# files: " 'font-lock-face 'bold)
            (number-to-string (length filetree-current-file-list))
            (propertize "\t\tMax depth: " 'font-lock-face 'bold)
            (if (> filetree-max-depth 0)
                (number-to-string filetree-max-depth)
              "full")
            "\t\t"
            (propertize "Stack size: " 'font-lock-face 'bold)
            (number-to-string (- (length filetree-file-list-stack) 1))
            "\t\t"
            (if (> (length filetree-marked-file-list) 0)
                (concat
                  (propertize "# Marked: " 'font-lock-face 'bold)
                  (number-to-string (length filetree-marked-file-list))
                  " ")
              "")
            " \n")
    (setq header-length (point))
    (insert (make-string (apply '+ (mapcar (lambda (x)
                                             (nth 1 x))
                                           extra-info)) ?\u2500)
            filetree-symb-for-left-elbow)
    (setq header-length (- header-length
                           (- (point) header-length)))
    (insert (make-string header-length ?\u2500))
    (insert filetree-symb-for-right-elbow "\n")
    (setq filetree-start-position (point))))

(defun filetree-create-single-node-tree (filename)
  "Create a tree for FILENAME."
  (let* ((filename-list (reverse (cdr (split-string
                                      filename "/"))))
         (single-node-tree
          (if (equal (car filename-list) "")
              nil
            (list "file" (car filename-list) filename))))
    (setq filename-list (cdr filename-list))
    (while (/= (length filename-list) 0)
      (setq single-node-tree (list "dir"
                                 (car filename-list)
                                 (if (not single-node-tree)
                                     nil
                                   (list single-node-tree))
                                 (concat "/" (mapconcat #'identity (reverse filename-list) "/"))))
      (setq filename-list (cdr filename-list)))
    single-node-tree))
  
(defun filetree-create-file-tree (file-list &optional cur-tree)
  "Create a tree for FILE-LIST and add it to CUR-TREE (or create new tree if not given)."
  (interactive)
  (let ((entry nil))
    (while (/= (length file-list) 0)
      (setq entry (car file-list))
      (setq cur-tree (filetree-add-entry-to-tree (filetree-create-single-node-tree entry)
                                                cur-tree))
      (setq file-list (cdr file-list)))
    cur-tree))

(defun filetree-create-file-list (filetree)
  "Create a list of files from FILETREE."
  (if (listp filetree)
      (progn
        (-flatten (mapcar (lambda (x) (if (eq (car x) "file")
                                          (nth 2 x)
                                        (filetree-create-file-list (nth 2 x))))
                          filetree)))
    filetree))

(defun filetree-update-or-open-info-buffer()
  "Update info buffer based on current buffer.
Open info buffer if not already open."
  (interactive)
  (if (and (buffer-live-p filetree-info-buffer)
           (window-live-p filetree-info-window))
      (filetree-update-info-buffer)
  (filetree-toggle-info-buffer)))

(defun filetree-parent-directory (file-dir)
  "Get parent directory of FILE-DIR.
From https://stackoverflow.com/questions/14095189/walk-up-the-directory-tree/14096693#14096693"
  (unless (equal "/" file-dir)
    (file-name-directory (directory-file-name file-dir))))

(defun filetree-find-notes-file (file-dir)
  "Find local notes file.
Check in the FILE-DIR directory hierarchy, if not found
there then return nil."
  (if (and file-dir (file-remote-p file-dir))
      nil
    (let ((my-dir file-dir)
          (my-file nil)
          (found nil)
          (done nil))
      (while (not done)
        (setq my-file (concat my-dir filetree-relative-notes-filename))
        (setq found (file-exists-p my-file))
        (setq done (or (equal "/" my-dir)
                       (not my-dir)
                       found))
        (if my-dir
            (setq my-dir (filetree-parent-directory my-dir))))
      (if (not found)
          ;; filetree-notes-file
          nil
        my-file))))

(defun filetree-toggle-info-buffer (&optional switch-to-info-flag)
  "Toggle info buffer in side window.
If SWITCH-TO-INFO-FLAG is true, then switch to the info window afterwards."
  (interactive)
  (let ((file-for-info-buffer (if (string-equal (buffer-name) filetree-buffer-name)
                                  (filetree-get-name)
                                nil)))
    (if (and (buffer-live-p filetree-info-buffer)
             (window-live-p filetree-info-window))
        (progn
          (switch-to-buffer filetree-info-buffer)
          (save-buffer)
          (kill-buffer filetree-info-buffer)
          (setq filetree-info-buffer-state nil))
      (setq filetree-info-buffer (find-file-noselect (or
                                                      (filetree-find-notes-file
                                                          file-for-info-buffer)
                                                         filetree-notes-file)))
      (setq filetree-info-buffer-state t)
      (setq filetree-info-window
            (display-buffer-in-side-window filetree-info-buffer
                                           '((side . right))))
      (if file-for-info-buffer
          (filetree-update-info-buffer file-for-info-buffer)
        (filetree-update-info-buffer))
      (if switch-to-info-flag
          (select-window filetree-info-window)))))

(defun filetree-update-info-buffer (&optional current-file-name)
  "Update info buffer contents to reflect CURRENT-FILE-NAME.
If CURENT-FILE-NAME not given use 'buffer-file-name'.
If no entry in info buffer for this file, create new info buffer entry."
  ;; TODO: clean up
  (let ((filetree-create-new-entry (if current-file-name nil t))
        (filetree-info-buffer-new nil))
    (unless current-file-name (setq current-file-name (buffer-file-name)))
    (unless current-file-name (setq current-file-name "No File Note Entry"))
    (let ((current-window (selected-window))
          (local-notes-file nil))
      (select-window filetree-info-window)
      (switch-to-buffer filetree-info-buffer)
      ;;(save-buffer)
      (setq local-notes-file (filetree-find-notes-file current-file-name))
      (if local-notes-file
          (progn
            (setq filetree-info-buffer-new (find-file-noselect local-notes-file))
            (setq current-file-name (concat "./"
                                            (file-relative-name current-file-name
                                                                (file-name-directory
                                                                 local-notes-file)))))
        (setq filetree-info-buffer-new (find-file-noselect filetree-notes-file)))
      (if (and (not (equal filetree-info-buffer-new filetree-info-buffer))
               (buffer-live-p filetree-info-buffer))
          (progn
            (save-buffer)
            (kill-buffer filetree-info-buffer)
            (setq filetree-info-buffer filetree-info-buffer-new)
            (setq filetree-info-window
                  (display-buffer-in-side-window filetree-info-buffer
                                                 '((side . right))))))
      (select-window filetree-info-window)
      (switch-to-buffer filetree-info-buffer)
      (if (get-buffer-window filetree-info-buffer)
          (let ((search-string (concat "* [[" current-file-name "]")))
            (widen)
            (goto-char (point-min))
            (unless (search-forward search-string nil t)
              (if filetree-create-new-entry
                  (progn
                    (message "creating new entry")
                    (goto-char (point-max))
                    (let ((filename (car (last (split-string current-file-name "/") 1))))
                      (insert "\n" "* [[" current-file-name "][" filename "]]\n")))
                (unless (search-forward "* [[No File Note Entry]" nil t)
                  (progn
                    (message "creating No File Note Entry")
                    (goto-char (point-max))
                    (filetree-insert-no-note-entry)))))
            (org-narrow-to-subtree)))
      (select-window current-window))))

(defun filetree-insert-no-note-entry ()
  "Insert an entry in info file indicating not file note entry.
This is used when first starting an info note file."
  (insert "\n* [[No File Note Entry]]\n"
          (propertize (concat "\u250c"
                              (make-string 9 ?\u2500)
                              "\u2510\n\u2502 NO NOTE \u2502\n\u2514"
                              (make-string 9 ?\u2500)
                              "\u2518\n")
                      'font-lock-face '(:foreground "red"))))

(defun filetree-remove-nonexistent-files ()
  "Remove non-existent files from `filetree-current-file-list'.
If `filetree-show-remote-file-info' is nil, then don't check file existence
for remote files."
  (setq filetree-current-file-list
        (delete nil (mapcar (lambda (x)
                              (if (or (and (not filetree-show-remote-file-info)
                                           (file-remote-p x))
                                      (file-exists-p x))
                                  x nil))
                            filetree-current-file-list
                            ))))
  
(defun filetree-update-buffer (&optional skip-update-stack)
  "Update the display buffer (following some change).
This function should be called after any change to 'filetree-current-file-list'.
If SKIP-UPDATE-STACK is t, `filetree-file-list-stack' is not updated."
  (interactive)
  (if filetree-enable-nonexistent-file-removal
      (filetree-remove-nonexistent-files))
  (let ((text-scale-previous (buffer-local-value 'text-scale-mode-amount
                                                 (current-buffer))))
    (save-current-buffer
      (with-current-buffer (get-buffer-create filetree-buffer-name)
        (let ((filetree-current-name (filetree-get-name)))
          (setq buffer-read-only nil)
          (erase-buffer)
          (setq filetree-current-file-list (-distinct (-non-nil
                                                       filetree-current-file-list)))
          (if (not skip-update-stack)
              (setq filetree-file-list-stack (cons (copy-sequence filetree-current-file-list)
                                                   filetree-file-list-stack)))
          (filetree-print-header)
          (if filetree-show-flat-list
              (filetree-print-flat filetree-current-file-list)
            (filetree-print-tree (filetree-create-file-tree
                                  (reverse filetree-current-file-list)) ()))
          (setq filetree-overall-depth
                (if (null filetree-current-file-list) 0
                  (apply #'max (mapcar (lambda (x) (length (split-string x "/")))
                                      filetree-current-file-list))))
          ;; (filetree-update-info-buffer filetree-buffer-name)
          (switch-to-buffer filetree-buffer-name)
          (filetree-goto-name filetree-current-name)
          (setq buffer-read-only t)
          (filetree)
          (text-scale-increase text-scale-previous))))))

(defun filetree-pop-file-list-stack ()
  "Pop last state from file list stack."
  (interactive)
  (if (> (length filetree-file-list-stack) 1)
      (setq filetree-file-list-stack (cdr filetree-file-list-stack)))

  (setq filetree-current-file-list (car filetree-file-list-stack))
  (if (> (length filetree-file-list-stack) 1)
      (setq filetree-file-list-stack (cdr filetree-file-list-stack)))
  (filetree-update-buffer))

(defun filetree-diff-with-file-list-stack ()
  "Filter the previous file-list on the stack to remove all files in the current file-list."
  (interactive)
  (if (> (length filetree-file-list-stack) 2)
      (progn
        (setq filetree-current-file-list (-difference (car (cdr filetree-file-list-stack))
                                                      filetree-current-file-list))
        (filetree-update-buffer))))

(defun filetree-union-with-file-list-stack ()
  "Add the previous file-list on the stack to the current file-list."
  (interactive)
  (if (> (length filetree-file-list-stack) 2)
      (progn
        (setq filetree-current-file-list (-union (car (cdr filetree-file-list-stack))
                                                 filetree-current-file-list))
        (filetree-update-buffer))))

(defun filetree-narrow (subtree)
  "Narrow file tree to SUBTREE."
  (setq filetree-current-file-list (filetree-create-file-list (list subtree)))
  (filetree-update-buffer))

(defun filetree-file-face (filename)
  "Return face to use for FILENAME.
Info determined from 'filetree-filetype-list' and 'filetree-default-file-face'."
  (let ((file-face filetree-default-file-face)
        (my-file-face-list (mapcar (lambda (x) (cdr (cdr x)))
                                   filetree-filetype-list))
        (elem nil)
        (filetree-regex nil))
    (while (/= (length my-file-face-list) 0)
      (setq elem (car my-file-face-list))
      (setq filetree-regex (car elem))
      (if (> (length filetree-regex) 0)
          (if (string-match filetree-regex filename)
              (setq file-face (car (cdr elem)))))
      (setq my-file-face-list (cdr my-file-face-list)))
    file-face))

(defun filetree-grep-marked-files ()
  "Run grep on files in `filetree-marked-file-list'.
Takes input from user for grep pattern. If `filetree-marked-file-list'
is empty use `filetree-current-file-list'"
  (interactive)
  (if (version< emacs-version "27.1")
      (message "filetree-grep-marked-files not supported for emacs versions before 27.1")
    (let* ((my-filetree-regex (read-string "Type search string: "))
           (xrefs nil)
           (file-list (if (> (length filetree-marked-file-list) 0)
                          filetree-marked-file-list
                        filetree-current-file-list))
           (fetcher
            (lambda ()
              (setq xrefs (xref-matches-in-files my-filetree-regex
                                                 (-filter 'file-exists-p file-list)))
              (unless xrefs
                (user-error "No matches for: %s" my-filetree-regex))
              xrefs)))
      (xref--show-xrefs fetcher nil))))

(defun filetree-helm-filter ()
  "Use helm-based filtering on filetree."
  (interactive)
  (setq filetree-file-list-stack-save (copy-sequence filetree-file-list-stack))
  (let ((current-node (filetree-get-name)))
    (add-hook 'helm-after-update-hook
              #'filetree-helm-hook)
    (helm :sources '(filetree-helm-source))
    (filetree-goto-name current-node)))

(defun filetree-helm-hook ()
  "Helm hook for filetree."
  (interactive)
  (setq filetree-current-file-list (car (helm--collect-matches
                                       (list (helm-get-current-source)))))
  (filetree-update-buffer t))

(defun filetree-select-file-list ()
  "Select file list from saved file lists."
  (interactive)
  (let ((file-list (helm :sources (helm-build-sync-source "File Lists"
                                   :candidates (mapcar (lambda (x)
                                                         (car x))
                                                       filetree-saved-lists)
                                   :action (lambda (candidate)
                                             (let ((file-list
                                                    (car (cdr (assoc candidate
                                                                     filetree-saved-lists)))))
                                               (if (functionp file-list)
                                                   (setq file-list (funcall file-list)))
                                               file-list))
                                                                   
                                   :fuzzy-match t)
                        :buffer "*filetree-helm-buffer*")))
    (if file-list
        (setq filetree-current-file-list file-list))
    (filetree-update-buffer)))

(defun filetree-update-saved-lists-file ()
  "Save current `filetree-saved-lists' to file."
  (save-current-buffer
    (with-current-buffer (get-buffer-create "*filetree-temp*")
      (erase-buffer)
      (insert "(setq filetree-saved-lists '")
      (insert (format "%S" filetree-saved-lists))
      (insert ")")
      (write-file filetree-saved-lists-file))))
  
(defun filetree-save-list ()
  "Save current file list."
  (interactive)
  (let ((list-name (helm :sources (helm-build-sync-source "File Lists"
                                    :candidates (cons "*New Entry*"
                                                      (mapcar (lambda (x)
                                                                (car x))
                                                              filetree-saved-lists))
                                   :fuzzy-match t)
                         :buffer "*filetree-helm-buffer*")))
    (if (string= list-name "*New Entry*")
        (setq list-name (read-string "Enter new list name: ")))
    ;; first delete previous list-name entry (if any)
    (setq filetree-saved-lists (delete nil (mapcar (lambda (x)
                                                     (if (string-match
                                                          list-name
                                                          (car x))
                                                         nil x))
                                                   filetree-saved-lists)))
    ;; add new entry
    (setq filetree-saved-lists (cons (cons list-name (list filetree-current-file-list))
                                     filetree-saved-lists))
    (filetree-update-saved-lists-file)))
      
(defun filetree-delete-list()
  "Delete a file list from the `filetree-saved-list' and save to file."
  (interactive)
  (let ((list-name (helm :sources (helm-build-sync-source "File Lists"
                                    :candidates (mapcar (lambda (x)
                                                          (car x))
                                                        filetree-saved-lists)
                                   :fuzzy-match t)
                         :buffer "*filetree-helm-buffer*")))
    (setq filetree-saved-lists (delete nil (mapcar (lambda (x)
                                                     (if (string-match
                                                          list-name
                                                          (car x))
                                                         nil x))
                                                   filetree-saved-lists)))
    (filetree-update-saved-lists-file)))
    
(defun filetree-show-files (file-list)
  "Load FILE-LIST into current file list and show in tree mode."
  (setq filetree-current-file-list file-list)
  (setq filetree-file-list-stack (list filetree-current-file-list))
  (filetree-update-buffer))

(defun filetree-show-recentf-files ()
  "Load recentf list into current file list and show in tree mode."
  (interactive)
  (if (not recentf-mode)
      (recentf-mode))
  (filetree-show-files recentf-list))

(defun filetree-show-cur-dir ()
  "Load files in current directory into current file list and show in tree mode."
  (interactive)
  (setq filetree-current-file-list nil)
  (setq filetree-file-list-stack (list filetree-current-file-list))
  (filetree-expand-dir (file-name-directory (buffer-file-name)) 0))

(defun filetree-show-cur-dir-recursively ()
  "Load files in current directory (recursively) into current file list and show in tree mode."
  (interactive)
  (setq filetree-current-file-list nil)
  (setq filetree-file-list-stack (list filetree-current-file-list))
  (filetree-expand-dir-recursively (file-name-directory (buffer-file-name)) 0))

(defun filetree-show-cur-buffers ()
  "Load file buffers in buffer list into current file list and show in tree mode."
  (interactive)
  (let ((my-buffer-list (buffer-list))
        (my-buffer nil)
        (my-file-list ()))
    (while my-buffer-list
      (setq my-buffer (car my-buffer-list))
      (setq my-buffer-list (cdr my-buffer-list))
      (if (buffer-file-name my-buffer)
          (setq my-file-list (cons (buffer-file-name my-buffer)
                                 my-file-list))))
    (setq filetree-current-file-list my-file-list)
    (filetree-update-buffer)))

(defun filetree-find-files-with-notes ()
  "Return list of files with notes."
  (find-file filetree-notes-file)
  (goto-char (point-min))
  (widen)
  (let ((regexp "^\\* \\[\\[\\(.*\\)\\]\\[")
        (filelist nil)
        (my-match nil))
    (while (re-search-forward regexp nil t)
      (setq my-match (match-string-no-properties 1))
      (setq filelist (cons my-match filelist)))
    filelist))
  
(defun filetree-show-files-with-notes ()
  "Load files with entries in notes file."
  (interactive)
  (filetree-show-files (filetree-find-files-with-notes)))

(define-derived-mode filetree nil "Text"
  "A mode to view and perform operations on files via a tree view"
  (make-local-variable 'filetree-list))

(provide 'filetree)
;;; filetree.el ends here
