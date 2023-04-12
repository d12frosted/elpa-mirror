;;; e2wm-bookmark.el --- Bookmark plugin for e2wm.el

;; Copyright (C) 2011, 2012 Yuhei Maeda <yuhei.maeda_at_gmail.com>
;; Author: Yuhei Maeda <yuhei.maeda_at_gmail.com>
;; Maintainer: Yuhei Maeda <yuhei.maeda_at_gmail.com>
;; Version: 0.1
;; Package-Commit: bad816b6d8049984d69bcd277b7d325fb84d55eb
;; Package-Version: 20151123.521
;; Package-X-Original-version: 0.1
;; Package-Requires: ((e2wm "1.2"))
;; Created: 2011-07-05
;; Keywords: convenience

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
;;
;; e2wm is window manager. e2wm makes windowlayout easy.
;; e2wm-bookmark is a plugin for e2wm. this provides small window
;; to manage bookmarks. this cooperate with files plugin and 
;; buffer history plugin.
;;


;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;require
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'e2wm)
(require 'bookmark)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;perspective definition : R-code / R Code editing 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar e2wm:c-code-ext-recipe
  '(| (:left-max-size 50)
      (- (:upper-size-ratio 0.6)
         files
         bookmarks)
      (- (:upper-size-ratio 0.7)
         (| (:right-max-size 50)
            main
            (- (:upper-size-ratio 0.6)
               imenu
               history))
         sub)))

(defvar e2wm:c-code-ext-winfo
  '((:name main)
    (:name files :plugin files)
    (:name history :plugin history-list)
    (:name sub :buffer "*info*" :default-hide t)
    (:name bookmarks :plugin bookmarks-list)
    (:name imenu :plugin imenu :default-hide nil)))

