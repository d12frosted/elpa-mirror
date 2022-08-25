;;; theme-looper.el --- A package for switching themes in Emacs interactively

;; This file is not part of Emacs

;; Author: Mohammed Ismail Ansari <team.terminal@gmail.com>
;; Version: 2.7
;; Package-Version: 20210827.424
;; Package-Commit: e6e8efd740df0b68db89805ba72492818dba61ab
;; Keywords: convenience, color-themes
;; Maintainer: Mohammed Ismail Ansari <team.terminal@gmail.com>
;; Created: 2014/03/22
;; Package-Requires: ((emacs "24") (cl-lib "0.5"))
;; Description: Loop through the available color-themes
;; URL: http://ismail.teamfluxion.com
;; Compatibility: Emacs24


;; COPYRIGHT NOTICE
;;
;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 2 of the License, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
;; for more details.
;;

;;; Install:

;; Put this file on your Emacs-Lisp load path, add following into your
;; ~/.emacs startup file
;;
;;     (require 'theme-looper)
;;
;; And assign a set of key-bindings for cycling through themes
;;
;;     (global-set-key (kbd "C-}") 'theme-looper-enable-next-theme)
;;     (global-set-key (kbd "C-{") 'theme-looper-previous-next-theme)
;;
;; Or you can switch to a random theme
;;
;;     (global-set-key (kbd "C-\\") 'theme-looper-enable-random-theme)
;;
;; Or you can choose from a list of themes through a completion interface
;; which could be either ivy or ido
;;
;;     (global-set-key (kbd "C-|") 'theme-looper-select-theme)
;;
;; You can also set a list of your favorite themes
;;
;;     (theme-looper-set-favorite-themes '(wombat tango-dark wheatgrass))
;;
;; or to use regular expressions
;;
;;     (theme-looper-set-favorite-themes-regexp "dark")
;;
;; The special symbol `*default*' represents Emacs defaults (no theme)
;;
;;     (theme-looper-set-favorite-themes '(cobalt wheatgrass *default*))
;;
;; You can alternatively set the themes to be ignored
;;
;;     (theme-looper-set-ignored-themes '(cobalt))
;;
;; or to use regular expressions
;;
;;     (theme-looper-set-ignored-themes-regexp "green")
;;
;; Or you can set both, in which case only the favorite themes that are not
;; among the ones to be ignored are used.
;;
;; If you want to reset your color-theme preferences, simply use
;;
;;     (theme-looper-reset-themes-selection)
;;
;; In order to reload the currently activated color-theme, you can use
;;
;;     (theme-looper-reload-current-theme)
;;
;; You can set hook functions to be run after every theme switch
;;
;;     (add-hook 'theme-looper-post-switch-hook 'my-func)
;;

;;; Commentary:

;;     You can use this package to cycle through color themes in Emacs with a
;;     shortcut. Select your favorite themes, unfavorite themes and key-bindings
;;     to switch color themes in style!
;;
;;  Overview of features:
;;
;;     o   Loop though available color themes conveniently
;;     o   Narrow down the list of color themes to only the ones you like
;;

;;; Code:

(require 'cl-lib)

(defvar theme-looper--favorite-themes)

(defvar theme-looper--ignored-themes
  nil)

(defvar theme-looper-post-switch-hook nil
  "Hook that runs after switch.")

(defvar theme-looper--themes-map-separator
  " | ")

(defvar theme-looper--initial-theme
  nil)

(defun theme-looper-available-themes ()
  "Lists the themes available for selection."
  (cons '*default*
        (custom-available-themes)))

;;;###autoload
(defun theme-looper-set-favorite-themes (themes)
  "Sets the list of color-themes to cycle through."
  (setq theme-looper--favorite-themes
	    themes))

;;;###autoload
(defun theme-looper-set-favorite-themes-regexp (regexp)
  "Sets the list of color-themes to cycle through, matching a regular expression."
  (setq theme-looper--favorite-themes
        (cl-remove-if-not (lambda (theme)
                            (string-match-p regexp
                                            (symbol-name theme)))
                          (theme-looper-available-themes))))

;;;###autoload
(defun theme-looper-set-ignored-themes (themes)
  "Sets the list of color-themes to ignore."
  (setq theme-looper--ignored-themes
	    themes))

;;;###autoload
(defun theme-looper-set-ignored-themes-regexp (regexp)
  "Sets the list of color-themes to ignore, matching a regular expression."
  (setq theme-looper--ignored-themes
        (cl-remove-if-not (lambda (theme)
                            (string-match-p regexp
                                            (symbol-name theme)))
                          (theme-looper-available-themes))))

;;;###autoload
(defun theme-looper-reset-themes-selection ()
  "Resets themes selection back to default."
  (theme-looper-set-favorite-themes (theme-looper-available-themes))
  (theme-looper-set-ignored-themes nil))

(defun theme-looper--get-current-theme ()
  "Determines the currently enabled theme."
  (or (car custom-enabled-themes) '*default*))

(defun theme-looper--get-current-theme-index ()
  "Finds the currently enabled color-theme in the list of color-themes."
  (cl-position (theme-looper--get-current-theme)
               (theme-looper--get-looped-themes)
               :test #'equal))

(defun theme-looper--get-looped-themes ()
  "Get themes to be looped through."
  (cl-remove-if (lambda (theme)
                  (member theme
                          theme-looper--ignored-themes))
                theme-looper--favorite-themes))

;;;###autoload
(defun theme-looper-enable-theme (theme)
  "Enables the specified color-theme.
Pass `*default*' to select Emacs defaults."
  (cl-flet* ((disable-all-themes ()
                                 (mapcar 'disable-theme
	                                     custom-enabled-themes)))
    (disable-all-themes)
    (condition-case nil
        (when (not (eq theme '*default*))
          (load-theme theme t))
      (error nil))
    (run-hooks 'theme-looper-post-switch-hook)))

(defun theme-looper--enable-theme-with-map (theme)
  "Enables a theme with displayed map."
  (cl-labels ((nth-cyclic (index collection)
                         (cond ((< index
                                   0) (nth-cyclic (+ index
                                                     (length collection))
                                   collection))
                               ((> index
                                   (1- (length collection))) (nth-cyclic (- index
                                                                            (length collection))
                                   collection))
                               (t (nth index
                                       collection))))
             (print-theme-path (theme)
                               (let ((theme-index (cl-position theme
                                                               (theme-looper--get-looped-themes)
                                                               :test #'equal)))
                                 (message (concat "theme-looper: "
                                                  (symbol-name (nth-cyclic (- theme-index 2)
                                                                           (theme-looper--get-looped-themes)))
                                                  theme-looper--themes-map-separator
                                                  (symbol-name (nth-cyclic (- theme-index 1)
                                                                           (theme-looper--get-looped-themes)))
                                                  theme-looper--themes-map-separator
                                                  (propertize (symbol-name theme)
                                                              'face
                                                              '(:inverse-video t))
                                                  theme-looper--themes-map-separator
                                                  (symbol-name (nth-cyclic (+ theme-index 1)
                                                                           (theme-looper--get-looped-themes)))
                                                  theme-looper--themes-map-separator
                                                  (symbol-name (nth-cyclic (+ theme-index 2)
                                                                           (theme-looper--get-looped-themes))))))))
    (theme-looper-enable-theme theme)
    (print-theme-path theme)))

;;;###autoload
(defun theme-looper-enable-next-theme ()
  "Enables the next color-theme in the list."
  (interactive)
  (cl-flet* ((get-next-theme-index ()
                                   (let ((current-theme-index (theme-looper--get-current-theme-index)))
                                     (cond
                                      ((equal current-theme-index
	                                          'nil)
                                       0)
                                      ((equal current-theme-index
	                                          (- (length (theme-looper--get-looped-themes))
		                                         1))
                                       0)
                                      ((+ current-theme-index
                                          1)))))
             (get-next-theme ()
                             (nth (get-next-theme-index)
                                  (theme-looper--get-looped-themes))))
    (let ((next-theme (get-next-theme)))
      (theme-looper--enable-theme-with-map next-theme))))

;;;###autoload
(defun theme-looper-enable-previous-theme ()
  "Enables the previous color-theme in the list."
  (interactive)
  (cl-flet* ((get-previous-theme-index ()
                                       (let ((current-theme-index (theme-looper--get-current-theme-index)))
                                         (cond
                                          ((equal current-theme-index
	                                              'nil)
                                           0)
                                          ((equal current-theme-index
	                                              0)
                                           (- (length (theme-looper--get-looped-themes))
                                              1))
                                          ((- current-theme-index
                                              1)))))
             (get-previous-theme ()
                                 (nth (get-previous-theme-index)
                                      (theme-looper--get-looped-themes))))
    (let ((previous-theme (get-previous-theme)))
      (theme-looper--enable-theme-with-map previous-theme))))

;;;###autoload
(defun theme-looper-enable-random-theme ()
  "Enables a random theme from the list."
  (interactive)
  (cl-flet* ((enable-theme-with-log (theme)
                                    (theme-looper-enable-theme theme)
                                    (message "theme-looper: %s"
                                             theme)))
    (let ((some-theme (nth (random (length (theme-looper--get-looped-themes)))
                           (theme-looper--get-looped-themes))))
      (enable-theme-with-log some-theme))))

;;;###autoload
(defun theme-looper-reload-current-theme ()
  "Reloads the currently activated theme."
  (interactive)
  (theme-looper-enable-theme (theme-looper--get-current-theme)))

(defun theme-looper--start-theme-selector (themes-collection)
  "Lets user select a theme from a list of specified themes rendered using a completion interface."
  (cl-flet* ((preview-theme ()
                            (let* ((current-selection (ivy-state-current ivy-last))
                                   (th (intern current-selection)))
                              (if (member th
                                          (theme-looper-available-themes))
                                  (ivy-call)))))
    (setq theme-looper--initial-theme
          (theme-looper--get-current-theme))
    (if (featurep 'ivy)
        (let ((ivy-wrap t))
          (ivy-read "theme-looper: "
                    themes-collection
                    :preselect (symbol-name (theme-looper--get-current-theme))
                    :update-fn #'preview-theme
                    :action (lambda (th)
                              (theme-looper-enable-theme (intern th)))
                    :unwind (lambda ()
                              (when theme-looper--initial-theme
                                (theme-looper-enable-theme theme-looper--initial-theme)))))
      (theme-looper-enable-theme (intern (ido-completing-read "theme-looper: "
                                                              (mapcar #'symbol-name
                                                                      themes-collection)))))))

;;;###autoload
(defun theme-looper-select-theme ()
  "Lets user select a theme from a list of favorite ones rendered using a completion interface."
  (interactive)
  (theme-looper--start-theme-selector (theme-looper--get-looped-themes)))

;;;###autoload
(defun theme-looper-select-theme-from-all ()
  "Lets user select a theme from a list of all available themes rendered a completion interface."
  (interactive)
  (theme-looper--start-theme-selector (theme-looper-available-themes)))

(theme-looper-reset-themes-selection)

(provide 'theme-looper)

;;; theme-looper.el ends here
