;;; all-the-icons-ibuffer.el --- Display icons for all buffers in ibuffer        -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Vincent Zhang

;; Author: Vincent Zhang <seagle0128@gmail.com>
;; Homepage: https://github.com/seagle0128/all-the-icons-ibuffer
;; Version: 1.5.0
;; Package-Version: 20220424.1027
;; Package-Commit: 0c7221366ceddbf122073ecd07dd86e1baf032ff
;; Package-Requires: ((emacs "24.4") (all-the-icons "2.2.0"))
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

;; Display icons for all buffers in ibuffer.
;;
;; Install:
;; From melpa, `M-x package-install RET all-the-icons-ibuffer RET`.
;; (add-hook 'ibuffer-mode-hook #'all-the-icons-ibuffer-mode)
;; or
;; (use-package all-the-icons-ibuffer
;;   :ensure t
;;   :hook (ibuffer-mode . all-the-icons-ibuffer-mode))

;;; Code:

(require 'ibuffer)
(require 'all-the-icons)

(defgroup all-the-icons-ibuffer nil
  "Display icons for all buffers in ibuffer."
  :group 'all-the-icons
  :group 'ibuffer
  :link '(url-link :tag "Homepage" "https://github.com/seagle0128/all-the-icons-ibuffer"))

(defface all-the-icons-ibuffer-icon-face
  '((t (:inherit default)))
  "Face used for the icons while `all-the-icons-ibuffer-color-icon' is nil."
  :group 'all-the-icons-ibuffer)

(defface all-the-icons-ibuffer-dir-face
  '((t (:inherit font-lock-doc-face)))
  "Face used for the directory icon."
  :group 'all-the-icons-ibuffer)

(defface all-the-icons-ibuffer-size-face
  '((t (:inherit font-lock-comment-face)))
  "Face used for the size."
  :group 'all-the-icons-ibuffer)

(defface all-the-icons-ibuffer-mode-face
  '((t (:inherit font-lock-keyword-face)))
  "Face used for the major mode."
  :group 'all-the-icons-ibuffer)

(defface all-the-icons-ibuffer-file-face
  '((t (:inherit font-lock-comment-face)))
  "Face used for the filename/process."
  :group 'all-the-icons-ibuffer)

(defcustom all-the-icons-ibuffer-display-predicate #'display-graphic-p
  "Predicate whether the icons are able to be displayed."
  :group 'all-the-icons-ibuffer
  :type 'boolean)

(defcustom all-the-icons-ibuffer-icon t
  "Whether display the icons."
  :group 'all-the-icons-ibuffer
  :type 'boolean)

(defcustom all-the-icons-ibuffer-color-icon t
  "Whether display the colorful icons.

It respects `all-the-icons-color-icons'."
  :group 'all-the-icons-ibuffer
  :type 'boolean)

(defcustom all-the-icons-ibuffer-icon-size 1.0
  "The default icon size in ibuffer."
  :group 'all-the-icons-ibuffer
  :type 'float)

(defcustom all-the-icons-ibuffer-icon-v-adjust 0.0
  "The default vertical adjustment of the icon in ibuffer."
  :group 'all-the-icons-ibuffer
  :type 'float)

(defcustom all-the-icons-ibuffer-human-readable-size t
  "Use human readable file size in ibuffer."
  :group 'all-the-icons-ibuffer
  :type 'boolean)

(defcustom all-the-icons-ibuffer-formats
  `((mark modified read-only ,(if (>= emacs-major-version 26) 'locked "")
          ;; Here you may adjust by replacing :right with :center or :left
          ;; According to taste, if you want the icon further from the name
          " " ,(if all-the-icons-ibuffer-icon
                   '(icon 2 2 :left :elide)
                 "")
          ,(if all-the-icons-ibuffer-icon
               (propertize " " 'display `(space :align-to 8))
             "")
          (name 18 18 :left :elide)
          " " (size-h 9 -1 :right)
          " " (mode+ 16 16 :left :elide)
          " " filename-and-process+)
    (mark " " (name 16 -1) " " filename))
  "A list of ways to display buffer lines with `all-the-icons'.

See `ibuffer-formats' for details."
  :group 'all-the-icons-ibuffer
  :type '(repeat sexp))

(defcustom all-the-icons-ibuffer-formats-simple
  `((mark modified read-only ,(if (>= emacs-major-version 26) 'locked "")
          ;; Here you may adjust by replacing :right with :center or :left
          ;; According to taste, if you want the icon further from the name
          (name 18 18 :left :elide)
          " " (size-h 9 -1 :right)
          " " (mode+ 16 16 :left :elide)
          " " filename-and-process+)
    (mark " " (name 16 -1) " " filename))
  "A list of ways to display buffer lines with `all-the-icons'.

See `ibuffer-formats' for details."
  :group 'all-the-icons-ibuffer
  :type '(repeat sexp))



(defun all-the-icons-ibuffer--file-size-human-readable-to-bytes (file-size &optional flavor)
  "Convert a human-readable file size string into bytes."
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
  (:name "  " :inline t)
  (let ((icon (cond ((and (buffer-file-name) (all-the-icons-auto-mode-match?))
                     (all-the-icons-icon-for-file (file-name-nondirectory (buffer-file-name))
                                                  :height all-the-icons-ibuffer-icon-size
                                                  :v-adjust all-the-icons-ibuffer-icon-v-adjust))
                    ((eq major-mode 'dired-mode)
                     (all-the-icons-icon-for-dir (buffer-name)
                                                 :height all-the-icons-ibuffer-icon-size
                                                 :v-adjust all-the-icons-ibuffer-icon-v-adjust
                                                 :face 'all-the-icons-ibuffer-dir-face))
                    (t (all-the-icons-icon-for-mode major-mode
                                                    :height all-the-icons-ibuffer-icon-size
                                                    :v-adjust all-the-icons-ibuffer-icon-v-adjust)))))
    (if (or (null icon) (symbolp icon))
        (setq icon (all-the-icons-faicon "file-o"
                                         :face (if all-the-icons-ibuffer-color-icon
                                                   'all-the-icons-dsilver
                                                 'all-the-icons-ibuffer-icon-face)
                                         :height (* 0.9 all-the-icons-ibuffer-icon-size)
                                         :v-adjust all-the-icons-ibuffer-icon-v-adjust))
      (let* ((props (get-text-property 0 'face icon))
             (family (plist-get props :family))
             (face (if all-the-icons-ibuffer-color-icon
                       (or (plist-get props :inherit) props)
                     'all-the-icons-ibuffer-icon-face))
             (new-face `(:inherit ,face :family ,family)))
        (propertize icon 'face new-face)))))

;; Human readable file size for ibuffer
(define-ibuffer-column size-h
  (:name "Size"
   :inline t
   :props ('font-lock-face 'all-the-icons-ibuffer-size-face)
   :header-mouse-map ibuffer-size-header-map
   :summarizer
   (lambda (column-strings)
     (let ((total 0))
       (dolist (string column-strings)
	     (setq total
	           ;; like, ewww ...
	           (+ (float (all-the-icons-ibuffer--file-size-human-readable-to-bytes string))
		          total)))
       (if all-the-icons-ibuffer-human-readable-size
           (file-size-human-readable total)
         (format "%0.f" total)))))
  (let ((size (buffer-size)))
    (if all-the-icons-ibuffer-human-readable-size
        (file-size-human-readable size)
      (format "%s" size))))

(define-ibuffer-column mode+
  (:name "Mode"
   :inline t
   :header-mouse-map ibuffer-mode-header-map
   :props ('font-lock-face 'all-the-icons-ibuffer-mode-face
                           'mouse-face 'highlight
	                       'keymap ibuffer-mode-name-map
	                       'help-echo "mouse-2: filter by this mode"))
  (format-mode-line mode-name nil nil (current-buffer)))

(define-ibuffer-column filename-and-process+
  (:name "Filename/Process"
   :props ('font-lock-face 'all-the-icons-ibuffer-file-face)
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

(defvar all-the-icons-ibuffer-old-formats ibuffer-formats)

;;;###autoload
(define-minor-mode all-the-icons-ibuffer-mode
  "Display icons for all buffers in ibuffer."
  :lighter nil
  (when (derived-mode-p 'ibuffer-mode)
    (if all-the-icons-ibuffer-mode
        (if (funcall all-the-icons-ibuffer-display-predicate)
            (setq-local ibuffer-formats all-the-icons-ibuffer-formats)
          (setq-local ibuffer-formats all-the-icons-ibuffer-formats-simple))
      (setq-local ibuffer-formats all-the-icons-ibuffer-old-formats))))

(provide 'all-the-icons-ibuffer)

;;; all-the-icons-ibuffer.el ends here
