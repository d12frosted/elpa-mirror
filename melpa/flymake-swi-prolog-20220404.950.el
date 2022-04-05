;;; flymake-swi-prolog.el --- A Flymake backend for SWI-Prolog -*- lexical-binding: t; -*-

;; Version: 0.2.2
;; Package-Version: 20220404.950
;; Package-Commit: ae0e4b706a40b71c007ed6cb0ec5425d49bea4c3
;; Author: Eshel Yaron
;; URL: https://git.sr.ht/~eshel/flymake-swi-prolog
;; Keywords: languages

;; Copyright 2022 Eshel Yaron

;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
;; LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
;; WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Package-Requires: ((emacs "26.1"))

;;; Commentary:

;; Provides a Flymake backend for SWI-Prolog source code.

;;; Code:


(require 'flymake)


(defgroup flymake-swi-prolog nil
  "Flymake checker for SWI-Prolog."
  :group 'programming
  :prefix "flymake-swi-prolog-")


(defcustom flymake-swi-prolog-executable-name "swipl"
  "Name of executable to run when checker is called.
Must be present in variable `exec-path'."
  :type 'string
  :group 'flymake-swi-prolog)


(defun flymake-swi-prolog--output-filter (report-fn output offset)
  "Filter function for handling and reporting diagnostics.
REPORT-FN is a function called to report diagnostics to the user
with Flymake.  OUTPUT is a string holding the diagnostics process
output.  OFFSET is an integer denoting the offset into OUTPUT
from which to start scanning for diagnotic messages."
  (let ((new-offset (string-match "^\\(.+\\):[[:space:]]+\\(.+\.pl\\):\\([0-9]+\\):\\([0-9]+\\):[[:space:]]+\\(.*\\)$"
                                  output
                                  offset)))
    (if new-offset
        (let* ((line-prefix (match-string 1 output))
               (path        (match-string 2 output))
               (locus       (or (find-buffer-visiting path) path))
               (beg         (+ 1   (string-to-number (match-string 3 output))))
               (end         (+ beg (string-to-number (match-string 4 output))))
               (text        (match-string 5 output))
               (type        (if (string-match "^Warning.*" line-prefix) :warning :error)))
          (when locus
            (funcall report-fn (list (flymake-make-diagnostic locus beg end type text))))
          (flymake-swi-prolog--output-filter report-fn output (+ 1 new-offset)))
      t)))


(defvar-local flymake-swi-prolog--proc nil)


(defun flymake-swi-prolog--checker (report-fn &rest _args)
  "Flymake backend function for SWI-Prolog.
REPORT-FN is the reporting function passed to backend by Flymake,
as documented in 'flymake-diagnostic-functions'"
  (when (process-live-p flymake-swi-prolog--proc)
    (kill-process flymake-swi-prolog--proc))
  (save-restriction
    (widen)
    (setq
     flymake-swi-prolog--proc
     (make-process
      :name "flymake-swi-prolog" :noquery t :connection-type 'pipe
      :command (list flymake-swi-prolog-executable-name "-q"
                     "-g" "use_module(library(diagnostics))"
                     "-t" "halt" "--" "-" buffer-file-name)
      :filter
      (lambda (_proc output)
        (flymake-swi-prolog--output-filter report-fn output nil))
      :sentinel
      (lambda (_proc _event)
        (funcall report-fn nil))))
    (process-send-region flymake-swi-prolog--proc (point-min) (point-max))
    (process-send-eof flymake-swi-prolog--proc)))


(defun flymake-swi-prolog-setup-backend ()
  "Setup routine for the SWI-Prolog Flymake checker."
  (add-hook 'flymake-diagnostic-functions #'flymake-swi-prolog--checker nil t))


(defun flymake-swi-prolog-ensure-diagnostics-pl ()
  "Install the underlying SWI-Prolog diagnostics package, if not already installed."
  (interactive)
  (make-process
   :name "flymake-swi-prolog-ensure-diagnostics-pl" :noquery t :connection-type 'pipe
   :buffer (generate-new-buffer "*flymake-swi-prolog-ensure-diagnostics-pl*")
   :command (list flymake-swi-prolog-executable-name "-q"
                  "-g" "pack_install(diagnostics, [interactive(false)])"
                  "-t" "halt")))


(provide 'flymake-swi-prolog)

;;; flymake-swi-prolog.el ends here
