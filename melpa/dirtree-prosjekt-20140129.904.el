;;; dirtree-prosjekt.el --- dirtree integration for prosjekt.

;; Copyright (C) 2012 Austin Bingham
;; Author: Austin Bingham <austin.bingham@gmail.com>
;; Version: 0.1
;; Package-Version: 20140129.904
;; Package-Commit: 03e06910589ba5cd736868793eb436b3233c6a26
;; URL: https://github.com/abingham/prosjekt
;; Package-Requires: ((prosjekt "0.3") (dirtree "0.01"))

;; This file is NOT part of GNU Emacs.

;;; Commentary:
;;
;; Adds simple support for dirtree to prosjekt. Specifically, it adds
;; a function, prosjekt-dirtree, for opening a dirtree buffer at the
;; project root.
;; 
;; To activate this function, add dirtree-prosjekt.el to your load
;; path and add
;;
;;   (require 'dirtree-prosjekt)
;;
;; to your emacs config.
;;
;; License:
;;
;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Code:
(require 'prosjekt)
(require 'dirtree)

;;;###autoload
(defun prosjekt-dirtree ()
  (interactive)
  (dirtree prosjekt-proj-dir t))

(provide 'dirtree-prosjekt)

;;; dirtree-prosjekt.el ends here
