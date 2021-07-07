;;; image-archive.el --- Image thumbnails in archive file with non-blocking

;; Author: Masahiro Hayashi <mhayashi1120@gmail.com>
;; Keywords: multimedia
;; Package-Version: 20150621.132
;; Package-Commit: 8d29535bd832329ffeeac780aae7aa8919af1175
;; URL: https://github.com/mhayashi1120/Emacs-image-archive
;; Emacs: GNU Emacs 24 or later
;; Package-Requires: ((emacs "24") (cl-lib "0.5"))
;; Version: 0.1.1

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Show thumbnails in a `archive-mode' buffer like `image-dired'. So
;; this module depend on `image-dired' to imitate UI.  Some of
;; customize variables are imported.  But not like image-dired,
;; non-blocking thumbnail process like `image-dired+'

;; ## Install:

;; Please install the ImageMagick before installing this elisp.

;; Put this file into load-path'ed directory, and byte compile it if
;; desired. And put the following expression into your ~/.emacs.
;;
;;     (autoload 'image-archive "image-archive" nil t)
;;     (autoload 'image-archive-marked-files "image-archive" nil t)
;;     (autoload 'image-archive-auto-thumbnails "image-archive")

;; ## Usage:

;; * Followings are tested result (`-` is not yet tested) .
;;
;; | zip |  7z | lha | arc | zoo |
;; |-----|-----|-----|-----|-----|
;; |  o  |  o  |  o  |  -  |  -  |
;;
;;   GNU bash, version 4.2.37(1)-release (x86_64-pc-linux-gnu)

;; * Type following in archive (e.g. zip) file which contains
;;   image files.
;;
;;     M-x image-archive

;; * Automatically execute `image-archive' when open an archive file.
;;
;;     (add-hook 'archive-mode-hook 'image-archive-auto-thumbnails)

;;; TODO:
;;  * log of sequential thumbnail is failed

;;; Code:

(require 'cl-lib)
(require 'image-dired)
(require 'arc-mode)

(defgroup image-archive ()
  "Image thumbnails in archive file"
  :group 'multimedia)

(defcustom image-archive-dir
  (locate-user-emacs-file "image-archive")
  "Directory where thumbnail images are stored."
  :group 'image-archive
  :type 'directory)

(defun image-archive--find-arc-subtype (file)
  (with-temp-buffer
    (let ((coding-system-for-read 'binary))
      (insert-file-contents file nil 0 1024))
    (setq buffer-file-name file)
    (prog1
        (archive-find-type)
      (set-buffer-modified-p nil))))

(defun image-archive--thumbnail-file (archive name)
  (let* ((arcname (expand-file-name archive))
         (md5-hash (md5 arcname))
         ;; This is similar to `use-image-dired-dir'
         ;; But prefixed by md5-hash which is grouped archive filename
         (fn (format "%s_%s.thumb.%s"
                     md5-hash
                     (file-name-base name)
                     (file-name-extension name))))
    (expand-file-name fn image-archive-dir)))

(defun image-archive--insert-image (file-or-data &optional relief margin)
  "Insert image FILE-OR-DATA of image TYPE, using RELIEF and MARGIN, at point."
  (let* ((type-from-data (image-type-from-data file-or-data))
         (i (create-image file-or-data type-from-data type-from-data
                          :relief (or relief 0)
                          :margin (or margin 0))))
    (insert-image i)))

(defun image-archive--insert-thumbnail (thumb archive name)
  "Insert THUMB image at ARCHIVE/NAME with adding some text properties."
  (let (beg end)
    (setq beg (point))
    (image-archive--insert-image
     thumb image-dired-thumb-relief image-dired-thumb-margin)
    (setq end (point))
    (add-text-properties
     beg end
     (list 'image-archive-thumbnail t
           'image-archive-archive-name archive
           'image-archive-name name
           'mouse-face 'highlight))))

(defvar image-archive--display-image-buffer "*image-archive-image*"
  "Where larger versions of the images are display.")

;;;
;;; External process
;;;

(defun image-archive--generate-process-buffer ()
  (let ((buf (generate-new-buffer " *image-archive process* ")))
    (with-current-buffer buf
      (set-buffer-multibyte nil))
    buf))

