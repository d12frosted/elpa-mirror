;;; edebug-inline-result.el --- Show Edebug result inline -*- lexical-binding: t; -*-

;; Authors: stardiviner <numbchild@gmail.com>
;; Package-Requires: ((emacs "25.1"))
;; Package-Version: 20210213.25
;; Package-Commit: 86a9ed9e4f58c2e9870b8918dc898ccd78d2d3f8
;; Version: 0.1
;; Keywords: extensions lisp tools
;; homepage: https://www.github.com/stardiviner/edebug-inline-result

;; edebug-inline-result is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; edebug-inline-result is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Usage:
;; [M-x edebug-inline-result-mode]

;;; Code:

(require 'edebug)

(declare-function posframe-show "ext:posframe.el" t t)
(declare-function posframe-hide "ext:posframe.el" t t)
(declare-function posframe-delete "ext:posframe.el" t t)
(declare-function popup-tip "ext:popup.el")
(declare-function quick-peek-show "ext:quick-peek.el")
(declare-function quick-peek-hide "ext:quick-peek.el")
(declare-function inline-docs "ext:inline-docs.el")
(declare-function pos-tip-show "ext:pos-tip.el" t t)


(defgroup edebug-inline-result nil
  "edebug-inline-result options."
  :prefix "edebug-inline-result-"
  :group 'edebug)

(defcustom edebug-inline-result-backend 'quick-peek
  "The popup backend for edebug-inline-result."
  :type '(choice
          (const :tag "posframe.el"    posframe)
          (const :tag "popup.el"       popup)
          (const :tag "quick-peek.el"  quick-peek)
          (const :tag "inline-docs.el" inline-docs)
          (const :tag "pos-tip.el"     pos-tip))
  :safe #'symbolp
  :group 'edebug-inline-result)

(defcustom edebug-inline-result-display-below t
  "Display inline result below current line."
  :type 'boolean
  :safe #'booleanp)

(defvar edebug-inline-result--buffer-name
  " *edebug-previous-result*"
  "The `edebug-inline-result' result buffer name in posframe.")

(defun edebug-inline-result--position (&optional position)
  "A helper function to return the POSITION to display inline result."
  (if edebug-inline-result-display-below
      ;; return next line of current position.
      (unwind-protect
          (let ((current-line-offset (- (point) (line-beginning-position))))
            (save-excursion
              (forward-line 1)
              (forward-char current-line-offset)
              (point))))
    (or position (point))))

(defun edebug-inline-result-show (&optional position)
  "Show variable `edebug-previous-result' with specific popup backend.
Optional argument POSITION ."
  (interactive)
  (let ((message-truncate-lines t))
    (pcase edebug-inline-result-backend
      ('posframe
       (posframe-show edebug-inline-result--buffer-name
                      :string (substring-no-properties edebug-previous-result)
                      :position (edebug-inline-result--position position)
                      :width (window-width)
                      :background-color
                      (if (eq (alist-get 'background-mode (frame-parameters)) 'dark)
                          "DarkCyan" "yellow")
                      :foreground-color
                      (if (eq (alist-get 'background-mode (frame-parameters)) 'dark)
                          "light gray" "black")
                      :internal-border-width 1))
      ('popup
       (popup-tip edebug-previous-result
                  :point (edebug-inline-result--position position)
                  :truncate t :height 20 :width 45 :nostrip t :margin 1 :nowait nil))
      ('quick-peek
       (quick-peek-show edebug-previous-result (edebug-inline-result--position position)))
      ('inline-docs
       (inline-docs edebug-previous-result))
      ('pos-tip
       (pos-tip-show edebug-previous-result 'popup-face)))))

(defun edebug-inline-result--hide-frame ()
  "Hide edebug result child-frame."
  (interactive)
  (pcase edebug-inline-result-backend
    ('posframe
     (posframe-hide edebug-inline-result--buffer-name))
    ('quick-peek
     (quick-peek-hide))))

(defun edebug-inline-result-enable ()
  "Enable function `edebug-inline-result-mode'."
  (advice-add 'edebug-previous-result :after #'edebug-inline-result-show)
  ;; (advice-add 'edebug-step-mode :after #'edebug-inline-result-show)
  ;; (advice-add 'edebug-next-mode :after #'edebug-inline-result-show)
  (advice-add 'top-level :before #'edebug-inline-result--hide-frame) ; advice on [q] quit
  ;; hide result when switching windows
  (add-function :after after-focus-change-function #'edebug-inline-result--hide-frame)
  ;; auto hide previous popup when press [n] next.
  (advice-add 'edebug-next-mode :before #'edebug-inline-result--hide-frame)
  (setq edebug-print-level  500)
  (setq edebug-print-length 500))

(defun edebug-inline-result-disable ()
  "Disable variable `edebug-inline-result-mode'."
  (advice-remove 'edebug-previous-result #'edebug-inline-result-show)
  ;; (advice-remove 'edebug-next-mode #'edebug-inline-result-show)
  (advice-remove 'top-level #'edebug-inline-result--hide-frame)
  (remove-function focus-out-hook #'edebug-inline-result--hide-frame)
  (advice-remove 'edebug-next-mode #'edebug-inline-result--hide-frame)
  ;; close result popup if not closed.
  (if (buffer-live-p (get-buffer edebug-inline-result--buffer-name))
      (posframe-delete edebug-inline-result--buffer-name))
  (setq edebug-print-level  (default-value 'edebug-print-level))
  (setq edebug-print-length (default-value 'edebug-print-length)))

(defvar edebug-inline-result-mode-map
  (let ((map (make-sparse-keymap)))
    map)
  "Edebug-inline-result-mode map.")

;;;###autoload
(define-minor-mode edebug-inline-result-mode
  "A minor mode that show Edebug result with inline style."
  :require 'edbeug-inline-result
  :init-value nil
  :global t
  :lighter ""
  :group 'edebug-inline-result
  :keymap 'edebug-inline-result-mode-map
  (if edebug-inline-result-mode
      (edebug-inline-result-enable)
    (edebug-inline-result-disable)))



(provide 'edebug-inline-result)

;;; edebug-inline-result.el ends here
