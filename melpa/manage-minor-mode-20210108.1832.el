;;; manage-minor-mode.el --- Manage your minor-modes easily -*- lexical-binding: t -*-

;; Copyright (C) 2014 by Shingo Fukuyama
;; Copyright (C) 2020-2021 Shen, Jen-Chieh

;; Version: 1.1
;; Package-Version: 20210108.1832
;; Package-Commit: f4b37fffec7b6608a597e6a3f6900634802807b4
;; Author: Shingo Fukuyama - http://fukuyama.co
;; Maintainer: Jen-Chieh Shen <jcs090218@gmail.com>
;; URL: https://github.com/ShingoFukuyama/manage-minor-mode
;; Created: Mar 8 2014
;; Keywords: tools minor-mode manage emacs
;; Package-Requires: ((emacs "24.3"))

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
;; PURPOSE.  See the GNU General Public License for more details.

;;; Commentary:

;; Usage:
;; 1. M-x manage-minor-mode
;; 2. Minor modes list buffer will appear
;; 3. Then type "RET" key on any minor-mode you want to toggle active/inactive

;;; Code:

(require 'cl-lib)

(defun manage-minor-mode--active-list ()
  "Get a list of which minor modes are enabled in the current buffer."
  (let ($list)
    (mapc (lambda ($mode)
            (condition-case nil
                (if (and (symbolp $mode) (symbol-value $mode))
                    (setq $list (cons $mode $list)))
              (error nil)))
          minor-mode-list)
    (sort $list 'string<)))

(defun manage-minor-mode--inactive-list ()
  "Get a list of which minor modes are disabled in the current buffer."
  (let ($list)
    (mapc (lambda ($mode)
            (condition-case nil
                (if (and (symbolp $mode) (not (symbol-value $mode)))
                    (setq $list (cons $mode $list)))
              (error nil)))
          minor-mode-list)
    (sort $list 'string<)))

(defgroup manage-minor-mode nil
  "Group for manage minor modes"
  :prefix "manage-minor-mode-"
  :group 'convenience)

(defvar manage-minor-mode-buffer "*manage-minor-mode*")

(defface manage-minor-mode-face-active
  '((t :inherit success :foreground "#33eeee"))
  "Face for active minor modes"
  :group 'manage-minor-mode)

(defface manage-minor-mode-face-inactive
  '((t :inherit warning :foreground "#ff6666"))
  "Face for inactive minor modes"
  :group 'manage-minor-mode)

(defface manage-minor-mode-face-changed
  '((t :inherit underline :foreground "#eeee00"))
  "Face for last changed minor modes"
  :group 'manage-minor-mode)

(defcustom manage-minor-mode-always-show-keybind t
  "Show keybind on the top of the buffer."
  :group 'manage-minor-mode :type 'boolean)

(defvar manage-minor-mode-map
  (let (($map (make-sparse-keymap)))
    (define-key $map (kbd "RET") 'manage-minor-mode-toggle)
    (define-key $map (kbd "<mouse-1>") 'manage-minor-mode-toggle)
    (define-key $map (kbd "g") 'manage-minor-mode-refresh)
    (define-key $map (kbd "e") 'manage-minor-mode-whole-session-enable)
    (define-key $map (kbd "d") 'manage-minor-mode-whole-session-disable)
    (define-key $map (kbd "r") 'manage-minor-mode-whole-session-release)
    $map))

(defun manage-minor-mode--goto-line ($line)
  "Go to $LINE considering narrowing."
  (goto-char (point-min))
  (forward-line (- $line 1)))

(defsubst manage-minor-mode--enable ($mode)
  "Enable $MODE."
  (ignore-errors (funcall $mode 1)))

(defsubst manage-minor-mode--disable ($mode)
  "Disable $MODE."
  (ignore-errors (funcall $mode 0)))

(defvar manage-minor-mode-default nil
  "Set `minor-mode' active/inactive when `major-mode' changed.

;; Value structure:
  '((global      (on  minor-mode minor-mode ...)
                 (off minor-mode minor-mode ...))
    (major-mode1 (on  minor-mode minor-mode ...)
                 (off minor-mode minor-mode ...))
    (major-mode2 (on  minor-mode minor-mode ...)
                 (off minor-mode minor-mode ...))
    ...)

;; Example
  (setq manage-minor-mode-default
        '((global
           (on   rainbow-mode hl-line-mode)
           (off  line-number-mode))
          (emacs-lisp-mode
           (on   rainbow-delimiters-mode eldoc-mode show-paren-mode))
          (js2-mode
           (on   color-identifiers-mode)
           (off  flycheck-mode))))")

;;;###autoload
(defun manage-minor-mode-set ()
  "Manage minor mode set."
  (when manage-minor-mode-default
    (let* (($global (assoc-default 'global manage-minor-mode-default))
           ($global-on  (assoc-default 'on  $global))
           ($global-off (assoc-default 'off $global))
           ($major  (assoc-default major-mode manage-minor-mode-default))
           ($major-on  (assoc-default 'on  $major))
           ($major-off (assoc-default 'off $major))
           ($on  (append $global-on  $major-on))
           ($off (append $global-off $major-off)))
      (mapc (lambda ($m) (manage-minor-mode--enable  $m)) $on)
      (mapc (lambda ($m) (manage-minor-mode--disable $m)) $off))))

(add-hook 'after-change-major-mode-hook 'manage-minor-mode-set t)

(defun manage-minor-mode-whole-session-enable ()
  "Enable minor-mode on the whole session."
  (interactive)
  (let (($po (if (eolp) (- (point) 1) (point)))
        $mode)
    (when (get-text-property $po 'manage-minor-mode)
      (setq $mode (intern (thing-at-point 'symbol)))
      (mapc (lambda ($buf)
              (with-current-buffer $buf
                (manage-minor-mode--enable $mode)))
            (buffer-list))
      (let* (($global (assoc-default 'global manage-minor-mode-default))
             ($on  (assq 'on  $global))
             ($off (assq 'off $global)))
        (cond ((not $global)
               (setq manage-minor-mode-default
                     (cons '(global (on) (off)) manage-minor-mode-default)))
              ((and $global (not $on) $off)
               (setf (cdr (assq 'global manage-minor-mode-default))
                     `((on) ,$off)))
              ((and $global (not $off) $on)
               (setf (cdr (assq 'global manage-minor-mode-default))
                     `(,$on (off)))))
        (setf (cdr (assq 'on  (assoc-default 'global manage-minor-mode-default)))
              (cons $mode (cdr $on)))
        (setf (cdr (assq 'off (assoc-default 'global manage-minor-mode-default)))
              (delq $mode (cdr $off))))
      (manage-minor-mode-refresh $mode))))

(defun manage-minor-mode-whole-session-disable ()
  "Disable minor-mode on the whole session."
  (interactive)
  (let (($po (if (eolp) (- (point) 1) (point)))
        $mode)
    (when (get-text-property $po 'manage-minor-mode)
      (setq $mode (intern (thing-at-point 'symbol)))
      (mapc (lambda ($buf)
              (with-current-buffer $buf
                (manage-minor-mode--disable $mode)))
            (buffer-list))
      (let* (($global (assoc-default 'global manage-minor-mode-default))
             ($on  (assq 'on  $global))
             ($off (assq 'off $global)))
        (cond ((not $global)
               (setq manage-minor-mode-default
                     (cons '(global (on) (off)) manage-minor-mode-default)))
              ((and $global (not $on) $off)
               (setf (cdr (assq 'global manage-minor-mode-default))
                     `((on) ,$off)))
              ((and $global (not $off) $on)
               (setf (cdr (assq 'global manage-minor-mode-default))
                     `(,$on (off)))))
        (setf (cdr (assq 'on  (assoc-default 'global manage-minor-mode-default)))
              (delq $mode (cdr $on)))
        (setf (cdr (assq 'off (assoc-default 'global manage-minor-mode-default)))
              (cons $mode (cdr $off))))
      (manage-minor-mode-refresh $mode))))

(defun manage-minor-mode-whole-session-release ()
  "Disable minor-mode on the whole session."
  (interactive)
  (let ($mode)
    (when (get-text-property (point) 'manage-minor-mode)
      (setq $mode (intern (thing-at-point 'symbol)))
      (let* (($global (assoc-default 'global manage-minor-mode-default))
             ($on  (assq 'on  $global))
             ($off (assq 'off $global)))
        (cond ((not $global)
               (setq manage-minor-mode-default
                     (cons '(global (on) (off)) manage-minor-mode-default)))
              ((and $global (not $on) $off)
               (setf (cdr (assq 'global manage-minor-mode-default))
                     `((on) ,$off)))
              ((and $global (not $off) $on)
               (setf (cdr (assq 'global manage-minor-mode-default))
                     `(,$on (off)))))
        (setf (cdr (assq 'on  (assoc-default 'global manage-minor-mode-default)))
              (delq $mode (cdr $on)))
        (setf (cdr (assq 'off (assoc-default 'global manage-minor-mode-default)))
              (delq $mode (cdr $off))))
      (manage-minor-mode-refresh))))

(defun manage-minor-mode-whole-session-show ()
  "Show globally enable/disable list."
  (let* (($global  (assoc-default 'global manage-minor-mode-default))
         ($enable  (assoc-default 'on  $global))
         ($disable (assoc-default 'off $global)))
    (when $enable
      (mapc (lambda ($m)
              (goto-char (point-min))
              (when (re-search-forward (concat "\\_<"
                                               (format "%s" $m)
                                               "\\_>") nil t)
                (let (($ov (make-overlay (match-beginning 0) (match-end 0))))
                  (if (not (save-excursion (goto-char (match-end 0)) (eolp)))
                      (delete-char 3))
                  (overlay-put $ov 'after-string
                               (propertize
                                "[E]"
                                'face '(:foreground "#ffff00" :background "#555555"))))))
            $enable))
    (when $disable
      (mapc (lambda ($m)
              (goto-char (point-min))
              (when (re-search-forward (concat "\\_<"
                                               (format "%s" $m)
                                               "\\_>") nil t)
                (let (($ov (make-overlay (match-beginning 0) (match-end 0))))
                  (overlay-put $ov 'after-string
                               (propertize
                                "[D]"
                                'face '(:foreground "#eeee00" :background "#333333"))))))
            $disable))))

(defvar manage-minor-mode-window-config nil)

(defun manage-minor-mode--buffer-p ()
  "Return non-nil if buffer-p."
  (equal (buffer-name (current-buffer)) manage-minor-mode-buffer))


(defvar manage-minor-mode-target-info nil)

(defun manage-minor-mode--get-target-info ($key)
  "Get target info $KEY."
  (car (assoc-default $key manage-minor-mode-target-info)))

(defun manage-minor-mode-refresh (&optional $mode-for-highlight $line $column)
  "Redraw the `*manabe-minor-mode*' buffer."
  (interactive)
  (let (($li (or $line (line-number-at-pos)))
        ($cl (or $column (current-column))))
    (set-window-configuration manage-minor-mode-window-config)
    (if (manage-minor-mode--buffer-p)
        (with-current-buffer (manage-minor-mode--get-target-info 'buffer)
          (manage-minor-mode $mode-for-highlight))
      (manage-minor-mode $mode-for-highlight))
    (manage-minor-mode--goto-line $li)
    (line-move-to-column $cl)
    (when (called-interactively-p 'any)
      (message (format "Refreshed '%s'" manage-minor-mode-buffer)))))

(defun manage-minor-mode-toggle ()
  "Toggle a minor-mode status under the cursor."
  (interactive)
  (let (($po (if (eolp) (- (point) 1) (point)))
        ($li (line-number-at-pos))
        ($cl (current-column))
        ($buf (manage-minor-mode--get-target-info 'buffer)))
    (cl-case (get-text-property $po 'manage-minor-mode)
      (active   (let (($mode (intern (thing-at-point 'symbol))))
                  (with-current-buffer $buf
                    (manage-minor-mode--disable $mode)
                    (manage-minor-mode-refresh $mode $li $cl))))
      (inactive (let (($mode (intern (thing-at-point 'symbol))))
                  (with-current-buffer $buf
                    (manage-minor-mode--enable $mode)
                    (manage-minor-mode-refresh $mode $li $cl)))))))

(defun manage-minor-mode--kill-buffer ($after-select-window)
  "Kill $AFTER-SELECT-WINDOW."
  (when (get-buffer manage-minor-mode-buffer)
    (kill-buffer manage-minor-mode-buffer)
    (select-window $after-select-window)))

;;;###autoload
(defun manage-minor-mode (&optional $last-toggled-item)
  "The minor mode.
Record for the $LAST-TOGGLED-ITEM."
  (interactive)
  (and $last-toggled-item
       (not (listp $last-toggled-item))
       (setq $last-toggled-item (cons $last-toggled-item nil)))
  (setq manage-minor-mode-window-config (current-window-configuration))
  (let* (($act   (manage-minor-mode--active-list))
         ($inact (manage-minor-mode--inactive-list))
         ($max-line (+ (length $act) (length $inact)))
         ($current-buf (current-buffer))
         ($current-win (get-buffer-window $current-buf))
         ($major-mode major-mode))
    (manage-minor-mode--kill-buffer $current-win)
    (pop-to-buffer manage-minor-mode-buffer)
    (setq truncate-lines t)
    (set (make-local-variable 'manage-minor-mode-target-info)
         `((buffer      ,$current-buf)
           (window      ,$current-win)
           (major-mode  ,$major-mode)))
    (cl-dotimes (ignored $max-line)
      (insert (format "|  \n")))
    ;; Insert inactive minor-modes
    (goto-char (point-min))
    (mapc (lambda ($m)
            (goto-char (point-at-eol))
            (insert
             (propertize
              (format "%s" $m)
              'face 'manage-minor-mode-face-inactive
              'manage-minor-mode 'inactive
              'pointer           'hand))
            (forward-line))
          $inact)
    ;; Insert active minor-modes
    (goto-char (point-min))
    (mapc (lambda ($m)
            (insert
             (concat
              (propertize
               (format "%s" $m)
               'face 'manage-minor-mode-face-active
               'manage-minor-mode 'active
               'pointer           'hand)
              "     " ;; 5 spaces
              ))
            (forward-line))
          $act)
    ;; header
    (goto-char (point-min))
    (setq header-line-format
          (concat "buffer: "
                  (propertize
                   (format "%s" $current-buf)
                   'face 'manage-minor-mode-face-active)
                  "  major-mode: "
                  (propertize
                   (format "%s" $major-mode)
                   'face 'manage-minor-mode-face-active)))
    (if manage-minor-mode-always-show-keybind
        (insert (concat "g:   Refresh this buffer\n"
                        "e:   Enable  in the whole session [E]\n"
                        "d:   Disable in the whole session [D]\n"
                        "r:   Release out of the enable/disable list\n"
                        "RET: Toggle active/inactive\n"
                        "\n")))
    (insert (concat "Active" "  |  " "Inactive" "\n"))
    ;; Adjust buffer
    (goto-char (point-min))
    (while (re-search-forward "^\\s-*|\\s-*$" nil t)
      (delete-region (match-beginning 0) (match-end 0)))
    (align-regexp (point-min) (point-max) "\\(\\s-*\\)|")
    (manage-minor-mode-whole-session-show)
    ;; highlight last toggled mode
    (when $last-toggled-item
      (mapc (lambda ($m)
              (goto-char (point-min))
              (when (re-search-forward (concat "\\_<"
                                               (format "%s" $m)
                                               "\\_>") nil t)
                (put-text-property (match-beginning 0) (match-end 0)
                                   'face 'manage-minor-mode-face-changed)))
            $last-toggled-item))
    (goto-char (point-min))
    (when (re-search-forward "^Active" nil t)
      (goto-char (point-at-bol)))
    (read-only-mode)
    (use-local-map manage-minor-mode-map)))

(defvar manage-minor-mode-modes-before-bals nil)

(defvar manage-minor-mode-bals-exclude-list nil
  "Minor-modes list evade from the eradication by `manage-minor-mode-bals'.

;; Value structure:
  '((global     (minor-mode1 minor-mode2 ...))
    (major-mode (minor-mode1 minor-mode2 ...))
    (major-mode (minor-mode1 minor-mode2 ...))
    ...)

;; Example
  (setq manage-minor-mode-bals-exclude-list
        '((global (recentf-mode global-font-lock-mode
                   delete-selection-mode transient-mark-mode tabbar-mode))
          (text-mode (line-number-mode))
          (org-mode (line-number-mode blink-cursor-mode))))")

;;;###autoload
(defun manage-minor-mode-bals ()
  "Eradicate all minor-modes in the current buffer.
This command may cause unexpected effect even to other buffers.
However, don't worry, restore command exists:
`manage-minor-mode-restore-from-bals'."
  (interactive)
  (let (($restore-variable (manage-minor-mode--active-list))
        $switched)
    (cl-flet
        ((set-restore-variable
          () (set (make-local-variable 'manage-minor-mode-modes-before-bals)
                  $restore-variable))
         (bals
          () (let (($excludes
                    (append
                     (car (assoc-default 'global manage-minor-mode-bals-exclude-list))
                     (car (assoc-default
                           (if (manage-minor-mode--buffer-p)
                               (manage-minor-mode--get-target-info 'major-mode)
                             major-mode)
                           manage-minor-mode-bals-exclude-list)))))
               (mapc (lambda ($m)
                       (unless (memq $m $excludes)
                         (manage-minor-mode--disable $m)
                         (setq $switched (cons $m $switched))))
                     $restore-variable))))
      (if (manage-minor-mode--buffer-p)
          (progn
            (with-current-buffer (manage-minor-mode--get-target-info 'buffer)
              (bals)
              (set-restore-variable))
            (manage-minor-mode-refresh $switched 2 1)
            (set-restore-variable))
        (set-restore-variable)
        (bals)))))

(defun manage-minor-mode-restore-from-bals ()
  "Restore minor modes to before `manage-minor-mode-bals' happened."
  (interactive)
  (if (manage-minor-mode--buffer-p)
      (let ($switched)
        (with-current-buffer (manage-minor-mode--get-target-info 'buffer)
          (mapc (lambda ($m)
                  (manage-minor-mode--enable $m)
                  (setq $switched (cons $m $switched)))
                manage-minor-mode-modes-before-bals))
        (manage-minor-mode-refresh $switched 2 1))
    (mapc (lambda ($m)
            (manage-minor-mode--enable $m))
          manage-minor-mode-modes-before-bals)))

;; Mouse click minor-mode in mode-line to popup "Manage minor modes"
(defadvice popup-menu (before manage-minor-mode-add-for-popup-menu disable)
  "Advice `popup-menu'."
  (ad-set-arg 0 (append (ad-get-arg 0)
                        '((manage-minor-mode
                           menu-item "Manage minor modes"
                           (lambda () (interactive) (manage-minor-mode)))))))

(defadvice minor-mode-menu-from-indicator (around manage-minor-mode-add-mode-line-menu activate)
  "Advice for `minor-mode-menu-from-indicator'."
  (ad-enable-advice 'popup-menu 'before 'manage-minor-mode-add-for-popup-menu)
  (ad-activate 'popup-menu)
  ad-do-it
  (ad-disable-advice 'popup-menu 'before 'manage-minor-mode-add-for-popup-menu)
  (ad-activate 'popup-menu))

(provide 'manage-minor-mode)
;;; manage-minor-mode.el ends here
