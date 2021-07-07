;;; logstash-conf.el --- basic mode for editing logstash configuration

;; Copyright (C) 2014 Wilfred Hughes <me@wilfred.me.uk>
;;
;; Author: Wilfred Hughes <me@wilfred.me.uk>
;; Created: 21 October 2014
;; Version: 0.5
;; Package-Version: 20210123.1949
;; Package-Commit: ebc4731c45709ad1e0526f4f4164020ae83cbeff

;;; Commentary:

;; Basic syntax highlighting and indentation for Logtash configuration
;; files. Does a better job than `conf-unix-mode', at least.

;;; License:

;; This file is not part of GNU Emacs.
;; However, it is distributed under the same license.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:
(defgroup logstash nil
  "Major mode for editing Logstash configuration files."
  :group 'languages)

(defcustom logstash-indent 4
  "Indentation offset for `logstash-conf-mode'."
  :group 'logstash
  :type 'integer)

(defun logstash--open-paren-count ()
  "Return the number of open brackets before point."
  (nth 0 (syntax-ppss)))

(defun logstash-indent-line ()
  "Indent the current line."
  (interactive)
  (let ((initial-column (current-column))
        initial-indentation
        correct-indentation-level)
    ;; Get the current indentation
    (back-to-indentation)
    (setq initial-indentation (current-column))

    ;; Remove it.
    (while (not (zerop (current-column)))
      (delete-char -1))

    ;; Step over trailing close curlies before counting.
    (save-excursion
      (while (looking-at "}")
        (forward-char 1))

      (setq correct-indentation-level (logstash--open-paren-count)))

    ;; Replace with the correct indentation.
    (dotimes (_ (* logstash-indent correct-indentation-level))
      (insert " "))

    ;; Restore point at the same offset on this line.
    (let ((point-offset (- initial-column initial-indentation)))
      (when (> point-offset 0)
        (forward-char point-offset)))))

(defvar logstash-conf-mode-font-lock-keywords
  `((,(regexp-opt '("if" "else" "in" "not" "and" "or" "nand" "xor") 'symbols)
     . font-lock-keyword-face)
    (,(regexp-opt '("input" "filter" "output") 'symbols)
     . font-lock-builtin-face)
    (,(regexp-opt '("true" "false") 'symbols)
     . font-lock-constant-face)
    ("\\<\\([a-z_]+\\)\\>\s*{" 1 font-lock-function-name-face)
    ("\\[[a-z0-9@_.-]+\\]" . font-lock-variable-name-face)))

(defvar logstash-conf-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; Treat # as a single-line comment.
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">" table)

    ;; Single and double-quoted strings.
    (modify-syntax-entry ?\" "\"" table)
    (modify-syntax-entry ?\\ "\\" table)
    (modify-syntax-entry ?' "\"" table)

    table))

;;;###autoload
(define-derived-mode logstash-conf-mode prog-mode "Logstash"
  "Major mode for editing logstash configuration files.

\\{logstash-conf-mode-map\\}"
  (setq font-lock-defaults '(logstash-conf-mode-font-lock-keywords))
  (setq-local indent-line-function #'logstash-indent-line)
  (setq-local comment-start "# "))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.logstash\\'" . logstash-conf-mode))

;;;###autoload
(add-to-list 'interpreter-mode-alist '("logstash" . logstash-conf-mode))

(provide 'logstash-conf)
;;; logstash-conf.el ends here
