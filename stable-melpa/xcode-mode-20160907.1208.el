;;; xcode-mode.el --- A minor mode for emacs to perform Xcode like actions.

;; Copyright (C) 2015 Nickolas Lanasa

;; Author: Nickolas Lanasa <nick@nytekproductions.com>,
;; Keywords: conveniences
;; Package-Version: 20160907.1208
;; Package-Commit: 5b5f0a4f505d44840a4924b24e3ef73b8528d98b
;; Version: 0.1
;; Package-Requires: ((emacs "24.4") (s "1.10.0") (dash "2.11.0") (multiple-cursors "1.0.0"))

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

(require 'cl-lib)
(require 'subr-x)
(require 'json)
(require 'hydra)

(defvar xcode-mode-map
  (make-sparse-keymap)
  "Keymap for xcode.")

;; com.apple.CoreSimulator.SimDeviceType.iPhone-4s, 9.2
;; com.apple.CoreSimulator.SimDeviceType.iPhone-5, 9.2
;; com.apple.CoreSimulator.SimDeviceType.iPhone-5s, 9.2
;; com.apple.CoreSimulator.SimDeviceType.iPhone-6, 9.2
;; com.apple.CoreSimulator.SimDeviceType.iPhone-6-Plus, 9.2
;; com.apple.CoreSimulator.SimDeviceType.iPhone-6s, 9.2
;; com.apple.CoreSimulator.SimDeviceType.iPhone-6s-Plus, 9.2
;; com.apple.CoreSimulator.SimDeviceType.iPad-2, 9.2
;; com.apple.CoreSimulator.SimDeviceType.iPad-Retina, 9.2
;; com.apple.CoreSimulator.SimDeviceType.iPad-Air, 9.2
;; com.apple.CoreSimulator.SimDeviceType.iPad-Air-2, 9.2
;; com.apple.CoreSimulator.SimDeviceType.iPad-Pro, 9.2
;; com.apple.CoreSimulator.SimDeviceType.Apple-TV-1080p, 9.1
;; com.apple.CoreSimulator.SimDeviceType.Apple-Watch-38mm, 2.1
;; com.apple.CoreSimulator.SimDeviceType.Apple-Watch-42mm, 2.1

(defvar xcode-ios-sim-devicetype "com.apple.CoreSimulator.SimDeviceType.iPhone-6, 9.3")

;;;###autoload
(define-minor-mode xcode-mode
  "Minor mode to perform xcode like actions."
  :lighter " xcode"
  :keymap xcode-mode-map)

;;; Keybindings ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Hydra
(define-key xcode-mode-map
  (kbd"C-M-x h") 'xcode-launcher/body)

;; Build then run
(define-key xcode-mode-map
  (kbd"C-M-x br") 'xcode-xctool-build-and-run)

(define-key xcode-mode-map
  (kbd"C-M-x rr") 'xcode-xctool-run)

;; Building
(define-key xcode-mode-map
  (kbd"C-M-x bb") 'xcode-xctool-build)

;; Testing
(define-key xcode-mode-map
  (kbd "C-M-x rt") 'xcode-xctool-run-tests)
(define-key xcode-mode-map
  (kbd "C-M-x bt") 'xcode-xctool-build-tests)
(define-key xcode-mode-map
  (kbd "C-M-x tt") 'xcode-xctool-test)
(define-key xcode-mode-map
  (kbd "C-M-x to") 'xcode-xctool-build-tests-only)
(define-key xcode-mode-map
  (kbd "C-M-x ro") 'xcode-xctool-run-tests-only)

;; Cleaning
(define-key xcode-mode-map
  (kbd "C-M-x cc") 'xcode-xctool-clean)

;; Cocoapods
(define-key xcode-mode-map
  (kbd "C-M-x pi") 'xcode-pod-install)

;; Opening in Xcode
(define-key xcode-mode-map
  (kbd "C-M-x os") 'xcode-open-storyboard)
(define-key xcode-mode-map
  (kbd "C-M-x op") 'xcode-open-project)
(define-key xcode-mode-map
  (kbd "C-M-x ow") 'xcode-open-workspace)

;; Archiving
(define-key xcode-mode-map
  (kbd "C-M-x aa") 'xcode-xctool-archive)

;; Helpers
(define-key xcode-mode-map
  (kbd "C-M-x dd") 'xcode-delete-derived-data)

;;; FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Hydra

(defhydra xcode-launcher (:color teal :hint nil)
  "
   Xcode: %(xcode-project-directory)

   Build                     Run                     Open
------------------------------------------------------------------------------------
  _ba_: Archive             _pi_: Run Pod Install   _op_: Open Project
  _bb_: Build               _rr_: Run               _os_: Open Storyboard
  _br_: Build and Run       _rt_: Run Tests         _ow_: Open Workspace
  _bt_: Builds Tests        _tt_: Run Test
  _bT_: Builds Tests Only
  _cc_: Clean

  "
  ("ba" xcode-xctool-archive)
  ("bb" xcode-xctool-build)
  ("br" xcode-xctool-build-and-run)
  ("bt" xcode-xctool-build-tests)
  ("bT" xcode-xctool-build-tests-only)
  ("cc" xcode-xctool-clean)
  ("dd" xcode-delete-derived-data "Delete Derived Data")
  ("op" xcode-open-storyboard)
  ("ow" xcode-open-workspace)
  ("os" xcode-open-project)
  ("pi" xcode-pod-install)
  ("rr" xcode-xctool-run)
  ("rt" xcode-xctool-run-tests)
  ("tt" xcode-xctool-test)
  ("q" nil "Cancel"))

;; Interface builder

(defun xcode-open-storyboard ()
  "Select and open storyboard."
  (interactive)
  (xcode-open (xcode-completing-read
	       "Open storyboard: "
	       (xcode-find-storyboards-for-directory default-directory) nil t)))

;; Building

(defun xcode-xctool-build ()
  "Builds the Xcode project using xctool."
  (interactive)
  (xcode-compile "xctool build"))

;; Running

(defun xcode-xctool-run ()
  "Runs the Xcode project in sim using xctool."
  (interactive)
  (xcode-in-root (compile
                  (format "ios-sim launch %s --devicetypeid '%s'"
                          (let ((xcode-binaries (xcode-find-binaries)))
                            (if (eq 1 (length xcode-binaries))
                                (car xcode-binaries)
                              (xcode-completing-read
                               "Select app: "
                               xcode-binaries nil t)))
                          xcode-ios-sim-devicetype))))

(defun xcode-xctool-build-and-run ()
  "Build and run the in sim using xctool"
  (interactive)
  (message "Building...")
  (add-hook 'compilation-finish-functions 'xcode-on-build-finish)
  (xcode-compile "xctool build"))

(defun xcode-on-build-finish (buffer desc)
  "Callback function after compilation finishes."
  (xcode-xctool-run)
  (remove-hook 'compilation-finish-functions 'xcode-on-build-finish))

;; Cleaning

(defun xcode-xctool-clean()
  "Cleans the project using xctool."
  (interactive)
  (xcode-compile "xctool clean"))

;; Testing

(defun xcode-xctool-run-tests ()
  "Tests a project using .xctool-args file in current directory."
  (interactive)
  (xcode-compile "xctool run-tests"))

(defun xcode-xctool-build-tests ()
  "Tests a project using .xctool-args file in current directory."
  (interactive)
  (xcode-compile "xctool build-tests"))

(defun xcode-xctool-test ()
  "Test the Xcode project using xctool."
  (interactive)
  (xcode-compile "xctool test"))

(defun xcode-xctool-test-only (scheme)
  "Test the Xcode project using xctool with a specific scheme."
  (interactive "sEnter scheme: ")
  (xcode-compile (format "xctool test -only %s" scheme)))

(defun xcode-xctool-run-tests-only (scheme)
  "Runs tests the Xcode project using xctool with a specific scheme."
  (interactive "sEnter scheme: ")
  (xcode-compile (format "xctool run-tests -only %s" scheme)))

(defun xcode-xctool-build-tests-only (scheme)
  "Builds tests the Xcode project using xctool with a specific scheme."
  (interactive "sEnter scheme: ")
  (xcode-compile (format "xctool build-tests -only %s" scheme)))

;; Archiving

(defun xcode-xctool-archive ()
  "Archive the Xcode project."
  (interactive)
  (xcode-compile "xctool archive -configuration Release"))

;; Cocoapods

(defun xcode-pod-install()
  "Runs pod install."
  (interactive)
  (xcode-compile "pod install"))

;; Helpers

(defcustom xcode-completing-read-function 'completing-read
  "Function to be called when requesting input from the user."
  :group 'xcode-mode
  :type '(radio (function-item completing-read)
                (function :tag "Other")))

(defmacro xcode-completing-read (&rest body)
  `(funcall xcode-completing-read-function ,@body))

(defun xcode-open-workspace ()
  "Open workspace in Xcode"
  (interactive)
  (shell-command
   (format "open -a Xcode %s"
	   (xcode-completing-read
	    "Select workspace: "
	    (xcode-find-workspaces-for-directory default-directory) nil t))))

(defun xcode-open-project ()
  "Open project in Xcode"
  (interactive)
  (shell-command
   (format "open -a Xcode %s"
	   (xcode-completing-read
	    "Select project: "
	    (xcode-find-projects-for-directory default-directory) nil t))))

(defun xcode-open (file)
  "Open file in Xcode"
  (interactive)
  (shell-command (format "open -a Xcode %s" file)))

(defun xcode-delete-derived-data ()
  (interactive)
  (xcode-compile
   (format "rm -r ~/Library/Developer/Xcode/DerivedData/%s"
	   (xcode-completing-read
	    "Select folder: "
	    (xcode-derived-data-list) nil t))))

(defun xcode-derived-data-list ()
  (mapcar #'string-trim
	  (split-string
	   (shell-command-to-string "ls ~/Library/Developer/Xcode/DerivedData/"))))

(defun xcode-find-binaries ()
  (mapcar #'string-trim
	  (split-string
	   (shell-command-to-string "find ~/Library/Developer/Xcode/DerivedData/ -name '*.app'"))))

(defun xcode-find-storyboards-for-directory (directory)
  (mapcar #'string-trim
          (split-string
           (shell-command-to-string
            (format "find %s -name '*storyboard'" (substring directory 0 -1))))))

(defun xcode-select-project ()
  (xcode-completing-read
   "Select project: "
   (xcode-find-projects-for-directory default-directory) nil t))

(defun xcode-select-workspace ()
  (xcode-completing-read
   "Select workspace: "
   (xcode-find-workspaces-for-directory default-directory) nil t))

(defun xcode-find-workspaces-for-directory (directory)
  (mapcar #'string-trim
          (split-string
           (shell-command-to-string
            (format "find %s -name '*workspace'" directory)))))

(defun xcode-find-projects-for-directory (directory)
  (mapcar #'string-trim
          (split-string
           (shell-command-to-string
            (format "find %s -name '*xcodeproj'")))))

(defun xcode-find-schemes-for-workspace (workspace)
  (mapcar #'string-trim
          (cdr (cdr (split-string (shell-command-to-string
                                   (format "xcodebuild -workspace %s -list" workspace)) "\n")))))

(defun xcode-find-schemes-for-project (project)
  (mapcar #'string-trim
          (cdr (cdr (split-string (shell-command-to-string
                                   (format "xcodebuild -project %s -list" project)) "\n")))))


(defvar xcode-platforms-list nil)

(defun xcode-get-platform-list ()
  (setq xcode-platforms-list
        (cdr (assoc 'devices
                    (json-read-from-string
                     (shell-command-to-string "xcrun simctl list devices -j"))))))

(defun xcode-get-device-list (platform)
  (let ((platforms (cdr (cl-assoc-if #'(lambda(str) (string= platform str))
				     xcode-platforms-list))))
    (mapcar (lambda (element)
              (let ((device-list '()))
                (let ((device (cdr element))
                      (udid (cdr (car element))))
                  (cons (concat (cdr (assoc 'name device)) (concat " - " udid)) device-list))))
            (append platforms nil))))

(defun xcode-select-destination-id ()
  (nth 3
       (split-string
        (xcode-completing-read "Select device:"
			       (xcode-get-device-list
				(xcode-completing-read "Select platform:"
						       (xcode-get-platform-list) nil t)) nil t))))

(defun xcode-select-sdk ()
  (xcode-completing-read "Select SDK:" '("iphoneos" "macosx" "appletvos" "watchos" "iphonesimulator") nil t))

(defun xcode-select-build-config ()
  (xcode-completing-read "Select build config:" '("Debug" "Release") nil t))

(defun xcode-compile (command)
  (xcode-in-root
   (compile command)))

(defun xcode-use-xctool ()
  (setq xcode-xctool-path "/usr/local/bin/xctool"))

(defmacro xcode-in-root (body)
  "Execute BODY form with `xcode-project-directory' as
``default-directory''."
  `(let ((default-directory (xcode-project-directory)))
     ,body))

(defun xcode-project-directory ()
  "Get project directory.
If projectile available, use projectile.
Else, use locate-dominating-file.
Finally fall back to the current directory."
  (or (locate-dominating-file default-directory ".xctool-args")
      (if (fboundp 'projectile-project-root)
	  (projectile-project-root)
	default-directory)))

(provide 'xcode-mode)
;;; xcode-mode.el ends here
