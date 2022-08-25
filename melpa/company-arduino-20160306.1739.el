;;; company-arduino.el --- company-mode for Arduino -*- lexical-binding: t; -*-

;; Copyright (C) 2015  Yuta Yamada

;; Author: Yuta Yamada <sleepboy.zzz@gmail.com>
;; Keywords: convenience development company
;; Package-Version: 20160306.1739
;; Package-Commit: 5958b917cc5cc729dc64d74d947da5ee91c48980
;; Version: 0.1.0
;; URL: https://github.com/yuutayamada/company-arduino
;; Package-Requires: ((emacs "24.1") (company "0.8.0") (irony "0.1.0") (cl-lib "0.5") (company-irony "0.1.0") (company-c-headers "20140930") (arduino-mode "1.0"))

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
;; This package is a set of configuration to let you auto-completion
;; by using `irony-mode', `company-irony' and `company-c-headers' on arduino-mode.
;;
;; Prerequisite:
;; This package need irony-mode, company-irony and company-c-headers
;; packages. Please install those packages first. But if you are using
;; MELPA, package.el will install dependencies automatically when you install
;; this package. Also, you need irony-mode's setting, so please follow
;; the irony-mode's instruction (https://github.com/Sarcasm/irony-mode).
;;
;; Although you may prepared Arduino environment, you need it as well to
;; refer to Arduino's header files. You can download from Arduino's web site
;; (http://www.arduino.cc/en/Main/Software)
;;
;; Usage:
;; Set $ARDUINO_HOME environment variable as Arduino IDE's installed directory.
;; (i.e., export ARDUINO_HOME=$HOME/share/devkit/arduino-1.6.3 on zsh)
;;
;; Then put following configurations to your .emacs or somewhere.
;;
;;   ;; Emacs configuration
;;   ;; If you installed this package from without MELPA, you may need
;;   ;; `(require 'company-arduino)'.
;;
;;   ;; Configuration for irony.el
;;   ;; Add arduino's include options to irony-mode's variable.
;;   (add-hook 'irony-mode-hook 'company-arduino-turn-on)
;;
;;   ;; Configuration for company-c-headers.el
;;   ;; The `company-arduino-append-include-dirs' function appends
;;   ;; Arduino's include directories to the default directories
;;   ;; if `default-directory' is inside `company-arduino-home'. Otherwise just
;;   ;; returns the default directories.
;;   ;; Please change the default include directories accordingly.
;;   (defun my-company-c-headers-get-system-path ()
;;     "Return the system include path for the current buffer."
;;     (let ((default '("/usr/include/" "/usr/local/include/")))
;;       (company-arduino-append-include-dirs default t)))
;;   (setq company-c-headers-path-system 'my-company-c-headers-get-system-path)
;;
;;   ;; Activate irony-mode on arudino-mode
;;   (add-hook 'arduino-mode-hook 'irony-mode)
;;
;;   ;; If you are already using ‘company-irony’ and ‘company-c-headers’,
;;   ;; you might have same setting. That case, you can omit below setting.
;;   (add-to-list 'company-backends 'company-irony)
;;   (add-to-list 'company-backends 'company-c-headers)
;;
;; Note:
;; This package's default configuration is set for Linux environment,
;; which I'm currently using, so if you are using different
;; environment (Mac or Windows), please change the Arduino's directory paths accordingly.
;; Related variables: `company-arduino-sketch-directory-regex', `company-arduino-home',
;; `company-arduino-header', `company-arduino-includes-dirs' and `irony-arduino-includes-options'.
;;
;;; Code:

(require 'cl-lib)
(require 'irony)
(require 'company-c-headers)

(defvar company-arduino-sketch-directory-regex
  ;; I'm not sure about Mac and Windows environment.
  ;; https://github.com/arduino/Arduino/blob/master/build/shared/manpage.adoc#files
  (format "^%s" (file-truename (cl-case system-type
                                 (darwin "~/Documents/Arduino")
                                 ((ms-dos windows-nt) "My Documents\\Arduino") ; <- please help
                                 (t "~/Arduino"))))
  "Regex to distinguish `default-directory' is inside of sketch directory.
If you are Mac or Windows user, please refer to
https://github.com/arduino/Arduino/blob/master/build/shared/manpage.adoc#files
to get right name.  Or if you build from Arduino IDE's command line, you can set
wherever you want to develop Arduino application.")

(defvar company-arduino-home (file-truename (or (getenv "ARDUINO_HOME") ""))
  "Installed directory of Arduino IDE.  Default value is $ARDUINO_HOME.")

(defvar company-arduino-header (format "%s%s" company-arduino-home "/hardware/arduino/avr/cores/arduino/Arduino.h")
  "Place of Arduino.h, which Arduino IDE includes by default.")

(defvar company-arduino-includes-dirs
  (cl-loop with dirs = '("/hardware/arduino/avr/cores/arduino/"
                         "/hardware/tools/avr/include/"
                         "/hardware/arduino/avr/libraries/")
           for include-dir in dirs
           collect (format "%s%s" company-arduino-home include-dir) into include-dirs
           finally return include-dirs)
  "Arduino's specific include directories.")

(defvar irony-arduino-includes-options
  (append (cl-loop for dir in company-arduino-includes-dirs
                   collect (format "-I%s" dir))
          `("-include" ,company-arduino-header))
  "Options are merged to return value of `irony--adjust-compile-options'.")

;;;###autoload
(defun company-arduino-append-include-dirs (original &optional only-dirs)
  "Append Arduino's include directoreis to ORIGINAL.
If you set non-nil to ONLY-DIRS, the return value is appended
`company-arduino-includes-dirs'  Otherwise, it appends `irony-arduino-includes-options'."
  (if (not (or (company-arduino-sketch-directory-p)
               (eq 'arduino-mode major-mode)))
      original
    (if only-dirs
        (append original company-arduino-includes-dirs)
      (append original irony-arduino-includes-options))))

;;;###autoload
(defun company-arduino-sketch-directory-p ()
  "Check whether current directory is in sketch directory or not."
  (string-match company-arduino-sketch-directory-regex default-directory))

;;; For irony-mode
(add-to-list 'irony-supported-major-modes 'arduino-mode)
(add-to-list 'irony-lang-compile-option-alist '(arduino-mode . "c++"))

;; TODO: add include path of sketch directory's `libraries` directory dynamically.
(defadvice irony--adjust-compile-options (around company-arduino-add-compile-options disable)
  "Add Arduino specific compile options if the directory is related to Arduino."
  ad-do-it
  (setq ad-return-value (company-arduino-append-include-dirs ad-return-value)))

;;;###autoload
(defun company-arduino-turn-on ()
  "Enable advice for `irony--adjust-compile-options' to add arduino's specific options."
  (ad-enable-advice 'irony--adjust-compile-options 'around 'company-arduino-add-compile-options)
  (ad-activate 'irony--adjust-compile-options))

;;;###autoload
(defun company-arduino-turn-off ()
  "Disable advice for `irony--adjust-compile-options' of company-arduino.el."
  (ad-disable-advice 'irony--adjust-compile-options 'around 'company-arduino-add-compile-options)
  (ad-activate 'irony--adjust-compile-options))

;;; For company-c-headers
(add-to-list 'company-c-headers-modes
             ;; same as c++
             (cons 'arduino-mode (assoc-default 'c++-mode company-c-headers-modes)))

(provide 'company-arduino)
;;; company-arduino.el ends here
