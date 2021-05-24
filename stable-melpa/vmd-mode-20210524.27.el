;;; vmd-mode.el --- Fast Github-flavored Markdown preview using a vmd subprocess.         -*- lexical-binding: t; -*-

;; Copyright (C) 2016 Blake Miller

;; Author: Blake Miller <blak3mill3r@gmail.com>
;; Version: 0.2.0
;; Package-Commit: b2bdf2ab54f8fc37780e6b473e4ad69c0e9ff4a6
;; Package-Version: 20210524.27
;; Package-X-Original-Version: 20161106.125
;; Keywords: markdown, preview, live, vmd
;; URL: https://github.com/blak3mill3r/vmd-mode
;; Package-Requires: ((emacs "24.3"))

;;; Commentary:

;; Realtime Markdown previews for Emacs, updates as the contents of the buffer
;; change.
;;
;; The rendered Markdown stays consistent with the markdown source in the
;; buffer, and performance is very good.

;;; Code:
(require 'json)                         ; use `json-read-object'

(defvar-local vmd-process nil
  "Handle to the inferior vmd process")

(defvar-local vmd-preview-file nil
  "Temp file which is watched by the vmd process")

(defvar-local vmd-copy-file nil)

(defgroup vmd nil
  "Fast Github-flavored Markdown preview using a vmd subprocess."
  :prefix "vmd-"
  :group 'text
  :group 'markdown)

(defcustom vmd-binary-path (executable-find "vmd")
  "Path to your vmd binary, or nil if vmd not available."
  :group 'vmd
  :type 'directory)


;; GitHub emojis

(defvar vmd-mode--emojis-file "./resources/emojis"
  "File containing emoji names.")

(defun vmd-mode--github-emojis ()
  "Get all GitHub emoji from the GitHub API.

The result is a list of emoji names, e.g. (\"+1\", \"-1\",
\"100\", ...).

See https://developer.github.com/v3/emojis/"
  (defvar url-http-end-of-headers)
  (let ((emoji-alist (with-current-buffer (url-retrieve-synchronously "https://api.github.com/emojis" t t)
                       (goto-char (1+ url-http-end-of-headers))
                       (json-read-object))))
    (mapcar #'symbol-name (mapcar #'car emoji-alist))))

(defun vmd-mode--update-emojis-file ()
  "Update emojis in ./resources/emojis."
  (with-temp-file vmd-mode--emojis-file
    (dolist (emoji (vmd-mode--github-emojis))
      (insert emoji)
      (insert "\n"))))

(defvar vmd-mode-github-emojis-list
  (and (file-exists-p vmd-mode--emojis-file)
       (with-temp-buffer
         (insert-file-contents vmd-mode--emojis-file)
         (split-string (buffer-string) "\n" t)))
  "Emoji for GitHub.")

(defun vmd-mode-start-vmd-process ()
  "Start an asynchronous `vmd' process to generate the temporary work file."
  ;; Work file name := current buffer file name and append ".temp" to it.
  (progn
    (setq vmd-copy-file (concat buffer-file-name ".temp"))
    (copy-file buffer-file-name vmd-copy-file "overwrite")
    (setq vmd-process (start-process "vmd" "vmd" vmd-binary-path vmd-copy-file))))

(defun vmd-mode-delete-temp (&rest _args)
  "Cleanup when buffer is killed."
  (progn (message "VMD-Mode deleting file: %s" vmd-copy-file)
         (if (file-exists-p vmd-copy-file)
             (delete-file vmd-copy-file))
         (message "VMD-Mode removing hook: 'kill-buffer-hook")
         (remove-hook 'kill-buffer-hook (function vmd-mode-delete-temp) t)
         (message "VMD-Mode removing hook: 'after-change-functions")
         (remove-hook 'after-change-functions (function vmd-mode-refresh) t)
         (if vmd-process
             (progn
               (delete-process vmd-process)
               (message "VMD-Mode deleted: vmd-process")))))

(defun vmd-mode-refresh (&rest _args)
  "Update the `vmd-preview-file'.
The optional ARGS argument is needed as this function is added to the
`after-change-functions' hook."
  (write-region (point-min) (point-max) vmd-copy-file nil 'quiet))

;;;###autoload
(define-minor-mode vmd-mode
  "Live Markdown preview with `vmd'."
  :lighter " vmd"
  (when vmd-mode
      (if vmd-binary-path
          (progn
            (add-hook 'after-change-functions (function vmd-mode-refresh) nil t)
            (add-hook 'kill-buffer-hook (function vmd-mode-delete-temp) nil t)
            (vmd-mode-start-vmd-process)
            (vmd-mode-refresh))
        (user-error "You need to have `vmd' installed in your environment PATH"))))

(provide 'vmd-mode)

;;; vmd-mode.el ends here
