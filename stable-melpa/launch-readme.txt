Launch files and directories using the associated applications provided by
your operating system.

If you're like me, you love using Emacs for all of your text
management needs.  But sometimes, there are documents that you'd like
to open with other programs.

For instance, you might want to launch your file manager to look at
pretty thumbnails in the current directory.  Or you're editing HTML and
want to launch your document in the system's web browser.

Launch makes it easy to do this by using your OS's built-in
file-associations to launch the appropriate program for a particular
file.

; Installation:

Launch is available from MELPA <http://melpa.milkbox.net/>.
Just run \\[package-install] and install `launch'.

Then, in your ~/.emacs configuration, add:
    (global-launch-mode +1)

If you only want to enable it for certain modes, add:
    (add-hook 'html-mode 'turn-on-launch-mode)
