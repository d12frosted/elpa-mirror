;;; launchctl.el --- Interface to launchctl on Mac OS X.
;; Author: Peking Duck <github.com/pekingduck>
;; Version: 1.0
;; Package-Commit: c9b7e93f5ec6fa504dfb03d60571cf3e5dc38e12
;; Package-Version: 20210611.2243
;; Package-X-Original-Version: 20150513
;; Package-Requires: ((emacs "24.1"))
;; Keywords: tools, convenience
;; URL: http://github.com/pekingduck/launchctl-el

;; This file is not part of GNU Emacs.

;; Copyright (c) 2015 Peking Duck

;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:

;; launchctl is a major mode in Emacs that eases the loading and unloading of services (user agents and system daemons) managed by launchd on Mac OS X.
;;
;; launchctl interfaces with the command line tool launchctl under the hood.
;;
;; - Type M-x launchctl RET
;;
;; - Press "h" to display help
;;
;;; Code:

(require 'tabulated-list)

(defgroup launchctl nil
  "View and manage launchctl agents/daemons."
  :group 'tools
  :group 'convenience)

(defcustom launchctl-use-header-line t
  "If non-nil, use the header line to display launchctl column titles."
  :type 'boolean
  :group 'launchctl)

(defface launchctl-name-face
  '((t (:weight bold)))
  "Face for service names in the display buffer."
  :group 'launchctl)

(defcustom launchctl-search-path '("~/Library/LaunchAgents/"
				   "/Library/LaunchAgents/"
				   "/Library/LaunchDaemons/"
				   "/System/Library/LaunchAgents/"
				   "/System/Library/LaunchDaemons/")
  "The search path for service configuration files."
  :type 'list
  :group 'launchctl)

(defcustom launchctl-configuration-template "<?xml version=\"1.0\" encoding=\"UTF-8\"?>

<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
  <dict>
    <key>Label</key>
    <string>{label}</string>
    <key>ProgramArguments</key>
    <array>
      <string></string>
    </array>
    <key>StandardOutPath</key>
    <string></string>
    <key>StandardErrorPath</key>
    <string></string>
  </dict>
</plist>"
  "The template for new configuration files."
  :type 'string
  :group 'launchctl)

(defcustom launchctl-name-width 50
  "Width of name column in the display buffer."
  :type 'number
  :group 'launchctl)

(defcustom launchctl-pid-width 7
  "Width of process id column in the display buffer."
  :type 'number
  :group 'launchctl)

(defcustom launchctl-status-width 5
  "Width of status column in the display buffer."
  :type 'number
  :group 'launchctl)

(defcustom launchctl-filter-regex ""
  "Filter regex for launchctl-refresh.  Empty string for no filter."
  :type 'string
  :group 'launchctl)

(defvar launchctl-plist-keys
  '("AbandonProcessGroup"
    "Bonjour"
    "CPU"
    "Core"
    "Data"
    "Day"
    "Debug"
    "Disabled"
    "EnableGlobbing"
    "EnableTransactions"
    "EnvironmentVariables"
    "ExitTimeOut"
    "FileSize"
    "GroupName"
    "HardResourceLimits"
    "HideUntilCheckIn"
    "Hour"
    "InitGroups"
    "KeepAlive"
    "Label"
    "LaunchOnlyOnce"
    "LimitLoadFromHosts"
    "LimitLoadToHosts"
    "LimitLoadToSessionType"
    "LowPriorityIO"
    "MachServices"
    "MemoryLock"
    "Minute"
    "Month"
    "MulticastGroup"
    "NetworkState"
    "Nice"
    "NumberOfFiles"
    "NumberOfProcesses"
    "OnDemand"
    "OtherServiceEnabled"
    "PathState"
    "ProcessType"
    "Program"
    "ProgramArguments"
    "QueueDirectories"
    "ResetAtClose"
    "ResidentSetSize"
    "RootDirectory"
    "RunAtLoad"
    "SecureSocketWithKey"
    "SockFamily"
    "SockNodeName"
    "SockPassive"
    "SockPathMode"
    "SockPathName"
    "SockProtocol"
    "SockServiceName"
    "SockType"
    "Sockets"
    "SoftResourceLimits"
    "Stack"
    "StandardErrorPath"
    "StandardInPath"
    "StandardOutPath"
    "StartCalendarInterval"
    "StartInterval"
    "StartOnMount"
    "SuccessfulExit"
    "ThrottleInterval"
    "TimeOut"
    "Umask"
    "UserName"
    "Wait"
    "WaitForDebugger"
    "WatchPaths"
    "Weekday"
    "WorkingDirectory"
    "inetdCompatibility")
  "A complete list of plist keys used in configuration files.")

(defvar launchctl-key-info
  '(("g" "Refresh" launchctl-refresh)
    ("q" "Quit window" quit-window)
    ("n" "Create new service configuration file" launchctl-new)
    ("e" "Edit configuration file" launchctl-edit)
    ("v" "View configuration file" launchctl-view)
    ("t" "Sort list" tabulated-list-sort)
    ("l" "Load service" launchctl-load)
    ("u" "Unload service" launchctl-unload)
    ("r" "Reload service" launchctl-reload)
    ("s" "Start service" launchctl-start)
    ("o" "Stop service" launchctl-stop)
    ("a" "Restart service" launchctl-restart)
    ("m" "Remove service" launchctl-remove)
    ("d" "Disable service permanently" launchctl-disable)
    ("p" "Enable service permanently" launchctl-enable)
    ("i" "Display service info" launchctl-info)
    ("*" "Filter by regex" launchctl-filter)
    ("$" "Set environment variable" launchctl-setenv)
    ("#" "Unset environment variable" launchctl-unsetenv)
    ("h" "Display this help message" launchctl-help))
  "Key descriptions and bindings.")

(defvar launchctl-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tabulated-list-mode-map)
    (dolist (e launchctl-key-info)
      (define-key map (car e) (car (cdr (cdr e)))))
    map))

(defconst launchctl-help-buffer "*Launchctl Help*"
  "Name of the help buffer.")

(defun launchctl-help ()
  "Display help message in a new buffer."
  (interactive)
  (with-current-buffer (get-buffer-create launchctl-help-buffer)
    (view-mode 0)
    (erase-buffer)
    (pop-to-buffer launchctl-help-buffer)
    (insert "Key Function\n--- --------\n")
    (insert (mapconcat
	     (lambda (p) (format "%s   %s" (car p) (cadr p)))
	     launchctl-key-info
	     "\n"))
    (insert "\n\nOnline documentation: https://github.com/pekingduck/launchctl-el")
    (view-mode)
    (message "Press q to quit.")))


(define-derived-mode launchctl-mode tabulated-list-mode "launchctl"
  "Major mode for managing Launchd services on Mac OS X."
  (setq default-directory (car launchctl-search-path))
  (add-hook 'tabulated-list-revert-hook 'launchctl-refresh nil t))

;;;###autoload
(defun launchctl()
  "Launchctl - major mode for managing Launchd services on Mac OS X.  This is the entry point."
  (interactive)
  (let ((buffer (get-buffer-create "*Launchctl*")))
    (with-current-buffer buffer
      (launchctl-mode)
      (launchctl-refresh))
    (switch-to-buffer buffer))
  (message "Press h for help"))

(defun launchctl--noselect ()
  "Helper function to launch launchctl."
)

(defun launchctl-setenv ()
  "Set an environment variable (for all services).  Equivalent to \"launchctl setenv <KEY> <VALUE>."
  (interactive)
  (launchctl--command
   (format "setenv %s"
	   (read-string "Variable to set (format \"NAME VALUE\"): "))))

(defun launchctl-unsetenv ()
  "Set an environment variable for all processes.  Equivalent to \"launchctl unsetenv <KEY>\"."
  (interactive)
  (launchctl--command
   (format "unsetenv %s"
	   (read-string "Variable to unset: "))))

(defun launchctl-refresh ()
  "Display/Refresh the process list."
  (interactive)
  (let ((name-width launchctl-name-width)
	(pid-width launchctl-pid-width)
	(status-width launchctl-status-width))
    (setq tabulated-list-format
	  (vector `("Name" ,name-width t)
		  `("PID" ,pid-width t)
		  `("Status" ,status-width nil))))
  (setq tabulated-list-use-header-line launchctl-use-header-line)
  (let ((entries '()))
    (with-temp-buffer
      (shell-command "launchctl list" t)
      ;; kill the header line without saving it to the kill-ring
      (save-excursion
	    (goto-char (point-min))
	    (forward-line 1)
	    (set-mark (point-min))
	    (delete-region (region-beginning) (region-end)))
      (dolist (l (split-string (buffer-string) "\n" t))
	(let ((fields (split-string l "\t" t)))
	  (if (or (eq launchctl-filter-regex nil)
		  (string= launchctl-filter-regex "")
		  (string-match launchctl-filter-regex (nth 2 fields)))
	      (push (list (nth 2 fields) (vector (launchctl--prettify
						  (nth 2 fields))
						 (nth 0 fields)
						 (nth 1 fields))) entries)))))
    (setq tabulated-list-entries entries))
  (tabulated-list-init-header)
  (tabulated-list-print t))

(defun launchctl-filter ()
  "Filter display by regular expressions."
  (interactive)
  (setq launchctl-filter-regex (read-regexp "Filter regex (. to clear filter): "
					    launchctl-filter-regex))
  (launchctl-refresh))

(defun launchctl--ask-file-name ()
  "Prompt user for a configuration file."
  (read-file-name "Configuration file: " (car launchctl-search-path)))

(defun launchctl--guess-file-name ()
  "Check if the corresponding configuration file exists in the search path.  If not, user will be prompted for the location."
  (let ((file-name nil)
	(id (tabulated-list-get-id))
	(search-path launchctl-search-path))
    (while (and (eq file-name nil)
		(not (eq search-path nil)))
      (let ((tmp-file-name (expand-file-name (format "%s.plist" id)
					     (car search-path))))
	(if (file-readable-p tmp-file-name)
	    (setq file-name tmp-file-name)
	  (setq search-path (cdr search-path)))))
    (if (eq file-name nil)
	(launchctl--ask-file-name) ;; file not in the search path, prompt user!
      file-name)))

(defun launchctl--command (cmd &rest e)
  "Make the actual call to launchctl.  CMD is the subcommand while E is the argument list of variable length."
  (shell-command (format "launchctl %s %s" cmd (mapconcat 'identity e " "))))

(defun launchctl-remove ()
  "Remove a service."
  (interactive)
  (launchctl--command "remove" (tabulated-list-get-id))
  (launchctl-refresh))

(defun launchctl-unload (&optional file-name)
  "Unload the service.  FILE-NAME is the service configuration file.  Equivalent to \"launchctl unload <service>\"."
  (interactive)
  (let ((file-name (or file-name (launchctl--guess-file-name))))
    (launchctl--command "unload" file-name)
    (launchctl-refresh)))

(defun launchctl-load ()
  "Load service.  FILE-NAME is the service configuration file to load.  Equivalent to \"launchctl load <service>\"."
  (interactive)
  (launchctl--command "load" (launchctl--ask-file-name))
  (launchctl-refresh))

(defun launchctl-reload (&optional file-name)
  "Restart service.  FILE-NAME is the service configuration file to reload.  The same as load and then reload."
    (interactive)
  (let ((file-name (or file-name (launchctl--guess-file-name))))
    (launchctl--command "unload" file-name)
    (launchctl--command "load" file-name)
    (launchctl-refresh)))

(defun launchctl-enable ()
  "Enable service permanently.  Equivalent to \"launchctl load -w <service>\"."
  (interactive)
  (launchctl--command "load -w" (launchctl--ask-file-name))
  (launchctl-refresh))

(defun launchctl-disable (&optional file-name)
  "Disable service permanently.  FILE-NAME is the service configuration file.  Equivalent to \"launchctl unload -w <service>\"."
  (interactive)
  (let ((file-name (or file-name (launchctl--guess-file-name))))
    (launchctl--command "unload -w" file-name)
    (launchctl-refresh)))

(defun launchctl-edit ()
  "Edit service plist configuration file."
  (interactive)
  (find-file-other-window (launchctl--guess-file-name)))

(defun launchctl-view ()
  "View configuration file."
  (interactive)
  (find-file-other-window (launchctl--guess-file-name))
  (view-mode)
  (message "Press q to quit"))

(defun launchctl-new ()
  "Create a new service configuration file."
  (interactive)
  (let ((file-name (launchctl--ask-file-name)))
    (let ((buf (get-file-buffer file-name))
	  (base-name (file-name-base file-name)))
      (if (eq buf nil)
	  (setq buf (get-buffer-create base-name)))
      (with-current-buffer buf
	(set-visited-file-name file-name)
	(if (equal (buffer-size) 0)
	    (progn
	      (insert launchctl-configuration-template)
	      (goto-char (point-min))
	      (while (search-forward "{label}" nil t)
		(replace-match base-name nil t))
	      (set-auto-mode))))
      (switch-to-buffer-other-window buf))))

(defun launchctl-stop ()
  "Stop service.  Equivalent to \"launchctl stop <service>\"."
  (interactive)
  (launchctl--command "stop" (tabulated-list-get-id))
  (launchctl-refresh))

(defun launchctl-start ()
  "Start service.  Equvalent to \"launchctl start <service>\"."
  (interactive)
  (launchctl--command "start" (tabulated-list-get-id))
  (launchctl-refresh))

(defun launchctl-info ()
  "Show service.  Equivalent to \"launchctl list <service>\"."
  (interactive)
  (launchctl--command "list" (tabulated-list-get-id)))

(defun launchctl-plist-key-complete ()
  "Provide completion for plist keys."
  (interactive)
  (insert  (completing-read "Keys: " launchctl-plist-keys)))

(defun launchctl--prettify (name)
  "Fontify the NAME column."
  (propertize name
              'font-lock-face 'launchctl-name-face
              'mouse-face 'highlight))

(provide 'launchctl)

;;; launchctl.el ends here