(defun e2wm:dp-code-ext-init ()
  (let* 
      ((code-wm 
        (wlf:no-layout 
         e2wm:c-code-ext-recipe
         e2wm:c-code-ext-winfo))
       (buf (or prev-selected-buffer
                (e2wm:history-get-main-buffer))))
    (when (e2wm:history-recordable-p prev-selected-buffer)
      (e2wm:history-add prev-selected-buffer))
    (wlf:set-buffer code-wm 'main buf)
    code-wm))

(e2wm:pst-class-register 
 (make-e2wm:$pst-class
  :name   'code-ext
  :title  "Coding"
  :init   'e2wm:dp-code-ext-init
  :main   'main
  :switch 'e2wm:dp-code-switch
  :popup  'e2wm:dp-code-popup
  :keymap 'e2wm:dp-code-minor-mode-map))

(defun e2wm:dp-code-ext ()
  (interactive)
  (e2wm:pst-change 'code-ext))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;plugin definition / Bookmarks-list plugin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun e2wm:dp-code-navi-bookmarks-command ()
  (interactive)
  (wlf:select (e2wm:pst-get-wm) 'bookmarks))

(defvar e2wm:bookmarks-list-buffer " *WM:Bookmarks*"
  "Name of buffer for displaying Bookmarks.")

(e2wm:plugin-register 'bookmarks-list
                      "Bookmarks-list"
                      'e2wm:def-plugin-bookmarks-list)

(defvar e2wm:def-plugin-bookmarks-list-mode-map
  (e2wm:define-keymap 
   '(("k"     . e2wm:def-plugin-bookmarks-list-previous-line)
     ("j"     . e2wm:def-plugin-bookmarks-list-next-line)
     ("p"     . e2wm:def-plugin-bookmarks-list-previous-line)
     ("n"     . e2wm:def-plugin-bookmarks-list-next-line)
     ("C-p"   . e2wm:def-plugin-bookmarks-list-previous-line)
     ("C-n"   . e2wm:def-plugin-bookmarks-list-next-line)
     ("C-m"   . e2wm:def-plugin-bookmarks-select-command)
     ("<SPC>" . e2wm:def-plugin-bookmarks-show-command)
     ("r"     . e2wm:def-plugin-bookmarks-rename)
     ("q"     . e2wm:pst-window-select-main-command)
     ("g"     . e2wm:def-plugin-bookmarks-list-update)
     ("d"     . e2wm:def-plugin-bookmarks-list-delete-mark)
     ("D"     . e2wm:def-plugin-bookmarks-list-quick-delete)
     ("M-d"   . e2wm:def-plugin-bookmarks-list-all-delete)
     ("u"     . e2wm:def-plugin-bookmarks-list-unmark)
     ("U"     . e2wm:def-plugin-bookmarks-list-all-unmark)
     ("w"     . e2wm:def-plugin-bookmarks-list-send-kill-ring)
     ("f"     . e2wm:def-plugin-bookmarks-list-send-files)
     ("x"     . e2wm:def-plugin-bookmarks-list-expunge))))

(define-derived-mode
  e2wm:def-plugin-bookmarks-list-mode
  fundamental-mode
  "Bookmarks list")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;Internal
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun e2wm:def-plugin-bookmarks-list (frame wm winfo)
  (let ((buf (get-buffer-create e2wm:bookmarks-list-buffer)))
    (with-current-buffer buf
      (unwind-protect
          (progn
            (setq buffer-read-only nil)
            (e2wm:def-plugin-bookmarks-list-mode)
            (setq header-line-format "Bookmarks list")
            (setq mode-line-format 
                  '("-" mode-line-mule-info
                    " " mode-line-position "-%-")))))
    (e2wm:def-plugin-bookmarks-list-update)
    (wlf:set-buffer wm (wlf:window-name winfo) buf)))

(defun e2wm:def-plugin-bookmarks-list-object ()
  "Return filename on current line."
  (save-excursion
    (beginning-of-line)
    (forward-char 2)
    (let (beg)
      (setq beg (point))
      (search-forward "\n")
      (backward-char 1)
      (buffer-substring-no-properties beg (point)))))

(defun e2wm:def-plugin-bookmarks-list-display-func (buf)
  (e2wm:pst-buffer-set 'main buf t))

(defun e2wm:def-plugin-bookmarks-list-to-object ()
  "Put point at start of object."
  (beginning-of-line)
  (forward-char 2))

(defun e2wm:def-plugin-bookmarks-list-mark (mark-char arg all)
  "English:
Mark the file, using MARK-CHAR,  on current line (or next ARG lines). 
ALL is non-nil , all file mark.
Japanese:
ファイルにマークをつける。ALLがnon-nilの時は全てのファイルにマークがつけられる。"
  (let ((buffer-read-only nil)
        move)
    (save-excursion
      (when all
        (setq move (point-min))
        (setq arg (count-lines (point-min) (point-max)))
        (goto-char (point-min)))
      (while (and (> arg 0) (not (eobp)))
        (setq arg (1- arg))
        (beginning-of-line)
        (progn
          (insert mark-char)
          (delete-char 1)
          (forward-line 1)))
      ;; (if move
      ;;     (goto-char move))
      )
    (unless all
      (forward-line 1))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;User Interface
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun e2wm:def-plugin-bookmarks-list-update ()
  "update Bookmarks List."
  (interactive)
  (let* ((buf (get-buffer-create e2wm:bookmarks-list-buffer))
         (blist (bookmark-all-names)))
    (with-current-buffer buf
      (unwind-protect
          (progn
            (setq buffer-read-only nil)
            (erase-buffer)
            (dolist (i blist)
              (unless (string= i  "")
                (insert (concat "  " i "\n"))))
            (setq buffer-read-only t))))))


(defun e2wm:def-plugin-bookmarks-list-next-line (arg)
  "Move down lines then position at object.
Optional prefix ARG says how many lines to move; default is one line."
  (interactive "p")
  (forward-line arg)
  (e2wm:def-plugin-bookmarks-list-to-object))

(defun e2wm:def-plugin-bookmarks-list-previous-line (arg)
  "Move up lines then position at object.
Optional prefix ARG says how many lines to move; default is one line."
  (interactive "p")
  (forward-line (- (or arg 1))) ; -1 if arg was nil
  (e2wm:def-plugin-bookmarks-list-to-object))

(defun e2wm:def-plugin-bookmarks-show-command ()
  (interactive)
  (bookmark-jump 
   (e2wm:def-plugin-bookmarks-list-object)
   'e2wm:def-plugin-bookmarks-list-display-func))

(defun e2wm:def-plugin-bookmarks-select-command ()
  (interactive)
  (bookmark-jump 
   (e2wm:def-plugin-bookmarks-list-object)
   'e2wm:def-plugin-bookmarks-list-display-func)
  (e2wm:pst-window-select-main)
  (e2wm:history-add(current-buffer)))

(defun e2wm:def-plugin-bookmarks-rename ()
  "Rename bookmark on current line.  Prompts for a new name."
  (interactive)
  (let ((bmrk (e2wm:def-plugin-bookmarks-list-object))
        (thispoint (point)))
    (bookmark-rename bmrk)
    (goto-char thispoint)
    (e2wm:def-plugin-bookmarks-list-update)))

(defun e2wm:def-plugin-bookmarks-list-delete-mark (arg)
  "Mark the current (or next ARG) file for deletion."
  (interactive "p")
  (e2wm:def-plugin-bookmarks-list-mark "D" arg nil))

(defun e2wm:def-plugin-bookmarks-list-unmark (arg)
  "Unmark the current (or next ARG) file for deletion."
  (interactive "p")
  (e2wm:def-plugin-bookmarks-list-mark " " arg nil))

(defun e2wm:def-plugin-bookmarks-list-all-delete (arg)
  "Mark the current (or next ARG) objects for deletion."
  (interactive "p")
  (e2wm:def-plugin-bookmarks-list-mark "D" arg t))

(defun e2wm:def-plugin-bookmarks-list-all-unmark (arg)
  "Unmark the current (or next ARG) objects.
If point is on first line, all objects will be unmarked."
  (interactive "p")
  (e2wm:def-plugin-bookmarks-list-mark " " arg t))

(defun e2wm:def-plugin-bookmarks-list-quick-delete (arg)
  "Mark the current (or next ARG) file for deletion."
  (interactive "p")
  (save-excursion
    (e2wm:def-plugin-bookmarks-list-mark "D" arg nil)
    (e2wm:def-plugin-bookmarks-list-expunge)))


(defun e2wm:def-plugin-bookmarks-list-send-kill-ring ()
  "Display location of this bookmark.  Displays in the minibuffer."
  (interactive)
  (let ((bmrk (e2wm:def-plugin-bookmarks-list-object)))
    (kill-new (bookmark-location bmrk))
    (message "added to kill ring: %s" (bookmark-location bmrk))))


(defun e2wm:def-plugin-bookmarks-list-send-files ()
  (interactive)
  (let ((dir (bookmark-location (e2wm:def-plugin-bookmarks-list-object))))
    (if (file-directory-p dir)
        (progn
          (e2wm:pst-window-select 'files)
          (setq e2wm:def-plugin-files-dir dir)
          (e2wm:def-plugin-files-update-by-command))
      (message "%s is not directory" dir))))

(defun e2wm:def-plugin-bookmarks-list-expunge ()
  "Delete bookmarks flagged `D'."
  (interactive)
  (message "Deleting bookmarks...")
  (let ((o-point  (point))
        (o-str    (save-excursion
                    (beginning-of-line)
                    (unless (looking-at "^D")
                      (buffer-substring
                       (point)
                       (progn (end-of-line) (point))))))
        (o-col     (current-column)))
    (goto-char (point-min))
    (while (re-search-forward "^D" (point-max) t)
      (bookmark-delete (e2wm:def-plugin-bookmarks-list-object) t)) ; pass BATCH arg
    (if o-str
        (progn
          (goto-char (point-min))
          (search-forward o-str)
          (beginning-of-line)
          (forward-char o-col))
      (goto-char o-point))
    (beginning-of-line)
    (message "Deleting bookmarks...done"))
  (e2wm:def-plugin-bookmarks-list-update))

(defadvice bookmark-set
  (after e2wm:def-plugin-bookmarks-list-bookmark-set activate)
  (when (e2wm:managed-p)
    (e2wm:def-plugin-bookmarks-list-update)))

(provide 'e2wm-bookmark)

;;; e2wm-bookmark.el ends here
