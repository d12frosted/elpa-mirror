;;; which-key-posframe.el --- Using posframe to show which-key  -*- lexical-binding: t -*-

;; Copyright (C) 2019 Yanghao Xie

;; Author: Yanghao Xie <yhaoxie@gmail.com>
;; Homepage: https://github.com/emacsorphanage/which-key-posframe
;; Keywords: convenience, bindings, tooltip
;; Package-Commit: e4a9ce9a1b20de550fca51f14d055821980d534a

;; Package-Version: 20230313.1841
;; Package-X-Original-Version: 0.2.0.50-git
;; Package-Requires: ((emacs "26.0") (posframe "1.4.0") (which-key "3.6.0"))

;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Display which key message using a posframe.
;; Check out the README for more information.

;;; Code:

(require 'posframe)
(require 'which-key)

(defgroup which-key-posframe nil
  "Using posframe to show which key."
  :group 'which-key
  :prefix "which-key-posframe")

(defcustom which-key-posframe-font nil
  "The font used by which-key-posframe.
When nil, use current frame's font as fallback."
  :group 'which-key-posframe
  :type 'string)

(defcustom which-key-posframe-poshandler #'posframe-poshandler-frame-center
  "The poshandler of which-key-posframe."
  :group 'which-key-posframe
  :type 'function)

(defcustom which-key-posframe-border-width 1
  "The border width used by which-key-posframe.
When 0, no border is shown."
  :group 'which-key-posframe
  :type 'number)

(defcustom which-key-posframe-parameters nil
  "The frame parameters used by which-key-posframe."
  :group 'which-key-posframe
  :type 'string)

(defface which-key-posframe
  '((t (:inherit default)))
  "Face used by which-key-posframe."
  :group 'which-key-posframe)

(defface which-key-posframe-border
  '((t (:inherit default :background "gray50")))
  "Face used by which-key-posframe's border."
  :group 'which-key-posframe)

(defvar which-key-posframe--restore nil
  "List of values to be restored when turning of `which-key-posframe-mode'.")

(defun which-key-posframe--show-buffer (act-popup-dim)
  "Show which-key buffer when popup type is posframe.
Argument ACT-POPUP-DIM has the form (HEIGHT . WIDTH), specifying
the dimensions of the buffer text to be displayed in the popup."
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
       :lines-truncate t
       :internal-border-width which-key-posframe-border-width
       :internal-border-color (face-attribute 'which-key-posframe-border
                                              :background nil t)
       :override-parameters which-key-posframe-parameters))))

(defun which-key-posframe--hide ()
  "Hide which-key buffer when posframe popup is used."
  (when (buffer-live-p which-key--buffer)
    (posframe-hide which-key--buffer)))

(defun which-key-posframe--max-dimensions (_)
  "Return max-dimensions of posframe.
The returned value has the form (HEIGHT . WIDTH) in lines and
characters respectably."
  (cons (- (frame-height) 2) ; account for mode-line and minibuffer
        (frame-width)))

;;;###autoload
(define-minor-mode which-key-posframe-mode nil
  :group 'which-key-posframe
  :global t
  :lighter nil
  (cond
   (which-key-posframe-mode
    (setq which-key-posframe--restore
          (list which-key-popup-type
                which-key-custom-show-popup-function
                which-key-custom-hide-popup-function
                which-key-custom-popup-max-dimensions-function))
    (setq which-key-popup-type 'custom)
    (setq which-key-custom-show-popup-function 'which-key-posframe--show-buffer)
    (setq which-key-custom-hide-popup-function 'which-key-posframe--hide)
    (setq which-key-custom-popup-max-dimensions-function
          'which-key-posframe--max-dimensions))
   (t
    (when which-key--buffer
      (posframe-delete which-key--buffer))
    (when-let* ((r which-key-posframe--restore))
      (setq which-key-posframe--restore nil)
      (setq which-key-popup-type (nth 0 r))
      (setq which-key-custom-show-popup-function (nth 1 r))
      (setq which-key-custom-hide-popup-function (nth 2 r))
      (setq which-key-custom-popup-max-dimensions-function (nth 3 r))))))

(provide 'which-key-posframe)

;; Local Variables:
;; indent-tabs-mode: nil
;; coding: utf-8-unix
;; End:

;;; which-key-posframe.el ends here
