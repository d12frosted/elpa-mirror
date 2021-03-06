;;; -*- lexical-binding: t -*-
;;; scratch-palette.el --- make scratch buffer for each files

;; Copyright (C) 2012-2015 zk_phi

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

;; Version: 1.0.2
;; Package-Version: 20210306.427
;; Package-Commit: e4642ed8a2b744ba48a8e11ca83861f8e4b9c5b3
;; Author: zk_phi
;; URL: http://zk-phi.gitub.io/
;; Package-Requires: ((popwin "0.7.0alpha"))

;;; Commentary:

;; Require this script and set a directory to save scratches in.
;;
;;   (require 'scratch-palette)
;;   (setq scratch-palette-directory "~/.emacs.d/palette/")
;;
;; Then the command =M-x scratch-palette-popup= is available. This
;; command displays the scratch buffer for the file. When called with
;; region, the region is yanked to the scratch buffer.
;;
;; You may close note with one of =C-g=, =C-x C-x=, or =C-x C-k=. Its
;; contents are automatically saved.

;;; Change Log:

;; 1.0.0 first released
;; 1.0.1 minor fixes and refactorings
;; 1.0.2 yank region automatically
;;       palette detection on find-file
;; 1.0.3 require popwin

;;; Code:

(require 'popwin)

(defconst scratch-palette-version "1.0.3")

;; + customs

(defgroup scratch-palette nil
  "add scratch notes for each file"
  :group 'emacs)

(defcustom scratch-palette-directory "~/.emacs.d/palette/"
  "directory used to store palette files in"
  :type 'string
  :group 'scratch-palette)

;; + minor mode for scratch-palette buffers

(defvar scratch-palette-minor-mode-map
  (let ((kmap (make-sparse-keymap)))
    (define-key kmap (kbd "C-x C-k") 'scratch-palette-kill)
    (define-key kmap (kbd "C-x C-s") 'scratch-palette-kill)
    (define-key kmap (kbd "C-g")     'scratch-palette-kill)
    kmap)
  "keymap for scratch-palette buffers")

(define-minor-mode scratch-palette-minor-mode
  "minor mode for scratch-palette files"
  :init-value nil
  :global nil
  :keymap scratch-palette-minor-mode-map
  :lighter " Palette")

;; + utils

(defun scratch-palette--file-name (name)
  "get the scratch-palette filename for this buffer"
  (concat scratch-palette-directory
          (replace-regexp-in-string "[/:]" "!" name)))

;; + commands

(defun scratch-palette-kill ()
  "save and kill scratch-palette buffer"
  (interactive)
  ;; save (or delete if empty)
  (if (= (point-min) (point-max))
      (when (file-exists-p buffer-file-name)
        (delete-file buffer-file-name))
    (save-buffer))
  (kill-buffer)
  (popwin:close-popup-window))

;;;###autoload
(defun scratch-palette-popup ()
  "find the palette file and display it"
  (interactive)
  (unless buffer-file-name
    (error "not a file buffer"))
  (let ((file (scratch-palette--file-name buffer-file-name))
        (str (when (use-region-p)
               (prog1 (buffer-substring (region-beginning) (region-end))
                 (delete-region (region-beginning) (region-end))
                 (deactivate-mark)))))
    (popwin:find-file file)
    (rename-buffer "*Palette*")
    (scratch-palette-minor-mode 1)
    (when str
      (goto-char (point-max))
      (insert (concat "\n" str "\n")))))

;; + find-file hooks

(defun scratch-palette--find-file-hook ()
  (when (and buffer-file-name
             (file-exists-p (scratch-palette--file-name buffer-file-name)))
    (message "scratch-palette: scratch-palette detected.")
    (sit-for 0.5)))

(add-hook 'find-file-hook 'scratch-palette--find-file-hook)

;; * provide

(provide 'scratch-palette)

;;; scratch-palette.el ends here
