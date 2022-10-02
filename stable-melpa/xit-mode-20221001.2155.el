;;; xit-mode.el --- A [x]it! major mode -*- lexical-binding: t; -*-

;; See: https://xit.jotaen.net/

;; Copyright (C) 2022 Ryan Olson

;; Authors: Ryan Olson <ryolson@me.com>
;; URL: https://github.com/ryanolsonx/xit-mode
;; Package-Version: 20221001.2155
;; Package-Commit: a64498f718bb0fc62e855bee4da121341d9716db
;; Version: 0.3
;; Package-Requires: ((emacs "24.1"))
;; Keywords: xit, todo, tools, convinience, project

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

;; Versions:
;;
;;   - 0.3 melpa recipe is now available
;;   - 0.2 adding interactivity with keybindings and imenu support
;;   - 0.1 initial release with syntax color support

;;; Code:

;; Faces

(defface xit-group-title-face
  '((t :inherit (bold underline)))
  "Face used for checkboxes group title."
  :group 'xit-faces)

(defface xit-open-checkbox-face
  '((t :inherit font-lock-function-name-face))
  "Face used for open checkbox."
  :group 'xit-faces)

(defface xit-open-description-face
  '((t :inherit default))
  "Face used for open checkbox description."
  :group 'xit-faces)

(defface xit-checked-checkbox-face
  '((t :inherit success))
  "Face used for checked checkbox."
  :group 'xit-faces)

(defface xit-checked-description-face
  '((t :inherit font-lock-comment-face))
  "Face used for checked checkbox description."
  :group 'xit-faces)

(defface xit-ongoing-checkbox-face
  '((t :inherit font-lock-keyword-face))
  "Face used for ongoing checkbox."
  :group 'xit-faces)

(defface xit-ongoing-description-face
  '((t :inherit default))
  "Face used for ongoing checkbox description."
  :group 'xit-faces)

(defface xit-obsolete-checkbox-face
  '((t :inherit font-lock-comment-delimiter-face))
  "Face used for obsolete checkbox."
  :group 'xit-faces)

(defface xit-obsolete-description-face
  '((t :inherit font-lock-comment-face))
  "Face used for obsolete checkbox description."
  :group 'xit-faces)

(defface xit-priority-face
  '((t :inherit error))
  "Face used for priority markers ! or ."
  :group 'xit-faces)

(defface xit-tag-face
  '((t :inherit font-lock-constant-face))
  "Face used for tags."
  :group 'xit-faces)

;; Variables

(defvar xit-mode-hook nil)

(defvar xit-imenu-function 'xit-imenu-groups-and-items)

(defvar xit--group-title-regexp "^[a-zA-Z]+.*$"
  "The regepx used to search for group titles.")

(defvar xit--open-checkbox-regexp "^\\(\\[ \\]\\) [\\!|\\.]*\\(.*\\)"
  "The regepx used to search for open checkboxes.")

(defvar xit--checked-checkbox-regexp "^\\(\\[x\\]\\) \\(.*\\)"
  "The regepx used to search for checked checkboxes.")

(defvar xit--ongoing-checkbox-regexp "^\\(\\[@\\]\\) [\\!|\\.]*\\(.*\\)"
  "The regepx used to search for ongoing checkboxes.")

(defvar xit--obsolete-checkbox-regexp "^\\(\\[~\\]\\) \\(.*\\)"
  "The regepx used to search for obsolete checkboxes.")

(defvar xit--checkbox-regexp "^\\(\\[[ |x|@|~]\\] \\)"
  "The regpexp used to search for the checkbox.")

(defvar xit--priority-regexp "\\([\\!|\\.]+ \\)"
  "The regpexp used to search for the priority.")

(defvar xit--checkbox-priority-regexp "^\\[[x|@| |~]\\] \\([\\!|\\.]+\\)[^\\!|\\.]"
  "The regpexp used to search for the checkbox and the priority.")

(defvar xit--tag-regexp "#[a-zA-Z0-9\\-_]+"
  "The regpexp used to search for tags.")

(defvar xit--checkbox-open-string "[ ] "
  "The open checkbox string.")

(defvar xit--checkbox-checked-string "[x] "
  "The checked checkbox string.")

(defvar xit--checkbox-ongoing-string "[@] "
  "The progress checkbox string.")

(defvar xit--checkbox-obsolete-string "[~] "
  "The obsolete checkbox string.")

;; Keymap functions

(defun xit-new-item ()
  "Create a new open item."
  (interactive)
  (beginning-of-line)
  (insert "[ ] \n")
  (forward-line -1)
  (end-of-line))

(defun xit--item-replace-checkbox (reg rep)
  "Replace the current item checkbox spotted by REG with REP."
  (save-restriction
    (narrow-to-region (line-beginning-position) (line-end-position))
    (goto-char (point-min))
    (when (re-search-forward reg nil t)
      (replace-match rep))))

(defun xit-open-item ()
  "Set an item as open."
  (interactive)
  (xit--item-replace-checkbox xit--checkbox-regexp xit--checkbox-open-string))

(defun xit-checked-item ()
  "Set an item as checked."
  (interactive)
  (xit--item-replace-checkbox xit--checkbox-regexp xit--checkbox-checked-string))

(defun xit-ongoing-item ()
  "Set an item as ongoing."
  (interactive)
  (xit--item-replace-checkbox xit--checkbox-regexp xit--checkbox-ongoing-string))

(defun xit-obsolete-item ()
  "Set an item as obsolete."
  (interactive)
  (xit--item-replace-checkbox xit--checkbox-regexp xit--checkbox-obsolete-string))

(defun xit-state-cycle-item ()
  "Cycle through items states."
  (interactive)
  (save-restriction
    (narrow-to-region (line-beginning-position) (line-end-position))
    (goto-char (point-min))
    (when (re-search-forward xit--checkbox-regexp nil t)
      (let ((checkbox (match-string-no-properties 0)))
        (cond
         ((string-equal checkbox xit--checkbox-open-string)
          (replace-match xit--checkbox-ongoing-string))
         ((string-equal checkbox xit--checkbox-ongoing-string)
          (replace-match xit--checkbox-checked-string))
         ((string-equal checkbox xit--checkbox-checked-string)
          (replace-match xit--checkbox-obsolete-string))
         ((string-equal checkbox xit--checkbox-obsolete-string)
          (replace-match xit--checkbox-open-string))
         (t (warn "Checkbox not found")))))))

(defun xit-inc-priority-item ()
  "Increase item priority."
  (interactive)
  (save-restriction
    (narrow-to-region (line-beginning-position) (line-end-position))
    (goto-char (point-min))
    (if (re-search-forward xit--priority-regexp nil t)
        (replace-match (concat "!" (match-string-no-properties 1)))
      (when (re-search-forward xit--checkbox-regexp nil t)
        (replace-match "\\1! ")))))

(defun xit-dec-priority-item ()
  "Decrease item priority."
  (interactive)
  (save-restriction
    (narrow-to-region (line-beginning-position) (line-end-position))
    (goto-char (point-min))
    (when (re-search-forward xit--priority-regexp nil t)
      (let ((s (substring (match-string-no-properties 1) 1)))
        (if (string-equal s " ")
            (replace-match "")
          (replace-match s))))))

;; Keymap definition

(defvar xit-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-n") 'xit-new-item) ;; n for new
    (define-key map (kbd "C-c C-o") 'xit-open-item) ;; o for open
    (define-key map (kbd "C-c C-d") 'xit-checked-item) ;; d for done
    (define-key map (kbd "C-c C-p") 'xit-ongoing-item) ;; p for progress
    (define-key map (kbd "C-c C-a") 'xit-obsolete-item) ;; a for archive
    (define-key map (kbd "C-c C-c") 'xit-state-cycle-item) ;; c for cycle
    (define-key map (kbd "C-c C-<up>") 'xit-inc-priority-item)
    (define-key map (kbd "C-c C-<down>") 'xit-dec-priority-item)
    map)
  "Keymap for `xit-mode'.")

;; Syntax highlighting

;; descriptions disabled until tags in descriptions are resolved.
;; right now tags don't display if a description has a face.
(defvar xit-mode-font-lock-keywords
  (list
   `(,xit--group-title-regexp 0 'xit-group-title-face)
   `(,xit--open-checkbox-regexp
     (1 'xit-open-checkbox-face))
     ;;(2 'xit-open-description-face))
   `(,xit--checked-checkbox-regexp
     (1 'xit-checked-checkbox-face))
     ;;(2 'xit-checked-description-face))
   `(,xit--ongoing-checkbox-regexp
     (1 'xit-ongoing-checkbox-face))
     ;;(2 'xit-ongoing-description-face))
   `(,xit--obsolete-checkbox-regexp
     (1 'xit-obsolete-checkbox-face)
     (2 'xit-obsolete-description-face))
   `(,xit--checkbox-priority-regexp 1 'xit-priority-face)
   `(,xit--tag-regexp 0 'xit-tag-face))
  "Highlighting specification for `xit-mode'.")

;; Imenu support

(defun xit-imenu-groups ()
  "Extract groups for imenu index from the current file."
  (let ((imenu-data '()))
    (save-excursion
      (goto-char (point-min))
      (save-match-data
        (while (re-search-forward xit--group-title-regexp nil t)
          (push (cons (match-string-no-properties 0)
                      (car (match-data 1)))
                imenu-data))))
    imenu-data))

(defun xit-imenu-groups-and-items ()
  "Extract groups and items for imenu index from the current file."
  (let ((imenu-data '())
        (items-buffer '())
        (last-group ""))
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (let* ((line (substring-no-properties (buffer-substring (point) (point-at-eol))))
               (trimmed-line (replace-regexp-in-string "\n$" "" line))
               (item-text (replace-regexp-in-string
                           xit--checkbox-regexp ""
                           (replace-regexp-in-string
                            xit--priority-regexp ""
                            trimmed-line))))
          (cond ((string-match xit--checkbox-regexp line)
                 (push (cons item-text (point)) items-buffer))
                ((string-match xit--group-title-regexp line)
                 (setq last-group trimmed-line))
                ((string-match "" line)
                 (when (not (null items-buffer))
                   (if (not (string-equal last-group ""))
                       (push (cons last-group (nreverse items-buffer)) imenu-data)
                     (setq imenu-data (append items-buffer imenu-data))))
                 (setq last-group "")
                 (setq items-buffer '()))))
        (beginning-of-line 2))
      (when (not (null items-buffer))
        (if (not (string-equal last-group ""))
            (push (cons last-group (nreverse items-buffer)) imenu-data)
          (setq imenu-data (append items-buffer imenu-data)))))
    (nreverse imenu-data)))

;; Mode definition

;;;###autoload
(define-derived-mode xit-mode text-mode "[x]it!"
  "Major mode for [x]it files."
  (use-local-map xit-mode-map)
  (setq font-lock-defaults '(xit-mode-font-lock-keywords))
  (setq imenu-sort-function 'imenu--sort-by-name)
  (setq imenu-create-index-function xit-imenu-function)
  (run-hooks 'xit-mode-hook))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.xit\\'" . xit-mode))

(provide 'xit-mode)
;;; xit-mode.el ends here
