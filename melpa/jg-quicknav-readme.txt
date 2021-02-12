A quick file-finder for emacs. Navigate up and down directories to find a file.

Like ido-find-file, lusty-explorer, helm/anything, etc. But none of them
did quite what I wanted so I created this. The goal is to navigate the file
system as fast as possible. Like a much faster way of doing the...

 1. cd <foo>
 2. ls
 3. goto 1
 4. <open file>

 ...loop in the shell.

Usage: - assign `jg-quicknav' to a key, and use it.
       - buffer will show you the directory listing for the current default directory
         (reminder: if you're in a file buffer, that will be the directory
         that file is in. If you're in shell-mode, eshell, ansi-term, dired, etc,
         that will be the correct current directory).
       - type some letters to filter down the results. C-n and C-p to change selection
       - RET on a file to open the file, or RET on a directory to `jg-quicknav' that dir.
       - C-, to go "up a directory", after which you can go "forward" with C-.
       - Drop into dired with C-/
       - I tried to make it easy to rebind the bindings. I rebind everything all the time
         so I was sure others would not like my key choices. see below.



You'll likely want to change some of the key bindings. Just redefine the keys
on jg-quicknav-mode-map. For example, if you use C-n for something else and want
to move up and down lines while navigating with M-n instead, use this:

(define-key jg-quicknav-mode-map (kbd "C-n") nil)
(define-key jg-quicknav-mode-map (kbd "M-n") 'jg-quicknav-next)


TODO/IDEAS:
- better support for dirs with many files in them
  - ensure-cursor-visible or something in case selection is off the screen
  - also page-down and page-up support for long lists
  - maybe add an option to toggle showing only files/only dirs?
- shell-mode plugin to "cd" to a directory chosen via jgqn?
- secondary-highlight for previous dir after going 'updir'
- different face/color for executables? or just the "*"?
  - and different face for file extensions? (just like dired+)
- add a jg-quick-buffer-switcher too?
