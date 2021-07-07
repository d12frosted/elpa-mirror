;;; eshell-up.el --- Quickly go to a specific parent directory in eshell

;; Copyright (C) 2016 Peter W. V. Tran-Jørgensen

;; Author: Peter W. V. Tran-Jørgensen <peter.w.v.jorgensen@gmail.com>
;; Maintainer: Peter W. V. Tran-Jørgensen <peter.w.v.jorgensen@gmail.com>
;; URL: https://github.com/peterwvj/eshell-up
;; Package-Version: 20161019.1806
;; Package-Commit: 653121392acd607d5dfbca0832927e06806a2d39
;; Created: 14th October 2016
;; Version: 0.0.3
;; Package-Requires: ((emacs "24"))
;; Keywords: eshell

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.

;; This file is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Package for quickly navigating to a specific parent directory in
;; eshell without having to repeatedly typing 'cd ..'.  This is
;; achieved using the 'eshell-up' function, which can be bound to an
;; eshell alias such as 'up'.  As an example, assume that the current
;; working directory is:
;;
;; /home/user/first/second/third/fourth/fifth $
;;
;; Now, in order to quickly go to (say) the directory named 'first' one
;; simply executes:
;;
;; /home/user/first/second/third/fourth/fifth $ up fir
;; /home/user/first $
;;
;; This command searches the current working directory from right to
;; left for a directory that matches the user's input ('fir' in this
;; case).  If a match is found then eshell changes to that directory,
;; otherwise it does nothing.
;;
;; Other uses:
;;
;; It is also possible to compute the matching parent directory
;; without changing to it.  This is achieved using the 'eshell-up-peek'
;; function, which can be bound to an alias such as 'pk'.  When this
;; function is used in combination with subshells the matching parent
;; directory can be passed as an argument to other
;; functions.  Returning to the previous example one can (for example)
;; list the contents of 'first' by executing:
;;
;; /home/user/first/second/third/fourth/fifth $ ls {pk fir}
;; <directory contents>
;; ...
;;
;; It is recommended to invoke 'eshell-up' or 'eshell-up-peek' using
;; aliases as done in the examples above.  To do that, add the
;; following to your .eshell.aliases file:
;;
;; alias up eshell-up $1
;; alias pk eshell-up-peek $1
;;
;; This package is inspired by 'bd', which uses bash to implement
;; similar functionality.
;; See: https://github.com/vigneshwaranr/bd

;;; Code:

;; User-definable variables

(defvar eshell-up-ignore-case t "Non-nil if searches must ignore case.")

(defun eshell-up-closest-parent-dir (file)
  "Find the closest parent directory of a file.
Argument FILE the file to find the closest parent directory for."
  (file-name-directory
   (directory-file-name
    (expand-file-name file))))

(defun eshell-up-find-parent-dir (match path)
  "Find the parent directory based on the user's input.
Argument MATCH a string that identifies the parent directory to search for.
Argument PATH the source directory to search from."
  (let ((case-fold-search eshell-up-ignore-case)
        (closest-parent (eshell-up-closest-parent-dir path)))
    (locate-dominating-file closest-parent
                            (lambda (parent)
                              (let ((dir (file-name-nondirectory
                                          (expand-file-name
                                           (directory-file-name parent)))))
                                (if (string-match match dir)
                                    dir
                                  nil))))))

(defun eshell-up (match)
  "Go to a specific parent directory in eshell.
Argument MATCH a string that identifies the parent directory to go
to."
  (interactive)
  (let* ((path default-directory)
         (parent-dir (eshell-up-find-parent-dir match path)))
    (when parent-dir
      (eshell/cd parent-dir))))

(defun eshell-up-peek (match)
  "Find a specific parent directory in eshell.
Argument MATCH a string that identifies the parent directory to find"
  (interactive)
  (let* ((path default-directory)
         (parent-dir (eshell-up-find-parent-dir match path)))
    (if parent-dir
        parent-dir
      path)))

(provide 'eshell-up)

;;; eshell-up.el ends here
