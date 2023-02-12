;;; ivy-explorer.el --- Dynamic file browsing grid using ivy  -*- lexical-binding: t; -*-

;; Copyright (C) 2018-2019  Free Software Foundation, Inc.

;; Author: Clemens Radermacher <clemera@posteo.net>
;; URL: https://github.com/clemera/ivy-explorer
;; Package-Version: 20190909.1921
;; Package-Commit: a413966cfbcecacc082d99297fa1abde0c10d3f3
;; Version: 0.3.2
;; Package-Requires: ((emacs "25") (ivy "0.10.0"))
;; Keywords: convenience, files, matching

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Provides a large more easily readable grid for file browsing using
;; `ivy'. When `avy' is installed, commands for fast avy navigation
;; are available to the user, as well. Heavily inspired by
;; LustyExplorer:
;;
;; https://www.emacswiki.org/emacs/LustyExplorer
;;
;; Known Bugs:
;;
;; When the number of candidates don't fit into the ivy-explorer
;; window, moving down along the grid can change the order of elements
;; when new candidates get displayed. This can change the column the
;; user is currently in while moving vertically down or up. Although
;; this is a bit confusing the correct candidate gets selected.
;; Patches welcome!
;;
;;; Code:


(require 'ivy)

(defgroup ivy-explorer nil
  "Dynamic file browsing grid using ivy."
  :group 'ivy
  :group 'files)

(defcustom ivy-explorer-enable-counsel-explorer t
  "If non-nil remap `find-file' to `counsel-explorer'.

This will also override remappings of function/`counsel-mode' for
`find-file' (`counsel-find-file').

This variable has to be (un)set before loading `ivy-explorer' to
take effect."
  :group 'ivy-explorer
  :type 'boolean)

(defcustom ivy-explorer-use-separator t
  "Whether to draw a line as separator.

Line is drawn between the ivy explorer window and the Echo Area."
  :group 'ivy-explorer
  :type 'boolean)

(defcustom ivy-explorer-max-columns 5
  "If given the maximal number of columns to use.

If the grid does not fit on the screen the number of columns is
adjusted to a lower number automatically."
  :group 'ivy-explorer
  :type 'integer)

(defcustom ivy-explorer-width (frame-width)
  "Width used to display the grid."
  :type 'integer)

(defcustom ivy-explorer-max-function #'ivy-explorer-max
  "Function which should return max number of canidates."
  :group 'ivy-explorer
  :type 'function)

(defcustom ivy-explorer-message-function #'ivy-explorer--lv-message
  "Function to be used for grid display.

By default you can choose between `ivy-explorer--posframe' and
`ivy-explorer--lv-message'."
  :group 'ivy-explorer
  :type 'function)

(defcustom ivy-explorer-height ivy-height
  "Height used if `ivy-explorer-message-function' has no dynamic height."
  :type 'integer)

(defcustom ivy-explorer-auto-init-avy nil
  "Whether to load grid views with avy selection enabled by default."
  :group 'ivy-explorer
  :type 'boolean)

(defcustom ivy-explorer-avy-handler-alist
  (list (cons #'ivy-explorer--lv-message
              #'ivy-explorer-avy-default-handler)
        (cons #'ivy-explorer--posframe
              #'ivy-explorer-avy-posframe-handler))
  "Alist which maps message functions to avy handlers.

The message functions are the candidates for
`ivy-explorer-message-function'. When avy selection command is
invoked the corresponding handler gets used."
  :type '(alist :key-type function
                :value-type function))

(defface ivy-explorer-separator
  (if (featurep 'lv)
      '((t (:inherit lv-separator)))
    '((t (:inherit border))))
  "Face used to draw line between the ivy-explorer window and the echo area.
This is only used if option `ivy-explorer-use-separator' is non-nil.
Only the background color is significant."
  :group 'ivy-explorer)


(defvar ivy-explorer-map
  (let ((map (make-sparse-keymap)))
    (prog1 map
      (define-key map (kbd "DEL") 'ivy-explorer-backward-delete-char)
      (define-key map (kbd "C-j") 'ivy-explorer-alt-done)
      (define-key map (kbd "C-x d") 'ivy-explorer-dired)

      (define-key map (kbd "C-x o") 'ivy-explorer-other-window)
      (define-key map (kbd "'") 'ivy-explorer-other-window)

      (define-key map (kbd "M-o") 'ivy-explorer-dispatching-done)
      (define-key map (kbd "C-'") 'ivy-explorer-avy)
      (define-key map (kbd ",") 'ivy-explorer-avy)
      (define-key map (kbd ";") 'ivy-explorer-avy-dispatch)
      ;; TODO: create C-o ivy-explorer-hydra
      (define-key map (kbd "C-f") 'ivy-explorer-forward)
      (define-key map (kbd "C-b") 'ivy-explorer-backward)
      (define-key map (kbd "C-M-f") 'ivy-explorer-forward-and-call)
      (define-key map (kbd "C-M-b") 'ivy-explorer-backward-and-call)

      (define-key map (kbd "C-a") 'ivy-explorer-bol)
      (define-key map (kbd "C-e") 'ivy-explorer-eol)
      (define-key map (kbd "C-M-a") 'ivy-explorer-bol-and-call)
      (define-key map (kbd "C-M-e") 'ivy-explorer-eol-and-call)

      (define-key map (kbd "C-n") 'ivy-explorer-next)
      (define-key map (kbd "C-p") 'ivy-explorer-previous)
      (define-key map (kbd "C-M-n") 'ivy-explorer-next-and-call)
      (define-key map (kbd "C-M-p") 'ivy-explorer-previous-and-call)))
  "Keymap used in the minibuffer for function/`ivy-explorer-mode'.")

;; * Ivy settings

(when (bound-and-true-p ivy-display-functions-props)
  (push '(ivy-explorer--display-function :cleanup ivy-explorer--cleanup)
        ivy-display-functions-props))

(defvar ivy-explorer--posframe-buffer
  " *ivy-explorer-pos-frame-buffer*")

(defun ivy-explorer--cleanup ()
  (when (and ivy-explorer-mode
             (eq ivy-explorer-message-function
                 #'ivy-explorer--posframe)
             (string-match "posframe"
                           (symbol-name ivy-explorer-message-function)))
    (posframe-hide ivy-explorer--posframe-buffer)))

;; * Ivy explorer menu

(defvar ivy-explorer--col-n nil
  "Current columns size of grid.")

(defvar ivy-explorer--row-n nil
  "Current row size of grid.")

(defun ivy-explorer--get-menu-string (strings cols &optional width)
  "Given a list of STRINGS create a menu string.

The menu string will be segmented into columns. COLS is the
maximum number of columns to use. Decisions to use less number of
columns is based on WIDTH which defaults to frame width. Returns
a cons cell with the (columns . rows) created as the `car' and
the menu string as `cdr'."
  (with-temp-buffer
    (let* ((length (apply 'max
                          (mapcar #'string-width strings)))
           (wwidth (or width (frame-width)))
           (columns (min cols (/ wwidth (+ 2 length))))
           (rows 1)
           (colwidth (/ wwidth columns))
           (column 0)
           (first t)
           laststring)
      (dolist (str strings)
        (unless (equal laststring str)
          (setq laststring str)
          (let ((length (string-width str)))
            (unless first
              (if (or (< wwidth (+ (max colwidth length) column))
                      (zerop length))
                  (progn
                    (cl-incf rows)
                    (insert "\n" (if (zerop length) "\n" ""))
                    (setq column 0))
                (insert " \t")
                (set-text-properties (1- (point)) (point)
                                     `(display (space :align-to ,column)))))
            (setq first (zerop length))
            (insert str)
            (setq column (+ column
                            (* colwidth (ceiling length colwidth)))))))
      (cons (cons columns rows) (buffer-string)))))

;; * Ivy explorer window, adapted from lv.el

(defvar display-line-numbers)
(defvar golden-ratio-mode)

(defvar ivy-explorer--window nil
  "Holds the current ivy explorer window.")

(defmacro ivy-explorer--lv-command (cmd)
  `(defun ,(intern (format "%s-lv" (symbol-name cmd))) ()
     (interactive)
     (with-selected-window (minibuffer-window)
       (call-interactively ',cmd)
       (ivy--exhibit))))

(defun ivy-explorer-select-mini ()
  (interactive)
  (select-window (minibuffer-window)))

(defvar ivy-explorer-lv-mode-map
  (let ((map (make-sparse-keymap)))
    (prog1 map
      (suppress-keymap map)
      (define-key map (kbd "C-g") (defun ivy-explorer-lv-quit ()
                                    (interactive)
                                    (with-selected-window (minibuffer-window)
                                      (minibuffer-keyboard-quit))))
      (define-key map "n" (ivy-explorer--lv-command ivy-explorer-next))
      (define-key map "p" (ivy-explorer--lv-command ivy-explorer-previous))
      (define-key map "f" (ivy-explorer--lv-command ivy-explorer-forward))
      (define-key map "b" (ivy-explorer--lv-command ivy-explorer-backward))
      (define-key map (kbd "RET") (ivy-explorer--lv-command ivy-alt-done))
      (define-key map (kbd "DEL") (ivy-explorer--lv-command ivy-backward-delete-char))
      (define-key map (kbd "M-o") (ivy-explorer--lv-command ivy-explorer-dispatching-done))
      (define-key map "," (ivy-explorer--lv-command ivy-explorer-avy))
      (define-key map (kbd "C-x o") 'ivy-explorer-select-mini)
      (define-key map (kbd "'") 'ivy-explorer-select-mini))))

(define-minor-mode ivy-explorer-lv-mode
  "Mode for buffer showing the grid.")

(defun ivy-explorer--lv ()
  "Ensure that ivy explorer window is live and return it."
  (if (window-live-p ivy-explorer--window)
      ivy-explorer--window
    (let ((ori (selected-window))
          buf)
      (prog1 (setq ivy-explorer--window
                   (select-window
                    (let ((ignore-window-parameters t))
                      (split-window
                       (frame-root-window) -1 'below))))
        (if (setq buf (get-buffer " *ivy-explorer*"))
            (switch-to-buffer buf)
          (switch-to-buffer " *ivy-explorer*")
          (set-window-hscroll ivy-explorer--window 0)
          (ivy-explorer-lv-mode 1)
          (setq window-size-fixed t)
          (setq mode-line-format nil)
          (setq cursor-type nil)
          (setq display-line-numbers nil)
          (set-window-dedicated-p ivy-explorer--window t)
          (set-window-parameter ivy-explorer--window 'no-other-window t))
        (select-window ori)))))

(defun ivy-explorer--lv-message (str)
  "Set ivy explorer window contents to string STR."
  (let* ((str (substring str 1))
         (n-lines (cl-count ?\n str))
         (window-size-fixed nil)
         deactivate-mark
         golden-ratio-mode)
    (with-selected-window (ivy-explorer--lv)
      (unless (string= (buffer-string) str)
        (delete-region (point-min) (point-max))
        (insert str)
        (when (and (window-system) ivy-explorer-use-separator)
          (unless (looking-back "\n" nil)
            (insert "\n"))
          (insert
           (propertize "__" 'face
                       'ivy-explorer-separator 'display '(space :height (1)))
           (propertize "\n" 'face
                       'ivy-explorer-separator 'line-height t)))
        (set (make-local-variable 'window-min-height) n-lines)
        (setq truncate-lines (> n-lines 1))
        (let ((window-resize-pixelwise t)
              (window-size-fixed nil))
          (fit-window-to-buffer nil nil 1)))
      (goto-char (point-min)))))

(defun ivy-explorer--lv-delete-window ()
  "Delete ivy explorer window and kill its buffer."
  (when (window-live-p ivy-explorer--window)
    (let ((buf (window-buffer ivy-explorer--window)))
      (delete-window ivy-explorer--window)
      (kill-buffer buf))))


(defun ivy-explorer--posframe (msg)
  (unless (require 'posframe nil t)
    (user-error "Posframe library not found"))
  (unless (bound-and-true-p ivy-display-functions-props)
    (user-error "Ivy version to old, use melpa version if possible"))
  (with-selected-window (ivy--get-window ivy-last)
    (posframe-show
     ivy-explorer--posframe-buffer
     :string
     (with-current-buffer (get-buffer-create " *Minibuf-1*")
       (let ((point (point))
             (string (concat (buffer-string) " " msg)))
         (add-text-properties (- point 1) point '(face (:inherit cursor))
                              string)
         string))
     :poshandler (lambda (info)
                   (cons (frame-parameter nil 'left-fringe)
                         (- 0
                            ;; TODO: calculate based on ivy-explorer-height
                            (plist-get info :mode-line-height)
                            (plist-get info :minibuffer-height))))
     :background-color (or (and (facep 'ivy-posframe)
                                (face-attribute 'ivy-posframe :background))
                           (face-attribute 'fringe :background))
     :foreground-color (or (and (facep 'ivy-posframe)
                                (face-attribute 'ivy-posframe :foreground)
                                (face-attribute 'default :foreground)))
     :internal-border-width (or (and (bound-and-true-p ivy-posframe-border-width)
                                     ivy-posframe-border-width)
                                0)
     :height ivy-explorer-height
     :left-fringe (frame-parameter nil 'left-fringe)
     :right-fringe (frame-parameter nil 'right-fringe)
     :width (frame-width))))


;; * Minibuffer commands

(defun ivy-explorer--ace-handler (char)
  "Execute buffer-expose action for CHAR."
  (cond ((memq char '(27 ?\C-g ?,))
         ;; exit silently
         (throw 'done 'exit))
        ((mouse-event-p char)
         (signal 'user-error (list "Mouse event not handled" char)))
        (t
         (require 'edmacro)
         (let* ((key (kbd (edmacro-format-keys (vector char))))
                (cmd (or (lookup-key ivy-explorer-map key)
                         (key-binding key))))
           (if (commandp cmd)
               (progn (call-interactively cmd)
                      (run-at-time 0 nil #'ivy--exhibit)
                      (throw 'done 'exit))
             (message "No such candidate: %s, hit `C-g' to quit."
                      (if (characterp char) (string char) char))
             (throw 'done 'restart))))))


(defvar avy-all-windows)
(defvar avy-keys)
(defvar avy-keys-alist)
(defvar avy-style)
(defvar avy-styles-alist)
(defvar avy-action)
(defun ivy-explorer--avy ()
  (let* ((avy-all-windows nil)
         (avy-keys (or (cdr (assq 'ivy-avy avy-keys-alist))
                       avy-keys))
         (avy-handler-function #'ivy-explorer--ace-handler)
         (avy-pre-action #'ignore)
         (avy-style (or (cdr (assq 'ivy-avy
                                   avy-styles-alist))
                        avy-style))
         (avy-action #'identity)
         (handler (cdr (assq ivy-explorer-message-function
                             ivy-explorer-avy-handler-alist)))
         (success (if handler (funcall handler)
                    (user-error "No handler for %s found in `ivy-explorer-avy-handler-alist'"
                                ivy-explorer-message-function))))
    success))

(defun ivy-explorer-avy-default-handler ()
  (let* ((w (ivy-explorer--lv))
         (b (window-buffer w)))
    (with-selected-window w
      (ivy-explorer--avy-1 b))))

(defun ivy-explorer-avy-posframe-handler ()
  (let* ((b ivy-explorer--posframe-buffer)
         (w (frame-selected-window
             (buffer-local-value 'posframe--frame
                                 (get-buffer b)))))
    (with-selected-window w
      (ivy-explorer--avy-1 b (with-current-buffer b
                               (save-excursion
                                 (goto-char (point-min))
                                 (forward-line 1)
                                 (point)))
                           (window-end w)))))

(defun ivy-explorer--avy-1 (&optional buffer start end)
  (let ((candidate (avy--process
                    (ivy-explorer--parse-avy-buffer buffer start end)
                    (avy--style-fn avy-style))))
    (when (number-or-marker-p candidate)
      (prog1 t
        (ivy-set-index
         (get-text-property candidate 'ivy-explorer-count))))))

(defun ivy-explorer--parse-avy-buffer (&optional buffer start end)
  (let ((count 0)
        (candidates ())
        (start (or start (point-min)))
        (end (or end (point-max))))
    (with-current-buffer (or buffer (current-buffer))
      (save-excursion
        (save-restriction
          (narrow-to-region start end)
          (goto-char (point-min))
          ;; ignore the first candidate if at ./
          ;; this command is meant to be used for navigation
          ;; navigate to same folder you are in makes no sense
          (unless (search-forward "./" nil t)
            (push (cons (point)
                        (selected-window))
                  candidates)
            (put-text-property
             (point) (1+ (point)) 'ivy-explorer-count count))
          (goto-char
           (or (next-single-property-change
                (point) 'mouse-face)
               (point-max)))
          (while (< (point) (point-max))
            (unless (looking-at "[[:blank:]\r\n]\\|\\'")
              (cl-incf count)
              (put-text-property
               (point) (1+ (point)) 'ivy-explorer-count count)
              (push
               (cons (point)
                     (selected-window))
               candidates))
            (goto-char
             (or (next-single-property-change
                  (point)
                  'mouse-face)
                 (point-max)))))))
    (nreverse candidates)))


;; Ivy explorer avy, adapted from ivy-avy
(defun ivy-explorer-avy (&optional action)
  "Jump to one of the current candidates using `avy'.

Files are opened and directories will be entered. When entering a
directory `avy' is invoked again. Users can exit this navigation
style with C-g.

If called from code ACTION is the action to trigger afterwards,
in this case `avy' is not invoked again."
  (interactive)
  (unless (require 'avy nil 'noerror)
    (error "Package avy isn't installed"))
  (when (ivy-explorer--avy)
    (ivy--exhibit)
    (funcall (or action #'ivy-alt-done))))

;; adapted from ivy-hydra
(defun ivy-explorer-avy-dispatching-done-hydra ()
  "Choose action and afterwards target using `hydra'."
  (interactive)
  (let* ((actions (ivy-state-action ivy-last))
         (estimated-len (+ 25 (length
                               (mapconcat
                                (lambda (x)
                                  (format "[%s] %s" (nth 0 x) (nth 2 x)))
                                (cdr actions) ", "))))
         (n-columns (if (> estimated-len (window-width))
                        (or (and (bound-and-true-p ivy-dispatching-done-columns)
                                 ivy-dispatching-done-columns)
                            2)
                      nil)))
    (if (null (ivy--actionp actions))
        (ivy-done)
      (ivy-explorer-avy 'ignore)
      (funcall
       (eval
        `(defhydra ivy-read-action (:color teal :columns ,n-columns)
           "action"
           ,@(mapcar (lambda (x)
                       (list (nth 0 x)
                             `(progn
                                (ivy-set-action ',(nth 1 x))
                                (ivy-done))
                             (nth 2 x)))
                     (cdr actions))
           ("M-i" nil "back")
           ("C-g" nil)))))))

(defun ivy-explorer-avy-dispatch ()
  "Choose target with avy and afterwards dispatch action."
  (interactive)
  (setq ivy-current-prefix-arg current-prefix-arg)
  (if (require 'hydra nil t)
      (call-interactively
       'ivy-explorer-avy-dispatching-done-hydra)
    (ivy-explorer-avy
     (lambda ()
       (let ((action (if (get-buffer ivy-explorer--posframe-buffer)
                         (progn (unless (require 'ivy-posframe nil t)
                                  (user-error "Ivy posframe not found"))
                                (ivy-posframe-read-action))
                       (ivy-read-action))))
         (when action
           (ivy-set-action action)
           (ivy-done)))))))

(declare-function dired-goto-file "ext:dired")
(defun ivy-explorer-dired ()
  "Open current directory in `dired'.

Move to file which was current on exit."
  (interactive)
  (let ((curr (ivy-state-current ivy-last)))
    (ivy--cd ivy--directory)
    (ivy--exhibit)
    (run-at-time 0 nil #'dired-goto-file
                 (expand-file-name curr ivy--directory))
    (ivy-done)))

(defun ivy-explorer-next (arg)
  "Move cursor vertically down ARG candidates."
  (interactive "p")
  (if (> (minibuffer-depth) 1)
      (call-interactively 'ivy-next-line)
    (let* ((n (* arg ivy-explorer--col-n))
           (max (1- ivy--length))
           (colmax (- max (% (- max ivy--index) n))))
      (ivy-set-index
       (if (= ivy--index -1)
           0
         (min colmax
              (+ ivy--index n)))))))

(defun ivy-explorer-eol ()
  "Move cursor to last column."
  (interactive)
  (let ((ci (% ivy--index ivy-explorer--col-n)))
    (ivy-explorer-forward (- (1- ivy-explorer--col-n) ci))))

(defun ivy-explorer-eol-and-call ()
  "Move cursor to last column.

Call the permanent action if possible."
  (interactive)
  (ivy-explorer-eol)
  (ivy--exhibit)
  (ivy-call))

(defun ivy-explorer-bol ()
  "Move cursor to first column."
  (interactive)
  (let ((ci (% ivy--index ivy-explorer--col-n)))
    (ivy-explorer-backward ci)))

(defun ivy-explorer-bol-and-call ()
  "Move cursor to first column.

Call the permanent action if possible."
  (interactive)
  (ivy-explorer-bol)
  (ivy--exhibit)
  (ivy-call))

(defun ivy-explorer-next-and-call (arg)
  "Move cursor down ARG candidates.

Call the permanent action if possible."
  (interactive "p")
  (ivy-explorer-next arg)
  (ivy--exhibit)
  (ivy-call))

(defun ivy-explorer-previous (arg)
  "Move cursor vertically up ARG candidates."
  (interactive "p")
  (if (> (minibuffer-depth) 1)
      (call-interactively 'ivy-previous-line)
    (let* ((n (* arg ivy-explorer--col-n))
           (colmin (% ivy--index n)))
      (ivy-set-index
       (if (and (= ivy--index 0)
                ivy-use-selectable-prompt)
           -1
         (max colmin
              (- ivy--index n)))))))

(defun ivy-explorer-previous-and-call (arg)
  "Move cursor up ARG candidates.
Call the permanent action if possible."
  (interactive "p")
  (ivy-explorer-previous arg)
  (ivy--exhibit)
  (ivy-call))

(defalias 'ivy-explorer-forward #'ivy-next-line
  "Move cursor forward ARG candidates.")

(defalias 'ivy-explorer-backward #'ivy-previous-line
  "Move cursor backward ARG candidates.")

(defun ivy-explorer-alt-done ()
  "Like `ivy-alt-done' but respecting `ivy-explorer-auto-init-avy'."
  (interactive)
  (with-selected-window (minibuffer-window)
    (call-interactively 'ivy-alt-done)
    (when ivy-explorer-auto-init-avy
      (ivy-explorer-avy))))

(defun ivy-explorer-backward-delete-char ()
  "Like `ivy-backward-delete-char' but respecting `ivy-explorer-auto-init-avy'."
  (interactive)
  (with-selected-window (minibuffer-window)
    (if (and ivy--directory (= (minibuffer-prompt-end) (point)))
        (progn (call-interactively 'ivy-backward-delete-char)
               (when ivy-explorer-auto-init-avy
                 (ivy-explorer-avy)))
      (call-interactively 'ivy-backward-delete-char))))


(defalias 'ivy-explorer-forward-and-call #'ivy-next-line-and-call
  "Move cursor forward ARG candidates.
Call the permanent action if possible.")

(defalias 'ivy-explorer-backward-and-call #'ivy-previous-line-and-call
  "Move cursor backward ARG candidates.
Call the permanent action if possible.")

;; * Ivy explorer mode

(defun ivy-explorer-other-window ()
  (interactive)
  (let ((w (or (get-buffer-window " *ivy-explorer*")
               (get-buffer-window (ivy-state-buffer ivy-last)))))
    (when (window-live-p w)
      (select-window w))))

(defun ivy-explorer-max ()
  "Default for `ivy-explorer-max-function'."
  (* 2 (frame-height)))

(defun ivy-explorer--display-function (text)
  "Displays TEXT as `ivy-display-function'."
  (let* ((strings (or (split-string text "\n" t)
                      (list "")))
         (menu (ivy-explorer--get-menu-string
                strings ivy-explorer-max-columns ivy-explorer-width))
         (mcols (caar menu))
         (mrows (cdar menu))
         (mstring (cdr menu)))
    (setq ivy-explorer--col-n mcols)
    (setq ivy-explorer--row-n mrows)
    (funcall ivy-explorer-message-function (concat "\n" mstring))))


(defun ivy-explorer-read (prompt coll &optional avy msgf mcols width height)
  "Read value from an explorer grid.

PROMPT and COLL are the same as for `ivy-read'. If AVY is non-nil
the grid is initilized with avy selection.

MCOLS is the number of columns to use. If the grid does not fit
on the screen the number of columns is adjusted to a lower number
automatically. If not given the the value is calculated
by (/ (frame-width) 30)

WIDTH is the width to be used to create the grid and defaults to
frame-width.

Height is the height for the grid display and defaults to
ivy-height.

MSGF is the function to be called with the grid string and defaults to
`ivy-explorer-message-function.'"
  (let ((ivy-explorer-message-function (or msgf ivy-explorer-message-function))
        (ivy-explorer-max-columns (or mcols (/ (frame-width) 30)))
        (ivy-wrap nil)
        (ivy-explorer-height (or height ivy-explorer-height))
        (ivy-explorer-width (or width (frame-width)))
        (ivy-height (funcall ivy-explorer-max-function))
        (ivy-display-function #'ivy-explorer--display-function)
        (ivy-display-functions-alist '((t . ivy-explorer--display-function)))
        (ivy-posframe-display-functions-alist nil)
        (ivy-posframe-hide-minibuffer
         (eq ivy-explorer-message-function #'ivy-explorer--posframe))
        (ivy-posframe--display-p t)
        (ivy-minibuffer-map (make-composed-keymap
                             ivy-explorer-map ivy-minibuffer-map)))
    (when avy
      (run-at-time 0 nil 'ivy-explorer-avy))
    (ivy-read prompt coll)))


(defun ivy-explorer--internal (f &rest args)
  "Invoke ivy explorer for F with ARGS."
  (let ((ivy-display-function #'ivy-explorer--display-function)
        (ivy-display-functions-alist '((t . ivy-explorer--display-function)))
        (ivy-posframe-display-functions-alist nil)
        (completing-read-function 'ivy-completing-read)
        (ivy-posframe-hide-minibuffer
         (eq ivy-explorer-message-function #'ivy-explorer--posframe))
        (ivy-posframe--display-p t)
        ;; max number of candidates
        (ivy-height (funcall ivy-explorer-max-function))
        (ivy-wrap nil)
        (ivy-minibuffer-map (make-composed-keymap
                             ivy-explorer-map ivy-minibuffer-map)))
    (when ivy-explorer-auto-init-avy
      (run-at-time 0 nil 'ivy-explorer-avy))
    (apply f args)))


(defun ivy-explorer-dispatching-done ()
  "Select one of the available actions and call `ivy-done'."
  (interactive)
  (cond ((get-buffer ivy-explorer--posframe-buffer)
         (unless (require 'ivy-posframe nil t)
           (user-error "Ivy posframe not found"))
         (ivy-posframe-dispatching-done))
        (t
         (let ((window (selected-window)))
           (unwind-protect
               (when (ivy-read-action)
                 (ivy-done))
             (when (window-live-p window)
               (window-resize nil (- 1 (window-height)))))))))


(defun ivy-explorer (&rest args)
  "Function to be used as `read-file-name-function'.

ARGS are bassed to `read-file-name-default'."
  (apply #'ivy-explorer--internal #'read-file-name-default args))


(defun counsel-explorer (&optional initial-input)
  "`counsel-find-file' version for ivy explorer.

INITIAL-INPUT is passed to `counsel-find-file'."
  (interactive)
  (apply #'ivy-explorer--internal #'counsel-find-file initial-input))

(defvar ivy-explorer-mode-map
  (let ((map (make-sparse-keymap)))
    (prog1 map
      (when ivy-explorer-enable-counsel-explorer
        (define-key map
          [remap find-file] #'counsel-explorer))))
  "Keymap for function/`ivy-explorer-mode'.")

;; from lispy.el
(defun ivy-explorer-raise ()
  "Make function/`ivy-explorer-mode' the first on `minor-mode-map-alist'."
  (let ((x (assq #'ivy-explorer-mode minor-mode-map-alist)))
    (when x
      (setq minor-mode-map-alist
            (cons x
                  (delq #'ivy-explorer-mode minor-mode-map-alist))))))

(defvar ivy-explorer--default nil
  "Saves user configured `read-file-name-function'.")


;;;###autoload
(define-minor-mode ivy-explorer-mode
  "Globally enable `ivy-explorer' for file navigation.

`ivy-explorer-mode' is a global minor mode which changes
`read-file-name-function' which is used for file completion.

When `ivy-explorer-enable-counsel-explorer' (by default it is),
`find-file' and `counsel-find-file' will be remapped to
`counsel-explorer.', too.

See `ivy-explorer-map' for bindings used in the minibuffer."
  :group 'ivy-explorer
  :require 'ivy-explorer
  :global t
  :init-value nil
  :lighter " ivy-explorer"
  (if (not ivy-explorer-mode)
      (setq read-file-name-function ivy-explorer--default)
    (setq ivy-explorer--default read-file-name-function
          read-file-name-function #'ivy-explorer)
    (when ivy-explorer-enable-counsel-explorer
      ;; in case users activate counsel afterwards.
      (add-hook 'counsel-mode-hook 'ivy-explorer-raise))))

(provide 'ivy-explorer)
;;; ivy-explorer.el ends here





