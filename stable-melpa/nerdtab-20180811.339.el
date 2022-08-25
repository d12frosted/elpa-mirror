;;; nerdtab.el --- Keyboard-oriented tabs

;; Copyright (C) 2018 Yuan Fu

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; Author: Yuan Fu <casouri@gmail.com>
;; URL: https://github.com/casouri/nerdtab
;; Package-Version: 20180811.339
;; Package-Commit: 601d531fa3748db733fbdff157a0f1cdf8a66416
;; Version: 1.2.3
;; Keywords: convenience
;; Package-Requires: ((emacs "24.5"))


;;; Commentary:
;;
;; This package gives you tabs.
;; But instead of the normal GUI tabs you might think of,
;; it provides a more keyboard-oriented (and visually inadequate) tabs.
;; You can jump to a specific buffer by `nerdtab-jump-<number>'
;; or by clicking the tab.
  
;; `nerdtab-mode' is a global minor mode.
;; Turn it on and it will open a side window and display buffers as tabs for you.

;; Checkout homepage for more information on usage and customizations.
  
;; Note that `nerdtab--' means private, `nerdtab-' means public / customizable (for variables)


;;; Code:

(require 'subr-x)

;;
;; Customizations
;;

(defgroup nerdtab nil
  "Customizations of nerdtab."
  :prefix "nerdtab-"
  :group 'files)

(defcustom nerdtab-window-position 'left
  "The position of nerdtab window."
  :group 'nerdtab
  :type '(choice (const left)
                 (const right)
                 (const top)
                 (const bottom)))

(defcustom nerdtab-mode-line-format nil
  "Mode-line format of nerdtab buffer."
  :group 'nerdtab
  :type 'plist)

(defcustom nerdtab-tab-width 15
  "Width of nerdtab tab."
  :group 'nerdtab
  :type 'number)

(defcustom nerdtab-tab-height 1
  "Height of tabs if `nerdtab-window-position' is 'top or 'bottom."
  :group 'nerdtab
  :type 'number)

(defcustom nerdtab-max-tab-vertical 50
  "Maximum number of tabs when displayed vertically."
  :group 'nerdtab
  :type 'number)

(defcustom nerdtab-max-tab-horizontal 20
  "Maximum number of tabs when displayed horizontally."
  :group 'nerdtab
  :type 'number)

(defcustom nerdtab-regex-blacklist '("\\*.*\\*" "^magit.*" "COMMIT_EDITMSG")
  "The regex blacklist of buffer names.
Nerdtab does not list buffers that match any regex in this blacklist."
  :group 'nerdtab
  :type 'sexp)

(defcustom nerdtab-update-interval 2
  "Nerdtab checkes if it needs to update tab list in every this seconds."
  :group 'nerdtab
  :type 'number)

(defcustom nerdtab-buffer-list-func #'buffer-list
  "The function that provides a list of buffers to nerdtab.
Change it to =projectile-project-buffers=
to intergrate with projectile (not tested)"
  :group 'nerdtab
  :type 'function)

;;
;; Variables
;;

(defface nerdtab-tab-face
  '((t (:inherit 'default)))
  "Face of tabs in nerdtab buffer."
  :group 'nerdtab)

(defface nerdtab-current-tab-face
  '((t (:inherit 'highlight)))
  "Face of current tab in nerdtab buffer."
  :group 'nerdtab)

(defface nerdtab-tab-mouse-face
  '((t (:inherit 'highlight)))
  "Face of tabs under mouse in nerdtab buffer."
  :group 'nerdtab)

(defvar nerdtab--tab-list ()
  "A list of tabs.
Each tab is of form: (buffer-display-name buffer).
buffer-display-name is turncated if too long, so don't depend on it.
buffer is a buffer object,
for simplicity it can only be a buffer object,
not a string of buffer name.

Also note that the order of buffers in `nerdtab--tab-list'
does not nessesarily match that in (buffer-list).

Because that order in (buffer-list) changes all the time,
and I want my tab list to be more stable.
So user can expect the index of a tab to not change very often.

`nerdtab-full-refresh' syncs both list.")

(defvar nerdtab--window nil
  "Nerdtab window.")

(defvar nerdtab--buffer nil
  "Nerdtab buffer.")

(defvar nerdtab-buffer-name " *nerdtab*"
  "Name of nerdtab buffer.")

(defvar nerdtab--do-update nil
  "If non-nil, nerdtab will update tab list in next cycle.
Time interval between to cycle is defined by `nerdtab-update-interval'.")

(defvar nerdtab-open-func #'switch-to-buffer
  "The function to open buffer.
Used in tab button and `nerdtab-jump-xx' functions.

The function should take a single buffer as argument.")

(defvar nerdtab--last-buffer nil
  "Last buffer. Used to compare against current buffer to see if buffer changed.")

;;
;; Modes
;;

(define-derived-mode nerdtab-major-mode special-mode
  "NerdTab")

;;;###autoload
(define-minor-mode nerdtab-mode
  "A global minor mode that provide tabs and activly update tab list."
  :global t
  :require 'nerdtab
  (if nerdtab-mode
      (progn
        (nerdtab--show-ui)
        (nerdtab-full-refresh)
        (add-hook 'post-command-hook #'nerdtab--active-update))
    (remove-hook 'post-command-hook #'nerdtab--active-update)
    (kill-buffer nerdtab--buffer)
    (setq nerdtab--buffer nil)
    (when (window-live-p nerdtab--window)
      (delete-window nerdtab--window))
    (setq nerdtab--window nil)))

;;
;; Functions -- sort of inverse hiearchy, the final function that calls everyone else is in the bottom.
;;

(defun nerdtab--open-buffer (buffer)
  "Open BUFFER.
This function is bound to tab buttons."
  (select-window (get-buffer-window nerdtab--last-buffer))
  (switch-to-buffer buffer))

(defun nerdtab--make-tab (buffer)
  "Make a tab from BUFFER."
  `(,(nerdtab-turncate-buffer-name (buffer-name buffer))
    ,buffer))

(defmacro nerdtab--h-this-v-that| (this that)
  "Do THIS is nerdtad is horizontal, THAT if vertical.
The macro checks `nerdtab-window-position',
and only check it against 'top and 'bottom,
it assumes other case means vertical.

THIS and THAT have to ba lists of sexps to be evaluate."
  `(if (member nerdtab-window-position '(top bottom)) ; horizontal
      ,@this
    ,@that))

(defun nerdtab--get-buffer-or-create ()
  "Get nerdtab buffer, create one if not exist."
  (get-buffer-create nerdtab-buffer-name))

(defun nerdtab-turncate-buffer-name (buffer-name)
  "Make sure BUFFER-NAME is short enough."
  (let ((max-width (- nerdtab-tab-width 3))
        (name-length (length buffer-name)))
    (if (< name-length max-width)
        buffer-name
      (format "%s.." (substring buffer-name 0 (- max-width 3))))))

(defun nerdtab--if-valid-buffer (buffer)
  "Check if BUFFER is suitable for a tab.
If yes, return t, otherwise return nil."
  (let ((black-regex (string-join nerdtab-regex-blacklist "\\|")))
    (if (and (not (equal black-regex "")) (string-match black-regex (buffer-name buffer)))
        nil
      t)))

(defun nerdtab--show-ui ()
  "Get nerdtab window and buffer displayed.
This function makes sure both buffer and window are present."
  (let ((original-window (selected-window)))
    (unless (window-live-p nerdtab--window)
      (setq nerdtab--buffer (nerdtab--get-buffer-or-create))
      (select-window
       (setq nerdtab--window
             (display-buffer-in-side-window
              nerdtab--buffer
              `((side . ,nerdtab-window-position)
                ,(nerdtab--h-this-v-that|
                  (`(window-height . ,nerdtab-tab-height))
                  (`(window-width . ,nerdtab-tab-width)))))))
      (switch-to-buffer nerdtab--buffer)
      (nerdtab-major-mode)
      (setq mode-line-format nerdtab-mode-line-format)
      (nerdtab--h-this-v-that|
       ((setq-local line-spacing 3))
       ((setq-local line-spacing 3)))
      (when (featurep 'linum) (linum-mode -1))
      (when (featurep 'nlinum) (nlinum-mode -1))
      (when (featurep 'display-line-numbers) (display-line-numbers-mode -1))
      (select-window original-window))))

(defun nerdtab--draw-tab (tab index &optional current-buffer)
  "Draw a single TAB, marked with INDEX, as a button in current buffer.
CURRENT-BUFFER will be highlighted.
This function doesn't insert newline.
The button lookes like: 1 *Help*.
\"1\" is the index."
  (let* ((tab-name (car tab))
        (buffer (nth 1 tab))
        (tab-face (if (eq buffer current-buffer)
                      'nerdtab-current-tab-face
                    'nerdtab-tab-face)))
    (insert-text-button (format "%d %s" index tab-name)
                        'keymap
                        (let ((keymap (make-sparse-keymap)))
                          (define-key keymap [mouse-2]
                            `(lambda ()
                               (interactive)
                               (nerdtab--open-buffer ,buffer)))
                          (define-key keymap [mouse-3]
                            `(lambda ()
                               (interactive)
                               (kill-buffer ,buffer)
                               (nerdtab-update)))
                          keymap)
                        'help-echo
                        (buffer-name buffer)
                        'follow-link
                        t
                        'face
                        tab-face
                        'mouse-face
                        'nerdtab-tab-mouse-face)))

(defun nerdtab--redraw-all-tab ()
  "Redraw every tab in `nerdtab-buffer'."
  (interactive)
  (let ((current-buffer (current-buffer)))
    (with-current-buffer nerdtab--buffer
      (setq buffer-read-only nil)
      (erase-buffer)
      (let ((index 0))
        (dolist (tab nerdtab--tab-list)
          (nerdtab--draw-tab tab index current-buffer)
          (setq index (1+ index))
          (insert (nerdtab--h-this-v-that| ("  ") ("\n"))))
        (goto-char 0))
      (setq buffer-read-only t)
      )))

(defun nerdtab--make-tab-list ()
  "Make a tab list from `nerdtab--tab-list'."
  (let ((tab-list ())
        (max-tab-num (nerdtab--h-this-v-that|
                  (nerdtab-max-tab-horizontal)
                  (nerdtab-max-tab-vertical)))
        (count 0))
    (catch 'max-num
      (dolist (buffer (funcall nerdtab-buffer-list-func))
        (when (nerdtab--if-valid-buffer buffer)
          (when (>= count max-tab-num)
            (throw 'max-num count))
          (setq count (1+ count))
          (push (nerdtab--make-tab buffer)
                tab-list))))
    tab-list))

(defun nerdtab--update-tab-list ()
  "Update nerdtab list upon buffer creation, rename, delete."
  (let ((new-list (nerdtab--make-tab-list))
        (old-list nerdtab--tab-list)
        (return-list ()))
    (dolist (old-tab old-list)
      (when (member old-tab new-list)
        (add-to-list 'return-list old-tab t)
        (delete old-tab new-list)))
    (dolist (remaining-new-tab new-list)
      (add-to-list 'return-list remaining-new-tab t))
    (setq nerdtab--tab-list return-list)))

(defun nerdtab-full-refresh ()
  "Refresh nerdtab buffer.
This function syncs tab list and list returned by `nerdtab-buffer-list-func',
which most likely will change the order of your tabs.
So don't use it too often."
  (interactive)
  (setq nerdtab--tab-list (nerdtab--make-tab-list))
  (nerdtab--show-ui)
  (nerdtab--redraw-all-tab))

(defun nerdtab-update ()
  "Update nerdtab tab list.
Similar to `nerdtab-full-refresh' but do not change the order of tabs."
  (nerdtab--show-ui)
  (nerdtab--update-tab-list)
  (nerdtab--redraw-all-tab)
  (nerdtab--update-next-cycle -1))

;;
;; Timer mode related functions
;;

(defun nerdtab--update-next-cycle (&optional do)
  "Make nerdtab update tab list on next cycle.
If DO is non-nil, make it not to."
  (setq nerdtab--do-update (not do)))

(defun nerdtab--timer-update ()
  "Update when needs to."
  (when nerdtab--do-update
    (nerdtab-update)))

;;
;; Active update mode related functions
;;

(defun nerdtab--active-update ()
  "Used in `nerdtab-active-mode'. Update tab list."
  (unless (or (string-match "Minibuf" (buffer-name))
              (string-match (format "^%s$" nerdtab-buffer-name) (buffer-name))
              (eq nerdtab--last-buffer (current-buffer)))
    (nerdtab-update)
    (setq nerdtab--last-buffer (current-buffer))))

;;
;; Commands
;;

(defun nerdtab-jump (index)
  "Jump to INDEX tab."
  (interactive "nIndex of tab: ")
  (switch-to-buffer (nth 1 (nth index nerdtab--tab-list))))

(defun define-nerdtab-jump-func (max)
  "Make `nerdtab-jump-n' functions from 1 to MAX."
  (dolist (index (number-sequence 0 max))
    (fset (intern (format "nerdtab-jump-%d" index))
          `(lambda () ,(format "Jump to %sth tab." index)
             (interactive)
             (nerdtab-jump ,index)))))

(define-nerdtab-jump-func 50)

(defun nerdtab-kill (index)
  "Kill the INDEX th buffer."
  (interactive "nIndex of tab: ")
  (kill-buffer (nth 1 (nth index nerdtab--tab-list)))
  (nerdtab-update))

(defun define-nerdtab-kill-func (max)
  "Make `nerdtab-kill-n' functions from 1 to MAX."
  (dolist (index (number-sequence 0 max))
    (fset (intern (format "nerdtab-kill-%d" index))
          `(lambda () ,(format "Kill the  %sth tab." index)
             (interactive)
             (nerdtab-kill ,index)))))

(define-nerdtab-kill-func 50)

(defun nerdtab-move-to (index)
  "Move current buffer's tab to INDEX th."
  (setf (nth index nerdtab--tab-list) (nerdtab--make-tab (current-buffer)))
  (delete-dups nerdtab--tab-list)
  (nerdtab-update))

(defun define-nerdtab-move-to-func (max)
  "Make `nerdtab-move-to-n' functions from 1 to MAX."
  (dolist (index (number-sequence 0 max))
    (fset (intern (format "nerdtab-move-to-%d" index))
          `(lambda () ,(format "Move current buffer's tab to  the  %sth." index)
             (interactive)
             (nerdtab-move-to ,index)))))

(define-nerdtab-move-to-func 50)


(defun nerdtab-change-window-posiion (position)
  "Change the window position to left/right/top/bottom base on POSITION(h/l/k/j)."
  (interactive "cPosition (h/j/k/l): ")
  (let ((position-symbol (pcase position
                           (?k 'top)
                           (?j 'bottom)
                           (?h 'left)
                           (?l 'right)
                           )))
    (setq nerdtab-window-position position-symbol)
    (delete-window nerdtab--window)
    (nerdtab--show-ui)))

(provide 'nerdtab)

;;; nerdtab.el ends here
