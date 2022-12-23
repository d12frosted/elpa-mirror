;;; swap-buffers.el --- The quickest way to swap buffers between windows. Based on switch-window package.
;;
;; Copyright (C) 2015 Evgeniy Kazakov
;;
;; Author: Evgeniy Kazakov <evgeniy.kazakov@gmail.com>
;; URL: https://github.com/ekazakov/swap-buffers
;; Package-Version: 20150506.2139
;; Package-Commit: 46ab31359b70d935add6c6e9533443116dc51103
;; Keywords: window swap buffer exchange
;; Licence: WTFPL, grab your copy here: http://sam.zoy.org/wtfpl/
;;
;; This file is NOT part of GNU Emacs.
;;

;;; Commentary:
;;
;;
;; Install:
;;  (require 'swap-buffers)
;;
;; Bind your favorite key to 'swap-buffers:
;;  (global-set-key (kbd "C-c b") 'swap-buffers)
;;
;; By default 'swap-buffers move focus to second window.
;; Press C-u C-c b to keep focus in first window
;;
;;
;;; Code:
;;
;;; requirements
(require 'cl)
(require 'quail)

(defgroup swap-buffers nil "swap-buffers customization group"
  :group 'convenience)

(defcustom swap-buffers-qwerty-shortcuts
  '("a" "s" "d" "f" "j" "k" ";" "w" "e" "i" "o")
  "todo"
  :type 'list
  :group 'swap-buffers)

(defcustom swap-buffers-increase 12
  "How much to increase text size in the window numbering, maximum."
  :type 'integer
  :group 'swap-buffers)

(defcustom swap-buffers-timeout 5
  "After this many seconds, cancel the swapping window."
  :type 'integer
  :group 'swap-buffers)

(defcustom swap-buffers-threshold 2
  "Only active after this many windows open."
  :type 'integer
  :group 'swap-buffers)

(defcustom swap-buffers-keep-focus nil
  "Whether to keep focus on the first window."
  :type 'boolean
  :group 'swap-buffers)

(defun swap-buffers-enumerate ()
  "Return a list of one-letter strings to label current windows."
  (loop for w being the windows for x in swap-buffers-qwerty-shortcuts collect x))

(defun swap-buffers-label (num)
  "Return the label to use for a given window number.
NUM is label num in list."
  (nth (- num 1) (swap-buffers-enumerate)))

(defun swap-buffers-list ()
  "List windows for current frame, starting at top left."
  ;; (remq (selected-window)
  (window-list nil "" (frame-first-window)))

(defun swap-buffers-other-window ()
  "Return the window opposite to selected one.
Works only with 2 windows."
  (let* ((other-window (remq (selected-window)
                             (window-list nil "" (frame-first-window))))
         (windows-count (length (window-list))))
    (cond ((= 1 windows-count) (selected-window))
          ((= 2 windows-count) (car other-window))
          (t (error "%s" "Function works only with 2 windows.")))))

(defun swap-buffers-display-number (win num)
  "Create an overlay to diplay in the WIN window with label NUM while choosing."
  (let* ((label (swap-buffers-label num))
         (buffer (window-buffer win))
         (wp (window-point win))
         (ol (make-overlay wp wp buffer)))
    (overlay-put ol 'before-string (propertize label 'face (list :height 4.0 :foreground "red")))
    (overlay-put ol 'window win)
    ol))

(defun swap-buffers-list-eobp ()
  "Return a list of all the windows where `eobp' is currently
true so that we can restore that important property (think
auto scrolling) after switching."
  (loop for win in (swap-buffers-list)
        when (with-current-buffer (window-buffer win) (eobp))
        collect win))

(defun swap-buffers-restore-eobp (eobp-window-list)
  "For each window in EOBP-WINDOW-LIST move the point to end of buffer."
  (loop for win in eobp-window-list
        do (with-current-buffer (window-buffer win) (end-of-buffer))))

(defun swap-buffers-prompt-for-selected-window (prompt-message)
  "Display an overlay in each window showing a unique key, then
ask user for the window to select"
  (let ((config (current-window-configuration))
        (num 1)
        (minibuffer-num nil)
        (original-cursor cursor-type)
        (eobps (swap-buffers-list-eobp))
        key overlays
        window-points
        dedicated-windows)

    ;; arrange so that C-g will get back to previous window configuration
    (unwind-protect
        (progn
          ;; hide cursor during window selection process
          (setq-default cursor-type nil)
          ;; display big numbers to ease window selection
          (dolist (win (swap-buffers-list))
            (push (cons win (window-point win)) window-points)
            (when (window-dedicated-p win)
              (push (cons win (window-dedicated-p win)) dedicated-windows)
              (set-window-dedicated-p win nil))
            (if (minibuffer-window-active-p win)
                (setq minibuffer-num num)
              (push (swap-buffers-display-number win num) overlays))
            (setq num (1+ num)))

          (while (not key)
            (let ((input
                   (event-basic-type
                    (read-event
                     (if minibuffer-num
                         (format "Move to window [minibuffer is %s]: "
                                 (swap-buffers-label minibuffer-num))
                       prompt-message)
                     nil swap-buffers-timeout))))

              (if (or (null input) (eq input 'return))
                  (progn
                    (swap-buffers-restore-eobp eobps)
                    (keyboard-quit))	; timeout or RET
                (unless (symbolp input)
                  (let* ((wchars (mapcar 'string-to-char
                                         (swap-buffers-enumerate)))
                         (pos (position input wchars)))
                    (if pos
                        (setq key (1+ pos))
                      (progn
                        (swap-buffers-restore-eobp eobps)
                        (keyboard-quit)))))))))

      ;; restore original cursor
      (setq-default cursor-type original-cursor)
      ;; get those huge numbers away
      (mapc 'delete-overlay overlays)
      (set-window-configuration config)
      (dolist (w window-points)
        (set-window-point (car w) (cdr w)))
      (dolist (w dedicated-windows)
        (set-window-dedicated-p (car w) (cdr w))))
    key))

(defun swap-buffers-swap (win1 win2)
  "Swap buffers between win1 and win2.
WIN1 and WIN2 windows to spaw buffers."
  (let* ((buf1 (window-buffer win1))
         (buf2 (window-buffer win2))
         (start1 (window-start win1))
         (start2 (window-start win2)))
    (set-window-buffer win1 buf2)
    (set-window-buffer win2 buf1)
    (set-window-start win1 start2)
    (set-window-start win2 start1)))

(defun swap-buffers-window-name (win)
  "Return the name of buffer from window WIN."
  (substring-no-properties
   (buffer-name (window-buffer (selected-window)))))

(defun swap-buffers-log-message (message-format from-win to-win)
  "Print message about buffers swap.
MESSAGE-FORMAT format string.
FROM-WIN and TO-WIN -- source windows"
  (message message-format from-win to-win))

(defun swap-buffers-above-threshold? ()
  ""
  (let ((window-count (length (window-list))))
    (> window-count swap-buffers-threshold)))

(defun swap-buffers-destination-window ()
  ""
  (if (swap-buffers-above-threshold?)
      (let ((index (swap-buffers-prompt-for-selected-window "Move to window: ")))
        (nth (- index 1) (swap-buffers-list)))
    (swap-buffers-other-window)))

;;;###autoload
(defun swap-buffers (&optional negative-keep-focus-option)
  "Swap buffer from selected window with specified buffer.
If NEGATIVE-KEEP-FOCUS-OPTION is t -- use the opposite setting of swap-buffers-keep-focus."
  (interactive "P")
  (let* ((window-count (length (window-list)))
         (from-win (selected-window))
         (eobps (swap-buffers-list-eobp))
         (to-win (swap-buffers-destination-window))
         (keep-focus (if negative-keep-focus-option (not swap-buffers-keep-focus)
                       swap-buffers-keep-focus)))

    (if (<= window-count swap-buffers-threshold)
        (swap-buffers-swap from-win (swap-buffers-other-window))
      (swap-buffers-swap from-win to-win))

    (unless keep-focus
      (select-window to-win))
    (swap-buffers-log-message "Swap %S with %S" from-win to-win)
    (swap-buffers-restore-eobp eobps)))

(defun swap-buffers-dired-open-in-window (win)
  (set-window-buffer win
                     (find-file-noselect
                      (dired-get-file-for-visit))))

;;;###autoload
(defun swap-buffers-dired-find-file ()
  (interactive)
  (let ((win (swap-buffers-destination-window)))
    (message "hello")
    (message "w: %S" win)
    (swap-buffers-dired-open-in-window win)))

(provide 'swap-buffers)
;;; swap-buffers.el ends here