(defun image-archive--construct-extract-shell (subtype archive name)
  (let* ((symname (concat "archive-" (symbol-name subtype) "-extract"))
         (sym (intern-soft symname)))
    (unless (boundp sym)
      (error "Not a valid `%s'" symname))
    (let* ((arc-command (symbol-value sym))
           (args (append arc-command
                         (list (shell-quote-argument archive)
                               (shell-quote-argument name))))
           (real-args (image-archive--hack-command args))
           (command (mapconcat 'identity real-args " ")))
      command)))

;;FIXME lha program output header line
(defun image-archive--hack-command (args)
  (cond
   ((equal (car args) "lha")
    ;; Do not escape "|"
    (append args (list "|" "tail" "-n" "+4")))
   (t
    args)))

(defun image-archive--construct-convert-shell (thumbnail-file)
  (let* ((width (number-to-string image-dired-thumb-width))
         (height (number-to-string image-dired-thumb-height))
         ;;FIXME this package doesn't use modif time although
         (modif-time (format "%.0f" (float-time)))
         (thumbnail-nq8-file (replace-regexp-in-string ".png\\'" "-nq8.png"
                                                       thumbnail-file))
         (command
          (format-spec
           image-dired-cmd-create-thumbnail-options
           (list
            (cons ?p image-dired-cmd-create-thumbnail-program)
            (cons ?w width)
            (cons ?h height)
            (cons ?m modif-time)
            (cons ?f "-")
            (cons ?q thumbnail-nq8-file)
            (cons ?t thumbnail-file)))))
    command))

(defun image-archive--construct-resize-shell ()
  (let* ((width (frame-pixel-width))
         (height (image-archive--original-image-pixel-height))
         (command
          (format-spec
           image-dired-cmd-create-temp-image-options
           (list
            (cons ?p image-dired-cmd-create-temp-image-program)
            (cons ?w width)
            (cons ?h height)
            (cons ?f "-")
            (cons ?t "-")))))
    command))

(defun image-archive--invoke-shell (name buffer shell)
  (start-process name buffer shell-file-name
                 shell-command-switch shell))

(defun image-archive--invoke-thumb-process (buf subtype archive name thumb)
  (let* ((extractor (image-archive--construct-extract-shell subtype archive name))
         (converter (image-archive--construct-convert-shell thumb))
         (shell (format "%s 2>/dev/null | %s" extractor converter))
         (proc (image-archive--invoke-shell "image-archive thumb" buf  shell)))
    proc))

(defun image-archive--create-thumb-process-chain (buf subtype archive names ui-buffer)
  (let* ((name (car names))
         (thumb (image-archive--thumbnail-file archive name))
         (proc (if (file-newer-than-file-p archive thumb)
                   (image-archive--invoke-thumb-process buf subtype archive name thumb)
                 ;; !! async trick !!
                 (image-archive--invoke-shell "image-archive dummy" buf ""))))
    (set-process-sentinel proc 'image-archive--thumb-process-sentinel)
    (process-put proc 'image-archive-thumb-file thumb)
    (process-put proc 'image-archive-archive-subtype subtype)
    (process-put proc 'image-archive-archive-file archive)
    (process-put proc 'image-archive-name name)
    (process-put proc 'image-archive-rest-names (cdr names))
    (process-put proc 'image-archive-thumb-buffer ui-buffer)
    proc))

(defun image-archive--thumb-process-sentinel (proc event)
  (unless (eq (process-status proc) 'run)
    (let ((subtype (process-get proc 'image-archive-archive-subtype))
          (archive (process-get proc 'image-archive-archive-file))
          (name (process-get proc 'image-archive-name))
          (names (process-get proc 'image-archive-rest-names))
          (ui-buf (process-get proc 'image-archive-thumb-buffer))
          (buf (process-buffer proc))
          (thumb (process-get proc 'image-archive-thumb-file)))
      (when (and (eq (process-status proc) 'exit)
                 (= (process-exit-status proc) 0))
        (when (buffer-live-p ui-buf)
          (with-current-buffer ui-buf
            (let ((inhibit-read-only t))
              (save-excursion
                (goto-char (point-max))
                (unless (bobp)
                  ;; insert space to split thumbnails text-property
                  (insert " "))
                (image-archive--insert-thumbnail thumb archive name))))))
      (cond
       ((and (not (process-get proc 'image-archive-force-stop))
             (buffer-live-p ui-buf)
             names)
        (image-archive--create-thumb-process-chain
         buf subtype archive names ui-buf))
       ((and buf (buffer-live-p buf))
        (kill-buffer buf))))))

;;;
;;; UI
;;;

(defun image-archive--generate-thumb-buffer (archive)
  (generate-new-buffer
   (format "*image-archive<%s>*"
           (file-name-nondirectory archive))))

(defun image-archive--original-image-pixel-height ()
  (- (frame-pixel-height)
     image-dired-thumb-height
     (* (or
         (and (fboundp 'window-mode-line-height) (window-mode-line-height))
         ;; mode line is just a simple line
         (frame-char-height))
        ;; multiply 2: split window have 2 modeline
        2)
     (frame-char-height)))

(defun image-archive--display-image (archive name &optional original-size)
  "Display image ARCHIVE/NAME in image buffer.

If optional argument ORIGINAL-SIZE is non-nil, display image in its
original size."

  (with-current-buffer (get-buffer-create image-archive--display-image-buffer)
    (setq mode-line-process
          (list
           (propertize "preparing..." 'face 'warning))))
  (let* ((subtype (image-archive--find-arc-subtype archive))
         (extractor (image-archive--construct-extract-shell subtype archive name))
         (resizer (if original-size "cat" (image-archive--construct-resize-shell)))
         ;; some of commands have stderr
         (shell (format "%s 2>/dev/null | %s" extractor resizer))
         (buf (image-archive--generate-process-buffer))
         (proc (image-archive--invoke-shell "image-archive original" buf shell)))
    (set-process-sentinel proc 'image-archive--original-image-sentinel)
    (process-put proc 'image-archive-original-archive archive)
    (process-put proc 'image-archive-original-name name)
    proc))

(defun image-archive--original-image-sentinel (p e)
  (cond
   ((not (eq (process-status p) 'exit)))
   ((= (process-exit-status p) 0)
    (let ((image-data (with-current-buffer (process-buffer p)
                        (buffer-string))))
      (with-current-buffer (get-buffer-create image-archive--display-image-buffer)
        (image-archive-display-image-mode)
        (let ((inhibit-read-only t))
          (erase-buffer)
          ;; TODO what is this mean?
          ;; (clear-image-cache)
          (image-archive--insert-image image-data))
        (let* ((archive-file (process-get p 'image-archive-original-archive))
               (name (process-get p 'image-archive-original-name))
               (archive (file-name-nondirectory archive-file)))
          (setq mode-line-process
                (list
                 (propertize (format "%s<%s>" name archive)
                             'face 'mode-line-emphasis)))))))
   (t
    (with-current-buffer (get-buffer-create image-archive--display-image-buffer)
      (setq mode-line-process
            (list
             (propertize "exit" 'face 'error)))
      (message "process exited abnormally (code %d)" (process-exit-status p)))))
  ;; cleanup buffer
  (unless (eq (process-status p) 'run)
    (let ((buf (process-buffer p)))
      (when (buffer-live-p buf)
        (kill-buffer buf)))))

;;;
;;; utility
;;;

(defun image-archive--files-to-names (entries)
  (cl-loop for f in entries
           if (vectorp f)
           collect (aref f 0)))

(defcustom image-archive-guess-archive-threshold 0.9
  "Threshold to guess the current archive buffer has just Images.
Valid value ranges are 0.0 to 1.0 .
`t' means certainly regard as all of thems are Images.
`nil' is never."
  :group 'image-archive
  :type '(choice
          float
          (const t)
          (const nil)))

(defun image-archive--guess-image-archive ()
  (cond
   ((eq image-archive-guess-archive-threshold t) t)
   ((floatp image-archive-guess-archive-threshold)
    (cl-loop with files = (append archive-files nil)
             with extensions = image-file-name-extensions
             for name in (image-archive--files-to-names files)
             count 1 into all-count
             if (and name (member-ignore-case (file-name-extension name) extensions))
             count 1 into image-count
             finally return
             (cond
              ((null files) nil)
              ((> (/ (ftruncate image-count) all-count)
                  image-archive-guess-archive-threshold)
               t)
              (t nil))))
   (t nil)))

;;;
;;; mode
;;;

;;
;; Display thumbnails
;;

(defvar image-archive-thumbnail-mode-map nil)

(unless image-archive-thumbnail-mode-map
  (let ((map (make-sparse-keymap)))

    (define-key map [right] 'image-archive-forward-image)
    (define-key map [left] 'image-archive-backward-image)
    (define-key map [up] 'image-archive-previous-line)
    (define-key map [down] 'image-archive-next-line)

    (define-key map "\C-f" 'image-archive-forward-image)
    (define-key map "\C-b" 'image-archive-backward-image)
    (define-key map "\C-p" 'image-archive-previous-line)
    (define-key map "\C-n" 'image-archive-next-line)

    (define-key map "p" 'image-archive-previous-line)
    (define-key map "n" 'image-archive-next-line)

    (define-key map " " 'image-archive-forward-image)

    (define-key map "g" 'revert-buffer)

    (define-key map "\C-m" 'image-archive-thumbnail-display-original-image)

    (setq image-archive-thumbnail-mode-map map)))

(defvar-local image-archive-thumbnail--active-display-process nil)
(defvar-local image-archive-thumbnail--process-buffer nil)

(defun image-archive-thumbnail--unactivate-process ()
  (when (and (bufferp image-archive-thumbnail--process-buffer)
             (buffer-live-p image-archive-thumbnail--process-buffer))
    (let ((proc (get-buffer-process image-archive-thumbnail--process-buffer)))
      (delete-process proc)
      (process-put proc 'image-archive-force-stop t))))

(defun image-archive-thumbnail--original-files ()
  (let ((res '()))
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (cl-destructuring-bind (archive name)
            (image-archive-thumbnail--original-file-name)
          (when (and archive name)
            (setq res (cons (list archive name) res))))

        (forward-char 1)))
    (nreverse res)))

(defun image-archive-thumbnail--display-original-image-maybe ()
  (when (get-buffer-window image-archive--display-image-buffer)
    (image-archive-thumbnail--ensure-unactive-process)
    (cl-destructuring-bind (archive name)
        (image-archive-thumbnail--original-file-name)
      (when (and archive name)
        (setq image-archive-thumbnail--active-display-process
              (image-archive--display-image archive name))))))

(defun image-archive-thumbnail--ensure-unactive-process ()
  (when image-archive-thumbnail--active-display-process
    (delete-process image-archive-thumbnail--active-display-process)
    (setq image-archive-thumbnail--active-display-process nil)))

(defun image-archive-thumbnail--image-at-point-p ()
  "Return true if there is an image-dired thumbnail at point."
  (get-text-property (point) 'image-archive-thumbnail))

(defun image-archive-thumbnail--original-file-name ()
  (list (get-text-property (point) 'image-archive-archive-name)
        (get-text-property (point) 'image-archive-name)))

(defun image-archive-thumbnail--move-image (arg)
  (let ((direction (if (< arg 0) -1 1))
        (count (abs arg))
        (terminated (if (< arg 0) 'bobp 'eobp)))
    (while (and (not (funcall terminated))
                (< 0 count))
      (forward-char direction)
      (while (not (image-archive-thumbnail--image-at-point-p))
        (forward-char direction))
      (setq count (1- count)))))

(defun image-archive--line-move (arg)
  (let ((line-move-visual t))
    (line-move arg))
  (unless (image-archive-thumbnail--image-at-point-p)
    (image-archive-thumbnail--move-image 1)))

(defun image-archive-previous-line (&optional arg)
  "Move to previous visible line thumbnail."
  (interactive "p")
  (image-archive--line-move (- arg))
  (image-archive-thumbnail--display-original-image-maybe))

(defun image-archive-next-line (&optional arg)
  "Move to next visible line thumbnail."
  (interactive "p")
  (image-archive--line-move arg)
  (image-archive-thumbnail--display-original-image-maybe))

(defun image-archive-forward-image (&optional arg)
  "Forward thumbnail."
  (interactive "p")
  (image-archive-thumbnail--move-image arg)
  (image-archive-thumbnail--display-original-image-maybe))

(defun image-archive-backward-image (&optional arg)
  "Backward thumbnail."
  (interactive "p")
  (image-archive-thumbnail--move-image (- arg))
  (image-archive-thumbnail--display-original-image-maybe))

(defun image-archive-thumbnail-revert-buffer (&optional ignore-auto noconfirm)
  (image-archive-thumbnail--unactivate-process)
  (let ((res (image-archive-thumbnail--original-files)))
    (cl-loop for (a n) in res
             do (let ((thumb (image-archive--thumbnail-file a n)))
                  (when (file-exists-p thumb)
                    (delete-file thumb))))
    ;;FIXME now image-archive handle just a archive.
    (let* ((archive (caar res))
           (subtype (image-archive--find-arc-subtype archive)))
      (image-archive--show-thumbnails
       subtype archive (mapcar 'cadr res) (current-buffer)))))

(defun image-archive-thumbnail-display-original-image (&optional arg)
  "Display current thumbnail's original image in display buffer."
  (interactive "P")
  (cl-destructuring-bind (archive name)
      (image-archive-thumbnail--original-file-name)
    (cond
     ((or (null archive) (null name))
      (message "No thumbnail at point"))
     (t
      (let ((buffer (get-buffer-create image-archive--display-image-buffer)))
        (unless (get-buffer-window buffer)
          (let* ((original-h (truncate
                              (*
                               (/ (image-archive--original-image-pixel-height)
                                  (frame-char-height))
                               ;; keep a little margin
                               1.05)))
                 (t-win (condition-case err
                            (split-window nil original-h 'above)
                          (error
                           ;; clear all windows when window too small
                           (delete-other-windows)
                           ;; try one more time.
                           (split-window nil original-h 'above))))
                 (i-win (selected-window)))
            (set-window-buffer i-win buffer)
            (select-window t-win))))
      (image-archive-thumbnail--ensure-unactive-process)
      (setq image-archive-thumbnail--active-display-process
            (image-archive--display-image archive name arg))))))

(define-derived-mode image-archive-thumbnail-mode
  fundamental-mode "image-archive-thumbnail"
  "Browse thumbnail images."
  (use-local-map image-archive-thumbnail-mode-map)
  (setq buffer-read-only t)
  (setq truncate-lines nil)
  (set (make-local-variable 'revert-buffer-function)
       'image-archive-thumbnail-revert-buffer))

;;
;; Display original image
;;

(defvar image-archive-display-image-mode-map nil)
(unless image-archive-display-image-mode-map
  (let ((map (make-sparse-keymap)))
    (setq image-archive-display-image-mode-map map)))

(define-derived-mode image-archive-display-image-mode
  fundamental-mode "image-archive-image-display"
  "Mode for displaying original image in archive file.
Resized or in full-size."
  (use-local-map image-archive-display-image-mode-map)
  (setq mode-name nil)
  (setq buffer-read-only t))

;;;
;;; Entry point
;;;

(defun image-archive--show-thumbnails (subtype archive names &optional ui-buffer)
  (let ((proc-buf (image-archive--generate-process-buffer))
        (ui-buf (or ui-buffer (image-archive--generate-thumb-buffer archive))))
    (with-current-buffer ui-buf
      (let ((inhibit-read-only t))
        (erase-buffer))
      (image-archive-thumbnail-mode)
      (setq image-archive-thumbnail--process-buffer proc-buf))
    (image-archive--create-thumb-process-chain
     proc-buf subtype archive names ui-buf)
    (switch-to-buffer ui-buf)))

;;;###autoload
(defun image-archive ()
  "Show image thumbnails regard as current `archive-mode' buffer only have
 images."
  (interactive)
  (unless (derived-mode-p 'archive-mode)
    (error "Not in `archive-mode'"))
  (image-archive--show-thumbnails
   archive-subtype buffer-file-name
   (image-archive--files-to-names (append archive-files nil))))

;;;###autoload
(defun image-archive-marked-files ()
  "Show image thumbnails on the marked files."
  (interactive)
  (unless (derived-mode-p 'archive-mode)
    (error "Not in `archive-mode'"))
  (image-archive--show-thumbnails
   archive-subtype buffer-file-name
   (image-archive--files-to-names (archive-get-marked ?*))))

(defun image-archive--buffer-for-auto (buffer)
  (with-current-buffer buffer
    (when (image-archive--guess-image-archive)
      (image-archive))))

;;;###autoload
(defun image-archive-auto-thumbnails ()
  ;; run timer after switch archive major-mode is done.
  (run-with-timer 0 nil 'image-archive--buffer-for-auto (current-buffer)))

(provide 'image-archive)

;;; image-archive.el ends here
