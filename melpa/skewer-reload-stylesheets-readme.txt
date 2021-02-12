This minor mode provides live-editing of CSS and transpile-to-CSS languages
via skewer.

skewer-css works for many cases, but if you're dealing with multiple
stylesheets and involved cascading (a.k.a. "legacy code"), it isn't so
useful. What you see while live-editing is not what you see when you
refresh, since skewer-css puts the updated CSS in new style tags, thus
changing their specificity.

skewer-css also doesn't work with Less, SCSS, or any of the lesser-known
compile-to-CSS languages - just vanilla CSS (though there is the skewer-less
package, if you run Less's in-browser JS version for development).

Enter this minor mode.

It refreshes stylesheets after saves by adding or updating a query string to
the relevant link tags in the browser.

Thus, what you see on a fresh pageload is always exactly what you see while
live-editing.

; Setup

Install from MELPA, then put the following somewhere in your init file:

(add-hook 'css-mode-hook 'skewer-reload-stylesheets-start-editing)

If you're live-editing Less, SCSS, or similar, add
`skewer-reload-stylesheets-start-editing' to the appropriate hook variable,
then set `skewer-reload-css-compile-command' to your transpile command:

    (setq skewer-reload-stylesheets-compile-command "gulp css")

This variable is best set in .dir-locals.el, so it can be set correctly
per-project.

; Usage

Open a browser window for the URL whose stylesheets you want to live-edit.
Skewer that window.

In emacs, open the stylesheet(s) you want to live-edit.

Make some changes in the stylesheet and save it. The updates will immediately
be reflected in the skewered windows.

and there you are - cross-browser live-editing for arbitrarily complex
stylesheets.

Note that browser plugins like
[Custom Javascript for Websites](https://chrome.google.com/webstore/detail/custom-javascript-for-web/poakhlngfciodnhlhhgnaaelnpjljija?hl=en)
make it easy to auto-skewer URLs on pageload, so you don't have to manually
re-skewer after every refresh.

Key bindings:

* C-x C-r -- `skewer-reload-stylesheets-reload-buffer`
Note that this keybinding is deprecated, as current usage reloads
stylesheets with an after-save-hook, so there is no need for a custom
keybinding.
