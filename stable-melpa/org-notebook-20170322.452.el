;;; org-notebook.el --- Ease the use of org-mode as a notebook  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Paul Elder

;; Author: Paul Elder <paul.elder@amanokami.net>
;; Keywords: convenience, tools
;; Package-Version: 20170322.452
;; Package-Commit: 86042d866bf441e2c9bb51f995e5994141b78517
;; Version: 1.1
;; Package-Requires: ((emacs "24") (org "8") (cl-lib "0.5"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; The main function is org-notebook-insert-image
;; Bind this to a convenient key combination
;;
;; There is also org-notebook-new-notebook
;; This creates a directory with the name of the
;; notebook you provide, and then creates
;; a notebook.org file and an img directory in it.
;; It populates the notebook.org file with org
;; headers, asking you for a title only since
;; the author, email, and language are extracted
;; automatically.
;;
;; For customization there is:
;;
;; org-notebook-drawing-program
;; By default this is set to kolourpaint
;; This determines what image-drawing program
;; will be launched when org-notebook-insert-image
;; is called.
;;
;; org-notebook-image-type
;; By default this is set to png
;; This determines the default filetype that
;; the drawn diagrams will be saved and linked.
;;
;; org-notebook-language
;; By default this is set to en
;; This determines the language org header that
;; will be inserted when org-notebook-new-notebook
;; is called.
;;
;; org-notebook-image-width
;; By default this is set to 600
;; This determines the image width org header that
;; will be inserted when org-notebook-new-notebook
;; is called. The header determines the width that
;; the images will be displayed in in org-mode.
;;
;; org-notebook-headers
;; By default this is an empty list
;; This is a list of cons where the first element
;; of each con is the header name (eg. LATEX_CLASS,
;; HTML_HEAD, etc) and the second element of each
;; con is the value of the header. These will be
;; inserted into the notebook org file when
;; org-notebook-new-notebook is called.

;;; Code:

(require 'org)
(require 'ido)
(require 'cl-lib)

(defgroup org-notebook nil
  "Ease the use of org-mode as a notebook"
  :group 'convenience
  :group 'tools
  :link '(emacs-library-link :tag "Lisp File" "org-notebook.el"))

(defcustom org-notebook-drawing-program (cond
                                         ((executable-find "kolourpaint") "kolourpaint")
                                         ((executable-find "mypaint") "mypaint")
                                         ((executable-find "krita") "krita")
                                         ((executable-find "gimp") "gimp"))
  "Drawing program to be used"
  :type 'string
  :group 'org-notebook)

(defcustom org-notebook-image-type "png"
  "Image type to be used"
  :type 'string
  :group 'org-notebook)

(defcustom org-notebook-language "en"
  "Language that the notebook will be in, mostly just for the org header"
  :type 'string
  :group 'org-notebook)

(defcustom org-notebook-image-width 600
  "Width of images in org"
  :type 'number
  :group 'org-notebook)

(defcustom org-notebook-headers '()
  "List of cons of html headers, latex headers, latex classes, etc"
  :type 'alist
  :group 'org-notebook)

;;;###autoload
(defun org-notebook-new-notebook ()
  "Create a new org-notebook notebook"
  (interactive)
  (let ((org-notebook-filepath (ido-read-file-name "Notebook name: " default-directory)))
    (make-directory org-notebook-filepath)
    (make-directory (concat org-notebook-filepath "/img"))
    (find-file (concat org-notebook-filepath "/notebook.org"))
    (insert "#+TITLE:     "
            (read-from-minibuffer
             "Title: " (car (last (split-string org-notebook-filepath "/"))))
            "\n"
            "# -*- mode: org; -*-" "\n"
            "#+AUTHOR:    " (user-full-name) "\n"
            "#+EMAIL:     " user-mail-address "\n"
            "#+LANGUAGE:  " org-notebook-language "\n"
            "#+ATTR_ORG: :width " (number-to-string org-notebook-image-width) "\n"
            (cl-loop for (name value) in org-notebook-headers
                     concat (format "#+%s: %s\n" name value)))))

;;;###autoload
(defun org-notebook-insert-image ()
  "Insert an image with auto-completion for the next image name and open the drawing program"
  (interactive)
  (unless (file-directory-p "./img") (make-directory "./img"))
  (let ((org-notebook-image-filepath
	 (concat
	  "./img/"
	  (read-from-minibuffer
           "Filename: "
           (format "img%d.png"
                   (+ (string-to-number
                       (substring
                        (car
                         (split-string
                          (car (last
                                (sort
                                 (or
                                  (cddr (directory-files "./img"))
                                  (list (concat "img0." org-notebook-image-type)))
                                 'org-notebook-dictionary-lessp)))
                          (concat "." org-notebook-image-type)))
                        3))
                      1))))))
    (insert "[[" org-notebook-image-filepath "]]")
    (start-process "org-notebook-drawing" nil org-notebook-drawing-program
                   org-notebook-image-filepath)))

;; The following is code for a custom comparison to allow for natural sorting to extract the guessed next-image name
;; Source: http://stackoverflow.com/questions/1942045/natural-order-sort-for-emacs-lisp

(defun org-notebook-dictionary-lessp (str1 str2)
  "return t if STR1 is < STR2 when doing a dictionary compare
(splitting the string at numbers and doing numeric compare with them)"
  (let ((str1-components (org-notebook-dict-split str1))
        (str2-components (org-notebook-dict-split str2)))
    (org-notebook-dict-lessp str1-components str2-components)))

(defun org-notebook-dict-lessp (slist1 slist2)
  "compare the two lists of strings & numbers"
  (cond ((null slist1)
         (not (null slist2)))
        ((null slist2)
         nil)
        ((and (numberp (car slist1))
              (stringp (car slist2)))
         t)
        ((and (numberp (car slist2))
              (stringp (car slist1)))
         nil)
        ((and (numberp (car slist1))
              (numberp (car slist2)))
         (or (< (car slist1) (car slist2))
             (and (= (car slist1) (car slist2))
                  (org-notebook-dict-lessp (cdr slist1) (cdr slist2)))))
        (t
         (or (string-lessp (car slist1) (car slist2))
             (and (string-equal (car slist1) (car slist2))
                  (org-notebook-dict-lessp (cdr slist1) (cdr slist2)))))))

(defun org-notebook-dict-split (str)
  "split a string into a list of number and non-number components"
  (save-match-data
    (let ((res nil))
      (while (and str (not (string-equal "" str)))
        (let ((p (string-match "[0-9]*\\.?[0-9]+" str)))
          (cond ((null p)
                 (setq res (cons str res))
                 (setq str nil))
                ((= p 0)
                 (setq res (cons (string-to-number (match-string 0 str)) res))
                 (setq str (substring str (match-end 0))))
                (t
                 (setq res (cons (substring str 0 (match-beginning 0)) res))
                 (setq str (substring str (match-beginning 0)))))))
      (reverse res))))

(provide 'org-notebook)
;;; org-notebook.el ends here
