el-patch allows you to override Emacs Lisp functions in a
future-proof way. Specifically, you can override a function by
providing an s-expression-based "patch", from which the "original"
and "modified" definitions can both be computed -- just like a Git
patch.

The "modified" definition is what is actually evaluated in your
init-file, but at any time you can ask el-patch to look up the
actual definition of the function and compare it to the patch's
"original" definition. If there is a difference -- meaning that the
original function definition was updated since you created the
patch -- el-patch will show you with Ediff. This means you know
when you might need to update your customizations (this is the
future-proof part).

el-patch also provides a powerful mechanism to help you lazy-load
packages. If you want to use a function from a package without
triggering its autoload (for instance, activating a minor mode or
defining keybindings), you can just copy its definition to your
init-file and declare it as a patch. Then you can freely use the
function, but you will still be notified of updates to the original
definition by el-patch so you will know when to update your copy of
the definition.

Please see https://github.com/radian-software/el-patch for more
information.
