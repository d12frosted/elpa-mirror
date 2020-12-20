;;; elegant-agenda-mode.el --- An elegant theme for your org-agenda -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Justin Barclay

;; Author: Justin Barclay <justinbarclay@gmail.com>
;; URL: https://github.com/justinbarclay/elegant-agenda-mode
;; Package-Version: 20201118.558
;; Package-Commit: c72f42e0f551c3dd81e68262f07a96c0ec90a589
;; Version: 0.1.0-alpha
;; Package-Requires: ((emacs "26.1"))
;; Keywords: faces
;; Summary: A minimalist and elegant theme for org-agenda

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

;;; Commentary:

;; elegant-agenda-mode uses fonts, Yanone Kaffeesatz and typography to give your org-agenda some
;; breathing room and elegance. Screenshots can be found in the project repository.

;; This package was inspired by the work Nicolas Rougier.
;;; Code:

(eval-when-compile
  (declare-function face-remap-remove-relative "face-remap" t t)
  (defvar org-agenda-redo-command)
  (defvar org-agenda-use-time-grid)
  (defvar org-agenda-block-separator)
  (defvar org-agenda-use-time-grid)
  (defvar org-agenda-block-separator)
  (defvar org-tag-group-re))

;;; Customization
(defcustom elegant-agenda-font
  "Yanone Kaffeesatz"
  "The default font to use in an elegant agenda buffer."
  :type 'string
  :group 'elegant-agenda-mode)

;; Used to revert changes when elegant-agenda-mode is disabled.
(defvar-local elegant-agenda-transforms nil "A list of faces and their associated specs.")


(defvar elegant-agenda-face-remappings
  (let ((face-height (face-attribute 'default :height)))
    (list
     (list 'default (list :family elegant-agenda-font
                          :height (ceiling (* face-height 1.5)) :weight 'thin))
     (list 'header-line (list :family elegant-agenda-font
                              :height (* face-height 2) :weight 'thin
                              :underline nil  :overline nil :box nil))
     (list 'org-agenda-date-today (list :weight 'regular))
     (list 'org-agenda-structure (list :weight 'regular))
     (list 'bold (list :height (ceiling (* face-height 1.1)) :weight 'thin))))
  "A list of faces and the associated specs.

This list is used to control the styling in an elegant-agenda-buffer.")

(defun elegant-agenda--get-title ()
  "Set an applicable title in the agenda buffer.

The title is the name of the custom command used to generate the
current view. No title will be displayed if the view was
generated from a built in command."
  (when-let ((title (when (and org-agenda-redo-command
                               (stringp (cadr org-agenda-redo-command)))
                      (format "—  %s"
                              (mapconcat
                               #'identity
                               (split-string-and-unquote (cadr org-agenda-redo-command) "")
                               " "))))
             (width (window-width)))
    (setq-local header-line-format
                (format "%s%s" title (make-string (- width (length title)) ?— t)))))

;;;;;;;;;;;;;;;;;;;;;;;;;
;; Handle tag alignment
;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Proportional fonts cause an issue when tags are involved
;; https://lists.gnu.org/archive/html/emacs-orgmode/2020-05/msg00680.html
(defun elegant-agenda--string-display-pixel-width (string &optional mode)
  "Calculate pixel width of STRING.

Optional MODE specifies major mode used for display."
  (with-temp-buffer
    (with-silent-modifications
      (setf (buffer-string) string))
    (when (fboundp mode)
      (funcall mode)
      (font-lock-ensure))
    (if (not (get-buffer-window (current-buffer)))
        (save-window-excursion
          ;; Avoid errors if the selected window is a dedicated one,
          ;; and they just want to insert a document into it.
          (set-window-dedicated-p nil nil)
          (set-window-buffer nil (current-buffer))
          (car (window-text-pixel-size nil (line-beginning-position) (point))))
      (car (window-text-pixel-size nil (line-beginning-position) (point))))))

(defun elegant-agenda--fix-tag-alignment ()
  "Use 'display :align-to instead of spaces in agenda."
  (goto-char (point-min))
  (setq-local word-wrap nil)
  (while (re-search-forward org-tag-group-re nil 'noerror)
    (put-text-property (match-beginning 0)
                       (match-beginning 1)
                       'display
                       `(space . (:align-to
                                  (- right
                                     (,(elegant-agenda--string-display-pixel-width
                                        (match-string 1)))))))))

(defun elegant-agenda--finalize-view ()
  "Finalize the elegant agenda view."
  (elegant-agenda--fix-tag-alignment)
  (elegant-agenda--get-title))

(defun elegant-agenda--enable ()
  "Set-up the current buffer to be more elegant."
  (setq-local line-spacing 8)
  (setq-local org-agenda-use-time-grid nil)
  (setq-local org-agenda-block-separator "  ")
  (display-line-numbers-mode 0)
  (setq elegant-agenda-transforms
        (mapcar (lambda (face-&-spec)
                  (face-remap-add-relative (car face-&-spec) (cadr face-&-spec)))
                elegant-agenda-face-remappings))
  (setq-local mode-line-format nil)
  (add-hook 'org-agenda-finalize-hook #'elegant-agenda--finalize-view))

(defun elegant-agenda--disable ()
  "Reset the buffer's settings back to default.

For when you're tired of being elegant."
  (setq-local line-spacing (default-value 'line-spacing))
  (setq-local org-agenda-use-time-grid (default-value 'line-spacing))
  (setq-local org-agenda-block-separator (default-value 'org-agenda-block-separator))
  (mapc #'face-remap-remove-relative
        elegant-agenda-transforms)
  (remove-hook 'org-agenda-finalize-hook #'elegant-agenda--finalize-view)
  (setq-local elegant-agenda-transforms nil)

  (setq-local mode-line-format (default-value 'mode-line-format))
  (setq-local header-line-format nil))

;;;###autoload
(define-minor-mode elegant-agenda-mode
  "Provides a more elegant view into your agenda"
  :init-value nil :lighter " elegant-agenda" :keymap nil
  (if elegant-agenda-mode
      (elegant-agenda--enable)
    (elegant-agenda--disable))
  (force-window-update (current-buffer)))

(provide 'elegant-agenda-mode)
;;; elegant-agenda-mode.el ends here
