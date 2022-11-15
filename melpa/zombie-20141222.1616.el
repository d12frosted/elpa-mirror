;;; zombie.el --- major mode for editing ZOMBIE programs

;; Copyright (C) 2014 zk_phi

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
;; URL: http://hins11.yu-yake.com/
;; Package-Version: 20141222.1616
;; Package-Commit: ff8cd1b4cdbb4b0b9b8fd1ec8f6fb93eba249345
;; Version: 1.0.0

;;; Commentary:

;; Recomended settings:
;;
;;   (autoload 'zombie-mode "zombie")
;;   (push '("\\.zombie$" . zombie-mode) auto-mode-alist)

;;; Change Log:

;; 1.0.0 first released

;;; Code:

(defgroup zombie nil
  "Editing ZOMBIE programs."
  :group 'languages)

(defcustom zombie-indent-width 4
  "The indent width used by the editing buffer."
  :group 'zombie)

(defvar zombie-font-lock-keywords
  `((,(regexp-opt                       ; entity types
       '("zombie" "enslaved undead" "ghost" "restless undead"
         "vampire" "free-willed undead" "demon" "djinn") 'symbols)
     . font-lock-type-face)
    ("\\(task\\) \\([^\s\t\n]+\\)"
     (1 font-lock-keyword-face) (2 font-lock-function-name-face))
    ("\\([^\s\t\n]+\\) is a"            ; entity names
     1 font-lock-variable-name-face)
    (,(regexp-opt                       ; keywords
       '("summon" "task" "animate" "disturb" "bind" "banish"
         "forget" "invoke" "moan" "remember" "say" "shamble"
         "until" "around" "stumble" "taste" "good" "bad"
         "spit" "remembering" "rend" "turn") 'symbols)
     . font-lock-keyword-face)))

(defvar zombie-mode-map
  (let ((kmap (make-sparse-keymap)))
    (define-key kmap [remap newline-and-indent] 'reindent-then-newline-and-indent)
    kmap))

(defvar zombie-block-opening-regexp
  (regexp-opt '("taste" "summon" "task" "shamble" "good" "bad") 'symbols))

(defvar zombie-block-closing-regexp
  (concat (regexp-opt '("bind" "until" "around" "good" "bad" "spit") 'symbols)
          "\\|"
          ;; "animate" and "disturb" can also be commands
          (regexp-opt '("animate" "disturb") 'symbols) "[\s\t]*$"))

(defun zombie-indent-line ()
  "Indent current-line as ZOMBIE code"
  (interactive)
  (let ((col (save-excursion
               (cond ((not (zerop (forward-line -1)))
                      0)
                     ((progn
                        (back-to-indentation)
                        (looking-at zombie-block-opening-regexp))
                      (+ (current-column) zombie-indent-width))
                     (t
                      (current-column)))))
        (closing (save-excursion
                   (back-to-indentation)
                   (looking-at zombie-block-closing-regexp))))
    (indent-line-to (max (- col (if closing zombie-indent-width 0)) 0))))

;;;###autoload
(define-derived-mode zombie-mode prog-mode "ZOMBIE"
  "Major mode for editing ZOMBIE programs."
  :group 'zombie
  (set (make-local-variable 'indent-line-function) 'zombie-indent-line)
  (setq font-lock-defaults '(zombie-font-lock-keywords)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.zombie\\'" . zombie-mode))

(provide 'zombie)

;;; zombie.el ends here
