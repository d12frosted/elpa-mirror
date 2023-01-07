;;; diffed.el --- Diffed is for recursive diff like Dired is for ls -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Bernhard Rotter

;; Author: Bernhard Rotter <bernhard@b-rotter.de>
;; Created: 28 Mar 2022
;; Keywords: tools
;; Package-Version: 20230105.1629
;; Package-Commit: aabf4de060d88b30b86c28582288c28cfb310ad3
;; URL: https://github.com/ber-ro/diffed
;; Version: 0.1.1
;; Package-Requires: ((emacs "25.1"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Diffed uses recursive diff output as a base for directory synchronization.
;; There are shortcuts for the following operations: copy, move, delete, ediff,
;; find-file.

;; Usage: (diffed "/dir/1" "/dir/2")

;;; Code:

(require 'diff-mode)

(defvar diffed-bindings
  `(("O" . diffed-find-file-other-window)
    ("c" . diffed-copy-file)
    ("d" . diffed-delete-file)
    ("e" . diffed-ediff)
    ("f" . diffed-find-file)
    ("i" . diffed-toggle-identical)
    ("m" . diffed-move-file)
    ("t" . diffed-toggle-diff)
    ("v" . diffed-view-file)))
(easy-mmode-defmap diffed-mode-map diffed-bindings "Keymap for `diffed'.")

(define-derived-mode
  diffed-mode diff-mode "Diffed"
  "Major mode which uses recursive diff output as a base for synchronization.
Only the list of files is visible on startup. Detailed file differences are
hidden, but can be toggled.

Example: (diffed \"/dir-a/\" \"/dir-b/\")

Some operations need to select a file to operate on. These are selected by
numeric prefix keys. '1' selects the file below /dir-a (1st parameter), '2'
selects the file below /dir-b (2nd parameter) and '0' selects both.

Operations always work on the file(s) on the current line.

For copy and move the source is the file on the current line and the target is
the file that does not exist.

After copy/move/delete a text tag is inserted and further operations are not
allowed on the respective file."
  :group 'tools
  (setq-local revert-buffer-function #'diffed-revert-buffer))

(defvar-local diffed-dir1 nil "First directory to compare.")
(defvar-local diffed-dir2 nil "Second directory to compare.")
(defvar-local diffed-re-dir1 nil "Regex of first directory to compare.")
(defvar-local diffed-re-dir2 nil "Regex of second directory to compare.")
(defvar-local diffed-diff-options "-rsu" "Options for diff invocation.")
(defvar diffed-buffer nil "Switch back to Diffed.")

;;;###autoload
(defun diffed (dir1 dir2)
  "Use recursive diff to enable syncing of directories.
DIR1 and DIR2 are the directories to sync."
  (interactive "DCompare directory: \nD with directory: ")
  (let ((diffed-buffer (concat "diffed " dir1 "|" dir2)))
    (get-buffer-create diffed-buffer)
    (switch-to-buffer-other-window diffed-buffer)
    (read-only-mode 1)
    (diffed-mode)
    (setq diffed-dir1 (expand-file-name (directory-file-name dir1)))
    (setq diffed-dir2 (expand-file-name (directory-file-name dir2)))
    (setq diffed-re-dir1 (regexp-quote diffed-dir1))
    (setq diffed-re-dir2 (regexp-quote diffed-dir2))
    (diffed-revert-buffer)
    (diffed-keywords)))

(defun diffed-keywords ()
  "Add font-lock keywords."
  (let ((kwl `((,diffed-dir1 . 'diff-refine-removed)
               (,diffed-dir2 . 'diff-refine-added))))
    ;; if one directory is a sub-directory of the other, then order makes a
    ;; difference
    (when (< (length diffed-dir1) (length diffed-dir2))
      (setq kwl (reverse kwl)))
    (font-lock-add-keywords nil kwl)))

(defun diffed-find-diff-start ()
  "Find position of diff command of next file."
  (if (re-search-forward "^diff .*" nil 1)
      (match-end 0)
    nil))

(defun diffed-find-diff-end ()
  "Find position of diff end of current file."
  (goto-char (if (re-search-forward "^[[:alpha:]]" nil 1)
                 (1- (match-beginning 0))
               (point-max))))

(defun diffed-parse-diff (process _event)
  "Prepare buffer when diff PROCESS has finished."
  (with-current-buffer (process-buffer process)
    (setq buffer-invisibility-spec nil)
    (let ((inhibit-read-only t)
          start)
      (goto-char (point-min))
      (while (setq start (diffed-find-diff-start))
        (let ((filename (intern (car (diffed-get-filenames))))
              (end (diffed-find-diff-end)))
          (put-text-property start end 'invisible `(,filename . t))
          (add-to-invisibility-spec `(,filename . t))))
      (goto-char (point-min))
      (while (setq match (text-property-search-forward 'invisible nil t))
        (goto-char (prop-match-beginning match))
        (let ((end (prop-match-end match)))
          (while (re-search-forward ".* are identical" end 1)
            (put-text-property (match-beginning 0) (1+ (match-end 0))
                               'invisible (intern "identical")))))
      (goto-char (point-min))))
  (message "%s" "Diffed running diff...done"))

(defun diffed-revert-buffer (&optional _arg _noconfirm)
  "(Re)run diff."
  (interactive)
  (let ((inhibit-read-only t)
        (process-environment (cons "LANG=C" process-environment)))
    (erase-buffer)
    (message "%s" "Diffed running diff...")
    (make-process
     :name "diffed"
     :command `("diff" ,diffed-diff-options ,diffed-dir1 ,diffed-dir2)
     :buffer (current-buffer)
     :sentinel 'diffed-parse-diff)))

(defun diffed-get-filenames ()
  "Return filenames of current line as list (1 or 2 items)."
  (save-excursion
    (move-to-column 0)
    (re-search-forward
     (concat
      "^diff " diffed-diff-options
      " \"?\\(" diffed-re-dir1 ".+?\\)\"?"
      " \"?\\(" diffed-re-dir2 ".+?\\)\"?$"
      "\\|^Files \\(.*\\) and \\(.*\\) are identical"
      "\\|^Binary files \\(.*\\) and \\(.*\\) differ"
      "\\|^Only in \\(.*\\): \\(.*\\)")
     (line-end-position) 1)
    (cond
     ((match-string 1) (mapcar #'match-string-no-properties [1 2]))
     ((match-string 3) (mapcar #'match-string-no-properties [3 4]))
     ((match-string 5) (mapcar #'match-string-no-properties [5 6]))
     ((match-string 7)
      (list (expand-file-name (match-string-no-properties 8)
                              (match-string-no-properties 7))))
     (t (error "Not on a header line (diff ..., Only in ..., ... are identical)")))))

(defun diffed-get-filename (arg)
  "Select first or second or both files.
Query user, if ARG is required, but not supplied."
  (let ((files (diffed-get-filenames)))
    (cond ((= 1 (length files)) files)
          (t (mapcar (lambda (arg) (nth arg files)) (diffed-choice arg))))))

(defun diffed-choice (arg)
  "Return indices of selected files (0, 1, 0/1).
Prompt user if ARG is not supplied."
  (pcase (or arg
             (read-char-choice "First/second/both files (1/2/0)? " '(?1 ?2 ?0)))
    ((or '1 '?1) '(0))
    ((or '2 '?2) '(1))
    ((or '0 '?0) '(0 1))))

(defun diffed-toggle-invisibility (elem arg)
  "Toggle invisibility of ELEM to ARG.
If ARG is nil, then toggle. If ARG is zero, then turn off. Else turn on."
  (if (or (and (not arg)
               (member elem buffer-invisibility-spec))
          (and arg (not (= arg 0))))
      (remove-from-invisibility-spec elem)
    (add-to-invisibility-spec elem))
  (force-window-update (current-buffer)))

(defun diffed-toggle-diff (&optional arg)
  "Turn display of diff output on or off.
For ARG see `diffed-toggle-invisibility'."
  (interactive)
  (save-excursion
    (move-to-column 0)
    (when (re-search-forward "^diff " (line-end-position) t)
      (let* ((filename (intern (car (diffed-get-filenames)))))
        (diffed-toggle-invisibility `(,filename . t) arg)))))

(defun diffed-toggle-identical ()
  "Toggle display of identical files."
  (interactive)
  (diffed-toggle-invisibility (intern "identical") nil))

(defun diffed-delete-file (arg)
  "Delete one file (specified by ARG)."
  (interactive "P")
  (let ((inhibit-read-only t)
        (filenames (diffed-get-filename arg)))
    (dolist (f filenames)
      (when (yes-or-no-p (concat "Delete " f "? "))
        (delete-file f)
        (diffed-toggle-diff 0)
        (move-to-column 0)
        (insert "DELETED ")))))

(defun diffed-find-file (arg)
  "Open current file in buffer (first or second specifed by ARG)."
  (interactive "P")
  (let ((f (diffed-get-filename arg)))
    (find-file (car f))
    (when (> (length f) 1) (find-file-other-window (nth 1 f)))))

(defun diffed-find-file-other-window (arg)
  "Open current file in other buffer (first or second specifed by ARG)."
  (interactive "P")
  (let ((f (diffed-get-filename arg)))
    (find-file-other-window (car f))))

(defun diffed-view-file (arg)
  "Open current file in other buffer (first or second specifed by ARG)."
  (interactive "P")
  (let ((f (diffed-get-filename arg)))
    (view-file (car f))))

(defun diffed-copy-file ()
  "Copy current file to other directory."
  (interactive)
  (let* ((dirp (file-directory-p (car (diffed-get-filename 1))))
         (func (if dirp #'copy-directory #'copy-file))
         (args (if dirp '(t) '(nil t))))
    (diffed-file-op func "copied" args)))

(defun diffed-move-file ()
  "Move current file to other directory."
  (interactive)
  (diffed-file-op #'rename-file "moved" '()))

(defun diffed-file-op (op text args)
  "Get context for copy/move operation.
OP is copy or move
TEXT is description for the message
ARGS are additional arguments for OP"
  (save-excursion
    (move-to-column 0)
    (if (re-search-forward "^Only in " (line-end-position) t)
        (let* ((filename (car (diffed-get-filename 1)))
               (other-filename (diffed-get-other-filename filename))
               (inhibit-read-only t))
          (apply op filename other-filename args)
          (message (concat text " %s -> %s") filename other-filename)
          (move-to-column 0)
          (insert (upcase text) " "))
      (message "File operation allowed only for files with only 1 instance."))))

(defun diffed-get-other-filename (filename)
  "Get other file.
FILENAME is below first (return second) or second (return first) diff directory
parameter."
  (let* ((relative1 (file-relative-name filename diffed-dir1))
         (relative2 (file-relative-name filename diffed-dir2))
         (firstp (< (length relative1) (length relative2))))
    (expand-file-name (if firstp relative1 relative2)
                      (if firstp diffed-dir2 diffed-dir1))))

(defun diffed-ediff ()
  "Invoke ediff for current file."
  (interactive)
  (save-excursion
    (setq diffed-buffer (current-buffer))
    (add-hook 'ediff-quit-hook #'diffed-ediff-hook)
    (apply #'ediff (diffed-get-filenames))))

(defun diffed-ediff-hook ()
  "Switch back to Diffed."
  (switch-to-buffer diffed-buffer)
  (delete-other-windows)
  (remove-hook 'ediff-quit-hook #'diffed-ediff-hook))

(provide 'diffed)
;;; diffed.el ends here
