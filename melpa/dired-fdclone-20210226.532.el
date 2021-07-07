;;; dired-fdclone.el --- dired functions and settings to mimic FDclone
;;
;; Copyright (c) 2014-2021 Akinori MUSHA
;;
;; All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;; 1. Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;; 2. Redistributions in binary form must reproduce the above copyright
;;    notice, this list of conditions and the following disclaimer in the
;;    documentation and/or other materials provided with the distribution.
;;
;; THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
;; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;; ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
;; OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
;; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
;; LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
;; OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
;; SUCH DAMAGE.

;; Author: Akinori MUSHA <knu@iDaemons.org>
;; URL: https://github.com/knu/dired-fdclone.el
;; Package-Version: 20210226.532
;; Package-Commit: 3ba369f5fc48a8fdf06d1c6ee1167b5a6eb7c1b3
;; Created: 25 Dec 2014
;; Version: 1.5.5
;; Keywords: unix, directories, dired

;;; Commentary:
;;
;; dired-fdclone.el provides the following interactive commands:
;;
;; * diredfd-goto-top
;; * diredfd-goto-bottom
;; * diredfd-toggle-mark-here
;; * diredfd-toggle-mark
;; * diredfd-toggle-all-marks
;; * diredfd-mark-or-unmark-all
;; * diredfd-narrow-to-marked-files
;; * diredfd-narrow-to-files-regexp
;; * diredfd-goto-filename
;; * diredfd-do-shell-command
;; * diredfd-do-sort
;; * diredfd-do-flagged-delete-or-execute
;; * diredfd-enter
;; * diredfd-enter-directory
;; * diredfd-enter-parent-directory
;; * diredfd-enter-root-directory
;; * diredfd-history-backward
;; * diredfd-history-forward
;; * diredfd-follow-symlink
;; * diredfd-do-pack
;; * diredfd-do-unpack
;; * diredfd-help
;; * diredfd-nav-mode
;;
;; The above functions are mostly usable stand-alone, but if you feel
;; like "omakase", add the following line to your setup.
;;
;;   (dired-fdclone)
;;
;; This makes dired:
;;
;; - color directories in cyan and symlinks in yellow like FDclone
;; - sort directory listings in the directory-first style
;; - alter key bindings to mimic FD/FDclone
;; - not open a new buffer when you navigate to a new directory
;; - run a shell command in ansi-term to allow launching interactive
;;   commands
;; - automatically revert the buffer after running a command with
;;   obvious side-effects
;; - automatically add visited files to `file-name-history`
;;   (customizable)
;;
;; Without spoiling dired's existing features.
;;
;; As usual, customization is available via:
;;
;;   M-x customize-group dired-fdclone RET

;;; Code:

