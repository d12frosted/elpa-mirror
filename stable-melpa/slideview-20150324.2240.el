;;; slideview.el --- File slideshow

;; Author: Masahiro Hayashi <mhayashi1120@gmail.com>
;; URL: https://github.com/mhayashi1120/Emacs-slideview
;; Package-Version: 20150324.2240
;; Package-Commit: b6d170bda139aedf81b47dc55cbd1a3af512fb4c
;; Keywords: files
;; Emacs: GNU Emacs 22 or later
;; Version: 0.7.3
;; Package-Requires: ((cl-lib "0.3"))

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

;; View sequential files with simple operation.

;; ## Install:

;;     (require 'slideview)

;; Start slideview-mode automatically when open a image file.

;;     (add-hook 'image-mode-hook 'slideview-mode)

;; ## Usage:

;; * Space
;;   Move forward slideview

;; * Backspace
;;   Move backward slideview

;; * `C-c C-i` / `C-c C-M-i` (Work only in `image-mode')
;;   Concat current image with next/previous image.
;;   To indicate the viewing file direction, please use
;;   `slideview-modify-setting' or `slideview-add-matched-file'

;; * Slideview settings for file.zip
;;
;;     (slideview-modify-setting "/path/to/file.zip"
;;                               :margin 30 :direction 'right)

;;; TODO:
;; * when directory contains numbered file
;;   1.jpg 10.jpg 2.jpg
;; * can include subdirectory
;; * look ahead (more sophisticated)

;;; Code:

(require 'cl-lib)
(require 'view)
(require 'eieio)

(defgroup slideview ()
  "Sequential viewing files."
  :group 'applications)

(defcustom slideview-slideshow-interval 5.0
  "*Interval seconds to next file when slideshow is activated."
  :group 'slideview
  :type 'float)

(defcustom slideview-move-file-hook nil
  "Hooks run after step to next/previous file"
  :group 'slideview
  :type 'hook)

(defcustom slideview-next-file-hook nil
  "Hooks run after step to next file"
  :group 'slideview
  :type 'hook)

(defcustom slideview-prev-file-hook nil
  "Hooks run after step to previous file"
  :group 'slideview
  :type 'hook)

(defcustom slideview-prefetch-count 2
  "Number of count prefetching slideshow files."
  :group 'slideview
  :type 'integer)

(defun slideview--prefetch-background (buffer context &optional count)
  "FUNC must receive one arg and return next buffer.
That arg is CONTEXT."
  (run-with-idle-timer
   0.5 nil `slideview--prefetch-body
   buffer context (or count slideview-prefetch-count)))

(defun slideview--prefetch-body (buf ctx remain)
  (when (buffer-live-p buf)
    (with-current-buffer buf
      (save-window-excursion
        (let ((next (slideview--find-next ctx nil t)))
          (when (bufferp next)
            (bury-buffer next)
            (when (> remain 0)
              (slideview--prefetch-background
               next ctx (1- remain)))))))))

(defun slideview-concat-image (prev margin direction)
  (unless (memq direction '(bottom left right))
    (error "Not supported direction"))
  (save-excursion
    (let ((inhibit-read-only t)
          ;;TODO to suppress the userlock
          (buffer-file-name))
      (cond
       ((eq direction 'right)
        ;; insert to the left.
        (goto-char (point-min))
        (insert-image prev)
        (insert (make-string (/ margin (frame-char-width)) ?\s)))
       ((eq direction 'left)
        ;; insert to the right
        (goto-char (point-max))
        (insert (make-string (/ margin (frame-char-width)) ?\s))
        (insert-image prev))
       ((eq direction 'bottom)
        ;; insert the top of buffer
        (goto-char (point-min))
        (insert-image prev)
        ;; insert newline after current image.
        (insert (make-string (1+ (/ margin (frame-char-height))) ?\n))))
      (set-buffer-modified-p nil))))

(defvar slideview--settings nil)

(defun slideview-read-direction ()
  (let ((str (completing-read "Direction: "
                              '("left" "right" "bottom") nil t)))
    (intern str)))

(defun slideview-get-match-setting (regexp)
  (cl-loop for s in slideview--settings
           if (and (plist-get s :regexp)
                   (equal (plist-get s :regexp) regexp))
           return s))

(defun slideview-get-setting (base-file)
  (let ((key (directory-file-name base-file)))
    (or
     (cl-loop for s in slideview--settings
              if (or (and (stringp (car s))
                          (string= (car s) key))
                     (equal (plist-get s :file) key))
              return s)
     (cl-loop with max-item
              with max-len
              for s in slideview--settings
              if (ignore-errors
                   (and (string-match (plist-get s :regexp) key)
                        (or (null max-len) (> (match-end 0) max-len))))
              do (setq max-len (match-end 0)
                       max-item s)
              finally return max-item))))

(defclass slideview-context ()
  ((buffers :type list
            :initform nil)
   (base-file :type string)
   (direction :type symbol
              :initform 'right)
   (margin :type number
           :initform 0))
  :abstract t)

(defvar slideview--context nil)
(make-variable-buffer-local 'slideview--context)

(defvar slideview--next-context nil)

(defun slideview--kill-buffer (buffer)
  "Kill BUFFER suppress `slideview--cleanup' execution."
  (with-current-buffer buffer
    (remove-hook 'kill-buffer-hook 'slideview--cleanup t))
  (kill-buffer buffer))

(defun slideview--step (&optional reverse-p)
  (let* ((context slideview--context)
         (prev (current-buffer))
         (next (slideview--find-next context reverse-p)))
    (slideview--step-internal prev next reverse-p)))

(defun slideview--step-internal (prev next reverse-p)
  (cond
   ((null prev))
   (reverse-p
    (bury-buffer prev))
   (t
    (slideview--kill-buffer prev)))
  (cond
   ((null next))
   (reverse-p
    (switch-to-buffer next)
    (run-hooks 'slideview-prev-file-hook)
    (run-hooks 'slideview-move-file-hook))
   (t
    (switch-to-buffer next)
    (run-hooks 'slideview-next-file-hook)
    (run-hooks 'slideview-move-file-hook)))
  (unless reverse-p
    (slideview--prefetch)))

(defun slideview--find-next (context reverse-p &optional no-error)
  (let* (
         ;; pass to next `slideview-mode'
         (slideview--next-context context)
         ;; `slideview--next-buffer' return new buffer
         (next (slideview--next-buffer context reverse-p)))
    (cond
     (next
      (let ((bufs (delq nil (mapcar
                             (lambda (b)
                               (and (buffer-live-p b) b))
                             (oref context buffers)))))
        (with-current-buffer next
          (slideview-mode 1))
        (unless (memq next bufs)
          (oset context buffers (cons next bufs)))
        next))
     (no-error nil)
     (t
      (error "No more file")))))

(defun slideview--prefetch (&optional buffer context)
  (slideview--prefetch-background
   (or buffer (current-buffer))
   (or context slideview--context)))

(defun slideview--next-item (now items reverse-p)
  (let ((items (if reverse-p (reverse items) items)))
    (cadr (member now items))))

;;
;; for directory files
;;

(defclass slideview-directory-context (slideview-context)
  (
   (files :type list)
   )
  "Slideshow context for a regular file."
  )

(defmethod initialize-instance ((this slideview-directory-context) &rest fields)
  (call-next-method)
  (oset this base-file default-directory)
  (slideview--load-context this))

(defmethod slideview--load-context ((context slideview-directory-context))
  (let* ((dir (oref context base-file))
         (files (directory-files dir nil "^\\(?:[^.]\\|\\.\\(?:[^.]\\|\\..\\)\\)")))
    (oset context files
          (slideview-sort-items
           (delq nil
                 (mapcar
                  (lambda (x)
                    ;; exclude directory
                    (unless (eq (car (file-attributes x)) t)
                      (expand-file-name x dir)))
                  files))))))

(defmethod slideview--next-buffer ((context slideview-directory-context) reverse-p)
  (let* ((files (oref context files))
         (file buffer-file-name)
         (next (slideview--next-item file files reverse-p)))
    (when next
      (save-window-excursion
        (slideview--view-file next)))))

(defun slideview--view-file (file)
  (view-file file)
  (current-buffer))

;;
;; arcbase
;;

(defclass slideview-arcbase-context (slideview-context)
  (
   (superior-buffer :type buffer)
   )
  "TODO")

(defmethod initialize-instance ((this slideview-arcbase-context) &rest fields)
  (call-next-method)
  (let* ((superior (slideview--superior-buffer this))
         (file (buffer-file-name superior)))
    (oset this superior-buffer superior)
    (oset this base-file file)))

(defmethod slideview--find-superior-buffer ((context slideview-arcbase-context))
  (or (let ((buffer (oref context superior-buffer)))
        (and (buffer-live-p buffer)
             buffer))
      (let* ((arcfile (oref context base-file))
             (buffer (find-file-noselect arcfile)))
        (oset context superior-buffer buffer)
        buffer)))

;;
;; tar-mode
;;

(defvar tar-parse-info)
(defvar tar-superior-descriptor)
(defvar tar-superior-buffer)

(declare-function tar-header-name "tar-mode" (tar-header) t)
(declare-function tar-current-descriptor "tar-mode")
(declare-function tar-extract "tar-mode")
(declare-function tar-next-line "tar-mode")

(defclass slideview-tar-context (slideview-arcbase-context)
  (
   (paths :type list)
   )
  "Slideshow context for `tar-mode'"
  )

(defun slideview--tar-view-file (file)
  (or
   (let* ((name (concat buffer-file-name "!" file))
          (buf (get-file-buffer name)))
     (when buf
       (switch-to-buffer buf)
       buf))
   (let ((first (point))
         desc)
     (goto-char (point-min))
     (catch 'done
       (while (setq desc (tar-current-descriptor))
         (when (string= (tar-header-name desc) file)
           (tar-extract 'view)
           (throw 'done (current-buffer)))
         (tar-next-line 1))
       ;; not found. restore the previous point
       (goto-char first)
       (error "%s not found" file)))))

(defmethod initialize-instance ((this slideview-tar-context) &rest fields)
  (call-next-method)
  (slideview--load-context this))

(defmethod slideview--load-context ((context slideview-tar-context))
  (with-current-buffer (slideview--find-superior-buffer context)
    (oset context paths
          (slideview-sort-items
           (mapcar 'tar-header-name tar-parse-info)))))

(defmethod slideview--next-buffer ((context slideview-tar-context) reverse-p)
  (let* ((superior (slideview--find-superior-buffer context))
         (path (and superior tar-superior-descriptor
                    (tar-header-name tar-superior-descriptor)))
         (paths (oref context paths))
         (next (and path (slideview--next-item path paths reverse-p))))
    (when next
      (with-current-buffer superior
        (save-window-excursion
          (slideview--tar-view-file next))))))

(defmethod slideview--superior-buffer ((context slideview-tar-context))
  (or
   (and (bufferp tar-superior-buffer)
        (buffer-live-p tar-superior-buffer)
        tar-superior-buffer)
   ;;FIXME this is local variable defined at tar-mode.el
   (and (boundp 'tar-buffer)
        tar-buffer)
   (and buffer-file-name
        (let ((file buffer-file-name))
          (and (string-match "^\\(.+?\\)!" file)
               (let ((archive (match-string 1 file)))
                 (or (get-file-buffer archive)
                     ;; Open archive buffer with no confirmation
                     (find-file-noselect archive))))))))

;;
;; for archive-mode
;;

(defvar archive-file-list-start)
(defvar archive-file-list-end)
(defvar archive-superior-buffer)
(defvar archive-files)
(defvar archive-subfile-mode)

(declare-function archive-view "arc-mode")
(declare-function archive-next-line "arc-mode")
(declare-function archive-get-descr "arc-mode")

(defclass slideview-archive-context (slideview-arcbase-context)
  (
   (paths :type list)
   )
  "Slideshow context for `archive-mode'"
  )

(defun slideview--archive-view-file (file)
  (or
   (let* ((name (concat buffer-file-name ":" file))
          (buf (get-file-buffer name)))
     (when buf
       (switch-to-buffer buf)
       buf))
   (let ((first (point))
         desc)
     (goto-char archive-file-list-start)
     (catch 'done
       (while (< (point) archive-file-list-end)
         (setq desc (archive-get-descr t))
         (when (and desc
                    (string= (aref desc 0) file))
           (archive-view)
           (throw 'done (current-buffer)))
         (archive-next-line 1))
       ;; not found. restore the previous point
       (goto-char first)
       (error "%s not found" file)))))

(defmethod initialize-instance ((this slideview-archive-context) &rest fields)
  (call-next-method)
  (slideview--load-context this))

(defmethod slideview--load-context ((context slideview-archive-context))
  (with-current-buffer (slideview--find-superior-buffer context)
    (oset context paths
          (slideview-sort-items
           (cl-loop for f across archive-files
                    if f
                    collect (aref f 0))))))

(defmethod slideview--next-buffer ((context slideview-archive-context) reverse-p)
  (let* ((superior (slideview--find-superior-buffer context))
         (path (and archive-subfile-mode
                    (aref archive-subfile-mode 0)))
         (paths (oref context paths))
         (next (and path (slideview--next-item path paths reverse-p))))
    (when next
      (with-current-buffer superior
        (save-window-excursion
          (slideview--archive-view-file next))))))

(defmethod slideview--superior-buffer ((context slideview-archive-context))
  (or
   (and (bufferp archive-superior-buffer)
        (buffer-live-p archive-superior-buffer)
        archive-superior-buffer)
   (and archive-subfile-mode
        buffer-file-name
        (let ((file buffer-file-name)
              (archive-path (aref archive-subfile-mode 0)))
          (when (string-match (concat (regexp-quote archive-path) "$") file)
            (let ((archive (substring file 0 (1- (match-beginning 0)))))
              (or (get-file-buffer archive)
                  ;; Open archive buffer with no confirmation
                  (find-file-noselect archive))))))))

;;
;; Minor mode
;;

(defvar slideview-mode-map nil)

(unless slideview-mode-map
  (let ((map (make-sparse-keymap)))

    (define-key map " " 'slideview-next-file)
    (define-key map "\d" 'slideview-prev-file)
    (define-key map "\C-c\C-i" 'slideview-concat-next-if-image)
    (define-key map "\C-c\e\C-i" 'slideview-concat-prev-if-image)

    (setq slideview-mode-map map)))

(defun slideview--cleanup ()
  (condition-case nil
      (dolist (b (oref slideview--context buffers))
        ;; save the current buffer
        (and (not (eq (current-buffer) b))
             (buffer-live-p b)
             (slideview--kill-buffer b)))
    (error nil)))

(defun slideview--revert ()
  (condition-case nil
      (slideview--load-context slideview--context)
    (error nil)))

(defun slideview--new-context ()
  (unless buffer-file-name
    (error "Not a file buffer"))
  (let* ((ctx (cond
               ((and (boundp 'archive-subfile-mode)
                     archive-subfile-mode)
                (make-instance slideview-archive-context))
               ((and (boundp 'tar-buffer)
                     ;; FIXME tar-buffer is `let' bind local-variable
                     ;;   defined at `tar-extract'
                     tar-buffer)
                (make-instance slideview-tar-context))
               ;;TODO
               ;; ((derived-mode-p 'doc-view-mode)
               ;;  (make-instance slideview-pdf-context))
               (t
                (make-instance slideview-directory-context))))
         (setting (slideview-get-setting (oref ctx base-file))))
    (cond
     ((not setting))
     ((stringp (car setting))
      ;; for old version
      (mapc
       (lambda (x)
         (eieio-oset ctx (car x) (cdr x)))
       (cdr setting)))
     (t
      (eieio-oset ctx 'margin (plist-get setting :margin))
      (eieio-oset ctx 'direction (plist-get setting :direction))))
    ctx))

;;;###autoload
(define-minor-mode slideview-mode
  ""
  :init-value nil
  :lighter " Slide"
  :keymap slideview-mode-map
  (cond
   (slideview-mode
    (condition-case err
        (progn
          (add-hook 'after-revert-hook 'slideview--revert nil t)
          (add-hook 'kill-buffer-hook 'slideview--cleanup nil t)
          (setq slideview--context
                (or slideview--next-context
                    (slideview--new-context))))
      (error
       ;; fallback
       (message "%s" err)
       (slideview-mode -1))))
   (t
    (remove-hook 'after-revert-hook 'slideview--revert t)
    (remove-hook 'kill-buffer-hook 'slideview--cleanup t)
    (when slideview--context
      (slideview--cleanup)))))

;;TODO add sample of settings
;;;###autoload
(cl-defun slideview-modify-setting (base-file &key margin direction)
  "Modify new slideview settings of BASE-FILE.
BASE-FILE is directory or *.tar file or *.zip filename.

:margin controls pixel margin between two sequenced images.
:direction controls slide direction of image files.
"
  (unless (or (null direction) (memq direction '(left right bottom)))
    (signal 'args-out-of-range (list direction)))
  (unless (or (null margin) (numberp margin))
    (signal 'wrong-type-argument (list margin)))
  (let ((setting (slideview-get-setting base-file)))
    (when setting
      (setq slideview--settings (delq setting slideview--settings)))
    (setq slideview--settings
          (cons
           `(:file ,(directory-file-name base-file)
                   ,@(if direction `(:direction ,direction) '())
                   ,@(if margin `(:margin ,margin) '()))
           slideview--settings))))

;;;###autoload
(cl-defun slideview-modify-match-setting (regexp &key margin direction)
  "Modify new slideview settings of REGEXP to match filename.

:margin controls pixel margin between two sequenced images.
:direction controls slide direction of image files.
"
  (unless (or (null direction) (memq direction '(left right bottom)))
    (signal 'args-out-of-range (list direction)))
  (unless (or (null margin) (numberp margin))
    (signal 'wrong-type-argument (list margin)))
  (let ((setting (slideview-get-match-setting regexp)))
    (when setting
      (setq slideview--settings (delq setting slideview--settings)))
    (setq slideview--settings
          (cons
           `(:regexp ,regexp
                     ,@(if direction `(:direction ,direction) '())
                     ,@(if margin `(:margin ,margin) '()))
           slideview--settings))))

;;;###autoload
(cl-defun slideview-add-matched-file (directory regexp &key margin direction)
  "Add new slideview settings of DIRECTORY files that match to REGEXP.

See `slideview-modify-setting' more information.
"
  (cond
   ((file-directory-p directory)
    (dolist (f (directory-files directory t regexp))
      (when (file-directory-p f)
        (slideview-modify-setting f :margin margin :direction direction)))))
  slideview--settings)

;;
;; Utilities
;;

;;TODO
;; check 1.jpg 2.jpg ... 10.jpg like names.
(defun slideview-numbering-lessp (x1 x2)
  (file-name-nondirectory x1)
  (file-name-nondirectory x2))

(defun slideview-sort-items (items)
  (sort items 'string-lessp))

;;
;; Commands
;;

(defun slideview-next-file ()
  "View next file (have same extension, sorted by string order)"
  (interactive)
  (slideview--step))

(defun slideview-prev-file ()
  "View next file (have same extension, sorted by reverse string order)"
  (interactive)
  (slideview--step t))

(declare-function image-get-display-property "image-mode")

(defun slideview-concat-prev-if-image (&optional direction)
  "Reopen the previous image file with concatenate current image.

See `slideview-modify-setting' about this settings.
"
  (interactive (if current-prefix-arg
                   (list (slideview-read-direction))))
  (unless (derived-mode-p 'image-mode)
    (error "Not a `image-mode'"))
  (let* ((context slideview--context)
         (prev (let ((buf (slideview--find-next context t)))
                 (and buf
                      (prog1
                          (with-current-buffer buf
                            (image-get-display-property))
                        (slideview--kill-buffer buf))))))
    (unless prev
      (error "No more previous image"))
    (slideview-concat-image
     prev (oref context margin)
     (or direction (oref context direction)))))

(defun slideview-concat-next-if-image (&optional direction)
  "Open the next image file with concatenate current image.

See `slideview-modify-setting' about this settings.
"
  (interactive (if current-prefix-arg
                   (list (slideview-read-direction))))
  (unless (derived-mode-p 'image-mode)
    (error "Not a `image-mode'"))
  (let ((prev (image-get-display-property))
        (context slideview--context))
    (slideview--step)
    (slideview-concat-image
     prev (oref context margin)
     (or direction (oref context direction)))))

;;
;; TESTING: slideshow
;;

;; only one slideshow in one emacs process?
(defvar slideview--slideshow-timer nil)
(make-variable-buffer-local 'slideview--slideshow-timer)

;;TODO switch to other buffer after start.
;;TODO when step to backward
(defun slideview--slideshow-next (buffer)
  `(lambda ()
     (condition-case nil
         (progn
           (when (buffer-live-p ,buffer)
             ;;TODO
             (save-window-excursion
               (with-current-buffer ,buffer
                 (slideview-next-file)
                 ;;TODO how to start new timer before slide to next
                 (slideview-start-slideshow)))))
       ;;TODO restrict by signal type
       (error
        (when (buffer-live-p ,buffer)
          (kill-buffer ,buffer))))))

(defun slideview-toggle-slideshow ()
  (interactive)
  (cond
   ((and slideview--slideshow-timer
         (timerp slideview--slideshow-timer))
    (cancel-timer slideview--slideshow-timer)
    (setq slideview--slideshow-timer nil)
    (message "Slideshow is stopped."))
   (t
    (slideview-start-slideshow)
    (message "Starting slideshow..."))))

(defun slideview-start-slideshow (&optional interval)
  "Start slideshow in current `slideview--context'"
  (interactive
   (let (interval)
     (when current-prefix-arg
       (setq interval (read-number "Interval: ")))
     (list interval)))
  (setq slideview--slideshow-timer
        (run-with-timer slideview-slideshow-interval nil
                        (slideview--slideshow-next (current-buffer)))))

(provide 'slideview)

;;; slideview.el ends here
