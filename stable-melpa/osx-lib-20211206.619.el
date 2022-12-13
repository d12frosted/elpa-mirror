;;; osx-lib.el --- Basic functions for Apple/OSX -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2015 OSX Lib authors
;;
;; Author: Raghav Kumar Gautam <raghav@apache.org>
;; URL: https://github.com/raghavgautam/osx-lib
;; Package-Commit: 7afdb57edd5725e8a66f841a90fa571a4cbb81e7
;; Keywords: Apple, AppleScript, OSX, Finder, Emacs, Elisp, VPN, Speech
;; Package-Requires: ((emacs "24.4"))
;; Package-Version: 20211206.619
;; Package-X-Original-Version: 0.1
;;; Commentary:
;; Provides functions for:
;;   1. Running Apple Script / osascript
;;   2. Play beep
;;      (setq ring-bell-function #'osx-lib-do-beep)
;;   3. Notification functions
;;      (osx-lib-notify2 "Emacs" "Text Editor")
;;   4. Copying to/from clipboard
;;   5. Show the current file in Finder.  Works with dired.
;;   6. Get/Set Sound volume
;;      (osx-lib-set-volume 25)
;;      (osx-lib-get-volume)
;;   6. Mute/unmute Sound volume
;;      (osx-lib-mute-volume)
;;      (osx-lib-unmute-volume)
;;   8. VPN Connect/Disconnect
;;      (defun work-vpn-connect ()
;;        "Connect to Work VPN."
;;        (interactive)
;;        (osx-lib-vpn-connect "WorkVPN" "VPN_Password"))
;;   9. Use speech
;;      (osx-lib-say "Emacs")
;;   10.Use mdfind(commandline equivalent of Spotlight) for locate
;;      (setq locate-make-command-line #'osx-locate-make-command-line)
;;
;;; Code:
;;running apple script

(require 'dired)
(require 'eshell)
(require 'subr-x)

(defcustom osx-lib-say-voice nil
  "Speech voice to use for osx-lib-say.  Nil/empty means default speech voice."
  :group 'osx-lib)

(defcustom osx-lib-say-rate nil
  "Speech rate to be used, in words per minute. Average human speech occurs at a rate of 180 to 220 words per minute. Default depends on the voice used."
  :group 'osx-lib)

(defcustom osx-lib-debug-level nil
  "Debug level for osx-lib.  Highier value implies more information."
  :group 'osx-lib)

(defun osx-lib-escape (str)
  "Escape STR to make it suitable for using is applescripts."
  (replace-regexp-in-string "\"" "\\\\\"" str))

;; Constants for major releases of macOS
;; macOS versions are formatted at MAJOR.MINOR[.PATCH]

(defconst osx-lib-ver-monterey "12.0"
  "Release version of macOS Monterey.")

(defconst osx-lib-ver-big-sur "11.0"
  "Release version of macOS Big Sur.")

(defconst osx-lib-ver-catalina "10.15"
  "Release version of macOS Catalina.")

(defconst osx-lib-ver-yosemite "10.10"
  "Release version of macOS Yosemite.")

;; macros

(defmacro with-min-osx-ver (min-ver &rest body)
  "Execute BODY if current macOS version meets MIN-VER requirement.
Otherwise prints error message."
  `(if (string-lessp (osx-lib-osx-version) ,min-ver)
       (message (concat "Unsupported on this version of macOS, minimum required: " ,min-ver))
     ,@body))

;;;###autoload
(defun osx-lib-run-osascript (script-content)
  "Run an SCRIPT-CONTENT as AppleScript/osascipt."
  (interactive "sContent of AppleScript/osascript:")
  (let  ((file (make-temp-file "osx-lib-" nil ".scpt")))
    (with-temp-file file
      (insert script-content)
      ;;delete the script after execution
      (unless osx-lib-debug-level
        (insert "\ndo shell script \"rm -rf \" & the quoted form of POSIX path of (path to me)")))
    (osx-lib-run-file file)))

(defun osx-lib-run-file (file)
  "Run an AppleScript/osascipt FILE."
  (when osx-lib-debug-level
    (with-current-buffer "*OsaScript*"
      (insert "Going to run file: " file)))
  (start-process "OsaScript" "*OsaScript*" "osascript" file))

;;;###autoload
(defun osx-lib-osx-version ()
  "Get OS version."
  (interactive)
  (string-trim (shell-command-to-string
        "sw_vers  -productVersion")))

(defun osx-lib-run-js-file (file)
  "Run an AppleScript/osascipt FILE."
  (start-process "OsaScript" "*OsaScript*" "osascript" "-l" "JavaScript" file))

;;;###autoload
(defun osx-lib-run-js (script-content)
  "Run an SCRIPT-CONTENT as JavaScript."
  (interactive "sContent of JavaScript AppleScript/osascript:")
  (let  ((file (make-temp-file "osx-lib-" nil ".js")))
    (with-temp-file file
      (insert script-content)
      ;;delete the script after execution
      ;;(insert "\ndo shell script \"rm -rf \" & the quoted form of POSIX path of (path to me)")
      )
    (osx-lib-run-js-file file)))

(defalias 'osx-lib-run-applescript 'osx-lib-run-osascript)

;;;###autoload
(defun osx-lib-do-beep ()
  "Play beep sound."
  (osx-lib-run-applescript "beep"))

;;notification fuctions
;;;###autoload
(defun osx-lib-notify2 (title message)
  "Create a notification with title as TITLE and message as MESSAGE."
  (osx-lib-run-osascript
   (concat "display notification \""
       (osx-lib-escape message)
       "\" with title  \""
       (osx-lib-escape title)
       "\"")))

;;;###autoload
(defun osx-lib-notify3 (title subtitle message)
  "Create a notification with title as TITLE, subtitle as SUBTITLE and message as MESSAGE."
  (osx-lib-run-osascript
   (concat "display notification \""
       (osx-lib-escape message)
       "\" with title  \""
       (osx-lib-escape title)
       "\" subtitle \""
       (osx-lib-escape subtitle)
       "\"")))

;;clipboard functions
;;;###autoload
(defun osx-lib-copy-to-clipboard (&optional text)
  "Copy the given TEXT to clipboard."
  (interactive)
  (unless text
    (setq text (buffer-substring (mark) (point))))
  (shell-command-to-string (concat "pbcopy < <(echo -n " (shell-quote-argument text) ")")))


(defalias 'osx-lib-copy-from-clipboard 'osx-lib-get-from-clipboard)
(defun osx-lib-get-from-clipboard ()
  "Get clipboard text."
  (shell-command-to-string "pbpaste"))

(defun osx-lib-paste-from-clipboard ()
  "Paste the clipboard text."
  (interactive)
  (insert (osx-lib-get-from-clipboard)))

;;function to show file in finder
;;;###autoload
(defun osx-lib-reveal-in-finder-as (file)
  "Reveal the supplied file FILE in Finder.
This function runs the actual AppleScript."
  (let ((script (concat
                 "set thePath to POSIX file \"" (shell-quote-argument file) "\"\n"
                 "tell application \"Finder\"\n"
                 " set frontmost to true\n"
                 " reveal thePath \n"
                 "end tell\n")))
    (osx-lib-run-osascript script)))

;;;###autoload
(defun osx-lib-reveal-in-finder ()
  "Reveal the file associated with the current buffer in the OS X Finder.
In a dired buffer, it will open the current file."
  (interactive)
  (osx-lib-reveal-in-finder-as
   (or (buffer-file-name)
       (expand-file-name (or (dired-file-name-at-point) ".")))))

(defalias 'osx-lib-find-file-in-finder 'osx-lib-reveal-in-finder)

;;vpn connect/disconnect functions
;;;###autoload
(defun osx-lib-vpn-connect (vpn-name password)
  "Connect to vpn using given VPN-NAME and PASSWORD."
  (interactive "MPlease enter vpn-name:\nMPlease enter vpn password:")
  (let ((old-content (osx-lib-copy-from-clipboard)))
    (if (string-lessp (osx-lib-osx-version) osx-lib-ver-yosemite)
    (osx-lib-run-osascript
     (format
      "tell application \"System Events\"
        tell current location of network preferences
                set VPN to service \"%s\" -- your VPN name here
                if exists VPN then connect VPN
                repeat while (current configuration of VPN is not connected)
                    delay 1
                end repeat
        end tell
end tell" (osx-lib-escape vpn-name)))
      (shell-command-to-string (shell-command-to-string (format "scutil --nc start \"%s\"" (shell-quote-argument vpn-name)))))
    (osx-lib-copy-to-clipboard password)
    (osx-lib-notify2 "Please paste" "Password has been copied to clipboard")
    (sit-for 5)
    (osx-lib-copy-to-clipboard old-content)
    (osx-lib-notify2 "Clipboard restored" "")))

;;;###autoload
(defun osx-lib-vpn-disconnect (vpn-name)
  "Disconnect from VPN-NAME vpn."
  (interactive "MEnter the vpn that you want to connect to:")
  (if (string-lessp (osx-lib-osx-version) osx-lib-ver-yosemite)
      (osx-lib-run-osascript
       (format "
tell application \"System Events\"
        tell current location of network preferences
                set VPN to service \"%s\" -- your VPN name here
                if exists VPN then disconnect VPN
                repeat while (current configuration of VPN is connected)
                    delay 1
                end repeat
        end tell
end tell"
           (osx-lib-escape vpn-name)))
    (shell-command-to-string (shell-command-to-string (format "scutil --nc stop \"%s\"" (shell-quote-argument vpn-name)))))
  (osx-lib-notify2 "VPN Disconnected" ""))

;;;###autoload
(defun osx-lib-say (message)
  "Speak the MESSAGE."
  (interactive "MEnter the name message: ")
  (osx-lib-run-osascript
   (format "
tell application \"System Events\"
    say \"%s\"%s%s
end tell
"
       (osx-lib-escape message)
       (if (and osx-lib-say-rate (numberp osx-lib-say-rate))
           (format " speaking rate %d" osx-lib-say-rate)
         "")
       (if (and osx-lib-say-voice (stringp osx-lib-say-voice) (> (length (string-trim osx-lib-say-voice)) 1))
           (format " using \"%s\"" osx-lib-say-voice)
         ""))))

(defalias 'osx-lib-speak 'osx-lib-say)

;;;###autoload
(defun osx-lib-open-url-at-point (url)
  "Open URL at point using default browser."
  (interactive (list (read-from-minibuffer "Please enter the url: " (thing-at-point 'url))))
  (start-process "OsaScript" "*OsaScript*" "open" (eshell-escape-arg url)))

;;use mdfind instead of locate (setq locate-make-command-line #'osx-locate-make-command-line)
(defun osx-lib-locate-make-command-line (search-string)
  (list "mdfind" "-name" (shell-quote-argument search-string)))

;;;###autoload
(defun osx-lib-set-volume (vol)
  "Set sound output volume to VOL(0-100)."
  (interactive "nEnter volume (0-100): ")
  (osx-lib-run-osascript
   (format "set volume output volume %d" vol)))

;;;###autoload
(defun osx-lib-get-volume ()
  "Get sound output volume (0-100)."
  (string-to-number
   (shell-command-to-string
    "osascript -e 'output volume of (get volume settings)'")))

(defun osx-lib-mute-volume ()
  "Mute sound volume."
  (interactive)
  (shell-command-to-string
   "osascript -e 'set volume output muted true'"))

(defun osx-lib-unmute-volume ()
  "Unmute sound volume."
  (interactive)
  (shell-command-to-string
   "osascript -e 'set volume output muted false'"))

;;;###autoload
(cl-defun osx-lib-start-terminal (&optional (dir default-directory) cmd-with-quoted-args)
  "Start terminal in DIR."
  (interactive)
  (let ((cd-cmd (concat "cd "
                        (shell-quote-argument (expand-file-name dir))
                        (when cmd-with-quoted-args
                          (concat ";" cmd-with-quoted-args)))))
    (osx-lib-run-applescript (concat "tell application \"Terminal\" to activate do script \"" cd-cmd "\""))))

(defun osx-lib-say-region (start end)
  "Send current region to osx speaker."
  (interactive "r")
  (let ((selection (buffer-substring-no-properties start end)))
        (osx-lib-say selection)))

;;;###autoload
(defun osx-lib-network-quality ()
  "Test the network's quality using the built-in NQ tool."
  (interactive)
  (with-min-osx-ver osx-lib-ver-monterey
                    (get-buffer-create "*network quality*")
                    (switch-to-buffer "*network quality*")
                    (let (buffer-read-only)
                      (erase-buffer)
                      (message "Running network quality tests...")
                      (center-line)
                      (insert "\n")
                      (insert (shell-command-to-string "networkQuality -s"))
                      (message "Tests completed."))))


(provide 'osx-lib)
;;; osx-lib.el ends here
