;;; random-splash-image.el --- Randomly sets splash image to *GNU Emacs* buffer on startup.

;; Copyright (C) 2015  kakakaya

;; Author: kakakaya <kakakaya AT gmail.com>
;; Keywords: games
;; Package-Version: 20151003.130
;; Package-Commit: 907e2db5ceff781ac7f4dbdd65fe71736c36aa22
;; Version: 1.0.0
;; URL: https://github.com/kakakaya/random-splash-image

;; Licence:
;; The MIT License (MIT)

;; Copyright (c) 2015 kakakaya

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.


;;; Code:
(defcustom random-splash-image-dir nil
  "directory to find splash image randomly."
  :group 'fancy-splash-screen
  :type '(choice
          (const     :tag "None" nil)
          (directory :tag "Directory")))

(defun random-splash-image-elt (choices)
  (elt choices (random (length choices))))

(defun random-splash-image-choose-image (img-dir)
  (random-splash-image-elt (directory-files img-dir t "^\\([^.]\\|\\.[^.]\\|\\.\\..\\)")))

(defun random-splash-image-set ()
  (if (null random-splash-image-dir)
      (message "Please set value to random-splash-image-dir, otherwise random-splash-image won't work.")
    (setq fancy-splash-image (random-splash-image-choose-image random-splash-image-dir))))

(defun random-splash-image-reopen-screen ()
  (interactive)
  (random-splash-image-set)
  (display-startup-screen))

(provide 'random-splash-image)
;;; random-splash-image.el ends here
