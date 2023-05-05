;;; nerd-icons-ibuffer.el --- Display nerd icons in ibuffer        -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Vincent Zhang

;; Author: Vincent Zhang <seagle0128@gmail.com>
;; Homepage: https://github.com/seagle0128/nerd-icons-ibuffer
;; Version: 1.0.0
;; Package-Version: 20230417.1549
;; Package-Commit: 18c00c03a0d7193bab5e3374ec02c5428db057fd
;; Package-Requires: ((emacs "24.3") (nerd-icons "0.0.1"))
;; Keywords: convenience, icons, ibuffer

;; This file is not part of GNU Emacs.

;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;

;;; Commentary:

;; Display nerd icons in ibuffer.
;;
;; Install:
;; From melpa, `M-x package-install RET nerd-icons-ibuffer RET`.
;; (add-hook 'ibuffer-mode-hook #'nerd-icons-ibuffer-mode)
;; or
;; (use-package nerd-icons-ibuffer
;;   :ensure t
;;   :hook (ibuffer-mode . nerd-icons-ibuffer-mode))

;;; Code:

(require 'ibuffer)
(require 'nerd-icons)

(defgroup nerd-icons-ibuffer nil
  "Display nerd icons in ibuffer."
  :group 'nerd-icons
  :group 'ibuffer
  :link '(url-link :tag "Homepage" "https://github.com/seagle0128/nerd-icons-ibuffer"))

(defface nerd-icons-ibuffer-icon-face
  '((t (:inherit default)))
  "Face used for the icons while `nerd-icons-ibuffer-color-icon' is nil."
  :group 'nerd-icons-ibuffer)

(defface nerd-icons-ibuffer-dir-face
  '((t (:inherit font-lock-doc-face)))
  "Face used for the directory icon."
  :group 'nerd-icons-ibuffer)

(defface nerd-icons-ibuffer-size-face
  '((t (:inherit font-lock-constant-face)))
  "Face used for the size."
  :group 'nerd-icons-ibuffer)

(defface nerd-icons-ibuffer-mode-face
  '((t (:inherit font-lock-keyword-face)))
  "Face used for the major mode."
  :group 'nerd-icons-ibuffer)

(defface nerd-icons-ibuffer-file-face
  '((t (:inherit completions-annotations)))
  "Face used for the filename/process."
  :group 'nerd-icons-ibuffer)

(defcustom nerd-icons-ibuffer-icon t
  "Whether display the icons."
  :group 'nerd-icons-ibuffer
  :type 'boolean)

(defcustom nerd-icons-ibuffer-color-icon t
  "Whether display the colorful icons.

It respects `nerd-icons-color-icons'."
  :group 'nerd-icons-ibuffer
  :type 'boolean)

(defcustom nerd-icons-ibuffer-icon-size 1.0
  "The default icon size in ibuffer."
  :group 'nerd-icons-ibuffer
  :type 'float)

(defcustom nerd-icons-ibuffer-human-readable-size t
  "Use human readable file size in ibuffer."
  :group 'nerd-icons-ibuffer
  :type 'boolean)

(defcustom nerd-icons-ibuffer-formats
  `((mark modified read-only ,(if (>= emacs-major-version 26) 'locked "")
          ;; Here you may adjust by replacing :right with :center or :left
          ;; According to taste, if you want the icon further from the name
          " " (icon 2 2)
          (name 18 18 :left :elide)
          " " (size-h 9 -1 :right)
          " " (mode+ 16 16 :left :elide)
          " " filename-and-process+)
    (mark " " (name 16 -1) " " filename))
  "A list of ways to display buffer lines with `nerd-icons'.

See `ibuffer-formats' for details."
  :group 'nerd-icons-ibuffer
  :type '(repeat sexp))



(defun nerd-icons-ibuffer--file-size-human-readable-to-bytes (file-size &optional flavor)
  "Convert a human-readable FILE-SIZE string into bytes with FLAVOR."
  (let ((power (if (or (null flavor) (eq flavor 'iec))
		           1024.0
		         1000.0))
	    (prefixes '("k" "M" "G" "T" "P" "E" "Z" "Y"))
	    (iterator 0))
	(catch 'bytes
	  (while
	      (cond
	       ((equal iterator 8)
		    (throw 'bytes (* (string-to-number file-size) (expt power 0))))
	       ((string-match (elt prefixes iterator) file-size)
		    (throw 'bytes (* (string-to-number file-size) (expt power (1+ iterator)))))
	       (t
		    (setq iterator (1+ iterator))))))))

;; For alignment, the size of the name field should be the width of an icon
(define-ibuffer-column icon
  (:name "" :inline t)
  (if nerd-icons-ibuffer-icon
      (let ((icon (cond ((and (buffer-file-name) (nerd-icons-auto-mode-match?))
                         (nerd-icons-icon-for-file (file-name-nondirectory (buffer-file-name))
                                                   :height nerd-icons-ibuffer-icon-size))
                        ((eq major-mode 'dired-mode)
                         (nerd-icons-icon-for-dir (buffer-name)
                                                  :height nerd-icons-ibuffer-icon-size
                                                  :face 'nerd-icons-ibuffer-dir-face))
                        (t
                         (nerd-icons-icon-for-mode major-mode
                                                   :height nerd-icons-ibuffer-icon-size)))))
        (concat
         (if (or (null icon) (symbolp icon))
             (nerd-icons-faicon "nf-fa-file_o"
                                :face (if nerd-icons-ibuffer-color-icon
                                          'nerd-icons-dsilver
                                        'nerd-icons-ibuffer-icon-face)
                                :height nerd-icons-ibuffer-icon-size)
           (if nerd-icons-ibuffer-color-icon
               icon
             (propertize icon
                         'face `(:inherit nerd-icons-ibuffer-icon-face
                                 :family ,(plist-get (get-text-property 0 'face icon)
                                                     :family)))))
         " "))
    ""))

;; Human readable file size for ibuffer
(define-ibuffer-column size-h
  (:name "Size"
   :inline t
   :props ('font-lock-face 'nerd-icons-ibuffer-size-face)
   :header-mouse-map ibuffer-size-header-map
   :summarizer
   (lambda (column-strings)
     (let ((total 0))
       (dolist (string column-strings)
	     (setq total
	           ;; like, ewww ...
	           (+ (float (nerd-icons-ibuffer--file-size-human-readable-to-bytes string))
		          total)))
       (if nerd-icons-ibuffer-human-readable-size
           (file-size-human-readable total)
         (format "%0.f" total)))))
  (let ((size (buffer-size)))
    (if nerd-icons-ibuffer-human-readable-size
        (file-size-human-readable size)
      (format "%s" size))))

(define-ibuffer-column mode+
  (:name "Mode"
   :inline t
   :header-mouse-map ibuffer-mode-header-map
   :props ('font-lock-face 'nerd-icons-ibuffer-mode-face
                           'mouse-face 'highlight
	                       'keymap ibuffer-mode-name-map
	                       'help-echo "mouse-2: filter by this mode"))
  (format-mode-line mode-name nil nil (current-buffer)))

(define-ibuffer-column filename-and-process+
  (:name "Filename/Process"
   :props ('font-lock-face 'nerd-icons-ibuffer-file-face)
   :header-mouse-map ibuffer-filename/process-header-map
   :summarizer
   (lambda (strings)
     (setq strings (delete "" strings))
     (let ((procs 0)
	       (files 0))
       (dolist (string strings)
         (when (get-text-property 1 'ibuffer-process string)
           (setq procs (1+ procs)))
	     (setq files (1+ files)))
       (concat (cond ((zerop files) "No files")
		             ((= 1 files) "1 file")
		             (t (format "%d files" files)))
	           ", "
	           (cond ((zerop procs) "no processes")
		             ((= 1 procs) "1 process")
		             (t (format "%d processes" procs)))))))
  (let ((proc (get-buffer-process buffer))
	    (filename (ibuffer-make-column-filename buffer mark)))
    (if proc
	    (concat (propertize (format "(%s %s)" proc (process-status proc))
			                'font-lock-face 'italic
                            'ibuffer-process proc)
		        (if (> (length filename) 0)
		            (format " %s" filename)
		          ""))
      filename)))

(defvar nerd-icons-ibuffer-old-formats ibuffer-formats)

;;;###autoload
(define-minor-mode nerd-icons-ibuffer-mode
  "Display icons for all buffers in ibuffer."
  :lighter nil
  (when (derived-mode-p 'ibuffer-mode)
    (setq-local ibuffer-formats (if nerd-icons-ibuffer-mode
                                    nerd-icons-ibuffer-formats
                                  nerd-icons-ibuffer-old-formats))
    (ibuffer-update nil t)))

(provide 'nerd-icons-ibuffer)

;;; nerd-icons-ibuffer.el ends here
