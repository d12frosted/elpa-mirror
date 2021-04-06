;;; bang.el --- A sam-like shell-command -*- lexical-binding: t -*-

;; Author: Philip K. <philip@warpmail.net>
;; Version: 1.0.3
;; Package-Version: 20210405.1640
;; Package-Commit: b5252a77aed6d1c533367fde0f11d6901bf23d96
;; Keywords: unix, processes, convenience
;; Package-Requires: ((emacs "24.1"))
;; URL: https://git.sr.ht/~zge/bang

;; This file is NOT part of Emacs.
;;
;; This file is in the public domain, to the extent possible under law,
;; published under the CC0 1.0 Universal license.
;;
;; For a full copy of the CC0 license see
;; https://creativecommons.org/publicdomain/zero/1.0/legalcode

;;; Commentary:
;;
;; Bang is a interactive `shell-command' substitute, that extends the
;; regular Emacs function by considering the first character as special.
;; Read `bang's docstring for more details.
;;
;; This version of Bang has been based on Leah Neukirchen's version,
;; though it has been internally rewritten.
;;
;; The original version can be found here:
;; https://leahneukirchen.org/dotfiles/.emacs

(eval-when-compile (require 'rx))

;;; Code:

(defgroup bang nil
  "An extended `shell-command'"
  :group 'external
  :prefix "bang-")

(defcustom bang-use-eshell t
  "Check if there is an eshell-handler for each command."
  :type 'boolean)

(defconst bang--command-regexp
  (rx bos (* space)
      (? (group (or (: ?. (not (any "/"))) ?/ ?~)
                (* (not space)))
         (+ space))
      (or (group ?<) (group ?>) (group ?|) ?! "")
      (* space)
      (group (: (group (* (any alnum ?_ ?-)))
                (? space))
             (+ not-newline))
      eos))

(defun bang-expand-path (path)
  "Expand any PATH into absolute path with additional tricks.

Furthermore, replace each sequence with three or more `.'s with a
proper upwards directory pointers.  This means that '....' becomes
'../../../..', and so on."
  (expand-file-name
   (replace-regexp-in-string
    (rx (>= 2 "."))
    (lambda (sub)
      (mapconcat #'identity (make-list (1- (length sub)) "..") "/"))
    path)))

;;;###autoload
(defun bang (command beg end)
  "Intelligently execute string COMMAND in inferior shell.

When COMMAND starts with
  <  the output of COMMAND replaces the current selection
  >  COMMAND is run with the current selection as input
  |  the current selection is filtered through COMMAND
  !  COMMAND is simply executed (same as without any prefix)

Without any argument, `bang' will behave like `shell-command'.

Before these characters, one may also place a relative or
absolute path, which will be the current working directory in
which the command will be executed.  See `bang-expand-path' for
more details on this expansion.

Inside COMMAND, % is replaced with the current file name.  To
insert a literal % quote it using a backslash.

In case a region is active, bang will only work with the region
between BEG and END.  Otherwise the whole buffer is processed."
  (interactive (list (read-shell-command "Shell command: ")
                     (if (use-region-p) (region-beginning) (point-min))
                     (if (use-region-p) (region-end) (point-max))))
  (save-match-data
    (unless (string-match bang--command-regexp command)
      (error "Invalid command"))
    (let* ((path (match-string-no-properties 1 command))
           (has-< (match-string-no-properties 2 command))
           (has-> (match-string-no-properties 3 command))
           (has-| (match-string-no-properties 4 command))
           (cmd (match-string-no-properties 6 command))
           (can-eshell (intern-soft (concat "eshell/" cmd)))
           (rest (condition-case nil
                     (replace-regexp-in-string
                      (rx (* ?\\ ?\\) (or ?\\ (group "%")))
                      buffer-file-name
                      (match-string-no-properties 5 command)
                      nil nil 1)
                   (error (match-string-no-properties 5 command)))))
      (let ((default-directory (bang-expand-path (or path "."))))
        (cond (has-< (delete-region beg end)
                     (shell-command rest t shell-command-default-error-buffer)
                     (exchange-point-and-mark))
              (has-> (shell-command-on-region
                      beg end rest nil nil
                      shell-command-default-error-buffer t))
              (has-| (shell-command-on-region
                      beg end rest t t
                      shell-command-default-error-buffer t))
              ((and bang-use-eshell can-eshell)
               (eshell-command rest (and current-prefix-arg t)))
              (t (shell-command rest (and current-prefix-arg t)
                                shell-command-default-error-buffer))))
      (when has->
        (with-current-buffer "*Shell Command Output*"
          (delete-region (point-min) (point-max)))))))

(make-obsolete 'bang
               "Use `shell-command+' from ELPA instead."
               "2020-09-28")

(provide 'bang)

;;; bang.el ends here
