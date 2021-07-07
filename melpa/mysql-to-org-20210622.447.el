;;; mysql-to-org.el --- Minor mode to output the results of mysql queries to org tables -*- lexical-binding: t -*-

;; Copyright © 2016 Tijs Mallaerts
;;
;; Author: Tijs Mallaerts <tijs.mallaerts@gmail.com>

;; Package-Requires: ((emacs "24.3") (s "1.11.0"))
;; Package-Version: 20210622.447
;; Package-Commit: c5eefc71200f2e1d0d67a13ed897b3cdfa835117

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

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Minor mode to output the results of mysql queries to org tables.
;; C-c C-m e will output the query inside the active region or current line to an org table.
;; C-c C-m p will output the query defined by the string at point to an org table.
;; C-c C-m s will open a mysql to org scratch buffer.

;;; Code:

(require 'org)
(require 's)
(require 'comint)
(require 'sql)
(require 'cl-lib)

(defvar mysql-to-org-mode-line-text " m->o")

(defgroup mysql-to-org nil
  "Mysql to org customizations."
  :group 'processes)

(defcustom mysql-to-org-mysql-command "mysql"
  "Path to the mysql command."
  :type 'string
  :group 'mysql-to-org)

(defcustom mysql-to-org-mysql-user "root"
  "The mysql user."
  :type 'string
  :group 'mysql-to-org)

(defcustom mysql-to-org-parameter-regexp ":\\w+"
  "Regexp for finding parameters inside a sql query."
  :type 'string
  :group 'mysql-to-org)

(defcustom mysql-to-org-display-output-buffer-below-selected nil
  "If non-nil the output buffer will be displayed below the selected window."
  :type 'boolean
  :group 'mysql-to-org)

(defcustom mysql-to-org-query-parts-requiring-confirmation '("DROP")
  "List of strings for which a confirmation will be asked if the query contains one of them."
  :type '(repeat string)
  :group 'mysql-to-org)

(defvar mysql-to-org-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-m e") 'mysql-to-org-eval)
    (define-key map (kbd "C-c C-m p") 'mysql-to-org-eval-string-at-point)
    (define-key map (kbd "C-c C-m s") 'mysql-to-org-scratch)
    (define-key map (kbd "C-c C-m 1") 'mysql-to-org-only-show-output-window)
    (define-key map (kbd "C-c C-m r") 'mysql-to-org-reload-completion-candidates)
    map))

(defvar mysql-to-org-output-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "q") 'kill-this-buffer)
    map))

(defun mysql-to-org--remove-control-m-from-string (str)
  "Remove ^M characters from STR."
  (replace-regexp-in-string (char-to-string 13) "" str))

(defun mysql-to-org--eval-process-filter (proc str)
  "The evaluation filter for the mysql to org PROC.
STR is the output string of the PROC."
  (let* ((buf (get-buffer-create "mysql-to-org-output"))
         (inhibit-message t))
    (with-current-buffer buf
      (org-mode)
      (mysql-to-org-output-mode)
      (if (or (string-match-p "mysql>" str)
              (string-match-p "MariaDB \\[" str))
          (progn (insert (mysql-to-org--remove-control-m-from-string str))
                 (save-excursion
                   (goto-char (point-min))
                   (replace-string "    -> " "" nil (point-min) (point-max))
                   (when (re-search-forward "+" (point-max) t)
                     (beginning-of-line)
                     (delete-region (line-beginning-position)
                                    (line-end-position))
                     (forward-line 2)
                     (delete-region (line-beginning-position)
                                    (line-end-position))
                     (insert "|--")
                     (org-cycle))
                   (goto-char (point-min))
                   (search-forward ";" nil t)
                   (unless (= (point) (point-min))
                     (let ((query (buffer-substring-no-properties (point-min)
                                                                  (point))))
                       (delete-region (point-min) (point))
                       (insert (concat (s-trim (s-collapse-whitespace query)))))))
                 (goto-char (point-max))
                 (beginning-of-line)
                 (delete-region (line-beginning-position)
                                (line-end-position))
                 (mysql-to-org--refresh-lighter))
        (insert (mysql-to-org--remove-control-m-from-string str))))))

(defun mysql-to-org--completion-process-filter (proc str)
  "The completion filter for the mysql to org PROC.
STR is the output string of the PROC."
  (with-current-buffer (get-buffer-create "mysql-to-org-completion")
    (insert str)))

(defun mysql-to-org--refresh-lighter-process-filter (proc str)
  "The refresh lighter filter for the mysql to org PROC.
STR is the output string of the PROC containing the currently
selected database."
  (let ((selected-db (if (s-contains-p "SHOW DATABASES" str)
                         (nth 8 (split-string str))
                       (nth 6 (split-string str)))))
    (setq mysql-to-org-mode-line-text (concat " m->o[" selected-db "]"))
    (force-mode-line-update)))

(defun mysql-to-org--load-completion-candidates ()
  "Load completion candidates into mysql-to-org-completion buffer."
  (let* ((proc (get-process "mysql-to-org")))
    (while (not proc)
      (setq proc (get-process "mysql-to-org")))
    (set-process-filter proc
                        'mysql-to-org--completion-process-filter)
    (process-send-string proc "SELECT DISTINCT TABLE_NAME FROM information_schema.tables;\n")
    (process-send-string proc "SELECT DISTINCT COLUMN_NAME FROM information_schema.columns;\n")
    (process-send-string proc "SHOW DATABASES;\n")))

(defun mysql-to-org--refresh-lighter ()
  "Refresh the currently selected database in the lighter."
  (let* ((proc (get-process "mysql-to-org")))
    (while (not proc)
      (setq proc (get-process "mysql-to-org")))
    (set-process-filter proc
                        'mysql-to-org--refresh-lighter-process-filter)
    (process-send-string proc "SELECT DATABASE();\n")))

(defun mysql-to-org-complete-at-point ()
  "Complete the symbol at point."
  (when-let ((bounds (bounds-of-thing-at-point 'symbol)))
    (list (car bounds)
          (cdr bounds)
          (mapcar 'car
                  (with-current-buffer (get-buffer "mysql-to-org-completion")
                    (s-match-strings-all "\\_<[a-z|_|0-9]*+\\_>"
                                         (buffer-substring-no-properties
                                          (point-min) (point-max)))))
          :exclusive 'no)))

(defun mysql-to-org--replace-query-params (query)
  "Replace the parameters of the QUERY by values supplied by the user."
  (let* ((matches (s-match-strings-all mysql-to-org-parameter-regexp query))
         (replacements (mapcar (lambda (x)
                                 (cons (car x)
                                       (read-string (concat "value for "
                                                            (car x)
                                                            " => "))))
                               matches)))
    (if matches
        (s-replace-all replacements query)
      query)))

(defun mysql-to-org--start-process ()
  "Start the mysql to org mysql process."
  (when (not (get-process "mysql-to-org"))
    (make-comint "mysql-to-org" mysql-to-org-mysql-command nil
                 (concat "-u" mysql-to-org-mysql-user)
                 (concat "-p" (read-passwd "mysql passwd: ")))
    (mysql-to-org--load-completion-candidates)))

(defun mysql-to-org--mark-string-at-point ()
  "Mark the contents of the string at point."
  (let ((ppss (syntax-ppss)))
    (when (nth 3 ppss)
      (let* ((sexp-beg (nth 8 ppss))
             (sexp-end (progn (goto-char sexp-beg)
                              (forward-sexp)
                              (point))))
        (push-mark (+ sexp-beg 1))
        (goto-char (- sexp-end 1))
        (exchange-point-and-mark)))))

(defun mysql-to-org-only-show-output-window ()
  "Switch to the output window and delete all other windows."
  (interactive)
  (switch-to-buffer "mysql-to-org-output")
  (delete-other-windows))

(defun mysql-to-org-reload-completion-candidates ()
  "Reloads the completion candidates."
  (interactive)
  (with-current-buffer (get-buffer-create "mysql-to-org-completion")
    (erase-buffer))
  (mysql-to-org--load-completion-candidates))

;;;###autoload
(defun mysql-to-org-eval ()
  "Evaluate the query inside the active region or current line."
  (interactive)
  (save-excursion
    (let* ((proc (get-process "mysql-to-org"))
           (reg-beg (if (region-active-p)
                        (region-beginning)
                      (line-beginning-position)))
           (reg-end (if (region-active-p)
                        (region-end)
                      (line-end-position)))
           (region (buffer-substring-no-properties reg-beg reg-end))
           (replace (replace-regexp-in-string ";" "" region))
           (query (concat (s-trim replace) ";\n"))
           (confirmation-needed? (and mysql-to-org-query-parts-requiring-confirmation
                                      (member t (mapcar (lambda (s)
                                                          (s-contains? s query t))
                                                        mysql-to-org-query-parts-requiring-confirmation)))))
      (if (or (not confirmation-needed?)
              (y-or-n-p "Are you sure you want to execute the query? "))
          (progn (set-process-filter proc
                                     'mysql-to-org--eval-process-filter)
                 (with-current-buffer (get-buffer-create "mysql-to-org-output")
                   (erase-buffer))
                 (process-send-string proc (mysql-to-org--replace-query-params query))
                 (if mysql-to-org-display-output-buffer-below-selected
                     (display-buffer-below-selected (get-buffer "mysql-to-org-output") '())
                   (display-buffer "mysql-to-org-output")))
        (message "%s" "Query canceled")))))

;;;###autoload
(defun mysql-to-org-eval-string-at-point ()
  "Evaluate the string at point."
  (interactive)
  (save-excursion
    (mysql-to-org--mark-string-at-point)
    (mysql-to-org-eval)))

;;;###autoload
(defun mysql-to-org-scratch ()
  "Open mysql to org scratch buffer."
  (interactive)
  (get-buffer-create "*mysql-to-org-scratch*")
  (switch-to-buffer "*mysql-to-org-scratch*")
  (sql-mode)
  (sql-set-product 'mysql)
  (mysql-to-org-mode))

;;;###autoload
(define-minor-mode mysql-to-org-mode
  "Minor mode to output the results of mysql queries to org tables."
  :lighter mysql-to-org-mode-line-text
  :keymap mysql-to-org-mode-map
  :after-hook (progn (mysql-to-org--start-process)
                     (setq-local completion-at-point-functions
                                 (append completion-at-point-functions
                                         '(mysql-to-org-complete-at-point)))))

(define-minor-mode mysql-to-org-output-mode
  "Minor mode for the mysql-to-org output buffer."
  :lighter " mysql->org-output"
  :keymap mysql-to-org-output-mode-map)

(provide 'mysql-to-org)

;;; mysql-to-org.el ends here
