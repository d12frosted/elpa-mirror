;;; trashed.el --- Viewing/editing system trash can -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Shingo Tanaka

;; Author: Shingo Tanaka <shingo.fg8@gmail.com>
;; Version: 2.1.2
;; Package-Version: 20200523.231
;; Package-Commit: 23e782f78d9adf6b5479a01bfac90b2cfbf729fe
;; Package-Requires: ((emacs "25.1"))
;; Keywords: files, convenience, unix
;; URL: https://github.com/shingo256/trashed

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

;; Viewing/editing system trash can -- open, view, restore or
;; permanently delete trashed files or directories in trash can with
;; Dired-like look and feel.  See below for details.
;; <https://github.com/shingo256/trashed>

;;; Code:

(require 'dired)
(require 'parse-time)

;;; Customization variables

(defgroup trashed nil
  "System trash can editing."
  :link '(custom-manual "(emacs)Trashed")
  :group 'files)

(defcustom trashed-use-header-line t
  "Non-nil means Emacs window's header line is used to show the column names.
Otherwise, text based header line is used."
  :group 'trashed
  :type 'boolean)

(defcustom trashed-sort-key (cons "Date deleted" t)
  "Default sort key.
If nil, no additional sorting is performed.
Otherwise, this should be a cons cell (COLUMN . FLIP).
COLUMN is a string matching one of the column names.
FLIP, if non-nil, means to invert the resulting sort."
  :group 'trashed
  :type '(choice (const :tag "No sorting" nil)
                 (cons (string) (boolean))))

(defcustom trashed-size-format 'human-readable
  "Trash file size format displayed in the list.
`plain' means a plain number, `human-readable' means a human readable number
formatted with `file-size-human-readable', `with-comma' means a number
with comma every 3 digits."
  :group 'trashed
  :type '(choice (const plain)
                 (const human-readable)
                 (const with-comma)))

(defcustom trashed-date-format "%Y-%m-%d %T"
  "Deletion date format displayed in the list.
Formatting is done with `format-time-string'.  See the function for details."
  :group 'trashed
  :type 'string)

(defcustom trashed-action-confirmer 'yes-or-no-p
  "Confirmer function to ask if user really wants to execute requested action.
`yes-or-no-p' or `y-or-n-p'."
  :group 'trashed
  :type '(choice (const :tag "yes or no" yes-or-no-p)
                 (const :tag "y or n" y-or-n-p)))

(defcustom trashed-load-hook nil
  "Run after loading Trashed."
  :group 'trashed
  :type 'hook)

;; It's defined in define-derived-mode, but make it customizable here
(defcustom trashed-mode-hook nil
  "Run at the very end of `trashed-mode'."
  :group 'trashed
  :type 'hook)

(defcustom trashed-before-readin-hook nil
  "Run before Trash Can buffer is read in (created or reverted)."
  :group 'trashed
  :type 'hook)

(defcustom trashed-after-readin-hook nil
  "Run after Trash Can buffer is read in (created or reverted)."
  :group 'trashed
  :type 'hook)

;;; Faces

(defgroup trashed-faces nil
  "Faces used by Trashed mode."
  :group 'trashed
  :group 'faces)

(defface trashed-mark
  '((t (:inherit dired-mark)))
  "Face used for trash marks."
  :group 'trashed-faces)
(defvar trashed-mark-face 'trashed-mark
  "Face name used for trash marks.")

(defface trashed-restored
  '((t (:inherit success)))
  "Face used for files flagged for restoration."
  :group 'trashed-faces)
(defvar trashed-restored-face 'trashed-restored
  "Face name used for files flagged for restoration.")

(defface trashed-deleted
  '((t (:inherit dired-flagged)))
  "Face used for files flagged for deletion."
  :group 'trashed-faces)
(defvar trashed-deleted-face 'trashed-deleted
  "Face name used for files flagged for deletion.")

(defface trashed-marked
  '((t (:inherit dired-marked)))
  "Face used for marked files."
  :group 'trashed-faces)
(defvar trashed-marked-face 'trashed-marked
  "Face name used for marked files.")

(defface trashed-directory
  '((t (:inherit dired-directory)))
  "Face used for directories."
  :group 'trashed-faces)
(defvar trashed-directory-face 'trashed-directory
  "Face name used for directories.")

(defface trashed-symlink
  '((t (:inherit dired-symlink)))
  "Face used for directories."
  :group 'trashed-faces)
(defvar trashed-symlink-face 'trashed-symlink
  "Face name used for directories.")

;;; Local variables

(defvar trashed-trash-dir
  (if (eq system-type 'windows-nt)
      (concat "c:/$Recycle.Bin/"
              (with-temp-buffer ;; sid
                (call-process "c:/Windows/System32/whoami" nil t nil
                              "/user" "/fo" "csv" "/nh")
                (re-search-backward "\"[^\"]+\",\"\\([^\"]+\\)\"")
                (buffer-substring (match-beginning 1) (match-end 1))))
    (directory-file-name (expand-file-name "Trash"
                                           (or (getenv "XDG_DATA_HOME")
                                               "~/.local/share"))))
  "Trash directory path.")

(defvar trashed-files-dir (and (not (eq system-type 'windows-nt))
                               (expand-file-name "files" trashed-trash-dir))
  "Trash files directory path.")

(defvar trashed-info-dir (and (not (eq system-type 'windows-nt))
                              (expand-file-name "info" trashed-trash-dir))
  "Trash info directory path.")

(defvar trashed-buffer nil
  "Trash Can buffer.")

(defvar trashed-buffer-name "Trash Can"
  "Buffer name string of Trash Can buffer.")

(defvar trashed-trash-can-size 0
  "Total size of Trash Can.")

(defvar trashed-mode-map
  (let ((map (make-keymap)))
    (set-keymap-parent map tabulated-list-mode-map)
    (define-key map " " 'trashed-next-line)
    (define-key map "n" 'trashed-next-line)
    (define-key map "\C-n" 'trashed-next-line)
    (define-key map [down] 'trashed-next-line)
    (define-key map [backspace] 'trashed-previous-line)
    (define-key map "p" 'trashed-previous-line)
    (define-key map "\C-p" 'trashed-previous-line)
    (define-key map [up] 'trashed-previous-line)
    (define-key map [tab] 'trashed-forward-column)
    (define-key map [backtab] 'trashed-backward-column)
    (define-key map "f" 'trashed-find-file)
    (define-key map "\C-m" 'trashed-find-file)
    (define-key map "o" 'trashed-find-file-other-window)
    (define-key map [mouse-2] 'trashed-mouse-find-file-other-window)
    (define-key map "\C-o" 'trashed-display-file)
    (define-key map "v" 'trashed-view-file)
    (define-key map "e" 'trashed-browse-url-of-file)
    (define-key map "W" 'trashed-browse-url-of-file)
    (define-key map [double-mouse-1] 'trashed-mouse-browse-url-of-file)
    (define-key map "r" 'trashed-flag-restore)
    (define-key map "d" 'trashed-flag-delete)
    (define-key map "~" 'trashed-flag-backup-files)
    (define-key map "#" 'trashed-flag-auto-save-files)
    (define-key map "m" 'trashed-mark)
    (define-key map "u" 'trashed-unmark)
    (define-key map "%r" 'trashed-flag-restore-files-regexp)
    (define-key map "%d" 'trashed-flag-delete-files-regexp)
    (define-key map "%m" 'trashed-mark-files-regexp)
    (define-key map "%u" 'trashed-unmark-files-regexp)
    (define-key map "$r" 'trashed-flag-restore-files-by-date)
    (define-key map "$d" 'trashed-flag-delete-files-by-date)
    (define-key map "$m" 'trashed-mark-files-by-date)
    (define-key map "$u" 'trashed-unmark-files-by-date)
    (define-key map "R" 'trashed-do-restore)
    (define-key map "D" 'trashed-do-delete)
    (define-key map "M" 'trashed-mark-all)
    (define-key map "U" 'trashed-unmark-all)
    (define-key map "t" 'trashed-toggle-marks)
    (define-key map "x" 'trashed-do-execute)
    (define-key map [mouse-3] 'trashed-mouse-popup-menu)
    map)
  "Local keymap for Trashed mode listings.")

(easy-menu-define trashed-menu trashed-mode-map
  "Menu map for Trashed mode listings."
  '("Trashed"
    ["Restore" trashed-do-restore
     :help "Restore this file or all marked files"]
    ["Delete" trashed-do-delete
     :help "Delete this file or all marked files"]
    "--"
    ["Find" trashed-find-file
     :help "Find this file"]
    ["Find in Other Window" trashed-find-file-other-window
     :help "find this file in other window"]
    ["Display in Other Window" trashed-display-file
     :help "Display this file in other window"]
    ["View" trashed-view-file
     :help "Examine this file in read-only mode"]
    ["Browse" trashed-browse-url-of-file
     :help "Ask a browser to display this file"]
    "--"
    ["Mark" trashed-mark
     :help "Mark this file for future operations"]
    ["Flag Restore" trashed-flag-restore
     :help "Flag this file for restoration"]
    ["Flag Delete" trashed-flag-delete
     :help "Flag this file for deletion"]
    ["Execute Flag" trashed-do-execute
     :help "Execute all flagged files"]
    ["Unmark" trashed-unmark
     :help "Unmark or unflag this file"]
     "--"
    ["Mark All" trashed-mark-all
     :help "Mark all files for future operations"]
    ["Unmark All" trashed-unmark-all
     :help "Unmark or unflag all files"]
    ["Toggle Marks" trashed-toggle-marks
     :help "Mark unmarked files, unmark marked ones"]
    ["Flag Backup Files" trashed-flag-backup-files
     :help "Flag all backup files for deletion"]
    ["Flag Auto-Save Files" trashed-flag-auto-save-files
     :help "Flag auto-save files for deletion"]
    "--"
    ("Advanced Marking"
     "--"
     ["Mark Regexp" trashed-mark-files-regexp
      :help "Mark all files matching regular expression for future operations"]
     ["Flag Restore Regexp" trashed-flag-restore-files-regexp
      :help "Flag all files matching regular expression for restoration"]
     ["Flag Delete Regexp" trashed-flag-delete-files-regexp
      :help "Flag all files matching regular expression for deletion"]
     ["Unmark Regexp" trashed-unmark-files-regexp
      :help "Unmark all files matching regular expression"]
     "--"
     ["Mark By Date" trashed-mark-files-by-date
      :help "Mark all files matching date condition for future operations"]
     ["Flag Restore By Date" trashed-flag-restore-files-by-date
      :help "Flag all files matching date condition for restoration"]
     ["Flag Delete By Date" trashed-flag-delete-files-by-date
      :help "Flag all files matching date condition for deletion"]
     ["Unmark By Date" trashed-unmark-files-by-date
      :help "Unmark all files matching date condition"])
    "--"
    ["Refresh" revert-buffer
     :help "Refresh Trash Can"]
    ["Quit" quit-window
     :help "Quit Trash Can"]))

(defvar trashed-res-char ?R
  "Character used to flag files for restoration.")

(defvar trashed-del-char ?D
  "Character used to flag files for deletion.")

(defvar trashed-marker-char ?*
  "Character used to mark files for restoration/deletion.")

(defvar trashed-regexp-history nil
  "History list of regular expressions.")

(defvar trashed-default-vpos 0
  "Line number of the 1st file entry in Trash Can buffer.
This is automatically set in `trashed-readin'.")

(defvar trashed-column-hpos [0]
  "Vector of all columns' horizontal positions.
This is automatically set in `trashed-readin'.")

(defvar trashed-default-col 3
  "Default column id to set default hpos.")

(defvar trashed-current-col trashed-default-col
  "Current column id for column forward/backward movement.")

(defvar trashed-font-lock-keywords
  `((,(string ?^ trashed-res-char ?\\ ?| ?^ trashed-del-char ?\\ ?|
              ?^ trashed-marker-char)
     . trashed-mark-face)
    (,(concat "^" (char-to-string trashed-res-char))
     (".+" (trashed-reset-hpos) nil (0 trashed-restored-face)))
    (,(concat "^" (char-to-string trashed-del-char))
     (".+" (trashed-reset-hpos) nil (0 trashed-deleted-face)))
    (,(concat "^" (char-to-string trashed-marker-char))
     (".+" (trashed-reset-hpos) nil (0 trashed-marked-face)))
    ("^. d" ".+" (trashed-reset-hpos) nil (0 trashed-directory-face))
    ("^. l" ".+" (trashed-reset-hpos) nil (0 trashed-symlink-face)))
  "Font lock keywords for Trashed mode.")

;;; Internal functions

(defun trashed-format-size-string (sizestr)
  "Format file string SIZESTR based on `trashed-size-format'."
  (pcase trashed-size-format
    ('plain sizestr)
    ('human-readable (file-size-human-readable (string-to-number sizestr)))
    ('with-comma (let ((size (string-to-number sizestr)) ret)
                   (while (> size 0)
                     (setq ret (concat (format (if (< size 1000) "%d" "%03d")
                                               (% size 1000))
                                       (if ret "," "") ret)
                           size (/ size 1000)))
                   (or ret "0")))
    (_ sizestr)))

(defun trashed-format-date-string (datestr)
  "Format date string DATESTR based on `trashed-date-format'."
  (string-match "\\([0-9]+\\) \\([0-9]+\\)" datestr)
  (format-time-string trashed-date-format
                      (list (string-to-number (match-string 1 datestr))
                            (string-to-number (match-string 2 datestr)))))

 ;; Just to silence byte-compiler for below `tabulated-list--near-rows'
(defvar tabulated-list--near-rows)

(defun trashed-list-print-entry (id cols)
  "Redefined `tabulated-list-print-entry' to format trash file size and date.
See the original function for ID and COLS."
  (let ((fcols (vector (aref cols 0)
                       (trashed-format-size-string (aref cols 1))
                       (trashed-format-date-string (aref cols 2))
                       (aref cols 3)))
        (beg   (point))
	(x     (max tabulated-list-padding 0))
	(ncols (length tabulated-list-format))
	(inhibit-read-only t))
    (if (> tabulated-list-padding 0)
	(insert (make-string x ?\s)))
    (let ((tabulated-list--near-rows ; Bind it if not bound yet (Bug#25506).
           (or (bound-and-true-p tabulated-list--near-rows)
               (list (or (tabulated-list-get-entry (point-at-bol 0))
                         fcols)
                     fcols))))
      (dotimes (n ncols)
        (setq x (tabulated-list-print-col n (aref fcols n) x))))
    (insert ?\n)
    ;; Use cols rather than fcols
    (add-text-properties
     beg (point)
     `(tabulated-list-id ,id tabulated-list-entry ,cols))))

(defun trashed-size-sorter (f1 f2)
  "Sorting function for size sorting.
See PREDICATE description of `sort' for F1 and F2."
  (> (string-to-number (aref (cadr f1) 1))
     (string-to-number (aref (cadr f2) 1))))

(defun trashed-update-col-width (col width)
  "Update column COL's width with WIDTH.
If WIDTH is nil, set width to its header name width.
If WIDTH is a number and greater than current width,
set current width to WIDTH."
  (let ((current-width (cdr (aref tabulated-list-format col))))
    (if (not width)
        (let ((column-name (car (aref tabulated-list-format col))))
          ;; 3 = 1 blank + sorting arrow width which could be 2
          (setcar current-width (+ (string-width column-name) 3)))
      (if (> width (car current-width))
          (setcar current-width width)))))

(defun trashed-buffer-get-integer (start length)
  "Return an unsigned integer embedded in current buffer from START for LENGTH.
Assumes byte order is little-endian."
  (let ((idx (+ start length))
        (int 0))
    (while (> idx start)
      (setq int (logior (lsh int 8) (char-after idx))
            idx (1- idx)))
    int))

(defun trashed-read-trashinfo (trashinfo-file)
  "Return a list of original file information from TRASHINFO-FILE.
The information is original file's size, deletion date and path.
Currently, MS Windows Vista/7/8/8.1/10 Recycle Bin and freedesktop trash can
are supported."
  (ignore-errors
    (with-temp-buffer
      (set-buffer-multibyte nil)
      (insert-file-contents-literally trashinfo-file)
      (let (sizenum datenum pathstr)
        (if (eq system-type 'windows-nt) ;; Windows Recycle Bin
            (let ((header (trashed-buffer-get-integer 0 8))
                  (datewin (trashed-buffer-get-integer 16 8))
                  pathpos pathlen)
              (pcase header
                (1 ;; Windows Vista/7/8/8.1
                 (setq pathpos 24
                       pathlen (let ((i pathpos) found) ;; search NUL char
                                 (while (and (< i (point-max)) (not found))
                                   (setq found (and
                                                (= (char-after i) 0)
                                                (= (char-after (1+ i)) 0))
                                         i (+ i 2)))
                                 (/ (- i pathpos 2) 2))))
                (2 ;; Windows 10
                 (setq pathpos 28
                       pathlen (1- (trashed-buffer-get-integer 24 4)))))
              (setq sizenum (trashed-buffer-get-integer 8 8)
                    ;; Win to Unix time format conversion
                    ;;  (100nsecs from 1/1/1601 to secs from 1/1/1970)
                    datenum (floor (/ (- datewin 116444736000000000)
                                      10000000))
                    ;; Conversion to (HIGH . LOW) format
                    datenum (list (lsh datenum -16)
                                  (logand datenum (1- (lsh 1 16))))
                    pathstr (replace-regexp-in-string
                             "\\\\" "/" (decode-coding-string
                                         (buffer-substring (+ 1 pathpos)
                                                           (+ 1 pathpos
                                                              (* pathlen 2)))
                                         'utf-16-le))))
          ;; freedesktop trash can
          (setq pathstr (decode-coding-string
                         (url-unhex-string
                          (when (re-search-forward
                                 (rx bol "Path" (0+ blank) "="
                                     (0+ blank) (group (1+ nonl)))
                                 nil t)
                            (match-string 1)))
                         'utf-8)
                datenum (progn
                          (goto-char (point-min))
                          (when (re-search-forward
                                 (rx bol "DeletionDate" (0+ blank) "="
                                     (0+ blank) (group (1+ nonl)))
                                 nil t)
                            (parse-iso8601-time-string (match-string 1))))))
        (list sizenum datenum pathstr)))))

(defun trashed-info-file (trash-file)
  "Return corresponding trash info filename to TRASH-FILE."
  (if (eq system-type 'windows-nt)
      (replace-regexp-in-string "/\\$R\\([^/]+\\)$" "/$I\\1" trash-file)
    (expand-file-name (concat trash-file ".trashinfo") trashed-info-dir)))

(defun trashed-file-info (file attrs)
  "Return a list of a trash file's id and descs for `tabulated-list-entries'.
FILE and ATTRS are file and attributes of the trash file."
  (if (if (eq system-type 'windows-nt)
          (string-match "[^:]/\\$R[^/]+$" file)
        (not (or (string= file ".") (string= file ".."))))
      (let ((info-file (trashed-info-file file)))
        (if (or (and (not (file-directory-p info-file))
                     (file-readable-p info-file))
                ;; Workaround for info files generated by Emacs bug #37922
                (and (not (eq system-type 'windows-nt))
                     (setq info-file (expand-file-name file trashed-info-dir))
                     (not (file-directory-p info-file))
                     (file-readable-p info-file)))
            (let* ((trashinfo (trashed-read-trashinfo info-file))
                   (sizenum (nth 0 trashinfo))
                   (datenum (nth 1 trashinfo))
                   (pathstr (nth 2 trashinfo)))
              (if (and datenum pathstr)
                  (let ((type (substring (nth 8 attrs) 0 1)) ;; type
                        (size (number-to-string (or sizenum ;; windows-nt
                                                    (nth 7 attrs)))) ;; size
                        (date (format "%07d %05d"
                                      (car datenum) (cadr datenum)))
                        (name (propertize pathstr 'mouse-face 'highlight)))
                    ;; Add up trash can size
                    (setq trashed-trash-can-size (+ trashed-trash-can-size
                                                    (string-to-number size)))
                    ;; Lengthen column width if needed
                    (trashed-update-col-width
                     1 (string-width (trashed-format-size-string size)))
                    (trashed-update-col-width
                     2 (string-width (trashed-format-date-string date)))
                    (trashed-update-col-width
                     3 (string-width name))
                    ;; File info
                    (list file (vector type size date name)))
                (message "Skipped %s: cannot recognize info file format." file)
                nil))
          (message "Skipped %s: cannot find or read info file." file)
          nil))))

(defun trashed-read-files ()
  "Read trash information from trash files and info directories.
The information is stored in `tabulated-list-entries', where ID is trash file
name in files directory, and DESC is a vector of file type(-/D), size,
deletion date and original filename."
  ;; Initialization
  (setq trashed-trash-can-size 0)
  (trashed-update-col-width 1 nil)
  (trashed-update-col-width 2 nil)
  (trashed-update-col-width 3 nil)
  ;; Read files
  (let* (files)
    (if (eq system-type 'windows-nt)
        ;; Read trash cans in all drives
        (let ((drive-letter ?a))
          (while (<= drive-letter ?z)
            (aset trashed-trash-dir 0 drive-letter)
            (setq files (append files
                                ;; Make each trash filename full path
                                (mapcar (lambda (file-attrs)
                                          (setcar file-attrs
                                                  (expand-file-name
                                                   (car file-attrs)
                                                   trashed-trash-dir))
                                          file-attrs)
                                 (ignore-errors (directory-files-and-attributes
                                                 trashed-trash-dir nil nil t))))
                  drive-letter (1+ drive-letter))))
      (setq files (ignore-errors (directory-files-and-attributes
                                  trashed-files-dir nil nil t))))
    (setq tabulated-list-entries
          (cl-loop for (file . attrs) in files
                   for entry = (trashed-file-info file attrs)
                   when entry collect entry))))

(defun trashed-display-trash-can-size ()
  "Display Trash Can size in buffer name."
  (rename-buffer (format "%s (%sB)"
                         trashed-buffer-name
                         (file-size-human-readable trashed-trash-can-size))))

(defun trashed-get-trash-size-sentinel (process event)
  "Get total Trash Can size and display it in buffer name when du completed.
PROCESS is the process which ran du command started by `trashed-get-trash-size'.
EVENT is ignored."
  (let* ((pbuf (process-buffer process))
         (sizestr (with-current-buffer pbuf
                    (goto-char (point-min))
                    (if (and (string-match "finished" event)
                             (re-search-forward "[^	]+" nil t))
                        (match-string 0)))))
    (kill-buffer pbuf)
    (if (and sizestr (buffer-live-p trashed-buffer))
        (progn
          (setq trashed-trash-can-size (string-to-number sizestr))
          (with-current-buffer trashed-buffer
            (trashed-display-trash-can-size))))))

(defun trashed-get-trash-size ()
  "Issue du shell command to get total Trash Can size."
  (let* ((buffer (generate-new-buffer "*Async Shell Command*"))
         (process (start-process "trash" buffer shell-file-name
                                 shell-command-switch
                                 (concat "du -s -b " trashed-files-dir))))
    (if (processp process)
        (set-process-sentinel process 'trashed-get-trash-size-sentinel)
      (kill-buffer buffer))))

(defun trashed-update-trash-can-size ()
  "Update Trash Can size in buffer name."
  (if (eq system-type 'windows-nt)
      (trashed-display-trash-can-size)
    ;; Get actual size with du shell command because trash directory size
    ;; is not valid
    (trashed-get-trash-size)))

(defun trashed-reset-vpos ()
  "Set vertical cursor position to `trashed-default-vpos'."
  (goto-char (point-min))
  (forward-line (1- trashed-default-vpos)))

(defun trashed-set-hpos (col)
  "Set horizontal cursor position to column COL."
  (beginning-of-line)
  (if (tabulated-list-get-id)
      ;; Can't use (forward-char n) as there could be 2 width char
      (let ((hpos (aref trashed-column-hpos col)) cur-width)
        (while (> hpos 0)
          (setq cur-width (string-width (char-to-string (char-after)))
                hpos (- hpos cur-width))
          (unless (and (< hpos 1) (> cur-width 1)) ;; the last char width is >1
            (forward-char))))))

(defun trashed-reset-hpos (&optional reset-col)
  "Set horizontal cursor position to the default column.
RESET-COL, if t, means reset current column position to the default as well."
  (if reset-col (setq trashed-current-col trashed-default-col))
  (trashed-set-hpos trashed-default-col))

(defun trashed-readin ()
  "Read, sort and insert trash information to current buffer."
  (run-hooks 'trashed-before-readin-hook)
  (message "Reading trash files...")
  (trashed-read-files)
  (trashed-update-trash-can-size)
  (message "Reading trash files...done")
  (run-hooks 'trashed-after-readin-hook)
  (setq tabulated-list-use-header-line trashed-use-header-line
        trashed-default-vpos (if trashed-use-header-line 1 2)
        trashed-column-hpos
        (let ((cur tabulated-list-padding))
          (vconcat (mapcar (lambda (format)
                             (if (plist-get (nthcdr 3 format) :right-align)
                                 (progn (setq cur (+ cur (cadr format) 1))
                                        (- cur 2))
                               (prog1 cur
                                 (setq cur (+ cur (cadr format) 1)))))
                           tabulated-list-format))))
  (tabulated-list-init-header))

(defun trashed-open-file (func)
  "Open this file with function FUNC."
  (let ((trash-file-name (tabulated-list-get-id)))
    (if trash-file-name
        (apply func (list (expand-file-name trash-file-name trashed-files-dir)))
      (error "No file on this line"))))

(defun trashed-tabulated-list-set-id (newid)
  "Change the Tabulated List entry at point, setting the ID to NEWID."
  (let ((oldid (tabulated-list-get-id))
        (tle tabulated-list-entries)
        (inhibit-read-only t))
    (while (not (string= (caar tle) oldid)) (setq tle (cdr tle)))
    (setcar (car tle) newid)
    (save-excursion (put-text-property (progn (beginning-of-line) (point))
                                       (progn (forward-line) (point))
                                       'tabulated-list-id newid))))

(defun trashed-browse-url-of-file-internal (filename)
  "Ask a browser to display FILENAME using `browse-url-of-file'.
If FILENAME's original file extension was modified due to the name collision
in Trash directory, restore it first by renaming the trash filename
so the browser can display it properly."
  (let ((name (aref (tabulated-list-get-entry) 3)))
    (if (or (file-directory-p filename)
            (string= (file-name-extension filename) (file-name-extension name)))
        (browse-url-of-file filename)
      ;; Rename trash file to recover the original filename extension
      ;; This is only possible when (not (eq system-type 'windows-nt))
      (let* ((info-file (trashed-info-file (file-name-nondirectory filename)))
             delete-by-moving-to-trash newname)
        ;; Workaround for info files generated by Emacs bug #37922
        (if (not (file-exists-p info-file))
            (setq info-file (expand-file-name
                             (file-name-nondirectory filename)
                             trashed-info-dir)))
        (while (progn
                 (setq newname (make-temp-file
                                (expand-file-name (file-name-base name)
                                                  trashed-files-dir)
                                nil (concat "." (file-name-extension name))))
                 (condition-case nil
                     (rename-file info-file (trashed-info-file
                                             (file-name-nondirectory
                                              newname))) ;; nil -> exit
                   (file-already-exists t))) ;; t -> retry
          (delete-file newname))
        (rename-file filename newname t)
        (trashed-tabulated-list-set-id (file-name-nondirectory newname))
        (browse-url-of-file newname)))))

(defun trashed-num-tagged-files (tag)
  "Return the number of tagged files with TAG."
  (let ((ret 0))
    (save-excursion
      (trashed-reset-vpos)
      (while (tabulated-list-get-id)
        (if (eq (char-after) tag) (setq ret (1+ ret)))
        (forward-line)))
    ret))

(defun trashed-restore-file (file newname)
  "Restore FILE to NEWNAME.
Return nil if it successfully restored, t if an error occurred
or it was cancelled by user."
  (let (delete-by-moving-to-trash)
    (make-directory (file-name-directory newname) t)
    (condition-case err
        (rename-file file newname)
      ((file-already-exists file-error)
       (if (or (eq (car err) 'file-already-exists)
               (and (eq (car err) 'file-error)
                    (string= (cadr err) "File is a directory")))
           (if (apply trashed-action-confirmer
                      (list (format
                             "%s already exists; overwrite it? "
                             newname)))
               (rename-file file newname t)
             t)
         (error "%s" (error-message-string err)))))))

(defun trashed-tag-files-regexp (tag &optional regexp prompt)
  "TAG all files matching regular expression REGEXP.
If REGEXP is nil, read it using `read-regexp' with a prompt beginning with
PROMPT."
  (let ((n 0))
    (or regexp
        (setq regexp
              (read-regexp
               (concat prompt " files (regexp): ")
               ;; Add more suggestions into the default list
               (cons nil
                     (and (tabulated-list-get-id)
                          (list (aref (tabulated-list-get-entry) 3)
                                (concat
                                 (regexp-quote
                                  (file-name-extension
                                   (aref (tabulated-list-get-entry) 3) t))
                                 "\\'"))))
               'trashed-regexp-history)))
    (save-excursion
      (trashed-reset-vpos)
      (while (tabulated-list-get-id)
        (when (string-match regexp (aref (tabulated-list-get-entry) 3))
          (tabulated-list-put-tag (char-to-string tag))
          (setq n (1+ n)))
        (forward-line)))
    (message "%d matching files." n)))

(defun trashed-tag-files-by-date (tag &optional condition prompt)
  "TAG all files matching date condition CONDITION.
If CONDITION is nil, read it using `read-regexp' with a prompt beginning with
PROMPT.

CONDITION must consist of `<'(before) or `>'(after), and `N' days ago.
For example, `<365' means tag all files deleted before the day 1 year ago,
`>30' means tag all files deleted after the day 1 month ago,
`>1' means tag all files deleted today."
  (let* ((now-list (current-time))
         (now (+ (ash (car now-list) 16) (cadr now-list)))
         (n 0)
         comp past datestr date)
    (or condition
        (setq condition
              (read-string (concat prompt
                                   " files (`<'(before) or `>'(after),"
                                   " and `N' days ago): "))))
    (if (not (string-match "^ *\\(\<\\|\>\\) *\\([0-9]+\\) *$" condition))
        (error "Wrong date condition format")
      (setq comp (if (string= (match-string 1 condition) "<") '< '>=)
            past (- now (* 60 60 24 (- (string-to-number
                                        (match-string 2 condition))
                                       (if (eq comp '<) 0 1))))
            past (apply 'encode-time (append '(0 0 0) ;; remove hour/min/sec
                                             (cdddr (decode-time past))))
            past (+ (ash (car past) 16) (cadr past)))
      (save-excursion
        (trashed-reset-vpos)
        (while (tabulated-list-get-id)
          (setq datestr (aref (tabulated-list-get-entry) 2))
          (string-match "\\([0-9]+\\) \\([0-9]+\\)" datestr)
          (setq date (+ (ash (string-to-number (match-string 1 datestr)) 16)
                        (string-to-number (match-string 2 datestr))))
          (when (funcall comp date past)
            (tabulated-list-put-tag (char-to-string tag))
            (setq n (1+ n)))
          (forward-line)))
      (message "%d matching files." n))))

(defun trashed-do-action (action)
  "Restore/delete all marked files when ACTION is restore/delete."
  (let ((n (trashed-num-tagged-files trashed-marker-char))
        (trash-file-name (tabulated-list-get-id))
        c marked-file)
    (if (= n 0)
        (if trash-file-name
            (progn (save-excursion
                     (setq c (progn (beginning-of-line) (char-after)))
                     (tabulated-list-put-tag (char-to-string
                                              trashed-marker-char)))
                   (setq n 1
                         marked-file (expand-file-name trash-file-name
                                                       trashed-files-dir)))
          (error "No file on this line")))
    (unwind-protect
        (if (and (> n 0) (apply trashed-action-confirmer
                                (list (format "%s %c [%d item(s)] "
                                              (capitalize (symbol-name action))
                                              trashed-marker-char n))))
            (trashed-do-execute-internal action))
      (and marked-file (file-exists-p marked-file)
           (save-excursion (tabulated-list-put-tag (char-to-string c)))))))

(defun trashed-do-execute-internal (mark-action)
  "Internal function to actually restore/delete files.
Restoration/deletion is done according to MARK-ACTION and each tag status.
When MARK-ACTION is:

  nil     -- restore/delete files with flag R/D.
  restore -- restore files with mark *.
  delete  -- delete files with mark *."
  (let* (trash-file-name m entry)
    (save-excursion
      (trashed-reset-vpos)
      (while (setq trash-file-name (tabulated-list-get-id))
        (setq m (char-after)
              entry (tabulated-list-get-entry))
        (if (not
             (cond
              ((or (and (not mark-action) (eq m trashed-res-char))
                   (and (eq mark-action 'restore) (eq m trashed-marker-char)))
               (trashed-restore-file
                (expand-file-name trash-file-name trashed-files-dir)
                (expand-file-name (aref entry 3))))
              ((or (and (not mark-action) (eq m trashed-del-char))
                   (and (eq mark-action 'delete) (eq m trashed-marker-char)))
               (if (string= (aref entry 0) "d")
                   (delete-directory (expand-file-name trash-file-name
                                                       trashed-files-dir)
                                     t)
                 (delete-file (expand-file-name trash-file-name
                                                trashed-files-dir))))
              (t)))
            (progn
              ;; Delete info file
              (if (file-exists-p (trashed-info-file trash-file-name))
                  (delete-file (trashed-info-file trash-file-name))
                ;; Workaround for info files generated by Emacs bug #37922
                (let* ((isfx ".trashinfo")
                       (isfxlen (length isfx)))
                  (if (and (> (length trash-file-name) isfxlen)
                           (string= (substring trash-file-name (- isfxlen))
                                    isfx)
                           (not (file-exists-p (expand-file-name
                                                (substring trash-file-name
                                                           0 (- isfxlen))
                                                trashed-files-dir))))
                      (delete-file (expand-file-name trash-file-name
                                                     trashed-info-dir)))))
              ;; Delete from `tabulated-list-entries'
              (if (string= (caar tabulated-list-entries) trash-file-name)
                  (setq tabulated-list-entries (cdr tabulated-list-entries))
                (let ((tail tabulated-list-entries) tail-cdr)
                  (while (setq tail-cdr (cdr tail))
                    (setq tail (if (string= (caar tail-cdr) trash-file-name)
                                   (progn (setcdr tail (cdr tail-cdr)) nil)
                                 tail-cdr)))))
              ;; Delete from the list displayed
              (tabulated-list-delete-entry)
              ;; Subtract from trash can size
              (setq trashed-trash-can-size (- trashed-trash-can-size
                                              (string-to-number
                                               (aref entry 1)))))
          (forward-line)))
      (trashed-update-trash-can-size))))

;;; User commands

(define-derived-mode trashed-mode tabulated-list-mode "Trashed"
  "Major mode for viewing/editing system trash can.
Open, view, restore or permanently delete trashed files or directories
in trash can with Dired-like look and feel.

Customization variables:

  `trashed-use-header-line'
  `trashed-sort-key'
  `trashed-size-format'
  `trashed-date-format'
  `trashed-action-confirmer'

Hooks:

  `trashed-load-hook'
  `trashed-mode-hook'
  `trashed-before-readin-hook'
  `trashed-after-readin-hook'

Keybindings:

\\{trashed-mode-map}"
  ;; Column widths of size/date/name are set in `trashed-read-files'
  (setq tabulated-list-format [("T"            1 t)
                               ("Size"         0 trashed-size-sorter
                                                   :right-align t)
                               ("Date deleted" 0 t :right-align t)
                               ("Name"         0 t)]
        tabulated-list-sort-key trashed-sort-key
        tabulated-list-printer 'trashed-list-print-entry
        tabulated-list-padding 2
        font-lock-defaults '(trashed-font-lock-keywords t))
  (add-hook 'tabulated-list-revert-hook #'trashed-readin nil t)
  (font-lock-mode t))

;;;###autoload
(defun trashed ()
  "Viewing/editing system trash can.
Open, view, restore or permanently delete trashed files or directories
in trash can with Dired-like look and feel.  The trash can has to be
compliant with freedesktop.org specification in

<https://freedesktop.org/wiki/Specifications/trash-spec/>"
  (interactive)
  (if (not (buffer-live-p trashed-buffer))
      (progn
        (pop-to-buffer
         (setq trashed-buffer (get-buffer-create trashed-buffer-name)))
        (trashed-mode)
        (revert-buffer)
        (trashed-reset-vpos)
        (trashed-reset-hpos t))
    (pop-to-buffer trashed-buffer)))

(defun trashed-previous-line ()
  "Move up one line then position at File column."
  (interactive)
  (forward-line -1)
  (trashed-reset-hpos t))

(defun trashed-next-line ()
  "Move down one line then position at File column."
  (interactive)
  (forward-line 1)
  (trashed-reset-hpos t))

(defun trashed-forward-column ()
  "Move point to the forward column position."
  (interactive)
  (setq trashed-current-col (mod (1+ trashed-current-col)
                                 (length tabulated-list-format)))
  (trashed-set-hpos trashed-current-col))

(defun trashed-backward-column ()
  "Move point to the backward column position."
  (interactive)
  (setq trashed-current-col (mod (1- trashed-current-col)
                                 (length tabulated-list-format)))
  (trashed-set-hpos trashed-current-col))

(defun trashed-find-file ()
  "Visit this file."
  (interactive)
  (trashed-open-file 'find-file))

(defun trashed-find-file-other-window ()
  "Visit this file in another window."
  (interactive)
  (trashed-open-file 'find-file-other-window))

(defun trashed-mouse-find-file-other-window (event)
  "Visit the file you click on in another window.
EVENT is the mouse click event."
  (interactive "e")
  (with-current-buffer (window-buffer (posn-window (event-end event)))
    (goto-char (posn-point (event-end event)))
    (trashed-open-file 'find-file-other-window)))

(defun trashed-browse-url-of-file ()
  "Ask a browser to display this file."
  (interactive)
  (trashed-open-file 'trashed-browse-url-of-file-internal))

(defun trashed-mouse-browse-url-of-file (event)
  "Ask a browser to display the file you click on.
EVENT is the mouse click event."
  (interactive "e")
  (with-current-buffer (window-buffer (posn-window (event-end event)))
    (goto-char (posn-point (event-end event)))
    (trashed-open-file 'trashed-browse-url-of-file-internal)))

(defun trashed-display-file ()
  "Display this file in another window."
  (interactive)
  (trashed-open-file (lambda (f) (display-buffer (find-file-noselect f) t))))

(defun trashed-view-file ()
  "Examine this file in view mode, returning when done."
  (interactive)
  (trashed-open-file 'view-file))

(defun trashed-flag-restore ()
  "Flag this file for restoration."
  (interactive)
  (tabulated-list-put-tag (char-to-string trashed-res-char) t)
  (trashed-reset-hpos t))

(defun trashed-flag-delete ()
  "Flag this file for deletion."
  (interactive)
  (tabulated-list-put-tag (char-to-string trashed-del-char) t)
  (trashed-reset-hpos t))

(defun trashed-flag-backup-files ()
  "Flag all backup files (names ending with `~') for deletion."
  (interactive)
  (trashed-tag-files-regexp trashed-del-char "~$"))

(defun trashed-flag-auto-save-files ()
  "Flag all auto save files (names starting & ending with `#') for deletion."
  (interactive)
  (trashed-tag-files-regexp trashed-del-char "/#[^#]+#$"))

(defun trashed-mark ()
  "Mark this file for use in later commands."
  (interactive)
  (tabulated-list-put-tag (char-to-string trashed-marker-char) t)
  (trashed-reset-hpos t))

(defun trashed-unmark ()
  "Unmark this file."
  (interactive)
  (tabulated-list-put-tag (char-to-string ? ) t)
  (trashed-reset-hpos t))

(defun trashed-mark-all ()
  "Mark all files for use in later commands."
  (interactive)
  (save-excursion
    (trashed-reset-vpos)
    (while (tabulated-list-get-id)
      (tabulated-list-put-tag (char-to-string trashed-marker-char) t))))

(defun trashed-unmark-all ()
  "Unmark all files."
  (interactive)
  (save-excursion
    (trashed-reset-vpos)
    (while (tabulated-list-get-id)
      (tabulated-list-put-tag (char-to-string ? ) t))))

(defun trashed-toggle-marks ()
  "Toggle mark status: marked files become unmarked, and vice versa.
Files marked with other flags (such as ‘D’) are not affected."
  (interactive)
  (save-excursion
    (let (c)
      (trashed-reset-vpos)
      (while (tabulated-list-get-id)
        (setq c (char-after))
        (cond ((eq c ? )
               (tabulated-list-put-tag (char-to-string trashed-marker-char) t))
              ((eq c trashed-marker-char)
               (tabulated-list-put-tag (char-to-string ? ) t))
              (t (forward-line)))))))

(defun trashed-flag-restore-files-regexp (&optional regexp)
  "Flag all files matching REGEXP for restoration.
If called interactively or REGEXP is nil, prompt for REGEXP."
  (interactive)
  (trashed-tag-files-regexp trashed-res-char regexp "Flag restore"))

(defun trashed-flag-delete-files-regexp (&optional regexp)
  "Flag all files matching REGEXP for deletion.
If called interactively or REGEXP is nil, prompt for REGEXP."
  (interactive)
  (trashed-tag-files-regexp trashed-del-char regexp "Flag delete"))

(defun trashed-mark-files-regexp (&optional regexp)
  "Mark all files matching REGEXP for use in later commands.
If called interactively or REGEXP is nil, prompt for REGEXP."
  (interactive)
  (trashed-tag-files-regexp trashed-marker-char regexp "Mark"))

(defun trashed-unmark-files-regexp (&optional regexp)
  "Unmark all files matching REGEXP.
If called interactively or REGEXP is nil, prompt for REGEXP."
  (interactive)
  (trashed-tag-files-regexp ?  regexp "Unmark"))

(defun trashed-flag-restore-files-by-date (&optional condition)
  "Flag all files matching date CONDITION for restoration.
If called interactively or CONDITION is nil, prompt for date condition.
See `trashed-tag-files-by-date' for date condition details."
  (interactive)
  (trashed-tag-files-by-date trashed-res-char condition "Flag restore"))

(defun trashed-flag-delete-files-by-date (&optional condition)
  "Flag all files matching date CONDITION for deletion.
If called interactively or CONDITION is nil, prompt for date condition.
See `trashed-tag-files-by-date' for date condition details."
  (interactive)
  (trashed-tag-files-by-date trashed-del-char condition "Flag delete"))

(defun trashed-mark-files-by-date (&optional condition)
  "Mark all files matching date CONDITION for use in later commands.
If called interactively or CONDITION is nil, prompt for date condition.
See `trashed-tag-files-by-date' for date condition details."
  (interactive)
  (trashed-tag-files-by-date trashed-marker-char condition "Mark"))

(defun trashed-unmark-files-by-date (&optional condition)
  "Unmark all files matching date CONDITION.
If called interactively or CONDITION is nil, prompt for date condition.
See `trashed-tag-files-by-date' for date condition details."
  (interactive)
  (trashed-tag-files-by-date ?  condition "Unmark"))

(defun trashed-do-restore ()
  "Restore all marked files.
If no file is marked, restore this file."
  (interactive)
  (trashed-do-action 'restore))

(defun trashed-do-delete ()
  "Delete all marked files.
If no file is marked, delete this file."
  (interactive)
  (trashed-do-action 'delete))

(defun trashed-do-execute ()
  "Restore/delete all files flagged for restoration/deletion."
  (interactive)
  (let ((nr (trashed-num-tagged-files trashed-res-char))
        (nd (trashed-num-tagged-files trashed-del-char)))
    (if (> (+ nr nd) 0)
        (if (apply trashed-action-confirmer
                   (list (format "%s%s%s [%d item(s)] "
                                 (if (> nr 0) "Restore" "")
                                 (if (and (> nr 0) (> nd 0)) "/" "")
                                 (if (> nd 0) "Delete" "")
                                 (+ nr nd))))
            (trashed-do-execute-internal nil))
      (message "(No actions requested)"))))

(defun trashed-mouse-popup-menu (event)
  "Popup menu for the file you click on.
EVENT is the mouse click event."
  (interactive "e")
  (let ((inhibit-read-only t)
        sp ep key cmd)
    (pop-to-buffer (window-buffer (posn-window (event-end event))))
    (goto-char (posn-point (event-end event)))
    ;; Highlight the file while menu is shown
    (save-excursion (setq sp (progn (trashed-set-hpos 3) (point))
                          ep (progn (end-of-line) (point))))
    (put-text-property sp ep 'font-lock-face 'highlight)
    (redisplay)
    (if (not (eq (setq key (apply 'vector (x-popup-menu event trashed-menu)))
                 []))
        (setq cmd (lookup-key trashed-menu key)))
    (remove-text-properties sp ep '(font-lock-face))
    (if cmd (call-interactively cmd))))

(provide 'trashed)

(run-hooks 'trashed-load-hook)

;;; trashed.el ends here
