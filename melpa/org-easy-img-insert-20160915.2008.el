;;; org-easy-img-insert.el --- An easier way to add images from the web in org mode  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Tashrif Sanil

;; Author: Tashrif Sanil <tashrifsanil@kloke-source.com>
;; URL: https://github.com/tashrifsanil/org-easy-img-insert
;; Package-Version: 20160915.2008
;; Package-Commit: 3efb4d70e5a39bfbf7ee4c4033cc61afa89430dd
;; Version: 2.0
;; Keywords: convenience, hypermedia, files
;; Package-Requires: ((emacs "24.4"))

;;; Commentary:
;;
;; This package (formerly known as auto-img-link-insert) makes inserting images from the web int org-mode much easier, and
;; quicker.  Launching, it opens up a mini-buffer where you can paste your link,
;; enter a name for it and optionally add a caption.  The rest is taken care of by
;; org-easy-img-insert, and it will be embed this data at your current cursor position.
;;

;;; Code:

(require 'subr-x)

(defun org-easy-img--extract-file-format (img-link)
  "Return the file format for a given web image link (IMG-LINK)."
  (when (string-match (concat "\\." (regexp-opt image-file-name-extensions)) img-link)
    (match-string 0 img-link)))

(defun org-easy-img--get-current-raw-file-name ()
  "Remove the file extension from the currently opened file and it's directory leaving just its raw file name."
  (let* ((current-file-name (buffer-file-name))
         (current-file-ext (concat "." (file-name-extension current-file-name)))
         (current-file-dir (file-name-directory current-file-name))
         (current-raw-file-name (string-remove-prefix current-file-dir current-file-name))
         (current-raw-file-name (string-remove-suffix current-file-ext current-raw-file-name))
         )
    current-raw-file-name
    )
  )

(defun org-easy-img--create-img-res-dir ()
  "Create the resource directory for the web image to be downloaded to."
  (let* ((current-file-name (buffer-file-name))
         (current-dir (file-name-directory current-file-name))
         (img-res-dir (concat  current-dir "Resources/"))
         )

    (unless (file-exists-p img-res-dir)
      (make-directory img-res-dir))

    (let ((img-res-dir (concat img-res-dir (org-easy-img--get-current-raw-file-name) "/")))
      (unless (file-exists-p img-res-dir)
        (make-directory img-res-dir))
      img-res-dir)
    )
  )

(defun org-easy-img--get-local-img-file-loc (img-name img-type)
  "Return the proposed local file location that the web image should be downloaded to, takes (IMG-NAME) and (IMG-TYPE) as args."
  (let ((img-local-file-loc (concat (org-easy-img--create-img-res-dir) img-name img-type)))
    img-local-file-loc))

;;;###autoload
(defun org-easy-img-insert (img-link img-name img-caption)
  "Automatically embed web image (IMG-LINK) with a name (IMG-NAME) and an optional caption (IMG-CAPTION) at cursor position in 'org-mode'."
  (interactive "MImage link: \nMImage name: \nMImage caption (optional): ")

  (let ((img-type (org-easy-img--extract-file-format img-link)))
    (let ((img-local-file-loc (org-easy-img--get-local-img-file-loc img-name img-type)))
      (start-process "img-download"
                     (get-buffer-create "*org-easy-img-insert*")
                     "wget"
                     img-link
                     "-O" img-local-file-loc)
      (org-easy-img--embed-img-at-cursor img-name img-caption img-local-file-loc))))

(defun org-easy-img--embed-img-at-cursor (img-name img-caption img-local-file-loc)
  "Function that actually embeds image data at current cursor position.  Takes (IMG-NAME),(IMG-CAPTION),(IMG-LOCAL-FILE-LOC) as args."
  (unless (string= "" img-caption)
    (insert (concat "#+CAPTION: " img-caption "\n")))
  (insert (concat "#+NAME: " img-name "\n"))
  (insert (concat "[[" img-local-file-loc "]]")))

(provide 'org-easy-img-insert)

;;; org-easy-img-insert.el ends here
