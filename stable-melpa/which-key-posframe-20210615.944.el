;;; which-key-posframe.el --- Using posframe to show which-key  -*- lexical-binding: t -*-

;; Copyright (C) 2019 Yanghao Xie

;; Author: Yanghao Xie
;; Maintainer: Yanghao Xie <yhaoxie@gmail.com>
;; URL: https://github.com/yanghaoxie/which-key-posframe
;; Package-Version: 20210615.944
;; Package-Commit: 90e85d74899fc23d95798048cc0bbdb4bab9c1b7
;; Version: 0.2.0
;; Keywords: convenience, bindings, tooltip
;; Package-Requires: ((emacs "26.0")(posframe "0.4.3")(which-key "3.3.2"))

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

;; Display which key message using a posframe.
;; Check out the README for more information.

;;; Code:
(require 'cl-lib)
(require 'posframe)
(require 'which-key)

(defgroup which-key-posframe nil
  "Using posframe to show which key"
  :group 'which-key
  :prefix "which-key-posframe")

(defcustom which-key-posframe-font nil
  "The font used by which-key-posframe.
When nil, Using current frame's font as fallback."
  :group 'which-key-posframe
  :type 'string)

(defcustom which-key-posframe-poshandler #'posframe-poshandler-frame-center
  "The poshandler of which-key-posframe."
  :group 'which-key-posframe
  :type 'function)

(defcustom which-key-posframe-border-width 1
  "The border width used by which-key-posframe.
When 0, no border is showed."
  :group 'which-key-posframe
  :type 'number)

(defcustom which-key-posframe-parameters nil
  "The frame parameters used by which-key-posframe."
  :group 'which-key-posframe
  :type 'string)

(defface which-key-posframe
  '((t (:inherit default)))
  "Face used by the which-key-posframe."
  :group 'which-key-posframe)

(defface which-key-posframe-border
  '((t (:inherit default :background "gray50")))
  "Face used by the which-key-posframe's border."
  :group 'which-key-posframe)

(defvar which-key-popup-type--previous nil
  "The previous value of `which-key-popup-type'")

(defvar which-key-custom-show-popup-function--previous nil
  "The previous value of `which-key-custom-show-popup-function'")

(defvar which-key-custom-hide-popup-function--previous nil
  "The previous value of `which-key-custom-hide-popup-function'")

(defvar which-key-custom-popup-max-dimensions-function--previous nil
  "The previous value of `which-key-custom-popup-max-dimensions-function'")

(defun which-key-posframe--show-buffer (act-popup-dim)
  "Show which-key buffer when popup type is posframe.
Argument ACT-POPUP-DIM includes the dimension, (height . width)
of the buffer text to be displayed in the popup"
  (when (posframe-workable-p)
    (save-window-excursion
      (posframe-show
       which-key--buffer
       :font which-key-posframe-font
       :position (point)
       :poshandler which-key-posframe-poshandler
       :background-color (face-attribute 'which-key-posframe :background nil t)
       :foreground-color (face-attribute 'which-key-posframe :foreground nil t)
       :height (car act-popup-dim)
       :width (cdr act-popup-dim)
       :internal-border-width which-key-posframe-border-width
       :internal-border-color (face-attribute 'which-key-posframe-border :background nil t)
       :override-parameters which-key-posframe-parameters))))

(defun which-key-posframe--hide ()
  "Hide which-key buffer when posframe popup is used."
  (when (buffer-live-p which-key--buffer)
    (posframe-hide which-key--buffer)))

(defun which-key-posframe--max-dimensions (_)
  "Return max-dimensions of posframe.
The returned value has the form (HEIGHT . WIDTH) in lines and
characters respectably."
  (cons (1- (frame-height)) (frame-width)))

;;;###autoload
(define-minor-mode which-key-posframe-mode nil
  :group 'which-key-posframe
  :global t
  :lighter nil
  (if which-key-posframe-mode
      (progn
	(setq which-key-popup-type--previous which-key-popup-type
	      which-key-custom-show-popup-function--previous which-key-custom-show-popup-function
	      which-key-custom-hide-popup-function--previous which-key-custom-hide-popup-function
	      which-key-custom-popup-max-dimensions-function--previous which-key-custom-popup-max-dimensions-function
	      which-key-popup-type 'custom
	      which-key-custom-show-popup-function 'which-key-posframe--show-buffer
	      which-key-custom-hide-popup-function 'which-key-posframe--hide
	      which-key-custom-popup-max-dimensions-function 'which-key-posframe--max-dimensions))
    (posframe-delete which-key--buffer)
    (setq which-key-popup-type which-key-popup-type--previous
	  which-key-custom-show-popup-function which-key-custom-show-popup-function--previous
	  which-key-custom-hide-popup-function which-key-custom-hide-popup-function--previous
	  which-key-custom-popup-max-dimensions-function which-key-custom-popup-max-dimensions-function--previous
	  which-key-popup-type--previous nil
	  which-key-custom-show-popup-function--previous nil
	  which-key-custom-hide-popup-function--previous nil
	  which-key-custom-popup-max-dimensions-function--previous nil)))

(provide 'which-key-posframe)

;; Local Variables:
;; coding: utf-8-unix
;; End:

;;; which-key-posframe.el ends here
