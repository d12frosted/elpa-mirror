;;; per-buffer-theme.el --- Change theme and font according to buffer name or major mode.  -*- lexical-binding:t -*-

;; Copyright (C) 2015-2022 Free Software Foundation, Inc.

;; Author: Iñigo Serna <inigoserna@gmx.com>
;; URL: https://hg.serna.eu/emacs/per-buffer-theme
;; Package-Version: 20221002.2219
;; Package-Commit: 2cbb15c05edff4ce23ce61858cf16e8953cd58b3
;; Version: 2.2
;; Keywords: themes
;; Package-Requires: ((emacs "25.1"))

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:

;; `per-buffer-theme.el' is an Emacs library that automatically changes
;; the global theme and frame font according to buffer name or major mode.
;;
;; Run the command `per-buffer-theme-mode' to toggle the minor-mode which
;; enables or disables the package.
;;
;; If buffer name matches any of `per-buffer-theme-ignored-buffernames-regex'
;; no theme or font change occurs.
;;
;; Customizable variable `per-buffer-theme-themes-alist' contains the
;; association between themes and buffer name or major modes.
;;
;; Special `notheme' theme name can be used to force the unload all themes
;; and use Emacs default theme.
;;
;; If there aren't any matches then it will load the theme stored in
;; `per-buffer-theme-default-theme' variable and the font stored in
;; `per-buffer-theme-default-font' variable, or the default font.
;;
;; There are two different methods in which buffer and theme can be checked.
;; It is controlled by customizable boolean `per-buffer-theme-use-timer':
;;
;; - 't' will use a timer, triggered every `per-buffer-theme-timer-idle-delay'
;;   seconds.  This is the default as it works smoothly.
;;   If it slows down Emacs a bit choose a bigger delay value.
;;
;; - 'nil' uses a function advice to `select-window' so it could introduce
;;   some Emacs windows flickering when switching buffers due to how
;;   `select-window' internally works.


;;; Updates:

;; 2015/04/12 Initial version.
;; 2015/04/13 Changed `per-buffer-theme-theme-list' data type from plist
;;            to alist to make customization easier.
;;            Make code comply with (some) Emacs Lisp Code Conventions:
;;            - added public function to unload hook
;; 2015/09/25 Use advice function instead of hooks, it's more robust.
;; 2015/10/13 As themes are cumulative, remove previous theme definitions
;;            before applying new one.
;; 2016/03/18 Don't update theme if temporary or hidden buffers.
;;            Added alternative timer-based method to check buffer and theme.
;;            Thanks to Clément Pit--Claudel and T.V. Raman for the suggestions.
;; 2019/07/03 Fix behaviour when notheme used as default-theme.
;;            Thanks to Andrea Greselin for report and fix.
;; 2020/05/27 Added font support.
;;            Defined as minor-mode.
;;            Cleaned code. Removed cl-lib dependency.
;; 2022/10/02 Fixed some typos in headers which prevent building MELPA package.
;; 2022/10/03 Modify package symbols to comply with the conventions.


;;; Code:


