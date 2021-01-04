;;; org-link-beautify.el --- Beautify Org Links -*- lexical-binding: t; -*-

;;; Time-stamp: <2021-01-05 01:08:49 stardiviner>

;; Authors: stardiviner <numbchild@gmail.com>
;; Package-Requires: ((emacs "27.1") (all-the-icons "4.0.0"))
;; Package-Commit: a04d84d89c37b75578aba442a32259d34f0c0a67
;; Package-Version: 20210104.1709
;; Package-X-Original-Version: 1.1.0
;; Keywords: hypermedia
;; homepage: https://github.com/stardiviner/org-link-beautify

;; org-link-beautify is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; org-link-beautify is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Usage:
;;
;; (org-link-beautify-mode 1)

;;; Code:

(require 'ol)
(require 'org-element)
(require 'all-the-icons)

(defgroup org-link-beautify nil
  "Customize group of org-link-beautify-mode."
  :prefix "org-link-beautify-"
  :group 'org)

(defcustom org-link-beautify-exclude-modes '(org-agenda-mode)
  "A list of excluded major modes which wouldn't enable `org-link-beautify'."
  :type 'list
  :safe #'listp
  :group 'org-link-beautify)

(defcustom org-link-beautify-video-preview (executable-find "ffmpegthumbnailer")
  "Whether enable video files thumbnail preview?"
  :type 'boolean
  :safe #'booleanp
  :group 'org-link-beautify)

(defcustom org-link-beautify-thumbnails-dir 'source-path
  "The directory of generated thumbnails.

By default the thumbnails are generated in source file path’s
.thumbnails directory. This is better for avoiding re-generate
preview thumbnails. Or you can set this option to ‘'user-home’
which represent to ~/.cache/thumbnails/."
  :type 'symbol
  :safe #'symbol
  :group 'org-link-beautify)

(defcustom org-link-beautify-video-preview-size 512
  "The video thumbnail image size."
  :type 'number
  :safe #'numberp
  :group 'org-link-beautify)

(defcustom org-link-beautify-video-preview-list '("avi" "rmvb" "ogg" "ogv" "mp4" "mkv" "mov" "webm" "flv")
  "A list of video file types be supported with thumbnails."
  :type 'list
  :safe #'listp
  :group 'org-link-beautify)

(defcustom org-link-beautify-pdf-preview (or (executable-find "pdftocairo")
                                             (executable-find "pdf2svg"))
  "Whether enable PDF files image preview?
If command \"pdftocairo\" or \"pdf2svg\" is available, enable PDF
preview by default. You can set this option to nil to disable
PDF preview."
  :type 'boolean
  :safe #'booleanp
  :group 'org-link-beautify)

(defcustom org-link-beautify-pdf-preview-command 'pdftocairo
  "The command used to preview PDF file cover."
  :type '(choice
          :tag "The command used to preview PDF cover."
          (const :tag "pdftocairo" pdftocairo)
          (const :tag "pdf2svg" pdf2svg))
  :safe #'symbolp
  :group 'org-link-beautify)

;;; TODO: smarter value decided based on screen size.
(defcustom org-link-beautify-pdf-preview-size 512
  "The PDF preview image size."
  :type 'number
  :safe #'numberp
  :group 'org-link-beautify)

(defcustom org-link-beautify-pdf-preview-default-page-number 1
  "The default PDF preview page number."
  :type 'number
  :safe #'numberp
  :group 'org-link-beautify)

(defcustom org-link-beautify-pdf-preview-image-format 'png
  "The format of PDF file preview image."
  :type '(choice
          :tag "The format of PDF file preview image."
          (const :tag "PNG" png)
          (const :tag "JPEG" jpeg)
          (const :tag "SVG" svg))
  :safe #'symbolp
  :group 'org-link-beautify)

(defcustom org-link-beautify-epub-preview (executable-find "gnome-epub-thumbnailer")
  "Whether enable EPUB files cover preview?
If command \"gnome-epub-thumbnailer\" is available, enable EPUB
preview by default. You can set this option to nil to disable
EPUB preview."
  :type 'boolean
  :safe #'booleanp
  :group 'org-link-beautify)

(defcustom org-link-beautify-epub-preview-size 400
  "The EPUB cover preview image size."
  :type 'number
  :safe #'numberp
  :group 'org-link-beautify)

(defcustom org-link-beautify-text-preview nil
  "Whether enable text files content preview?"
  :type 'boolean
  :safe #'booleanp
  :group 'org-link-beautify)

(defcustom org-link-beautify-text-preview-list
  '("org" "txt" "markdown" "md"
    "lisp" "scm" "clj" "cljs"
    "py" "rb" "pl"
    "c" "cpp" "h" "hpp" "cs" "java"
    "r" "jl")
  "A list of link types supports text preview below the link."
  :type 'list
  :safe #'listp
  :group 'org-link-beautify)

(defun org-link-beautify--get-element (position)
  "Return the org element of link at the `POSITION'."
  (save-excursion (goto-char position) (org-element-context)))

(defun org-link-beautify--get-link-description-fast (position)
  "Get the link description at `POSITION' (fuzzy but faster version)."
  (save-excursion
    (goto-char position)
    (and (org-in-regexp org-link-bracket-re) (match-string 2))))

(defun org-link-beautify--warning (path)
  "Use `org-warning' face if link PATH does not exist."
  (if (and (not (file-remote-p path))
           (file-exists-p (expand-file-name path)))
      'org-link 'org-warning))

(defun org-link-beautify--add-overlay-marker (start end)
  "Add 'org-link-beautify on link text-property. between START and END."
  (put-text-property start end 'type 'org-link-beautify))

(defun org-link-beautify--display-thumbnail (thumbnail thumbnail-size start end)
  "Display THUMBNAIL between START and END in size of THUMBNAIL-SIZE only when it exist."
  (when (file-exists-p thumbnail)
    (put-text-property
     start end
     'display (create-image thumbnail nil nil :ascent 'center :max-height thumbnail-size))))

(defun org-link-beautify--preview-pdf (path start end)
  "Preview PDF file PATH and display on link between START and END."
  (if (string-match "\\(.*?\\)\\(?:::\\(.*\\)\\)?\\'" path)
      (let* ((file-path (match-string 1 path))
             ;; DEBUG: (_ (lambda (message "--> HERE")))
             (pdf-page-number (or (match-string 2 path)
                                  org-link-beautify-pdf-preview-default-page-number))
             (pdf-file (expand-file-name (org-link-unescape file-path)))
             (thumbnails-dir (pcase org-link-beautify-thumbnails-dir
                               ('source-path
                                (concat (file-name-directory pdf-file) ".thumbnails/"))
                               ('user-home
                                (expand-file-name "~/.cache/thumbnails/"))))
             (thumbnail (expand-file-name
                         (concat
                          (if (= pdf-page-number 1)
                              (format "%s%s.%s"
                                      thumbnails-dir (file-name-base pdf-file)
                                      (symbol-name org-link-beautify-pdf-preview-image-format))
                            (format "%s%s-P%s.%s"
                                    thumbnails-dir (file-name-base pdf-file) pdf-page-number
                                    (symbol-name org-link-beautify-pdf-preview-image-format))))))
             (thumbnail-size (or org-link-beautify-pdf-preview-size 512)))
        (unless (file-directory-p thumbnails-dir)
          (make-directory thumbnails-dir))
        (unless (file-exists-p thumbnail)
          (pcase org-link-beautify-pdf-preview-command
            ('pdftocairo
             ;; DEBUG:
             ;; (message
             ;;  "org-link-beautify: page-number %s, pdf-file %s, thumbnail %s"
             ;;  pdf-page-number pdf-file thumbnail)
             (start-process
              "org-link-beautify--pdf-preview"
              " *org-link-beautify pdf-preview*"
              "pdftocairo"
              (pcase org-link-beautify-pdf-preview-image-format
                ('png "-png")
                ('jpeg "-jpeg")
                ('svg "-svg"))
              "-singlefile"
              "-f" (number-to-string pdf-page-number)
              pdf-file (file-name-sans-extension thumbnail)))
            ('pdf2svg
             (unless (eq org-link-beautify-pdf-preview-image-format 'svg)
               (warn "The pdf2svg only supports convert PDF to SVG format.
Please adjust `org-link-beautify-pdf-preview-command' to `pdftocairo' or
Set `org-link-beautify-pdf-preview-image-format' to `svg'."))

             (start-process
              "org-link-beautify--pdf-preview"
              " *org-link-beautify pdf-preview*"
              "pdf2svg"
              pdf-file thumbnail (number-to-string pdf-page-number)))))
        (org-link-beautify--add-overlay-marker start end)
        ;; display thumbnail only when it exist.
        (org-link-beautify--display-thumbnail thumbnail thumbnail-size start end))))

(defun org-link-beautify--preview-epub (path start end)
  "Preview EPUB file PATH and display on link between START and END."
  (if (string-match "\\(.*?\\)\\(?:::\\(.*\\)\\)?\\'" path)
      (let* ((file-path (match-string 1 path))
             ;; DEBUG: (_ (lambda (message "--> HERE")))
             (_epub-page-number (or (match-string 2 path) 1))
             (epub-file (expand-file-name (org-link-unescape file-path)))
             (thumbnails-dir (pcase org-link-beautify-thumbnails-dir
                               ('source-path
                                (concat (file-name-directory epub-file) ".thumbnails/"))
                               ('user-home
                                (expand-file-name "~/.cache/thumbnails/"))))
             (thumbnail (expand-file-name
                         (format "%s%s.png"
                                 thumbnails-dir (file-name-base epub-file))))
             (thumbnail-size (or org-link-beautify-epub-preview-size 600)))
        (unless (file-directory-p thumbnails-dir)
          (make-directory thumbnails-dir))
        (unless (file-exists-p thumbnail)
          ;; DEBUG:
          ;; (message
          ;;  "org-link-beautify: epub-file %s, thumbnail %s"
          ;;  epub-file thumbnail)
          (start-process
           "org-link-beautify--epub-preview"
           ;; DEBUG: check out this output buffer
           " *org-link-beautify epub-preview*"
           "gnome-epub-thumbnailer"
           epub-file thumbnail
           ;; FIXME:
           ;; (when org-link-beautify-epub-preview-size
           ;;   '("--size" thumbnail-size))
           ))
        (org-link-beautify--add-overlay-marker start end)
        (org-link-beautify--display-thumbnail thumbnail thumbnail-size start end))))

(defun org-link-beautify--preview-text-file (file lines)
  "Return first LINES of FILE."
  (with-temp-buffer
    (insert-file-contents-literally file)
    (cl-loop repeat lines
             unless (eobp)
             collect (prog1 (buffer-substring-no-properties
                             (line-beginning-position)
                             (line-end-position))
                       (forward-line 1)))))

(defun org-link-beautify--preview-text (path start end)
  "Preview TEXT file PATH and display on link between START and END."
  (let* ((text-file (expand-file-name (org-link-unescape path)))
         (preview-lines 10)
         (preview-content (org-link-beautify--preview-text-file text-file preview-lines)))
    (org-link-beautify--add-overlay-marker (1+ end) (+ end 2))
    (put-text-property (1+ end) (+ end 2) 'display (propertize preview-content))
    (put-text-property
     (1+ end) (+ end 2)
     'face '(:inherit nil :slant 'italic
                      :foreground nil
                      :background (color-darken-name (face-background 'default) 5)))))

(defun org-link-beautify--preview-video (path start end)
  "Preview video file PATH and display on link between START and END."
  (let* ((video (expand-file-name (org-link-unescape path)))
         (thumbnails-dir (pcase org-link-beautify-thumbnails-dir
                           ('source-path
                            (concat (file-name-directory video) ".thumbnails/"))
                           ('user-home
                            (expand-file-name "~/.cache/thumbnails/"))))
         (thumbnail (expand-file-name
                     (format "%s%s.jpg" thumbnails-dir (file-name-base video))))
         (thumbnail-size (or org-link-beautify-video-preview-size 512)))
    (unless (file-directory-p thumbnails-dir)
      (make-directory thumbnails-dir))
    (unless (file-exists-p thumbnail)
      (start-process
       "org-link-beautify--video-preview"
       " *org-link-beautify video-preview*"
       "ffmpegthumbnailer"
       "-f" "-i" video "-s" thumbnail-size
       "-o" thumbnail))
    (org-link-beautify--add-overlay-marker start end)
    (org-link-beautify--display-thumbnail thumbnail thumbnail-size start end)))

(defun org-link-beautify--return-icon (path type extension)
  "Return the corresponding icon for link PATH smartly based on TYPE, EXTENSION, etc."
  (pcase type
    ("file"
     (cond
      ((file-remote-p path) ; remote file
       (all-the-icons-faicon "server" :face 'org-warning))
      ((not (file-exists-p (expand-file-name path))) ; not exist file
       (all-the-icons-faicon "exclamation-triangle" :face 'org-warning))
      ((file-directory-p path) ; directory
       (all-the-icons-icon-for-dir
        "path"
        :face (org-link-beautify--warning path)
        :v-adjust 0))
      ;; MindMap files
      ((member (file-name-extension path) '("mm" "xmind"))
       (all-the-icons-fileicon "brain" :face '(:foreground "BlueViolet")))
      (t (all-the-icons-icon-for-file ; file
          (format ".%s" extension)
          :face (org-link-beautify--warning path)
          :v-adjust 0))))
    ("file+sys" (all-the-icons-faicon "link"))
    ("file+emacs" (all-the-icons-icon-for-mode 'emacs-lisp-mode))
    ("http" (all-the-icons-icon-for-url (concat "http:" path) :v-adjust -0.05))
    ("https" (all-the-icons-icon-for-url (concat "https:" path) :v-adjust -0.05))
    ("ftp" (all-the-icons-faicon "link"))
    ("eaf" (all-the-icons-faicon "linux" :v-adjust -0.05)) ; emacs-application-framework
    ("custom-id" (all-the-icons-faicon "hashtag"))
    ("coderef" (all-the-icons-faicon "code"))
    ("id" (all-the-icons-fileicon ""))
    ("attachment" (all-the-icons-faicon "puzzle-piece"))
    ("elisp" (all-the-icons-icon-for-mode 'emacs-lisp-mode :v-adjust -0.05))
    ("shell" (all-the-icons-icon-for-mode 'shell-mode))
    ("eww" (all-the-icons-icon-for-mode 'eww-mode))
    ("mu4e" (all-the-icons-faicon "envelope-square" :v-adjust -0.05))
    ("git" (all-the-icons-octicon "git-branch"))
    ("orgit" (all-the-icons-octicon "git-branch"))
    ("orgit-rev" (all-the-icons-octicon "git-commit"))
    ("orgit-log" (all-the-icons-icon-for-mode 'magit-log-mode))
    ("pdfview" (all-the-icons-icon-for-file ".pdf"))
    ("grep" (all-the-icons-icon-for-mode 'grep-mode))
    ("occur" (all-the-icons-icon-for-mode 'occur-mode))
    ("man" (all-the-icons-icon-for-mode 'Man-mode))
    ("info" (all-the-icons-icon-for-mode 'Info-mode))
    ("help" (all-the-icons-icon-for-mode 'Info-mode))
    ("rss" (all-the-icons-material "rss_feed"))
    ("elfeed" (all-the-icons-material "rss_feed"))
    ("telnet" (all-the-icons-faicon "compress"))
    ("wikipedia" (all-the-icons-faicon "wikipedia-w"))
    ("mailto" (all-the-icons-material "email" :v-adjust -0.05))
    ("irc" (all-the-icons-faicon "comment-o"))
    ("doi" (all-the-icons-fileicon "isabelle"))
    ("org-contact" (all-the-icons-material "account_box"))))

(defun org-link-beautify--display-icon (start end description icon)
  "Display ICON for link on START and END with DESCRIPTION."
  (put-text-property
   start end
   'display
   (propertize
    (concat
     (propertize "[" 'face '(:inherit nil :underline nil :foreground "orange"))
     (propertize description 'face '(:underline t :foreground "dark cyan"))
     (propertize "]" 'face '(:inherit nil :underline nil :foreground "orange"))
     (propertize "(" 'face '(:inherit nil :underline nil :foreground "orange"))
     (propertize icon 'face '(:inherit nil :underline nil :foreground "gray"))
     (propertize ")" 'face '(:inherit nil :underline nil :foreground "orange"))))))

(defun org-link-beautify (start end path bracket-p)
  "Display icon for the link type based on PATH from START to END."
  ;; (message
  ;;  (format "start: %s, end: %s, path: %s, bracket-p: %s" start end path bracket-p))
  (unless (memq major-mode org-link-beautify-exclude-modes)
    ;; detect whether link is normal, jump other links in special places.
    (when (eq (car (org-link-beautify--get-element start)) 'link)
      (save-match-data
        (let* ((link-element (org-link-beautify--get-element start))
               ;; (link-element-debug (message link-element))
               (raw-link (org-element-property :raw-link link-element))
               ;; (raw-link-debug (message raw-link))
               (type (org-element-property :type link-element))
               (extension (or (file-name-extension (org-link-unescape path)) "txt"))
               ;; (ext-debug (message extension))
               (description (or (and (org-element-property :contents-begin link-element) ; in raw link case, it's nil
                                     (buffer-substring-no-properties
                                      (org-element-property :contents-begin link-element)
                                      (org-element-property :contents-end link-element)))
                                ;; when description not exist, use raw link for raw link case.
                                raw-link))
               ;; (desc-debug (message description))
               (icon (org-link-beautify--return-icon path type extension)))
          (when bracket-p (ignore))
          (cond
           ;; video thumbnail preview
           ;; [[file:/path/to/video.mp4]]
           ((and (equal type "file")
                 (member extension org-link-beautify-video-preview-list)
                 org-link-beautify-video-preview)
            (org-link-beautify--preview-video path start end))
           ;; PDF file preview
           ;; [[file:/path/to/filename.pdf]]
           ;; [[pdfview:/path/to/filename.pdf::15]]
           ((and org-link-beautify-pdf-preview
                 (or (and (equal type "file") (string= extension "pdf"))
                     (equal type "pdfview")))
            (org-link-beautify--preview-pdf path start end))
           ;; EPUB file cover preview
           ((and org-link-beautify-epub-preview
                 (and (equal type "file") (string= extension "epub")))
            (org-link-beautify--preview-epub path start end))
           ;; text content preview
           ((and (equal type "file")
                 (member extension org-link-beautify-text-preview-list)
                 org-link-beautify-text-preview)
            (org-link-beautify--preview-text path start end))
           ;; general icons
           (t
            (org-link-beautify--add-overlay-marker start end)
            (org-link-beautify--display-icon start end description icon))))))))

(defun org-link-beautify-toggle-overlays ()
  "Toggle the display of `org-link-beautify'."
  (let ((point (point-min))
        (bmp (buffer-modified-p)))
    (while (setq point (next-single-property-change point 'display))
	  (when (and (get-text-property point 'display)
		         (eq (get-text-property point 'type) 'org-link-beautify))
	    (remove-text-properties
	     point (setq point (next-single-property-change point 'display))
	     '(display t))))
    (set-buffer-modified-p bmp))
  (org-restart-font-lock))

(defun org-link-beautify--add-more-icons-support ()
  "Add more icons for file types."
  (add-to-list 'all-the-icons-icon-alist '("\\.mm" all-the-icons-fileicon "brain" :face all-the-icons-lpink))
  (add-to-list 'all-the-icons-icon-alist '("\\.xmind" all-the-icons-fileicon "brain" :face all-the-icons-lpink)))

;;;###autoload
(defun org-link-beautify-enable ()
  "Enable `org-link-beautify'."
  (org-link-beautify--add-more-icons-support)
  (dolist (link-type (mapcar #'car org-link-parameters))
    (org-link-set-parameters link-type :activate-func #'org-link-beautify))
  (org-link-beautify-toggle-overlays))

;;;###autoload
(defun org-link-beautify-disable ()
  "Disable `org-link-beautify'."
  (dolist (link-type (mapcar #'car org-link-parameters))
    (org-link-set-parameters link-type :activate-func t))
  (org-link-beautify-toggle-overlays))

;;;###autoload
(define-minor-mode org-link-beautify-mode
  "A minor mode that beautify Org links with colors and icons."
  :init-value nil
  :lighter nil
  :group 'org-link-beautify
  :global t
  (if org-link-beautify-mode
      (org-link-beautify-enable)
    (org-link-beautify-disable)))



(provide 'org-link-beautify)

;;; org-link-beautify.el ends here
