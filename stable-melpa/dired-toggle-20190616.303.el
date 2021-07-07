;;; dired-toggle.el --- Show dired as sidebar and will not create new buffers when changing dir
;;
;; Copyright (C) 2013, Xu FaSheng
;;
;; Author: Xu FaSheng <fasheng[AT]fasheng.info>
;; Maintainer: Xu FaSheng
;; Version: 0.1
;; Package-Version: 20190616.303
;; Package-Commit: 7fe5fe35c63d1b0da14d6d6d52bdf6b2a5410ba7
;; URL: https://github.com/fasheng/dired-toggle
;; Keywords: dired, sidebar
;; Compatibility: GNU Emacs: 24.x
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;; Description:
;;
;; `dired-toggle' command could toggle to show dired buffer as a
;; sidebar for current directory(similar to `dired-sidebar', but more
;; lightweight). The sidebar buffer also enabled a minor mode named
;; `dired-toggle-mode', and it only contains one buffer instance,
;; change directories in it will not create news buffers.
;;
;; Usage:
;;
;; (use-package dired-toggle
;;   :defer t
;;   :bind (("<f3>" . #'dired-toggle)
;;          :map dired-mode-map
;;          ("q" . #'dired-toggle-quit)
;;          ([remap dired-find-file] . #'dired-toggle-find-file)
;;          ([remap dired-up-directory] . #'dired-toggle-up-directory)
;;          ("C-c C-u" . #'dired-toggle-up-directory))
;;   :config
;;   (setq dired-toggle-window-size 32)
;;   (setq dired-toggle-window-side 'left)

;;   ;; Optional, enable =visual-line-mode= for our narrow dired buffer:
;;   (add-hook 'dired-toggle-mode-hook
;;             (lambda () (interactive)
;;               (visual-line-mode 1)
;;               (setq-local visual-line-fringe-indicators '(nil right-curly-arrow))
;;               (setq-local word-wrap nil))))
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(require 'dired)

(defvar dired-toggle-buffer-name "*Dired Toggle*"
  "Target buffer name for `dired-toggle'.")

(defvar dired-toggle-window-size 24
  "Target window size for `dired-toggle'.")

