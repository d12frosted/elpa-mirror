;;; didyoumean.el --- Did you mean to open another file? -*- lexical-binding: t; -*-

;; Authors: Kisaragi Hiu <mail@kisaragi-hiu.com>
;; URL: https://gitlab.com/kisaragi-hiu/didyoumean.el
;; Package-Version: 20200905.1843
;; Package-Commit: ce5edcce160b86e7f6480f0381be785d43f97e19
;; Version: 0.4.0
;; Package-Requires: ((emacs "24.4"))
;; Keywords: convenience

;; This file is NOT part of GNU Emacs.

;; MIT License
;;
;; Copyright (c) 2019 Kisaragi Hiu
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:
;; Ask for the right file to open.

;;; Code:

(require 'cl-lib)

(defgroup didyoumean nil
  "Did you mean to open another file?"
  :group 'convenience
  :prefix "didyoumean-")

(defcustom didyoumean-ignored-suffixes '(".elc" "~" ".bak" ".backup"
                                         ".pacnew" ".pacsave" ".blend1")
  "Do not suggest files that have these suffixes."
  :group 'didyoumean
  :type '(repeat string))

;; TODO: turn this into a hook
(defcustom didyoumean-custom-ignore-function nil
  "Do not suggest files that make this function return non-nil."
  :group 'didyoumean
  :type '(choice (const :tag "None" nil)
                 function))

(defvar didyoumean--history nil "History for `didyoumean' prompts.")

(defun didyoumean--matching-files (file)
  "Return files that seems to be similar in name to FILE (excluding itself)."
  (when (stringp file)
    (cl-remove-if
     (lambda (x) (or (not (string-prefix-p file x))
                     (equal file x)
                     ;; don't suggest suffixes in this list
                     (and didyoumean-ignored-suffixes
                          (cl-remove nil (mapcar
                                          (lambda (suf)
                                            (string-suffix-p suf x :ignore-case))
                                          didyoumean-ignored-suffixes)))
                     ;; don't suggest anything that d-c-i-f says so
                     (and (functionp didyoumean-custom-ignore-function)
                          (funcall didyoumean-custom-ignore-function file))))
     (directory-files "." (file-name-absolute-p file)))))

;;;###autoload
(defun didyoumean ()
  "Prompt for files similar to the current file if they exist."
  (interactive)
  (let* ((matching-files (didyoumean--matching-files buffer-file-name))
         (comp-read-func
          (cond ((or (bound-and-true-p ivy-mode)
                     (bound-and-true-p helm-mode))
                 ;; `completing-read' would be advised in this case
                 #'completing-read)
                ;; the list needs to be visible up front
                (t (require 'ido)
                   #'ido-completing-read)))
         (correct-file
          (when matching-files
            (funcall comp-read-func
                     "Did you mean: "
                     `(,buffer-file-name ,@matching-files)
                     nil nil nil
                     'didyoumean--history)))
         (this-file (current-buffer)))
    (when (and correct-file
               (not (equal buffer-file-name correct-file)))
      (find-file correct-file)
      ;; killing the buffer during find-file-hook, sure...?
      (kill-buffer this-file))))

;;;###autoload
(define-minor-mode didyoumean-mode
  "DidYouMean minor mode.

Prompt for files similar to the current file if they exist."
  :global t
  (if didyoumean-mode
      (add-hook 'find-file-hook #'didyoumean)
    (remove-hook 'find-file-hook #'didyoumean)))

(defun didyoumean-unload-function ()
  "Unload DidYouMean."
  (didyoumean-mode -1)
  ;; Continue standard unloading.
  ;; See (info "(elisp)Unloading").
  nil)

(provide 'didyoumean)
;;; didyoumean.el ends here
