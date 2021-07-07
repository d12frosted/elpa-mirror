This minor mode exists to mimick TextMate's awesome
features.

   ⌘T - Go to File
 ⇧⌘T - Go to Symbol
   ⌘L - Go to Line
 ⇧⌘L - Select Line (or expand Selection to select lines)
   ⌘/ - Comment Line (or Selection/Region)
   ⌘] - Shift Right
   ⌘[ - Shift Left
 ⌥⌘] - Align Assignments
 ⌥⌘[ - Indent Line
   ⌥↑ - Column Up
   ⌥↓ - Column Down
 ⌘RET - Insert Newline at Line's End
 ⌥⌘T - Reset File Cache (for Go to File)

A "project" in textmate-mode is determined by the presence of
a .git directory, an .hg directory, a Rakefile, or a Makefile.

You can configure what makes a project root by appending a file
or directory name onto the `*textmate-project-roots*' list.

If no project root indicator is found in your current directory,
textmate-mode will traverse upwards until one (or none) is found.
The directory housing the project root indicator (e.g. a .git or .hg
directory) is presumed to be the project's root.

In other words, calling Go to File from
~/Projects/fieldrunners/app/views/towers/show.html.erb will use
~/Projects/fieldrunners/ as the root if ~/Projects/fieldrunners/.git
exists.

; Installation

$ cd ~/.emacs.d/vendor
$ git clone git://github.com/defunkt/textmate.el.git

In your emacs config:

(add-to-list 'load-path "~/.emacs.d/vendor/textmate.el")
(require 'textmate)
(textmate-mode)

; Depends on imenu