(defvar dired-toggle-window-side 'left
  "Target window's place side for `dired-toggle', could be 'left, 'right,
'below or 'above, more information to see `split-window'.")

(defvar dired-toggle-modeline-lighter " DiredTog"
  "Modeline lighter for `dired-toggle-mode'.")

(defvar-local dired-toggle-refwin nil
  "Mark the referred window that jumping from.")

(defvar dired-toggle-dired-mode-name 'dired-mode
  "Setup the default dired mode working with `dired-toggle-mode'.")

(defun dired-toggle-list-dir (buffer dir &optional mode)
  "List target directory in a buffer."
  (let ((mode (or mode dired-toggle-dired-mode-name)))
    (with-current-buffer buffer
      (setq default-directory dir)
      (if (eq mode major-mode)
          (setq dired-directory dir)
        (funcall mode dir))
      (dired-toggle-mode 1)
      ;; default-directory and dired-actual-switches are set now
      ;; (buffer-local), so we can call dired-readin:
      (unwind-protect
          (progn (dired-readin))))))

;;;###autoload
(defun dired-toggle-quit ()
  "Quit action under `dired-toggle-mode'."
  (interactive)
  (if (one-window-p)
      (quit-window)
    (delete-window)))

;;;###autoload
(defun dired-toggle-find-file ()
  "Wraper for `dired-find-file', use `find-alternate-file' instead so will not
create new buffer when changing directory, and will keep `dired-toggle-mode' and
`dired-hide-details-mode' states after opening new direcoty."
  (interactive)
  (let* ((dired-toggle-enabled (if dired-toggle-mode 1 0))
         (dired-hide-details-enabled (if dired-hide-details-mode 1 0))
         (buffer (current-buffer))
         (file (dired-get-file-for-visit))
         (dir-p (file-directory-p file)))
    (if dir-p                           ;open a directory
        ;; (dired-toggle-list-dir buffer (file-name-as-directory file))
        (find-alternate-file file)
      ;; open a file, and delete the referred window firstly
      (if (and (window-live-p dired-toggle-refwin)
               (not (window-minibuffer-p dired-toggle-refwin))
               ;; Some times `dired-toggle-refwin' maybe dired-toggle
               ;; window itself, so just ignore it.
               (not (equal (selected-window) dired-toggle-refwin)))
          (delete-window dired-toggle-refwin))
      (dired-find-file))
    (when (eq major-mode 'dired-mode)
      (dired-toggle-mode dired-toggle-enabled)
      (dired-hide-details-mode dired-hide-details-enabled))))

;;;###autoload
(defun dired-toggle-up-directory ()
  "Wraper for `dired-up-directory', use `find-alternate-file' instead so will
not create new buffer when changing directory, and will keep `dired-toggle-mode'
and `dired-hide-details-mode' states after opening new direcoty."
  (interactive)
  (let* ((dired-toggle-enabled (if dired-toggle-mode 1 0))
         (dired-hide-details-enabled (if dired-hide-details-mode 1 0))
         (dir (dired-current-directory))
         (up (file-name-directory (directory-file-name dir))))
    (or (dired-goto-file (directory-file-name dir))
        ;; Only try dired-goto-subdir if buffer has more than one dir.
        (and (cdr dired-subdir-alist)
             (dired-goto-subdir up))
        (progn
          (set-buffer-modified-p nil)
          (find-alternate-file "..")
          (dired-goto-file dir)))
    (when (eq major-mode 'dired-mode)
      (dired-toggle-mode dired-toggle-enabled)
      (dired-hide-details-mode dired-hide-details-enabled))))

(defvar dired-toggle-mode-map (make-sparse-keymap)
  "Keymap for `dired-toggle-mode'.")

(defvar dired-toggle-mode-hook nil
  "Function(s) to call after `dired-toggle-mode' enabled.")

(define-minor-mode dired-toggle-mode
  "Assistant minor mode for `dired-toggle'."
  :lighter dired-toggle-modeline-lighter
  :keymap dired-toggle-mode-map
  :after-hook dired-toggle-mode-hook)

(defun dired-toggle--get-window ()
  "Get the dired-toggle window."
  (let* (target-window)
    (dolist (w (window-list))
      (when (and (window-live-p w) (buffer-live-p (window-buffer w)))
        (with-current-buffer (window-buffer w)
          (when (bound-and-true-p dired-toggle-mode)
            (setq target-window w)))))
    target-window))

(defun dired-toggle--do (&optional dir file)
  "Toggle current buffer's directory.
DIR is the target direcoty, FILE is the file to be selected."
  (let* ((file (or file (buffer-file-name)))
         (dir (or dir (if file (file-name-directory file) default-directory)))
         (win (frame-root-window))
         (buf (buffer-name))
         (size dired-toggle-window-size)
         (side dired-toggle-window-side)
         (target-bufname dired-toggle-buffer-name)
         (target-buf (get-buffer-create target-bufname))
         (target-window (dired-toggle--get-window))
         (dired-buffer-with-same-dir (dired-find-buffer-nocreate dir))
         (new-dired-buffer-p
          (or (not dired-buffer-with-same-dir)
              (not (string= target-bufname
                            (buffer-name dired-buffer-with-same-dir))))))
    (if target-window            ;hide window if target buffer is shown
        (if (one-window-p)
            (quit-window)
          (delete-window target-window))
      ;; Else show target buffer in a side window
      (progn
        (setq target-window (split-window win (- size) side))
        (select-window target-window)
        (switch-to-buffer target-buf)
        ;; init dired-mode
        (if new-dired-buffer-p
            (dired-toggle-list-dir target-buf dir))
        (with-current-buffer target-buf
          (dired-hide-details-mode 1)
          ;; TODO mark the referred window that jumping from
          (setq-local dired-toggle-refwin win)
          ;; try to select target file
          (if file
              (or (dired-goto-file file)
                  ;; toggle off omit mode if is on, and try to select file again
                  (when (and (boundp 'dired-omit-mode) dired-omit-mode)
                    (dired-omit-mode 0)
                    (or (dired-goto-file file)
                        ;; restore omit mode if could not select file again
                        (dired-omit-mode 1)))))
          ;; if cursor at begin of buffer, select the first item
          (if (eq (point) 1)
              (dired-next-line 1)))))))

;;;###autoload
(defun dired-toggle (&optional prefix)
  "Toggle current buffer's directory."
  (interactive "P")
  (if prefix
      (dired-toggle-project-root)
    (dired-toggle--do)))

;;;###autoload
(defun dired-toggle-project-root (&optional prefix)
  "Toggle current project root directory."
  (interactive "P")
  (if prefix
      (dired-toggle--do)
    (let* ((dir (cdr (project-current 'prompt))))
      (dired-toggle--do dir))))

(provide 'dired-toggle)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; dired-toggle.el ends here
