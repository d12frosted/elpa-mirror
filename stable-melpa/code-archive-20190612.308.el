;;; code-archive.el --- git supported code archive and reference for org-mode -*- lexical-binding: t -*-

;; Copyright (C) 2018 Michael Schuldt

;; Author: Michael Schuldt <mbschuldt@gmail.com>
;; Version: 0.3
;; Package-Version: 20190612.308
;; Package-Commit: 1ad9af6679d0294c3056eab9cad673f29c562721
;; Package-Requires: ((emacs "24.3"))
;; URL: https://github.com/mschuldt/code-archive

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Archive and reference source code snippets
;;
;; This package provides commands for saving selecting code regions and
;; inserting them as org-mode styled code blocks. These code blocks are
;; tagged with an id that allows jumping back to the original source file.
;; The original source file is archived in a git managed repo each time
;; a code block is saved.
;;
;; Saving full file copies enables referencing the orignal context and
;; avoids the problem of locating bookmarked regions when the file becomes
;; massively mutated or deleted. Using git solves the problem of saving
;; multiple versions of a file history in a space efficient way.
;;
;; Additional helpers are provided for org-capture templates.
;;
;; See the README for usage at https://github.com/mschuldt/code-archive
;;
;;; Code:

(require 'cl)

(defgroup code-archive nil
  "Source code archival and reference"
  :prefix "code-archive-"
  :group 'applications)

(defcustom code-archive-dir "~/code-archive"
  "Directory in which to archive source files."
  :group 'code-archive
  :type 'string)

(defcustom code-archive-src-map '((lisp-interaction-mode . "emacs-lisp")
                                  (makefile-automake-mode . "makefile")
                                  (GNUmakefile . "makefile")
                                  (makefile-gmake-mode . "makefile")
                                  (fundamental-mode . "text")
                                  (mhtml-mode . "html")
                                  )
  "Alist mapping major mode name to source name.
The source name is the alternative mode to use without the -mode suffix"
  :group 'code-archive
  :type '(alist :key-type (symbol :tag "Major mode name")
                :value-type (string :tag "source name for org block")))

(defcustom code-archive-git-executable "git"
  "The Git executable used by code-archive."
  :group 'code-archive
  :type 'string)

(defvar code-archive--save-stack nil)

(defvar code-archive--codeblocks (make-hash-table))

(defvar code-archive--initialized nil
  "Non-nil when the code archive has been initialized.")

(defvar code-archive--codeblocks-loaded nil
  "Non-nil when codeblocks are loaded.")

(defvar code-archive--last-id nil
  "Value of the last codeblock ID.")

(defstruct code-archive--entry
  codeblock src-type string)

(defstruct code-archive--codeblock
  id file archived-file line archived-git-commit archived-md5)

(defun code-archive--link-file ()
  "Return the archive link-file."
  (concat (file-name-as-directory code-archive-dir) "_code-links.el"))

(defun code-archive--run-git (&rest command-args)
  "Execute Git with COMMAND-ARGS, display any output."
  (let (s)
    (with-temp-buffer
      (cd code-archive-dir)
      (dolist (args command-args)
        (erase-buffer)
        (apply 'call-process code-archive-git-executable nil t nil args)
        (setq s (buffer-string))
        (message (format "command-args: %s" command-args))
        (when (and (not (equal (caar command-args) "show"))
                   (> (length s) 0))
          (message "%s" s))
        ))
    s))

(defun code-archive-init ()
  "Initialize the code archive."
  (unless (or code-archive--initialized
              (file-exists-p (concat (file-name-as-directory code-archive-dir)
                                     ".git")))
    (unless (file-exists-p code-archive-dir)
      (mkdir code-archive-dir))
    (with-temp-buffer
      (write-file (code-archive--link-file)))
    (code-archive--run-git '("init")
                           '("add" "*")
                           '("commit" "-m" "initial")))
  (setq code-archive--initialized t))

(defun code-archive--source-type ()
  "Return the source type of the current buffer."
  (when major-mode
    (or (cdr (assoc major-mode code-archive-src-map))
        (car (split-string (symbol-name major-mode) "-mode")))))

;;;###autoload
(defun code-archive-save-code ()
  "Archive the current buffer and save the region to the code archive stack."
  (interactive)
  (code-archive-init)
  (let* ((file (buffer-file-name))
         (line (and file
                    (line-number-at-pos (and (region-active-p)
                                             (region-beginning))
                                        t)))
         (region-string (if (region-active-p)
                             (buffer-substring (region-beginning)
                                               (region-end))
                          ""))
         (codeblock (code-archive--save-buffer-file)))
    (setf (code-archive--codeblock-file codeblock) file)
    (setf (code-archive--codeblock-line codeblock) line)
    (push (make-code-archive--entry :codeblock codeblock
                                    :src-type (code-archive--source-type)
                                    :string region-string)
          code-archive--save-stack)))

(defun code-archive--format-org-block ()
  "Format an `org-mode' styled code block sourced from the code archive stack.
This consumes an entry from ‘code-archive--save-stack’."
  (code-archive--load-codeblocks)
  (let* ((entry (pop code-archive--save-stack))
         (codeblock (code-archive--entry-codeblock entry))
         (src-type (code-archive--entry-src-type entry))
         (lines (split-string (code-archive--entry-string entry) "\n"))
         (code (mapconcat (lambda (line) (concat "  " line)) lines "\n"))
         (id (code-archive--next-id)))
    (setf (code-archive--codeblock-id codeblock) id)
    (code-archive--add-codeblock codeblock)
    (format  "\n#+BEGIN_SRC %s :var _id=%s
%s\n#+END_SRC
" src-type id code)))

;;;###autoload
(defun code-archive-insert-org-block ()
  "Insert an `org-mode' styled code block sourced from the code archive stack.
This consumes an entry from ‘code-archive--save-stack’."
  (interactive)
  (if code-archive--save-stack
      (save-excursion
        (insert (code-archive--format-org-block)))
    (message "code archive stack is empty")))

;;;###autoload
(defun code-archive-do-org-capture (filename)
  "For use in an org capture template, insert an org code block.
FILENAME is the name of the file visited by buffer when org capture was called.
Usage in capture template: (code-archive-do-org-capture \"%F\")"
  (when (string= filename "")
    (error "Buffer buffer-file-name was probably unset"))
  (with-current-buffer (find-buffer-visiting filename)
    (code-archive-save-code))
  (code-archive--format-org-block))

;;;###autoload
(defun code-archive-org-src-tag (filename)
  "For use in an org capture template, insert an org code block.
FILENAME is the name of the file visited by buffer when org capture was called.
Usage in capture template: (code-archive-org-src-tag \"%F\")"
  (when (string= filename "")
    (error "Buffer buffer-file-name was probably unset"))
  (let (src-type)
    (with-current-buffer (find-buffer-visiting filename)
      (setq src-type (code-archive--source-type)))
    (if src-type
        (progn (dolist (x '(("-" . "_")
                            ("+" . "p")
                            ))
                 (setq src-type (replace-regexp-in-string (car x) (cdr x) src-type)))
               (format ":%s:" src-type))
      "")))

(defun code-archive--set-auto-mode (filename)
  "Set auto mode for current buffer displaying FILENAME."
  (let ((buffer-file-name filename))
    (set-auto-mode)))

(defun code-archive--get-codeblock-id ()
  "Return the id of the codeblock at point."
  (save-excursion
    (end-of-line)
    (let ((bound (point)))
      (beginning-of-line)
      (if (looking-at "[ \t]*#\\+BEGIN_SRC")
          (if (re-search-forward "_id=\\([0-9]+\\)" bound)
              (string-to-number (match-string 1))
            (message "Error: could not find block id")
            nil)
        (message "Error: not on a source block header")
        nil))))

;;;###autoload
(defun code-archive-goto-src ()
  "Open the original source file of the codeblock at point.
The point must be on the first line." ;;TODO: jump from anywhere in the source block
  (interactive)
  (let ((id (code-archive--get-codeblock-id))
        info)
    (when id
      (setq info (code-archive--get-block-info id))
      (if info
          (let* ((source-file (code-archive--codeblock-file info))
                 (file source-file)
                 (archive-md5 (code-archive--codeblock-archived-md5 info))
                 (line (1- (code-archive--codeblock-line info)))
                 (file-exists (file-exists-p file))
                 hash archive-file filename buffer-name)
            (if (and file-exists
                     (string= (code-archive--file-md5 file)
                              archive-md5))
                (progn (find-file-other-window file)
                       (goto-char 1)
                       (forward-line line)
                       (message "Visiting original version"))
              ;; else:
              (setq filename (format "%s.%s"
                                     (file-name-base file)
                                     (file-name-extension file))
                    hash (code-archive--codeblock-archived-git-commit info)
                    buffer-name (concat filename "-" hash))
              (when (get-buffer buffer-name)
                (kill-buffer buffer-name))
              (setq buf (get-buffer-create buffer-name)
                    archive-file (code-archive--codeblock-archived-file info))
              (with-current-buffer buf
                (insert (code-archive--run-git
                         (list "show" (concat hash ":" archive-file))))
                (code-archive--set-auto-mode filename)
                (code-archive-mode)
                (setq code-archive--source-file source-file)
                (setq code-archive--source-line line)
                (goto-char 1)
                (forward-line line)
                (pop-to-buffer (current-buffer)))
              (message (concat "Visiting archived version. "
                               (if file-exists
                                   "Press 'o' to visit original changed file"
                                 "Original file deleted.")))))
        (message "Error: no link info for codeblock id: %s" id)))))

(defun code-archive--next-id ()
  "Return the next source block id."
  (assert (not (null code-archive--last-id)))
  (setq code-archive--last-id (1+ code-archive--last-id)))

(defun code-archive--file-md5 (filename)
  "Calculate the md5 digest of the file FILENAME."
  (with-temp-buffer
    (insert-file-contents-literally filename)
    (md5 (buffer-string))))

(defun code-archive--save-buffer-file ()
  "Archive the current buffer in `code-archive-dir'.
Return the archive data in a code-archive--codeblock struct."
  (save-buffer)
  (let* ((str (buffer-string))
         (checksum (md5 str))
         (path (or (buffer-file-name) ""))
         (name (replace-regexp-in-string "[/*]" "_"
                                         (or (file-name-nondirectory path)
                                             (buffer-name))))
         (filename (format "%s_%s" (md5 (or path (buffer-name))) name))
         (archive-path (concat (file-name-as-directory code-archive-dir)
                               filename))
         commit curr-md5 commit-hash)

    (if (file-exists-p archive-path)
        ;; check if file has changed
        (progn (setq curr-md5 (code-archive--file-md5 archive-path))
               (unless (string= checksum curr-md5)
                 (copy-file path archive-path :overwrite)
                 (setq commit "changed")))
      (progn (if path
                 ;; copy file to archive directory
                 (copy-file path archive-path)
               (with-temp-buffer
                 ;; file does not exist on disk, save the buffer contents to file
                 (insert str)
                 (write-file archive-path)))
             (setq commit "added")))

    (when commit
      (code-archive--run-git (list "add" filename)
                             (list "commit" "-m" (format "%s: %s"
                                                         commit path))))

    (setq commit-hash (code-archive--strip-end
                       (code-archive--run-git '("rev-parse" "HEAD"))
                       "\n"))
    (make-code-archive--codeblock :file path
                                  :archived-file filename
                                  :archived-git-commit commit-hash
                                  :archived-md5 checksum)
    ))

(defun code-archive--char-split-string (string)
  "Split a STRING into its charaters."
  (cdr (butlast (split-string string ""))))

(defun code-archive--strip-end (string &optional char)
  "If CHAR occurs at the end of STRING, remove it."
  (let ((split (nreverse (code-archive--char-split-string string)))
        (char (or char " ")))
    (while (string= char (car split))
      (setq split (cdr split)))
    (mapconcat 'identity (nreverse split) "")))

(defun code-archive--record-to-vector (record)
  "Convert RECORD type to a vector."
  (let* ((len (1- (length record)))
         (v (make-vector len nil)))
    (dotimes (i len)
      (aset v i (aref record (1+ i))))
    v))

(defun code-archive--codeblock-to-vector (codeblock)
  "Convert CODEBLOCK type to a vector."
  (cond ((vectorp codeblock)
         codeblock)
        ((recordp codeblock)
         (code-archive--record-to-vector codeblock))
        (t (error "Unhanded type: %s" (type-of codeblock)))))

(defun code-archive--array-to-codeblock (a)
  "Create a codeblock struct from the array A."
  (make-code-archive--codeblock :id (aref a 0)
                                :file (aref a 1)
                                :archived-file (aref a 2)
                                :line (aref a 3)
                                :archived-git-commit (aref a 4)
                                :archived-md5 (aref a 5)))

(defun code-archive--add-codeblock (codeblock)
  "Add a new CODEBLOCK link to the archive."
  (code-archive--load-codeblocks)
  (with-temp-buffer
    (let ((print-level nil)
          (print-length nil))
      (print (code-archive--codeblock-to-vector codeblock) (current-buffer)))
    (append-to-file (point-min)
                    (point-max)
                    (code-archive--link-file)))
  (puthash (code-archive--codeblock-id codeblock)
           codeblock
           code-archive--codeblocks)
  (code-archive--run-git '("add" "*")
                         (list "commit" "-m"
                               (format "code block link %s"
                                       (code-archive--codeblock-id codeblock)))))

(defun code-archive--get-block-info (id)
  "Return the source information for codeblock with given ID."
  (code-archive--load-codeblocks)
  (gethash id code-archive--codeblocks))

(defun code-archive--load-codeblocks ()
  "Load code archive codeblocks links."
  (unless code-archive--codeblocks-loaded
    (let ((c 0)
          (codeblocks (make-hash-table))
          (block-id 0)
          (max-id 0)
          blocks)
      (with-temp-buffer
        (condition-case err
            (progn
              (insert-file-contents-literally (code-archive--link-file))
              (goto-char (point-max))
              (insert ")")
              (goto-char 1)
              (insert "(")
              (goto-char 1)
              (setq blocks (mapcar 'code-archive--array-to-codeblock
                                   (read (current-buffer)))))
          (error (message "Error reading kb codeblock file '%s': %s"
                          (code-archive--link-file) err))))
      (dolist (x blocks)
        (if (gethash (code-archive--codeblock-id x) codeblocks)
            (error  "Duplicate codeblock link for id: %s"
                    (code-archive--codeblock-id x))
          (setq block-id (code-archive--codeblock-id x)
                max-id (max block-id max-id))
          (puthash block-id x codeblocks)
          (setq c (1+ c))))
      (setq code-archive--codeblocks codeblocks
            code-archive--last-id max-id)
      (message (format "loaded %s codeblock links" c)))
    (setq code-archive--codeblocks-loaded t)))

;;; minor mode for viewing archived code

(defvar-local code-archive--source-file nil
  "The original source file path for the archived buffer file")

(defvar-local code-archive--source-line nil
  "The line number in the original source file")

(defun code-archive-open-original-file ()
  "Open the original source file associated with the archived buffer source."
  (interactive)
  (if (file-exists-p code-archive--source-file)
      (let ((line code-archive--source-line))
        (find-file-other-window code-archive--source-file)
        (goto-char 1)
        (forward-line line))
    (message "Original file does not exist")))

(defun code-archive-kill-buffer () ;; prevent remapping by ido
  "Kill the current buffer."
  (interactive)
  (kill-buffer))

(defvar code-archive-mode-map
  (let ((map (make-sparse-keymap 'code-archive-mode-map)))
    (define-key map (kbd "o") 'code-archive-open-original-file)
    (define-key map (kbd "q") 'code-archive-kill-buffer)
    map)
  "The variable ‘code-archive-mode’ keymap.")

(define-minor-mode code-archive-mode
  "Minor mode for viewing archived files"
  nil "-code-archive" code-archive-mode-map
  (read-only-mode 1))

(provide 'code-archive)

;;; code-archive.el ends here
