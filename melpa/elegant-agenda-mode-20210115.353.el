;;; elegant-agenda-mode.el --- An elegant theme for your org-agenda -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Justin Barclay

;; Author: Justin Barclay <justinbarclay@gmail.com>
;; URL: https://github.com/justinbarclay/elegant-agenda-mode
;; Package-Version: 20210115.353
;; Package-Commit: 5cbc688584ba103ea3be7d7b30e5d94e52f59eb6
;; Version: 0.2.0
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

;; elegant-agenda-mode has a very small amount of customization.

;; If you want to change the font family used in the buffer you could would set elegant-agenda-font
;; ex: (setq elegant-agenda-font "Roboto Mono")

;; Then if you use a mono spaced font you'll also want to let elegant-agenda to know about that.
;; ex: (setq elegant-agenda-is-mono-font 't)

;; This package was inspired by work from Nicolas Rougier.
;;; Code:

(eval-when-compile
  (declare-function face-remap-remove-relative "face-remap" t t)
  (declare-function org-add-props "org-macs" t t)
  (declare-function org-font-lock-add-tag-faces "org" t t)
  (defvar org-agenda-redo-command)
  (defvar org-agenda-tags-column)
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

(defcustom elegant-agenda-is-mono-font nil
  "Describes whether the font elegant agenda is using is monospace.

This controls whether elegant-agenda applies tag fixes."
  :type 'boolean
  :group 'elegant-agenda-mode)

(defcustom elegant-agenda-header-preference 'regular
  "A choice of what style to set headers in elegant-agenda-mode"
  :type '(radio (const :tag "Thin" thin)
                (const :tag "Regular" regular))
  :group 'elegant-agenda-mode)

;; Used to revert changes when elegant-agenda-mode is disabled.
(defvar-local elegant-agenda-transforms nil "A list of faces and their associated specs.")

(defun elegant-agenda--face-remappings ()
  "Generates a list of faces and the associated specs.

This list is used to control the styling in an elegant-agenda-buffer."
  (let ((face-height (face-attribute 'default :height)))
    (list
     (list 'default (list :family elegant-agenda-font
                          :height (ceiling (* face-height 1.5)) :weight 'thin))
     (list 'header-line (list :family elegant-agenda-font
                              :height (* face-height 2) :weight 'thin
                              :underline nil  :overline nil :box nil))
     (list 'org-agenda-date-today (list :weight 'regular))
     (list 'org-agenda-done (list :weight 'thin))
     (list 'org-agenda-structure (list :weight 'regular))
     (list 'bold (list :height (ceiling (* face-height 1.1)) :weight 'thin)))))

(defun elegant-agenda--thin-face-remappings ()
  "A list of faces that strive to be thin or light.

This list is used to control the styling in an elegant-agenda-buffer."
  (let ((face-height (face-attribute 'default :height)))
    (list
     (list 'default (list :family elegant-agenda-font
                          :height (ceiling (* face-height 1.5)) :weight 'thin))
     (list 'header-line (list :family elegant-agenda-font
                              :height (* face-height 2) :weight 'thin
                              :underline nil  :overline nil :box nil))
     (list 'org-agenda-date-today (list :weight 'thin :height (ceiling (* face-height 1.8))))
     (list 'org-agenda-structure (list :weight 'thin :height (ceiling (* face-height 1.9))))
     (list 'org-agenda-done (list :weight 'thin))
     (list 'bold (list :height (ceiling (* face-height 1.1)) :weight 'thin))
     (list 'org-agenda-date-weekend (list :weight 'thin :height (ceiling (* face-height 1.7))))
     (list 'org-agenda-date (list :weight 'thin :height (ceiling (* face-height 1.7)))))))

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

(defun elegant-agenda--align-tags (&optional line)
  "Align all tags in agenda items to `org-agenda-tags-column'.
When optional argument LINE is non-nil, align tags only on the
current line.

This is mostly copy and pasted from the org-agenda file, but
reworked based on default font size and not default frame font
size."
  (let ((inhibit-read-only t)
	(org-agenda-tags-column (if (eq 'auto org-agenda-tags-column)
				    (- (floor (/ (window-text-width nil 't)
                                                 (window-font-width nil 'default))))
				  org-agenda-tags-column))
	(end (and line (line-end-position)))
	l c)
    (save-excursion
      (goto-char (if line (line-beginning-position) (point-min)))
      (while (re-search-forward org-tag-group-re end t)
	(add-text-properties
	 (match-beginning 1) (match-end 1)
	 (list 'face (delq nil (let ((prop (get-text-property
					    (match-beginning 1) 'face)))
				 (or (listp prop) (setq prop (list prop)))
				 (if (memq 'org-tag prop)
				     prop
				   (cons 'org-tag prop))))))
	(setq l (string-width (match-string 1))
	      c (if (< org-agenda-tags-column 0)
		    (- (abs org-agenda-tags-column) l)
		  org-agenda-tags-column))
	(goto-char (match-beginning 1))
	(delete-region (save-excursion (skip-chars-backward " \t") (point))
		       (point))
	(insert (org-add-props
		    (make-string (max 1 (- c (current-column))) ?\s)
		    (plist-put (copy-sequence (text-properties-at (point)))
			       'face nil))))
      (goto-char (point-min))
      (org-font-lock-add-tag-faces (point-max)))))

(defun elegant-agenda--finalize-view ()
  "Finalize the elegant agenda view."
  (elegant-agenda--get-title)
  (if (not elegant-agenda-is-mono-font)
      (elegant-agenda--fix-tag-alignment)
    (elegant-agenda--align-tags)))

(defun elegant-agenda--enable ()
  "Set-up the current buffer to be more elegant."
  (setq-local line-spacing 8)
  (setq-local org-agenda-use-time-grid nil)
  (setq-local org-agenda-block-separator "  ")
  (display-line-numbers-mode 0)
  (setq elegant-agenda-transforms
        (mapcar (lambda (face-&-spec)
                  (face-remap-add-relative (car face-&-spec) (cadr face-&-spec)))
                (if (eq elegant-agenda-header-preference 'thin)
                    (elegant-agenda--thin-face-remappings)
                  (elegant-agenda--face-remappings))))
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
