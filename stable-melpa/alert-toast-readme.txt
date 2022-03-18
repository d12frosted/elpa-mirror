This package defines a new alert style (`toast') for alert.el using Windows
10 toast notifications. It works with native Windows 10 Emacs versions and
with Emacs run under Windows Subsystem for Linux (WSL) or under Cygwin. These
notifications are limited to a single-line title and four lines of text.
Longer text can be passed but it will be truncated by Windows 10.

* Icons
Icons located on network shares are not supported. This includes icons on the
WSL virtual drive, therefore for Emacs running under WSL the default Emacs
icon is copied to C:\Users\<user>\AppData\Local\Emacs-Toast\Emacs.png. PNG
version is used because toast notifications render SVG graphics as tiny and
put them in top left corner of the notification.

Under WSL or Cygwin, a path to a custom icon should be given as a WSL/Cygwin
path (/mnt/c/... or /cygdrive/c/...) instead of a Windows path (C:\\...).

* Priorities
Looking at Windows.UI.Notifications API, toast notifications seem to support
2 priority levels: High and Default. Mapping between alert.el priorities and
these levels is defined by `alert-toast-priorities'.

* Bugs
There is an issue in WSL where wslhost.exe dies for no discernible reason,
which prevents accessing Windows partitions and executables
(https://github.com/microsoft/WSL/issues/6161). If this happens then you
should see powershell.exe process failing to start. This will obviously
prevent this package from working. The only known workaround is to call `wsl
--shutdown' and start WSL again.
