;;; presentation.el --- Display large character for presentation  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Keywords: environment, faces, frames
;; Package-Version: 20180427.224
;; Package-Commit: f53f67aeab97e8eea6d1f12df5f7ce3b1b03b879
;; Created: 7 Apr 2018
;; Version: 0.1.1
;; Package-Requires: ((emacs "24.4") (cl-lib "0.5"))
;; URL: https://github.com/zonuexe/emacs-presentation-mode
;; License: GPL-3.0-or-later

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

;; Presentation mode is a global minor mode to zoom characters.
;; This mode applies the effect of `text-scale-mode' to all buffers.
;; This feature help you to present Emacs edit / operation to the audience
;; in front of the screen.
;;
;; ## How to use
;;
;;  1. Execute `M-x presentation-mode' to start the presentation.
;;  2. Adjust scale size by `C-x C-+' or `C-x C--'
;;     See https://www.gnu.org/software/emacs/manual/html_node/emacs/Text-Scale.html
;;  3. After the presentation, execute `M-x presentation-mode` again.
;;  4. And then execute `M-x presentation-mode` again, the last scale will be reproduced.
;;  5. If you want to persistize its size as the default size of presentation-mode
;;     after restarting Emacs, set `presentation-default-text-scale`.
;;
;; ## Notice
;;
;; ### Not for "persistent font size change"
;;
;; It is well known that how to change the font size of Emacs in GUI is difficult.
;; However, this mode is *NOT* intended for permanent font size change.
;;
;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Parameter-Access.html
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Frame-Parameters.html
;;
;; ## Difference from other methods
;;
;; ### vs GlobalTextScaleMode (Emacs Wiki)
;;
;; Although the content of this article is simple, it does not provide a way to
;; recover buffers.
;; https://www.emacswiki.org/emacs/GlobalTextScaleMode
;;
;; ### Org Tree Slide / org-present
;;
;; These packages are simple presentations using org-mode.
;; By using these with org-babel, it may be possible to perform live coding of
;; arbitrary languages.
;; https://github.com/takaxp/org-tree-slide
;; https://github.com/rlister/org-present
;;

;;; Code:
(require 'cl-lib)
(require 'nadvice)
(require 'face-remap)

;; Customize variables:
(defgroup presentation nil
  "Display large charactor for presentation."
  :prefix "presentation-"
  :group 'environment)

(defcustom presentation-on-hook nil
  "Functions to run whenever Presentation mode is turned on."
  :type 'hook
  :group 'presentation)

(defcustom presentation-off-hook nil
  "Functions to run whenever Presentation mode is turned off."
  :type 'hook
  :group 'presentation)

(defcustom presentation-default-text-scale 3
  "Text scale for presentation."
  :type 'integer
  :group 'presentation)

(defcustom presentation-keep-last-text-scale t
  "When non-NIL eproduce the size when using presention-mode last time.

Be aware that size will not be inherited when you exit Emacs.
Please set presentation-default-text-scale in initialization processing of your init.el."
  :type 'boolean
  :group 'presentation)

(defcustom presentation-mode-lighter " Presentation"
  "String to display in mode line when Presentation Mode is enabled; nil for none."
  :type 'string
  :group 'presentation)

(defcustom presentation-mode-ignore-major-modes
  '()
  "List of major modes unaffected by presentation mode."
  :type '(repeat (choice function symbol))
  :group 'presentation)

(defcustom presentation-mode-ignore-minor-modes
  '(org-present-mode org-tree-slide-mode)
  "List of minor modes unaffected by presentation mode."
  :type '(repeat (choice variable symbol))
  :group 'presentation)

;; Buffer local variables:
(defvar-local presentation-disable nil)

;; Variables:
(defvar presentation-last-text-scale nil)

;; Functions:

(defun presentation--text-scale-set (&rest _args)
  "Set `text-scale-mode-amount' for each buffer."
  (setq presentation-last-text-scale text-scale-mode-amount)
  (presentation-windows-text-scale-set text-scale-mode-amount))

(defun presentation--text-scale-apply ()
  "Set `presentation-last-text-scale' for each buffer."
  (presentation-windows-text-scale-set presentation-last-text-scale))

(defun presentation-ignore-current-buffer ()
  "Return T if current-burrer should be ignore for presentation."
  (or presentation-disable
      (memq major-mode presentation-mode-ignore-major-modes)
      (cl-loop for m in presentation-mode-ignore-minor-modes
               always (and (boundp m) (symbol-value m)))))

(defun presentation-windows-text-scale-set (level)
  "Set `LEVEL' for each buffer."
  (setq text-scale-mode-amount level)
  (text-scale-mode (if (zerop text-scale-mode-amount) -1 1))

  (save-selected-window
    (walk-windows
     (lambda (win)
       (with-selected-window win
         (unless (presentation-ignore-current-buffer)
           (setq text-scale-mode-amount level)
           (text-scale-mode (if (zerop text-scale-mode-amount) -1 1)))))
     t t)))

;; Mode:

;;;###autoload
(define-minor-mode presentation-mode
  "Toggle Presentation mode ON or OFF."
  :group 'presentation
  :global t
  :lighter presentation-mode-lighter
  :keymap (make-sparse-keymap)
  :require 'presentation
  (if presentation-mode
      (save-selected-window
        (advice-add 'text-scale-set :after #'presentation--text-scale-set)
        (advice-add 'text-scale-increase :after #'presentation--text-scale-set)
        (add-hook 'window-configuration-change-hook  #'presentation--text-scale-apply)
        (let ((text-scale-mode-amount (or (when presentation-keep-last-text-scale presentation-last-text-scale)
                                          presentation-default-text-scale)))
          (presentation--text-scale-set))
        (run-hooks 'presentation-on-hook))
    (advice-remove 'text-scale-set #'presentation--text-scale-set)
    (advice-remove 'text-scale-increase #'presentation--text-scale-set)
    (remove-hook 'window-configuration-change-hook  #'presentation--text-scale-apply)
    (save-selected-window
      (cl-loop for buf in (buffer-list)
               do (with-current-buffer buf
                    (unless (presentation-ignore-current-buffer)
                      (text-scale-set 0))))
      (run-hooks 'presentation-off-hook))))

(provide 'presentation)
;;; presentation.el ends here
