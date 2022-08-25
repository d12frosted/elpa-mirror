;;; alert-toast.el --- Windows 10 toast notifications -*- lexical-binding: t; -*-

;; Copyright 2020, 2022 Grzegorz Kowzan

;; Author: Grzegorz Kowzan <grzegorz@kowzan.eu>
;; Created: 25 Oct 2020
;; Updated: 25 Mar 2022
;; Version: 1.0.0
;; Package-Version: 20220312.229
;; Package-Commit: 96c88c93c1084de681700f655223142ee0eb944a
;; Package-Requires: ((emacs "25.1") (alert "1.2") (f "0.20.0") (s "1.12.0"))
;; Url: https://github.com/gkowzan/alert-toast

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; This package defines a new alert style (`toast') for alert.el using Windows
;; 10 toast notifications. It works with native Windows 10 Emacs versions and
;; with Emacs run under Windows Subsystem for Linux (WSL) or under Cygwin. These
;; notifications are limited to a single-line title and four lines of text.
;; Longer text can be passed but it will be truncated by Windows 10.
;;
;; * Icons
;; Icons located on network shares are not supported. This includes icons on the
;; WSL virtual drive, therefore for Emacs running under WSL the default Emacs
;; icon is copied to C:\Users\<user>\AppData\Local\Emacs-Toast\Emacs.png. PNG
;; version is used because toast notifications render SVG graphics as tiny and
;; put them in top left corner of the notification.

;; Under WSL or Cygwin, a path to a custom icon should be given as a WSL/Cygwin
;; path (/mnt/c/... or /cygdrive/c/...) instead of a Windows path (C:\\...).
;;
;; * Priorities
;; Looking at Windows.UI.Notifications API, toast notifications seem to support
;; 2 priority levels: High and Default. Mapping between alert.el priorities and
;; these levels is defined by `alert-toast-priorities'.
;;
;; * Bugs
;; There is an issue in WSL where wslhost.exe dies for no discernible reason,
;; which prevents accessing Windows partitions and executables
;; (https://github.com/microsoft/WSL/issues/6161). If this happens then you
;; should see powershell.exe process failing to start. This will obviously
;; prevent this package from working. The only known workaround is to call `wsl
;; --shutdown' and start WSL again.
;;; Code:

(require 'f)
(require 's)
(require 'alert)
(require 'dom)
(require 'shr)

;; WSL-related functions and constants
;; In the words of WSL developers, there is no official way of testing for WSL
;; but they said at the same time that either "wsl" or "microsoft" should always
;; be present in the kernel release string.
(defun alert-toast--check-wsl ()
  "Check if running under Windows Subsystem for Linux."
  (and (eq system-type 'gnu/linux)
       (let ((kernel-release (shell-command-to-string "uname --kernel-release")))
         (or (s-contains? "wsl" kernel-release t)
             (s-contains? "microsoft" kernel-release t)))))

(defconst alert-toast--wsl (alert-toast--check-wsl))
(defconst alert-toast--appdir-text "[System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData) | Join-Path -ChildPath Emacs-Toast\\Emacs.png")

(defun alert-toast--appdir ()
  "Path to Windows user's data directory."
  (with-temp-buffer
    (let ((coding-system-for-read 'utf-8-dos))
      (call-process-region alert-toast--appdir-text nil "powershell.exe" nil t nil "-noprofile" "-NonInteractive" "-WindowStyle" "Hidden" "-Command" "-"))
    (s-chomp (buffer-string))))

(defun alert-toast--default-wsl-icon-path ()
  "Path to Emacs icon in Windows user's data directory."
  (with-temp-buffer
    (call-process "wslpath" nil t nil (alert-toast--appdir))
    (s-chomp (buffer-string))))

(defun alert-toast--init-wsl-icon ()
  "Copy Emacs icon to a Windows-side directory."
  (let ((icon-path (alert-toast--default-wsl-icon-path)))
    (unless (f-exists? icon-path)
      (make-directory (f-parent icon-path) t)
      (f-copy (concat data-directory "images/icons/hicolor/128x128/apps/emacs.png")
              icon-path))))

(defun alert-toast--icon-path (path)
  "Convert icon PATH from WSL/Cygwin to Windows path if needed."
  (cond
   (alert-toast--wsl
    (with-temp-buffer
      (call-process "wslpath" nil t nil "-m" path)
      (s-chomp (buffer-string))))
   ((eq system-type 'cygwin)
    (with-temp-buffer
      (call-process "cygpath.exe" nil t nil "-w" path)
      (s-chomp (buffer-string))))
   (t path)))

;; Default icon
(defvar alert-toast-default-icon
  (if alert-toast--wsl
      (alert-toast--default-wsl-icon-path)
    (concat data-directory "images/icons/hicolor/128x128/apps/emacs.png"))
  "Path to default icon for toast notifications.")

;; Common part -- script body, powershell quoting, priorities and main function
(defconst alert-toast--psquote-replacements
  '(("'" . "''")))

(defcustom alert-toast-priorities
  '((urgent . "[Windows.UI.Notifications.ToastNotificationPriority]::High")
    (high . "[Windows.UI.Notifications.ToastNotificationPriority]::High")
    (moderate . "[Windows.UI.Notifications.ToastNotificationPriority]::Default")
    (normal . "[Windows.UI.Notifications.ToastNotificationPriority]::Default")
    (low . "[Windows.UI.Notifications.ToastNotificationPriority]::Default")
    (trivial . "[Windows.UI.Notifications.ToastNotificationPriority]::Default"))
  "A mapping of alert severities onto Windows 10 toast priority values."
  :type '(alist :key-type symbol :value-type string)
  :group 'alert)

(defconst alert-toast--sounds
  '((default . "ms-winsoundevent:Notification.Default")
    (im . "ms-winsoundevent:Notification.IM")
    (mail . "ms-winsoundevent:Notification.Mail")
    (reminder . "ms-winsoundevent:Notification.Reminder")
    (sms . "ms-winsoundevent:Notification.SMS"))
  "Alist of available sounds.")

(defconst alert-toast--looping-sounds
  (let ((looping-sounds '((call . "ms-winsoundevent:Notification.Looping.Call")
                        (alarm . "ms-winsoundevent:Notification.Looping.Alarm"))))
  (dolist (i '(2 3 4 5 6 7 8 9 10) looping-sounds)
    (setq looping-sounds
          (cons `(,(intern (format "call%d" i)) . ,(format "ms-winsoundevent:Notification.Looping.Call%d" i))
                looping-sounds))
    (setq looping-sounds
          (cons `(,(intern (format "alarm%d" i)) . ,(format "ms-winsoundevent:Notification.Looping.Alarm%d" i))
                looping-sounds))))
  "Alist of available looping sounds.")

(defvar alert-toast--psprocess nil
  "Persistent powershell process emitting toast notifications.")

(defun alert-toast--coding-page ()
  "Get powershell encoding."
  (with-temp-buffer
    (let ((coding-system-for-read 'utf-8-dos))
      (call-process-region "[console]::InputEncoding.BodyName" nil "powershell.exe" nil t nil "-noprofile" "-NonInteractive" "-WindowStyle" "Hidden" "-Command" "-"))
    (intern-soft (s-chomp (buffer-string)))))

(defun alert-toast--psprocess-init ()
  "Initialize powershell process."
  (setq alert-toast--psprocess
        (make-process :name "powershell-toast"
                      :buffer "*powershell-toast*"
                      :command '("powershell.exe" "-noprofile" "-NoExit" "-NonInteractive" "-WindowStyle" "Hidden"
                                 "-Command" "-")
                      :coding (if alert-toast--wsl 'utf-8 (alert-toast--coding-page))
                      :noquery t
                      :connection-type 'pipe))
  (process-send-string alert-toast--psprocess "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml, ContentType=WindowsRuntime] > $null\n"))

(defun alert-toast--psprocess-kill ()
  "Kill powershell process (for debugging)."
  (delete-process alert-toast--psprocess)
  (setq alert-toast--psprocess nil))

(defun alert-toast--fill-template (title message icon-path &optional audio silent long loop)
  "Create alert toast XML document.

Set title to TITLE, message body to MESSAGE and icon to the image at ICON-PATH.
ICON-PATH has to be a native Windows path, use `alert-toast--icon-path' for
Cygwin->native and WSL->native conversion.

AUDIO can be one of symbols defined in `alert-toast--sounds' or
`alert-toast--looping-sounds'. If SILENT is non-nil, the notification is muted.
If LONG is non-nil or one of the sounds in `alert-toast--looping-sounds' was
provided as AUDIO, then the notification will last for ~20 s; otherwise it lasts
for several seconds. Non-nil LOOP will loop the sound."
  (let ((looping-sound (alist-get audio alert-toast--looping-sounds))
        (dom
         (dom-node
          'toast nil
          (dom-node
           'visual nil
           (dom-node
            'binding
            '((template . "ToastImageAndText02"))
            (dom-node 'text '((id . "1")) title)
            (dom-node 'text '((id . "2")) message)
            (dom-node 'image `((id . "1")
                               (src . ,icon-path)
                               (placement . "appLogoOverride"))))))))
    (when (or audio silent loop)
      (dom-append-child
       dom (dom-node 'audio `((src . ,(or looping-sound
                                          (alist-get audio alert-toast--sounds)
                                          (alist-get 'default alert-toast--sounds)))
                              (silent . ,(if silent "true" "false"))
                              (loop . ,(if (or loop looping-sound) "true" "false"))))))
    (when (or long looping-sound)
      (dom-set-attribute dom 'duration "long"))
    (shr-dom-to-xml dom)))

