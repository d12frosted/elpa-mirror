;;; auto-minor-mode.el --- Enable minor modes by file name and contents -*- lexical-binding: t -*-
;;
;; Copyright 2017 Joe Wreschnig
;;
;; Author: Joe Wreschnig <joe.wreschnig@gmail.com>
;; Package-Version: 20180527.1
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/joewreschnig/auto-minor-mode
;; Keywords: convenience
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This package lets you enable minor modes based on file name and
;; contents.  To find the right modes, it checks filenames against
;; patterns in ‘auto-minor-mode-alist’ and file contents against
;; ‘auto-minor-mode-magic-alist’.  These work like the built-in Emacs
;; variables ‘auto-mode-alist’ and ‘magic-mode-alist’.
;;
;; Unlike major modes, all matching minor modes are enabled, not only
;; the first match.
;;
;; A reason you might want to use it:
;;   (add-to-list 'auto-minor-mode-alist '("-theme\\.el\\'" . rainbow-mode))
;;
;; There’s intentionally no equivalent of ‘interpreter-mode-alist’.
;; Interpreters should determine the major mode.  Relevant minor
;; modes can then be enabled by major mode hooks.
;;
;; Minor modes are set whenever ‘set-auto-mode’, the built-in function
;; responsible for handling automatic major modes, is called.
;;
;; If you also use ‘use-package’, two new keywords are added, ‘:minor’
;; and ‘:magic-minor’, which register entries in these alists.  You
;; must load (and not defer) ‘auto-minor-mode’ before using these
;; keywords for other packages.


;;; Code:

(require 'cl-lib)

;;;###autoload
(defvar auto-minor-mode-alist ()
  "Alist of filename patterns vs corresponding minor mode functions.

This is an equivalent of ‘auto-mode-alist’, for minor modes.

Unlike ‘auto-mode-alist’, matching is always case-folded.")

;;;###autoload
(defvar auto-minor-mode-magic-alist ()
  "Alist of buffer beginnings vs corresponding minor mode functions.

This is an equivalent of ‘magic-mode-alist’, for minor modes.

Magic minor modes are applied after ‘set-auto-mode’ enables any
major mode, so it’s possible to check for expected major modes in
match functions.

Unlike ‘magic-mode-alist’, matching is always case-folded.")

(defun auto-minor-mode-enabled-p (minor-mode)
  "Return non-nil if MINOR-MODE is enabled in the current buffer."
  (and (memq minor-mode minor-mode-list)
       (symbol-value minor-mode)))

(defun auto-minor-mode--plain-filename (file-name)
  "Remove remote connections and backup version from FILE-NAME."
  (let ((remote-id (file-remote-p file-name))
        (file-name (file-name-sans-versions file-name)))
    (if (and remote-id (string-match (regexp-quote remote-id) file-name))
        (substring file-name (match-end 0))
      file-name)))

(defun auto-minor-mode--run-auto (alist keep-mode-if-same)
  "Run through an auto ALIST and enable all matching minor modes.

A auto alist contains pairs of regexps or functions to match the
buffer’s contents, and functions to call when matched.  For more
information, see ‘auto-mode-alist’.

If the optional argument KEEP-MODE-IF-SAME is non-nil, then we
don’t re-activate minor modes already enabled in the buffer."
  (when buffer-file-name
    (let ((bufname (auto-minor-mode--plain-filename buffer-file-name)))
      (dolist (p alist)
        (let ((match (car p))
              (mode (cdr p)))
          (when (string-match-p match bufname)
            (unless (and keep-mode-if-same
                         (auto-minor-mode-enabled-p mode))
              (funcall mode 1))))))))

(defun auto-minor-mode--run-magic (alist keep-mode-if-same)
  "Run through a magic ALIST and enable all matching minor modes.

A magic alist contains pairs of regexps or functions to match the
buffer’s contents, and functions to call when matched.  For more
information, see ‘magic-mode-alist’.

If the optional argument KEEP-MODE-IF-SAME is non-nil, then we
don’t re-activate minor modes already enabled in the buffer."
  (dolist (p alist)
    (let ((match (car p))
          (mode (cdr p)))
      (goto-char (point-min))
      (when (if (functionp match) (funcall match) (looking-at match))
        (unless (and keep-mode-if-same
                     (auto-minor-mode-enabled-p mode))
          (funcall mode 1))))))

;;;###autoload
(defun auto-minor-mode-set (&optional keep-mode-if-same)
  "Enable all minor modes appropriate for the current buffer.

If the optional argument KEEP-MODE-IF-SAME is non-nil, then we
don’t re-activate minor modes already enabled in the buffer."
  (let ((case-fold-search t))
    (auto-minor-mode--run-auto auto-minor-mode-alist keep-mode-if-same))

  (save-excursion
    (save-restriction
      (narrow-to-region (point-min)
                        (min (point-max)
                             (+ (point-min) magic-mode-regexp-match-limit)))
      (let ((case-fold-search t))
        (auto-minor-mode--run-magic auto-minor-mode-magic-alist
                                    keep-mode-if-same)))))

;;;###autoload
(advice-add #'set-auto-mode :after #'auto-minor-mode-set)


;;;
;; use-package integration

(with-eval-after-load 'use-package
  (defalias 'use-package-normalize/:minor #'use-package-normalize-mode)
  (defalias 'use-package-normalize/:magic-minor #'use-package-normalize-mode)

  (defun use-package-handler/:minor (name _ arg rest state)
    (use-package-handle-mode name 'auto-minor-mode-alist arg rest state))

  (defun use-package-handler/:magic-minor (name _ arg rest state)
    (use-package-handle-mode name 'auto-minor-mode-magic-alist arg rest state))

  (when (and (fboundp #'use-package-handle-mode) ; added in 5bd87be
             (not (memq :minor use-package-keywords)))
    (let ((pos (cl-position :commands use-package-keywords)))
      (when pos
        (setq use-package-keywords
              (append (cl-subseq use-package-keywords 0 pos)
                      '(:minor :magic-minor)
                      (cl-subseq use-package-keywords pos)))))))


(provide 'auto-minor-mode)
;;; auto-minor-mode.el ends here
