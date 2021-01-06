;;; winnow.el --- winnow ag/grep results by matching/excluding lines -*- lexical-binding: t; -*-

;; Copyright (C) 2017-2021  Charles L.G. Comstock

;; Author: Charles L.G. Comstock <dgtized@gmail.com>
;; Created: 3 Sept 2017
;; Version: 0.1
;; Package-Version: 20210105.1919
;; Package-Commit: 761b15bc31696a4f80c5fd508c84b1f5b4190ec2
;; URL: https://github.com/dgtized/winnow.el
;; Keywords: matching
;; Package-Requires: ((emacs "24"))

;; This program is free software; you can redistribute it and/or modify
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

;; Winnow `compilation-mode' results by matching or excluding lines from the
;; results. Normally these buffers are `read-only-mode', preventing the use of
;; editing commands, but `winnow-mode' commands inhibits this to apply
;; `flush-line' or `keep-lines' on the command output.
;;
;; As the edits are to the buffer, `recompile' is the recommended way to
;; regenerate the search.
;;
;; The main use case for this is filtering `ag-mode' search results in the
;; buffer to separate the wheat from the chaff.

;;; Usage:

;; Enable the package in `ag-mode' with the following:
;;
;;  (add-hook 'ag-mode-hook 'winnow-mode)

;;; Todo:

;; * Possibly use grep on ag command output?
;; * Expand to work on ack, git-grep, rgrep results

;;; Code:

(require 'compile)

(defun winnow-results-start ()
  "Find the start position of the compilation output."
  (save-excursion
    (goto-char (point-min))
    (compilation-next-error 1)
    (point-at-bol 1)))

(defun winnow-results-end ()
  "Find the end position of the compilation output."
  (save-excursion
    (goto-char (point-max))
    (compilation-next-error -1)
    (point-at-bol 2)))

(defun winnow-exclude-lines (regexp &optional rstart rend interactive)
  "Exclude the REGEXP matching lines from the compilation results.

Ignores read-only-buffer to exclude lines from a result.

See `flush-lines' for additional details about arguments REGEXP,
RSTART, REND, INTERACTIVE."
  (interactive (keep-lines-read-args "Flush lines containing match for regexp"))
  (let ((inhibit-read-only t)
        (start (or rstart (winnow-results-start)))
        (end (or rend (winnow-results-end))))
    (flush-lines regexp start end interactive)
    (goto-char (point-min))))

(defun winnow-match-lines (regexp &optional rstart rend interactive)
  "Limit the compilation results to the lines matching REGEXP.

Ignores read-only-buffer to focus on matching lines from a
result.

See `keep-lines' for additional details about arguments REGEXP,
RSTART, REND, INTERACTIVE."
  (interactive (keep-lines-read-args "Keep lines containing match for regexp"))
  (let ((inhibit-read-only t)
        (start (or rstart (winnow-results-start)))
        (end (or rend (winnow-results-end))))
    (keep-lines regexp start end interactive)
    (goto-char (point-min))))

;;;###autoload
(define-minor-mode winnow-mode
  "Filter compilation results by matching/excluding lines.

This is invaluable for excluding or limiting to matching `ag-mode' results.

\\{winnow-mode-map}"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "x") 'winnow-exclude-lines)
            (define-key map (kbd "m") 'winnow-match-lines)
            map))

(provide 'winnow)
;;; winnow.el ends here
