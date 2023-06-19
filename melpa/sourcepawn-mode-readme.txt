SourcePawn is a scripting language for SourceMod, which can be
found at <http://www.sourcemod.net/>,

More (and nicer) documentation for sourcepawn-mode may be found at
<http://gamma-level.com/teamfortress2/sourcepawn-mode>.

Suggestions, improvements, and bug reports are welcome.  Please
contact me at the email address above!

; Installation:

NOTE: the file `sourcepawn-mode.el.in` is used to GENERATE the file
`sourcepawn-mode.el`, which is what you should install. DO NOT USE
the .in version: it will not work. Instead, see the README for how
to generate the real file, or get a pregenerated file from my
website, linked above.

Installation instructions:

1. Put this file somewhere in your emacs load path OR add the
   following to your .emacs file (modifying the path
   appropriately):

   (add-to-list 'load-path "/home/agrif/emacsinclude")

2. Add the following to your .emacs file to load this file
   automatically when needed, and to make this autoload *.sp files:

   (autoload 'sourcepawn-mode "sourcepawn-mode" nil t)
   (add-to-list 'auto-mode-alist '(".sp\\'" . sourcepawn-mode))

3. (Optional) Customize SourcePawn mode with your own hooks.  Below
   is a sample which automatically untabifies when you save:

   (defun my-sourcepawn-mode-hook ()
     (add-hook 'local-write-file-hooks 'auto-untabify-on-save))

   (add-hook 'sourcepawn-mode-hook 'my-sourcepawn-mode-hook)
