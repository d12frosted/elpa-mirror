;;; sproto-mode.el --- Major mode for editing sproto.

;; Author: m2q1n9
;; Created: 15-Nov-2015
;; Version: 0.1
;; Package-Version: 20151115.1805
;; Package-Commit: 1753277d9f2163fb3bc58b983a9892831cf9874b
;; Keywords: sproto

;;; Commentary:

;; Installation:
;;   - Put `sproto-mode.el' in your Emacs load-path.
;;   - Add this line to your .emacs file:
;;       (require 'sproto-mode)
;;       (add-to-list 'auto-mode-alist '("\\.sproto\\'" . sproto-mode))

;;; Code:

;;;###autoload
(define-derived-mode sproto-mode fundamental-mode "Sproto"
  "Major mode for editing sproto."
  (setq font-lock-defaults '((
    ("#.*$" . font-lock-comment-face)
    ("-*[0-9]+-*" . font-lock-constant-face)
    ("[\\.\\*][[:alnum:]]+" . font-lock-type-face)
    ("-*\\(string\\|integer\\|boolean\\|request\\|response\\)-*" . font-lock-keyword-face)
))))

(provide 'sproto-mode)

;;; sproto-mode.el ends here
