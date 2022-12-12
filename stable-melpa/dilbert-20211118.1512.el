;;; dilbert.el --- View Dilbert comics  -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Daniils Petrovs

;; Author: Daniils Petrovs <thedanpetrov@gmail.com>
;; URL: https://github.com/DaniruKun/dilbert-el
;; Version: 0.2
;; Package-Requires: ((emacs "26.1") (enlive "0.0.1") (dash "2.19.1"))
;; Keywords: multimedia news

;; This file is not part of GNU Emacs.

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

;; Read Dilbert comics from the comfort of Emacs.

;;;; Installation

;;;;; MELPA

;; If you installed from MELPA, you're done.

;;;;; Manual

;; Install these required packages:

;; + enlive
;; + dash

;; Then put this file in your load-path, and put this in your init
;; file:

;; (require 'dilbert)

;;;; Usage

;; Run one of these commands:

;; `dilbert': Get the latest Dilbert comic strip.

;;;; Tips

;; + You can customize settings in the `dilbert' group.

;;;; Credits

;; This package would not have been possible without the following
;; packages: xkcd[1].
;;
;;  [1] https://github.com/vibhavp/emacs-xkcd

;;; Code:

;;;; Requirements

(require 'url)
(require 'image)
(require 'enlive)
(require 'dash)
(require 'browse-url)

(define-derived-mode dilbert-mode special-mode "dilbert"
  "Major mode for viewing Dilbert (https://dilbert.com) comics."
  :group 'dilbert)

;;;; Customization

(defgroup dilbert nil
  "Settings for `dilbert'."
  :group 'multimedia
  :link '(url-link "https://github.com/DaniruKun/dilbert-el"))

(defcustom dilbert-cache-dir (let ((dir (concat user-emacs-directory "dilbert/")))
                               (make-directory dir :parents)
                               dir)
  "Directory for caching comics and other files."
  :group 'dilbert
  :type 'directory)

(defcustom dilbert-cache-latest (concat dilbert-cache-dir "latest")
  "File to store the latest cached dilbert number in.
Should preferably be located in `dilbert-cache-dir'."
  :group 'dilbert
  :type 'file)

;;;; Variables

(defconst dilbert-home-url "https://dilbert.com")


;;;; Structs

(defstruct dilbert-comic
  "Defines a single Dilbert comic strip entity to
be used for presentation."
  title url)

;;;;; Keymaps

(defvar dilbert-map
  ;; This makes it easy and much less verbose to define keys
  (let ((map (make-sparse-keymap "dilbert map"))
        (maps (list
               ;; Mappings go here, e.g.:
               "q" #'dilbert-kill-buffer)))
    (cl-loop for (key fn) on maps by #'cddr
             do (progn
                  (when (stringp key)
                    (setq key (kbd key)))
                  (define-key map key fn)))
    map))

;;;; Commands

;;;###autoload
(defun dilbert-view-latest ()
  "View the latest Dilbert comic strip."
  (interactive)
  (get-buffer-create "*dilbert*")
  (switch-to-buffer "*dilbert*")
  (dilbert-prep-buffer)
  (let (buffer-read-only)
    (erase-buffer)
    (let* ((comic (dilbert-latest-comic))
           (url (dilbert-comic-url comic))
           (title (dilbert-comic-title comic))
           (file (dilbert-download url)))
      (message "Getting comic...")
      (center-line)
      (insert "\n")
      (dilbert-insert-image file)
      (message "%s" title))))

;;;###autoload
(defalias 'dilbert #'dilbert-view-latest)

;;;; Functions

;;;; Private

(defun dilbert-fetch-homepage ()
  "Fetch the Dilbert homepage containing the latest comic strip."
  (enlive-fetch dilbert-home-url))

(defun dilbert-latest-comic ()
  "Returns the latest Dilbert comic."
  (->> (dilbert-latest-comics) (first)))

(defun dilbert-download (img-url)
  "Download the comic strip image at IMG-URL.
If exists, just return the full img path."
  (let* ((img-hash (-> img-url (split-string "/") (last) (first)))
        (file-name (format "%s%s.gif" dilbert-cache-dir img-hash)))
    (if (file-exists-p file-name)
        file-name
      (url-copy-file img-url file-name))
    file-name))

(defun dilbert-insert-image (file)
  "Insert image described by FILE in buffer with the title-text.
If the image is a gif, animate it."
  (let ((image (create-image file 'gif))
    (start (point)))
    (insert-image image)
    (if (or
         (and (fboundp 'image-multi-frame-p)
              (image-multi-frame-p image))
         (and (fboundp 'image-animated-p)
              (image-animated-p image)))
    (image-animate image 0 t))
    (add-text-properties start (point) '(help-echo "Alt"))))

(defun dilbert-kill-buffer ()
  "Kill the dilbert buffer."
  (interactive)
  (kill-buffer "*dilbert*"))

(defun dilbert-prep-buffer ()
  "Prepare the dilbert buffer for presentation by toggling modes."
  (dilbert-mode)
  (display-line-numbers-mode 0))

(defun dilbert-latest-comics ()
  "Fetches and returns the latest comic strips on the homepage."
  (let* ((homepage (dilbert-fetch-homepage))
         (img-selector [img.img-comic])
         (img->comic (lambda (img)
                       (let ((attrs (second img)))
                         (make-dilbert-comic
                          :title (->> attrs (assoc 'alt) (cdr))
                          :url (->> attrs (assoc 'src) (cdr)))))))
    (->> img-selector
     (enlive-query-all homepage)
     (-map img->comic))))

;;;; Footer

(provide 'dilbert)

;;; dilbert.el ends here
