;;; org-link-beautify.el --- Beautify Org Links -*- lexical-binding: t; -*-

;; Authors: stardiviner <numbchild@gmail.com>
;; Package-Requires: ((emacs "27.1") (all-the-icons "4.0.0"))
;; Package-Version: 20210222.227
;; Package-Commit: 4662b3a7b9244aa35aae2f469f87be4a44a6b1bb
;; Version: 1.2.1
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
  :safe #'symbolp
  :group 'org-link-beautify)

(defcustom org-link-beautify-video-preview-size 512
  "The video thumbnail image size."
  :type 'number
  :safe #'numberp
  :group 'org-link-beautify)

(defcustom org-link-beautify-video-preview-list
  '("avi" "rmvb" "ogg" "ogv" "mp4" "mkv" "mov" "m4v" "webm" "flv")
  "A list of video file types be supported with thumbnails."
  :type 'list
  :safe #'listp
  :group 'org-link-beautify)

(defcustom org-link-beautify-audio-preview (executable-find "audiowaveform")
  "Whether enable audio files wave form preview?"
  :type 'boolean
  :safe #'booleanp
  :group 'org-link-beautify)

(defcustom org-link-beautify-audio-preview-list '("mp3" "wav" "flac" "ogg" "dat")
  "A list of audio file types be supported generating audio wave form image."
  :type 'list
  :safe #'listp
  :group 'org-link-beautify)

(defcustom org-link-beautify-audio-preview-size 150
  "The audio wave form image size."
  :type 'number
  :safe #'numberp
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

(defcustom org-link-beautify-epub-preview-size nil
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

(defun org-link-beautify--ensure-thumbnails-dir (thumbnails-dir)
  "Ensure THUMBNAILS-DIR exist, if not ,create it."
  (unless (file-directory-p thumbnails-dir)
    (make-directory thumbnails-dir)))

(defun org-link-beautify--display-thumbnail (thumbnail thumbnail-size start end)
  "Display THUMBNAIL between START and END in size of THUMBNAIL-SIZE only when it exist."
  (when (file-exists-p thumbnail)
    (put-text-property
     start end
     'display (create-image thumbnail nil nil :ascent 'center :max-height thumbnail-size))
    ;; Support mouse left click on image to open link.
    (make-local-variable 'image-map)
    (define-key image-map (kbd "<mouse-1>") 'org-open-at-point)))

(defun org-link-beautify--preview-pdf (path start end)
  "Preview PDF file PATH and display on link between START and END."
  (if (string-match "\\(.*?\\)\\(?:::\\(.*\\)\\)?\\'" path)
      (let* ((file-path (match-string 1 path))
             ;; DEBUG: (_ (lambda (message "--> HERE")))
             (pdf-page-number (if (match-string 2 path)
                                  (string-to-number (match-string 2 path))
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
        (org-link-beautify--ensure-thumbnails-dir thumbnails-dir)
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
        (org-link-beautify--add-keymap start end)
        ;; display thumbnail only when it exist.
        (when (file-exists-p thumbnail)
          (org-link-beautify--display-thumbnail thumbnail thumbnail-size start end)))))

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
             (thumbnail-size org-link-beautify-epub-preview-size))
        (org-link-beautify--ensure-thumbnails-dir thumbnails-dir)
        (unless (file-exists-p thumbnail)
          (start-process
           "org-link-beautify--epub-preview"
           ;; DEBUG: check out this output buffer
           " *org-link-beautify epub-preview*"
           "gnome-epub-thumbnailer"
           epub-file thumbnail
           ;; (if org-link-beautify-epub-preview-size
           ;;     "--size")
           ;; (if org-link-beautify-epub-preview-size
           ;;     (number-to-string thumbnail-size))
           ))
        (org-link-beautify--add-overlay-marker start end)
        (org-link-beautify--add-keymap start end)
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
    (org-link-beautify--add-keymap (1+ end) (+ end 2))
    (put-text-property (1+ end) (+ end 2) 'display (propertize preview-content))
    (put-text-property
     (1+ end) (+ end 2)
     'face '(:inherit nil :slant 'italic
                      :foreground nil
                      :background (color-darken-name (face-background 'default) 5)))))

(defun org-link-beautify--preview-video (path start end)
  "Preview video file PATH and display on link between START and END."
  (let* ((video-file (expand-file-name (org-link-unescape path)))
         (thumbnails-dir (pcase org-link-beautify-thumbnails-dir
                           ('source-path
                            (concat (file-name-directory video-file) ".thumbnails/"))
                           ('user-home
                            (expand-file-name "~/.cache/thumbnails/"))))
         (thumbnail (expand-file-name
                     (format "%s%s.jpg" thumbnails-dir (file-name-base video-file))))
         (thumbnail-size (or org-link-beautify-video-preview-size 512)))
    (org-link-beautify--ensure-thumbnails-dir thumbnails-dir)
    (unless (file-exists-p thumbnail)
      (start-process
       "org-link-beautify--video-preview"
       " *org-link-beautify video-preview*"
       "ffmpegthumbnailer"
       "-f" "-i" video-file
       "-s" (number-to-string thumbnail-size)
       "-o" thumbnail))
    (org-link-beautify--add-overlay-marker start end)
    (org-link-beautify--add-keymap start end)
    (org-link-beautify--display-thumbnail thumbnail thumbnail-size start end)))

(defun org-link-beautify--preview-audio (path start end)
  "Preview audio file PATH and display wave form image on link between START and END."
  (let* ((audio-file (expand-file-name (org-link-unescape path)))
         (thumbnails-dir (pcase org-link-beautify-thumbnails-dir
                           ('source-path
                            (concat (file-name-directory audio-file) ".thumbnails/"))
                           ('user-home
                            (expand-file-name "~/.cache/thumbnails/"))))
         (thumbnail (expand-file-name
                     (format "%s%s.png" thumbnails-dir (file-name-base audio-file))))
         (thumbnail-size (or org-link-beautify-audio-preview-size 200)))
    (org-link-beautify--ensure-thumbnails-dir thumbnails-dir)
    (unless (file-exists-p thumbnail)
      ;; DEBUG:
      ;; (message "%s\n%s\n" audio-file thumbnail)
      (start-process
       "org-link-beautify--audio-preview"
       " *org-link-beautify audio-preview*" ; DEBUG: check out output buffer
       "audiowaveform"
       "-i" audio-file
       "-o" thumbnail))
    (org-link-beautify--add-overlay-marker start end)
    (org-link-beautify--add-keymap start end)
    (org-link-beautify--display-thumbnail thumbnail thumbnail-size start end)))

(defun org-link-beautify--return-icon (path type extension)
  "Return the corresponding icon for link PATH smartly based on TYPE, EXTENSION, etc."
  (pcase type
    ("file"
     (cond
      ((file-remote-p path)             ; remote file
       (all-the-icons-material "dns" :face 'org-warning))
      ((not (file-exists-p (expand-file-name path))) ; not exist file
       (all-the-icons-material "priority_high" :face 'org-warning))
      ((file-directory-p path)          ; directory
       (all-the-icons-icon-for-dir
        "path"
        :face (org-link-beautify--warning path)
        :v-adjust 0))
      ;; MindMap files
      ((member (file-name-extension path) '("mm" "xmind"))
       (all-the-icons-fileicon "brain" :face '(:foreground "BlueViolet")))
      (t (all-the-icons-icon-for-file   ; file
          (format ".%s" extension)
          :face (org-link-beautify--warning path)
          :v-adjust 0))))
    ("file+sys" (all-the-icons-material "link"))
    ("file+emacs" (all-the-icons-icon-for-mode 'emacs-lisp-mode))
    ("http" (all-the-icons-icon-for-url (concat "http:" path) :v-adjust -0.05))
    ("https" (all-the-icons-icon-for-url (concat "https:" path) :v-adjust -0.05))
    ("ftp" (all-the-icons-material "link"))
    ("telnet" (all-the-icons-material "settings_ethernet"))
    ("eaf" (all-the-icons-material "apps" :v-adjust -0.05)) ; emacs-application-framework
    ("custom-id" (all-the-icons-material "location_searching"))
    ("coderef" (all-the-icons-material "code"))
    ("id" (all-the-icons-material "link"))
    ("attachment" (all-the-icons-material "attachment"))
    ("elisp" (all-the-icons-icon-for-mode 'emacs-lisp-mode :v-adjust -0.05))
    ("eshell" (all-the-icons-icon-for-mode 'eshell-mode))
    ("shell" (all-the-icons-icon-for-mode 'shell-mode))
    ("eww" (all-the-icons-icon-for-mode 'eww-mode))
    ("mu4e" (all-the-icons-material "mail_outline"))
    ("git" (all-the-icons-octicon "git-branch"))
    ("orgit" (all-the-icons-octicon "git-branch"))
    ("orgit-rev" (all-the-icons-octicon "git-commit"))
    ("orgit-log" (all-the-icons-icon-for-mode 'magit-log-mode))
    ("pdfview" (all-the-icons-icon-for-file ".pdf"))
    ("grep" (all-the-icons-icon-for-mode 'grep-mode))
    ("occur" (all-the-icons-icon-for-mode 'occur-mode))
    ("man" (all-the-icons-material "description"))
    ("info" (all-the-icons-material "description"))
    ("help" (all-the-icons-material "description"))
    ("rss" (all-the-icons-material "rss_feed"))
    ("elfeed" (all-the-icons-material "rss_feed"))
    ("wikipedia" (all-the-icons-faicon "wikipedia-w"))
    ("mailto" (all-the-icons-material "contact_mail" :v-adjust -0.05))
    ("irc" (all-the-icons-material "comment"))
    ("doi" (all-the-icons-material "link"))
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

(defun org-link-beautify-display (start end path bracket-p)
  "Display icon for the link type based on PATH from START to END."
  ;; DEBUG:
  ;; (message
  ;;  (format "start: %s, end: %s, path: %s, bracket-p: %s" start end path bracket-p))
  ;; detect whether link is normal, jump other links in special places.
  (when (eq (car (org-link-beautify--get-element start)) 'link)
    (save-match-data
      (let* ((link-element (org-link-beautify--get-element start))
             ;; DEBUG: (link-element-debug (message link-element))
             (raw-link (org-element-property :raw-link link-element))
             ;; DEBUG:
             ;; (raw-link-debug (message raw-link))
             (type (org-element-property :type link-element))
             ;; DEBUG:
             ;; (type-debug (message type))
             (extension (or (file-name-extension (org-link-unescape path)) "txt"))
             ;; DEBUG: (ext-debug (message extension))
             (description (or (and (org-element-property :contents-begin link-element) ; in raw link case, it's nil
                                   (buffer-substring-no-properties
                                    (org-element-property :contents-begin link-element)
                                    (org-element-property :contents-end link-element)))
                              ;; when description not exist, use raw link for raw link case.
                              raw-link))
             ;; DEBUG: (desc-debug (message description))
             (icon (org-link-beautify--return-icon path type extension)))
        (when bracket-p (ignore))
        (cond
         ;; video thumbnail preview
         ;; [[file:/path/to/video.mp4]]
         ((and (equal type "file")
               (member extension org-link-beautify-video-preview-list)
               org-link-beautify-video-preview)
          (org-link-beautify--preview-video path start end))
         ;; audio wave form image preview
         ;; [[file:/path/to/audio.mp3]]
         ((and (equal type "file")
               (member extension org-link-beautify-audio-preview-list)
               org-link-beautify-audio-preview)
          (org-link-beautify--preview-audio path start end))
         ;; PDF file preview
         ;; [[file:/path/to/filename.pdf]]
         ;; [[pdfview:/path/to/filename.pdf::15]]
         ((and org-link-beautify-pdf-preview
               (or (and (equal type "file") (string= extension "pdf"))
                   (equal type "pdfview")
                   (equal type "docview")
                   (equal type "eaf")))
          (org-link-beautify--preview-pdf
           (if (equal type "eaf")
               (replace-regexp-in-string "pdfviewer::" "" path)
             path)
           start end))
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
          ;; DEBUG:
          ;; (message "-->> icon displayed")
          (org-link-beautify--add-overlay-marker start end)
          (org-link-beautify--add-keymap start end)
          (org-link-beautify--display-icon start end description icon)))))))

;;; hook on headline expand
(defun org-link-beautify-headline-cycle (&optional state)
  "Function to be executed on `org-cycle-hook' STATE."
  (pcase state
    ('subtree (ignore))
    ('children (ignore))
    ('folded
     (org-link-beautify-clear state))
    (_ (ignore)))
  ;; PERFORMANCE: benchmark this.
  (org-restart-font-lock))

;;; toggle org-link-beautify text-properties
(defun org-link-beautify--clear-text-properties (&optional begin end)
  "Clear all org-link-beautify text-properties between BEGIN and END."
  (let ((point (or begin (point-min)))
        (bmp (buffer-modified-p)))
    (while (setq point (next-single-property-change point 'display))
      (when (and (< point (or end (point-max)))
                 (get-text-property point 'display)
                 (eq (get-text-property point 'type) 'org-link-beautify))
        (remove-text-properties
	     point (setq point (next-single-property-change point 'display))
	     '(display t))))
    (set-buffer-modified-p bmp)))

(defun org-link-beautify-clear (&optional state)
  "Clear the text-properties of `org-link-beautify' globally.
Or clear org-link-beautify if headline STATE is folded."
  (if (eq state 'folded)
      ;; clear in current folded headline
      (save-excursion
        (save-restriction
          (org-narrow-to-subtree)
          (let* ((begin (point-min))
                 (end (save-excursion (org-next-visible-heading 1) (point))))
            (org-link-beautify--clear-text-properties begin end))))
    ;; clear in whole buffer
    (org-link-beautify--clear-text-properties))
  (org-restart-font-lock))

;;; add more missing icons to `all-the-icons'.
(defun org-link-beautify--add-more-icons-support ()
  "Add more icons for file types."
  (add-to-list 'all-the-icons-icon-alist
               '("\\.mm" all-the-icons-fileicon "brain" :face all-the-icons-lpink))
  (add-to-list 'all-the-icons-icon-alist
               '("\\.xmind" all-the-icons-fileicon "brain" :face all-the-icons-lpink)))

(defvar org-link-beautify-keymap (make-sparse-keymap))

(defun org-link-beautify--add-keymap (start end)
  "Add keymap on link text-property. between START and END."
  (put-text-property start end 'keymap org-link-beautify-keymap))

(define-key org-link-beautify-keymap (kbd "RET") 'org-open-at-point)
(define-key org-link-beautify-keymap [mouse-1] 'org-open-at-point)
(define-key org-link-beautify-keymap (kbd "<mouse-1>") 'org-open-at-point)


;;;###autoload
(defun org-link-beautify-enable ()
  "Enable `org-link-beautify'."
  (when (display-graphic-p)
    (org-link-beautify--add-more-icons-support)
    (dolist (link-type (mapcar #'car org-link-parameters))
      (org-link-set-parameters link-type :activate-func #'org-link-beautify-display))
    (add-hook 'org-cycle-hook #'org-link-beautify-headline-cycle)
    (org-restart-font-lock)))

;;;###autoload
(defun org-link-beautify-disable ()
  "Disable `org-link-beautify'."
  (dolist (link-type (mapcar #'car org-link-parameters))
    (org-link-set-parameters link-type :activate-func t))
  (remove-hook 'org-cycle-hook #'org-link-beautify-headline-cycle)
  (org-link-beautify-clear))

;;;###autoload
(define-minor-mode org-link-beautify-mode
  "A minor mode that beautify Org links with colors and icons."
  :group 'org-link-beautify
  :global t
  :init-value nil
  :lighter nil
  (if org-link-beautify-mode
      (org-link-beautify-enable)
    (org-link-beautify-disable)))



(provide 'org-link-beautify)

;;; org-link-beautify.el ends here
