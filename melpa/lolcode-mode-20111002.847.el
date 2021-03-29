;;; lolcode-mode.el --- Major mode for editing LOLCODE

;; Copyright (C) 2011 Bodil Stokke

;; Version: 0.2
;; Package-Version: 20111002.847
;; Package-Commit: 1914f1ba87587ecf5f175eeb2144c28e9f039317
;; Keywords: LOLCODE major mode
;; Author: Bodil Stokke <lolcode@bodil.tv>
;; URL: http://github.com/bodil/lolcode-mode

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Suite 500, Boston, MA 02110.

;;; Commentary:

;; This is a major mode for editing LOLCODE, with the following
;; features:

;; * Syntax highlighting.
;; * Smart indentation.
;; * Execution of LOLCODE buffers (press C-c C-c).
;; * Automatic Flymake integration.

;;; Installation:

;; Put this file somewhere in your load-path, and put the following in
;; your .emacs:

;;   (require 'lolcode-mode)

;; You may want to install a LOLCODE interpreter. This package comes
;; preconfigured for lci, which you can get at the following URL:

;;   http://icanhaslolcode.org/

;;; Configuration:

;; This is an example setup which integrates lolcode-mode with
;; auto-complete-mode and yasnippet. It also sets default indentation
;; to 2 spaces.

;;   (require 'lolcode-mode)
;;   (require 'auto-complete)
;;   (defvar ac-source-lolcode
;;     '((candidates . lolcode-lang-all)))
;;   (add-to-list 'ac-modes 'lolcode-mode)
;;   (add-hook 'lolcode-mode-hook
;;             (lambda ()
;;               (setq default-tab-width 2)
;;               (add-to-list 'ac-sources 'ac-source-lolcode)
;;               (add-to-list 'ac-sources 'ac-source-yasnippet)))

;;; Code:

(defgroup lolcode-mode nil
  "I CAN HAS MAJOR MODE 4 LOLCODE?"
  :group 'languages)

(defcustom lolcode-interpreter-command "lci"
  "The LOLCODE interpreter to use. Must be on your path and accept source input on stdin."
  :type 'string
  :group 'lolcode-mode)

(defcustom lolcode-output-buffer-name "*LOLCODE-OUTPUT*"
  "The name of the scratch buffer used when executing LOLCODE."
  :type 'string
  :group 'lolcode-mode)



(defvar lolcode-mode-hook nil)

(defvar lolcode-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") 'lolcode-execute-buffer-or-region)
    map)
  "Keymap for lolcode-mode.")



(defvar lolcode-lang-keywords
  '("HAI" "KTHXBYE"
    "I HAS A" "IS NOW A" "ITZ" "R" "MAEK" "A"
    "O RLY?" "YA RLY" "NO WAI" "MEBBE" "OIC"
    "WTF?" "OMG" "OMGWTF" "GTFO"
    "IM IN" "YR" "TIL" "WILE" "IM OUTTA YR"
    "HOW DUZ I" "IF U SAY SO" "FOUND YR"
    ))

(defvar lolcode-lang-types
  '("NOOB" "TROOF" "NUMBR" "NUMBAR" "YARN" "BUKKIT"))

(defvar lolcode-lang-operators
  '("SUM OF" "DIFF OF" "PRODUKT OF" "QUOSHUNT OF" "MOD OF" "BIGGR OF" "SMALLR OF"
    "BOTH OF" "EITHER OF" "WON OF" "NOT" "ALL OF" "ANY OF"
    "BOTH SAEM" "DIFFRINT"
    "SMOOSH" "MKAY" "AN"))

(defvar lolcode-lang-constants
  '("WIN" "FAIL"))

(defvar lolcode-lang-builtins
  '("VISIBLE" "GIMMEH"
    "UPPIN" "NERFIN"))

(defvar lolcode-lang-variables
  '("IT"))

(defvar lolcode-lang-comment-keywords
  '("OBTW" "TLDR"))

(defvar lolcode-lang-all
  (append lolcode-lang-keywords lolcode-lang-types lolcode-lang-operators lolcode-lang-constants
          lolcode-lang-builtins lolcode-lang-variables lolcode-lang-comment-keywords))

(defvar lolcode-keyword-regexp (regexp-opt lolcode-lang-keywords 'words))
(defvar lolcode-type-regexp (regexp-opt lolcode-lang-types 'words))
(defvar lolcode-operator-regexp (regexp-opt lolcode-lang-operators 'words))
(defvar lolcode-constant-regexp (regexp-opt lolcode-lang-constants 'words))
(defvar lolcode-builtin-regexp (regexp-opt lolcode-lang-builtins 'words))
(defvar lolcode-variable-regexp (regexp-opt lolcode-lang-variables 'words))
(defvar lolcode-comment-keyword-regexp (regexp-opt lolcode-lang-comment-keywords 'words))

;; regexp-opt doesn't do words with question marks in them well, so
;; handle these with a custom regexp.
(defvar lolcode-difficult-keyword-regexp "\\<\\(?:WTF\\|O RLY\\)[?]*\\>")

(defconst lolcode-font-lock-keywords
  `((,lolcode-keyword-regexp . font-lock-keyword-face)
    (,lolcode-difficult-keyword-regexp . font-lock-keyword-face)
    (,lolcode-type-regexp . font-lock-type-face)
    (,lolcode-operator-regexp . font-lock-operator-face)
    (,lolcode-constant-regexp . font-lock-constant-face)
    ("\\<BTW\\>" (0 font-lock-comment-delimiter-face) (".*$" nil nil (0 font-lock-comment-face)))
    ("\\(\\<OBTW\\>\\)\\(.*?\\)\\(\\<TLDR\\>\\)" 2 font-lock-comment-face)
    (,lolcode-comment-keyword-regexp . font-lock-comment-delimiter-face)
    (,lolcode-builtin-regexp . font-lock-builtin-face)
    (,lolcode-variable-regexp . font-lock-variable-name-face)))



(defun lolcode-line-at-point-matches (regexp)
  (string-match regexp (thing-at-point 'line)))

(defun lolcode-indent-line ()
  (interactive)
  (if (= (line-number-at-pos) 1)
      (indent-line-to 0)
    (let (
          (block-start "\\(^\\s-*\\(?:HAI\\|IM IN YR\\|HOW DUZ I\\)\\|.*\\(?:O RLY\\|WTF\\)\\?\\s-*$\\)")
          (block-end "^\\s-*\\(?:KTHXBYE\\|IM OUTTA YR\\|IF U SAY SO\\|OIC\\)")
          (case-label "^\\s-*\\(?:OMG\\(?:\\s-\\|WTF\\)\\|MEBBE\\s-\\|YA RLY\\|NO WAI\\)")
          (not-indented t)
          cur-indent)
      (save-excursion
        (beginning-of-line)
        (cond
         ((lolcode-line-at-point-matches block-end)
          (save-excursion
            (forward-line -1)
            (setq cur-indent (- (current-indentation) default-tab-width)))
          (if (< cur-indent 0)
              (setq cur-indent 0)))
         ((lolcode-line-at-point-matches case-label)
          (save-excursion
            (forward-line -1)
            (if (lolcode-line-at-point-matches block-start)
                ;; A case label just after a block start should be
                ;; aligned with it,
                (setq cur-indent (current-indentation))
              ;; But if it's after any old line, it de-indents.
              (setq cur-indent (- (current-indentation) default-tab-width))))
          (if (< cur-indent 0)
              (setq cur-indent 0)))
         (t
          (while not-indented
            (forward-line -1)
            (if (lolcode-line-at-point-matches block-end)
                (progn
                  (setq cur-indent (current-indentation))
                  (setq not-indented nil))
              (if (lolcode-line-at-point-matches block-start)
                  (progn
                    (setq cur-indent (+ (current-indentation) default-tab-width))
                    (setq not-indented nil))
                (if (bobp)
                    (setq not-indented nil))))))))
      (save-excursion
        (if cur-indent
            (indent-line-to cur-indent)
          (indent-line-to 0)))
      (when (<= (current-column) (current-indentation))
        (backward-to-indentation 0)))))


;; Execute the current buffer using lci
(defun lolcode-execute-buffer ()
  (interactive)
  (save-excursion
    (lolcode-execute-region (point-min) (point-max))))

;; Execute a region using lci
(defun lolcode-execute-region (start end)
  (interactive "r")

  (let ((buffer (get-buffer lolcode-output-buffer-name)))
    (when buffer
      (kill-buffer buffer)))

  (call-process-region start end lolcode-interpreter-command nil
                       (get-buffer-create lolcode-output-buffer-name)
                       nil
                       "-")
  (let ((buffer (get-buffer lolcode-output-buffer-name)))
    (display-buffer buffer)))

;; Execute the current buffer or active region using lci
(defun lolcode-execute-buffer-or-region ()
  (interactive)
  (if (region-active-p)
      (lolcode-execute-region (mark) (point))
    (lolcode-execute-buffer)))

;; Flymake
(defun flymake-lolcode-init ()
  (let* ((temp-file (flymake-init-create-temp-buffer-copy 'flymake-create-temp-inplace))
         (local-file (file-relative-name temp-file (file-name-directory buffer-file-name))))
    (list lolcode-interpreter-command (list local-file))))
(defvar flymake-lolcode-allowed-file-name-masks
  '(("\\.lol\\'" flymake-lolcode-init)))
(defvar flymake-lolcode-err-line-patterns
  '(("\\([^:]+\\):\\([[:digit:]]+\\): *\\(.*\\)" 1 2 nil 3)))
(defun flymake-lolcode-load ()
  (interactive)
  (when (and (not (null buffer-file-name)) (file-writable-p buffer-file-name))
    (set (make-local-variable 'flymake-allowed-file-name-masks) flymake-lolcode-allowed-file-name-masks)
    (set (make-local-variable 'flymake-err-line-patterns) flymake-lolcode-err-line-patterns)
    (flymake-mode t)))
(eval-after-load 'flymake
  (add-hook 'lolcode-mode-hook 'flymake-lolcode-load))

;;;###autoload
(define-derived-mode lolcode-mode fundamental-mode
  "LOLCODE"
  "I CAN HAS MAJOR MODE 4 LOLCODE?"
  (set (make-local-variable 'font-lock-defaults) '(lolcode-font-lock-keywords))
  (set (make-local-variable 'indent-line-function) 'lolcode-indent-line)
  (setq indent-tabs-mode nil)

  (set (make-local-variable 'font-lock-multiline) t)

  (set (make-local-variable 'comment-start) "BTW")
  (set (make-local-variable 'comment-start-skip) "BTW\\s-*"))

(provide 'lolcode-mode)

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.lol$" . lolcode-mode))

;;; lolcode-mode.el ends here
