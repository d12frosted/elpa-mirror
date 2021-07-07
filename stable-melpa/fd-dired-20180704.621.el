;;; fd-dired.el --- find-dired alternative using fd  -*- lexical-binding: t; -*-

;; Copyright © 2018, Free Software Foundation, Inc.

;; Author: Rashawn Zhang <namy.19@gmail.com>
;; Created:  3 July 2018
;; Keywords: tools, fd, find, dired
;; Package-Version: 20180704.621
;; Package-Commit: d90ec902f417c194e44697f73a9d6cbfd0cf7216

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

;;  Provide a dired-mode interface for fd's result. Same functionality as
;;  find-dired, use fd instead. Depend on find-dired

;; Just call `fd-dired'.

;;; Code:

(require 'find-dired)
(defvar fd-program "fd")
(defvar pre-fd-args "-0 -c never")
(defvar fd-ls-option '("| xargs -0 ls -ld" . "-ld"))
(defvar input-fd-args "")
(defvar fd-args-history nil)

;;;###autoload
(defun fd-dired (dir args)
  "Run `fd' and go into Dired mode on a buffer of the output.
The command run (after changing into DIR) is essentially

    fd . ARGS -ls

except that the car of the variable `fd-ls-option' specifies what to
use in place of \"-ls\" as the final argument."
  (interactive (list (and current-prefix-arg (read-directory-name "Run fd in directory: " nil "" t))
                     (read-string "Run fd (with args): " input-fd-args
                                  '(fd-args-history . 1))))
  (let ((dired-buffers dired-buffers))
    ;; Expand DIR ("" means default-directory), and make sure it has a
    ;; trailing slash.
    (setq dir (file-name-as-directory (expand-file-name (or dir default-directory))))
    ;; Check that it's really a directory.
    (or (file-directory-p dir)
        (error "fd-dired needs a directory: %s" dir))
    (switch-to-buffer (get-buffer-create "*Fd*"))

    ;; See if there's still a `fd' running, and offer to kill
    ;; it first, if it is.
    (let ((fd (get-buffer-process (current-buffer))))
      (when fd
        (if (or (not (eq (process-status fd) 'run))
                (yes-or-no-p
                 (format-message "A `fd' process is running; kill it? ")))
            (condition-case nil
                (progn
                  (interrupt-process fd)
                  (sit-for 1)
                  (delete-process fd))
              (error nil))
          (error "Cannot have two processes in `%s' at once" (buffer-name)))))

    (widen)
    (kill-all-local-variables)
    (setq buffer-read-only nil)
    (erase-buffer)
    (setq default-directory dir
          input-fd-args args        ; save for next interactive call
          args (concat fd-program " " pre-fd-args
                       ;; " . "
                       (if (string= args "")
                           ""
                         (concat
                          " " args " "
                          " "))
                       (if (string-match "\\`\\(.*\\) {} \\(\\\\;\\|+\\)\\'"
                                         (car fd-ls-option))
                           (format "%s %s %s"
                                   (match-string 1 (car fd-ls-option))
                                   (shell-quote-argument "{}")
                                   find-exec-terminator)
                         (car fd-ls-option))))
    ;; Start the find process.
    (shell-command (concat args "&") (current-buffer))
    ;; The next statement will bomb in classic dired (no optional arg allowed)
    (dired-mode dir (cdr fd-ls-option))
    (let ((map (make-sparse-keymap)))
      (set-keymap-parent map (current-local-map))
      (define-key map "\C-c\C-k" 'kill-find)
      (use-local-map map))
    (make-local-variable 'dired-sort-inhibit)
    (setq dired-sort-inhibit t)
    (set (make-local-variable 'revert-buffer-function)
         `(lambda (ignore-auto noconfirm)
            (fd-dired ,dir ,input-fd-args)))
    ;; Set subdir-alist so that Tree Dired will work:
    (if (fboundp 'dired-simple-subdir-alist)
        ;; will work even with nested dired format (dired-nstd.el,v 1.15
        ;; and later)
        (dired-simple-subdir-alist)
      ;; else we have an ancient tree dired (or classic dired, where
      ;; this does no harm)
      (set (make-local-variable 'dired-subdir-alist)
           (list (cons default-directory (point-min-marker)))))
    (set (make-local-variable 'dired-subdir-switches) find-ls-subdir-switches)
    (setq buffer-read-only nil)
    ;; Subdir headlerline must come first because the first marker in
    ;; subdir-alist points there.
    (insert "  " dir ":\n")
    ;; Make second line a ``find'' line in analogy to the ``total'' or
    ;; ``wildcard'' line.
    (let ((point (point)))
      (insert "  " args "\n")
      (dired-insert-set-properties point (point)))
    (setq buffer-read-only t)
    (let ((proc (get-buffer-process (current-buffer))))
      (set-process-filter proc (function find-dired-filter))
      (set-process-sentinel proc (function find-dired-sentinel))
      ;; Initialize the process marker; it is used by the filter.
      (move-marker (process-mark proc) (point) (current-buffer)))
    (setq mode-line-process '(":%s"))))

(provide 'fd-dired)
;;; fd-dired.el ends here
