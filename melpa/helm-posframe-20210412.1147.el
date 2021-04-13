;;; helm-posframe.el --- Using posframe to show helm window  -*- lexical-binding: t -*-

;; Copyright (C) 2017-2018 Free Software Foundation, Inc.

;; Author: Feng Shu
;; Maintainer: Feng Shu <tumashu@163.com>
;; URL: https://github.com/tumashu/helm-posframe
;; Package-Version: 20210412.1147
;; Package-Commit: 2412e5b3c584c7683982a7e9cfa10a67427f2567
;; Version: 0.1.0
;; Keywords: abbrev, convenience, matching, helm
;; Package-Requires: ((emacs "26.0")(posframe "1.0.0")(helm "0.1"))

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:
;; * helm-posframe README                                :README:
;; ** Need new maintainer !!!
;; I do not use helm and hard to maintain this package, for I
;; do not know the details of helm. need a new maintainer !!!

;; ** What is helm-posframe
;; helm-posframe is a helm extension, which let helm use posframe
;; to show its candidate menu.

;; NOTE: helm-posframe requires Emacs 26

;; ** How to enable and disable helm-posframe
;;    #+BEGIN_EXAMPLE
;;    (helm-posframe-enable)
;;    (helm-posframe-disable)
;;    #+END_EXAMPLE

;; ** Tips

;; *** How to show fringe to helm-posframe
;; ;; #+BEGIN_EXAMPLE
;; (setq helm-posframe-parameters
;;       '((left-fringe . 10)
;;         (right-fringe . 10)))
;; ;; #+END_EXAMPLE

;; By the way, User can set *any* parameters of helm-posframe with
;; the help of `helm-posframe-parameters'.

;;; Code:
;; * helm-posframe's code
(require 'cl-lib)
(require 'posframe)
(require 'helm)

(defgroup helm-posframe nil
  "Using posframe to show helm menu"
  :group 'helm
  :prefix "helm-posframe")

(defcustom helm-posframe-poshandler
  #'posframe-poshandler-frame-center
  "The poshandler of helm-posframe."
  :group 'helm-posframe
  :type 'function)

(defcustom helm-posframe-width nil
  "The width of helm-posframe."
  :group 'helm-posframe
  :type 'number)

(defcustom helm-posframe-height nil
  "The height of helm-posframe."
  :group 'helm-posframe
  :type 'number)

(defcustom helm-posframe-min-width nil
  "The width of helm-min-posframe."
  :group 'helm-posframe
  :type 'number)

(defcustom helm-posframe-min-height nil
  "The height of helm-min-posframe."
  :group 'helm-posframe
  :type 'number)

(defcustom helm-posframe-border-width 3
  "The border width used by helm-posframe.
When 0, no border is showed."
  :type 'number)

(defcustom helm-posframe-size-function #'helm-posframe-get-size
  "The function which is used to deal with posframe's size."
  :group 'helm-posframe
  :type 'function)

(defcustom helm-posframe-font nil
  "The font used by helm-posframe.
When nil, Using current frame's font as fallback."
  :group 'helm-posframe
  :type 'string)

(defcustom helm-posframe-border-width 1
  "The border width used by helm-posframe.
When 0, no border is shown."
  :group 'helm-posframe
  :type 'number)

(defcustom helm-posframe-parameters nil
  "The frame parameters used by helm-posframe."
  :group 'helm-posframe
  :type 'string)

(defface helm-posframe-border
  '((t (:inherit default :background "gray50")))
  "Face used by the ivy-posframe's border."
  :group 'helm-posframe)

(defvar helm-posframe-buffer nil
  "The posframe-buffer used by helm-posframe.")

;; Fix warn
(defvar emacs-basic-display)

(defun helm-posframe-display (buffer &optional _resume)
  "The display function which is used by `helm-display-function'.
Argument BUFFER."
  (setq helm-posframe-buffer buffer)
  (apply #'posframe-show
         buffer
         :position (point)
         :poshandler helm-posframe-poshandler
         :font helm-posframe-font
         :override-parameters helm-posframe-parameters
	 :internal-border-width helm-posframe-border-width
         :respect-header-line t
         :border-width helm-posframe-border-width
         :border-color (face-attribute 'helm-posframe-border :background nil t)
         (funcall helm-posframe-size-function)))

(defun helm-posframe-get-size ()
  "The default functon used by `helm-posframe-size-function'."
  (list
   :width (or helm-posframe-width (+ (window-width) 2))
   :height (or helm-posframe-height helm-display-buffer-height)
   :min-height (or helm-posframe-min-height
                   (let ((height (+ helm-display-buffer-height 1)))
                     (min height (or helm-posframe-height height))))
   :min-width (or helm-posframe-min-width
                  (let ((width (round (* (frame-width) 0.62))))
                    (min width (or helm-posframe-width width))))))

(defun helm-posframe-cleanup (orig-func)
  "Advice function of `helm-cleanup'.

`helm-cleanup' will call `bury-buffer' function, which
will let emacs minimize and restore when helm close.

In this advice function, `burn-buffer' will be temp redefine as
`ignore', do nothing."
  (cl-letf (((symbol-function 'bury-buffer) #'ignore)
            ((symbol-function 'replace-buffer-in-windows) #'ignore))
    (funcall orig-func)
    (when (posframe-workable-p)
      (posframe-hide helm-posframe-buffer))))

;;;###autoload
(defun helm-posframe-enable ()
  "Enable helm-posframe."
  (interactive)
  (require 'helm)
  (setq helm-display-function #'helm-posframe-display)
  (advice-add 'helm-cleanup :around #'helm-posframe-cleanup)
  (message "helm-posframe is enabled."))

(defun helm-posframe-disable ()
  "Disable helm-posframe"
  (interactive)
  (require 'helm)
  (setq helm-display-function #'helm-default-display-buffer)
  (advice-remove 'helm-cleanup  #'helm-posframe-cleanup)
  (message "helm-posframe is disabled."))

(provide 'helm-posframe)

;; Local Variables:
;; coding: utf-8
;; End:

;;; helm-posframe.el ends here
