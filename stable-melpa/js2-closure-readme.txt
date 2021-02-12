
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

; Installation:

Install this package from MELPA using `M-x install-package` and type
`js2-closure`.  If you aren't already using MELPA, see:
http://melpa.milkbox.net/#/getting-started

You then need to run a helper script that crawls all your JavaScript sources
for `goog.provide` statements, in addition to your Closure Templates (Soy)
for `{namespace}` declarations (assuming you're using the Soy to JS
compiler).  You must also download the source code to the Closure Library
and pass this script the path of the `closure/goog` folder.

Here's an example command for regenerating the provides index that you can
add to your `~/.bashrc` file:

    jsi() {
      local github="https://raw.githubusercontent.com"
      local script="js2-closure-provides.sh"
      bash <(wget -qO- ${github}/jart/js2-closure/master/${script}) \
        ~/code/closure-library/closure/goog \
        ~/code/my-project/js \
        ~/code/my-project/soy \
        >~/.emacs.d/js2-closure-provides.el
    }

That will generate an index file in your `~/.emacs.d` directory.  If you
want to store it in a different place, then `js2-closure-provides-file' will
need to be customised.

This index file will be loaded into Emacs automatically when the timestamp
on the file changes.  You need to re-run the script manually whenever new
`goog.provide` statements are added or removed.  Automating that part is up
to you.
