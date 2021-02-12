
DESCRIPTION AND USAGE

Show CSS is a minor mode for emacs.

With showcss-mode turned on, as you navigate around an HTML file the
matching css for that element will be displayed in another buffer.

In the current html buffer, if you move the cursor over a class=".*?"
or id=".*?" a buffer will open with the external css file loaded and
scrolled to the matching selector.

Show Css will look at the <link> tags and a custom comment tag to get
the location of external css files.

Show Css looks for a comment with this regex:
<!-- showcss: \\(.*?\\) -->

For example:
<!-- showcss: /home/user/projects/facebook/site/css/main.css -->
or
<!-- showcss: ./sass_files/main.sass-->

The comment is useful if you want to use sass files directly instead
of compiling them.  Also showcss-mode will only use local files.  So
if you use css on a remote server, you will need to use the showcss
tag in you html file and have it point to a local copy of that css.

INSTALLATION

Put this in your init.el or .emacs file:

  (autoload 'showcss-mode "show-css"
     "Display the css of the class or id the cursor is at" t)

Personally, I find this mode to distracting to use all the time, so I
use this function to quickly toggle the mode on and off.

  (defun sm/toggle-showcss()
    "Toggle showcss-mode"
    (interactive)
    (if (derived-mode-p
         'html-mode
         'nxml-mode
         'nxhtml-mode
         'web-mode
         'handlebars-mode)
        (showcss-mode 'toggle)
      (message "Not in an html mode")))
  (global-set-key (kbd "C-c C-k") 'sm/toggle-showcss)

BUGS

Please report any bugs found to the github repository
https://github.com/smmcg/showcss-mode

Also, it you have ideas, suggestions, or advice; please
let me know.  Use the github issues tool or send me
an email.
