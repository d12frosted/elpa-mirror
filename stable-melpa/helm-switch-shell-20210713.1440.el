;;; helm-switch-shell.el --- A Helm source for switching between shell buffers -*- lexical-binding: t -*-

;; Copyright (C) 2019 James Cash

;; Author: James N. V. Cash <james.cash@occasionallycogent.com>
;; URL: https://github.com/jamesnvc/helm-switch-shell
;; Package-Version: 20210713.1440
;; Package-Commit: 8d7ba1d99ff12a8f1d6ce3b9684ae8aebf494cf3
;; Package-Requires: ((emacs "25.1") (helm "2.8.8"))
;; Version: 1.0
;; Keywords: matching, processes, terminals, tools

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;;; License

;; GPL 3.0+

;;; Commentary:

;; This package offers a helm-source for switching between shells via
;; helm, sorting them by how their working directory is to your
;; current active directory.

;; It’s especially convienent to make a key binding for this, e.g.
;; (global-set-key (kbd "<f3>") #'helm-switch-shell)

;; It show a list of the shell-mode and eshell-mode shells you have
;; open by their current directory, sorted by how close they are to
;; the directory you’re currently in.

;; You can switch to one of those buffers, or type the name of a new
;; directory to create a shell there (defaulting to your current
;; directory).

;; By default, new shells are created with eshell. You can customize
;; this by setting helm-switch-shell-new-shell-type to be shell, in
;; which case new shells will be created with shell, or vterm, in
;; which case they will be created with vterm (if the emacs-libvterm
;; package is installed).

;; It provides the following keybindings by default:
;; C-s: open the indicated shell in horizontal split (split-window-below)
;; C-v: open the indicated shell in a vertical split (split-window-right)

;; Other options for customization:
;;
;;   helm-switch-shell-truncate-lines: set to non-nil to truncate candidates
;;   helm-switch-shell-show-shell-indicator: set to non-nil to show an
;;   indicator of what kind of shell the candidate is in the list
;;   (e.g. [V] for vterm, [E] for eshell, etc)

;; Faces:
;;
;;   helm-switch-shell-buffer-name-face: Face for the candidate buffer name
;;   helm-switch-shell-indicator-face: Face for the candidate indicator type
;;   helm-switch-shell-path-face: Face for the candidate path name
;;   helm-switch-shell-new-shell-face: Face for the [+] new shell indicator

;;; Code:

(require 'cl-lib)
(require 'helm)
(require 'helm-lib)
(require 'subr-x)

;; Customization

(defgroup helm-switch-shell nil
  "Group for `helm-switch-shell' customizations"
  :group 'helm)

(defcustom helm-switch-shell-new-shell-type 'eshell
  "When creating a new shell, should it be eshell (default), shell, or vterm."
  :type '(radio (const :tag "eshell" eshell)
                (const :tag "shell" shell)
                (const :tag "vterm" vterm))
  :group 'helm-switch-shell)

(defcustom helm-switch-shell-truncate-lines t
  "Truncate lines in `helm-switch-shell' when non-nil."
  :group 'helm-switch-shell
  :type 'boolean)

(defcustom helm-switch-shell-show-shell-indicator t
  "When non-nil, show indicator of what type of shell (e.g. [E] for eshell, [V] for vterm, etc) each candidate is in `helm-switch-shell'."
  :group 'helm-switch-shell
  :type 'boolean)

;; Faces

(defface helm-switch-shell-new-shell-face
  '((t :background "#ff69c6" :foreground "#282a36"))
  "Face for the [+] indicator for creating a new shell."
  :group 'helm-switch-shell)

(defface helm-switch-shell-indicator-face
  '((t :inherit font-lock-buildin-face))
  "Face for the candidate type indicator (e.g. [V], [E], etc)."
  :group 'helm-switch-shell)

(defface helm-switch-shell-buffer-name-face
  '((t :inherit font-lock-comment-face))
  "Face for the candidate buffer name."
  :group 'helm-switch-shell)

(defface helm-switch-shell-path-face
  '((t :inherit font-lock-keyword-face))
  "Face for the candidate path."
  :group 'helm-switch-shell)

;; Helpers

(defun helm-switch-shell--pwd-replace-home (directory)
  "Replace $HOME in DIRECTORY with tilde character."
  (let ((home (expand-file-name (getenv "HOME"))))
    (if (string-prefix-p home directory)
        (concat "~" (substring directory (length home)))
      directory)))

(defun helm-switch-shell--candidate-name (buf)
  "Display the directory of BUF, with HOME replaced with tilde."
  (let ((buffer-mode (buffer-local-value 'major-mode buf)))
    (when (cl-member buffer-mode '("eshell-mode" "shell-mode" "vterm-mode")
                     :test #'string=)
      (list
       (cons 'indicator
             (concat
              "["
              (string (upcase (string-to-char (symbol-name buffer-mode))))
              "] ") )
       (cons 'buffer-name (buffer-name buf))
       (cons 'path (helm-switch-shell--pwd-replace-home (buffer-local-value 'default-directory buf)))))))

(defun helm-switch-shell--new-shell ()
  "Create a new shell."
  (shell (generate-new-buffer-name "*shell*")))

(defun helm-switch-shell--shell-select ()
  "Switch to a new shell, prompting for the shell to run."
  (let* ((default-shell (or (getenv "SHELL") "/bin/bash"))
         (explicit-shell-file-name (read-file-name "Shell: " (file-name-directory default-shell) default-shell)))
    (helm-switch-shell--new-shell)))

(defun helm-switch-shell--create-new (&optional type)
  "Create a new shell or eshell, as optionally specified by TYPE, defaulting to `helm-switch-shell-new-shell-type'."
  (cl-case (or type helm-switch-shell-new-shell-type)
    (eshell (eshell t))
    (shell (helm-switch-shell--new-shell))
    (vterm (if (fboundp 'vterm)
               (vterm t)
             (message "emacs-libvterm not installed")))
    (shell-select (helm-switch-shell--shell-select))))

;; Switching shells

(defun helm-switch-shell--get-candidates ()
  "Get existing shell/eshell buffers as well as a potential new shell location for the ‘helm-switch-shell’ source."
  (let* ((here (expand-file-name default-directory))
         (dist2here (lambda (d)
                      (let* ((d (replace-regexp-in-string "^\\[[ETV]\\] " "" d))
                             (prefix (compare-strings
                                      here 0 nil
                                      (expand-file-name d) 0 nil))
                             (prefix-len (if (numberp prefix)
                                             (- (abs prefix) 1)
                                           (length d))))
                        (thread-first (substring here 0 prefix-len)
                          (split-string "/")
                          (length)
                          (+ (if (numberp prefix) 0 2))))))
         (shells (cl-loop for buf being the buffers
                          when (helm-switch-shell--candidate-name buf)
                          collect (cons it buf) into cands
                          and maximize (length (buffer-name buf)) into len-names
                          finally return (cons len-names
                                               (thread-first cands
                                                 (sort (lambda (a b) (< (length (alist-get 'path (car a)))
                                                                   (length (alist-get 'path (car b))))))
                                                 (sort
                                                  (lambda (a b) (> (funcall dist2here (alist-get 'path (car a)))
                                                              (funcall dist2here (alist-get 'path (car b))))))))))
         (candidates (cl-loop with max-len = (car shells)
                              for cand-buf in (cdr shells)
                              for cand = (car cand-buf)
                              for buf = (cdr cand-buf)
                              collect (cons (concat
                                             (when helm-switch-shell-show-shell-indicator
                                               (propertize
                                                (alist-get 'indicator cand)
                                                'face 'helm-switch-shell-indicator-face))
                                             (propertize
                                              (alist-get 'buffer-name cand)
                                              'face 'helm-switch-shell-buffer-name-face)
                                             (make-string
                                              (- (+ 2 max-len)
                                                 (string-width (alist-get 'buffer-name cand)))
                                              ? )
                                             (propertize
                                              (alist-get 'path cand)
                                              'face 'helm-switch-shell-path-face))
                                            buf)
                              into cands
                              finally return cands))
         (new-dir (if (string-blank-p helm-input)
                      default-directory
                    helm-input))
         (new-shell (cons (concat
                           (propertize
                            " " 'display
                            (propertize "[+]" 'face 'helm-switch-shell-new-shell-face))
                           " "
                           (helm-switch-shell--pwd-replace-home new-dir))
                          new-dir)))
    (cons new-shell candidates)))

(defun helm-switch-shell--move-to-first-real-candidate ()
  "Move the helm selection down to the first that's actually a buffer."
  (let ((sel (helm-get-selection nil nil (helm-get-current-source))))
    (unless (bufferp sel)
      (helm-next-line))))

(defun helm-switch-shell--open-split (splitf candidate)
  "Open CANDIDATE in a new split using the window splitting function SPLITF."
  (if (bufferp candidate)
      (progn
        (select-window (funcall splitf))
        (switch-to-buffer candidate))
    (let ((default-directory candidate)
          (display-buffer-alist '(("\\`\\*e?shell" display-buffer-same-window))))
      (select-window (funcall splitf))
      (helm-switch-shell--create-new)
      (balance-windows))))

(defun helm-switch-shell--horiz-split (candidate)
  "Open CANDIDATE in a horizontal split."
  (helm-switch-shell--open-split #'split-window-below candidate))

(defun helm-switch-shell--vert-split (candidate)
  "Open CANDIDATE in a vertical split."
  (helm-switch-shell--open-split #'split-window-right candidate))

(defun helm-switch-shell--horiz-split-command ()
  "Helm command that opens shell in a horizontal split."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action #'helm-switch-shell--horiz-split)))

(defun helm-switch-shell--vert-split-command ()
  "Helm command that opens shell in a vertical split."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action #'helm-switch-shell--vert-split)))

(defconst helm-switch-shell-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map helm-map)
    (define-key map (kbd "C-s") #'helm-switch-shell--horiz-split-command)
    (define-key map (kbd "C-v") #'helm-switch-shell--vert-split-command)
    map)
  "Keymap for `helm-switch-shell'.")

(defconst helm-switch-shell--source
  (helm-build-sync-source "shell-switcher"
    :keymap helm-switch-shell-map
    :candidates #'helm-switch-shell--get-candidates
    :action (helm-make-actions
             "Switch to shell"
             (lambda (candidate)
               (if (bufferp candidate)
                   (switch-to-buffer candidate)
                 (let ((default-directory candidate))
                   (helm-switch-shell--create-new))))

             "Create in eshell"
             (lambda (candidate)
               (let ((default-directory (if (bufferp candidate)
                                            (buffer-local-value 'default-directory candidate)
                                          candidate)))
                 (helm-switch-shell--create-new 'eshell)))

             "Create in shell"
             (lambda (candidate)
               (let ((default-directory (if (bufferp candidate)
                                            (buffer-local-value 'default-directory candidate)
                                          candidate)))
                 (helm-switch-shell--create-new 'shell)))

             "Create in vterm"
             (lambda (candidate)
               (let ((default-directory (if (bufferp candidate)
                                            (buffer-local-value 'default-directory candidate)
                                          candidate)))
                 (helm-switch-shell--create-new 'vterm)))

             "Create in shell (choose shell)"
             (lambda (candidate)
               (let ((default-directory (if (bufferp candidate)
                                            (buffer-local-value 'default-directory candidate)
                                          candidate)))
                 (helm-switch-shell--create-new 'shell-select)))

             (substitute-command-keys
               "Open shell in horizontal split `\\<helm-switch-shell-map>\\[helm-switch-shell--horiz-split-command]'")
             #'helm-switch-shell--horiz-split

             (substitute-command-keys
               "Open shell in vertical split `\\<helm-switch-shell-map>\\[helm-switch-shell--vert-split-command]'")
             #'helm-switch-shell--vert-split)
    :volatile t
    :cleanup
    (lambda ()
      (remove-hook 'helm-after-update-hook
                   #'helm-switch-shell--move-to-first-real-candidate)))
  "Helm source to switch between shells.")

;;;###autoload
(defun helm-switch-shell ()
  "Switch between or create shell/eshell buffers using helm.

\\<helm-switch-shell-map>\\[helm-switch-shell--horiz-split-command] to open in a horizontal split.
\\<helm-switch-shell-map>\\[helm-switch-shell--vert-split-command] to open in a vertical split."
  (interactive)
  (add-hook 'helm-after-update-hook
            #'helm-switch-shell--move-to-first-real-candidate)
  (helm :sources helm-switch-shell--source
        :buffer "*helm shell*"
        :prompt "shell in: "
        :truncate-lines helm-switch-shell-truncate-lines))

(provide 'helm-switch-shell)
;;; helm-switch-shell.el ends here
