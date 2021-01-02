nclip.el is network clipboard for Emacs which makes possible to use
your local clipboard even when you are running Emacs inside
terminal on remote server.

When enabled, it will use remote HTTP server to fetch and update
clipboard content. Included HTTP server `nclip.rb` supports OSX
(pbcopy/pbpaste) but it should be pretty straightforward to support
other systems as well (e.g. Linux using xclip).

; Installation:

Available as a package in http://melpa.milkbox.net
