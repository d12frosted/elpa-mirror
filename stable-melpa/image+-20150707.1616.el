;;; image+.el --- Image manipulate extensions for Emacs

;; Author: Masahiro Hayashi <mhayashi1120@gmail.com>
;; Keywords: multimedia, extensions
;; Package-Version: 20150707.1616
;; Package-Commit: 6834d0c09bb4df9ecc0d7a559bd7827fed48fffc
;; URL: https://github.com/mhayashi1120/Emacs-imagex
;; Emacs: GNU Emacs 22 or later
;; Version: 0.6.3
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

;; ## Install:

;; Please install the ImageMagick before installing this elisp.

;; Put this file into load-path'ed directory, and byte compile it if
;; desired. And put the following expression into your ~/.emacs.

;;     (eval-after-load 'image '(require 'image+))

;; ## Usage:

;; * [__Recommended__] Sample Hydra setting. Instead of `imagex-global-sticky-mode' .

;;  https://github.com/abo-abo/hydra

;;     (eval-after-load 'image+
;;       `(when (require 'hydra nil t)
;;          (defhydra imagex-sticky-binding (global-map "C-x C-l")
;;            "Manipulating Image"
;;            ("+" imagex-sticky-zoom-in "zoom in")
;;            ("-" imagex-sticky-zoom-out "zoom out")
;;            ("M" imagex-sticky-maximize "maximize")
;;            ("O" imagex-sticky-restore-original "restore original")
;;            ("S" imagex-sticky-save-image "save file")
;;            ("r" imagex-sticky-rotate-right "rotate right")
;;            ("l" imagex-sticky-rotate-left "rotate left"))))

;;  Then try to type `C-x C-l +` to zoom-in the current image.
;;  You can zoom-out with type `-` .

;; * To manipulate a image under cursor.

;;     M-x imagex-sticky-mode

;;  Or to activate globally:

;;     M-x imagex-global-sticky-mode

;;  Or in .emacs:

;;     (eval-after-load 'image+ '(imagex-global-sticky-mode 1))

;; * `C-c +` / `C-c -`: Zoom in/out image.
;; * `C-c M-m`: Adjust image to current frame size.
;; * `C-c C-x C-s`: Save current image.
;; * `C-c M-r` / `C-c M-l`: Rotate image.
;; * `C-c M-o`: Show image `image+` have not modified.

;; * Adjusted image when open image file.

;;     M-x imagex-auto-adjust-mode

;;   Or in .emacs:

;;     (eval-after-load 'image+ '(imagex-auto-adjust-mode 1))

;; * If you do not want error message in minibuffer:

;;     (setq imagex-quiet-error t)

;;; Code:

(eval-when-compile
  (require 'easy-mmode))

(require 'cl-lib)
(require 'image)
(require 'image-file)
(require 'advice)

(defgroup image+ ()
  "Image extensions"
  :group 'multimedia)

(defcustom imagex-convert-command "convert"
  "ImageMagick convert command"
  :group 'image+
  :type 'file)

(defcustom imagex-identify-command "identify"
  "ImageMagick identify command"
  :group 'image+
  :type 'file)

(defvar this-command)
(defvar imagex-auto-adjust-mode)

(defcustom imagex-auto-adjust-threshold 3
  "Maximum magnification when `imagex-auto-adjust-mode' is on."
  :group 'image+
  :type 'number)

(defcustom imagex-quiet-error nil
  "Suppress error message when convert image."
  :group 'imagex
  :type 'boolean)


(defun imagex--call-convert (image &rest args)
  (let ((spec (cdr image)))
    (with-temp-buffer
      (set-buffer-multibyte nil)
      (let ((coding-system-for-read 'binary)
            (coding-system-for-write 'binary)
            (default-directory
              (or
               (and temporary-file-directory
                    (file-name-as-directory temporary-file-directory))
               default-directory)))
        (cond
         ((plist-get spec :data)
          (insert (plist-get spec :data))
          ;; stdin to current-buffer
          (unless (eq (apply 'call-process-region
                             (point-min) (point-max) imagex-convert-command
                             t (current-buffer) nil
                             `("-" ,@args "-")) 0)
            (error "Cannot convert image")))
         ((plist-get spec :file)
          ;; stdin to current-buffer
          (unless (eq (apply 'call-process
                             imagex-convert-command
                             (plist-get spec :file) t nil
                             `("-" ,@args "-")) 0)
            (error "Cannot convert image")))
         (t
          (error "Not a supported image")))
        (let ((img (create-image (buffer-string) nil t)))
          (plist-put (cdr img) 'imagex-original-image
                     (or (plist-get (cdr image) 'imagex-original-image)
                         (copy-sequence image)))
          img)))))

(defun imagex-image-object-p (object)
  (and object (consp object)
       (eq (car object) 'image)))

(defun imagex--replace-textprop-image (start end image)
  (let ((flag (buffer-modified-p))
        (inhibit-read-only t))
    (put-text-property start end 'display image)
    (set-buffer-modified-p flag)))

(defun imagex--replace-current-image (new-image)
  (cond
   ((derived-mode-p 'image-mode)
    (cl-destructuring-bind (begin end)
        (imagex--display-region (point-min))
      (imagex--replace-textprop-image begin end new-image)))
   ((derived-mode-p 'doc-view-mode)
    (let ((ov (car (overlays-in (point-min) (point-max)))))
      (overlay-put ov 'display new-image)))
   (t
    (cl-destructuring-bind (begin end)
        (imagex--display-region (point))
      (imagex--replace-textprop-image begin end new-image)))))

(declare-function image-get-display-property nil)
(declare-function doc-view-current-image nil)

(defun imagex--current-image ()
  (cond
   ((derived-mode-p 'image-mode)
    (image-get-display-property))
   ((derived-mode-p 'doc-view-mode)
    (doc-view-current-image))
   (t
    (let* ((ovs (overlays-at (point)))
           (disp (get-text-property (point) 'display))
           (ov (car (cl-remove-if-not
                     (lambda (ov) (overlay-get ov 'display))
                     ovs))))
      (when (and ov (overlay-get ov 'display))
        (setq disp (overlay-get ov 'display)))
      ;; only image object (Not sliced image)
      (and (imagex-image-object-p disp)
           disp)))))

(defun imagex--display-region (point)
  (let* ((end (or (next-single-property-change point 'display)
                  (point-max)))
         (begin (or (previous-single-property-change end 'display)
                    (point-min))))
    (list begin end)))

(defun imagex--zoom (image magnification)
  (let* ((pixels (image-size image t))
         (new (imagex--call-convert
               image
               "-resize"
               (format "%sx%s"
                       (truncate (* (car pixels) magnification))
                       (truncate (* (cdr pixels) magnification))))))
    ;; clone source image properties
    (when (plist-get (cdr image) :margin)
      (plist-put (cdr new) :margin
                 (plist-get (cdr image) :margin)))
    (when (plist-get (cdr image) :relief)
      (plist-put (cdr new) :relief
                 (plist-get (cdr image) :relief)))
    new))

(defun imagex--fit-to-size (image width height &optional max)
  "Resize IMAGE with preserving magnification."
  (let* ((pixels (image-size image t))
         (margin (or (plist-get (cdr image) :margin) 0))
         (relief (or (plist-get (cdr image) :relief) 0))
         (mr (+ (* 2 margin) (* 2 relief)))
         (w (+ (car pixels) mr))
         (h (+ (cdr pixels) mr))
         (wr (/ width (ftruncate w)))
         (hr (/ height (ftruncate h)))
         (magnification (apply 'min (delq nil (list wr hr max)))))
    (imagex--zoom image magnification)))

(defun imagex--maximize (image &optional maximum)
  "Adjust IMAGE to current frame."
  (let* ((edges (window-inside-pixel-edges))
         (width (- (nth 2 edges) (nth 0 edges)))
         (height (- (nth 3 edges) (nth 1 edges))))
    (imagex--fit-to-size image width height maximum)))

(defun imagex--rotate-degrees (arg)
  (cond
   ((numberp arg)
    arg)
   ((consp arg)
    (* (truncate
        (/ (log (prefix-numeric-value arg) 2) 2)) 90))
   (t 90)))

(defun imagex-one-image-mode-p ()
  (memq major-mode '(image-mode doc-view-mode)))

(defun imagex--message (format &rest args)
  (unless imagex-quiet-error
    (apply 'message (concat "image+: " format) args)
    (sit-for 0.5)))

;;
;; Image+ Minor mode definitions
;;

(defvar imagex-sticky-mode-map nil)

(unless imagex-sticky-mode-map
  (let ((map (make-sparse-keymap)))

    (define-key map "\C-c+" 'imagex-sticky-zoom-in)
    (define-key map "\C-c-" 'imagex-sticky-zoom-out)
    (define-key map "\C-c\el" 'imagex-sticky-rotate-left)
    (define-key map "\C-c\er" 'imagex-sticky-rotate-right)
    (define-key map "\C-c\em" 'imagex-sticky-maximize)
    (define-key map "\C-c\eo" 'imagex-sticky-restore-original)
    (define-key map "\C-c\C-x\C-s" 'imagex-sticky-save-image)

    (setq imagex-sticky-mode-map map)))

;;;###autoload
(define-minor-mode imagex-sticky-mode
  "To manipulate Image at point."
  :group 'image+
  :keymap imagex-sticky-mode-map
  )

;;;###autoload
(define-globalized-minor-mode imagex-global-sticky-mode
  imagex-sticky-mode imagex-sticky-mode-maybe
  :group 'image+)

(defun imagex-sticky-mode-maybe ()
  (when (executable-find imagex-convert-command)
    (unless (minibufferp (current-buffer))
      (imagex-sticky-mode 1))))

(defun imagex-sticky--current-textprop-display ()
  (let ((disp (get-text-property (point) 'display)))
    ;; only image object (Not sliced image)
    (when (imagex-image-object-p disp)
      (cl-destructuring-bind (begin end)
          (imagex--display-region (point))
        (list disp begin end)))))

(defun imagex-sticky--current-ovprop-display ()
  (let* ((ovs (overlays-at (point)))
         (ov (car (cl-remove-if-not
                   (lambda (ov) (overlay-get ov 'display))
                   ovs))))
    (when (and ov (overlay-get ov 'display))
      (let ((disp (overlay-get ov 'display)))
        ;; only image object (Not sliced image)
        (and (imagex-image-object-p disp)
             (list disp ov))))))

;; fallback to original keybind
;; if current point doesn't have image.
(defun imagex-sticky-fallback (&optional except-command)
  (let ((keys (this-command-keys-vector)))
    ;; suppress this minor mode to get original command
    (let* ((imagex-sticky-mode nil)
           (command (if keys (key-binding keys))))
      (when (and (commandp command)
                 (not (eq command except-command)))
        (setq this-command command)
        (call-interactively command)))))

(defun imagex-sticky--convert-image (converter)
  (catch 'done
    (let (err)
      (condition-case err1
          (let ((display (imagex-sticky--current-ovprop-display)))
            (when display
              (cl-destructuring-bind (image ov) display
                (let ((new (funcall converter image)))
                  (plist-put (cdr new) 'imagex-manual-manipulation t)
                  (overlay-put ov 'display new))
                (throw 'done t))))
        (error
         (setq err (append err err1))))
      (condition-case err2
          (let ((display (imagex-sticky--current-textprop-display)))
            (when display
              (cl-destructuring-bind (image begin end) display
                (let ((new (funcall converter image)))
                  (plist-put (cdr new) 'imagex-manual-manipulation t)
                  (imagex--replace-textprop-image begin end new))
                (throw 'done t))))
        (error
         (setq err (append err err2))))
      (when err
        (imagex--message "%s" err))
      (imagex-sticky-fallback this-command))))

(defun imagex-sticky--rotate-image (degrees)
  (imagex-sticky--convert-image
   (lambda (image)
     (imagex--call-convert
      image "-rotate" (format "%s" degrees)))))

(defun imagex-sticky--zoom (magnification)
  (imagex-sticky--convert-image
   (lambda (image)
     (imagex--zoom image magnification))))

(defun imagex-sticky-zoom-in (&optional arg)
  "Zoom in image at point.
If there is no image, fallback to original command."
  (interactive "p")
  (imagex-sticky--zoom (* 1.1 arg)))

(defun imagex-sticky-zoom-out (&optional arg)
  "Zoom out image at point.
If there is no image, fallback to original command."
  (interactive "p")
  (imagex-sticky--zoom (/ 1 1.1 arg)))

(defun imagex-sticky-save-image ()
  "Save image at point.
If there is no image, fallback to original command."
  (interactive)
  (condition-case nil
      (cl-destructuring-bind (image . _)
          (or (imagex-sticky--current-ovprop-display)
              (imagex-sticky--current-textprop-display))
        (let ((spec (cdr image)))
          (cond
           ((plist-get spec :file)
            (let* ((src-file (plist-get spec :file))
                   (ext (concat "." (symbol-name (image-type src-file nil))))
                   (file (read-file-name "Image File: " nil nil nil ext)))
              (let ((coding-system-for-write 'binary))
                (copy-file src-file file t))))
           ((plist-get spec :data)
            (let* ((data (plist-get spec :data))
                   (ext (concat "." (symbol-name (image-type data nil t))))
                   (file (read-file-name "Image File: " nil nil nil ext)))
              (let ((coding-system-for-write 'binary))
                (write-region data nil file))))
           (t (error "Abort")))))
    (error
     (imagex-sticky-fallback this-command))))

(defun imagex-sticky-maximize ()
  "Maximize the point image to fit the current frame."
  (interactive)
  (imagex-sticky--convert-image
   (lambda (image)
     (imagex--maximize image))))

(defun imagex-sticky-restore-original ()
  "Restore the original image if current image has been converted."
  (interactive)
  (imagex-sticky--convert-image
   (lambda (image)
     (let ((orig (plist-get (cdr image) 'imagex-original-image)))
       (unless orig
         (error "No original image here"))
       orig))))

(defun imagex-sticky-rotate-left (&optional degrees)
  "Rotate current image left (counter clockwise) 90 degrees.
Use \\[universal-argument] followed by a number to specify a exactly degree.
Multiple \\[universal-argument] as argument means to count of type multiply
by 90 degrees."
  (interactive "P")
  (imagex-sticky--rotate-image
   (- 360 (imagex--rotate-degrees degrees))))

(defun imagex-sticky-rotate-right (&optional degrees)
  "Rotate current image right (counter clockwise) 90 degrees.
Use \\[universal-argument] followed by a number to specify a exactly degree.
Multiple \\[universal-argument] as argument means to count of type multiply
by 90 degrees."
  (interactive "P")
  (imagex-sticky--rotate-image
   (imagex--rotate-degrees degrees)))



(defun imagex--activate-advice (flag alist)
  (cl-loop for (fn adname) in alist
           do (condition-case nil
                  (progn
                    (funcall (if flag
                                 'ad-enable-advice
                               'ad-disable-advice)
                             fn 'around adname)
                    (ad-activate fn))
                (error nil))))

;; adjust image fit to window if window has just one image
;; this function is invoked from `imagex-auto-adjust-mode'
(defun imagex--adjust-image-to-window ()
  (when (and (not (minibufferp))
             imagex-auto-adjust-mode
             (imagex-one-image-mode-p))
    (condition-case err
        (let ((image (imagex--current-image)))
          (cond
           ((null image))
           ;; TODO work around to fix background file modification
           ((not (verify-visited-file-modtime))
            (error "Image is modified on the disk"))
           (t
            (let ((manualp (plist-get (cdr image) 'imagex-manual-manipulation))
                  (prev-edges (plist-get (cdr image) 'imagex-auto-adjusted-edges))
                  (curr-edges (window-edges)))
              (when (and (not manualp)
                         (or (null prev-edges)
                             (not (equal curr-edges prev-edges))))
                (let* ((orig (plist-get (cdr image) 'imagex-original-image))
                       (target (or orig image))
                       (new-image
                        (imagex--maximize target imagex-auto-adjust-threshold)))
                  ;; new-image may be nil if original image file was removed
                  (when new-image
                    (imagex--replace-current-image new-image)
                    (plist-put (cdr new-image)
                               'imagex-auto-adjusted-edges curr-edges))))))))
      (error
       (imagex--message "%s" err)))))


(defvar imagex-auto-adjust-advices
  '(
    insert-image-file
    image-toggle-display-image
    doc-view-insert-image
    ))

(defmacro imagex--auto-adjust-activate (&rest body)
  "Execute BODY with activating `create-image' advice."
  `(progn
     (ad-enable-advice 'create-image 'around 'imagex-create-image)
     (ad-activate 'create-image)
     (unwind-protect
         (progn ,@body)
       (ad-disable-advice 'create-image 'around 'imagex-create-image)
       (ad-activate 'create-image))))

;;;###autoload
(define-minor-mode imagex-auto-adjust-mode
  "Adjust image to current frame automatically in `image-mode'.

Type \\[imagex-sticky-restore-original] to restore the original image.
"
  :global t
  :group 'image+
  (let ((alist
         (mapcar
          (lambda (fn)
            (let* ((adname (intern (concat "imagex-" (symbol-name fn) "-ad")))
                   (advice (ad-make-advice
                            adname nil nil
                            `(advice lambda (&rest args)
                                     (imagex--auto-adjust-activate
                                      (setq ad-return-value ad-do-it))))))
              (ad-add-advice fn advice 'around nil)
              (list fn adname)))
          imagex-auto-adjust-advices)))
    (imagex--activate-advice imagex-auto-adjust-mode alist)
    ;;TODO want make local hook but seems `window-configuration-change-hook'
    ;; is not working locally.
    (cond
     (imagex-auto-adjust-mode
      (add-hook 'window-configuration-change-hook
                'imagex--adjust-image-to-window)
      ;; maybe replace current displaying image
      (imagex--adjust-image-to-window))
     (t
      ;; No need to restore originals
      (remove-hook 'window-configuration-change-hook
                   'imagex--adjust-image-to-window)))))

(defun imagex-create-adjusted-image
    (file-or-data &optional type data-p &rest props)
  (let ((img
         (apply (ad-get-orig-definition 'create-image)
                file-or-data type data-p props)))
    (cond
     ((boundp 'imagex-adjusting)
      (plist-put (cdr img) 'imagex-auto-adjusted-edges (window-edges))
      img)
     (t
      (or
       (condition-case err
           ;; suppress eternal recurse
           (let ((imagex-adjusting t))
             (imagex--maximize img imagex-auto-adjust-threshold))
         (error
          ;; handling error that is caused by ImageMagick unsupported image.
          (imagex--message "%s" err)
          nil))
       img)))))

(defadvice create-image
    (around imagex-create-image (&rest args) disable)
  (setq ad-return-value
        (apply 'imagex-create-adjusted-image args)))



(provide 'image+)

;;; image+.el ends here
