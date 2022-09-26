;;; flymake-sqlfluff.el --- A flymake plugin for SQL files using sqlfluff

;; Copyright © 2022 Erick Navarro
;; Author: Erick Navarro <erick@navarro.io>
;; URL: https://github.com/erickgnavar/flymake-sqlfluff
;; Package-Version: 20220925.2144
;; Package-Commit: b76f335555c9a94ffc3d7281f3dca345de474eed
;; Version: 0.1.0
;; SPDX-License-Identifier: GPL-3.0-or-later
;; Package-Requires: ((emacs "27.1"))

;;; Commentary:

;; Usage:
;;   (require 'flymake-sqlfluff)
;;   (add-hook 'sql-mode-hook #'flymake-sqlfluff-load)

;;; Code:

(defcustom flymake-sqlfluff-program "sqlfluff"
  "Path to program sqlfluff."
  :group 'flymake-sqlfluff
  :type 'string)

(defvar flymake-sqlfluff--dialect-options '("ansi" "athena" "bigquery" "clickhouse" "databricks" "db2" "exasol" "hive" "mysql" "oracle" "postgres" "redshift" "snowflake" "soql" "sparksql" "sqlite" "teradata" "tsql")
  "List of supported dialects.")

(defcustom flymake-sqlfluff-dialect "postgres"
  "List of possible dialect to be checked."
  :group 'flymake-sqlfluff
  :options flymake-sqlfluff--dialect-options
  :type 'list)

;;;###autoload
(defun flymake-sqlfluff-change-dialect ()
  "Change sqlfluff dialect."
  (interactive)
  (setq flymake-sqlfluff-dialect (completing-read "Choose dialect: " flymake-sqlfluff--dialect-options)))

;;;###autoload
(defun flymake-sqlfluff-load ()
  "Load hook for the current buffer to tell flymake to run checker."
  (interactive)
  (add-hook 'flymake-diagnostic-functions #'flymake-sqlfluff--run-checker nil t))

(defun flymake-sqlfluff--run-checker (report-fn &rest _args)
  "Run checker using REPORT-FN."
  (funcall report-fn (flymake-sqlfluff--check-buffer)))

(defun flymake-sqlfluff-process-item (item)
  "Build a flymake diagnostic using ITEM data."
  (let* ((line (gethash "line_no" item))
         (column (gethash "line_pos" item))
         (error-point (flymake-sqlfluff--get-position line column))
         (description (gethash "description" item)))
    (flymake-make-diagnostic (current-buffer) error-point (1+ error-point) :error description)))

(defun flymake-sqlfluff--check-buffer ()
  "Generate a list of diagnostics for the current buffer."
  (flatten-list (mapcar (lambda (node) (mapcar #'flymake-sqlfluff-process-item (gethash "violations" node))) (json-parse-string (flymake-sqlfluff--get-raw-report)))))

(defun flymake-sqlfluff--get-position (line column)
  "Calculate position for the given LINE and COLUMN."
  (save-excursion
    (goto-char (point-min))
    (forward-line (1- line))
    (move-to-column column)
    (point)))

(defun flymake-sqlfluff--get-raw-report ()
  "Run sqlfluff on the current buffer and return a raw report."
  (let ((temp-file (concat (make-temp-file "sqlfluff") ".sql")))
    (write-region (point-min) (point-max) temp-file nil 'quiet)
    (shell-command-to-string (format "%s lint --dialect %s -f json %s" (shell-quote-argument flymake-sqlfluff-program) (shell-quote-argument flymake-sqlfluff-dialect) temp-file))))

(provide 'flymake-sqlfluff)
;;; flymake-sqlfluff.el ends here
