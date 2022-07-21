;;; cljr-helm.el --- Wraps clojure refactor commands with helm -*- coding: utf-8-unix -*-

;; Copyright (C) 2015 Phil Jackson

;; Author   : Phil Jackson <phil@shellarchive.co.uk>
;; URL      : https://github.com/philjackson/cljr-helm
;; Package-Version: 20220721.824
;; Package-Commit: 2c1f9cbd892ec03335f671ea3f974ee2ff6078dc
;; Version  : 0.9
;; Keywords : helm, clojure, refactor
;; Package-Requires: ((clj-refactor "0.13.0") (helm-core "3.6.0") (cl-lib "0.5"))

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

;; A Helm wrapper for the cljr features.

;; Remembering key bindings for cljr is hard, especially the less
;; frequently used ones - this should help with that.

;; This package is available in melpa as `cljr-helm`. So doing `M-x
;; install-package RET cljr-helm` should get you what you need.

;; Then add `(require 'cljr-helm)` to your init file, bind `cljr-helm` to
;; a key (I'd suggest `C-c C-r`) in Clojure mode, and you're ready to go.

;;; Code:

(require 'helm-core)
(require 'clj-refactor)

(defun cljr-helm-candidates ()
  (mapcar (lambda (c)
            (concat (car c) ": " (cl-second (cdr c))))
          cljr--all-helpers))

(defvar helm-source-cljr
  '((name . "cljr functions hlel")
    (candidates . cljr-helm-candidates)
    (persistent-action . ignore)
    (action . (("Run" . (lambda (candidate)
                          (string-match "^\\(.+?\\): " candidate)
                          (call-interactively
                           (cadr (assoc (match-string 1 candidate) cljr--all-helpers)))))))))

;;;###autoload
(defun cljr-helm ()
  (interactive)
  (helm-other-buffer 'helm-source-cljr "*cljr*"))

(provide 'cljr-helm)

;;; cljr-helm.el ends here

