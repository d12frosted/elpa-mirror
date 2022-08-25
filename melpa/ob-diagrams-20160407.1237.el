;;; ob-diagrams.el --- org-babel functions for diagrams evaluation

;; Copyright (C) 2013 Daniel Bergey

;; Author: Daniel Bergey
;; Keywords: literate programming, reproducible research
;; Package-Version: 20160407.1237
;; Package-Commit: be45815f5596d181592fae709096b7b5f4a71992
;; Homepage: http://orgmode.org

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; Org-Babel support for evaluating diagrams source code.
;;
;; This differs from most standard languages in that
;;
;; 1) we are generally only going to return results of type "file"
;;
;; 2) we are adding the "file" and "cmdline" header arguments

;;; Requirements:

;; - diagrams          :: http://projects.haskell.org/diagrams/
;; - diagrams-builder  :: http://hackage.haskell.org/package/diagrams-builder

;;; Code:
(require 'ob)

(defvar org-babel-default-header-args:diagrams
  '((:results . "file")
    (:exports . "results")
    (:width . 300))
  "Default arguments for drawing a diagrams image.")

(defcustom org-diagrams-executable "diagrams-builder-cairo"
  "Path to the diagrams-builder executable"
  :group 'org-babel
  :type  'string)

(add-to-list 'org-src-lang-modes '("diagrams" . haskell))

(defun org-babel-execute:diagrams (body params)
  (let ((out-file (cdr (assoc :file params)))
        (result-type (cdr (assoc :results params))))
    (save-window-excursion
      (let ((script-file (org-babel-temp-file "diagrams-input")))
        (with-temp-file script-file (insert body))
        (message "%s \"%s\"" org-diagrams-executable script-file)
        (let ((output (shell-command-to-string
                       (format
                        "%s \"%s\" -o\"%s\" -w%s"
                        org-diagrams-executable
                        (org-babel-process-file-name
                         script-file)
                        out-file
                        (cdr (assoc :width params))))))
          (message output))
        nil ;; signal that output has already been written to file
        ))))

(provide 'ob-diagrams)
;;; ob-diagrams.el ends here