(defun alert-toast--fill-shoulder (title message icon-path person payload)
  "Create shoulder tap XML document.

PERSON is an email address given as 'mailto:login@domain.com' of a contact
previously added to My People. PAYLOAD is either remote http or local path to a
GIF or PNG image. Under WSL and Cygwin, local paths need to be converted to
native Windows paths with `alert-toast--icon-path'.

As a fallback, set title to TITLE, message body to MESSAGE and icon to the image
at ICON-PATH. ICON-PATH has to be a native Windows path, use
`alert-toast--icon-path' for Cygwin->native and WSL->native conversion."
  (let ((dom
         (dom-node 'toast
                   `((hint-people . ,person))
                   (dom-node 'visual nil
                             (dom-node 'binding '((template . "ToastGeneric"))
                                       (dom-node 'text nil title)
                                       (dom-node 'text nil message)
                                       (dom-node 'image `((src . ,icon-path)
                                                          (placement . "appLogoOverride")
                                                          (hint-crop . "circle"))))
                             (dom-node 'binding '((template . "ToastGeneric")
                                                  (experienceType . "shoulderTap"))
                                       (dom-node 'image `((src . ,payload))))))))
    (shr-dom-to-xml dom)))

(defconst alert-toast--psscript-text "$Xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $Xml.LoadXml('%s')

    $Toast = [Windows.UI.Notifications.ToastNotification]::new($Xml)
    $Toast.Tag = \"Emacs\"
    $Toast.Group = \"Emacs\"
    $Toast.Priority = %s
    $Toast.ExpirationTime = [DateTimeOffset]::Now.AddSeconds(%f)

    $Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier(\"Emacs\")
    $Notifier.Show($Toast);\n"
  "Template of Powershell script emitting regular toast notification.")

(defconst alert-toast--psscript-shoulder "$Xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $Xml.LoadXml('%s')

    $Toast = [Windows.UI.Notifications.ToastNotification]::new($Xml)

    $Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Microsoft.People_8wekyb3d8bbwe!x4c7a3b7dy2188y46d4ya362y19ac5a5805e5x')
    $Notifier.Show($Toast);\n"
  "Template of Powershell script emitting shoulder tap.")

;;;###autoload
(defun alert-toast-notify (info)
  "Send INFO using Windows 10 toast notification.
Handles :ICON, :SEVERITY, :PERSISTENT, :NEVER-PERSIST, :TITLE and
:MESSAGE keywords from INFO plist."
  (let ((data-plist (plist-get info :data))
        psscript)
    (if (and (plist-get data-plist :shoulder-person) (plist-get data-plist :shoulder-payload))
        (setq psscript (format alert-toast--psscript-shoulder
                               (s-replace-all alert-toast--psquote-replacements
                                              (alert-toast--fill-shoulder
                                               (plist-get info :title)
                                               (plist-get info :message)
                                               (alert-toast--icon-path
                                                (or (plist-get info :icon)
                                                    alert-toast-default-icon))
                                               (plist-get data-plist :shoulder-person)
                                               (plist-get data-plist :shoulder-payload)))))
      (setq psscript
        (format alert-toast--psscript-text
                (s-replace-all alert-toast--psquote-replacements
                               (alert-toast--fill-template
                                (plist-get info :title)
                                (plist-get info :message)
                                (alert-toast--icon-path (or (plist-get info :icon)      alert-toast-default-icon))
                                (plist-get data-plist :audio)
                                (plist-get data-plist :silent)
                                (plist-get data-plist :long)
                                (plist-get data-plist :loop)))
                   (or (cdr (assq (plist-get info :severity) alert-toast-priorities))
                       (cdr (assq 'normal alert-toast-priorities)))
                   (if (and (plist-get info :persistent)
                            (not (plist-get info :never-persist)))
                       (* 60 60 24 7)  ; a week
                     alert-fade-time))))
    (unless alert-toast--psprocess
      (alert-toast--psprocess-init))
    (process-send-string alert-toast--psprocess psscript)))

(alert-define-style 'toast :title "Windows 10 toast notification"
                    :notifier #'alert-toast-notify)

(when alert-toast--wsl
  (alert-toast--init-wsl-icon))

(provide 'alert-toast)
;;; alert-toast.el ends here
