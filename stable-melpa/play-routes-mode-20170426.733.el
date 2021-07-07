;;; play-routes-mode.el --- Play Framework Routes File Support

;; Copyright (C) 2016 Maximilien Riehl, Patrick Haun

;; Author: M.Riehl <max@flatmap.ninja>, P.Haun <bomgar85@googlemail.com>
;; Version: 0.1
;; Package-Version: 20170426.733
;; Package-Commit: 22d7b87e0eaf0330f2b2283872f8dc08a3258771
;; Package-Requires: ()
;; Keywords: play, scala
;; URL: https://github.com/brocode/play-routes-mode/

;;; Commentary:

;; This package provides basic support for the play routes file

;;; Code:

(defgroup play-routes nil
  "Play routes file support"
  :group 'tools)

(defcustom play-routes-host "localhost"
  "Play host to open routes"
  :type 'string
  :group 'play-routes)

(defcustom play-routes-port 9000
  "Play port to open routes"
  :type 'number
  :group 'play-routes)

(defcustom play-routes-protocol "http"
  "Play protocol to open routes"
  :type 'string
  :group 'play-routes)

(defun play-routes-open-route () "Open route in browser"
       (interactive)
       (let ((line (thing-at-point 'line t))
             (route-regex (rx (seq bol (zero-or-more white) (one-or-more alpha)) (zero-or-more whitespace) (group (one-or-more (not white))) (one-or-more any) eol)))
         (if (string-match route-regex line)
             (let ((path (match-string 1 line)))
               (browse-url (concat play-routes-protocol "://" play-routes-host ":" (number-to-string play-routes-port) path)))
           (message "no route at point"))))

(defconst play-routes-mode-keywords '("GET" "POST" "DELETE" "PUT" "HEAD" "OPTIONS" "PATCH"))
(defconst play-routes-mode-keywords-regexp (regexp-opt play-routes-mode-keywords 'words))
(defconst play-routes-mode-path-variable-regex (rx ?/ (group (any ?: ?* ?$) (one-or-more (not (any whitespace ?/))))))
(defconst play-routes-mode-arg-variable-regex (rx (or ?, ?\( (seq ?, (zero-or-more whitespace)))
                                                  (group (or lower upper) (zero-or-more alnum))
                                                  (group (or ?: (seq (zero-or-more whitespace) ?=) ?\)))))

(defvar play-routes-mode-highlights
  `(
    (,play-routes-mode-path-variable-regex 1 font-lock-variable-name-face)
    (,play-routes-mode-arg-variable-regex 1 font-lock-variable-name-face)
    (,play-routes-mode-keywords-regexp . font-lock-keyword-face)
    ))

(defvar play-routes-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-o") 'play-routes-open-route)
    map)
  "Keymap for `play-routes-mode'.")

;;;###autoload
(define-derived-mode play-routes-mode prog-mode "PlayRoutes"
  "Major mode for Play Framework routes files."
  (setq font-lock-defaults '(play-routes-mode-highlights))
  (set (make-local-variable 'comment-start) "# ")
  (set (make-local-variable 'comment-start-skip) "#+ *"))

(modify-syntax-entry ?# "<   " play-routes-mode-syntax-table)
(modify-syntax-entry ?\n ">   " play-routes-mode-syntax-table)

;;;###autoload
(add-to-list 'auto-mode-alist '("/routes\\'" . play-routes-mode))

(provide 'play-routes-mode)
;;; play-routes-mode.el ends here
