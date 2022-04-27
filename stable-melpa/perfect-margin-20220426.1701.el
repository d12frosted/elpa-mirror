;;; perfect-margin.el --- auto center windows, work with minimap and/or linum-mode
;; Copyright (C) 2014 Randall Wang

;; Author: Randall Wang <randall.wjz@gmail.com>
;; Created: 19 Nov 2014
;; Version: 0.1
;; Package-Version: 20220426.1701
;; Package-Commit: d5cb5f075264ff2e625099aebca3151f4f35019a
;; URL: https://github.com/mpwang/perfect-margin
;; Keywords: convenience, frames
;; Package-Requires: ((emacs "24.0") (cl-lib "0.5"))

;; This file is *NOT* part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANT ABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; # Usage
;;
;; Put perfect-margin under your Emacs load path, and add this to your init.el
;;
;; (require 'perfect-margin)
;;
;; Use `M-x perfect-margin-mode` to turn on/off perfect-margin.
;;
;; To make it permanent add this to your init.el after require.
;;
;; (perfect-margin-mode 1)
;;
;; Note: when using together with minimap or linum, make sure you place config for perfect-margin *AFTER* minimap and linum.
;;
;; # Customization
;;
;; Via `M-x customize-group` and enter perfect-margin.
;;
;; Change `perfect-margin-visible-width` and `Apply and Save`. That's it.
;;
;; *Or* you can change the visible window width by setup `perfect-margin-visible-width` on the init.el.
;;
;; (setq perfect-margin-visible-width 128)
;;
;; # Additional binding on margin area
;;
;; You can place this in your init.el to make mouse wheel scroll on margin area just like it scroll on the visible window.
;;
;; (dolist (margin '("<left-margin> " "<right-margin> "))
;;   (global-set-key (kbd (concat margin "<mouse-1>")) 'ignore)
;;   (global-set-key (kbd (concat margin "<mouse-3>")) 'ignore)
;;   (dolist (multiple '("" "double-" "triple-"))
;;     (global-set-key (kbd (concat margin "<" multiple "wheel-up>")) 'mwheel-scroll)
;;     (global-set-key (kbd (concat margin "<" multiple "wheel-down>")) 'mwheel-scroll)))

;;; Code:

(require 'linum)
(require 'cl-lib)

(defvar minimap-width-fraction)
(defvar minimap-buffer-name)
(declare-function minimap-get-window "minimap")

(defgroup perfect-margin nil
  "Auto center windows, work with minimap and/or linum-mode."
  :group 'emacs)

(defcustom perfect-margin-lighter " \u24c2"
  "Mode-line indicator for symbol `perfect-margin-mode'."
  :type '(choice (const :tag "No lighter" "") string)
  :safe 'stringp
  :group 'perfect-margin)

(defcustom perfect-margin-visible-width 128
  "The visible width of main window to be kept at center."
  :group 'perfect-margin
  :type 'number)

(defcustom perfect-margin-hide-fringes t
  "Whether to set both fringes in all windows to 0."
  :group 'perfect-margin
  :type 'boolean)

(defcustom perfect-margin-ignore-regexps
  '("^minibuf" "^[*]")
  "List of strings to determine if window is ignored.
Each string is used as regular expression to match the window buffer name."
  :group 'perfect-margin
  :type '(repeat regexp))

(defcustom perfect-margin-ignore-filters
  '(window-minibuffer-p)
  "List of functions to determine if window is ignored.
Each function is called with window as its sole arguemnt, returning a non-nil value indicate to ignore the window."
  :group 'perfect-margin
  :type '(list function))

(defcustom perfect-margin-ignore-modes
  '(exwm-mode
    doc-view-mode
    nov-mode)
  "List of symbols of ignored major modes."
  :type '(repeat symbol)
  :group 'perfect-margin)

;;----------------------------------------------------------------------------
;; env predictors
;;----------------------------------------------------------------------------
(defun perfect-margin-with-linum-p ()
  "Whether linum is found and turn on."
  (bound-and-true-p linum-mode))

(defun perfect-margin-with-minimap-p ()
  "Whether minimap is found."
  (bound-and-true-p minimap-mode))

;;----------------------------------------------------------------------------
;; Private functions
;;----------------------------------------------------------------------------
(defun perfect-margin--width-with-margins (win)
  "Calculate size of window(WIN) with it's margins."
  (let ((margins (window-margins win)))
    (+ (window-width win)
       (or (car margins) 0)
       (or (cdr margins) 0))))

(defun perfect-margin--minimap-window-p (win)
  "Judge if the window(WIN) is the minimap window itself, when it's live."
  (when (and (perfect-margin-with-minimap-p)
             (minimap-get-window)
             (window-live-p (minimap-get-window)))
    (let ((minimap-edges (window-edges (minimap-get-window)))
          (current-edges (window-edges win)))
      (and (= (nth 0 minimap-edges) (nth 0 current-edges))
           (= (nth 1 minimap-edges) (nth 1 current-edges))
           (= (nth 2 minimap-edges) (nth 2 current-edges))))))

(defun perfect-margin--minimap-left-adjacent-covered-p (win)
  "Judge if the window(WIN) is left adjacent to minimap window."
  (when (and (perfect-margin-with-minimap-p)
             (minimap-get-window)
             (window-live-p (minimap-get-window)))
    (let ((minimap-edges (window-edges (minimap-get-window)))
          (current-edges (window-edges win)))
      (and (= (nth 2 minimap-edges) (nth 0 current-edges))
           (<= (nth 1 minimap-edges) (nth 1 current-edges))
           (>= (nth 3 minimap-edges) (nth 3 current-edges))))))

(defun perfect-margin--init-window-margins ()
  "Calculate target window margins as if there is only one window on frame."
  (let ((init-margin-width (round (max 0 (/ (- (frame-width) perfect-margin-visible-width) 2)))))
    (cons init-margin-width init-margin-width)))

(defun perfect-margin--auto-margin-ignore-p (win)
  "Conditions for filtering window (WIN) to setup margin."
  (let* ((buffer (window-buffer win))
         (name (buffer-name buffer)))
    (or (with-current-buffer buffer
          (apply #'derived-mode-p perfect-margin-ignore-modes))
        (cl-some #'identity
                 (nconc (mapcar (lambda (regexp) (string-match-p regexp name)) perfect-margin-ignore-regexps)
                        (mapcar (lambda (func) (funcall func win)) perfect-margin-ignore-filters))))))

;;----------------------------------------------------------------------------
;; Minimap
;;----------------------------------------------------------------------------
(defun perfect-margin-minimap-margin-window (win)
  "Setup window margins with minimap at different stage.
WIN will be any visible window, including the minimap window."
  ;; Hint: do not reply on (window-width (minimap-get-window))
  (let ((init-window-margins (perfect-margin--init-window-margins))
        (win-edges (window-edges win)))
    (cond
     ((perfect-margin--auto-margin-ignore-p win)
      (set-window-margins win (if (perfect-margin-with-linum-p) 3 0) 0))
     ((not (minimap-get-window))
      ;; minimap-window is not available
      (cond
       ((= (frame-width) (perfect-margin--width-with-margins win))
        (set-window-margins win (car init-window-margins) (cdr init-window-margins)))
       ;; When the window is first splited and minimap-window is not set,
       ;; the minimap has the same buffer name with it's target window.
       ;; Distinguish the minimap and target window base on edge and size.
       ;;
       ;; the left hand side window when minimap window is created by
       ;; split-window-horizontally the first time.
       ;; catch and don't set minimap window
       ((and (= (nth 0 win-edges) 0)
             (= (nth 2 win-edges) (round (* perfect-margin-visible-width minimap-width-fraction)))))
       ((and (= (nth 0 win-edges) (round (* perfect-margin-visible-width minimap-width-fraction)))
             (= (or (car (window-margins win)) 0)  (car init-window-margins))
             (= (or (cdr (window-margins win)) 0)  (cdr init-window-margins)))
        ;; the newly split-off window on the right hand side, which carries init-window-margins
        (set-window-margins win
                            (max (if (perfect-margin-with-linum-p) 3 0)
                                 (- (car init-window-margins)
                                    (round (* perfect-margin-visible-width minimap-width-fraction))))
                            (cdr init-window-margins)))
       (t
        (set-window-margins win (if (perfect-margin-with-linum-p) 3 0) 0))))
     ;; catch and don't set minimap window
     ((string-match minimap-buffer-name (buffer-name (window-buffer win))))
     ((not (window-live-p (minimap-get-window)))
      ;; minimap-window is not live yet
      (cond
       ;; catch and don't set minimap window
       ((and (= (nth 0 win-edges) 0)
             (= (nth 2 win-edges) (round (* perfect-margin-visible-width minimap-width-fraction)))))
       ((and (= (nth 0 win-edges) (round (* perfect-margin-visible-width minimap-width-fraction)))
             ;; the splited target window carries original margins
             (= (or (car (window-margins win)) 0) (car init-window-margins))
             (= (or (cdr (window-margins win)) 0) (cdr init-window-margins)))
        (set-window-margins win
                            (max (if (perfect-margin-with-linum-p) 3 0)
                                 (- (car init-window-margins)
                                    (round (* perfect-margin-visible-width minimap-width-fraction))))
                            (cdr init-window-margins)))
       ((= (frame-width) (perfect-margin--width-with-margins win))
        ;; when switch window, the minimap window is kill first, set it's left adjacent window margins to nil.
        ;; left edge of win extends to frame's left-most edge, it's width increased by width of minimap window.
        (set-window-margins win (car init-window-margins) (cdr init-window-margins)))
       (t
        (set-window-margins win (if (perfect-margin-with-linum-p) 3 0) 0))))
     ;; minimap window is created, but it has the same name with it's target window
     ;; catch and don't set minimap window
     ((perfect-margin--minimap-window-p win))
     ((perfect-margin--minimap-left-adjacent-covered-p win)
      (cond
       ((not (>= (nth 2 win-edges) (frame-width)))
        (set-window-margins win (if (perfect-margin-with-linum-p) 3 0) 0))
       (t
        (set-window-margins win
                            (max (if (perfect-margin-with-linum-p) 3 0)
                                 (- (car init-window-margins)
                                    (round (* perfect-margin-visible-width minimap-width-fraction))))
                            (cdr init-window-margins)))))
     ((= (frame-width) (perfect-margin--width-with-margins win))
      (set-window-margins win (car init-window-margins) (cdr init-window-margins)))
     (t
      (set-window-margins win (if (perfect-margin-with-linum-p) 3 0) 0)))))

;;----------------------------------------------------------------------------
;; Main
;;----------------------------------------------------------------------------
(defun perfect-margin-margin-windows ()
  "Main logic to setup window's margin, keep the visible main window always at center."
  (dolist (win (window-list))
    (cond
     ((perfect-margin-with-minimap-p) (perfect-margin-minimap-margin-window win))
     ((and (not (perfect-margin--auto-margin-ignore-p win))
           (<= (frame-width) (perfect-margin--width-with-margins win)))
      (let ((init-window-margins (perfect-margin--init-window-margins)))
        (set-window-margins win (car init-window-margins) (cdr init-window-margins))))
     (t (set-window-margins win (if (perfect-margin-with-linum-p) 3 0) 0)))
    (when perfect-margin-hide-fringes
      (set-window-fringes win 0 0))))

(defun perfect-margin-margin-frame (&optional _)
  "Hook to resize window when frame size change."
  (when (frame-size-changed-p)
    (perfect-margin-margin-windows)))

;;----------------------------------------------------------------------------
;; Advice
;;----------------------------------------------------------------------------
(defun perfect-margin--linum-format (line)
  "Function for `linum-format' to set left margin for LINE to be 3 as maximum."
  (propertize
   (format (concat "%" (number-to-string (max 3 (length (number-to-string line)))) "d") line)
   'face
   'linum))

(defvar perfect-margin--linum-update-win-left-margin nil
  "Variable to store original window marings before `linum-update-window'.")

(defadvice linum-update-window (before perfect-margin-linum-update-before (win))
  "Save window's original left margin."
  (setq perfect-margin--linum-update-win-left-margin (or (car (window-margins win)) 0)))

(defadvice linum-update-window (after perfect-margin-linum-update-after (win))
  "Restore windonw's original left margin, as `linum-update-window' always reset left margin."
  (set-window-margins win perfect-margin--linum-update-win-left-margin (cdr (window-margins win))))

(defadvice minimap-update (after minimap-update-no-fringe nil)
  "Prevent fringe overlay of target buffer from drawing on `minimap-window'."
  (when (and  (minimap-get-window)
              (window-live-p (minimap-get-window))
              minimap-hide-fringes)
    (set-window-fringes (minimap-get-window) 0 0)))

(defadvice split-window (before perfect-margin--disable-margins nil)
  (dolist (win (window-list))
    (set-window-margins win 0 0)
    (when perfect-margin-hide-fringes
      (set-window-fringes win 0 0))))

;;----------------------------------------------------------------------------
;; MINOR mode definition
;;----------------------------------------------------------------------------
;;;###autoload
(define-minor-mode perfect-margin-mode
  "Auto center windows."
  :init-value nil
  :lighter perfect-margin-lighter
  :global t
  (if perfect-margin-mode
      ;; add hook and activate
      (progn
        (when (perfect-margin-with-linum-p)
          (ad-activate 'linum-update-window)
          (when (eq linum-format 'dynamic)
            (setq linum-format 'perfect-margin--linum-format)))
        (when (perfect-margin-with-minimap-p)
          (ad-activate 'minimap-update))
        (ad-activate 'split-window)
        (add-hook 'window-configuration-change-hook 'perfect-margin-margin-windows)
        (add-hook 'window-size-change-functions 'perfect-margin-margin-frame)
        (perfect-margin-margin-windows))
    ;; remove hook and restore margin
    (when (perfect-margin-with-linum-p)
      (ad-deactivate 'linum-update-window)
      (when (eq linum-format 'perfect-margin--linum-format)
        (setq linum-format 'dynamic))
      (linum-update-current))
    (when (perfect-margin-with-minimap-p)
      (ad-deactivate 'minimap-update))
    (ad-deactivate 'split-window)
    (remove-hook 'window-configuration-change-hook 'perfect-margin-margin-windows)
    (remove-hook 'window-size-change-functions 'perfect-margin-margin-frame)
    (dolist (window (window-list))
      (set-window-margins window 0 0))))

(provide 'perfect-margin)

;;; perfect-margin.el ends here
