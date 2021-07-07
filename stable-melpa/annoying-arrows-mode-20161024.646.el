;;; annoying-arrows-mode.el --- Ring the bell if using arrows too much

;; Copyright (C) 2011 Magnar Sveen

;; Author: Magnar Sveen <magnars@gmail.com>
;; Package-Requires: ((cl-lib "0.5"))
;; Package-Version: 20161024.646
;; Package-Commit: 3c42e9807d7696da2da2a21b63beebf9cdb3f5dc
;; Version: 0.1.0

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

;; Entering annoying-arrows-mode makes Emacs ring the bell in your
;; face if you use the arrow keys to move long distances.

;; Set the `annoying-arrows-too-far-count' to adjust the length.

;;; Code:

(require 'cl-lib)

(defvar annoying-arrows-too-far-count 10
  "Number of repeated arrow presses before Emacs gets annoyed.")

(defvar annoying-arrows--commands '())

(defvar annoying-arrows--current-count 0)

(defun annoying-arrows--commands-with-shortcuts (cmds)
  (cl-remove-if (lambda (cmd)
                  (string-equal
                   (substring (substitute-command-keys (format "\\[%S]" cmd)) 0 3)
                   "M-x")) cmds))

(defun annoying-arrows--maybe-complain (cmd)
  (if (and (memq this-command annoying-arrows--commands)
           (eq this-command last-command))
      (progn
        (cl-incf annoying-arrows--current-count)
        (when (> annoying-arrows--current-count annoying-arrows-too-far-count)
          (beep 1)
          (let* ((alts (annoying-arrows--commands-with-shortcuts (get cmd 'annoying-arrows--alts)))
                 (alt (nth (random (length alts)) alts))
                 (key (substitute-command-keys (format "\\[%S]" alt))))
            (message "Annoying! How about using %S (%s) instead?" alt key))))
    (setq annoying-arrows--current-count 0)))

;;;###autoload
(define-minor-mode annoying-arrows-mode
  "Annoying-Arrows emacs minor mode."
  nil "" nil)

;;;###autoload
(define-globalized-minor-mode global-annoying-arrows-mode
  annoying-arrows-mode annoying-arrows-mode)


(defmacro add-annoying-arrows-advice (cmd alternatives)
  `(progn
     (add-to-list 'annoying-arrows--commands (quote ,cmd))
     (put (quote ,cmd) 'annoying-arrows--alts ,alternatives)
     (defadvice ,cmd (before annoying-arrows activate)
       (when annoying-arrows-mode
         (annoying-arrows--maybe-complain (quote ,cmd))))))

(add-annoying-arrows-advice previous-line '(ace-jump-mode backward-paragraph isearch-backward ido-imenu smart-up))
(add-annoying-arrows-advice next-line '(ace-jump-mode forward-paragraph isearch-forward ido-imenu smart-down))
(add-annoying-arrows-advice right-char '(jump-char-forward iy-go-to-char right-word smart-forward))
(add-annoying-arrows-advice left-char '(jump-char-backward iy-go-to-char-backward left-word smart-backward))
(add-annoying-arrows-advice forward-char '(jump-char-forward iy-go-to-char right-word smart-forward))
(add-annoying-arrows-advice backward-char '(jump-char-backward iy-go-to-char-backward left-word smart-backward))

(add-annoying-arrows-advice backward-delete-char-untabify '(backward-kill-word kill-region-or-backward-word subword-backward-kill))
(add-annoying-arrows-advice backward-delete-char '(backward-kill-word kill-region-or-backward-word subword-backward-kill))
;;(add-annoying-arrows-advice delete-char '(subword-kill kill-line zap-to-char))

(defun aa-add-suggestion (cmd alternative)
  (let ((old-alts (or (get cmd 'annoying-arrows--alts)
                      ())))
    (unless (memq alternative old-alts)
      (put cmd 'annoying-arrows--alts (cons alternative old-alts)))))

(defun aa-add-suggestions (cmd alternatives)
  (let ((old-alts (or (get cmd 'annoying-arrows--alts)
                      ())))
    (put cmd 'annoying-arrows--alts (append
                                     (cl-remove-if (lambda (cmd)
                                                     (memq cmd old-alts)) alternatives)
                                     old-alts))))

(provide 'annoying-arrows-mode)
;;; annoying-arrows-mode.el ends here
