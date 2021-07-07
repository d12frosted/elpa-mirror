;;; ace-jump-buffer.el --- fast buffer switching extension to `avy' -*- lexical-binding: t -*-
;;
;; Copyright 2013-2015 Justin Talbott
;;
;; Author: Justin Talbott <justin@waymondo.com>
;; URL: https://github.com/waymondo/ace-jump-buffer
;; Package-Version: 20171031.1550
;; Package-Commit: 0d335064230caf3efdd5a732e8fbd67e3948ed6a
;; Version: 0.4.1
;; Package-Requires: ((avy "0.4.0") (dash "2.4.0"))
;; License: GNU General Public License version 3, or (at your option) any later version

;;; Commentary:
;;
;;   (require 'ace-jump-buffer)
;;   then bind `ace-jump-buffer' to something useful
;;
;;; Code:

(require 'bs)
(require 'avy)
(require 'recentf)
(require 'dash)

(defgroup ace-jump-buffer nil
  "Fast buffer switching extension to `avy'."
  :version "0.4.0"
  :link '(url-link "https://github.com/waymondo/ace-jump-buffer")
  :group 'convenience)

(defcustom ajb-max-window-height 20
  "Maximal window height of Ace Jump Buffer Selection Menu."
  :group 'ace-jump-buffer
  :type 'integer)

(defcustom ajb-sort-function nil
  "The `bs-sort-function' function used when displaying `ace-jump-buffer'."
  :group 'ace-jump-buffer
  :type '(radio (const :tag "No custom sorting" nil)
                (function-item bs--sort-by-recentf)
                (function-item bs--sort-by-name)
                (function-item bs--sort-by-size)
                (function-item bs--sort-by-filename)
                (function-item bs--sort-by-mode)
                (function :tag "Other function")))

(defcustom ajb-bs-configuration "all"
  "The `bs-configuration' used when displaying `ace-jump-buffer'."
  :group 'ace-jump-buffer)

(defface ajb-face '((t :background unspecified :foreground unspecified))
  "Customizable face to use within the `ace-jump-buffer' menu. The default is unspecified."
  :group 'ace-jump-buffer)

(defcustom ajb-style 'at-full
  "The default method of displaying the overlays for `ace-jump-buffer'."
  :type '(choice
          (const :tag "Pre" pre)
          (const :tag "At" at)
          (const :tag "At Full" at-full)
          (const :tag "Post" post)
          (const :tag "De Bruijn" de-bruijn)
          (const :tag "Words" words)))

;; interval settings
(defvar ajb/showing nil)
(defvar ajb/other-window nil)
(defvar ajb/in-one-window nil)
(defvar ajb/configuration-history nil)

;; settings for a barebones `bs' switcher
(defvar ajb/bs-attributes-list '(("" 2 2 left " ")
                                 ("" 1 1 left bs--get-marked-string)
                                 ("" 1 1 left " ")
                                 ("Buffer" bs--get-name-length 10 left bs--get-name)))

(defun ajb/bs--show-header--around (oldfun)
  "Don't show the `bs' header when doing `ace-jump-buffer'."
  (unless ajb/showing (funcall oldfun)))

(advice-add 'bs--show-header :around 'ajb/bs--show-header--around)

(defun ajb/bs-set-configuration--after (name)
  "Set `bs-buffer-sort-function' to the value of `ajb-sort-function'."
  (when ajb/showing (setq bs-buffer-sort-function ajb-sort-function)))

(advice-add 'bs-set-configuration :after 'ajb/bs-set-configuration--after)

(defun bs--sort-by-recentf (b1 b2)
  "Sort function for comparing buffers `B1' and `B2' by recentf order."
  (let ((b1-index (-elem-index (buffer-file-name b1) recentf-list))
        (b2-index (-elem-index (buffer-file-name b2) recentf-list)))
    (when (and b1-index b2-index (< b1-index b2-index)) t)))

(defun ajb/select-buffer ()
  "On the end of ace jump, select the buffer at the current line."
  (when (string-match (buffer-name) "*buffer-selection*")
    (if ajb/other-window (bs-select-other-window)
      (if ajb/in-one-window (bs-select-in-one-window)
        (bs-select)))))

(defun ajb/kill-bs-menu ()
  "Exit and kill the `bs' window on an invalid character."
  (bs-kill)
  (when (get-buffer "*buffer-selection*")
    (kill-buffer "*buffer-selection*")))

(defun ajb/exit (_char)
  "Exit and kill the `bs' window on an invalid character, throw done message."
  (ajb/kill-bs-menu)
  (throw 'done nil))

(defun ajb/goto-line-and-buffer ()
  "Goto visible line below the cursor and visit the associated buffer."
  (interactive)
  (let ((avy-all-windows nil)
        (r (avy--line
            nil (line-beginning-position 1)
            (window-end (selected-window) t))))
    (if (or (stringp r) (not r))
        (ajb/kill-bs-menu)
      (unless (eq r t)
        (avy-action-goto r)
        (ajb/select-buffer)))))

;;;###autoload
(defun ace-jump-buffer ()
  "Quickly hop to buffer with `avy'."
  (interactive)
  (let ((avy-background nil)
        (avy-all-windows nil)
        (bs-attributes-list ajb/bs-attributes-list)
        (avy-handler-function 'ajb/exit)
        (avy-style ajb-style)
        (ajb/showing t))
    (save-excursion
      (bs--show-with-configuration ajb-bs-configuration)
      (set (make-local-variable 'bs-header-lines-length) 0)
      (set (make-local-variable 'bs-max-window-height) ajb-max-window-height)
      (face-remap-add-relative 'default 'ajb-face)
      (goto-char (point-min))
      (bs--set-window-height)
      (ajb/goto-line-and-buffer))))

;;;###autoload
(defun ace-jump-buffer-other-window ()
  "Quickly hop to buffer with `avy' in other window."
  (interactive)
  (let ((ajb/other-window t))
    (ace-jump-buffer)))

;;;###autoload
(defun ace-jump-buffer-in-one-window ()
  "Quickly hop to buffer with `avy' in one window."
  (interactive)
  (let ((ajb/in-one-window t))
    (ace-jump-buffer)))

;;;###autoload
(defun ace-jump-buffer-with-configuration ()
  "Quickly hop to buffer with `avy' with selected configuration."
  (interactive)
  (let* ((name (completing-read "Ace jump buffer with configuration: "
                                (--map (car it) bs-configurations) nil t nil
                                'ajb/configuration-history
                                (car ajb/configuration-history)))
         (ajb-bs-configuration name))
    (ace-jump-buffer)))

;;;###autoload
(defmacro make-ace-jump-buffer-function (name &rest buffer-list-reject-filter)
  "Create a `bs-configuration' and interactive defun using `NAME'.

It will displays buffers that don't get rejected by the body of
`BUFFER-LIST-REJECT-FILTER'."
  (declare (indent 1))
  (let ((filter-defun-name (intern (format "ajb/filter-%s-buffers" name)))
        (defun-name (intern (format "ace-jump-%s-buffers" name))))
    `(progn
       (defun ,filter-defun-name (buffer)
         ,@buffer-list-reject-filter)
       (defun ,defun-name ()
         (interactive)
         (let ((ajb-bs-configuration ,name))
           (ace-jump-buffer)))
       (add-to-list 'bs-configurations
                    '(,name nil nil nil ,filter-defun-name nil)))))

(make-ace-jump-buffer-function "same-mode"
  (let ((current-mode major-mode))
    (with-current-buffer buffer
      (not (eq major-mode current-mode)))))

(when (require 'perspective nil 'noerror)
  (make-ace-jump-buffer-function "persp"
    (with-current-buffer buffer
      (not (member buffer (persp-buffers persp-curr))))))

(when (require 'persp-mode nil 'noerror)
  (make-ace-jump-buffer-function "persp"
    (with-current-buffer buffer
      (not (memq buffer (persp-buffer-list))))))

(when (require 'projectile nil 'noerror)
  (make-ace-jump-buffer-function "projectile"
    (let ((project-root (projectile-project-root)))
      (with-current-buffer buffer
        (not (projectile-project-buffer-p buffer project-root))))))

(provide 'ace-jump-buffer)
;;; ace-jump-buffer.el ends here
