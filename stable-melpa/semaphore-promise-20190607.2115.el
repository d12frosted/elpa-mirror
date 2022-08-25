;;; semaphore-promise.el --- semaphore integration with promise -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Herwig Hochleitner

;; Author: Herwig Hochleitner <herwig@bendlas.net>
;; Maintainer: Herwig Hochleitner <herwig@bendlas.net>
;; Version: 1.0.0
;; Package-Version: 20190607.2115
;; Package-Commit: 9cdfef91cc0293371af549ad41027aa5b73f30a4
;; Keywords: processes, unix
;; URL: http://github.com/webnf/semaphore.el
;; Package-Requires: ((emacs "26") (semaphore "1") (promise "1"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; semaphore-promise-gated uses semaphore to implement a sort of
;; thread pool for promises

;;; Code:

(require 'semaphore)
(require 'promise)

(defun semaphore-promise-gated (semaphore handler)
  "Create a promise based on handler, like promise-new, but
   acquire and release the semaphore around resolving the
   handler (+ result promises).

   This is useful for controlling parallelism in asynchronous work flows:
   e.g. if you want to fetch 10000 files, but only 7 at a time:

   (let ((s (semaphore-create 7)))
     (promise-all
       (mapcar
         (lambda (url)
           (semaphore-promise-gated s
             (lambda (resolve _)
               (funcall resolve (http-get url))))) ;; assuming http-get returns another promise
         url-list))"
  (if semaphore
      (promise-finally
       (promise-new
        (lambda (resolve reject)
          (semaphore-acquire semaphore)
          (funcall handler resolve reject)))
       (lambda ()
         (semaphore-release semaphore)))
    (promise-new handler)))


(provide 'semaphore-promise)

;;; semaphore-promise.el ends here
