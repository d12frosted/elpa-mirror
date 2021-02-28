;;; ob-reticulate.el --- Babel Functions for reticulate -*- lexical-binding: t; -*-

;; Author: Jack Kamm
;; Keywords: literate programming, reproducible research, R, Python, statistics, languages, outlines, processes
;; Package-Version: 20210214.2229
;; Package-Commit: 8109fb02fb6339b1cf9290df29fc0c1109a33c04
;; Package-Requires: ((org "9.4") (emacs "24.4"))
;; Homepage: https://github.com/jackkamm/ob-reticulate
;; Version: 1.0.0

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.


;;; Commentary:

;; Org-Babel support for the R package reticulate, which enables use
;; of Python within R.

;;; Code:

(require 'ob-R)
(require 'ob-python)

(defun ob-reticulate-advice (orig-fun body params)
  "Advice to use ob-python blocks with R reticulate.
ORIG-FUN must be `org-babel-execute:python'.  BODY and PARAMS are
the arguments of that function."
  (let* ((session (cdr (assq :session params)))
         (session-mode
          (and session
             (not (string= session "none"))
             (let ((session-buffer (get-buffer session)))
               (and session-buffer
                    (with-current-buffer session-buffer
                      major-mode))))))
    (if (not (eq session-mode 'inferior-ess-r-mode))
        (funcall orig-fun body params)
      (let* ((tmp-src-file (org-babel-temp-file "reticulate-"))
	     (result-type (cdr (assq :result-type params))))
        (with-temp-file tmp-src-file (insert body))
        (org-babel-execute:R
         (concat (format
                  "reticulate::py_run_string(\"%s\")"
                  (org-babel-python-format-session-value
                   tmp-src-file
                   (org-babel-process-file-name
                    (org-babel-temp-file "reticulate-dummy-") 'noquote)
                   nil))
		 (when (equal result-type 'value) "
reticulate::py$`__org_babel_python_final`"))
         params)))))

;;;###autoload
(define-minor-mode ob-reticulate-mode
  "Toggle to enable ob-reticulate-mode.

When enabled, the :session header argument of ob-python blocks
may be an R session.  Note the R session should have the reticulate
library loaded before executing ob-python blocks with it.

Also, note that ob-reticulate blocks use header arguments for
`ob-R' instead of `ob-python'.  For example, the :colnames and
:rownames headers, which are available in ob-R but not ob-python,
can be used with Python blocks executed by ob-reticulate."
  :global t
  (if ob-reticulate-mode
      (advice-add
       #'org-babel-execute:python :around #'ob-reticulate-advice)
    (advice-remove #'org-babel-execute:python #'ob-reticulate-advice)))

(provide 'ob-reticulate)

;;; ob-reticulate.el ends here
