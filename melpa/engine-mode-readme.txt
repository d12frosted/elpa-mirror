`engine-mode' is a global minor mode for Emacs. It enables you to
easily define search engines, bind them to keybindings, and query
them from the comfort of your editor.

For example, suppose we want to be able to easily search GitHub:

(defengine github
  "https://github.com/search?ref=simplesearch&q=%s")

This defines an interactive function `engine/search-github'. When
executed it will take the selected region (or prompt for input, if
no region is selected) and search GitHub for it, displaying the
results in your default browser.

The `defengine' macro can also take an optional key combination,
prefixed with "C-x /":

(defengine duckduckgo
  "https://duckduckgo.com/?q=%s"
  :keybinding "d")

`C-x / d' is now bound to the new function
engine/search-duckduckgo'! Nifty.
