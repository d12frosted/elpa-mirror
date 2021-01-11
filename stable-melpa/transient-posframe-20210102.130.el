;;; transient-posframe.el --- Using posframe to show transient  -*- lexical-binding: t -*-

;; Copyright (C) 2020 Yanghao Xie

;; Author: Yanghao Xie
;; Maintainer: Yanghao Xie <yhaoxie@gmail.com>
;; URL: https://github.com/yanghaoxie/transient-posframe
;; Package-Version: 20210102.130
;; Package-Commit: dcd898d1d35183a7d4f2c8f0ebcb43b4f8e70ebe
;; Version: 0.1.0
;; Keywords: convenience, bindings, tooltip
;; Package-Requires: ((emacs "26.0")(posframe "0.4.3")(transient "0.2.0"))

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

;; Display transient popups using a posframe.
;; Check out the README for more information.

;;; Code:
(require 'posframe)
(require 'transient)

(defgroup transient-posframe nil
  "Using posframe to show transient popups"
  :group 'transient
  :prefix "transient-posframe")

(defcustom transient-posframe-font nil
  "The font used by transient-posframe.
When nil, Using current frame's font as fallback."
  :group 'transient-posframe
  :type 'string)

(defcustom transient-posframe-poshandler #'posframe-poshandler-frame-center
  "The poshandler of transient-posframe."
  :group 'transient-posframe
  :type 'function)

(defcustom transient-posframe-min-width 80
  "The width of transient-min-posframe."
  :group 'transient-posframe
  :type 'number)

(defcustom transient-posframe-min-height 30
  "The height of transient-min-posframe."
  :group 'transient-posframe
  :type 'number)

(defcustom transient-posframe-border-width 1
  "The border width used by transient-posframe.
When 0, no border is showed."
  :group 'transient-posframe
  :type 'number)

(defcustom transient-posframe-parameters nil
  "The frame parameters used by transient-posframe."
  :group 'transient-posframe
  :type 'string)

(defface transient-posframe
  '((t (:inherit default)))
  "Face used by the transient-posframe."
  :group 'transient-posframe)

(defface transient-posframe-border
  '((t (:inherit default :background "gray50")))
  "Face used by the transient-posframe's border."
  :group 'transient-posframe)

(defvar transient-posframe-display-buffer-action--previous nil
  "The previous value of `transient-display-buffer-action'.")

(defun transient-posframe--show-buffer (buffer _alist)
  "Show BUFFER in posframe and we do not use _ALIST at this period."
  (when (posframe-workable-p)
    (let* ((posframe
	    (posframe-show buffer
			   :font transient-posframe-font
			   :position (point)
			   :poshandler transient-posframe-poshandler
			   :background-color (face-attribute 'transient-posframe :background nil t)
			   :foreground-color (face-attribute 'transient-posframe :foreground nil t)
			   :min-width transient-posframe-min-width
			   :min-height transient-posframe-min-height
			   :internal-border-width transient-posframe-border-width
			   :internal-border-color (face-attribute 'transient-posframe-border :background nil t)
			   :override-parameters transient-posframe-parameters)))
      (frame-selected-window posframe))))

(defun transient-posframe--delete ()
  "Delete transient posframe."
  (posframe-delete-frame transient--buffer-name)
  (posframe--kill-buffer transient--buffer-name))

;;;###autoload
(define-minor-mode transient-posframe-mode
  "Toggle transient posframe mode on of off."
  :group 'transient-posframe
  :global t
  :lighter nil
  (if transient-posframe-mode
      (progn
	(setq transient-posframe-display-buffer-action--previous transient-display-buffer-action
	      transient-display-buffer-action '(transient-posframe--show-buffer))
	(advice-add 'transient--delete-window :override #'transient-posframe--delete))
    (setq transient-display-buffer-action transient-posframe-display-buffer-action--previous)
    (advice-remove 'transient--delete-window #'transient-posframe--delete)))

(provide 'transient-posframe)

;; Local Variables:
;; coding: utf-8-unix
;; End:

;;; transient-posframe.el ends here
