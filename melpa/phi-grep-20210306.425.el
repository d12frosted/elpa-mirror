;;; -*- lexical-binding: t -*-
;;; phi-grep.el --- Interactively-editable recursive grep implementation in elisp

;; Copyright (C) 2014- zk_phi

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

;; Author: zk_phi
;; URL: http://github.com/zk-phi/phi-grep
;; Package-Version: 20210306.425
;; Package-Commit: 7e2804c7ab4e875c7511917692c4b192662aa1ae
;; Version: 1.2.3
;; Package-Requires: ((cl-lib "0.1") (emacs "26.1"))

;;; Commentary:

;; This script is based on "traverselisp.el", originally authored by
;; Thierry Volpiatto.

;; Put this file in your load-path and load from init script,
;;
;;   (require 'phi-grep)
;;
;; then following commands are available:
;;
;;   - phi-grep-in-file
;;   - phi-grep-in-directory
;;
;; phi-grep can also invoked from dired buffers.
;;
;;   - phi-grep-dired-in-dir-at-point
;;   - phi-grep-dired-in-file-at-point
;;   - phi-grep-dired-in-marked-files
;;   - phi-grep-dired-in-all-files
;;   - phi-grep-dired-dwim
;;
;; You can optionally bind some keys.
;;
;;   (global-set-key (kbd "<f6>") 'phi-grep-in-directory)

;;; Change Log:

;; 1.0.0 First release
;; 1.1.0 Respect the language's syntax table while searching
;; 1.1.1 Bug fix
;; 1.2.0 do not to query whether to restore changes but to save
;; 1.2.1 add recursive phi-grep feature
;; 1.2.2 add option phi-grep-enable-syntactic-regex
;; 1.2.3 migrate to nadvice.el
;;       use mapcan for performance

;;; Code:

(require 'files)
(require 'dired)
(require 'cl-lib)

(defconst phi-grep-version "1.2.3")

;; + user options

(defgroup phi-grep nil
  "Recursive editable grep implemented in elisp."
  :group 'text)

(defcustom phi-grep-ignored-files
  '("\.elc$" "\.pyc$" "\.orig$" "\.bz2$" "\.gz$" "\.zip$"
    "\.vdi$" "\.doc$" "\.jpg$" "\.avi$" "\.jpeg$" "\.png$"
    "\.xpm$" "\.jar$" "\.pbm$" "\.gif$" "\.xls$" "\.ppt$"
    "\.mdb$" "\.adp$" "\\<\\(TAGS\\)\\>" "\.tiff$" "\.img$"
    "\.pdf$" "\.dvi$" "\.xbm$" "\.gpg$" "\.svg$" "\.rej$"
    "\.exe$" "\.gch$" "\.o$" "\.so$" "\.class$"
    "\.ppt$" "\.pptx$" "\.xls$" "\.xlsx$" "\.doc$" "\.docx$"
    "~$" "#[^/]+#$")
  "List of regexps that defines what files to ignore."
  :type '(repeat string)
  :group 'phi-grep)

(defcustom phi-grep-ignored-dirs
  '("." ".." ".hg" ".svn" "RCS" ".bzr" ".git"
    ".VirtualBox" ".arch-ids" "CVS" "{arch}" "knits")
  "List of directory names we don't want to search in."
  :type '(repeat string)
  :group 'phi-grep)

(defcustom phi-grep-mode-hook nil
  "Hook run when initializing phi-grep buffers."
  :type '(repeat function)
  :group 'phi-grep)

(defcustom phi-grep-mode-map
  (let ((kmap (make-sparse-keymap)))
    (define-key kmap (kbd "RET") 'phi-grep-exit)
    (define-key kmap (kbd "C-g") 'phi-grep-abort)
    (define-key kmap [remap kill-buffer] 'phi-grep-abort)
    (define-key kmap [remap phi-grep-in-directory] 'phi-grep-recursive)
    (define-key kmap [remap phi-grep-in-file] 'phi-grep-recursive)
    kmap)
  "Keymap for phi-grep buffers."
  :type '(restricted-sexp :match-alternatives (syntax-table-p))
  :group 'phi-grep)

(defcustom phi-grep-make-backup-function 'phi-grep-default-backup-function
  "a function called with one argument, FILENAME, before
comitting changes to the file. the function is expected to make a
backup of the file. this variable can also set nil, to tell
phi-grep not to make backups."
  :type 'function
  :group 'phi-grep)

(defcustom phi-grep-window-height 20
  "height of phi-grep window"
  :type 'integer
  :group 'phi-grep)

(defcustom phi-grep-enable-syntactic-regex t
  "when non-nil, phi-grep applies an appropreate major-mode for
each target files before searching into."
  :type 'boolean
  :group 'phi-grep)

;; + faces

(defface phi-grep-heading-face '((t (:inverse-video t)))
  "Face used to highlight the header line."
  :group 'phi-grep)

(defface phi-grep-match-face '((t (:background "yellow1" :foreground "black")))
  "Face used to highlight matches."
  :group 'phi-grep)

(defface phi-grep-overlay-face '((t (:background "Indianred4" :underline t)))
  "Face used to highlight the corresponding line in a preview buffer."
  :group 'phi-grep)

(defface phi-grep-line-number-face '((t (:bold t)))
  "Face used for line-numbers in phi-grep buffer."
  :group 'phi-grep)

(defface phi-grep-modified-face '((((background light)) (:background "#fdc6b3"))
                                  (t (:background "#502b36")))
  "Face used for modified lines in phi-grep buffer")

;; + utility functions
;; ++ general

(defun pgr:goto-line (line)
  "like goto-line but not for interactive use"
  (goto-char (point-min))
  (forward-line (1- line)))

(defun pgr:filter (pred lst)
  "Return a list of elements in LIST that satisfies PRED."
  (delq nil (mapcar (lambda (elem) (and (funcall pred elem) elem)) lst)))

;; ++ regexp

(defun pgr:string-match-any (str regexps)
  "Return non-nil iff some regexps in REGEXPS match STR."
  (and regexps
       (or (string-match (car regexps) str)
           (pgr:string-match-any str (cdr regexps)))))

(defun pgr:search-all-regexp (regexp)
  "Return a list of all (LINE-NUM LINE-STR (BEG . END) (BEG
 . END) ...) in the buffer that matches REGEXP."
  (save-excursion
    (let (res)
      (goto-char 1)
      (while (search-forward-regexp regexp nil t)
        (let ((beg (point-at-bol)) (end (point-at-eol)) matches)
          (while (progn
                   (push (cons (- (match-beginning 0) beg) (- (match-end 0) beg)) matches)
                   (search-forward-regexp regexp end t)))
          (push (cons (line-number-at-pos nil t)
                      (cons (buffer-substring-no-properties beg end) matches))
                res)))
      (nreverse res))))

;; ++ files

(defun phi-grep-default-backup-function (file)
  "backup FILE"
  (copy-file file (concat file "~") t))

(defun pgr:directory-files (dirname &optional recursive only-list)
  "List of files (not directory nor symlink) in DIRNAME. Files
  listed in \"phi-grep-ignored-files\" are excluded. When
  optional arg ONLY-LIST is specified, files not listed in the
  list are also excluded. Directories listed in
  \"phi-grep-ignored-dirs\" are not searched in."
  (let ((lst (pgr:filter
              (lambda (file) (not (file-symlink-p file)))
              (directory-files dirname t))))
    (message "scanning directory ... %s" (file-relative-name dirname))
    (nconc
     (pgr:filter (lambda (file)
                   (and (file-regular-p file)
                        (not (pgr:string-match-any file phi-grep-ignored-files))
                        (or (null only-list)
                            (pgr:string-match-any file only-list))))
                 lst)
     (and recursive
          (mapcan (lambda (dir)
                    (when (and (file-directory-p dir)
                               (not (member (file-name-nondirectory dir)
                                            phi-grep-ignored-dirs)))
                      (pgr:directory-files dir t only-list)))
                  lst)))))

;; ++ overlays

(defun pgr:overlay-at (point category)
  "Return an overlay at POINT whose category is CATEGORY, if
there is one."
  (cl-some (lambda (ov)
             (when (eq (overlay-get ov 'category) category)
               ov))
           (overlays-at point)))

(defun pgr:overlays-in (from to category)
  "Return all overlays between FROM and TO whose category is
CATEGORY."
  (cl-remove-if-not (lambda (ov) (eq (overlay-get ov 'category) category)) (overlays-in from to)))

(defun pgr:overlay-string (ov)
  "String which is overlayed by OV. text-properties are removed."
  (with-current-buffer (overlay-buffer ov)
    (buffer-substring-no-properties (overlay-start ov) (overlay-end ov))))

(defun pgr:replace-overlay-string (ov replacement)
  "Replace string overlayed by OV with REPLACEMENT."
  (with-current-buffer (overlay-buffer ov)
    (delete-region (overlay-start ov) (overlay-end ov))
    (goto-char (overlay-start ov))
    (move-overlay ov (point) (progn (insert replacement) (point)))))

;; + main function

(defvar pgr:original-buf nil)
(defvar pgr:original-pos nil)
(defvar pgr:original-win nil)
(defvar pgr:occurence-overlay nil)
(defvar pgr:preview-file nil "file showm in *phi-grep preview* buffer")
(defvar pgr:items nil "list of (FILE . (OV OV OV ...))")

(defun phi-grep-mode ()
  "Major mode to recurse in a tree and perform diverses actions on files."
  (interactive)
  (kill-all-local-variables)
  (use-local-map phi-grep-mode-map)
  (setq mode-name  "phi-grep"
        major-mode 'phi-grep-mode)
  (toggle-truncate-lines 1)
  (add-hook 'post-command-hook 'pgr:update-preview-window nil t)
  (run-hooks 'phi-grep-mode-hook))

(defun phi-grep (target-files regexp)
  "Do phi-grep on TARGET-FILES with REGEXP."
  (let ((win (split-window (selected-window) (- phi-grep-window-height) 'below)))
    (setq pgr:original-buf (current-buffer)
          pgr:original-pos (point)
          pgr:original-win (selected-window)
          pgr:preview-file nil
          pgr:items        nil)
    (select-window win)
    (switch-to-buffer (get-buffer-create "*phi-grep*"))
    (phi-grep-mode)
    (unwind-protect
        (let ((num-targets (length target-files))
              (num-done 0))
          (with-silent-modifications
            (dolist (file target-files)
              (pgr:insert-items file regexp)
              (cl-incf num-done)
              (let ((message-log-max nil))
                (message "searching [%3d/%3d] ... %4d match(es) found"
                         num-done num-targets (1- (line-number-at-pos)))))))
      (message "Found %s match(es) for `%s'" (1- (line-number-at-pos)) regexp)
      (goto-char (point-min)))))

(defun pgr:make-item-overlay (beg end file linum &optional with-heading)
  (let ((ov (make-overlay beg end nil nil t)))
    (overlay-put ov 'category      'phi-grep)
    (overlay-put ov 'filename      file)
    (overlay-put ov 'linum         linum)
    (overlay-put ov 'before-string (concat
                                    (when with-heading
                                      (propertize (concat (file-relative-name file) "\n")
                                                  'face 'phi-grep-heading-face))
                                    (propertize (format "%4d: " linum)
                                                'face 'phi-grep-line-number-face)))
    (overlay-put ov 'insert-in-front-hooks '(pgr:sync-modifications))
    (overlay-put ov 'insert-behind-hooks   '(pgr:sync-modifications))
    (overlay-put ov 'modification-hooks    '(pgr:sync-modifications))
    ov))

(defun pgr:make-partner-overlay (item &optional buf)
  "make a partner overlay for ITEM in buffer BUF."
  (save-current-buffer
    (when buf (set-buffer buf))
    (pgr:goto-line (overlay-get item 'linum))
    (let ((ov (make-overlay (point-at-bol) (point-at-eol) nil nil t)))
      (overlay-put ov   'category 'phi-grep-partner)
      (overlay-put ov   'partner  item)
      (overlay-put ov   'insert-in-front-hooks '(pgr:sync-modifications))
      (overlay-put ov   'insert-behind-hooks   '(pgr:sync-modifications))
      (overlay-put ov   'modification-hooks    '(pgr:sync-modifications))
      (overlay-put item 'partner ov)
      ov)))

(defun pgr:insert-items (file regexp)
  "Insert items in FILE that matches REGEXP."
  (with-silent-modifications
    (let* ((buf (get-file-buffer file))
           (matched-lines (if buf
                              (with-current-buffer buf
                                (pgr:search-all-regexp regexp))
                            (with-temp-buffer
                              (insert-file-contents file)
                              (when phi-grep-enable-syntactic-regex
                                (let ((buffer-file-name file))
                                  (ignore-errors (set-auto-mode))))
                              (pgr:search-all-regexp regexp))))
           (first-item-p t)
           items)
      (dolist (line matched-lines)
        (cl-destructuring-bind (linum string . matches) line
          (let ((beg (point)))
            (insert string "\n")
            (push (pgr:make-item-overlay beg (1- (point)) file linum first-item-p) items)
            (setq first-item-p nil)
            (when buf
              (pgr:make-partner-overlay (car items) buf))
            ;; make highlight overlays
            (dolist (match matches)
              (let ((ov (make-overlay (+ (car match) beg) (+ (cdr match) beg))))
                (overlay-put ov 'face 'phi-grep-match-face)
                (overlay-put ov 'modification-hooks '(pgr:delete-match-overlay)))))))
      (push (cons file items) pgr:items))))

(defun pgr:sync-modifications (ov after &rest _)
  (let* ((partner (overlay-get ov 'partner))
         (item-ov (if (eq (overlay-get ov 'category) 'phi-grep)
                      ov
                    partner)))
    (if (not after)
        ;; save original string BEFORE change
        (when (null (overlay-get item-ov 'original-str))
          (overlay-put item-ov 'original-str (pgr:overlay-string item-ov)))
      (let* ((buf (and partner (overlay-buffer partner)))
             (previewbuf (get-buffer "*phi-grep preview*"))
             (str (pgr:overlay-string ov))
             (inhibit-modification-hooks t))
        ;; sync modifications AFTER change
        (cond ((buffer-live-p buf)
               (with-current-buffer buf
                 (pgr:replace-overlay-string partner str)))
              ((and (buffer-live-p previewbuf)
                    (string= (overlay-get ov 'filename) pgr:preview-file))
               (with-current-buffer previewbuf
                 (pgr:goto-line (overlay-get ov 'linum))
                 (insert str)
                 (delete-region (point) (point-at-eol)))))
        (overlay-put ov 'face 'phi-grep-modified-face)
        (when partner
          (overlay-put partner 'face 'phi-grep-modified-face))
        ;; restore state if undone
        (when (string= str (overlay-get item-ov 'original-str))
          (overlay-put ov 'face nil)
          (when partner
            (overlay-put partner 'face nil))
          (overlay-put item-ov 'original-str nil))))))

(defun pgr:delete-match-overlay (ov after &rest _)
  (unless after (delete-overlay ov)))

(defun pgr:maybe-kill-preview-buffer ()
  (let ((buf (get-buffer "*phi-grep preview*")))
    (when (and buf (buffer-live-p buf))
      (kill-buffer buf))))

(defun pgr:update-preview-window ()
  "Show the selected line at pos in the preview window."
  (let ((ov (pgr:overlay-at (point) 'phi-grep)))
    (when ov
      (let ((filename (overlay-get ov 'filename))
            (linum (overlay-get ov 'linum))
            deactivate-mark)
        (when (window-live-p pgr:original-win)
          (with-selected-window pgr:original-win
            (let ((buf (get-file-buffer filename)))
              (cond (buf
                     (pgr:maybe-kill-preview-buffer)
                     (switch-to-buffer buf))
                    (t
                     (pgr:maybe-kill-preview-buffer)
                     (with-current-buffer (get-buffer-create "*phi-grep preview*")
                       (with-silent-modifications
                         (insert-file-contents filename))
                       (let ((buffer-file-name filename))
                         (ignore-errors (set-auto-mode)))
                       (setq pgr:preview-file filename)
                       ;; sync changes
                       (dolist (item (cdr (assoc filename pgr:items)))
                         (when (overlay-get item 'original-str)
                           (pgr:goto-line (overlay-get item 'linum))
                           (save-excursion
                             (delete-region (point-at-bol) (point-at-eol)))
                           (insert (pgr:overlay-string item))))
                       (add-hook 'before-change-functions
                                 'pgr:find-preview-file nil t))
                     (switch-to-buffer "*phi-grep preview*"))))
            ;; jump to the line
            (pgr:goto-line linum)
            (recenter)
            ;; make overlay
            (if pgr:occurence-overlay
                (move-overlay pgr:occurence-overlay
                              (point-at-bol) (1+ (point-at-eol)) (current-buffer))
              (setq pgr:occurence-overlay
                    (make-overlay (point-at-bol) (1+ (point-at-eol))))
              (overlay-put pgr:occurence-overlay 'face 'phi-grep-overlay-face))))))))

(defun pgr:find-preview-file (&rest _)
  "make it a file buffer."
  (let ((buf (get-buffer "*phi-grep preview*")))
    (when buf
      (with-current-buffer buf
        (let ((modified (buffer-modified-p)))
          (set-visited-file-name pgr:preview-file)
          (restore-buffer-modified-p modified)
          ;; make partner overlays and apply modifications
          (save-excursion
            (dolist (ov (cdr (assoc pgr:preview-file pgr:items)))
              (let ((partner (pgr:make-partner-overlay ov)))
                (when (overlay-get ov 'original-str)
                  (pgr:replace-overlay-string partner (pgr:overlay-string ov))))))
          (setq pgr:preview-file nil))))))

(define-advice find-file-noselect (:before (filename &optional nowarn &rest _) pgr:find-file-ad)
  "If the preview buffer is showing the file going to be found,
reuse the buffer instead of finding file to keep modifications."
  (when (and pgr:preview-file
             (get-buffer "*phi-grep preview*")
             (string= (file-truename pgr:preview-file)
                      (file-truename filename))
             (null nowarn))
    (pgr:find-preview-file)))

(defun pgr:quit ()
  "Clean up phi-grep buffer and preview buffer."
  ;; commit or revert changes
  (let ((file-changes nil)
        (buf-changes nil))
    (dolist (items pgr:items)
      (when (cl-some (lambda (ov)
                       (eq (overlay-get ov 'face) 'phi-grep-modified-face))
                     (cdr items))
        (if (get-file-buffer (car items))
            (push items buf-changes)
          (push items file-changes))))
    (when (or file-changes buf-changes)
      (when (y-or-n-p (format "Save %d files, %d buffers ?"
                              (length file-changes) (length buf-changes)))
        (dolist (changes file-changes)
          (let ((file (car changes)))
            (with-temp-buffer
              (when phi-grep-make-backup-function
                (funcall phi-grep-make-backup-function file))
              (insert-file-contents file)
              (dolist (change (cdr changes))
                (let ((line (overlay-get change 'linum)))
                  (pgr:goto-line line)
                  (save-excursion
                    (delete-region (point-at-bol) (point-at-eol)))
                  (insert (pgr:overlay-string change))))
              (write-region (point-min) (point-max) file))))
        (dolist (changes buf-changes)
          (with-current-buffer (get-file-buffer (car changes))
            (save-buffer))))))
  ;; remove partner overlays
  (dolist (items pgr:items)
    (when (get-file-buffer (car items))
      (dolist (item (cdr items))
        (let ((partner (overlay-get item 'partner)))
          (when partner (delete-overlay partner))))))
  ;; clean-up preview buffers and phi-grep windows
  (when pgr:occurence-overlay
    (delete-overlay pgr:occurence-overlay))
  (let ((buf (get-buffer "*phi-grep preview*")))
    (when buf (kill-buffer buf)))
  (kill-buffer)
  (delete-window))

;; + interactive commands

(defun pgr:dired-get-marked-files ()
  "Return list of all marked files in a dired buffer."
  (unless (eq major-mode 'dired-mode)
    (error "not in dired buffer"))
  (let ((all-marked (dired-get-marked-files nil nil nil t)))
    (when (symbolp (car all-marked))
      (setq all-marked (cdr all-marked)))
    (pgr:filter 'file-regular-p all-marked)))

;;;###autoload
(defun phi-grep-in-file (fname regexp)
  "phi-grep in a single file."
  (interactive (list (read-file-name "Grep File: " nil (buffer-file-name))
                     (read-regexp (if (fboundp 'read-regexp) "Regexp" "Regexp: "))))
  (phi-grep (list fname) regexp))

;;;###autoload
(defun phi-grep-in-directory (tree regexp &optional only)
  "phi-grep in all files recursively in a directory."
  (interactive
   (list (read-directory-name "Tree: ")
         (read-regexp (if (fboundp 'read-regexp) "Regexp" "Regexp: "))
         (read-string "CheckOnly: ")))
  (phi-grep (pgr:directory-files tree t (split-string (or only "") " ")) regexp))

;;;###autoload
(defun phi-grep-dired-in-dir-at-point (regex &optional only)
  "phi-grep in all files recursively in the selected directory."
  (interactive (list (read-regexp (if (fboundp 'read-regexp) "Regexp" "Regexp: "))
                     (read-string "CheckOnly: ")))
  (unless (eq major-mode 'dired-mode)
    (error "not in dired buffer"))
  (let ((tree (dired-get-filename)))
    (unless (file-directory-p tree)
      (error "%s is not a directory" tree))
    (phi-grep-in-directory tree regex only)))

;;;###autoload
(defun phi-grep-dired-in-file-at-point (regex)
  "phi-grep in the selected file."
  (interactive (list (read-regexp (if (fboundp 'read-regexp) "Regexp" "Regexp: "))))
  (unless (eq major-mode 'dired-mode)
    (error "not in dired buffer"))
  (let ((fname (dired-get-filename)))
    (unless (file-regular-p fname)
      (error "%s is not a regular file" fname))
    (phi-grep-in-file fname regex)))

;;;###autoload
(defun phi-grep-dired-in-marked-files (regexp)
  "phi-grep in all marked files."
  (interactive (list (read-regexp (if (fboundp 'read-regexp) "Regexp" "Regexp: "))))
  (unless (eq major-mode 'dired-mode)
    (error "not in dired buffer"))
  (phi-grep (pgr:dired-get-marked-files) regexp))

;;;###autoload
(defun phi-grep-dired-in-all-files (regexp only)
  "phi-grep in all files in the current directory."
  (interactive (list (read-regexp (if (fboundp 'read-regexp) "Regexp" "Regexp: "))
                     (read-string "CheckOnly: ")))
  (unless (eq major-mode 'dired-mode)
    (error "not in dired buffer"))
  (phi-grep
   (pgr:directory-files (dired-current-directory) nil (split-string only)) regexp))

;;;###autoload
(defun phi-grep-dired-dwim (regexp &optional only)
  "Call the phi-grep-dired command you want (Do What I Mean).

- file at point
- marked files
- directory at point (recursion)"
  (interactive
   (let ((f-or-d-name (dired-get-filename)))
     (cond ((pgr:dired-get-marked-files)
            (list (read-regexp (if (fboundp 'read-regexp) "Regexp" "Regexp: "))))
           ((file-directory-p f-or-d-name)
            (list (read-regexp (if (fboundp 'read-regexp) "Regexp" "Regexp: "))
                  (read-string "CheckOnly: "))))))
  (let ((fname (dired-get-filename)))
    (cond ((pgr:dired-get-marked-files)
           (phi-grep-dired-in-marked-files regexp))
          ((file-directory-p fname)
           (phi-grep-dired-in-dir-at-point regexp only)))))

;;;###autoload
(defun phi-grep-find-file-flat (tree)
  "Like `find-file' but all files under the directory TREE may be
completed with `completing-read'. This may be useful when you are
using a library like `ido-ubiquitous'."
  (interactive (list (read-directory-name "Tree : ")))
  (find-file
   (expand-file-name
    (completing-read "Find File: "
                     (mapcar (lambda (f) (file-relative-name f tree))
                             (pgr:directory-files tree t))
                     nil t)
    tree)))

(defun phi-grep-recursive ()
  "phi-grep in all files lited in this phi-grep result."
  (interactive)
  (unless (eq major-mode 'phi-grep-mode)
    (error "Not in a phi-grep result buffer."))
  (let ((files (cl-remove-duplicates
                (mapcar (lambda (ov) (overlay-get ov 'filename))
                        (pgr:overlays-in (point-min) (point-max) 'phi-grep))))
        (regexp (read-regexp (if (fboundp 'read-regexp) "Recursive grep" "Recursive grep: "))))
    (phi-grep-abort)
    (phi-grep files regexp)))

(defun phi-grep-abort ()
  "Quit phi-grep window and back to the original position."
  (interactive)
  (pgr:quit)
  (when (buffer-live-p pgr:original-buf)
    (switch-to-buffer pgr:original-buf)
    (goto-char pgr:original-pos)))

(defun phi-grep-exit ()
  "Quit phi-grep window with the preview window kept."
  (interactive)
  (pgr:update-preview-window)
  (pgr:find-preview-file)
  (pgr:quit))

;; + provide

(provide 'phi-grep)

;;; phi-grep.el ends here
