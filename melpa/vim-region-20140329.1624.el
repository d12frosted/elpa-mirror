;;; vim-region.el --- Select region as vim

;; Copyright (C) 2013 by ongaeshi

;; Author: ongaeshi <ongaeshi0621@gmail.com>
;; URL: https://github.com/ongaeshi/emacs-vim-region
;; Package-Version: 20140329.1624
;; Package-Commit: 7c4a99ce3678fee40c83ab88e8ad075d2a935fdf
;; Version: 0.5
;; Package-Requires: ((expand-region "20140127"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; To use this package, add following code to your init.el or .emacs
;; (require 'vim-region)
;; (global-set-key (kbd "C-@") 'vim-region-mode)
;;

;;; Code:
(require 'thingatpt)

(defvar vim-region-non-auto-quit nil)

(defun vim-region-auto-quit ()
  (unless vim-region-non-auto-quit
      (vim-region-mode 0)))

(defun vim-region-copy ()
  (interactive)
  (kill-ring-save (region-beginning) (region-end))
  (yank))

(defun vim-region-save ()
  (interactive)
  (kill-ring-save (region-beginning) (region-end)))

(defun vim-region-kill ()
  (interactive)
  (if mark-active
      (progn
        (kill-region (region-beginning) (region-end)))
    (kill-line)))

(defun vim-region-delete-char ()
  (interactive)
  (delete-char 1))

(defun vim-region-yank ()
  (interactive)
  (if (featurep 'cua-base)
      (cua-paste nil)
    (yank)))

(defun vim-region-scroll-up ()
  (interactive)
  (scroll-up)
  (recenter))

(defun vim-region-scroll-down ()
  (interactive)
  (scroll-down)
  (recenter))

(defvar vim-region-last-search-char nil)

(defun vim-region-forward-to-char (arg &optional char)
  (interactive "p\n")
  (unless char
    (if (memq last-command '(vim-region-forward-to-char vim-region-backward-to-char))
        (setq char vim-region-last-search-char)
      (setq char (read-char "Forward Char: "))))
  (setq vim-region-last-search-char char)
  (when (>= arg 0)
    (forward-char 1))
  (let ((case-fold-search nil))
    (search-forward (char-to-string char) nil t arg)))

(defun vim-region-backward-to-char (arg &optional char)
  (interactive "p\n")
  (unless char
    (if (memq last-command '(vim-region-forward-to-char vim-region-backward-to-char))
        (setq char vim-region-last-search-char)
      (setq char (read-char "Backward Char: "))))
  (backward-char 1)
  (vim-region-forward-to-char (- arg) char))

(defun vim-region-forward-last-char ()
  (interactive)
  (vim-region-forward-to-char 1 vim-region-last-search-char))

(defun vim-region-backward-last-char ()
  (interactive)
  (vim-region-backward-to-char 1 vim-region-last-search-char))

(defun vim-region-toggle-mark ()
  (interactive)
  (if (featurep 'cua-base)
      (cua-set-mark)                    ; auto toggle
    (if mark-active
        (deactivate-mark)
      (set-mark (point)))))

(defun vim-region-toggle-eternal ()
  (interactive)
  (if vim-region-non-auto-quit
    (progn
      (message "End eternal vim-region mode")
      (setq vim-region-non-auto-quit nil))
    (if mark-active
        (deactivate-mark))
    (message "[EVR] Start eternal vim-region mode")
    (setq vim-region-non-auto-quit t)))

(defun vim-reginon-backward-paragraph ()
  (interactive)
  (forward-paragraph -1))

(defun vim-region-mark-symbol ()
  (interactive)
  (beginning-of-thing 'sexp)
  (set-mark (point))
  (end-of-thing 'sexp))

(defun vim-region-query-replace (replacement)
  "Replace the symbol at point with REPLACEMENT."
  (interactive (list (read-from-minibuffer "Replacement: " nil nil nil query-replace-to-history-variable)))
  (let ((src (buffer-substring (region-beginning) (region-end))))
    (goto-char (region-beginning))
    (deactivate-mark)
    (query-replace-regexp src replacement)))

(define-minor-mode local-vim-region-mode
  "vim-region-mode"
  :lighter " vim-region"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "l") 'forward-char)
            (define-key map (kbd "j") 'next-line)
            (define-key map (kbd "k") 'previous-line)
            (define-key map (kbd "h") 'backward-char)

            (define-key map (kbd "a") 'move-beginning-of-line)
            (define-key map (kbd "e") 'move-end-of-line)
            (define-key map (kbd "0") 'move-beginning-of-line)
            (define-key map (kbd "$") 'move-end-of-line)

            (define-key map (kbd "y") 'vim-region-save)
            (define-key map (kbd "d") 'vim-region-kill)
            (define-key map (kbd "p") 'vim-region-yank)
            (define-key map (kbd "c") 'vim-region-copy)
            (define-key map (kbd "x") 'vim-region-delete-char)

            (define-key map (kbd "z") 'exchange-point-and-mark)
            (define-key map (kbd "v") 'vim-region-toggle-mark)
            (define-key map (kbd "q") 'vim-region-toggle-eternal) ; Under Development

            (define-key map (kbd "w") 'forward-word)
            (define-key map (kbd "b") 'backward-word)
            
            (define-key map (kbd "s") 'forward-sexp)
            (define-key map (kbd "S") 'backward-sexp)

            (define-key map (kbd "t") 'vim-region-mark-symbol)
            (define-key map (kbd "r") 'vim-region-query-replace)

            (define-key map (kbd "m") 'forward-paragraph)
            (define-key map (kbd "M") 'vim-reginon-backward-paragraph)

            (define-key map (kbd "g") 'beginning-of-buffer)
            (define-key map (kbd "G") 'end-of-buffer)

            (define-key map (kbd "O") 'mark-whole-buffer)

            (define-key map (kbd "C-f") 'vim-region-scroll-up)
            (define-key map (kbd "C-b") 'vim-region-scroll-down)

            (define-key map (kbd "/") 'isearch-forward)
            (define-key map (kbd "?") 'isearch-backward)
            (define-key map (kbd "n") 'isearch-repeat-forward)
            (define-key map (kbd "N") 'isearch-repeat-backward)

            (define-key map (kbd "f") 'vim-region-forward-to-char)
            (define-key map (kbd ";") 'vim-region-forward-last-char)
            (define-key map (kbd "F") 'vim-region-backward-to-char)
            (define-key map (kbd ",") 'vim-region-backward-last-char)

            (define-key map (kbd "u") 'undo)

            (define-key map (kbd "+") 'er/expand-region)

            (define-key map (kbd "L") 'sort-lines)
            (define-key map (kbd "A") 'align-regexp)

            map))

;;;###autoload
(define-global-minor-mode vim-region-mode
  local-vim-region-mode
  (lambda ()
    (unless (minibufferp)
      (local-vim-region-mode t)))
  :group 'vim-region)

(add-hook 'vim-region-mode-hook 
          (lambda ()
            (setq vim-region-non-auto-quit nil)
            (if vim-region-mode
                (unless mark-active
                    (if (featurep 'cua-base)
                        (cua-set-mark)
                      (set-mark (point)))))))

(defvar vim-region-funcs
  '("forward-char"
    "next-line"
    "previous-line"
    "backward-char"
    "move-beginning-of-line"
    "move-end-of-line"
    "move-beginning-of-line"
    "move-end-of-line"
    ;; "vim-region-save"
    ;; "vim-region-kill"
    ;; "vim-region-yank"
    ;; "vim-region-copy"
    "vim-region-delete-char"
    "exchange-point-and-mark"
    "cua-exchange-point-and-mark"
    "vim-region-toggle-mark"
    "vim-region-toggle-eternal"
    "forward-word"
    "backward-word"
    "forward-sexp"
    "backward-sexp"
    "vim-region-mark-symbol"
    "forward-paragraph"
    "vim-reginon-backward-paragraph"
    "beginning-of-buffer"
    "end-of-buffer"
    "mark-whole-buffer"
    ;; "vim-region-quit"
    "vim-region-scroll-up"
    "vim-region-scroll-down"
    "isearch-forward"
    "isearch-backward"
    "isearch-repeat-forward"
    "isearch-repeat-backward"
    "isearch-printing-char"
    "isearch-other-control-char"
    "isearch-exit"
    "isearch-abort"
    "isearch-delete-char"
    "isearch-backward"
    "isearch-yank-kill"
    "vim-region-forward-to-char"
    "region-forward-last-char"
    "vim-region-backward-to-char"
    "region-backward-last-char"
    "undo"
    "vim-region-mode"
    "er/expand-region"
    "er/contract-region"
    "forward-list"
    "backward-list"
    "ruby-beginning-of-block"
    "ruby-end-of-block"
    "beginning-of-defun"
    "end-of-defun"
    "c-beginning-of-defun"
    "c-end-of-defun"
    ))

(defun vim-region-is-in (list str)
  (catch 'match
    (while (car list)
      (progn (if (string= (car list) str)
                 (throw 'match 1))
             (setq list (cdr list))))
    nil))

(defun vim-region-command-check ()
 ;; (message "func: %s" this-command)
 (if (and vim-region-mode
          (symbolp this-command)
          (not (vim-region-is-in vim-region-funcs this-command)))
     (progn
       ;; (message "[hook] vim-region-auto-quit: %s" this-command)
       (vim-region-auto-quit))))

(add-hook 'pre-command-hook 'vim-region-command-check)

(provide 'vim-region)
;;; vim-region.el ends here
