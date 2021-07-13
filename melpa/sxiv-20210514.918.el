;;; sxiv.el --- Run the sxiv image viewer -*- lexical-binding: t; -*-

;; Author: contrapunctus <xmpp:contrapunctus@jabber.fr>
;; Maintainer: contrapunctus <xmpp:contrapunctus@jabber.fr>
;; Keywords: multimedia
;; Package-Version: 20210514.918
;; Package-Commit: 028409c3a9ff7ba33a1cc2158abfc1793ed50717
;; Homepage: https://gitlab.com/contrapunctus/sxiv.el
;; Package-Requires: ((dash "2.16.0") (emacs "25.1"))
;; Version: 0.4.1

;; This is free and unencumbered software released into the public domain.
;;
;; Anyone is free to copy, modify, publish, use, compile, sell, or
;; distribute this software, either in source code form or as a compiled
;; binary, for any purpose, commercial or non-commercial, and by any
;; means.
;;
;; For more information, please refer to <https://unlicense.org>

;;; Commentary:
;; The sole command and primary entry point is `sxiv'.
;;
;; `sxiv-filter' is the process filter, to insert subdirectories (via
;; `sxiv-insert-subdirs') and mark files marked in sxiv (via
;; `sxiv-dired-mark-files').

(require 'dired)
(require 'dash)

;;; Code:

(defgroup sxiv nil
  "Run the Simple X Image Viewer."
  :group 'multimedia)

(defcustom sxiv-arguments '("-a" "-f" "-o")
  "Arguments to be passed to the sxiv process.
It must contain \"-o\" for marking in Dired buffers to function."
  :type '(repeat string))

(defcustom sxiv-exclude-strings '()
  "Exclude files whose paths match these strings."
  :type '(repeat string))

(defcustom sxiv-after-exit-functions '(sxiv-dired-mark-files)
  "Functions run after the sxiv process exits.
Each function must accept two arguments, the associated process
and a string, which is output just received from it."
  :type '(repeat function))

(defvar sxiv--directory nil
  "Directory `sxiv' was called from.
Used by `sxiv-filter' to know where to mark files.")

(defun sxiv-dired-marked-files-p ()
  "Return t if there are marked files in the current Dired buffer.
With no marked files, or if not in a Dired buffer, return nil."
  (and (derived-mode-p 'dired-mode)
       (save-excursion
         (goto-char (point-min))
         (re-search-forward dired-re-mark nil t))))

(defun sxiv-insert-subdirs (paths)
  "Insert subdirectories from PATHS into the current Dired buffer.
Return PATHS unchanged."
  (cl-loop for path in paths
    ;; If the file does not exist in the current directory...
    when (and (not (file-exists-p (file-name-nondirectory path)))
              ;; Workaround for what looks like an Emacs issue (see TODO #9)
              (file-exists-p path)
                ;; ;; ...I don't understand why this is here!
                ;; ;; Why would there be a directory in the selected
                ;; ;; files, seeing as one can't mark directories in
                ;; ;; sxiv?
                ;; (file-directory-p path)
              )
    do (dired-insert-subdir (file-name-directory path))
    finally return paths))

(defun sxiv-dired-mark-files (_process output)
  "Open a `dired' buffer and mark any files marked by the user in `sxiv'."
  (find-file sxiv--directory)
  (let ((files (--> (split-string output "\n")
                 (-drop-last 1 it)
                 (sxiv-insert-subdirs it))))
    (dired-mark-if
     (and (not (looking-at-p dired-re-dot))
          (not (eolp))
          (let ((fn (dired-get-filename t t)))
            (and fn (--find (equal fn it) files))))
     "file")))

(defun sxiv-filter (process output)
  "Used as process filter for `sxiv'.
OUTPUT is the output of the sxiv process as a string."
  (run-hook-with-args 'sxiv-after-exit-functions process output))

(defun sxiv-paths-raw ()
  (cond ((sxiv-dired-marked-files-p)
         (dired-get-marked-files))
        ((derived-mode-p 'text-mode)
         (split-string
          (buffer-substring-no-properties (point-min) (point-max))
          "\n"))
        (t (directory-files default-directory))))

(defun sxiv-file-at-point-index (&optional paths)
  "Return index of file at point.
PATHS should be a list of relative file names as strings, and is
required for dired-mode buffers."
  (cond ((derived-mode-p 'dired-mode)
         (let* ((path-at-point (dired-file-name-at-point))
                (image-at-point (and path-at-point
                                     ;; REVIEW - also check if file is an image?
                                     (file-regular-p path-at-point)
                                     (file-relative-name path-at-point)))
                (index (when image-at-point
                         (--find-index (equal image-at-point it) paths))))
           (when index (1+ index))))
        ((derived-mode-p 'text-mode)
         (line-number-at-pos))))

(defun sxiv (&optional prefix)
  "Run sxiv(1), the Simple X Image Viewer.
By default, when run in a Dired buffer, open all files in the
current directory. Files marked in sxiv will be marked in Dired.

If run from a Dired buffer with marked files, open only those
files.

With prefix argument PREFIX, or when only provided directories,
run recursively (-r).

If run from a text file containing one file name per line, open
the files listed."
  (interactive "P")
  (let* ((paths   (--remove (or (equal it ".") (equal it "..")
                                ;; Currently, this takes effect even
                                ;; when running from a text
                                ;; file...should that be the case?
                                (-find (lambda (exclude)
                                         (string-match-p exclude it))
                                       sxiv-exclude-strings))
                            (sxiv-paths-raw)))
         ;; recurse with prefix arg, or if every path is a directory
         (recurse (or prefix (-every? #'file-directory-p paths)))
         ;; remove directories if not running recursively
         (paths   (if recurse paths (seq-remove #'file-directory-p paths)))
         (index   (sxiv-file-at-point-index paths))
         (index   (when index (number-to-string index)))
         (recurse (if recurse "-r" "")))
    (setq sxiv--directory default-directory)
    (message "Running sxiv...")
    (make-process :name "sxiv"
                  :buffer (generate-new-buffer-name "sxiv")
                  :command
                  (append '("sxiv")
                          sxiv-arguments
                          (when index (list "-n" index))
                          (list recurse "--")
                          paths)
                  :connection-type 'pipe
                  :filter #'sxiv-filter
                  :stderr "sxiv-errors")))

;; Local Variables:
;; nameless-current-name: "sxiv"
;; End:

(provide 'sxiv)

;;; sxiv.el ends here
