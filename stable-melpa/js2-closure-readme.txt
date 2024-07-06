
Do you use Emacs, `js2-mode', and Google's Closure Library?  Do you get
frustrated writing your `goog.require` statements by hand?  If that's the
case, then this extension is going to make you very happy.

js2-closure is able to analyse the JavaScript code in your buffer to
determine which imports you need, and then update the `goog.require` list at
the top of your buffer.  It works like magic.  It also runs instantaneously,
even if you have a big project.

This tool only works on files using traditional namespacing,
i.e. `goog.provide` and `goog.require`.  However js2-closure is smart enough
to turn itself off in files that use `goog.module` or ES6 imports.
