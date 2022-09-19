This package provides an intuitive GUI for pueue task manager.

;; Installation

;;; Package manager

If you've installed it with your package manager, then you are probably done.
`pueue' command is autoloaded, so you can call it right away.

;;; Manual

It depends on the following packages:

+ with-editor

Then put this file in your load-path, and put this in your init
file:

(require 'pueue)

;; Usage

Run `pueue' command.  You can press ? key or call `describe-mode' to discover
available keybindings.  Dired-like marking also works.

;; Tips

+ You can customize settings in the `pueue' group.

+ Required version of pueue is 2.0.0.  Although the visualization of tasks
  and detailed view will work with 1.0.0, some commands (like group) have
  changed their API in 2.0.0.

;; Credits

This package would not have been possible without the excellent pueue[1] task
manager.

 [1] https://github.com/Nukesor/pueue
