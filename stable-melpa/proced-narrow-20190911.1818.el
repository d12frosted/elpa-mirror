;;; proced-narrow.el --- Live-narrowing of search results for proced. -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Travis Jeffery

;; Author: Travis Jeffery <tj@travisjeffery.com>
;; Maintainer: Travis Jeffery <tj@travisjeffery.com>
;; URL: https://github.com/travisjeffery/proced-narrow
;; Package-Version: 20190911.1818
;; Package-Commit: 0e2a4dfb072eb0369d0020b429e820ae620d325e
;; Keywords: processes, proced
;; Created: 15th July 2019
;; Version: 1.0.5
;; Package-requires: ((seq "2.20") (emacs "24"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This package provides live filtering of processes in proced buffers.  Open proced, call
;; proced-narrow, and type the query to filter the processes with.  If you type "emacs" then
;; proced-narrow will filter the processes listed to only the Emacs processes.  While in the
;; minibuffer, typing RET will exit the minibuffer and leave the proced buffer in the narrowed
;; state, and typing C-g will exit the minibuffer and restore the list of processes.  While in the
;; proced buffer, to bring back all processes, call revert-buffer (default bind is g).

;;; Code:

(require 'proced)
(require 'seq)
(require 'delsel)

(defvar proced-narrow-buffer nil
  "Proced buffer we are currently filtering.")

(defvar proced-narrow--minibuffer-content ""
  "Content of the minibuffer during narrowing.")

(defvar proced-narrow-filter-function 'identity
  "Filter function used to filter the proced view.")

(defgroup proced-narrow ()
  "Live-narrowing of search results for proced."
  :group 'proced-hacks
  :prefix "proced-narrow-")

;;;###autoload
(defvar proced-narrow-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-g") 'minibuffer-keyboard-quit)
    (define-key map (kbd "RET") 'exit-minibuffer)
    (define-key map (kbd "<return>") 'exit-minibuffer)
    map)
  "Keymap used while `proced-narrow' is reading the pattern.")

;;;###autoload
(defun proced-narrow ()
  "Narrow a proced buffer to the processes matching a string.

If the string contains spaces, then each word is matched against
the process name separately.  To succeed, all of them have to
match but the order does not matter.  To bring it back to the
original view, you can call `revert buffer' (usually bound to g)."
  (interactive)
  (proced-narrow--internal 'proced-narrow--string-filter))

(defun proced-narrow--string-filter (filter)
  "Return t if FILTER is non-nil for the current file."
  (let ((words (split-string filter " ")))
    (seq-every-p
     (lambda (it)
       (save-excursion (search-forward it (line-end-position) t))) words)))

(defun proced-narrow--remove-text-with-property (prop)
  "Delete all text in the current buffer with text property PROP."
  (let ((start (point-min))
        end)
    (unless (get-text-property start prop)
      (setq start (next-single-property-change start prop)))
    (while start
      (setq end (text-property-any start (point-max) prop nil))
      (delete-region start (or end (point-max)))
      (setq start (when end
                    (next-single-property-change start prop))))))

(define-minor-mode proced-narrow-mode
  "Minor mode for indicating when narrowing is in progress."
  :lighter " proced-narrow")

(defun proced-narrow--internal (filter-function)
  "Narrow a proced buffer to the processes matching a filter.

The function FILTER-FUNCTION is called on each line: if it
returns non-nil, the line is kept, otherwise it is removed.  The
function takes on argument, which is the current filter string
read from the minibuffer."
  ( let ((proced-narrow-buffer (current-buffer))
         (proced-narrow-filter-function filter-function))
    (unwind-protect
        (progn
          (proced-narrow-mode 1)
          (add-to-invisibility-spec :proced-narrow)
          (read-from-minibuffer "Filter: " nil proced-narrow-map)
          (let ((inhibit-read-only t))
            (proced-narrow--remove-text-with-property :proced-narrow)))
      (with-current-buffer proced-narrow-buffer
        (remove-from-invisibility-spec :proced-narrow)
        (proced-narrow--restore)))))

(defun proced-narrow--restore ()
  "Restore the invisible files of the current buffer."
  (let ((inhibit-read-only t))
    (remove-list-of-text-properties (point-min) (point-max)
                                    '(invisible :proced-narrow))))

(defun proced-narrow--minibuffer-setup ()
  "Set up the minibuffer for live filtering."
  (when proced-narrow-buffer
    (add-hook 'post-command-hook #'proced-narrow--live-update nil :local)))

(add-hook 'minibuffer-setup-hook #'proced-narrow--minibuffer-setup)

(defun proced-narrow--live-update ()
  "Update the proced buffer based on the contents of the minibuffer."
  (when proced-narrow-buffer
    (let ((current-filter (minibuffer-contents-no-properties)))
      (with-current-buffer proced-narrow-buffer
        (unless (equal current-filter proced-narrow--minibuffer-content)
          (proced-narrow--update current-filter))))))

(defun proced-narrow--update (filter)
  "Make the processes not matching the FILTER invisible."
  (let ((inhibit-read-only t))
    (save-excursion
      (goto-char (point-min))
      (proced-narrow--restore)
      (while (not (eobp))
        (unless (funcall proced-narrow-filter-function filter)
          (put-text-property (line-beginning-position) (1+ (line-end-position)) :proced-narrow t)
          (put-text-property (line-beginning-position) (1+ (line-end-position)) 'invisible :proced-narrow))
        (forward-line 1)))))

(provide 'proced-narrow)
;;; proced-narrow.el ends here
