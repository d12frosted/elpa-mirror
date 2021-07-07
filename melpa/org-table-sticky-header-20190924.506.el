;;; org-table-sticky-header.el --- Sticky header for org-mode tables  -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Junpeng Qiu

;; Author: Junpeng Qiu <qjpchmail@gmail.com>
;; Keywords: extensions
;; Package-Version: 20190924.506
;; Package-Commit: b65442857128ab04724aaa301e60aa874a31a798
;; Version: 0.1.0
;; Package-Requires: ((org "8.2.10") (emacs "24.4"))

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

;;                      ______________________________

;;                       ORG-TABLE-STIKCY-HEADER-MODE

;;                               Junpeng Qiu
;;                      ______________________________


;; Table of Contents
;; _________________

;; 1 Overview
;; 2 Usage
;; 3 Demo


;; [[file:https://melpa.org/packages/org-table-sticky-header-badge.svg]]

;; A minor mode to show the sticky header for org-mode tables.


;; [[file:https://melpa.org/packages/org-table-sticky-header-badge.svg]]
;; https://melpa.org/#/org-table-sticky-header


;; 1 Overview
;; ==========

;;   Similar to `semantic-stickyfunc-mode', this package uses the header
;;   line to show the table header when it is out of sight.


;; 2 Usage
;; =======

;;   To install manually:
;;   ,----
;;   | (add-to-list 'load-path "/path/to/org-table-sticky-header.el")
;;   `----

;;   `M-x org-table-sticky-header-mode' to enable the minor mode in an
;;   org-mode buffer.

;;   To automatically enable the minor mode in all org-mode buffers, use
;;   ,----
;;   | (add-hook 'org-mode-hook 'org-table-sticky-header-mode)
;;   `----


;; 3 Demo
;; ======

;;   [./screenshots/demo.gif]

;;; Code:

(require 'org)
(require 'org-table)

(defface org-table-sticky-header-face
  '((t :inherit 'default))
  "Face for org-table-sticky-header."
  :group 'org-faces)

(defvar org-table-sticky-header--last-win-start -1)
(defvar org-table-sticky-header--old-header-line-format nil)

(defun org-table-sticky-header--is-header-p (line)
  (not
   (or (string-match "^ *|-" line)
       (let ((cells (split-string line "|"))
             (ret t))
         (catch 'break
           (dolist (c cells ret)
             (unless (or (string-match "^ *$" c)
                         (string-match "^ *<[0-9]+> *$" c)
                         (string-match "^ *<[rcl][0-9]*> *$" c))
               (throw 'break nil))))))))

(defun org-table-sticky-header--table-real-begin ()
  (save-excursion
    (goto-char (org-table-begin))
    (while (and (not (eobp))
                (not (org-table-sticky-header--is-header-p
                      (buffer-substring-no-properties
                       (point-at-bol)
                       (point-at-eol)))))
      (forward-line))
    (point)))

(defun org-table-sticky-header-org-table-header-visible-p ()
  (save-excursion
    (goto-char org-table-sticky-header--last-win-start)
    (>= (org-table-sticky-header--table-real-begin) (point))))

(defun org-table-sticky-header--get-display-line-number-width ()
  (if (bound-and-true-p display-line-numbers-mode)
      ;; 2 extra columns for padding
      (+ 2 (line-number-display-width))
    0))

(defun org-table-sticky-header--get-line-prefix-width (line)
  (let (prefix)
    (or (and (bound-and-true-p org-indent-mode)
             (setq prefix (get-text-property 0 'line-prefix line))
             (string-width prefix))
        0)))

(defun org-table-sticky-header--get-visual-header (text visual-col)
  (if (= visual-col 0)
      text
    (with-temp-buffer
      (insert text)
      (goto-char (point-min))
      (while (> visual-col 0)
        (when (string= (get-text-property (point) 'display) "=>")
          (setq visual-col (1- visual-col)))
        (move-point-visually 1)
        (setq visual-col (1- visual-col)))
      (buffer-substring (point) (point-at-eol)))))

(defun org-table-sticky-header-get-org-table-header ()
  (let ((col (window-hscroll))
        visual-header)
    (save-excursion
      (goto-char org-table-sticky-header--last-win-start)
      (if (bobp)
          ""
        (if (org-at-table-p 'any)
            (goto-char (org-table-sticky-header--table-real-begin))
          (forward-line -1))
        (setq visual-header
              (org-table-sticky-header--get-visual-header
               (buffer-substring (point-at-bol) (point-at-eol))
               col))
        (remove-text-properties 0
                                (length visual-header)
                                '(face nil)
                                visual-header)
        visual-header))))

(defun org-table-sticky-header--fetch-header ()
  (if (org-table-sticky-header-org-table-header-visible-p)
      (setq header-line-format org-table-sticky-header--old-header-line-format)
    ;; stole from `semantic-stickyfunc-mode'
    (let ((line (org-table-sticky-header-get-org-table-header)))
      (setq header-line-format
            `(:eval (list
                     (propertize
                      " "
                      'display
                      '((space :align-to
                               ,(+ (org-table-sticky-header--get-display-line-number-width)
                                   (org-table-sticky-header--get-line-prefix-width line)))))
                     (propertize
                      ,line
                      'face 'org-table-sticky-header-face)))))))

(defun org-table-sticky-header--scroll-function (win start-pos)
  (unless (= org-table-sticky-header--last-win-start start-pos)
    (setq org-table-sticky-header--last-win-start start-pos)
    (save-match-data
      (org-table-sticky-header--fetch-header))))

(defun org-table-sticky-header--insert-delete-column ()
  (if org-table-sticky-header-mode
      (save-match-data
        (org-table-sticky-header--fetch-header))))

(defun org-table-sticky-header--table-move-column (&optional left)
  (if org-table-sticky-header-mode
      (save-match-data
        (org-table-sticky-header--fetch-header))))

;;;###autoload
(define-minor-mode org-table-sticky-header-mode
  "Sticky header for org-mode tables."
  nil " OTSH" nil
  (if org-table-sticky-header-mode
      (if (derived-mode-p 'org-mode)
          (progn
            (setq org-table-sticky-header--old-header-line-format header-line-format)
            (add-hook 'window-scroll-functions
                      'org-table-sticky-header--scroll-function 'append 'local)
            (advice-add 'org-table-delete-column :after #'org-table-sticky-header--insert-delete-column)
            (advice-add 'org-table-insert-column :after #'org-table-sticky-header--insert-delete-column)
            (advice-add 'org-table-move-column :after #'org-table-sticky-header--table-move-column)
            (setq org-table-sticky-header--last-win-start (window-start))
            (org-table-sticky-header--fetch-header))
        (setq org-table-sticky-header-mode nil)
        (error "Not in `org-mode'"))
    (advice-remove 'org-table-delete-column #'org-table-sticky-header--insert-delete-column)
    (advice-remove 'org-table-insert-column #'org-table-sticky-header--insert-delete-column)
    (advice-remove 'org-table-move-column #'org-table-sticky-header--table-move-column)
    (remove-hook 'window-scroll-functions 'org-table-sticky-header--scroll-function 'local)
    (setq header-line-format org-table-sticky-header--old-header-line-format)))

(provide 'org-table-sticky-header)
;;; org-table-sticky-header.el ends here