(require 'dired-x)
(require 'dired-aux)
(require 'term)

(eval-when-compile
  (require 'cl))

(defgroup dired-fdclone nil
  "Dired functions and settings to mimic FDclone."
  :group 'dired)

(defcustom diredfd-auto-revert t
  "Automatically revert dired buffers after an interactive command is run."
  :type 'boolean
  :group 'dired-fdclone)

(defvar diredfd-enter-history nil
  "Default variable for `diredfd-enter-history-variable'.")

(defcustom diredfd-enter-history-variable 'diredfd-enter-history
  "History list to use for diredfd-enter."
  :type 'symbol
  :group 'dired-fdclone)

(defcustom diredfd-add-visited-file-to-file-name-history-p t
  "If non-nil, visited files will be added to `file-name-history'."
  :type 'boolean
  :group 'dired-fdclone)

(defvar diredfd--add-to-file-name-history nil
  "Internal flag to determine if the result of `dired-get-file-for-visit' should be added to `file-name-history'.")

(defadvice dired-get-file-for-visit
  (after diredfd activate)
  (if diredfd--add-to-file-name-history
      (add-to-history 'file-name-history ad-return-value)))

(defadvice dired-find-file
  (around diredfd activate)
  (let ((dired--add-to-file-name-history t))
    ad-do-it))

(defadvice dired-find-file-other-window
  (around diredfd activate)
  (let ((dired--add-to-file-name-history t))
    ad-do-it))

(defun diredfd-auto-revert ()
  (if diredfd-auto-revert
      (revert-buffer)
    (diredfd-sort)))

(defconst diredfd-auto-revert-command-list
  '(dired-do-flagged-delete
    dired-create-directory))

(defconst diredfd-auto-revert-redisplaying-command-list
  '(dired-do-chmod
    dired-do-chown
    dired-do-chgrp
    dired-do-touch))

(defconst diredfd-auto-revert-maybe-async-command-list
  '(dired-do-copy
    dired-do-delete
    dired-do-rename))

(defmacro diredfd-add-after-advice (name &rest body)
  `(progn
     (ad-add-advice ,name
                    '(diredfd
                      nil t
                      (advice . (lambda () ,@body)))
                    'after 'last)
     (ad-activate ,name)))

(defun diredfd-advice-auto-revert (command)
  (diredfd-add-after-advice command
                            (diredfd-auto-revert)))

(defun diredfd-advice-auto-revert-if-sync (command)
  (diredfd-add-after-advice command
                            (or (bound-and-true-p dired-async-be-async)
                                (diredfd-auto-revert))))

;;;###autoload
(defun diredfd-enable-auto-revert ()
  "Enable auto-revert settings for dired.

`dired-async' is supported."

  (dolist (command diredfd-auto-revert-command-list)
    (diredfd-advice-auto-revert command))

  (defadvice dired-do-redisplay
      (after diredfd activate)
    ;; save and restore the point
    (let ((filename (dired-get-filename nil t)))
      (if (memq this-command diredfd-auto-revert-redisplaying-command-list)
          (diredfd-auto-revert))
      (diredfd-goto-filename filename)))

  (dolist (command diredfd-auto-revert-maybe-async-command-list)
    (diredfd-advice-auto-revert-if-sync command))

  (defadvice dired-async-after-file-create
      (around diredfd activate)
    (let ((revert (and
                   diredfd-auto-revert
                   (bound-and-true-p dired-async-mode))))
      ad-do-it
      (if revert
          (dolist (buffer (buffer-list))
            (with-current-buffer buffer
              (if (eq major-mode 'dired-mode)
                  (revert-buffer))))))))

(defcustom diredfd-nav-width 25
  "Default window width of `diredfd-nav-mode'."
  :type 'integer
  :group 'dired-fdclone)

;;;###autoload
(define-minor-mode diredfd-nav-mode
  "Toggle nav mode."
  :group 'dired-fdclone
  (unless (derived-mode-p 'dired-mode)
    (error "Not a Dired buffer"))
  (if diredfd-nav-mode
      (dired-hide-details-mode 1)
    (dired-hide-details-mode 0)))

(defun diredfd-nav-set-window-width (&optional n)
  (let ((window (window-normalize-window nil))
        (n (max (or n diredfd-nav-width)
                window-min-width)))
    (window-resize window (- n (window-width)) t)))

(defmacro diredfd-nav-other-window-do (&rest body)
  `(if diredfd-nav-mode
       (let ((split-height-threshold nil)
             (split-width-threshold 0)
             (dired-window (selected-window))
             (width (window-width)))
         (if (ignore-errors (windmove-right) t)
             (progn
               ;; delete the window to the right if any
               (delete-window)
               (select-window dired-window t))
           (setq width nil))
         (prog1
             (progn ,@body)
           (let ((window (selected-window)))
             (select-window dired-window t)
             (diredfd-nav-set-window-width width)
             (select-window window t))))
     ,@body))

;;;###autoload
(defun diredfd-find-file ()
  "Visit the current file or directory."
  (cond (diredfd-nav-mode
         (diredfd-nav-other-window-do (dired-find-file-other-window))
         (add-hook 'kill-buffer-hook 'diredfd-nav-delete-window t t))
        (t (dired-find-file))))

(defun diredfd-nav-delete-window ()
    (when (save-excursion
            (ignore-errors
              (windmove-left)
              (and
               (eq major-mode 'dired-mode)
               diredfd-nav-mode)))
      (delete-window)))

;;;###autoload
(defun diredfd-goto-top ()
  "Go to the top line of the current file list after `..'.\nIf the point is already at the top file, go to the beginning of the buffer."
  (interactive)
  (let ((pos (point)))
    (beginning-of-buffer)
    (while (not (dired-move-to-filename))
      (forward-line 1))
    (while (let* ((file (dired-get-file-for-visit))
                  (filename (file-name-nondirectory file)))
             (string-match-p "\\`\\.\\.?\\'" filename))
      (dired-next-line 1))
    (if (= pos (point))
        (beginning-of-buffer))))

;;;###autoload
(defun diredfd-goto-bottom ()
  "Go to the bottom line of the current file list.\nIf the point is already at the bottom file, go to the end of the buffer."
  (interactive)
  (let ((pos (point)))
    (end-of-buffer)
    (while (not (dired-move-to-filename))
      (forward-line -1))
    (while (let* ((file (dired-get-file-for-visit))
                  (filename (file-name-nondirectory file)))
             (string-match-p "\\`\\.\\.?\\'" filename))
      (dired-next-line 1))
    (if (= pos (point))
        (end-of-buffer))))

;;;###autoload
(defun diredfd-toggle-mark-here ()
  "Toggle the mark on the current line."
  (interactive)
  (beginning-of-line)
  (or (dired-between-files)
      (looking-at-p dired-re-dot)
      (let ((inhibit-read-only t)
            (char (following-char)))
        (funcall 'subst-char-in-region
                 (point) (1+ (point)) char
                 (if (eq char ?\s)
                     dired-marker-char ?\s))))
  (dired-move-to-filename))

;;;###autoload
(defun diredfd-toggle-mark (&optional arg)
  "Toggle the mark on the current line and move to the next line.\nRepeat ARG times if given."
  (interactive "p")
  (loop for n from 1 to arg
        until (eobp) do
        (diredfd-toggle-mark-here)
        (dired-next-line 1)))

;;;###autoload
(defun diredfd-toggle-all-marks ()
  "Toggle all marks."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (not (eobp))
      (beginning-of-line)
      (or (dired-between-files)
          (looking-at-p dired-re-dot)
          (diredfd-toggle-mark-here))
      (dired-next-line 1))))

;;;###autoload
(defun diredfd-mark-or-unmark-all (&optional arg)
  "Unmark all files if there is any file marked, or mark all non-directory files otherwise.
If ARG is given, mark all files including directories."
  (interactive "P")
  (if arg
      (dired-mark-if (not (or (dired-between-files)
                              (looking-at-p dired-re-dot)))
                     "file")
    (if (cdr (dired-get-marked-files nil nil nil t))
        (dired-unmark-all-marks)
      (dired-mark-if (not (or (dired-between-files)
                              (looking-at-p dired-re-dot)
                              (file-directory-p (dired-get-filename nil t))))
                     "non-directory file"))))

;;;###autoload
(defun diredfd-narrow-to-marked-files ()
  "Kill all unmarked lines using `dired-kill-line'."
  (interactive)
  (save-excursion
    (goto-char (point-max))
    (while (not (bobp))
      (beginning-of-line)
      (or (dired-between-files)
          (looking-at-p dired-re-dot)
          (eq dired-marker-char (following-char))
          (dired-kill-line 1))
      (forward-line -1))))

;;;###autoload
(defun diredfd-narrow-to-files-regexp (regexp)
  "Kill all lines except those matching REGEXP using `dired-kill-line'."
  (interactive
   (list (dired-read-regexp "Narrow to files (regexp): ")))
  (save-excursion
    (goto-char (point-max))
    (while (not (bobp))
      (beginning-of-line)
      (or (dired-between-files)
          (looking-at-p dired-re-dot)
          (string-match-p regexp (dired-get-filename nil t))
          (dired-kill-line 1))
      (forward-line -1))))

;;;###autoload
(defun diredfd-goto-filename (filename)
  "Jump to FILENAME."
  (interactive "sGo to filename: ")
  (let ((pos (save-excursion
               (goto-char (point-min))
               (loop until (eobp) do
                     (dired-next-line 1)
                     (and (dired-move-to-filename)
                          (string= (file-name-nondirectory (dired-get-filename nil t))
                                   filename)
                          (return (point)))))))
    (if pos (goto-char pos)
      (error "Filename not found: %s" filename))))

(defun diredfd-expand-command-tmpl (command-tmpl &optional current-file marked-file)
  (let* ((current-file (or current-file
                           (dired-get-filename nil t)))
         (arg (and current-prefix-arg
                   (prefix-numeric-value current-prefix-arg)))
         (marked-files (dired-get-marked-files t arg)))
    (let ((value
           (catch 'macro
             (let ((command
                    (replace-regexp-in-string
                     "%\\([%PC]\\|X\\(M\\|TA?\\)?\\|M\\|TA?\\)"
                     (lambda (match)
                       (cond ((string= match "%%")
                              "%")
                             ((string= match "%P")
                              (shell-quote-argument default-directory))
                             ((string= match "%C")
                              (shell-quote-argument
                               (file-relative-name current-file)))
                             ((string= match "%X")
                              (shell-quote-argument
                               (file-name-sans-extension
                                (file-relative-name current-file))))
                             ((string-match-p "M" match 1)
                              (if marked-file
                                  (shell-quote-argument
                                   (let* ((file (file-relative-name marked-file)))
                                     (if (string-match-p "X" match 1)
                                         (file-name-sans-extension file)
                                       file)))
                                (throw 'macro 'mark)))
                             ((string-match-p "T" match 1)
                              (mapconcat
                               `(lambda (file)
                                  (shell-quote-argument
                                   (let ((file (file-relative-name file)))
                                     ,(if (string-match-p "X" match 1)
                                          '(file-name-sans-extension file)
                                        'file))))
                               marked-files
                               " "))
                             (t match)))
                     command-tmpl t t)))
               (list command)))))
      (cond ((eq value 'mark)
             (loop for marked-file in marked-files
                   nconc (diredfd-expand-command-tmpl command-tmpl current-file marked-file)))
            (t value)))))

(defun diredfd--shell-commands (caller-buffer-name shell buffer-name commands)
  (if commands
      (let* ((command (car commands))
             (args (if (string= command "")
                       nil
                     (list "-c" command)))
             (buffer
              (apply 'term-ansi-make-term
                     buffer-name
                     shell nil args)))
        (with-current-buffer buffer
          (term-mode)
          (term-char-mode))
        (set-process-sentinel
         (get-buffer-process buffer)
         `(lambda (proc msg)
            (let ((commands (list ,@(cdr commands))))
              (if commands
                  (diredfd--shell-commands ,caller-buffer-name ,shell ,buffer-name commands)
                (let ((buffer (process-buffer proc))
                      (return-to-caller-buffer
                       (lambda () (interactive)
                         (kill-buffer (current-buffer))
                         (switch-to-buffer ,caller-buffer-name)
                         (and (eq major-mode 'dired-mode)
                              (revert-buffer)))))
                  (term-sentinel proc msg)
                  (when (buffer-live-p buffer)
                    (with-current-buffer buffer
                      (local-set-key "q" return-to-caller-buffer)
                      (local-set-key " " return-to-caller-buffer)
                      (local-set-key (kbd "RET") return-to-caller-buffer)
                      (let ((buffer-read-only))
                        (insert "Hit SPC/RET/q to return...")))))))))
        (switch-to-buffer buffer))))

(defun diredfd-shell-commands (commands)
  (let ((caller-buffer-name (buffer-name))
        (shell (or explicit-shell-file-name
                   (getenv "ESHELL")
                   (getenv "SHELL")
                   "/bin/sh"))
        (buffer-name (generate-new-buffer-name
                      (format "*%s - %s*"
                              "dired-shell"
                              default-directory))))
    (diredfd--shell-commands caller-buffer-name shell buffer-name commands)))

;;;###autoload
(defun diredfd-do-shell-command (command)
  "Open an ANSI terminal and run a COMMAND in it.

In COMMAND, the % sign is a meta-character and the following
macros are available.  All path names expanded will be escaped
with `shell-quote-argument'.

%P  -- Expands to the current directory name in full path.
%C  -- Expands to the name of the file at point.
%T  -- Expands to the names of the marked files, separated by
       spaces.
%M  -- Expands to the name of each marked file, repeating the
       command once for every marked file.
%X  -- Expands to the name of the file at point without the last
       suffix. (cf. `file-name-sans-extension')
%XM -- Expands to the name of each marked file without the last
       suffix, repeating the command once for every marked file.
%XT -- Expands to the names of the marked files without their
       last suffix, separated by spaces.
%%  -- Expands to a literal %."
  (interactive
   (list (if current-prefix-arg ""
           (read-shell-command "Shell command: "))))
  (diredfd-shell-commands (diredfd-expand-command-tmpl command)))

;;;###autoload
(defun diredfd-do-flagged-delete-or-execute (&optional arg)
  "Run `dired-do-flagged-delete' if any file is flagged for deletion.
If none is, run a shell command with all marked (or next ARG) files or the current file.

For a list of macros usable in a shell command line, see `diredfd-do-shell-command'."
  (interactive "P")
  (if (save-excursion
        (let* ((dired-marker-char dired-del-marker)
               (regexp (dired-marker-regexp))
               case-fold-search)
          (goto-char (point-min))
          (re-search-forward regexp nil t)))
      (dired-do-flagged-delete)
    (let* ((file (or (dired-get-filename nil t)
                     (error "No file to execute")))
           (rel (file-relative-name file))
           (qrel (shell-quote-argument rel))
           (initial-contents
            (if (and (file-regular-p file)
                     (file-executable-p file))
                (concat (file-name-as-directory ".") qrel " ")
              (cons (concat " " qrel) 1)))
           (command (read-shell-command "Shell command: "
                                        initial-contents)))
      (diredfd-do-shell-command command))))

(defconst diredfd-sort-key-alist
  '((?n . filename)
    (?e . extension)
    (?s . size)
    (?t . time)
    (?l . length))
  "List of sort keys.")

(defconst diredfd-sort-key-chars (mapcar 'car diredfd-sort-key-alist))
(defconst diredfd-sort-keys (mapcar 'cdr diredfd-sort-key-alist))

(defcustom diredfd-sort-key 'filename
  "Default sort key for directory listings."
  :type `(choice :tag "Sort Key"
                 ,@(mapcar (lambda (symbol)
                             `(const :tag ,(capitalize (symbol-name symbol))
                                     ,symbol))
                           diredfd-sort-keys))
  :group 'dired-fdclone)
(make-variable-buffer-local 'dired-sort-key)

(defcustom diredfd-sort-direction 'asc
  "If non-nil, sort directory listings in descending order."
  :type '(choice (const :tag "Ascending" asc)
                 (const :tag "Descending" desc))
  :group 'dired-fdclone)
(make-variable-buffer-local 'diredfd-sort-direction)

(defun diredfd-sort-desc-p ()
  (eq diredfd-sort-direction 'desc))

;;;###autoload
(defun diredfd-enter ()
  "Visit the current file, or enter if it is a directory."
  (interactive)
  (let* ((file (dired-get-file-for-visit))
         (filename (file-name-nondirectory file)))
    (cond ((file-directory-p file)
           (if (string= filename "..")
               (diredfd-enter-parent-directory)
             (diredfd-enter-directory file "..")))
          (t
           (diredfd-find-file)))))

;;;###autoload
(defun diredfd-enter-directory (&optional directory filename)
  "Enter DIRECTORY and jump to FILENAME."
  (interactive (list (read-directory-name
                      "Go to directory: "
                      dired-directory nil t)))
  (set-buffer-modified-p nil)
  (let ((nav diredfd-nav-mode)
        (sort-key diredfd-sort-key)
        (sort-direction diredfd-sort-direction))
    (if (and server-buffer-clients
             (loop for proc in server-buffer-clients
                   thereis (and (memq proc server-clients)
                                (eq (process-status proc) 'open))))
        ;; Keep a directory buffer opened with emacsclient
        (let ((find-file-run-dired t))
          (find-file directory))
      (find-alternate-file directory))
    (add-to-history diredfd-enter-history-variable directory nil t)
    (revert-buffer)
    (diredfd-do-sort sort-key sort-direction)
    (if nav (diredfd-nav-mode 1)))
  (if filename
      (diredfd-goto-filename filename)))

;;;###autoload
(defun diredfd-enter-parent-directory ()
  "Enter the parent directory."
  (interactive)
  (let* ((file (dired-get-filename nil t))
         (dirname (directory-file-name (if file (file-name-directory file) dired-directory))))
    (diredfd-enter-directory (expand-file-name ".." dirname) (file-name-nondirectory dirname))))

;;;###autoload
(defun diredfd-enter-root-directory ()
  "Enter the root directory."
  (interactive)
  (set-buffer-modified-p nil)
  (diredfd-enter-directory "/" "..")
  (dired-next-line 1))

;;###autoload
(defun diredfd-history-backward ()
  "Go to the previous directory in history"
  (interactive)
  (let* ((history (symbol-value diredfd-enter-history-variable))
         (curr (car history))
         (rest (cdr history)))
    (set diredfd-enter-history-variable (nconc (cdr rest) (list curr)))
    (diredfd-enter-directory (car rest))))

;;###autoload
(defun diredfd-history-forward ()
  "Go to the next directory in history"
  (interactive)
  (let* ((history (symbol-value diredfd-enter-history-variable))
         (last (last history))
         (rest (butlast history)))
    (set diredfd-enter-history-variable rest)
    (diredfd-enter-directory (car last))))

;;;###autoload
(defun diredfd-follow-symlink ()
  "Follow the s parent directory."
  (interactive)
  (let* ((file (or (dired-get-filename nil t)
                   (error "No file to follow")))
         (truename (file-truename file))
         (dirname (directory-file-name (file-name-directory truename)))
         (filename (file-name-nondirectory truename)))
    (diredfd-enter-directory dirname filename)))

;;;###autoload
(defun diredfd-view-file ()
  "Visit the current file in view mode."
  (interactive)
  (let ((file (dired-get-file-for-visit)))
    (if (file-directory-p file)
        (dired-view-file)
      (diredfd-nav-other-window-do (view-file-other-window file)))))

(defcustom diredfd-archive-info-list
  '(["\\.tar\\'"
     "tar cf ? *"
     "tar xf ? *"]
    ["\\.\\(tar\\.Z\\|taZ\\)\\'"
     "tar Zcf ? *"
     "tar Zxf ? *"]
    ["\\.\\(tar\\.g?z\\|t[ga]z\\)\\'"
     "tar cf - * | gzip -9c > ?"
     "tar zxf ? *"]
    ["\\.\\(tar\\.bz2\\|tbz\\)\\'"
     "tar cf - * | bzip2 -9c > ?"
     "tar jxf ? *"]
    ["\\.\\(tar\\.xz\\|txz\\)\\'"
     "tar cf - * | xz -9c > ?"
     "xz -cd ? | tar xf - *"]
    ["\\.a\\'"
     "ar -rc ? *"
     "ar -x ? *"]
    ["\\.lzh\\'"
     "lha aq ? *"
     "lha xq ? *"]
    ["\\.\\(zip\\|jar\\|xpi\\)\\'"
     "zip -qr ? *"
     "unzip -q ? *"]
    ["\\.Z\\'"
     "compress -c * > ?"
     "sh -c 'uncompress -c \"$1\" > \"${1%.Z}\"' . ?"]
    ["\\.gz\\'"
     "gzip -9c * > ?"
     "gzip -dk ?"]
    ["\\.bz2\\'"
     "bzip2 -9c * > ?"
     "bzip2 -dk ?"]
    ["\\.lzma\\'"
     "lzma -9c * > ?"
     "lzma -dk ?"]
    ["\\.xz\\'"
     "xz -9c * > ?"
     "xz -dk ?"]
    ["\\.gem\\'"
     nil
     "tar xf ? *"]
    ["\\.rpm\\'"
     nil
     "rpm2cpio ? | cpio -id *"]
    ["\\.deb\\'"
     nil
     "ar -x ? *"])
  "List of vectors that define how to handle archive formats.

Each element is a vector of the form [REGEXP ARCHIVE-COMMAND
UNARCHIVE-COMMAND], where:

   regexp                is a regexp that matches filenames that are
                         archived with this format.

   archive-command       is a shell command line that creates or
                         adds files to an archive file of this
                         format, where a `?' separated with space
                         will be replaced by the archive filename
                         and a `*' separated with space by the
                         list of files to archive.

                         Nil means you shouldn't need or want to
                         manually do that.

   unarchive-command     is a shell command line that extracts
                         files stored in an archive file of this
                         format, where a `?' separated with space
                         will be replaced by the archive filename
                         and a `*' separated with space by the
                         list of files to extract or an empty
                         string when extracting all files in it.

                         Lack of a `*' indicates that this
                         archive format is for storing a single
                         file.

This list is used by such commands as `diredfd-do-pack' and
`diredfd-do-unpack' to determine the archive format of a
filename.  If a filename matches more than one regexp, the one
with the longest match is adopted so `.tar.gz' is chosen over
`.gz' independent of the order in the list."
  :type '(repeat (vector (regexp :tag "Filename Regexp")
			 (choice :tag "Archive Command"
				 (string :format "%v")
				 (const :tag "No archive command" nil))
                         (string :tag "Unarchive Command")))
  :group 'dired-fdclone)

(defsubst diredfd-archive-info-regexp            (info) (and info (aref info 0)))
(defsubst diredfd-archive-info-archive-command   (info) (and info (aref info 1)))
(defsubst diredfd-archive-info-unarchive-command (info) (and info (aref info 2)))

(defun diredfd-archive-info-for-file (filename)
  (and (or (not (file-exists-p filename))
           (file-regular-p filename))
       (loop for info in diredfd-archive-info-list
             with longest = 0
             with matched = nil
             if (string-match (diredfd-archive-info-regexp info) filename)
             do
             (let ((len (- (match-end 0) (match-beginning 0))))
               (if (< longest len)
                   (setq longest len
                         matched info)))
             finally return matched)))

(defun diredfd-archive-command-for-file (filename)
  (diredfd-archive-info-archive-command
   (diredfd-archive-info-for-file filename)))

(defun diredfd-unarchive-command-for-file (filename)
  (diredfd-archive-info-unarchive-command
   (diredfd-archive-info-for-file filename)))

(defun diredfd-parse-user-input (input)
  (if (string-match "[ \t]*&[ \t]*\\'" input)
      (list (substring input 0 (match-beginning 0)) t)
    (list input nil)))

;;;###autoload
(defun diredfd-do-pack (&optional arg)
  "Pack all marked (or next ARG) files, or the current file into an archive."
  (interactive "P")
  (let* ((arg (and arg (prefix-numeric-value arg)))
         (files (dired-get-marked-files t arg))
         (default (dired-get-filename nil t))
         (directory (if default (file-name-directory default) dired-directory))
         (default (and default
                       (/= (char-after (line-beginning-position))
                           dired-marker-char)
                       (diredfd-archive-command-for-file default)
                       (file-name-nondirectory default)
                       default))
         (parsed (diredfd-parse-user-input
                  (read-file-name
                   (format "Pack %s into%s: "
                           (dired-mark-prompt arg files)
                           (if default
                               (format " (%s)" default) ""))
                   directory default nil nil
                   #'(lambda (file)
                       (or (file-directory-p file)
                           (diredfd-archive-command-for-file file))))))
         (archive (expand-file-name (car parsed)))
         (async (cadr parsed)))
    (diredfd-pack files archive async)))

;;;###autoload
(defun diredfd-pack (files archive &optional async)
  "Pack FILES into ARCHIVE, asynchronously if ASYNC is non-nil."
  (let* ((command-tmpl (or (diredfd-archive-command-for-file archive)
                           (error "Unknown archive format: %s" archive)))
         (command (mapconcat
                   (lambda (token)
                     (cond ((string= token "?")
                            (shell-quote-argument archive))
                           ((string= token "*")
                            (mapconcat #'shell-quote-argument
                                       files " "))
                           (t
                            token)))
                   (split-string command-tmpl " ")
                   " ")))
    (if async
        (async-shell-command command)
      (diredfd-do-shell-command command))))

;;;###autoload
(defun diredfd-do-unpack (&optional arg)
  "Unpack all marked (or next ARG) files or the current file."
  (interactive "P")
  (let* ((arg (and arg (prefix-numeric-value arg)))
         (files (dired-get-marked-files t arg))
         (default (dired-get-filename nil t))
         (directory (if default (file-name-directory default) dired-directory))
         (default (and default
                       (/= (char-after (line-beginning-position))
                           dired-marker-char)
                       (file-directory-p default)
                       default))
         (parsed (diredfd-parse-user-input
                  (read-file-name
                   (format "Unpack %s into%s: "
                           (dired-mark-prompt arg files)
                           (if default
                               (format " (%s)" default) ""))
                   directory default nil nil
                   #'file-directory-p)))
         (directory (expand-file-name (car parsed)))
         (async (cadr parsed)))
    (or (file-directory-p directory)
        (if (y-or-n-p (format "Directory %s does not exist; create? " directory))
            (make-directory directory t)
          (error "Unpack aborted.")))
    (dolist (archive files)
      (diredfd-unpack archive directory async))))

(defun diredfd-unpack (archive directory &optional async)
  "Unpack ARCHIVE into DIRECTORY, asynchronously if ASYNC is non-nil."
  (let* ((command-tmpl (or (diredfd-unarchive-command-for-file archive)
                           (error "Unknown archive format: %s" archive)))
         (command (concat
                   (format "cd %s || exit; "
                           (shell-quote-argument
                            (expand-file-name directory)))
                   (mapconcat
                    (lambda (token)
                      (cond ((string= token "?")
                             (shell-quote-argument (expand-file-name archive)))
                            ((string= token "*")
                             "")
                            (t
                             token)))
                    (split-string command-tmpl " ")
                    " "))))
    (if async
        (async-shell-command command)
      (diredfd-do-shell-command command))))

(defun diredfd-sort-lines (reverse beg end)
  (interactive "P\nr")
  (save-excursion
    (save-restriction
      (narrow-to-region beg end)
      (goto-char (point-min))
      (let ((inhibit-field-text-motion t))
	(sort-subr nil 'forward-line 'end-of-line
                   #'diredfd-get-line-value nil
                   (if (diredfd-sort-desc-p)
                       #'diredfd-line-value->
                     #'diredfd-line-value-<))))))

(defun diredfd-get-line-value ()
  (let* ((filename (dired-get-filename nil t))
         (basename (file-name-nondirectory filename))
         (type (cond ((string= "." basename) 0)
                     ((string= ".." basename) 1)
                     (t (let ((type (char-after (+ (line-beginning-position) 2))))
                          (cond ((= type ?d) 2)
                                ((= type ?l)
                                 (cond ((file-directory-p filename) 2)
                                       ((file-exists-p filename) 3)
                                       (t 4)))
                                (t 3)))))))
    (cons (if (diredfd-sort-desc-p) (- type) type) ;; Always sort by type in ascending order
          (cond ((eq diredfd-sort-key 'filename)
                 (list basename))
                ((eq diredfd-sort-key 'extension)
                 (reverse (split-string (file-name-nondirectory filename)
                                        "\\.")))
                ((eq diredfd-sort-key 'time)
                 (append (nth 5 (file-attributes filename)) (list basename)))
                ((eq diredfd-sort-key 'size)
                 (list (nth 7 (file-attributes filename)) basename))
                ((eq diredfd-sort-key 'length)
                 (list (length filename) basename))))))

(defun diredfd-line-value-< (l1 l2)
  (let ((v1 (car l1))
        (v2 (car l2)))
    (cond ((null v1) (not (null v2)))
          ((null v2) nil)
          ((stringp v1)
           (or (string< v1 v2)
               (and (string= v1 v2)
                    (diredfd-line-value-< (cdr l1) (cdr l2)))))
          (t
           (or (< v1 v2)
               (and (= v1 v2)
                    (diredfd-line-value-< (cdr l1) (cdr l2))))))))

(defun diredfd-line-value-> (l1 l2)
  (diredfd-line-value-< l2 l1))

(defconst diredfd-sort-key-prompt
  (concat "Sort by "
          (mapconcat
           (lambda (pair)
             (let* ((cs (char-to-string (car pair)))
                    (quoted (regexp-quote cs))
                    (upper (upcase cs))
                    (name (symbol-name (cdr pair))))
               (if (string-match-p quoted name)
                   (replace-regexp-in-string
                    (concat quoted "\\(.*\\)\\'")
                    (concat upper "\\1")
                    name)
                 (concat upper ":" name))))
           diredfd-sort-key-alist
           "/")
          "?"))

(defun diredfd-do-sort (&optional sort-key sort-direction)
  (interactive
   (list (cdr (assq (read-char-choice diredfd-sort-key-prompt
                                      diredfd-sort-key-chars)
                    diredfd-sort-key-alist))
         (if (char-equal
              ?d
              (read-char-choice "Ascending or Descending?"
                                '(?a ?d ?u))) ;; FDclone's options are U and D
             'desc 'asc)))
  (setq diredfd-sort-key (or sort-key diredfd-sort-key)
        diredfd-sort-direction (or sort-direction diredfd-sort-direction))
  (diredfd-sort)
  (message "Sorted by %s (%s)"
           diredfd-sort-key
           (if (diredfd-sort-desc-p) "descending" "ascending")))

(defun diredfd-sort ()
  (save-excursion
    (let (buffer-read-only)
      (goto-char (point-min))
      (while (loop while (dired-between-files)
                   do (if (eobp)
                          (return nil)
                        (forward-line))
                   finally return t)
        (let ((beg (point)))
          (while (not (dired-between-files))
            (forward-line))
          (diredfd-sort-lines nil beg (point)))))
    (set-buffer-modified-p nil)))

(defcustom diredfd-highlight-line t
  "If non-nil, the current line is highlighted like FDclone."
  :type 'boolean
  :group 'dired-fdclone)

(defcustom diredfd-sort-by-type t
  "If non-nil, directory entries are sorted by file type (directories first)."
  :type 'boolean
  :group 'dired-fdclone)

(defun diredfd-dired-mode-setup ()
  (if diredfd-highlight-line (hl-line-mode 1)))

(defun diredfd-dired-after-readin-setup ()
  (if diredfd-sort-by-type (diredfd-sort)))

;;;###autoload
(defun diredfd-help ()
  "Show the help window."
  (interactive)
  (describe-bindings)
  (with-current-buffer (help-buffer)
    (goto-char (point-min))
    (re-search-forward "^Major Mode Bindings:$")
    (beginning-of-line)
    (recenter 0)))

;;;###autoload
(defun dired-fdclone ()
  "Enable FDclone mimicking settings for dired."
  (define-key dired-mode-map (kbd "TAB") 'diredfd-toggle-mark-here)
  (define-key dired-mode-map (kbd "DEL") 'diredfd-enter-parent-directory)
  (define-key dired-mode-map (kbd "RET") 'diredfd-enter)
  (define-key dired-mode-map " "         'diredfd-toggle-mark)
  (define-key dired-mode-map "("         'diredfd-nav-mode)
  (define-key dired-mode-map "*"         'dired-mark-files-regexp)
  (define-key dired-mode-map "+"         'diredfd-mark-or-unmark-all)
  (define-key dired-mode-map "-"         'diredfd-toggle-all-marks)
  (define-key dired-mode-map "/"         'dired-do-search)
  (define-key dired-mode-map "<"         'diredfd-goto-top)
  (define-key dired-mode-map ">"         'diredfd-goto-bottom)
  (define-key dired-mode-map "["         'diredfd-history-backward)
  (define-key dired-mode-map "]"         'diredfd-history-forward)
  (define-key dired-mode-map [remap beginning-of-buffer] 'diredfd-goto-top)
  (define-key dired-mode-map [remap end-of-buffer]       'diredfd-goto-bottom)
  (define-key dired-mode-map "?"         'diredfd-help)
  (define-key dired-mode-map "D"         'dired-flag-file-deletion)
  (define-key dired-mode-map "\\"        'diredfd-enter-root-directory)
  (define-key dired-mode-map "a"         'dired-do-chmod)
  (define-key dired-mode-map "c"         'dired-do-copy)
  (define-key dired-mode-map "d"         'dired-do-delete)
  (define-key dired-mode-map "f"         'diredfd-narrow-to-files-regexp)
  (define-key dired-mode-map "h"         'diredfd-do-shell-command)
  (define-key dired-mode-map "k"         'dired-create-directory)
  (define-key dired-mode-map "J"         'diredfd-follow-symlink)
  (define-key dired-mode-map "l"         'diredfd-enter-directory)
  (define-key dired-mode-map "m"         'dired-do-rename)
  (define-key dired-mode-map "n"         'diredfd-narrow-to-marked-files)
  (define-key dired-mode-map "p"         'diredfd-do-pack)
  (define-key dired-mode-map "r"         (if (fboundp 'wdired-change-to-wdired-mode)
                                             'wdired-change-to-wdired-mode
                                           'dired-do-rename))
  (define-key dired-mode-map "s"         'diredfd-do-sort)
  (define-key dired-mode-map "u"         'diredfd-do-unpack)
  (define-key dired-mode-map "v"         'diredfd-view-file)
  (define-key dired-mode-map "x"         'diredfd-do-flagged-delete-or-execute)

  (set-face-attribute 'dired-directory
                      nil :inherit font-lock-function-name-face :foreground "cyan")
  (set-face-attribute 'dired-symlink
                      nil :inherit font-lock-keyword-face :foreground "yellow")

  (setq dired-deletion-confirmer 'y-or-n-p)

  (diredfd-enable-auto-revert)

  (add-hook 'dired-mode-hook 'diredfd-dired-mode-setup)
  (add-hook 'dired-after-readin-hook 'diredfd-dired-after-readin-setup))

(provide 'dired-fdclone)

;;; dired-fdclone.el ends here
