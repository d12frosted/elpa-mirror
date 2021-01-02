
This major mode for GNU Emacs provides support for editing Povray
scene files, rendering and viewing them.  It automatically indents
blocks, both {} and #if #end.  It also provides context-sensitive
keyword completion and font-lock highlighting, as well as the
ability to look up those keywords in the povray docu.


INSTALLATION

Add the following code to your emacs init file.

(add-to-list 'load-path "~/john/pov-mode-3.x")
(autoload 'pov-mode "pov-mode" "PoVray scene file mode" t)
(add-to-list 'auto-mode-alist '("\\.pov\\'" . pov-mode))
(add-to-list 'auto-mode-alist '("\\.inc\\'" . pov-mode))

The "~/john/pov-mode-3.x" should be the path to the file pov-mode.el .

Once installed, you may need to set pov-include-dir and
pov-documentation-directory. You can set these by using M-x
set-variable or M-x customize-group RET pov RET.

Byte compile the pov-mode.el to make it load faster.
Type M-x byte-compile-file.

To read pov-mode documentation, type M-x pov-mode then C-h m.
To access the pov-mode info file type C-u C-h i RET. This will
prompt you for  a file: give the pov-mode.info file that you can
find in the pov-mode.el directory. Or install somewhere in your
INFOPATH and run install-info pov-mode.info dir.

Download and install somewhere the InsertMenu directory, if you
want this nice feature. I'd recommend you to unpack it in the same
directory of pov-mode.el and check via M-x customize-group that the
variable pov-insertmenu-location has the correct value. It is
possible that <http://www.imagico.de/> has a fresher version of
this package.