;;; Customization
(defgroup per-buffer-theme nil
  "Change theme according to buffer name or major mode."
  :link '(emacs-library-link :tag "Source Lisp File" "per-buffer-theme.el")
  :prefix "per-buffer-theme-"
  :group 'customize)

(defcustom per-buffer-theme-default-theme 'leuven
  "Default theme to be used if no matching is found."
  :type 'symbol
  :group 'per-buffer-theme)

(defcustom per-buffer-theme-default-font nil
  "Default font to be used if no matching is found."
  :type 'string
  :group 'per-buffer-theme)

(defcustom per-buffer-theme-ignored-buffernames-regex '("*[Mm]ini" "*[Hh]elm" "*[Oo]rg" "*[Cc]alendar" "*[Cc]alc" "*SPEEDBAR*" "*NeoTree*")
  "If current buffer name matches one of these it won't change the theme."
  :type '(repeat string)
  :group 'per-buffer-theme)

(defcustom per-buffer-theme-themes-alist
      '(((:theme . adwaita)
         (:font . nil)
         (:buffernames . ("*info" "*eww" "*w3m" "*mu4e"))
         (:modes . (eww-mode w3m-mode cfw:calendar-mode mu4e-main-mode mu4e-headers-mode mu4e-view-mode mu4e-compose-mode mu4e-about-mode mu4e-update-mode)))
        ((:theme . notheme)
         (:font . nil)
         (:buffernames . ("*Help*"))
         (:modes . (nil))))
  "An alist with default associations (theme font buffernames modes).
Special `notheme' theme can be used to unload all themes and use Emacs
default theme."
  :type '(repeat alist)
  :group 'per-buffer-theme)

(defcustom per-buffer-theme-use-timer t
  "Use timer (t, default) or check buffer when switching (nil)."
  :type 'boolean
  :group 'per-buffer-theme)

(defcustom per-buffer-theme-timer-idle-delay 0.5
  "Number of seconds between buffer and theme checks."
  :type 'float
  :group 'per-buffer-theme)


;;; Variables
(defvar per-buffer-theme--current-theme nil
  "Theme in use.")

(defvar per-buffer-theme--initial-font nil
  "Initial font.")

(defvar per-buffer-theme--timer nil
  "Private variable to store idle timer.")


;;; Functions
(defun per-buffer-theme--match-theme (buffer)
  "Return (theme font) if BUFFER name or major-mode match in
`per-buffer-theme-themes-alist' or nil."
  (let ((alist per-buffer-theme-themes-alist)
        newtheme
        newfont)
    ;; (message "THEMES: %s" (prin1-to-string alist))
    (while alist
      (let* ((elm (pop alist))
             (theme (cdr (assoc :theme elm)))
             (font (cdr (assoc :font elm)))
             (buffernames (cdr (assoc :buffernames elm)))
             (modes (cdr (assoc :modes elm))))
        ;; (message "Theme: %s" (prin1-to-string theme))
        ;; (message "Font:  %s" (prin1-to-string font))
        ;; (message "    Buffer names: %s" (prin1-to-string buffernames))
        ;; (message "    Major modes:  %s" (prin1-to-string modes))
        (when (and (car buffernames) (seq-some #'(lambda (regex) (string-match regex (buffer-name buffer))) buffernames))
          ;; (message "=> Matched buffer name with regex '%s' => Theme: %s | Font: %S" (match-string 0 (buffer-name buffer)) theme font)
          (setq newtheme theme
                newfont font
                alist nil))
        (when (member major-mode modes)
          ;; (message "=> Matched with major mode '%s' => Theme: %s | Font: %S" major-mode theme font)
          (setq newtheme theme
                newfont font
                alist nil))))
    (list (cons :theme newtheme) (cons :font newfont))))

(defun per-buffer-theme-change-theme-if-buffer-matches (&optional buffer)
  "Change theme and font according to BUFFER major mode or name.
Don't do anything if buffer name matches in
`per-buffer-theme-ignored-buffernames-regex'.
Search for theme matches in `per-buffer-theme-themes-alist'
customizable variable.
If none is found uses default theme stored in `per-buffer-theme-default-theme'.
Special `notheme' theme can be used to disable all loaded themes."
  (interactive)
  (setq buffer (or buffer (current-buffer)))
  (let ((bufname (buffer-name buffer)))
    (when (and (get-buffer-window buffer)
               (not (string-prefix-p " " bufname))
               (not (seq-some #'(lambda (regex) (string-match regex bufname)) per-buffer-theme-ignored-buffernames-regex)))
      (let* ((res (per-buffer-theme--match-theme buffer))
             (theme (cdr (assoc :theme res)))
             (font (cdr (assoc :font res))))
        ;; (message "=> Returned theme: %S | font: %S" theme font)
        (unless (equal per-buffer-theme--current-theme theme)
          ; as themes are cumulative, remove previous theme definitions before applying new one
          (mapc #'disable-theme custom-enabled-themes)
          (cond
           ((equal theme 'notheme)
            t) ; mapc #'disable... already executed above
           ((equal theme nil)
            (unless (equal per-buffer-theme-default-theme 'notheme)
              (load-theme per-buffer-theme-default-theme t)))
           (t
            (load-theme theme t)))
          (setq per-buffer-theme--current-theme theme))
        (when (display-graphic-p)
          (set-frame-font (or font per-buffer-theme-default-font per-buffer-theme--initial-font)))))))


;;; Initialiation
(defun per-buffer-theme--advice-function (window &optional norecord)
  "Advice function to `select-window'."
  (per-buffer-theme-change-theme-if-buffer-matches (window-buffer window)))

(defun per-buffer-theme--enable ()
  "Enable `per-buffer-theme' package."
  (if (and per-buffer-theme-use-timer (not per-buffer-theme--timer))
      (setq per-buffer-theme--timer (run-with-idle-timer per-buffer-theme-timer-idle-delay t #'per-buffer-theme-change-theme-if-buffer-matches))
    (advice-add 'select-window :before 'per-buffer-theme--advice-function))
  (message "per-buffer-theme enabled."))

(defun per-buffer-theme--disable ()
  "Disable `per-buffer-theme' package."
  (if per-buffer-theme-use-timer
      (when (timerp per-buffer-theme--timer)
        (cancel-timer per-buffer-theme--timer)
        (setq per-buffer-theme--timer nil))
    (advice-remove 'select-window 'per-buffer-theme--advice-function))
  (message "per-buffer-theme disabled."))

;;;###autoload
(defun per-buffer-theme-enable ()
  "Deprecated, please use `per-buffer-theme-mode'."
  (interactive)
  (per-buffer-theme-mode 1)
  (error "This command is deprecated, please use `per-buffer-theme-mode'"))

;;;###autoload
(defun per-buffer-theme-disable ()
  "Deprecated, please use `per-buffer-theme-mode'."
  (interactive)
  (per-buffer-theme-mode -1)
  (error "This command is deprecated, please use `per-buffer-theme-mode'"))

;;;###autoload
(define-minor-mode per-buffer-theme-mode
  "Changes theme and/or font according to buffer name or major mode."
  :init-value nil
  :global t
  :lighter " Per buffer theme"
  (if per-buffer-theme-mode
      (progn
        (setq per-buffer-theme--initial-font (frame-parameter nil 'font-parameter))
        (per-buffer-theme--enable))
    (per-buffer-theme--disable)
    (when per-buffer-theme--initial-font
      (set-frame-font per-buffer-theme--initial-font))))


(provide 'per-buffer-theme)

;;; per-buffer-theme.el ends here
