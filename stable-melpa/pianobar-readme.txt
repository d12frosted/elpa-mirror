Pianobar is a command-line client for Pandora <http://pandora.com>,
written by Lars-Dominik Braun (and others), which can be found at
<http://6xq.net/html/00/17.html>.

There is a README that should have come with this file that
contains more detailed information than what's here. If you can't
find it, you can find it on GitHub at <http://github.com/agrif/pianobar.el>.

Suggestions, improvements, and bug reports are welcome. This is a
*very* early version, so expect there to be many!

; Installation:

Installation instructions:

1. Put this file in your emacs load path OR add the following to
   your .emacs file (modifying the path appropriately):

   (add-to-list 'load-path "/home/agrif/emacsinclude")

2. Add the following to your .emacs file to load this file
   automatically when M-x pianobar is run:

   (autoload 'pianobar "pianobar" nil t)

3. (Optional) Customize pianobar! See the README for information on
    what variables are available to set.
