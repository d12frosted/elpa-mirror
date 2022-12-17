;;; exato.el --- EXATO: Evil XML/HTML Attributes Text Object -*- lexical-binding: t -*-

;; Copyright (C) 2017, 2018 by Filipe Silva (ninrod)

;; Author: Filipe Silva <filipe.silva@gmail.com>
;; URL: https://github.com/ninrod/exato
;; Package-Version: 20200524.1319
;; Package-Commit: 5e7b5721bf48aa49c6cdb5d41b908ef7d513b2a8
;; Version: 0.0.1
;; Package-Requires: ((evil "1.2.13") (emacs "24"))

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

;; This package provides the `x` text object to manipulate html/xml tag attributes.
;; it is a port of https://github.com/whatyouhide/vim-textobj-xmlattr vim plugin.

;; Try using `dax`, `vix` and `gUix`. You can customize the binding.

;; To install the package, Just use https://melpa.org.
;; Here's an oneliner using https://github.com/jwiegley/use-package:
;; (use-package exato :ensure t)

;; *customization*: to change the bind from `x` to your liking, you can customize exato-key:

;; (use-package exato
;;   :ensure t
;;   :init
;;   (setq exato-key "h"))

;;; Code:

;;; Settings:

(require 'evil)

(defgroup exato nil
  "Provides a xml tag attribute text object."
  :group 'exato
  :prefix 'exato-)

(defcustom exato-key "x"
  "Key for exato text object."
  :type 'string
  :group 'exato)

;;; Core functions

(defun exato--evil-bounds-of-string-at-point ()
  (save-excursion
    (or (bounds-of-evil-string-at-point)
        (progn (forward-char) (bounds-of-evil-string-at-point)))))

(defun exato--find-str-start ()
  "Find the beggining of the string."
  (condition-case nil
      (save-excursion
        (goto-char (car (exato--evil-bounds-of-string-at-point)))
        (point))
    (error nil)))

(defun exato--find-str-end ()
  "Find the end of the string."
  (condition-case nil
      (save-excursion
        (goto-char (cdr (exato--evil-bounds-of-string-at-point)))
        (1- (point)))
    (error nil)))

(defun exato--find-delimiter-backward ()
  "Backward search the occurence of the delimiter."
  (let ((str-start (exato--find-str-start)))
    (cond (str-start
           (save-excursion
             (goto-char (1- str-start))
             (cond ((looking-at "=")
                    (point))
                   (t
                    nil))))
          ((looking-at "[[:alpha:]]")
           (save-excursion
             (skip-chars-backward "[[:alpha:]]")
             (backward-char)
             (cond ((looking-at "=")
                    (point))
                   (t
                    nil))))
          (t nil))))

(defun exato--find-delimiter-forward ()
  "Forward search the occurence of the delimiter."
  (save-excursion
    (when (looking-at " ")
      (skip-chars-forward " \n\t"))
    (let ((tag-close
           (save-excursion
             (cond ((search-forward ">" (point-max) t)
                    (1- (point)))
                   (t
                    (point-max))))))
      (cond ((re-search-forward "=\"" tag-close t)
             (- (point) 2))
            ((re-search-forward "=" tag-close t)
             (1- (point)))
            (t
             nil)))))

(defun exato--find-delimiter ()
  "Try to find the delimiter around point."
  (let* ((backward (exato--find-delimiter-backward))
         (forward (exato--find-delimiter-forward)))
    (cond (backward backward)
          (forward forward)
          (t nil))))

(defun exato--find-xml-attr-start ()
  "Try to pinpoint the start of the xml attribute."
  (let ((delimiter (exato--find-delimiter)))
    (cond (delimiter
           (save-excursion
             (goto-char delimiter)
             (skip-chars-backward "^ ")
             (point)))
          (t
           nil))))

(defun exato--find-xml-attr-end ()
  "Try to pinpoint the end of the xml attribute."
  (let* ((delimiter (exato--find-delimiter)))
    (cond (delimiter
           (save-excursion
             (goto-char (1+ delimiter))
             (cond ((looking-at "\"")
                    (exato--find-str-end))
                   (t
                    (cond ((looking-at "[[:alpha:]]")
                           (save-excursion
                             (skip-chars-forward "[[:alpha:]]")
                             (backward-char)
                             (point)))
                          (t
                           nil))))))
          (t nil))))

;;; Connect to evil machinery:

(defun exato--evil-xml-attr-inner-range ()
  "Define the inner xml attr text object."
  (let ((start (exato--find-xml-attr-start))
        (finish (exato--find-xml-attr-end)))
    (cond ((and start finish)
           (evil-range start (1+ finish)))
          (t
           nil))))

(defun exato--evil-xml-attr-outer-range ()
  "Define the outer xml attr text object."
  (let ((start (exato--find-xml-attr-start))
        (finish (exato--find-xml-attr-end)))
    (cond ((and start finish)
           (evil-range (1- start) (1+ finish)))
          (t
           nil))))

(evil-define-text-object evil-inner-xml-attr (count &optional _beg _end _type)
  (exato--evil-xml-attr-inner-range))
(evil-define-text-object evil-outer-xml-attr (count &optional _beg _end _type)
  (exato--evil-xml-attr-outer-range))

(define-key evil-outer-text-objects-map exato-key 'evil-outer-xml-attr)
(define-key evil-inner-text-objects-map exato-key 'evil-inner-xml-attr)

(provide 'exato)

;;; exato.el ends here
