;;; -*- lexical-binding: t -*-
;;; bfbuilder.el --- A brainfuck development environment with interactive debugger

;; Copyright (C) 2015 zk_phi

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

;; Author: zk_phi
;; URL: http://zk-phi.gitub.io/
;; Package-Version: 20210228.1740
;; Package-Commit: 689f320a9a1326cdeff43b8538e0d739f8519c4b
;; Version: 1.0.1
;; Package-Requires: ((cl-lib "0.3") (emacs "24.4"))

;;; Commentary:

;; Require this script and setup `auto-mode-alist'
;;
;;   (require 'bfbuilder)
;;   (add-to-list 'auto-mode-alist '("\\.bf$" . bfbuilder-mode))
;;
;; then `bfbuilder-mode' is activated when opening ".bf" files.

;; For more informations, see "Readme".

;;; Change Log:

;; 1.0.0 first released
;; 1.0.1 Emacs 24.4 support

;;; Code:

(require 'cl-lib)

(defconst bfbuilder-version "1.0.1")

;; + customizable vars

(defgroup bfbuilder nil
  "A brainfuck development environment with interactive debugger"
  :group 'languages)

(defcustom bfbuilder-indent-width 4
  "The indent width used by the editing buffer."
  :type 'integer
  :group 'bfbuilder)

(defcustom bfbuilder-debug-memory-size 10000
  "Memory size (in bytes) for brainfuck interpreter."
  :type 'integer
  :group 'bfbuilder)

(defcustom bfbuilder-debug-visible-memory-size 20
  "Size of visual portion of the memory."
  :type 'integer
  :group 'bfbuilder)

(defcustom bfbuilder-debug-breakpoint "@"
  "String used to represent a breakpoint."
  :type 'string
  :group 'bfbuilder)

(defcustom bfbuilder-overflow-wrap-around t
  "Whether (+ 255 1) should be 0 or 255."
  :type 'boolean
  :group 'bfbuilder)

(defcustom bfbuilder-mode-map
  (let ((kmap (make-sparse-keymap)))
    (define-key kmap (kbd "TAB") 'bfbuilder-TAB-dwim)
    (define-key kmap (kbd "C-c C-c") 'bfbuilder-debug)
    kmap)
  "Keymap for `bfbuilder-mode'"
  :type 'keymap
  :group 'bfbuilder)

(defcustom bfbuilder-debug-keymap
  (let ((kmap (make-sparse-keymap)))
    (define-key kmap (kbd "j") 'bfbuilder-debug-next-line)
    (define-key kmap (kbd "l") 'bfbuilder-debug-forward-instr)
    (define-key kmap (kbd "L") 'bfbuilder-debug-skip-instr-forward)
    (define-key kmap (kbd "g") 'bfbuilder-debug)
    (define-key kmap (kbd "G") 'bfbuilder-debug-forward-breakpoint)
    kmap)
  "Keymap for brainfuck interpreter."
  :type 'keymap
  :group 'bfbuilder)

;; + majormode

(defvar bfbuilder-font-lock-keywords
  '(("[,.]" . font-lock-type-face)
    ("[][]" . font-lock-keyword-face)
    ("[><]" . font-lock-function-name-face)
    ("[^]\t\n\s+,.<>[-]" . font-lock-comment-face)))


(defun bfbuilder-indent-line ()
  "Indent current-line as BF code."
  (interactive)
  (let ((width (save-excursion
                 (back-to-indentation)
                 (and (looking-at "[]+,.<>[-]\\|$")
                      (* (max (- (nth 0 (syntax-ppss))
                                 (if (eql (char-after) ?\]) 1 0))
                              0)
                         bfbuilder-indent-width)))))
    (when width (indent-line-to width))))

(defun bfbuilder-TAB-dwim ()
  "Expand repetition command or indent-line."
  (interactive)
  (cond ((use-region-p)
         (indent-for-tab-command))
        ((looking-back "\\([]+,.<>[-]\\)\\([0-9]+\\)" nil t)
         (replace-match (make-string (string-to-number (match-string 2))
                                     (string-to-char (match-string 1)))))
        ((looking-back ")\\([0-9]+\\)" nil t)
         (let ((cnt (string-to-number (match-string 1)))
               (content-end (match-beginning 0))
               (end (match-end 0))
               content)
           (goto-char (match-beginning 1))
           (backward-sexp 1)
           (setq content (buffer-substring (1+ (point)) content-end))
           (delete-region (point) end)
           (dotimes (_ cnt) (insert content))))
        (t
         (indent-for-tab-command))))

(define-derived-mode bfbuilder-mode prog-mode "BF"
  "Major mode for editing BF programs."
  :group 'bfbuilder
  (set (make-local-variable 'indent-line-function) 'bfbuilder-indent-line)
  (setq font-lock-defaults '(bfbuilder-font-lock-keywords)))

;; + brainfuck debugger

;; *TODO* IMPLEMENT "UNDO" (REVERSE-EXECUTION) FEATURE

;; internal vars

(defvar bfbuilder-debug--memory nil)      ; Vector<Int>
(defvar bfbuilder-debug--ptr nil)         ; Int
(defvar bfbuilder-debug--stdin nil)       ; List<Char>
(defvar bfbuilder-debug--stdout nil)      ; reversed List<Char>

(defvar bfbuilder-debug--saved-pos nil)
(defvar bfbuilder-debug--saved-window-conf nil)

;; utils

(defun bfbuilder-debug--search-forward-instruction (&optional noerror)
  (when (search-forward-regexp "[]+,.<>[-]" nil noerror)
    (backward-char 1)
    t))

(defun bfbuilder-debug--dump-memory ()
  (with-current-buffer (get-buffer-create "*BF-RUN*")
    (erase-buffer)
    ;; memory
    (let ((mem-min (max (- bfbuilder-debug--ptr
                           (/ bfbuilder-debug-visible-memory-size 2))
                        0)))
      ;; memory
      (insert "memory: ")
      (dotimes (n bfbuilder-debug-visible-memory-size)
        (if (not (= (+ n mem-min) bfbuilder-debug--ptr))
            (insert (format "%2x " (aref bfbuilder-debug--memory (+ n mem-min))))
          (delete-char -1)
          (insert (format "[%2x]" (aref bfbuilder-debug--memory (+ n mem-min))))))
      (insert "\n"))
    ;; stdin
    (insert "stdin : " (mapconcat 'char-to-string bfbuilder-debug--stdin "") "\n")
    ;; stdout
    (insert "stdout: " (mapconcat 'char-to-string (reverse bfbuilder-debug--stdout) ""))
    ;; display
    (display-buffer-pop-up-window (current-buffer) '((window-height . 5)))))

;; interactive commands

(defun bfbuilder-debug (stdin)
  "Start brainfuck interpreter/debugger."
  (interactive (list (string-to-list (read-from-minibuffer "stdin: "))))
  (setq bfbuilder-debug--memory            (make-string bfbuilder-debug-memory-size 0)
        bfbuilder-debug--ptr               0
        bfbuilder-debug--stdin             stdin
        bfbuilder-debug--stdout            nil
        bfbuilder-debug--saved-pos         (point)
        bfbuilder-debug--saved-window-conf (current-window-configuration))
  (goto-char (point-min))
  (bfbuilder-debug--search-forward-instruction t)
  (bfbuilder-debug--dump-memory)
  (message "BF: Use [lLgGj] to control.")
  (set-transient-map
   bfbuilder-debug-keymap
   (lambda ()
     (or (and (symbolp this-command)
              (string-match "^bfbuilder-debug-" (symbol-name this-command)))
         (progn
           ;; cleanup
           (goto-char bfbuilder-debug--saved-pos)
           (when (buffer-live-p (get-buffer "*BF-RUN*"))
             (kill-buffer "*BF-RUN*"))
           (set-window-configuration bfbuilder-debug--saved-window-conf)
           nil)))))

(defun bfbuilder-debug-forward-instr ()
  (interactive)
  (unless (bfbuilder-debug--search-forward-instruction t)
    (error "BF: Execution terminated."))
  (cl-case (char-after)
    ((?+) (aset bfbuilder-debug--memory bfbuilder-debug--ptr
                (if bfbuilder-overflow-wrap-around
                    (mod (+ (aref bfbuilder-debug--memory bfbuilder-debug--ptr) 1) 256)
                  (min (+ (aref bfbuilder-debug--memory bfbuilder-debug--ptr) 1) 255))))
    ((?-) (aset bfbuilder-debug--memory bfbuilder-debug--ptr
                (if bfbuilder-overflow-wrap-around
                    (mod (- (aref bfbuilder-debug--memory bfbuilder-debug--ptr) 1) 256)
                  (max (- (aref bfbuilder-debug--memory bfbuilder-debug--ptr) 1) 0))))
    ((?>) (if (>= (1+ bfbuilder-debug--ptr) bfbuilder-debug-memory-size)
              (error "BF: Memory limit exceeded.")
            (setq bfbuilder-debug--ptr (1+ bfbuilder-debug--ptr))))
    ((?<) (if (<= bfbuilder-debug--ptr 0)
              (error "BF: Pointer value got negative.")
            (setq bfbuilder-debug--ptr (1- bfbuilder-debug--ptr))))
    ((?\[) (when (zerop (aref bfbuilder-debug--memory bfbuilder-debug--ptr))
             (forward-sexp 1)
             (backward-char 1)))
    ((?\]) (unless (zerop (aref bfbuilder-debug--memory bfbuilder-debug--ptr))
             (backward-up-list 1)))
    ((?.) (push (aref bfbuilder-debug--memory bfbuilder-debug--ptr)
                bfbuilder-debug--stdout))
    ((?,) (aset bfbuilder-debug--memory bfbuilder-debug--ptr
                (or (pop bfbuilder-debug--stdin) 255))))
  (forward-char 1)
  (bfbuilder-debug--search-forward-instruction t)
  (bfbuilder-debug--dump-memory))

(defun bfbuilder-debug-next-line ()
  (interactive)
  (let ((limit (save-excursion (forward-line 1) (point))))
    (while (< (point) limit)
      (bfbuilder-debug-forward-instr))))

(defun bfbuilder-debug-skip-instr-forward ()
  (interactive)
  (let ((char (char-after)))
    (while (= (char-after) char)
      (bfbuilder-debug-forward-instr))))

(defun bfbuilder-debug-forward-breakpoint ()
  (interactive)
  (let ((limit (save-excursion
                 (if (search-forward bfbuilder-debug-breakpoint nil t)
                     (point)
                   (point-max)))))
    (while (< (point) limit)
      (bfbuilder-debug-forward-instr))))

;; + provide

(provide 'bfbuilder)

;;; bfbuilder.el ends here
