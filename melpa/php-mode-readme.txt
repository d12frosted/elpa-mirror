PHP Mode is a major mode for editing PHP script.  It's an extension
of CC mode; thus it inherits all C mode's navigation functionality.
But it colors according to the PHP syntax and indents according to the
PSR-2 coding guidelines.  It also includes a couple handy IDE-type
features such as documentation search and a source and class browser.

Please read the manual for setting items compatible with CC Mode.
https://www.gnu.org/software/emacs/manual/html_mono/ccmode.html

This mode is designed for PHP scripts consisting of a single <?php block.
We recommend the introduction of Web Mode for HTML and Blade templates combined with PHP.
http://web-mode.org/

Modern PHP Mode can be set on a project basis by .dir-locals.el.
Please read php-project.el for details of directory local variables.

If you are using a package manager, you do not need (require 'php-mode) in
your ~/.emacs.d/init.el.  Read the README for installation instructions.
https://github.com/emacs-php/php-mode
