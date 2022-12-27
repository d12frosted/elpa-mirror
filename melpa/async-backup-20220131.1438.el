;;; async-backup.el --- Backup on each save without freezing Emacs

;; Author: contrapunctus <xmpp:contrapunctus@jabjab.de>
;; Maintainer: contrapunctus <xmpp:contrapunctus@jabjab.de>
;; Keywords: files
;; Package-Version: 20220131.1438
;; Package-Commit: 6ddb39fe77d66cdef48b87cb0d0554ad7d132308
;; Homepage: https://tildegit.org/contrapunctus/async-backup
;; Package-Requires: ((emacs "24.4"))
;; Version: 0.0.1

;; This is free and unencumbered software released into the public domain.
;;
;; Anyone is free to copy, modify, publish, use, compile, sell, or
;; distribute this software, either in source code form or as a compiled
;; binary, for any purpose, commercial or non-commercial, and by any
;; means.
;;
;; For more information, please refer to <https://unlicense.org>

;;; Commentary:

;; Emacs has a built-in backup system, but it does not backup on each
;; save. It can be made to, but that makes saving really slow (and the
;; UI unresponsive), especially for large files.
;;
;; Fortunately, Emacs has asynchronous processes.
;;
;; To enable for all files -
;;   `(add-hook 'after-save-hook #'async-backup)'
;; To enable for a specific file -
;;   `M-x add-file-local-variable RET eval RET (add-hook 'after-save-hook #'async-backup nil t) RET'
;;
;; See the full documentation at <https://tildegit.org/contrapunctus/async-backup>

;;; Code:
(require 'cl-lib)
(eval-when-compile
  (require 'subr-x))

(defgroup async-backup nil
  "Backup on each save without freezing Emacs."
  :group 'files)

(defcustom async-backup-location
  (locate-user-emacs-file "async-backup")
  "Path to save backups to."
  :type 'directory)

(defcustom async-backup-time-format "%FT%H-%M-%S"
  "Time format used in backup files."
  :type 'string)

(defcustom async-backup-predicates '(identity)
  "List of predicates which must all pass for a file to be backup up.
Each predicate must accept a single argemnt, which is the full
path of the file to be backed up."
  :type '(repeat function))

;;;###autoload
(defun async-backup (&optional file)
  "Backup FILE, or file visited by current buffer."
  (let* ((backup-root      (string-remove-suffix "/" (expand-file-name async-backup-location)))
         (input-file       (if file (expand-file-name file)
                             (buffer-file-name)))
         (file-name-base   (file-name-base input-file))
         (file-extension   (file-name-extension input-file))
         (file-directory   (file-name-directory input-file))
         (output-directory (concat backup-root file-directory))
         (output-file      (concat output-directory
                                   file-name-base
                                   "-" (format-time-string async-backup-time-format)
                                   (if file-extension
                                       (concat "." file-extension)
                                     ""))))
    (unless (file-exists-p output-directory)
      (make-directory output-directory t))
    (when (cl-every (lambda (predicate)
                      (funcall predicate input-file))
                    async-backup-predicates)
      (start-process "async-backup" "*async-backup*" "emacs" "-Q" "--batch"
                     (format "--eval=(copy-file %S %S)" input-file output-file)))))

(provide 'async-backup)

;;; async-backup.el ends here
