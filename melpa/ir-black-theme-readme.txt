This is an Emacs 24 port of Todd Werth's IR Black theme available at URL
`http://blog.toddwerth.com/entries/8'. It still needs font-locking for
operators, numbers, and regular expressions, and it could definitely use
some cleaning up. Improvements are welcome!

To use this theme, download it to ~/.emacs.d/themes. In your `.emacs' or
`init.el', add this line:

   (add-to-list 'custom-theme-load-path "~/.emacs.d/themes")

Once you have reloaded your configuration (`eval-buffer'), do `M-x
load-theme' and select "ir-black".
