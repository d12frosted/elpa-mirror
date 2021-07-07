;;; ace-jump-zap.el --- Character zapping, `ace-jump-mode` style

;; Copyright (C) 2014  justin talbott

;; Author: justin talbott <justin@waymondo.com>
;; Keywords: convenience, tools, extensions
;; Package-Version: 20170717.1849
;; Package-Commit: 52b5d4c6c73bd0fc833a0dcb4e803a5287d8cae8
;; URL: https://github.com/waymondo/ace-jump-zap
;; Version: 0.1.2
;; Package-Requires: ((ace-jump-mode "1.0") (dash "2.10.0"))
;; License: GNU General Public License version 3, or (at your option) any later version
;;

;;; Commentary:
;;
;; Bind `(ace-jump-zap-up-to-char)' or `(ace-jump-zap-to-char)' to the
;; key-binding of your choice.

;;; Code:

(require 'ace-jump-mode)
(require 'dash)
(autoload 'zap-up-to-char "misc"
  "Kill up to, but not including ARGth occurrence of CHAR.")

(defvar ajz/zapping nil
  "Internal flag for detecting if currently zapping.")
(defvar ajz/to-char nil
  "Internal flag for determining if zapping to-char or up-to-char.")
(defvar ajz/saved-point nil
  "Internal variable for caching the current point.")

(defcustom ajz/zap-function 'delete-region
  "This is the function used for zapping between point and char.
The default is `delete-region' but it could also be `kill-region'.")

(defcustom ajz/forward-only nil
  "Set to non-nil to choose to only zap forward from the point.
Default will zap in both directions from the point in the current window.")

(defcustom ajz/sort-by-closest t
  "Non-nil means sort the zap candidates by proximity to the current point.
Set to nil for the default `ace-jump-mode' ordering.
Enabled by default as of 0.1.0.")

(defcustom ajz/52-character-limit t
  "Set to non-nil to limit zapping reach to the first 52 characters.
Enabled by default as of 0.1.0.")

(defun ajz/maybe-zap-start ()
  "Push the mark when zapping with `ace-jump-char-mode'."
  (when ajz/zapping
    (push-mark)))

(defun ajz/maybe-zap-end ()
  "Zap after jumping with `ace-jump-char-mode.'."
  (when ajz/zapping
    (if (ajz/forward-query)
        (when ajz/to-char (forward-char))
      (unless ajz/to-char (forward-char)))
    (cond ((eq ajz/zap-function 'delete-region)
           (call-interactively 'delete-region))
          ((eq ajz/zap-function 'kill-region)
           (kill-region (point) (mark))))
    (deactivate-mark))
  (ajz/reset))

(defun ajz/reset ()
  "Reset the internal zapping variable flags."
  (setq ajz/zapping nil)
  (setq ajz/saved-point nil)
  (setq ajz/to-char nil))

(defun ajz/keyboard-reset ()
  "Reset when `ace-jump-mode' is cancelled.
Also called when chosen character isn't found while zapping."
  (interactive)
  (ajz/reset)
  (ace-jump-done))

(defun ajz/forward-query ()
  "Filter for checking if jump candidate is after point."
  (< ajz/saved-point (point)))

(add-hook 'ace-jump-mode-before-jump-hook #'ajz/maybe-zap-start)

(add-hook 'ace-jump-mode-end-hook #'ajz/maybe-zap-end)

(defun ajz/closeness-to-point (c1 c2)
  "Compare C1 to C2 to determine closer candidate to point."
  (let* ((p1 (aj-position-offset c1))
         (p2 (aj-position-offset c2))
         (dist1 (if (< p1 ajz/saved-point)
                    (- p1 ajz/saved-point)
                  (- ajz/saved-point p1)))
         (dist2 (if (< p2 ajz/saved-point)
                    (- p2 ajz/saved-point)
                  (- ajz/saved-point p2))))
    (> dist1 dist2)))

(defun ajz/maybe-limit-candidate-length (args)
  "Limit the candidates to 52 when `ajz/52-character-limit' is non-nil."
  (if (and ajz/zapping ajz/52-character-limit (> (car args) 52))
      (list 52 (nth 1 args))
    args))

(advice-add 'ace-jump-tree-breadth-first-construct :filter-args #'ajz/maybe-limit-candidate-length)

(defun ajz/maybe-sort-candidate-list (args)
  "Maybe sort and limit the `ace-jump-mode' node-tree."
  (if ajz/zapping
      (let* ((candidate-list (nth 1 args))
             (candidate-list (if ajz/sort-by-closest
                                 (-sort 'ajz/closeness-to-point candidate-list)
                               candidate-list))
             (candidate-list (if ajz/52-character-limit
                                 (-take 52 candidate-list)
                               candidate-list)))
        (list (car args) candidate-list))
    args))

(advice-add 'ace-jump-populate-overlay-to-search-tree :filter-args #'ajz/maybe-sort-candidate-list)

;;;###autoload
(defun ace-jump-zap-up-to-char ()
  "Call `ace-jump-char-mode' and zap all characters up to the selected character."
  (interactive)
  (setq ajz/saved-point (point))
  (let ((ace-jump-mode-scope 'window)
        (ace-jump-search-filter (when ajz/forward-only 'ajz/forward-query)))
    (setq ajz/zapping t)
    (call-interactively 'ace-jump-char-mode)
    (when overriding-local-map
      (define-key overriding-local-map [t] 'ajz/keyboard-reset))))

;;;###autoload
(defun ace-jump-zap-to-char ()
  "Call `ace-jump-char-mode' and zap all characters up to and including the selected character."
  (interactive)
  (setq ajz/to-char t)
  (ace-jump-zap-up-to-char))

;;;###autoload
(defun ace-jump-zap-to-char-dwim (&optional prefix)
  "Without PREFIX, call `zap-to-char'.
With PREFIX, call `ace-jump-zap-to-char'."
  (interactive "P")
  (if prefix
      (ace-jump-zap-to-char)
    (call-interactively 'zap-to-char)))

;;;###autoload
(defun ace-jump-zap-up-to-char-dwim (&optional prefix)
  "Without PREFIX, call `zap-up-to-char'.
With PREFIX, call `ace-jump-zap-up-to-char'."
  (interactive "P")
  (if prefix
      (ace-jump-zap-up-to-char)
    (call-interactively 'zap-up-to-char)))

(provide 'ace-jump-zap)
;;; ace-jump-zap.el ends here
