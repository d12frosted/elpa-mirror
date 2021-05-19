;;; right-click-context.el --- Right Click Context menu  -*- lexical-binding: t; -*-

;; Copyright (C) 2021 USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 8 May 2016
;; Version: 0.4.0
;; Package-Version: 20210519.1713
;; Package-Commit: c3c9d36ffbc9fb2bc7c2c4b75291dbcdb1c5f531
;; Package-Requires: ((emacs "24.3") (popup "0.5") (ordinal "0.0.1"))
;; Keywords: mouse menu rightclick
;; Homepage: https://github.com/zonuexe/right-click-context
;; License: GPL-3.0-or-later

;; This file is NOT part of GNU Emacs.

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

;; This mode focuses on providing operations similar to GUI context menus.
;; It not only activates commands, it also supports operations on Region.
;;
;; Put the following into your .emacs file (~/.emacs.d/init.el) to enable context menu.
;;
;;     (right-click-context-mode 1)
;;
;; This function does not depend on GUI, it is fully available on terminal.
;; The menu is launched by "right click" (<mouse-3>) by default, but you can assign any key.
;;
;;     (define-key right-click-context-mode-map (kbd "C-c :") 'right-click-context-menu)
;;
;; This menu can be constructed with a simple DSL based on S-expression.
;; Additional information can be found in README and implementation code.
;;
;; ## Context-menu construction DSL
;;
;; For example, the following code adds undo and redo to the beginning of the context menu.
;;
;;     (setq right-click-context-global-menu-tree
;;           (append
;;            '((\"Undo\" :call (if (fboundp 'undo-tree-undo) (undo-tree-undo) (undo-only)))
;;              (\"Redo\"
;;              :call (if (fboundp 'undo-tree-redo) (undo-tree-redo))
;;              :if (and (fboundp 'undo-tree-redo) (undo-tree-node-previous (undo-tree-current buffer-undo-tree)))))
;;            right-click-context-global-menu-tree))

;;; Code:
(eval-when-compile
  (require 'cl-lib))
(require 'url-util)
(require 'popup)
(require 'ordinal)

(defgroup right-click-context ()
  "Right Click Context menu"
  :group 'convenience)

(defcustom right-click-context-mode-lighter " RightClick"
  "Lighter displayed in mode line when `right-click-context-mode' is enabled."
  :group 'right-click-context
  :type 'string)

(defcustom right-click-context-mouse-set-point-before-open-menu 'not-region
  "Control the position of the mouse pointer before opening the menu."
  :group 'right-click-context
  :type '(choice (const :tag "When not Region activated" 'not-region)
                 (const :tag "Always set cursor to mouse pointer" 'always)
                 (const :tag "Not set cursor to mouse pointer" nil)))

(defvar right-click-context-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "<mouse-3>") #'right-click-context-click-menu)
    map)
  "Keymap used in `right-click-context-mode'.")

(defcustom right-click-context-global-menu-tree
  '(("Copy" :call (kill-ring-save (region-beginning) (region-end))
     :if (use-region-p))
    ("Cut"  :call (kill-region (region-beginning) (region-end))
     :if (and (use-region-p) (not buffer-read-only)))
    ("Paste" :call (yank) :if (not buffer-read-only))
    ("Select Region"
     ("All"  :call (mark-whole-buffer) :if (not (use-region-p)))
     ("Word" :call (mark-word))
     ("Paragraph" :call (mark-paragraph)))
    ("Text Convert"
     ("Downcase"   :call (downcase-region (region-beginning) (region-end)))
     ("Upcase"     :call (upcase-region (region-beginning) (region-end)))
     ("Capitalize" :call (capitalize-region (region-beginning) (region-end)))
     ("URL Encode" :call (right-click-context--process-region
                          (region-beginning) (region-end) 'url-encode-url))
     ("URL Decode" :call (right-click-context--process-region
                          (region-beginning) (region-end) 'right-click-context--url-decode))
     ("Comment Out" :call comment-dwim))
    ("Go To"
     ("Top"    :call (goto-char (point-min)))
     ("Bottom" :call (goto-char (point-max)))
     ("Directory" :call (find-file default-directory)))
    ("Describe Character" :call (describe-char (point)) :if (not (use-region-p))))
  "Right Click Context menu for default context.

This variable is a simple DSL with a tree structure consisting of alist with
label string as a key and plist for calling S expression."
  :group 'right-click-context
  :type '(alist :key-type (string :tag "Context label")
                :value-type
                (choice (plist :key-type (choice (const :if)
                                                 (const :call)))
                        (alist :key-type string
                               :value-type (choice
                                            (plist :key-type (choice (const :if)
                                                                     (const :call)))
                                            (alist :key-type string :tag "Context label"))))))

(defun right-click-context--build-menu-for-popup-el (tree parent-labels)
  "Build right click menu for `popup.el' from `TREE'.

`PARENT-LABELS' requires to identify the cause of the error during construction of the tree."
  (cl-loop
   for n from 0
   for (name . child) in tree
   if (not (stringp name))
   do (error
       "Invalid tree.  (%s element(0-origin) of %s)"
       (let ((ordinal-number-accept-0 t)) (ordinal-format n))
       (if parent-labels
           (mapconcat (lambda (string) (format "\"%s\"" string))
                      (reverse parent-labels)
                      "-")
         "top-level"))
   if (or (null (plist-get child :if)) (eval (plist-get child :if)))
   if (listp (car child))
   collect (cons name (right-click-context--build-menu-for-popup-el child (cons name parent-labels)))
   else collect (popup-make-item name :value (plist-get child :call))))

(defvar-local right-click-context-local-menu-tree nil
  "Buffer local Right Click Menu.")

(defun right-click-context--menu-tree ()
  "Return right click menu tree."
  (cond ((and (symbolp right-click-context-local-menu-tree) (fboundp right-click-context-local-menu-tree)) (funcall right-click-context-local-menu-tree))
        (right-click-context-local-menu-tree right-click-context-local-menu-tree)
        (:else right-click-context-global-menu-tree)))

(defun right-click-context--process-region (begin end callback &rest args)
  "Convert string in region(BEGIN to END) by `CALLBACK' function call with additional arguments `ARGS'."
  (let* ((region-string (buffer-substring-no-properties begin end))
         (result (apply callback region-string args)))
    (unless result
      (error "Convert Error"))
    (delete-region begin end)
    (insert result)
    (set-mark begin)))

(defun right-click-context--url-decode (src-string)
  "Return URI decoded string from `SRC-STRING'."
  (decode-coding-string (url-unhex-string (url-encode-url src-string)) 'utf-8))

;;;###autoload
(define-minor-mode right-click-context-mode
  "Minor mode for enable Right Click Context menu.

This mode just binds the context menu to <mouse-3> (\"Right Click\").

\\{right-click-context-mode-map}
If you do not want to bind this right-click, you should not call this minor-mode.

You probably want to just add follows code to your .emacs file (init.el).

    (global-set-key (kbd \"C-c :\") #'right-click-context-menu)
"
  :lighter right-click-context-mode-lighter
  :global t
  :require 'right-click-context
  right-click-context-mode-map
  :group 'right-click-context)

;;;###autoload
(defun right-click-context-click-menu (_event)
  "Open Right Click Context menu by Mouse Click `EVENT'."
  (interactive "e")
  (when (or (eq right-click-context-mouse-set-point-before-open-menu 'always)
            (and (null mark-active)
                 (eq right-click-context-mouse-set-point-before-open-menu 'not-region)))
    (call-interactively #'mouse-set-point))
  (right-click-context-menu))

(defun right-click-context--click-menu-popup ()
  "Open a new right click context menu at the new mouse position."
  (interactive)
  (when (memq this-command '(right-click-context-click-menu))
    (popup-delete (nth (1- (length popup-instances)) popup-instances))
    (call-interactively #'right-click-context-click-menu)))

;;;###autoload
(defun right-click-context-menu ()
  "Open Right Click Context menu."
  (interactive)
  (let ((popup-menu-keymap (copy-sequence popup-menu-keymap)))
    (define-key popup-menu-keymap [mouse-3] #'right-click-context--click-menu-popup)
    (let ((value (popup-cascade-menu (right-click-context--build-menu-for-popup-el (right-click-context--menu-tree) nil))))
      (when value
        (if (symbolp value)
            (call-interactively value t)
          (eval value))))))

(provide 'right-click-context)
;;; right-click-context.el ends here
