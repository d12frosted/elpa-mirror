;;; flymake-racket.el --- Flymake extension for Racket. -*- lexical-binding: t -*-

;; Copyright (C) 2018 James Nguyen

;; Authors: James Nguyen <james@jojojames.com>
;; Maintainer: James Nguyen <james@jojojames.com>
;; URL: https://github.com/jojojames/flymake-racket
;; Package-Version: 20210105.606
;; Package-Commit: 3d3e5f2a9ab696670f9e52baa4dde7b84b7542df
;; Version: 1.0
;; Package-Requires: ((emacs "26.1"))
;; Keywords: languages racket scheme

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
;; Flymake extension for Racket.
;;
;; (with-eval-after-load 'flymake
;;   (flymake-racket-setup))

;;; Code:

(require 'flymake)
(require 'cl-lib)
(eval-when-compile (require 'subr-x))

;;; Flymake

(defcustom flymake-racket-executable "raco"
  "Executable for racket."
  :type 'string
  :group 'flymake-racket)

(defcustom flymake-racket-args '("expand")
  "Args to pass to racket."
  :type 'list
  :group 'flymake-racket)

(defvar-local flymake-racket--lint-process nil
  "Buffer-local process started for linting the buffer.")

(defvar flymake-racket-raco-has-expand-p nil
  "Boolean to check if `flymake-racket-executable' contains expand.")

;;;###autoload
(defun flymake-racket-setup ()
  "Set up Flymake for Racket."
  (interactive)
  (add-hook 'racket-mode-hook #'flymake-racket-add-hook)
  (add-hook 'scheme-mode-hook #'flymake-racket-add-hook))

;;;###autoload
(defun flymake-racket-add-hook ()
  "Add `flymake-racket-lint' to `flymake-diagnostic-functions'."
  ;; Checking if raco expand exists is really slow (200ms~), so
  ;; try to do it using the `async' library.
  (cond
   ((not (executable-find flymake-racket-executable))
    (message (format "%s not found, not using `flymake-racket'."
                     flymake-racket-executable))
    :do-nothing)
   ((and
     (fboundp 'async-start)
     (eq flymake-racket-raco-has-expand-p nil))
    (let ((buffer (current-buffer)))
      (async-start
       `(lambda ()
          (load ,(locate-library "flymake-racket"))
          (require 'flymake-racket)
          (flymake-racket--check-shell-raco-expand))
       `(lambda (result)
          (setq flymake-racket-raco-has-expand-p (if result 'yes 'no))
          (with-current-buffer ,buffer
            (flymake-racket-add-hook)
            ;; Because we did this asynchronously, we should explicitly
            ;; start a syntax check.. but only if `flymake-start-on-flymake-mode'
            ;; is t.
            (when flymake-start-on-flymake-mode
              (flymake-start)))))))
   (:else
    (when (flymake-racket--raco-has-expand)
      (add-hook 'flymake-diagnostic-functions
                'flymake-racket-lint-if-possible nil t)))))

(defun flymake-racket-lint-if-possible (report-fn &rest args)
  "Run `flymake-racket-lint' if possible.

REPORT-FN is called when `flymake-racket-lint' runs.

ARGS is passed straight through to `flymake-racket-lint'."
  (when (or
         (eq major-mode 'racket-mode)
         (and (eq major-mode 'scheme-mode)
              (boundp 'geiser-impl--implementation)
              (eq geiser-impl--implementation 'racket)))
    (apply #'flymake-racket-lint report-fn args)))

(defun flymake-racket-lint (report-fn &rest _args)
  "A Flymake backend for racket check.

REPORT-FN will be called when racket process finishes."
  (when (and flymake-racket--lint-process
             (process-live-p flymake-racket--lint-process))
    (kill-process flymake-racket--lint-process))
  (let ((source-buffer (current-buffer))
        (output-buffer (generate-new-buffer " *flymake-racket-lint*")))
    (setq flymake-racket--lint-process
          (make-process
           :name "flymake-racket-lint"
           :buffer output-buffer
           :command `(,flymake-racket-executable
                      ,@flymake-racket-args
                      ,buffer-file-name)
           :connection-type 'pipe
           :sentinel
           (lambda (proc _event)
             (when (eq (process-status proc) 'exit)
               (unwind-protect
                   (cond
                    ((not (and (buffer-live-p source-buffer)
                               (eq proc (with-current-buffer source-buffer
                                          flymake-racket--lint-process))))
                     (flymake-log :warning
                                  "racket process %s obsolete" proc))
                    ((zerop (process-exit-status proc))
                     ;; No racket errors/warnings..
                     (funcall report-fn nil))
                    ((= 1 (process-exit-status proc))
                     (flymake-racket--lint-done report-fn
                                                source-buffer
                                                output-buffer))
                    (:error
                     (funcall report-fn
                              :panic
                              :explanation
                              (format "racket process %s errored." proc))))
                 (kill-buffer output-buffer))))))))

;; Helpers
(defun flymake-racket--lint-done (report-fn
                                  source-buffer
                                  output-buffer)
  "Process racket result and call REPORT-FN.

SOURCE-BUFFER is the buffer to apply flymake to.
OUTPUT-BUFFER is the result of running racket on SOURCE-BUFFER."
  (with-current-buffer
      source-buffer
    (save-excursion
      (save-restriction
        (widen)
        (funcall
         report-fn
         (with-current-buffer output-buffer
           (let* ((result '()) ;; Accumulate results here.
                  (lines (split-string (buffer-string) "\n" t))
                  (numLines (length lines))
                  (i 0)
                  (source-buffer-name
                   (with-current-buffer source-buffer
                     (file-name-nondirectory buffer-file-name))))
             ;; Example error message:
             ;; racket_file.rkt:24:0: read-syntax: expected a `)` to close `(`
             ;; possible cause: indentation suggests a missing `)` before line 34
             (while (< i numLines)
               ;; Filter out messages that don't match buffer name.
               (when (string-prefix-p source-buffer-name (nth i lines))
                 (let* ((line (nth i lines))
                        (split (split-string line ":" t))
                        (_ (nth 0 split)) ; filename
                        (line (string-to-number (nth 1 split)))
                        (column (string-to-number (nth 2 split)))
                        (message (mapconcat (lambda (str) str)
                                            (cdddr split)
                                            ""))
                        (point (flymake-racket--find-point
                                source-buffer
                                line
                                column)))
                   (when (and (< (1+ i) numLines)
                              (string-match-p "possible cause"
                                              (nth (1+ i) lines)))
                     (setq message (concat message "\n" (nth (1+ i) lines)))
                     ;; Skip next line when processing.
                     (setq i (1+ i)))
                   ;; Accumulate the result.
                   (push (flymake-make-diagnostic source-buffer
                                                  point
                                                  (1+ point)
                                                  :warning
                                                  message)
                         result)))
               (setq i (1+ i)))
             result)))))))

(defun flymake-racket--find-point (source-buffer line column)
  "Return point given LINE and COLUMN in SOURCE-BUFFER."
  (with-current-buffer source-buffer
    (save-excursion
      (goto-char (point-min))
      (forward-line (1- line))
      (move-to-column column)
      (point))))

(defun flymake-racket--raco-has-expand ()
  "Check if raco has expand."
  (cond
   ((eq flymake-racket-raco-has-expand-p 'yes) t)
   ((eq flymake-racket-raco-has-expand-p 'no) nil)
   (:default
    (setq flymake-racket-raco-has-expand-p
          (flymake-racket--check-shell-raco-expand))
    (if flymake-racket-raco-has-expand-p
        (setq flymake-racket-raco-has-expand-p 'yes)
      (setq flymake-racket-raco-has-expand-p 'no))
    (flymake-racket--raco-has-expand))))

(defun flymake-racket--check-shell-raco-expand ()
  "Check if raco has expand using `call-process'."
  (with-temp-buffer
    (call-process flymake-racket-executable nil t nil "expand")
    (goto-char (point-min))
    (not (looking-at-p
          (rx bol (1+ not-newline)
              "Unrecognized command: expand"
              eol)))))

(provide 'flymake-racket)
;;; flymake-racket.el ends here
