;;; side-hustle.el --- Hustle through Imenu in a side window  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Paul W. Rankin

;; Author: Paul W. Rankin <pwr@bydasein.com>
;; Keywords: convenience
;; Package-Version: 20210627.701
;; Package-Commit: 1f4cd5e7cfbabb00c6d87e913770f21e3d16c957
;; Version: 0.2.0
;; Package-Requires: ((emacs "24.4") (seq "2.20"))
;; URL: https://github.com/rnkn/side-hustle

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Side Hustle
;; ===========

;; Hustle through a buffer's Imenu in a side window in GNU Emacs.

;; Side Hustle spawns a side window linked to the current buffer, which allows
;; working with multiple buffers simultaneously.


;; Installation
;; ------------

;; The latest stable release of Side Hustle is available via [MELPA-stable][1].
;; First, add MELPA-stable to your package archives:

;;     M-x customize-option RET package-archives RET

;; Insert an entry named melpa-stable with URL:
;; https://stable.melpa.org/packages/

;; You can then find the latest stable version of side-hustle in the list
;; returned by:

;;     M-x list-packages RET

;; If you prefer the latest but perhaps unstable version, do the above using
;; [MELPA][2].

;; Then add a key binding to your init file:

;;     (define-key (current-global-map) (kbd "M-s l") #'side-hustle-toggle)


;; Bugs and Feature Requests
;; -------------------------

;; Send me an email (address in the package header). For bugs, please
;; ensure you can reproduce with:

;;     $ emacs -Q -l side-hustle.el

;; Known issues are tracked with FIXME comments in the source.


;; Alternatives
;; ------------

;; Side Hustle takes inspiration primarily from
;; [imenu-list](https://github.com/bmag/imenu-list).


;; [1]: https://stable.melpa.org/#/side-hustle
;; [2]: https://melpa.org/#/side-hustle

;;; Code:

(require 'imenu)

(defgroup side-hustle nil
  "Navigate Imenu in a side window."
  :group 'convenience
  :group 'matching
  :link '(info-link "(emacs) Imenu"))


;;; Internal Variables ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar-local side-hustle--source-buffer nil)
(defvar-local side-hustle--hidden nil)


;;; User Options ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcustom side-hustle-display-alist
  '((side . left)
    (slot . 0)
    (window-width . 40))
  "Alist used to display side-hustle buffer."
  :type 'alist
  :group 'side-hustle
  :link '(info-link "(elisp) Buffer Display Action Alists"))

(defcustom side-hustle-select-window t
  "When non-nil, select the menu window after creating it."
  :type 'boolean
  :safe 'booleanp
  :group 'side-hustle)

(defcustom side-hustle-persistent-window nil
  "When non-nil, make the side-window persistent.
This requires either calling `quit-window' or
`side-hustle-toggle' to quit the side-window."
  :type 'boolean
  :safe 'booleanp
  :group 'side-hustle)

(defcustom side-hustle-evaporate-window nil
  "When non-nil, quit the side window when following link."
  :type 'boolean
  :safe 'booleanp
  :group 'side-hustle)

(defcustom side-hustle-item-char ?\*
  "Character to use to itemize `imenu' items."
  :type '(choice (const nil) character)
  :group 'side-hustle)

(defcustom side-hustle-indent-width 4
  "Indent width in columns for sublevels of `imenu' items."
  :type 'integer
  :safe 'integerp
  :group 'side-hustle)


;;; Faces ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defface side-hustle
  '((t (:underline nil :inherit button)))
  "Default face for side-window items."
  :group 'side-hustle)

;; (defface side-hustle-highlight
;;   '((t (:extend t :inherit (secondary-selection))))
;;   "Default face for highlighted items."
;;   :group 'side-hustle)


;;; Internal Functions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun side-hustle-button-ensure ()
  "Ensure point is at button."
  (or (button-at (point))
      (and (eolp) (forward-button -1 nil nil t))
      (forward-button 1 nil nil t)))

(defun side-hustle-pop-to-marker (button save-window)
  "Pop up buffer containing `imenu' item for BUTTON.
Handle buffer according to SAVE-WINDOW or value of
`side-hustle-evaporate-window'."
  (let ((buffer (current-buffer))
        (marker (button-get button 'hustle-marker)))
    (when (markerp marker)
      (pop-to-buffer (marker-buffer marker))
      (goto-char (marker-position marker))
      (recenter-top-bottom)
      (cond (save-window
             (select-window (get-buffer-window buffer (selected-frame))))
            (side-hustle-evaporate-window
             (quit-window nil (get-buffer-window buffer (selected-frame))))))))

(defun side-hustle-switch-hide-state (label)
  "Toggle inclusion of LABEL in `side-hustle--hidden'."
  (setq side-hustle--hidden
        (if (member label side-hustle--hidden)
            (remove label side-hustle--hidden)
          (cons label side-hustle--hidden))))

(defun side-hustle-show-hide (start end)
  "Toggle invisibility of items between START and END."
  (with-silent-modifications
    (if (eq (get-text-property (button-end (button-at (point))) 'invisible)
            'hustle-invisible)
        (put-text-property start end 'invisible nil)
      (put-text-property start end 'invisible 'hustle-invisible))))

(defun side-hustle-button-action (button &optional hide save-window)
  "Call appropriate button action for BUTTON.
When HIDE is non-nil, always hide child items. Pass SAVE-WINDOW
to `side-hustle-pop-to-marker'."
  (let ((level (button-get button 'hustle-level))
        (label (button-label button))
        (start (button-end button))
        (end   (button-end button)))
    (save-excursion
      (while (and (forward-button 1 nil nil t)
                  (< level (button-get (button-at (point)) 'hustle-level)))
        (setq end (button-end (button-at (point))))))
    (cond ((= start end)
           (side-hustle-pop-to-marker button save-window))
          (hide
           (side-hustle-show-hide start end))
          (t
           (side-hustle-show-hide start end)
           (side-hustle-switch-hide-state label)))))

(defun side-hustle-insert (item level)
  "Insert ITEM at indentation level LEVEL.
And `imenu' marker as button property."
  (insert (make-string level ?\t))
  (when (characterp side-hustle-item-char)
    (insert side-hustle-item-char "\s"))
  (insert-text-button (car item)
                      'hustle-marker (cdr item)
                      'hustle-level level
                      'face 'side-hustle
                      'action #'side-hustle-button-action
                      'help-echo "mouse-1, RET: go to this item; SPC: show this item"
                      'follow-link t)
  (insert ?\n))

(defun side-hustle-insert-items (imenu-items level)
  "For each item in IMENU-ITEMS, insert appropriately.
Either call `side-hustle-insert' at LEVEL, or if item is an
alist, insert alist string and increment LEVEL before calling
recursively with `cdr'."
  (mapc
   (lambda (item)
     (if (imenu--subalist-p item)
         (progn
           (side-hustle-insert item level)
           (side-hustle-insert-items (cdr item) (1+ level)))
       (side-hustle-insert item level)))
   imenu-items))

(defun side-hustle-refresh ()
  "Rebuild and insert `imenu' entries for source buffer."
  (interactive)
  (with-silent-modifications
    (let ((x (point))
          imenu-items)
      (when (buffer-live-p side-hustle--source-buffer)
        (setq imenu-items
              (with-current-buffer side-hustle--source-buffer
                (setq imenu--index-alist nil)
                (imenu--make-index-alist t)
                imenu--index-alist)))
      (erase-buffer)
      (setq header-line-format (buffer-name side-hustle--source-buffer))
      (setq tab-width side-hustle-indent-width)
      (when imenu-items (side-hustle-insert-items imenu-items 0))
      (goto-char (point-min))
      (let (button)
        (while (setq button (forward-button 1 nil nil t))
          (when (member (button-label button) side-hustle--hidden)
            (side-hustle-button-action button t))))
      (goto-char x))))

(defun side-hustle-find-existing (sourcebuf)
  "Return existing `side-hustle' buffer for SOURCEBUF or nil if none."
  (seq-find
   (lambda (buf)
     (with-current-buffer buf
       (eq side-hustle--source-buffer sourcebuf)))
   (buffer-list)))

(defun side-hustle-get-buffer-create (sourcebuf)
  "Get or create `side-hustle' buffer for SOURCEBUF."
  (or (side-hustle-find-existing sourcebuf)
      (let ((new-buf (get-buffer-create
                      (concat "Side-Hustle: " (buffer-name sourcebuf)))))
        (with-current-buffer new-buf
          (side-hustle-mode)
          (setq side-hustle--source-buffer sourcebuf)
          (setq side-hustle--hidden nil))
        new-buf)))

;; (defun side-hustle-highlight-current ()
;;   "Highlight the current `imenu' item in `side-hustle'.
;; Added to `window-configuration-change-hook'."
;;   (unless (or (minibuffer-window-active-p (selected-window))
;;               (eq major-mode 'side-hustle-mode))
;;     (let ((x (point))
;;           (buf (side-hustle-find-existing (current-buffer)))
;;           candidate diff)
;;       (when (and buf (window-live-p (get-buffer-window buf)))
;;         (with-current-buffer buf
;;           (with-silent-modifications
;;             (remove-text-properties (point-min) (point-max) '(face))
;;             (goto-char (point-min))
;;             (while (< (point) (point-max))
;;               (let ((marker (get-text-property (point) 'side-hustle-imenu-marker)))
;;                 (when (and (markerp marker)
;;                            (<= (marker-position marker) x)
;;                            (or (null diff) (< (- x (marker-position marker)) diff)))
;;                   (setq candidate (point)
;;                         diff (if diff
;;                                  (min diff (- x (marker-position marker)))
;;                                (- x (marker-position marker))))))
;;               (forward-line 1))
;;             (when candidate
;;               (goto-char candidate)
;;               (put-text-property (line-beginning-position 1)
;;                                  (line-beginning-position 2)
;;                                  'face 'side-hustle-highlight))))))))


;;; Commands ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun side-hustle-goto-item ()
  "Go to the `imenu' item at point in other window."
  (interactive)
  (when (side-hustle-button-ensure)
    (side-hustle-button-action (button-at (point)))))

(defun side-hustle-show-item ()
  "Display the `imenu' item at point in other window."
  (interactive)
  (when (side-hustle-button-ensure)
    (side-hustle-button-action (button-at (point)) nil t)))

;;;###autoload
(defun side-hustle-toggle ()
  "Pop up a side window containing `side-hustle'."
  (interactive)
  (if (eq major-mode 'side-hustle-mode)
      (quit-window)
    (let ((display-buffer-mark-dedicated t)
          (buf (side-hustle-get-buffer-create (current-buffer))))
      (if (get-buffer-window buf (selected-frame))
          (delete-windows-on buf (selected-frame))
        (display-buffer-in-side-window
         buf (append side-hustle-display-alist
                     (when side-hustle-persistent-window
                       (list '(window-parameters
                               (no-delete-other-windows . t))))))
        (with-current-buffer buf (side-hustle-refresh))
        ;; (side-hustle-highlight-current)
        (when side-hustle-select-window
          (select-window (get-buffer-window buf (selected-frame))))))))

;; (defalias 'toggle-side-hustle #'side-hustle-toggle)


;;; Mode Definition ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar side-hustle-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "p") #'previous-line)
    (define-key map (kbd "n") #'next-line)
    (define-key map (kbd "q") #'quit-window)
    (define-key map (kbd "g") #'side-hustle-refresh)
    (define-key map (kbd "RET") #'side-hustle-goto-item)
    (define-key map (kbd "SPC") #'side-hustle-show-item)
    (define-key map (kbd "TAB") #'forward-button)
    (define-key map (kbd "S-TAB") #'backward-button)
    (define-key map (kbd "<backtab>") #'backward-button)
    map))

(define-derived-mode side-hustle-mode
  special-mode "Side-Hustle"
  "Major mode to navigate `imenu' via a side window.

You should not activate this mode directly, rather, call
`side-hustle-toggle' \\[side-hustle-toggle] in a source buffer."
  (add-to-invisibility-spec '(hustle-invisible . t)))



(provide 'side-hustle)
;;; side-hustle.el ends here

;; Local Variables:
;; coding: utf-8-unix
;; fill-column: 80
;; require-final-newline: t
;; sentence-end-double-space: nil
;; indent-tabs-mode: nil
;; End:
