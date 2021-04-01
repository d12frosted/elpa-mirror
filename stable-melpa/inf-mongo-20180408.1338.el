;;; inf-mongo.el --- Run a MongoDB shell process in a buffer

;; Copyright (C) 2013 Tobias Svensson

;; Author: Tobias Svensson
;; URL: http://github.com/endofunky/inf-mongo
;; Package-Version: 20180408.1338
;; Package-Commit: 2e498d1c88bd1904eeec18ed06b1a0cf8bdc2a92
;; Created: 1 March 2013
;; Keywords: databases mongodb
;; Version: 1.0.0

;; This file is released under the same terms as GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; inf-mongo.el provides a REPL buffer connected to a MongoDB shell
;; (mongo) subprocess.

;; Install

;; $ cd ~/.emacs.d/vendor
;; $ git clone git://github.com/endofunky/inf-mongo.git

;; In your emacs config:

;; (add-to-list 'load-path "~/.emacs.d/vendor/inf-mongo")
;; (require 'inf-mongo)

;; Usage

;; Run with `M-x inf-mongo'

;;; Code:

(require 'js)
(require 'comint)

;;;###autoload
(defgroup inf-mongo nil
  "Run a MongoDB shell (mongo) process in a buffer."
  :group 'inf-mongo)

;;;###autoload
(defcustom inf-mongo-command "/usr/local/bin/mongo 127.0.0.1:27017"
  "Default MongoDB shell command used.")

;;;###autoload
(defcustom inf-mongo-mode-hook nil
  "*Hook for customizing inf-mongo mode."
  :type 'hook
  :group 'inf-mongo)

(add-hook 'inf-mongo-mode-hook 'ansi-color-for-comint-mode-on)

;;;###autoload
(defun inf-mongo (cmd &optional dont-switch-p)
  "Major mode for interacting with an inferior MongoDB shell (mongo) process.

The following commands are available:
\\{inf-mongo-mode-map}

A MongoDB shell process can be fired up with M-x inf-mongo.

Customisation: Entry to this mode runs the hooks on comint-mode-hook and
inf-mongo-mode-hook (in that order)."
  (interactive (list (read-from-minibuffer "Run MongoDB shell: "
                                           inf-mongo-command)))

  (if (not (comint-check-proc "*mongo*"))
      (save-excursion (let ((cmdlist (split-string cmd)))
        (set-buffer (apply 'make-comint "mongo" (car cmdlist)
                           nil (cdr cmdlist)))
        (inf-mongo-mode)
        (setq inf-mongo-command cmd) 
        (setq inf-mongo-buffer "*mongo*")
        (inf-mongo-setup-autocompletion))))
  (if (not dont-switch-p)
      (pop-to-buffer "*mongo*")))

;;;###autoload
(defun mongo-send-region (start end)
  "Send the current region to the inferior MongoDB process."
  (interactive "r")
  (inf-mongo inf-mongo-command t)
  (comint-send-region inf-mongo-buffer start end)
  (comint-send-string inf-mongo-buffer "\n"))

;;;###autoload
(defun mongo-send-region-and-go (start end)
  "Send the current region to the inferior MongoDB process."
  (interactive "r")
  (inf-mongo inf-mongo-command t)
  (comint-send-region inf-mongo-buffer start end)
  (comint-send-string inf-mongo-buffer "\n")
  (switch-to-inf-mongo inf-mongo-buffer))

;;;###autoload
(defun mongo-send-last-sexp-and-go ()
  "Send the previous sexp to the inferior Mongo process."
  (interactive)
  (mongo-send-region-and-go (save-excursion (backward-sexp) (point)) (point)))

;;;###autoload
(defun mongo-send-last-sexp ()
  "Send the previous sexp to the inferior MongoDB process."
  (interactive)
  (mongo-send-region (save-excursion (backward-sexp) (point)) (point)))

;;;###autoload
(defun mongo-send-buffer ()
  "Send the buffer to the inferior MongoDB process."
  (interactive)
  (mongo-send-region (point-min) (point-max)))

;;;###autoload
(defun mongo-send-buffer-and-go ()
  "Send the buffer to the inferior MongoDB process."
  (interactive)
  (mongo-send-region-and-go (point-min) (point-max)))

;;;###autoload
(defun switch-to-inf-mongo (eob-p)
  "Switch to the MongoDB process buffer.
With argument, position cursor at end of buffer."
  (interactive "P")
  (if (or (and inf-mongo-buffer (get-buffer inf-mongo-buffer))
          (mongo-interactively-start-process))
      (pop-to-buffer inf-mongo-buffer)
    (error "No current process buffer. See variable inf-mongo-buffer."))
  (when eob-p
    (push-mark)
    (goto-char (point-max))))

(defvar inf-mongo-buffer)

(defvar inf-mongo-auto-completion-setup-code
  "function INFMONGO__getCompletions(prefix) {
      shellAutocomplete(prefix);
      return(__autocomplete__.join(\";\"));
  }"
  "Code executed in inferior mongo to setup autocompletion.")

(defun inf-mongo-setup-autocompletion ()
  "Function executed to setup autocompletion in inf-mongo."
  (comint-send-string (get-buffer-process inf-mongo-buffer) inf-mongo-auto-completion-setup-code)
  (comint-send-string (get-buffer-process inf-mongo-buffer) "\n")
  (define-key inf-mongo-mode-map "\t" 'complete-symbol))

(defvar inf-mongo-prompt "\n> \\|\n.+> "
  "String used to match inf-mongo prompt.")

(defvar inf-mongo--shell-output-buffer "")

(defvar inf-mongo--shell-output-filter-in-progress nil)

(defun inf-mongo--shell-output-filter (string)
  "This function is used by `inf-mongo-get-result-from-inf'.
It watches the inferior process until, the process returns a new prompt,
thus marking the end of execution of code sent by
`inf-mongo-get-result-from-inf'.  It stores all the output from the
process in `inf-mongo--shell-output-buffer'.  It signals the function
`inf-mongo-get-result-from-inf' that the output is ready by setting
`inf-mongo--shell-output-filter-in-progress' to nil"
  (setq string (ansi-color-filter-apply string)
	inf-mongo--shell-output-buffer (concat inf-mongo--shell-output-buffer string))
  (let ((prompt-match-index (string-match inf-mongo-prompt inf-mongo--shell-output-buffer)))
    (when prompt-match-index
      (setq inf-mongo--shell-output-buffer
	    (substring inf-mongo--shell-output-buffer
		       0 prompt-match-index))
      (setq inf-mongo--shell-output-filter-in-progress nil)))
  "")

(defun inf-mongo-get-result-from-inf (code)
  "Helper function to execute the given CODE in inferior mongo and return the result."
  (let ((inf-mongo--shell-output-buffer nil)
        (inf-mongo--shell-output-filter-in-progress t)
        (comint-preoutput-filter-functions '(inf-mongo--shell-output-filter))
        (process (get-buffer-process inf-mongo-buffer)))
    (with-local-quit
      (comint-send-string process code)
      (comint-send-string process "\n")
      (while inf-mongo--shell-output-filter-in-progress
        (accept-process-output process))
      (prog1
          inf-mongo--shell-output-buffer
        (setq inf-mongo--shell-output-buffer nil)))))

(defun inf-mongo-shell-completion-complete-at-point ()
  "Perform completion at point in inferior-mongo.
Most of this is borrowed from python.el"
  (let* ((start
          (save-excursion
            (with-syntax-table js-mode-syntax-table
              (let* ((syntax-list (append (string-to-syntax ".")
					  (string-to-syntax "_")
					  (string-to-syntax "w"))))
                (while (member
                        (car (syntax-after (1- (point)))) syntax-list)
                  (skip-syntax-backward ".w_")
                  (when (or (equal (char-before) ?\))
                            (equal (char-before) ?\"))
                    (forward-char -1)))
                (point)))))
         (end (point)))
    (list start end
          (completion-table-dynamic
           (apply-partially
            #'inf-mongo-get-completions-at-point)))))

(defun inf-mongo-get-completions-at-point (prefix)
  "Get completions for PREFIX using inf-mongo."
  (if (equal prefix "") 
      nil
    (split-string (inf-mongo-get-result-from-inf (concat "INFMONGO__getCompletions('" prefix "');")) ";")))

;;;###autoload
(defvar inf-mongo-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-x\C-e" 'mongo-send-last-sexp)
    map))

;;;###autoload
(define-derived-mode inf-mongo-mode comint-mode "Inferior MongoDB mode"
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults (list js--font-lock-keywords))

  (make-local-variable 'syntax-propertize-function)
  (setq syntax-propertize-function #'js-syntax-propertize)

  (add-hook 'before-change-functions #'js--flush-caches t t)
  (js--update-quick-match-re)

  (add-to-list (make-local-variable 'comint-dynamic-complete-functions)
               'inf-mongo-shell-completion-complete-at-point)

  (use-local-map inf-mongo-mode-map))

(provide 'inf-mongo)
;;; inf-mongo.el ends here
