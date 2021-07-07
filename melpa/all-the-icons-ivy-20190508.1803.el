;;; all-the-icons-ivy.el --- Shows icons while using ivy and counsel  -*- lexical-binding: t; -*-

;; Copyright (C) 2017 asok

;; Author: asok
;; Version: 0.5.0
;; Package-Version: 20190508.1803
;; Package-Commit: a70cbfa1effe36efc946a823a580cec686d5e88d
;; Keywords: faces
;; Package-Requires: ((emacs "24.4") (all-the-icons "2.4.0") (ivy "0.8.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; To use this package, do
;;
;; (all-the-icons-ivy-setup)
;;
;; Or if you prefer to only set transformers
;; for a subset of ivy commands:
;;
;; (require 'all-the-icons-ivy)
;; (ivy-set-display-transformer 'ivy-switch-buffer 'all-the-icons-ivy-buffer-transformer)

;;; Code:

(require 'all-the-icons)
(require 'ivy)

(defface all-the-icons-ivy-dir-face
  '((((background dark)) :foreground "white")
    (((background light)) :foreground "black"))
  "Face for the dir icons used in ivy"
  :group 'all-the-icons-faces)

(defgroup all-the-icons-ivy nil
  "Shows icons while using ivy and counsel."
  :group 'ivy)

(defcustom all-the-icons-ivy-buffer-commands
  '(ivy-switch-buffer ivy-switch-buffer-other-window counsel-projectile-switch-to-buffer)
  "Commands to use with `all-the-icons-ivy-buffer-transformer'."
  :type '(repeat function)
  :group 'all-the-icons-ivy)

(defcustom all-the-icons-spacer
  "\t"
  "The string used as the space between the icon and the candidate."
  :type 'string
  :group 'all-the-icons-ivy)

(defcustom all-the-icons-ivy-family-fallback-for-buffer
  'all-the-icons-faicon
  "Icon font family used as a fallback when no icon for buffer transformer can be found."
  :type 'function
  :options all-the-icons-font-families
  :group 'all-the-icons-ivy)

(defcustom all-the-icons-ivy-name-fallback-for-buffer
  "sticky-note-o"
  "Icon font name used as a fallback when no icon for buffer transformer can be found."
  :type 'string
  :options all-the-icons-font-names
  :group 'all-the-icons-ivy)

(defcustom all-the-icons-ivy-file-commands
  '(counsel-find-file
    counsel-file-jump
    counsel-recentf
    counsel-projectile
    counsel-projectile-find-file
    counsel-projectile-find-dir
    counsel-git)
  "Commands to use with `all-the-icons-ivy-file-transformer'."
  :type '(repeat function)
  :group 'all-the-icons-ivy)

(defun all-the-icons-ivy--buffer-propertize (b s)
  "If buffer B is modified apply `ivy-modified-buffer' face on string S."
  (if (and (buffer-file-name b)
           (buffer-modified-p b))
      (propertize s 'face 'ivy-modified-buffer)
    s))

(defun all-the-icons-ivy--icon-for-mode (mode)
  "Apply `all-the-icons-for-mode' on MODE but either return an icon or nil."
  (let ((icon (all-the-icons-icon-for-mode mode)))
    (unless (symbolp icon)
      icon)))

(defun all-the-icons-ivy--buffer-transformer (b s)
  "Return a candidate string for buffer B named S preceded by an icon.
Try to find the icon for the buffer's B `major-mode'.
If that fails look for an icon for the mode that the `major-mode' is derived from."
  (let ((mode (buffer-local-value 'major-mode b)))
    (format (concat "%s" all-the-icons-spacer "%s")
            (propertize "\t" 'display (or
                                       (all-the-icons-ivy--icon-for-mode mode)
                                       (all-the-icons-ivy--icon-for-mode (get mode 'derived-mode-parent))
                                       (funcall
                                        all-the-icons-ivy-family-fallback-for-buffer
                                        all-the-icons-ivy-name-fallback-for-buffer)))
            (all-the-icons-ivy--buffer-propertize b s))))

(defun all-the-icons-ivy-icon-for-file (s)
  "Return icon for filename S.
Return the octicon for directory if S is a directory.
Otherwise fallback to calling `all-the-icons-icon-for-file'."
  (cond
   ((string-match-p "\\/$" s)
    (all-the-icons-octicon "file-directory" :face 'all-the-icons-ivy-dir-face))
   (t (all-the-icons-icon-for-file s))))

(defun all-the-icons-ivy-file-transformer (s)
  "Return a candidate string for filename S preceded by an icon."
  (format (concat "%s" all-the-icons-spacer "%s")
          (propertize "\t" 'display (all-the-icons-ivy-icon-for-file s))
          s))

(defun all-the-icons-ivy-buffer-transformer (s)
  "Return a candidate string for buffer named S.
Assume that sometimes the buffer named S might not exists.
That can happen if `ivy-switch-buffer' does not find the buffer and it
falls back to `ivy-recentf' and the same transformer is used."
  (let ((b (get-buffer s)))
    (if b
        (all-the-icons-ivy--buffer-transformer b s)
      (all-the-icons-ivy-file-transformer s))))

;;;###autoload
(defun all-the-icons-ivy-setup ()
  "Set ivy's display transformers to show relevant icons next to the candidates."
  (dolist (cmd all-the-icons-ivy-buffer-commands)
    (ivy-set-display-transformer cmd 'all-the-icons-ivy-buffer-transformer))
  (dolist (cmd all-the-icons-ivy-file-commands)
    (ivy-set-display-transformer cmd 'all-the-icons-ivy-file-transformer)))

(provide 'all-the-icons-ivy)

;;; all-the-icons-ivy.el ends here
